#!/bin/bash
set -e

echo "Redis Cluster Initialization Starting..."

# 等待所有節點就緒
echo "Waiting for all cluster nodes to be ready..."
for node in redis-cluster-node-1 redis-cluster-node-2 redis-cluster-node-3; do
  echo "Waiting for $node..."
  until redis-cli -h $node -p 6379 ping > /dev/null 2>&1; do
    echo "  Still waiting for $node..."
    sleep 2
  done
  echo "  $node is ready!"
done

echo "All nodes are ready. Checking cluster status..."

# 檢查是否已經有集群存在
if redis-cli -h redis-cluster-node-1 -p 6379 cluster info | grep -q 'cluster_state:ok'; then
  echo "Cluster already exists and is OK."
  redis-cli -h redis-cluster-node-1 -p 6379 cluster nodes
else
  echo "Creating new Redis cluster..."
  
  # 先重置所有節點的集群狀態
  for node in redis-cluster-node-1 redis-cluster-node-2 redis-cluster-node-3; do
    echo "Resetting cluster state for $node..."
    redis-cli -h $node -p 6379 FLUSHALL || true
    redis-cli -h $node -p 6379 CLUSTER RESET HARD || true
  done
  
  echo "All nodes reset. Creating cluster..."
  
  # 創建集群 - 使用內部地址創建，但節點會 announce 外部地址
  redis-cli --cluster create \
    redis-cluster-node-1:6379 \
    redis-cluster-node-2:6379 \
    redis-cluster-node-3:6379 \
    --cluster-replicas 0 \
    --cluster-yes
  
  echo "Cluster created successfully!"
  
  # 顯示集群狀態
  echo "Cluster nodes:"
  redis-cli -h redis-cluster-node-1 -p 6379 cluster nodes
  
  echo "Cluster info:"
  redis-cli -h redis-cluster-node-1 -p 6379 cluster info
fi

echo "Redis Cluster initialization completed!"

# 保持容器運行一段時間以便觀察日誌
sleep 10