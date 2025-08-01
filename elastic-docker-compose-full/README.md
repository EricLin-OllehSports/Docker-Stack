# Elasticsearch Docker Compose - Complete Stack

This repository provides multiple Elasticsearch configurations for different deployment scenarios:

- **Single Node** (`docker-compose.yml`) - Development environment
- **3-Node Cluster** (`docker-compose-cluster.yml`) - High availability setup  
- **Security Enabled** (`docker-compose-security.yml`) - Production-ready with authentication

Each configuration includes a complete ELK (Elasticsearch, Logstash, Kibana) stack with dual log processing workflows.

## Architecture Overview

```
Workflow 1: Docker Container Logs
Docker Containers -> Filebeat -> Logstash:5000 -> Elasticsearch -> Kibana

Workflow 2: Application Logs  
Application -> Logstash (File/TCP) -> Elasticsearch -> Kibana
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Elasticsearch** | 9200, 9300 | Search and analytics engine |
| **Kibana** | 5601 | Data visualization and exploration |
| **Logstash** | 5000, 5001 | Data processing pipeline |
| **Filebeat** | - | Log shipping agent |

## Quick Start

### 選擇部署模式

**單節點模式 (開發環境)**
```bash
# 啟動單節點服務
docker-compose up -d
```

**3節點叢集模式 (高可用性)**
```bash
# 啟動叢集服務
docker-compose -f docker-compose-cluster.yml up -d
```

**安全模式 (生產環境)**
```bash
# 啟動安全服務
docker-compose -f docker-compose-security.yml up -d
```

**檢查服務狀態**
```bash
# 查看容器狀態
docker-compose ps

# 查看日誌
docker-compose logs -f

# 清理環境
./cleanup.sh
```

### 驗證服務

**單節點/叢集模式**
- **Elasticsearch**: http://localhost:9200/_cluster/health
- **Kibana**: http://localhost:5601  
- **Logstash**: http://localhost:9600/_node/stats

**叢集模式額外端點**
- **Node 2**: http://localhost:9201/_cluster/health
- **Node 3**: http://localhost:9202/_cluster/health

**安全模式 (需要認證)**
- **Elasticsearch**: https://localhost:9200/_cluster/health (elastic/changeme)
- **Kibana**: https://localhost:5601 (elastic/changeme)
- **Username**: elastic, **Password**: changeme

### 3. Test Log Workflows

#### Workflow 1: Docker Container Logs (Automatic)
Docker container logs are automatically collected by Filebeat and processed.

#### Workflow 2: Application Logs

**Option A: File-based logs**
```bash
# Add your application logs to the logs/app/ directory
echo "2024-08-01T10:00:00 INFO [app] Application started" >> logs/app/myapp.log
```

**Option B: TCP-based logs**
```bash
# Send JSON logs via TCP to port 5001
echo '{"timestamp":"2024-08-01T10:00:00","level":"INFO","service":"myapp","message":"Test message"}' | nc localhost 5001

# Or use the test script
./test-tcp-logs.sh
```

## 部署模式比較

| 特性 | 單節點 | 3節點叢集 | 安全模式 |
|------|--------|-----------|----------|
| **用途** | 開發測試 | 高可用性 | 生產環境 |
| **節點數** | 1 | 3 | 1 |
| **端口衝突處理** | ✅ | ✅ | ✅ |
| **SSL/TLS** | ❌ | ❌ | ✅ |
| **身份驗證** | ❌ | ❌ | ✅ |
| **資源需求** | 低 | 高 | 中 |
| **健康檢查** | ✅ | ✅ | ✅ |

## Configuration Details

### Elasticsearch Configuration
- **Version**: 8.13.0
- **Memory**: 1GB heap size per node
- **Storage**: 
  - Single: `./data/elasticsearch`
  - Cluster: Docker volumes (`es-data-01/02/03`)
  - Security: Docker volumes + SSL certificates

### Logstash Pipeline
- **Input Sources**:
  - TCP port 5002: Filebeat (Docker logs) - 避免端口衝突
  - TCP port 5001: Application TCP logs
  - File input: `./logs/app/*.log`
- **Output**: 
  - Single: `http://elasticsearch:9200`
  - Cluster: Load balanced across 3 nodes
  - Security: `https://elasticsearch:9200` with SSL
- **Memory**: 512MB heap size
- **Monitoring**: Disabled to reduce overhead

### Filebeat Configuration
- **Sources**: Docker container logs (`/var/lib/docker/containers/*/*.log`)
- **Output**: Logstash TCP port 5000
- **Storage**: `./data/filebeat`

### Index Patterns
Logs are automatically indexed by source:
- `logs-docker-YYYY.MM.dd` - Docker container logs
- `logs-application-YYYY.MM.dd` - Application file logs  
- `logs-app-tcp-YYYY.MM.dd` - Application TCP logs

## Kibana Setup

1. Access Kibana at http://localhost:5601
2. Go to **Stack Management** → **Index Patterns**
3. Create index patterns:
   - `logs-docker-*`
   - `logs-application-*`
   - `logs-app-tcp-*`
4. Go to **Discover** to view and search logs

## Health Monitoring

All services include health checks:

```bash
# Check individual service health
docker-compose exec elasticsearch curl -f http://localhost:9200/_cluster/health
docker-compose exec kibana curl -f http://localhost:5601/api/status
docker-compose exec logstash curl -f http://localhost:9600/_node/stats
docker-compose exec filebeat filebeat test config
```

## Troubleshooting

### Common Issues

**Services not starting:**
```bash
# Check logs
docker-compose logs elasticsearch
docker-compose logs kibana
docker-compose logs logstash
docker-compose logs filebeat

