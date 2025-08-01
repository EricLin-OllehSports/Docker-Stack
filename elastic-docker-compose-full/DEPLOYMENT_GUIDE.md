# Elasticsearch Docker 部署指南

## 部署模式選擇

### 1. 單節點模式 (開發/測試環境)
```bash
docker-compose up -d
```

**適用場景：**
- 本地開發
- 功能測試
- 資源有限的環境

**資源需求：**
- RAM: 最少 4GB
- CPU: 2 cores
- 磁碟: 10GB+

### 2. 三節點叢集模式 (高可用性)
```bash
docker-compose -f docker-compose-cluster.yml up -d
```

**適用場景：**
- 高可用性需求
- 大數據量處理
- 生產環境預備

**資源需求：**
- RAM: 最少 8GB (每節點2-3GB)
- CPU: 6+ cores
- 磁碟: 50GB+

### 3. 安全模式 (生產環境)
```bash
docker-compose -f docker-compose-security.yml up -d
```

**適用場景：**
- 生產環境
- 敏感數據處理
- 合規要求

**資源需求：**
- RAM: 最少 6GB
- CPU: 4+ cores
- 磁碟: 30GB+

## 部署前檢查清單

### 系統需求
- [ ] Docker Engine 20.10+
- [ ] Docker Compose 2.0+
- [ ] 充足的記憶體和磁碟空間
- [ ] 開放必要的網路端口

### 端口檢查
```bash
# 檢查端口是否被佔用
lsof -i :9200  # Elasticsearch
lsof -i :5601  # Kibana
lsof -i :5000  # Logstash (可能衝突)
lsof -i :5001  # Logstash TCP
lsof -i :5002  # Logstash TCP (修正後)
```

### 記憶體設定
```bash
# 檢查和設定 vm.max_map_count
sysctl vm.max_map_count
sudo sysctl -w vm.max_map_count=262144

# 永久設定
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
```

## 部署步驟

### Step 1: 環境準備
```bash
# 克隆或下載配置文件
cd elastic-docker-compose-full

# 確認權限
chmod +x test-tcp-logs.sh cleanup.sh

# 建立必要目錄
mkdir -p data/elasticsearch data/filebeat logs/app
```

### Step 2: 選擇並啟動服務
```bash
# 單節點模式
docker-compose up -d

# 或叢集模式
docker-compose -f docker-compose-cluster.yml up -d

# 或安全模式
docker-compose -f docker-compose-security.yml up -d
```

### Step 3: 驗證部署
```bash
# 檢查容器狀態
docker-compose ps

# 檢查健康狀態
curl http://localhost:9200/_cluster/health?pretty

# 檢查節點 (叢集模式)
curl http://localhost:9200/_cat/nodes?v
```

### Step 4: 配置索引模式 (Kibana)
1. 訪問 http://localhost:5601
2. 導航到 "Stack Management" → "Index Patterns"
3. 創建索引模式：
   - `logs-docker-*`
   - `logs-application-*`
   - `logs-app-tcp-*`

## 故障排除

### 常見問題

**1. 端口衝突**
```bash
# 解決方案：修改端口映射或停止衝突服務
docker-compose down
# 編輯 docker-compose.yml 修改端口
```

**2. 記憶體不足**
```bash
# 檢查記憶體使用
docker stats

# 減少 heap size
# 修改 ES_JAVA_OPTS=-Xms512m -Xmx512m
```

**3. 權限問題**
```bash
# 修正數據目錄權限
sudo chown -R 1000:1000 data/
sudo chmod -R 755 data/
```

**4. SSL 證書問題 (安全模式)**
```bash
# 重新生成證書
docker-compose -f docker-compose-security.yml down -v
docker-compose -f docker-compose-security.yml up -d
```

### 日誌檢查
```bash
# 查看服務日誌
docker-compose logs elasticsearch
docker-compose logs kibana
docker-compose logs logstash
docker-compose logs filebeat

# 實時監控
docker-compose logs -f
```

## 效能調整

### Elasticsearch 調整
```yaml
environment:
  - ES_JAVA_OPTS=-Xms2g -Xmx2g  # 增加 heap size
  - indices.memory.index_buffer_size=30%
  - indices.memory.min_index_buffer_size=96mb
```

### Logstash 調整
```yaml
environment:
  - LS_JAVA_OPTS=-Xmx1g -Xms1g  # 增加 heap size
  - PIPELINE_WORKERS=4           # 增加工作線程
  - PIPELINE_BATCH_SIZE=1000     # 批處理大小
```

## 監控和維護

### 健康檢查
```bash
# Elasticsearch 健康狀態
curl "http://localhost:9200/_cluster/health?level=indices&pretty"

# 索引統計
curl "http://localhost:9200/_cat/indices?v&s=store.size:desc"

# 節點統計
curl "http://localhost:9200/_nodes/stats?pretty"
```

### 清理和維護
```bash
# 使用清理腳本
./cleanup.sh

# 手動清理
docker-compose down -v
docker system prune -a
```

### 備份策略
```bash
# 快照備份 (生產環境建議)
curl -X PUT "localhost:9200/_snapshot/backup" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/usr/share/elasticsearch/backup"
  }
}
'
```

## 升級指南

### 版本升級
1. 備份數據和配置
2. 停止服務：`docker-compose down`
3. 更新 Docker 映像版本
4. 啟動服務：`docker-compose up -d`
5. 驗證升級結果

### 配置遷移
```bash
# 從舊版本遷移配置
cp old-config/* new-config/
# 手動調整不相容設定
```

## 安全最佳實務

### 密碼管理
```bash
# 更改預設密碼 (安全模式)
docker exec elasticsearch-secure \
  curl -u elastic:changeme -X POST \
  "localhost:9200/_security/user/elastic/_password" \
  -d '{"password":"your-new-password"}'
```

### 網路安全
- 使用防火牆限制存取
- 配置 VPN 或內網存取
- 定期更新 SSL 證書

### 存取控制
- 實施角色基礎存取控制 (RBAC)
- 定期審查用戶權限
- 啟用稽核日誌