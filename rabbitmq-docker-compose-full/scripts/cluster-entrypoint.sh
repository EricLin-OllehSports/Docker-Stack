#!/bin/bash

set -euo pipefail

echo "🐰 Starting RabbitMQ cluster node..."

# Start RabbitMQ server in detached mode
/usr/local/bin/docker-entrypoint.sh rabbitmq-server -detached

# Wait for RabbitMQ to be ready
echo "⏳ Waiting for RabbitMQ to be ready..."
timeout=60
count=0
while ! rabbitmq-diagnostics -q ping > /dev/null 2>&1; do
    sleep 2
    count=$((count + 2))
    if [ $count -ge $timeout ]; then
        echo "❌ Timeout waiting for RabbitMQ to start"
        exit 1
    fi
done
echo "✅ RabbitMQ is ready"

# Stop the app and join the cluster
echo "🔗 Joining cluster..."
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@rabbitmq-cluster-1
rabbitmqctl start_app

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