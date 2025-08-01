#!/bin/bash

# 等待 Redis master 可用
until redis-cli -h redis-sentinel-master -p 6379 ping > /dev/null 2>&1; do
  echo "Waiting for Redis master to be ready..."
  sleep 2
done

echo "Redis master is ready, starting Sentinel..."

# 獲取 Redis master 的 IP 地址
MASTER_IP=$(getent hosts redis-sentinel-master | awk '{ print $1 }')
echo "Redis master IP: $MASTER_IP"

# 生成 Sentinel 配置，使用 IP 地址
cat > /tmp/sentinel.conf << EOF
# 監聽 port
port 26379

# 允許從任何主機連接
bind 0.0.0.0

# 監控名稱 mymaster、主節點 IP、內部 port 6379、quorum 1
sentinel monitor mymaster $MASTER_IP 6379 1

# 主節點認定為 down 前的等待毫秒數
sentinel down-after-milliseconds mymaster 5000

# 同步時同時接收資料的 replica 數量
sentinel parallel-syncs mymaster 1

# failover 超時毫秒數
sentinel failover-timeout mymaster 60000

# 當配置更改時，將配置寫入配置文件
sentinel deny-scripts-reconfig yes
EOF

# 啟動 Sentinel
exec redis-server /tmp/sentinel.conf --sentinel