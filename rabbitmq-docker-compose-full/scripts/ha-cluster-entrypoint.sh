#!/bin/bash

set -euo pipefail

echo "🐰 Starting RabbitMQ HA cluster node..."

# Start RabbitMQ server in detached mode
/usr/local/bin/docker-entrypoint.sh rabbitmq-server -detached

# Wait for RabbitMQ to be ready
echo "⏳ Waiting for RabbitMQ to be ready..."
timeout=90
count=0
while ! rabbitmq-diagnostics -q ping > /dev/null 2>&1; do
    sleep 3
    count=$((count + 3))
    if [ $count -ge $timeout ]; then
        echo "❌ Timeout waiting for RabbitMQ to start"
        exit 1
    fi
done
echo "✅ RabbitMQ is ready"

# Wait additional time for node to be fully operational
echo "⏳ Waiting for node to be fully operational..."
sleep 5

# Stop the app and join the cluster
echo "🔗 Joining HA cluster..."
rabbitmqctl stop_app
rabbitmqctl reset

# Wait for primary node to be available
echo "⏳ Waiting for primary node to be available..."
timeout=60
count=0
while ! rabbitmqctl -n rabbit@rabbitmq-ha-1 cluster_status > /dev/null 2>&1; do
    sleep 3
    count=$((count + 3))
    if [ $count -ge $timeout ]; then
        echo "❌ Timeout waiting for primary node"
        exit 1
    fi
done

# Check if this is the third node (rabbitmq-ha-3) and wait for second node
HOSTNAME=$(hostname)
if [ "$HOSTNAME" = "rabbitmq-ha-3" ]; then
    echo "⏳ Waiting for second node to join cluster..."
    timeout=90
    count=0
    while ! rabbitmqctl -n rabbit@rabbitmq-ha-1 cluster_status | grep -q "rabbit@rabbitmq-ha-2"; do
        sleep 3
        count=$((count + 3))
        if [ $count -ge $timeout ]; then
            echo "❌ Timeout waiting for second node to join"
            exit 1
        fi
    done
    echo "✅ Second node is in cluster"
fi

rabbitmqctl join_cluster rabbit@rabbitmq-ha-1
rabbitmqctl start_app

# Enable HA policy for all queues
echo "🔧 Setting up HA policy..."
rabbitmqctl set_policy ha-all ".*" '{"ha-mode":"all","ha-sync-mode":"automatic"}'

# Verify cluster status
echo "🔍 Verifying cluster status..."
rabbitmqctl cluster_status

# Stop the server to restart in foreground
echo "🔄 Restarting RabbitMQ in foreground..."
rabbitmqctl stop

# Wait for clean shutdown
sleep 3

# Start RabbitMQ in foreground
echo "🚀 Starting RabbitMQ server in foreground..."
exec rabbitmq-server