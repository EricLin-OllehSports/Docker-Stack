# Docker Stack Complete - 統一監控

針對 Docker Stack Complete 專案中所有元件的完整監控解決方案。此配置提供 Redis、MySQL、MongoDB、Kafka、RabbitMQ、Nginx、Elasticsearch 等跨服務的綜合監控。

## 🏗️ 架構概覽

```
Docker Stack Complete 統一監控
├── 核心監控 (永遠運行)
│   ├── Prometheus (指標收集)
│   ├── Grafana (視覺化) 
│   ├── AlertManager (警報)
│   ├── Node Exporter (系統指標)
│   └── cAdvisor (容器指標)
│
├── 資料庫監控
│   ├── Redis (單機/複寫/哨兵/叢集)
│   ├── MySQL (單機/主從)
│   └── MongoDB (單機/複本/分片)
│
├── 訊息佇列監控
│   ├── Kafka
│   └── RabbitMQ
│
├── 網頁伺服器監控
│   └── Nginx
│
└── 搜尋引擎監控
    └── Elasticsearch
```

## 🚀 快速開始

### 1. 基本統一監控
```bash
# 僅啟動核心監控
docker-compose -f docker-compose-unified.yml up -d

# 存取網址:
# Prometheus: http://localhost:9091
# Grafana: http://localhost:3000 (admin/admin123)
# AlertManager: http://localhost:9093
# cAdvisor: http://localhost:8080
```

### 2. 監控特定堆疊元件

#### Redis 監控
```bash
# 啟動 Redis 單機監控
docker-compose -f docker-compose-unified.yml --profile redis-single up -d

# 啟動 Redis 複寫監控
docker-compose -f docker-compose-unified.yml --profile redis-replication up -d

# 啟動 Redis 哨兵監控
docker-compose -f docker-compose-unified.yml --profile redis-sentinel up -d

# 啟動 Redis 叢集監控
docker-compose -f docker-compose-unified.yml --profile redis-cluster up -d
```

#### MySQL 監控
```bash
# 啟動 MySQL 單機監控
docker-compose -f docker-compose-unified.yml --profile mysql-single up -d

# 啟動 MySQL 主從監控
docker-compose -f docker-compose-unified.yml --profile mysql-replication up -d
```

#### MongoDB 監控
```bash
# 啟動 MongoDB 單機監控
docker-compose -f docker-compose-unified.yml --profile mongo-single up -d

# 啟動 MongoDB 複本集監控
docker-compose -f docker-compose-unified.yml --profile mongo-replica up -d

# 啟動 MongoDB 分片叢集監控
docker-compose -f docker-compose-unified.yml --profile mongo-sharded up -d
```

### 3. 監控所有服務
```bash
# 啟動所有監控服務
docker-compose -f docker-compose-unified.yml --profile all up -d
```

## 📊 監控設定檔

| 設定檔 | 監控服務 | 使用埠號 |
|---------|----------|----------|
| `redis-single` | Redis 單機 | 9121 |
| `redis-replication` | Redis 主從 | 9122-9123 |
| `redis-sentinel` | Redis 哨兵高可用 | 9124 |
| `redis-cluster` | Redis 叢集 | 9125 |
| `mysql-single` | MySQL 單機 | 9104 |
| `mysql-replication` | MySQL 主從 | 9105-9106 |
| `mongo-single` | MongoDB 單機 | 9216 |
| `mongo-replica` | MongoDB 複本集 | 9217 |
| `mongo-sharded` | MongoDB 分片 | 9218 |
| `kafka` | Kafka 叢集 | 9308 |
| `rabbitmq` | RabbitMQ | 9419 |
| `nginx` | Nginx 網頁伺服器 | 9113 |
| `elasticsearch` | Elasticsearch | 9114 |
| `all` | 所有服務 | 所有埠號 |

## 🔗 網路整合

統一監控會自動連接到其他 Docker Stack Complete 元件的外部網路：

```yaml
networks:
  - redis-docker-compose-full_redis-network
  - mysql-docker-compose-full_mysql-network  
  - mongo-docker-compose-full_mongo-network
  - kafka-docker-compose-full_default
  - rabbitmq-docker-compose-full_default
  - nginx-docker-compose-full_default
  - elastic-docker-compose-full_elastic
```

## 📈 可用儀表板

### 1. 統一概覽儀表板
- 系統資源使用率
- 所有服務狀態概覽
- 容器指標
- 活躍警報摘要
- **網址**: http://localhost:3000/d/unified-overview

