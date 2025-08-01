# MongoDB Docker Compose - 連接 URL 總覽

## 🔗 各模式連接信息

### 1️⃣ 單機模式 (Single Instance)
```bash
# 啟動命令
docker-compose --profile single up -d

# 連接 URL
mongodb://root:rootpassword@127.0.0.1:27017/admin

# mongosh 連接命令
mongosh --host 127.0.0.1 --port 27017 --username root --password rootpassword --authenticationDatabase admin

# 連接測試
mongosh --host 127.0.0.1 --port 27017 --username root --password rootpassword --authenticationDatabase admin --eval "db.runCommand({ping:1})"
```

### 2️⃣ 副本集模式 (Replica Set)
```bash
# 啟動命令
docker-compose --profile replica up -d

# 連接 URL (Primary)
mongodb://root:rootpassword@127.0.0.1:27018/admin?replicaSet=rs0

# 連接 URL (所有節點)
mongodb://root:rootpassword@127.0.0.1:27018,127.0.0.1:27019,127.0.0.1:27020/admin?replicaSet=rs0

# mongosh 連接命令
mongosh --host 127.0.0.1 --port 27018 --username root --password rootpassword --authenticationDatabase admin

# 副本集狀態檢查
mongosh --host 127.0.0.1 --port 27018 --username root --password rootpassword --authenticationDatabase admin --eval "rs.status()"

# 節點信息
- Primary:    127.0.0.1:27018
- Secondary1: 127.0.0.1:27019  
- Secondary2: 127.0.0.1:27020
```

### 3️⃣ 分片集群模式 (Sharded Cluster)
```bash
# 啟動命令
docker-compose --profile sharded up -d

# 連接 URL (通過 Mongos 路由器)
mongodb://127.0.0.1:27021/admin

# mongosh 連接命令
mongosh --host 127.0.0.1 --port 27021

# 分片集群狀態檢查
mongosh --host 127.0.0.1 --port 27021 --eval "sh.status()"

# 集群組件端口映射
Mongos Router:     127.0.0.1:27021
Config Server 1:   127.0.0.1:27022
Config Server 2:   127.0.0.1:27023  
Config Server 3:   127.0.0.1:27024
Shard1 Node 1:     127.0.0.1:27025
Shard1 Node 2:     127.0.0.1:27026
Shard1 Node 3:     127.0.0.1:27027
Shard2 Node 1:     127.0.0.1:27028
Shard2 Node 2:     127.0.0.1:27029
Shard2 Node 3:     127.0.0.1:27030
```

## 🧪 測試命令範例

### 單機模式測試
```bash
mongosh --host 127.0.0.1 --port 27017 --username root --password rootpassword --authenticationDatabase admin --eval "
db.test.insertOne({name: 'single-mode', created: new Date()});
db.test.find().pretty();
"
```

### 副本集模式測試  
```bash
# 主節點寫入測試
mongosh --host 127.0.0.1 --port 27018 --username root --password rootpassword --authenticationDatabase admin --eval "
db.test.insertOne({name: 'replica-test', created: new Date(), node: 'primary'});
"

# 從節點讀取測試
mongosh --host 127.0.0.1 --port 27019 --username root --password rootpassword --authenticationDatabase admin --eval "
db.getMongo().setReadPref('secondary');
db.test.find({name: 'replica-test'}).pretty();
"
```

### 分片集群測試
```bash
# 啟用數據庫分片
mongosh --host 127.0.0.1 --port 27021 --eval "
sh.enableSharding('testdb');
sh.shardCollection('testdb.users', { '_id': 'hashed' });
"

# 插入測試數據
mongosh --host 127.0.0.1 --port 27021 --eval "
use testdb;
for(let i = 0; i < 1000; i++) {
  db.users.insertOne({
    userId: i,
    name: 'user' + i,
    email: 'user' + i + '@example.com',
    created: new Date()
  });
}
print('✓ Inserted 1000 documents');
"

# 檢查數據分佈
mongosh --host 127.0.0.1 --port 27021 --eval "
use testdb;
print('Total documents: ' + db.users.countDocuments());
db.users.getShardDistribution();
"
```

## 🔧 管理命令

### 停止所有服務
```bash
# 停止單機模式
docker-compose --profile single down

# 停止副本集模式  
docker-compose --profile replica down

# 停止分片集群模式
docker-compose --profile sharded down

# 停止所有模式
docker-compose down
```

### 清理數據
```bash
# 清理所有 MongoDB 數據
rm -rf ~/container-data/mongo/

# 清理 Docker 卷
docker volume prune
```

## 📊 性能特點

| 模式 | 容器數量 | 用途 | 特點 |
|------|----------|------|------|
| 單機模式 | 1 | 開發測試 | 輕量級、快速啟動 |
| 副本集模式 | 3 | 高可用測試 | 故障轉移、讀寫分離 |
| 分片集群模式 | 11 | 水平擴展 | 大數據支持、負載分散 |

## 🚀 實際應用場景

### 開發環境
- 使用單機模式進行日常開發
- 連接 URL: `mongodb://root:rootpassword@127.0.0.1:27017/admin`

### 測試環境  
- 使用副本集模式測試高可用性
- 連接 URL: `mongodb://root:rootpassword@127.0.0.1:27018,127.0.0.1:27019,127.0.0.1:27020/admin?replicaSet=rs0`

### 壓測環境
- 使用分片集群模式進行性能測試
- 連接 URL: `mongodb://127.0.0.1:27021/admin`