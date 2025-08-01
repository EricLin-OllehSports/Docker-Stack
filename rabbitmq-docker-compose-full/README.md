# RabbitMQ Docker Compose - Complete Multi-Mode Setup

完整的 RabbitMQ 部署解決方案，支援三種部署模式：單節點、集群和高可用模式。

## 🚀 快速開始

```bash
# 單節點模式 (開發測試)
docker compose --profile single up -d

# 雙節點集群模式 (集群測試)
docker compose --profile cluster up -d

# 三節點HA模式 (生產環境)
docker compose --profile production up -d
```

## 📋 部署模式

| Profile | 服務 | 端口 | 用途 | 測試狀態 |
|---------|------|------|------|----------|
| `single` | rabbitmq-single | 5672, 15672 | 開發測試 | ✅ 已測試 |
| `cluster` | 2-node cluster | 5673-5674, 15673-15674 | 集群測試 | ✅ 已測試 |
| `production` | 3-node HA + HAProxy | 5672, 15672, 8404 | 生產環境 | ✅ 已測試 |

## 🔧 管理介面

- **單節點**: http://localhost:15672
- **集群**: http://localhost:15673 (node-1), http://localhost:15674 (node-2)
- **HA模式**: http://localhost:15672 (透過 HAProxy 負載均衡)
- **HAProxy統計**: http://localhost:8404/stats

**預設帳密**: admin / admin123

## 🛠️ 常用命令

```bash
# 查看可用 profiles
docker compose config --profiles

# 查看集群狀態
docker exec rabbitmq-cluster-1 rabbitmqctl cluster_status     # 集群模式
docker exec rabbitmq-ha-1 rabbitmqctl cluster_status         # HA模式

# 查看佇列狀態
docker exec rabbitmq-ha-1 rabbitmqctl list_queues name policy

# 停止指定模式
docker compose --profile single down
docker compose --profile cluster down
docker compose --profile production down

# 完全清理 (包含資料)
docker compose down -v --remove-orphans
```

## ⚙️ 配置

環境變數在 `.env` 檔案中配置：

```env
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=admin123
RABBITMQ_DEFAULT_VHOST=/
RABBITMQ_ERLANG_COOKIE=my-secret-cookie-for-cluster
COMPOSE_PROJECT_NAME=rabbitmq-cluster
```

## 📁 數據存儲

所有數據和日誌都存儲在 `${HOME}/container-data/rabbitmq/` 目錄下：

```
${HOME}/container-data/rabbitmq/
├── single/
│   ├── data/         # 單節點數據
│   └── logs/         # 單節點日誌
├── cluster/
│   ├── node-1/       # 集群節點1
│   └── node-2/       # 集群節點2
└── ha-cluster/
    ├── node-1/       # HA節點1
    ├── node-2/       # HA節點2
    └── node-3/       # HA節點3
```

## 🧪 測試結果

### 單節點模式 (single)
✅ **成功測試** - 完整功能驗證
- 服務啟動正常
- 管理介面可訪問
- AMQP 連接正常
- 資料持久化正常

### 雙節點集群模式 (cluster)  
✅ **成功測試** - 集群功能驗證
- 兩節點自動組建集群
- 集群狀態正常
- 節點間數據同步
- 管理介面均可訪問

### 三節點HA模式 (production)
✅ **成功測試** - 高可用性完整驗證
- 三節點自動組建HA集群
- HAProxy負載均衡正常
- HA策略自動配置 (`ha-mode: all`)
- 故障轉移測試通過
- 節點恢復後自動重新加入集群
- 所有介面透過HAProxy正常訪問

### HAProxy 負載均衡驗證
✅ **功能完整**
- AMQP負載均衡 (port 5672)
- 管理介面負載均衡 (port 15672)
- 健康檢查正常
- 統計介面可訪問 (port 8404)
- 故障節點自動剔除，恢復後自動加入

## 📊 特性

- ✅ Docker Compose Profiles 控制
- ✅ 三種部署模式切換
- ✅ 自動集群組建
- ✅ HAProxy 負載均衡與故障轉移
- ✅ 健康檢查與依賴管理
- ✅ 數據持久化
- ✅ HA 策略自動配置
- ✅ 完整的錯誤處理與重試機制

## 🔍 故障排除

### 集群組建失敗
```bash
# 檢查日誌
docker logs rabbitmq-cluster-2
docker logs rabbitmq-ha-2

# 檢查 Erlang Cookie
docker exec rabbitmq-ha-1 cat /var/lib/rabbitmq/.erlang.cookie
```

### HAProxy 連接問題
```bash
# 檢查 HAProxy 狀態
curl http://localhost:8404/stats

# 檢查後端節點健康狀態
docker exec rabbitmq-haproxy cat /proc/net/tcp
```

### 資料持久化問題
```bash
# 檢查掛載目錄權限
ls -la ${HOME}/container-data/rabbitmq/

# 手動清理資料 (慎用)
rm -rf ${HOME}/container-data/rabbitmq/
```