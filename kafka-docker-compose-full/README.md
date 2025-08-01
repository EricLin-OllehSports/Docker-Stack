# Kafka & Zookeeper Docker Compose Stack (優化版)

本範例支援以下模式：
- **單機**: Zookeeper + Kafka 單節點
- **集群**: Zookeeper + 3 個 Kafka Broker
- **Kafka UI**: 管理介面，可同時查看單機和集群

## 優化特性
- ✅ 健康檢查 (Health Checks)
- ✅ 專用網絡 (Dedicated Network)
- ✅ JMX 監控端口
- ✅ 生產級別設定
- ✅ 依賴條件檢查
- ✅ 性能調優參數

## 目錄結構
```
.
├── docker-compose.yml  # 主要配置檔
├── .env               # 環境變數設定
└── README.md          # 說明文件
```

## 啟動

### 單機模式
```bash
docker-compose --profile single up -d
```

### 集群模式
```bash
docker-compose --profile cluster up -d
```

### 同時啟動 UI
上述兩種模式啟動後，執行：
```bash
docker-compose --profile single --profile cluster up -d kafka-ui
```

## 測試指令

### Zookeeper
```bash
echo ruok | nc 127.0.0.1 2181
# 应返回 imok
```

### Kafka 單機

1. 創建 topic:
   ```bash
   docker exec kafka-single kafka-topics --create --topic test --bootstrap-server kafka-single:9092 --replication-factor 1 --partitions 1
   ```
2. 列出 topics:
   ```bash
   docker exec kafka-single kafka-topics --list --bootstrap-server kafka-single:9092
   ```
3. 生產與消費:
   ```bash
   echo "hello" | docker exec -i kafka-single kafka-console-producer --topic test --bootstrap-server kafka-single:9092
   docker exec kafka-single kafka-console-consumer --topic test --from-beginning --bootstrap-server kafka-single:9092 --max-messages 1
   ```

### Kafka 集群

1. 創建 topic:
   ```bash
   docker exec kafka-broker-1 kafka-topics --create --topic cluster-test --bootstrap-server kafka-broker-1:9093 --replication-factor 3 --partitions 3
   ```
2. 列出 topics:
   ```bash
   docker exec kafka-broker-1 kafka-topics --list --bootstrap-server kafka-broker-1:9093
   ```
3. 生產與消費:
   ```bash
   echo "world" | docker exec -i kafka-broker-1 kafka-console-producer --topic cluster-test --bootstrap-server kafka-broker-1:9093
   docker exec kafka-broker-2 kafka-console-consumer --topic cluster-test --from-beginning --bootstrap-server kafka-broker-2:9094 --max-messages 1
   ```

## 監控與管理

### JMX 監控端口
- Kafka 單機: `localhost:9999`
- Kafka 集群: 
  - Broker 1: `localhost:19991`
  - Broker 2: `localhost:19992`
  - Broker 3: `localhost:19993`

### 健康檢查
所有服務都配置了健康檢查，可使用以下指令查看狀態：
```bash
docker-compose ps
```

### Kafka UI
訪問 http://localhost:8080 查看 Kafka 管理介面

## 優化配置說明

### 生產級別設定
- `AUTO_CREATE_TOPICS_ENABLE: false` - 禁用自動建立 topic
- `UNCLEAN_LEADER_ELECTION_ENABLE: false` - 禁用不乾淨的 leader 選舉
- `MIN_INSYNC_REPLICAS: 2` - 集群模式最小同步副本數

### 性能調優
- Log retention: 7天 (168小時)
- Segment size: 1GB
- 預設分區數: 3

## 注意事項

1. **資料卷路徑**  
   - Zookeeper: `${HOME}/container-data/zookeeper/...`  
   - Kafka 單機: `${HOME}/container-data/kafka/single`  
   - Kafka 集群: `${HOME}/container-data/kafka/broker-{1,2,3}`  

2. **網絡設定**  
   - 使用專用網絡 `kafka-network`
   - Container 名稱作為通訊名稱，外部測試用 `localhost:<port>`
   - Kafka UI 可同時監控多個集群

3. **環境變數**  
   可在 `.env` 檔案中調整 JVM 記憶體設定和其他參數

4. **清理重建**  
   ```bash
   docker-compose down
   rm -rf ~/container-data/zookeeper ~/container-data/kafka
   ```

5. **資源需求**  
   - 建議至少 4GB RAM
   - 每個 Kafka broker 預設分配 1GB heap memory  