# Restart specific service
docker-compose restart elasticsearch
```

**Elasticsearch heap size errors:**
```bash
# Increase Docker memory or reduce heap size in docker-compose.yml
# ES_JAVA_OPTS=-Xms512m -Xmx512m
```

**Permission errors:**
```bash
# Fix data directory permissions
sudo chown -R 1000:1000 data/
```

**Logstash not receiving logs:**
```bash
# Test TCP connectivity
nc -zv localhost 5000
nc -zv localhost 5001

# Check Logstash configuration
docker-compose exec logstash logstash --config.test_and_exit
```

### Useful Commands

```bash
# View Elasticsearch indices
curl http://localhost:9200/_cat/indices?v

# Search logs directly
curl "http://localhost:9200/logs-*/_search?q=ERROR&size=10&pretty"

# Monitor cluster status
curl http://localhost:9200/_cluster/health?pretty

# Check Logstash pipeline stats
curl http://localhost:9600/_node/stats?pretty
```

## 生產環境注意事項

**⚠️ 開發環境配置不適合生產使用**

### 安全模式已實現的功能
- ✅ **X-Pack Security** 已啟用
- ✅ **SSL/TLS** 自動生成證書
- ✅ **身份驗證** 內建用戶管理
- ✅ **持久化存儲** Docker volumes
- ✅ **健康檢查** 所有服務

### 生產環境額外建議
1. **更改預設密碼** (elastic/changeme)
2. **使用自有SSL證書**
3. **實施資源限制和監控**
4. **建立備份策略**
5. **網路安全配置**
6. **日誌轉換和保留政策**

### 清理和維護
```bash
# 使用清理腳本
./cleanup.sh

# 或手動清理
docker-compose down -v  # 停止並刪除volumes
docker system prune -a  # 清理未使用的Docker資源
```

## 檔案結構

```
elastic-docker-compose-full/
├── docker-compose.yml              # 單節點配置
├── docker-compose-cluster.yml      # 3節點叢集配置
├── docker-compose-security.yml     # 安全模式配置
├── README.md                       # 說明文檔
├── cleanup.sh                      # 清理腳本
├── .gitignore                      # Git忽略文件
├── filebeat/
│   ├── filebeat.yml               # 基本配置
│   └── filebeat-secure.yml        # 安全模式配置
├── logstash/
│   ├── pipeline/
│   │   ├── logstash.conf          # 叢集模式配置
│   │   └── logstash-single.conf   # 單節點配置
│   └── pipeline-secure/
│       └── logstash.conf          # 安全模式配置
├── logs/
│   └── app/
│       └── sample-app.log         # 範例日誌
├── data/                          # 數據目錄
└── test-tcp-logs.sh              # 測試腳本
```

## Version Information

- **Elasticsearch**: 8.13.0
- **Kibana**: 8.13.0  
- **Logstash**: 8.13.0
- **Filebeat**: 8.13.0
- **Docker Compose**: 3.7+ (version字段已移除，符合新版本要求)

## License

This configuration is provided as-is for educational and development purposes.