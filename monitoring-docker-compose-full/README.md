# 完整監控堆疊 Docker Compose

使用 Prometheus、Grafana、AlertManager 和各種匯出器監控不同服務的綜合監控解決方案。

## 功能特色

- **核心監控**: Prometheus、Grafana、AlertManager
- **系統監控**: Node Exporter 用於系統指標
- **資料庫監控**: MySQL、Redis、MongoDB 匯出器
- **訊息佇列監控**: Kafka、RabbitMQ 匯出器
- **網頁伺服器監控**: Nginx、Elasticsearch 匯出器
- **健康檢查**: 所有服務內建健康檢查
- **警報系統**: 預先配置常見問題警報
- **設定檔**: 特定服務的設定檔用於選擇性部署

## 快速開始

### 基本監控 (核心 + Node Exporter)
```bash
docker compose up -d
```

### 完整堆疊與所有匯出器
```bash
docker compose --profile all up -d
```

### 選擇性監控
```bash
# MySQL 監控
docker compose --profile mysql up -d

# Redis 監控
docker compose --profile redis up -d

# 多個服務
docker compose --profile mysql --profile redis up -d
```

## 可用設定檔

- `mysql` - MySQL 資料庫監控
- `redis` - Redis 監控
- `mongodb` - MongoDB 監控
- `kafka` - Kafka 監控
- `rabbitmq` - RabbitMQ 監控
- `nginx` - Nginx 網頁伺服器監控
- `elasticsearch` - Elasticsearch 監控
- `all` - 所有匯出器

## 存取網址

- **Prometheus**: http://localhost:9091
- **Grafana**: http://localhost:3000 (admin/admin123)
- **AlertManager**: http://localhost:9093

## 服務埠號

| Service | Port | Description |
|---------|------|-------------|
| Prometheus | 9091 | 指標收集和查詢 |
| Grafana | 3000 | 視覺化儀表板 |
| AlertManager | 9093 | 警報管理 |
| Node Exporter | 9100 | 系統指標 |
| MySQL Exporter | 9104 | MySQL 指標 |
| Redis Exporter | 9121 | Redis 指標 |
| MongoDB Exporter | 9216 | MongoDB 指標 |
| Kafka Exporter | 9308 | Kafka 指標 |
| RabbitMQ Exporter | 9419 | RabbitMQ 指標 |
| Nginx Exporter | 9113 | Nginx 指標 |
| Elasticsearch Exporter | 9114 | Elasticsearch 指標 |

## 配置

### Prometheus
- 配置檔: `prometheus/prometheus.yml`
- 警報規則: `prometheus/rules/basic-alerts.yml`
- 資料保存期: 30 天

### Grafana
- 管理員密碼: `admin123` (在 docker-compose.yml 中更改)
- 資料源: 自動配置 Prometheus
- 儀表板: 將 JSON 檔案放在 `grafana/dashboards/`

### AlertManager
- 配置檔: `alertmanager/alertmanager.yml`
- 預設 webhook: http://127.0.0.1:5001/

## 測試

### 測試核心服務
```bash
# 檢查所有核心服務是否運行
docker compose ps

# 測試 Prometheus 目標
curl http://localhost:9091/api/v1/targets

# 測試 Grafana 健康狀態
curl http://localhost:3000/api/health
```

### 使用特定設定檔測試
```bash
# 使用 Redis 設定檔啟動
docker compose --profile redis up -d

# 驗證 Redis 匯出器是否工作
curl http://localhost:9121/metrics
```

### 健康檢查
所有服務都包含健康檢查。檢查狀態：
```bash
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

## 監控外部服務

要監控外部服務，請在 `docker-compose.yml` 中更新匯出器環境變數：

```yaml
mysql_exporter:
  environment:
    - DATA_SOURCE_NAME=user:password@(external-mysql:3306)/

redis_exporter:
  environment:
    - REDIS_ADDR=redis://external-redis:6379
```

## 擴展和生產環境

### 資源限制
為生產環境添加資源限制：
```yaml
services:
  prometheus:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
```

### 安全性
- 更改預設 Grafana 密碼
- 配置適當的身份驗證
- 對敏感資料使用機密
- 使用反向代理啟用 HTTPS

## 疑難排解

### 常見問題

1. **服務無法啟動**: 使用 `docker compose logs <service>` 檢查日誌
2. **指標沒有出現**: 驗證匯出器配置和目標連接性
3. **權限被拒絕**: 確保已掛載卷的檔案權限正確

### 除錯指令
```bash
# 查看服務日誌
docker compose logs -f prometheus

# 檢查容器健康狀態
docker compose exec prometheus wget -q --spider http://localhost:9090/-/healthy

# 測試服務間連線
docker compose exec prometheus nslookup node_exporter
```

## 清理

```bash
# 停止所有服務
docker compose down

# 移除卷 (警告: 這會刪除所有資料)
docker compose down -v

# 移除所有內容包括映像檔
docker compose down -v --rmi all
```