### 2. Redis 統一儀表板
- 單一檢視中的所有 Redis 模式
- 依模式分別的記憶體使用量
- 每秒指令數
- 複寫狀態
- 叢集狀態
- **網址**: http://localhost:3000/d/redis-unified

### 3. MySQL 統一儀表板
- 單機和複寫模式
- 連線追蹤
- 查詢效能
- 複寫延遲監控
- InnoDB 指標
- **網址**: http://localhost:3000/d/mysql-unified

### 4. MongoDB 統一儀表板
- 單機、複本和分片模式
- 操作追蹤
- 記憶體和快取使用量
- 複本集健康狀態
- 分片狀態
- **網址**: http://localhost:3000/d/mongodb-unified

### 5. Node Exporter 儀表板
- 系統 CPU、記憶體、磁碟
- 網路 I/O
- 檔案系統使用量
- **網址**: http://localhost:3000/d/node-exporter

## 🚨 警報規則

### 系統警報
- `HostDown`: 服務無法使用超過 5 分鐘
- `HighCPUUsage`: CPU 使用率 > 80% 超過 5 分鐘
- `HighMemoryUsage`: 記憶體使用率 > 85% 超過 5 分鐘
- `DiskSpaceLow`: 磁碟空間 < 10%

### Redis 警報
- `RedisDown`: Redis 實例停機
- `RedisHighMemoryUsage`: 記憶體使用率 > 80%
- `RedisReplicationLag`: 複寫延遲 > 10 秒
- `RedisClusterDown`: 叢集不完整

### MySQL 警報
- `MySQLDown`: MySQL 實例停機
- `MySQLReplicationLag`: 複寫延遲 > 30 秒
- `MySQLSlowQueries`: 慢查詢增加
- `MySQLConnectionsHigh`: 連線數 > 最大值的 80%

### MongoDB 警報
- `MongoDBDown`: MongoDB 實例停機
- `MongoDBReplicationLag`: 複寫延遲 > 10 秒
- `MongoDBHighConnections`: 連線數 > 可用數的 80%

### 訊息佇列警報
- `KafkaDown`: 沒有 Kafka broker 可用
- `KafkaConsumerLag`: 消費者延遲 > 1000 訊息
- `RabbitMQDown`: RabbitMQ 實例停機
- `RabbitMQQueueMessages`: 未確認訊息過多

## 🧪 測試

### 執行綜合測試套件
```bash
./test-unified-monitoring.sh
```

測試套件驗證：
1. 核心監控服務
2. 堆疊整合
3. 網路連線
4. Prometheus 目標
5. Grafana 整合
6. 警報規則
7. 多堆疊監控
8. 服務發現
9. 效能
10. 清理

### 手動測試指令
```bash
# 測試 Prometheus 目標
curl http://localhost:9091/api/v1/targets

# 測試 Grafana 健康狀態
curl http://localhost:3000/api/health

# 測試 AlertManager
curl http://localhost:9093/api/v1/status

# 測試特定匯出器
curl http://localhost:9121/metrics  # Redis
curl http://localhost:9104/metrics  # MySQL
curl http://localhost:9216/metrics  # MongoDB
```

## 🔧 配置檔案

### 核心配置
- `docker-compose-unified.yml` - 主要統一監控配置
- `prometheus/prometheus-unified.yml` - 所有服務的 Prometheus 配置
- `prometheus/rules/unified-alerts.yml` - 所有元件的警報規則
- `alertmanager/alertmanager.yml` - AlertManager 配置

### Grafana 配置
- `grafana/provisioning/datasources/prometheus.yml` - 自動配置 Prometheus 資料源
- `grafana/provisioning/dashboards/dashboards.yml` - 自動載入儀表板
- `grafana/dashboards/` - 所有儀表板 JSON 檔案

## 📋 先決條件

### 必需的 Docker 網路
監控系統會自動建立這些網路（如果不存在）：
- `redis-docker-compose-full_redis-network`
- `mysql-docker-compose-full_mysql-network`
- `mongo-docker-compose-full_mongo-network`
- `kafka-docker-compose-full_default`
- `rabbitmq-docker-compose-full_default`
- `nginx-docker-compose-full_default`
- `elastic-docker-compose-full_elastic`

### 必需的服務
要獲得有意義的指標，請先啟動對應的服務：

```bash
# Redis
cd ../redis-docker-compose-full
docker compose --profile single up -d

# MySQL
cd ../mysql-docker-compose-full
docker compose --profile single up -d

# MongoDB
cd ../mongo-docker-compose-full
docker compose --profile single up -d

# 然後啟動監控
cd ../monitoring-docker-compose-full
docker-compose -f docker-compose-unified.yml --profile all up -d
```

