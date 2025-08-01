# Redis Docker Compose Complete

本專案提供 Redis 的四種部署模式，支援從開發到生產環境的各種需求：**單機 (single)**、**主從複製 (replication)**、**Sentinel 高可用**、**集群分片 (cluster)**。

## 🏗️ 目錄結構
```
.
├── docker-compose.yml          # 主要配置文件 (統一管理四種模式)
├── README.md                   # 使用說明和測試指令
├── redis_config/              # Redis 基礎配置
│   └── redis.conf             # 通用 Redis 配置文件
└── scripts/                   # 自動化腳本
    ├── init-cluster.sh        # 集群自動初始化
    └── start-sentinel.sh      # Sentinel 動態配置啟動
```

## 🚀 快速啟動

### 1️⃣ 單機模式 (開發測試)
```bash
docker-compose --profile single up -d
```
- **端口**: 6379
- **用途**: 開發環境、功能測試
- **特點**: 輕量級、快速啟動

### 2️⃣ 主從複製模式 (讀寫分離)
```bash
docker-compose --profile replication up -d
```
- **端口**: Master 6380, Slave 6381
- **用途**: 讀寫分離、數據備份
- **特點**: 提升讀取性能

### 3️⃣ Sentinel 模式 (高可用)
```bash
docker-compose --profile sentinel up -d
```
- **端口**: Master 6382, Slave 6383, Sentinel 26379
- **用途**: 生產環境高可用
- **特點**: 自動故障轉移、監控告警

### 4️⃣ 集群模式 (水平擴展)
```bash
docker-compose --profile cluster up -d
```
- **端口**: 7001, 7002, 7003 (+ bus ports 17001-17003)
- **用途**: 大規模數據、高併發
- **特點**: 數據分片、水平擴展

### 🔄 啟動所有模式 (演示用)
```bash
docker-compose up -d
```

## 測試指令

#### 單機模式
```bash
redis-cli -h 127.0.0.1 -p 6379 ping
```

#### 主從複製
```bash
# 檢查 Master 角色
redis-cli -h 127.0.0.1 -p 6380 info replication | grep role

# 在 Master 設定一筆測試鍵
redis-cli -h 127.0.0.1 -p 6380 set testkey "hello"

# 在 Slave 驗證
redis-cli -h 127.0.0.1 -p 6381 get testkey
```

#### Sentinel
```bash
# 查詢 Master 地址
redis-cli -h 127.0.0.1 -p 26379 sentinel get-master-addr-by-name mymaster

# 測試故障轉移：停止 redis-master，觀察 redis-slave 是否成為 Master
```

#### 集群
```bash
# 檢查集群狀態
redis-cli -c -p 7001 cluster info

# 檢查節點分配
redis-cli -p 7001 cluster nodes

# 設置和獲取數據 (注意：使用同一節點避免重定向問題)
redis-cli -p 7001 set clusterkey "value"
redis-cli -p 7001 get clusterkey

# 測試不同 slot 的 key (可能會重定向)
redis-cli -p 7001 set key1 "node1"
redis-cli -p 7002 set key2 "node2" 
redis-cli -p 7003 set key3 "node3"
```

**⚠️ 集群模式限制：**
- 使用 `-c` 參數時，客戶端可能被重定向到內部 Docker IP
- 建議直接連接到正確的節點，或在容器內使用客戶端
- 生產環境需要配置 `cluster-announce-ip` 參數

## 📝 重要事項

### 數據持久化
所有 Redis 數據存儲在 `${HOME}/container-data/redis/data/` 目錄：
- **單機**: `single/`
- **主從**: `master/`, `slave/`  
- **Sentinel**: `sentinel-master/`, `sentinel-slave/`
- **集群**: `cluster/node1/`, `cluster/node2/`, `cluster/node3/`

### 配置自動化
- **Sentinel**: 使用動態腳本自動配置，無需手動設置
- **Cluster**: 自動初始化和分片配置
- **健康檢查**: 所有服務都包含自動健康監控

### 清理和重建
```bash
# 停止所有服務
docker-compose down

# 清理數據目錄 (可選，會清除所有數據)
rm -rf ~/container-data/redis/data

# 重新啟動
docker-compose --profile <mode> up -d
```

### 生產環境建議
1. 在 `redis_config/redis.conf` 中設置密碼
2. 調整記憶體和持久化策略
3. 配置適當的日誌級別
4. 使用專用的 Docker 網路

## 🔧 故障排除

### Cluster 連接問題
如果 Cluster 客戶端重定向失敗：
```bash
# 方法1: 在容器內執行命令
docker exec -it redis-cluster-node-1 redis-cli -c -p 6379 set key value

# 方法2: 不使用 -c 參數，直接連接節點
redis-cli -p 7001 set key1 "value1"
redis-cli -p 7002 set key2 "value2" 

# 方法3: 檢查 key 應該在哪個節點
redis-cli -p 7001 cluster keyslot mykey
```

### Sentinel 連接問題
如果無法連接 Sentinel：
```bash
# 檢查 Sentinel 日誌
docker-compose logs redis-sentinel

# 檢查 Sentinel 和 Redis 節點網路
docker-compose exec redis-sentinel ping redis-sentinel-master
```

### 常見錯誤
- **端口衝突**: 確保端口 6379-6383, 7001-7003, 26379 沒有被佔用
- **權限問題**: 確保 `~/container-data/redis` 目錄可寫入
- **網路問題**: 如果服務無法互相通信，重啟 Docker 網路
