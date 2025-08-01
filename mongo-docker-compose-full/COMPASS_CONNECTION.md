# MongoDB Compass 連接指南

## 🧭 **各模式 Compass 連接配置**

### ✅ **1. 單機模式**
```
Connection Type: Individual Server
Host: 127.0.0.1
Port: 27017
Authentication: Username / Password
Username: root
Password: rootpassword
Authentication Database: admin
```

### ✅ **2. 副本集模式**

#### 🔧 **解決方案 A: 連接 Primary 節點（推薦）**

**MongoDB Compass 1.46.3 URI 連接（最簡單）**：
```
mongodb://root:rootpassword@127.0.0.1:27018/admin?directConnection=true
```

**MongoDB Compass 表單連接**：
```
Connection Type: Individual Server
Host: 127.0.0.1
Port: 27018
Authentication: Username / Password
Username: root
Password: rootpassword
Authentication Database: admin
Read Preference: Primary
SSL: Off
Advanced Options: directConnection=true
```

**為什麼選擇這種方式？**
- ✅ 簡單可靠，立即可用
- ✅ 使用 `directConnection=true` 避免自動發現問題
- ✅ 無需修改系統 hosts 文件
- ✅ 仍然享受副本集的數據安全性
- ✅ 避免端口映射衝突

#### 🔧 **解決方案 B: 添加主機名映射（完整副本集體驗）**

**當出現 `getaddrinfo ENOTFOUND mongo-primary` 錯誤時，這是必需的解決方案**

1. **一鍵添加主機名映射**
   ```bash
   sudo bash -c 'cat >> /etc/hosts << EOF
   127.0.0.1 mongo-primary
   127.0.0.1 mongo-secondary1
   127.0.0.1 mongo-secondary2
   EOF'
   ```

2. **驗證映射是否生效**
   ```bash
   ping mongo-primary -c 1
   ping mongo-secondary1 -c 1
   ping mongo-secondary2 -c 1
   ```

3. **在 MongoDB Compass 1.46.3 中使用 URI 連接**
   ```
   mongodb://root:rootpassword@mongo-primary:27018,mongo-secondary1:27019,mongo-secondary2:27020/admin?replicaSet=rs0
   ```

   **或使用表單連接**：
   ```
   Connection Type: Replica Set
   Replica Set Name: rs0
   Hosts: mongo-primary:27018,mongo-secondary1:27019,mongo-secondary2:27020
   Authentication: Username / Password
   Username: root
   Password: rootpassword
   Authentication Database: admin
   ```

### ✅ **3. 分片集群模式**
```
Connection Type: Individual Server
Host: 127.0.0.1
Port: 27021
Authentication: None (無需認證)
```

## 🔍 **連接測試**

### 測試副本集連接
```bash
# 測試 Primary 節點
mongosh --host 127.0.0.1 --port 27018 --username root --password rootpassword --authenticationDatabase admin --eval "db.runCommand({ping: 1})"

# 測試副本集狀態
mongosh --host 127.0.0.1 --port 27018 --username root --password rootpassword --authenticationDatabase admin --eval "rs.status().members.length"
```

### 測試分片集群連接
```bash
# 測試 Mongos 路由器
mongosh --host 127.0.0.1 --port 27021 --eval "sh.status()"
```

## 🎯 **推薦連接方式**

### 開發階段
- **單機模式**: 用於快速開發和測試
- **連接**: `127.0.0.1:27017`

### 測試階段  
- **副本集模式**: 測試數據安全性和讀寫分離
- **連接**: `127.0.0.1:27018` (Primary 節點)

### 性能測試階段
- **分片集群模式**: 測試水平擴展能力
- **連接**: `127.0.0.1:27021` (Mongos 路由器)

## 🛠️ **常見連接問題**

### 問題 1: "MongoNetworkError: getaddrinfo ENOTFOUND mongo-primary"
- **原因**: 副本集使用內部主機名（mongo-primary, mongo-secondary1, mongo-secondary2），外部無法解析
- **現象**: 使用完整副本集連接字符串 `mongodb://root:rootpassword@127.0.0.1:27018,127.0.0.1:27019,127.0.0.1:27020/admin?replicaSet=rs0` 時失敗
- **解決**: 使用解決方案 A 直接連接 Primary 節點 `127.0.0.1:27018`

### 問題 2: "Server selection timed out"
- **原因**: 網絡連接問題或服務未啟動
- **解決**: 檢查容器狀態 `docker-compose --profile replica ps`

### 問題 3: "Authentication failed"  
- **檢查**: 用戶名密碼和認證數據庫
- **副本集**: `root/rootpassword@admin`
- **分片集群**: 無需認證

### 問題 4: "No primary available"
- **檢查**: 副本集狀態
- **命令**: `rs.status()`
- **解決**: 等待選舉完成或重啟副本集

## 📊 **Compass 中的功能探索**

連接成功後，您可以：

1. **數據瀏覽**
   - 查看 `test.compass_demo` 集合
   - 實時編輯文檔

2. **性能監控**  
   - 查看實時性能指標
   - 分析慢查詢

3. **索引管理**
   - 查看現有索引
   - 創建優化索引

4. **聚合管道**
   - 可視化構建聚合查詢
   - 調試管道階段

## 🚀 **測試數據**

如果需要測試數據，可以執行：

```bash
# 插入示例數據
mongosh --host 127.0.0.1 --port 27018 --username root --password rootpassword --authenticationDatabase admin --eval "
db.compass_demo.insertMany([
  {name: 'Alice', age: 30, city: 'New York', salary: 75000, department: 'Engineering'},
  {name: 'Bob', age: 25, city: 'San Francisco', salary: 85000, department: 'Design'},
  {name: 'Charlie', age: 35, city: 'Chicago', salary: 70000, department: 'Marketing'},
  {name: 'Diana', age: 28, city: 'Seattle', salary: 90000, department: 'Engineering'},
  {name: 'Eve', age: 32, city: 'Boston', salary: 78000, department: 'Sales'}
]);
print('✓ 測試數據已插入');
"
```

現在您應該能夠成功連接到 MongoDB Compass 了！🎉