# MongoDB Docker Compose - Development Environment

本專案提供 MongoDB 7.0 的三種部署模式，適合本機開發和測試環境：**單機 (single)**、**副本集 (replica)** 和 **分片集群 (sharded)**。

## 🏗️ 目錄結構
```
.
├── docker-compose.yml          # 主配置文件 (統一管理三種模式)
├── README.md                   # 使用說明和測試指令
├── keyfile/                    # 副本集和分片集群認證
│   └── mongodb-keyfile         # MongoDB 內部認證密鑰
└── scripts/                    # 初始化腳本
    ├── init-replica.sh         # 副本集自動配置腳本
    └── init-sharded.sh         # 分片集群自動配置腳本
```

## 🚀 快速啟動

### 1️⃣ 單機模式 (開發測試)
```bash
docker-compose --profile single up -d
```
- **端口**: 27017
- **用途**: 日常開發、功能測試
- **特點**: 輕量級、快速啟動

### 2️⃣ 副本集模式 (高可用測試)
```bash
docker-compose --profile replica up -d
```
- **端口**: Primary 27018, Secondary1 27019, Secondary2 27020
- **用途**: 高可用測試、讀寫分離測試
- **特點**: 自動配置副本集、故障轉移

### 3️⃣ 分片集群模式 (水平擴展)
```bash
docker-compose --profile sharded up -d
```
- **端口**: Mongos 27021, Config Servers 27022-27024, Shards 27025-27030
- **用途**: 大規模數據、水平擴展測試
- **特點**: 自動配置分片、數據分佈、查詢路由

### 🔄 啟動所有模式 (演示用)
```bash
docker-compose up -d
```

## 🧪 測試指令

### 單機模式測試
```bash
# 連接測試
mongosh --host 127.0.0.1 --port 27017 --username root --password rootpassword --authenticationDatabase admin --eval "db.runCommand({ping:1})"

# 建立測試數據
mongosh --host 127.0.0.1 --port 27017 --username root --password rootpassword --authenticationDatabase admin --eval "
db.test.insertOne({name: 'single-mode', created: new Date()});
db.test.find().pretty();
"
```

### 副本集模式測試
```bash
# 1. 檢查副本集狀態
mongosh --host 127.0.0.1 --port 27018 --username root --password rootpassword --authenticationDatabase admin --eval "rs.status()"

# 2. 檢查主/從角色
mongosh --host 127.0.0.1 --port 27018 --username root --password rootpassword --authenticationDatabase admin --eval "rs.hello()"

# 3. 在 Primary 寫入測試數據
mongosh --host 127.0.0.1 --port 27018 --username root --password rootpassword --authenticationDatabase admin --eval "
db.test.insertOne({name: 'replica-test', created: new Date(), node: 'primary'});
"

# 4. 從 Secondary 讀取數據 (需要設置讀取偏好)
mongosh --host 127.0.0.1 --port 27019 --username root --password rootpassword --authenticationDatabase admin --eval "
db.getMongo().setReadPref('secondary');
db.test.find({name: 'replica-test'}).pretty();
"

# 5. 測試副本集寫入限制 (Secondary 只能讀取)
mongosh --host 127.0.0.1 --port 27019 --username root --password rootpassword --authenticationDatabase admin --eval "
try {
  db.test.insertOne({test: 'should-fail'});
} catch (e) {
  print('Expected error on secondary write: ' + e.message);
}
" 2>&1 | head -3
```

### 分片集群模式測試
```bash
# 1. 檢查分片集群狀態
mongosh --host 127.0.0.1 --port 27021 --username root --password rootpassword --authenticationDatabase admin --eval "sh.status()"

# 2. 檢查集群拓撲
mongosh --host 127.0.0.1 --port 27021 --username root --password rootpassword --authenticationDatabase admin --eval "db.runCommand('listShards')"

# 3. 測試分片寫入 (預設已啟用 testdb.users 分片)
mongosh --host 127.0.0.1 --port 27021 --username root --password rootpassword --authenticationDatabase admin --eval "
use testdb;
for(let i = 0; i < 1000; i++) {
  db.users.insertOne({
    _id: ObjectId(),
    userId: i,
    name: 'user' + i,
    email: 'user' + i + '@example.com',
    created: new Date()
  });
}
print('✓ Inserted 1000 documents');
"

# 4. 檢查數據分佈
mongosh --host 127.0.0.1 --port 27021 --username root --password rootpassword --authenticationDatabase admin --eval "
use testdb;
db.users.getShardDistribution()
"

# 5. 測試查詢路由
mongosh --host 127.0.0.1 --port 27021 --username root --password rootpassword --authenticationDatabase admin --eval "
use testdb;
print('Total documents: ' + db.users.countDocuments());
print('Sample document:');
db.users.findOne();
"

# 6. 檢查 Mongos 路由統計
mongosh --host 127.0.0.1 --port 27021 --username root --password rootpassword --authenticationDatabase admin --eval "
db.runCommand({serverStatus: 1}).sharding
"
```

## 📝 重要事項

### 數據持久化
所有 MongoDB 數據存儲在 `${HOME}/container-data/mongo/` 目錄：
- **單機**: `single/`
- **副本集**: `replica/primary/`, `replica/secondary1/`, `replica/secondary2/`
- **分片集群**: `sharded/config1-3/`, `sharded/shard1-1-3/`, `sharded/shard2-1-3/`

### 自動化功能
- **健康檢查**: 所有服務包含自動健康監控
- **依賴管理**: 節點按正確順序啟動，等待健康檢查通過
- **副本集初始化**: 自動配置和等待所有節點就緒
- **分片集群初始化**: 自動配置 Config Server、Shard 副本集和路由
- **錯誤處理**: 腳本包含重試機制和詳細日誌

### 清理和重建
```bash
# 停止所有服務
docker-compose down

# 清理數據目錄 (可選，會清除所有數據)
rm -rf ~/container-data/mongo

# 重新啟動
docker-compose --profile <mode> up -d
```

### 開發環境特點
- **統一認證**: root/rootpassword (僅適合開發)
- **MongoDB 7.0**: 穩定版本，支援最新特性
- **專用網路**: 服務間隔離通訊
- **現代工具**: 使用 mongosh 替代舊版 mongo 客戶端

## 🔧 故障排除

### 副本集連接問題
如果副本集初始化失敗：
```bash
# 檢查初始化日誌
docker-compose logs mongo-replica-init

# 手動重新初始化
docker-compose restart mongo-replica-init

# 檢查所有節點狀態
docker-compose ps
```

### 分片集群連接問題
如果分片集群初始化失敗：
```bash
# 檢查集群初始化日誌
docker-compose logs mongo-cluster-init

# 檢查各組件狀態
docker-compose ps | grep mongo

# 手動重新初始化
docker-compose restart mongo-cluster-init

# 檢查 Config Server 狀態
mongosh --host 127.0.0.1 --port 27022 --username root --password rootpassword --authenticationDatabase admin --eval "rs.status()"

# 檢查 Mongos 路由器狀態
mongosh --host 127.0.0.1 --port 27021 --username root --password rootpassword --authenticationDatabase admin --eval "sh.status()"
```

### 常見錯誤
- **端口衝突**: 確保端口 27017-27030 沒有被佔用
- **權限問題**: 確保 `~/container-data/mongo` 目錄可寫入
- **副本集問題**: 如果初始化失敗，清理數據目錄後重啟
- **分片集群問題**: 初始化順序很重要，確保所有組件都健康後再初始化
- **記憶體不足**: 分片集群需要較多記憶體，確保 Docker 有足夠資源