## 🔍 疑難排解

### 常見問題

1. **網路連線問題**
   ```bash
   # 檢查外部網路是否存在
   docker network ls | grep -E "(redis|mysql|mongo|kafka|rabbitmq|nginx|elastic)"
   
   # 如需要手動建立網路
   docker network create redis-docker-compose-full_redis-network
   ```

2. **服務發現問題**
   ```bash
   # 從監控測試與服務的連接性
   docker-compose -f docker-compose-unified.yml exec prometheus nc -z redis-single 6379
   docker-compose -f docker-compose-unified.yml exec prometheus nc -z mysql-single 3306
   ```

3. **匯出器無法啟動**
   ```bash
   # 檢查匯出器日誌
   docker-compose -f docker-compose-unified.yml logs redis_exporter_single
   docker-compose -f docker-compose-unified.yml logs mysql_exporter_single
   ```

4. **缺少指標**
   ```bash
   # 檢查 Prometheus 目標
   curl http://localhost:9091/api/v1/targets | jq '.data.activeTargets[].health'
   
   # 檢查特定匯出器指標
   curl http://localhost:9121/metrics | grep redis_up
   ```

### 除錯指令
```bash
# 查看所有服務狀態
docker-compose -f docker-compose-unified.yml ps

# 檢查服務日誌
docker-compose -f docker-compose-unified.yml logs -f prometheus
docker-compose -f docker-compose-unified.yml logs -f grafana

# 測試網路連線
docker-compose -f docker-compose-unified.yml exec prometheus nslookup redis-single
docker-compose -f docker-compose-unified.yml exec prometheus nslookup mysql-single

# 檢查 Prometheus 配置
docker-compose -f docker-compose-unified.yml exec prometheus cat /etc/prometheus/prometheus.yml
```

## 🚀 進階用法

### 自訂警報規則
新增自訂警報規則到 `prometheus/rules/custom-alerts.yml`：
```yaml
groups:
  - name: custom-alerts
    rules:
      - alert: CustomAlert
        expr: your_metric > threshold
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "自訂警報描述"
```

### 自訂儀表板
1. 在 Grafana UI 中建立儀表板
2. 匯出為 JSON
3. 儲存到 `grafana/dashboards/`
4. 重啟 Grafana 以自動載入

### 生產環境擴展
```yaml
# 新增資源限制
deploy:
  resources:
    limits:
      memory: 2G
      cpus: '1.0'
    reservations:
      memory: 1G
      cpus: '0.5'
```

## 📊 指標概覽

### 依服務分類的可用指標

#### Redis 指標
- `redis_up` - 服務可用性
- `redis_memory_used_bytes` - 記憶體使用量
- `redis_commands_processed_total` - 處理的指令
- `redis_connected_clients` - 連接的客戶端
- `redis_keyspace_hits_total` - 快取命中
- `redis_keyspace_misses_total` - 快取未命中

#### MySQL 指標
- `mysql_up` - 服務可用性
- `mysql_global_status_threads_connected` - 活躍連線
- `mysql_global_status_queries` - 總查詢數
- `mysql_global_status_slow_queries` - 慢查詢
- `mysql_slave_lag_seconds` - 複寫延遲

#### MongoDB 指標
- `mongodb_up` - 服務可用性
- `mongodb_connections` - 連線數量
- `mongodb_opcounters_total` - 操作計數
- `mongodb_memory` - 記憶體使用量
- `mongodb_mongod_replset_member_replication_lag` - 複本延遲

## 🎯 最佳實踐

1. **依序啟動服務**
   - 先啟動目標服務
   - 再啟動監控服務
   - 這確保適當的服務發現

2. **策略性使用設定檔**
   - 從核心監控開始
   - 根據需要新增特定設定檔
   - 使用 `--profile all` 進行綜合監控

3. **監控資源使用量**
   - 使用 cAdvisor 檢查容器指標
   - 使用 node-exporter 監控主機資源
   - 設定適當的資源限制

4. **定期維護**
   - 定期輪換日誌
   - 清理舊的指標資料
   - 更新儀表板配置

5. **安全性考量**
   - 更改預設 Grafana 密碼
   - 對敏感資料使用機密
   - 實施適當的身份驗證

這個統一監控解決方案提供對所有 Docker Stack Complete 元件的完整可見性，配置開銷最小。