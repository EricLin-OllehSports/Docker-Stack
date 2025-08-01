# Another Redis Desktop Manager 連接配置指南

## 🔧 **各種 Redis 部署模式的連接配置**

### 1️⃣ **Redis 單機模式 (Standalone)**

**連接設定**：
```
Connection Name: Redis Single
Host: 127.0.0.1
Port: 6379
Auth: (如果有密码填入)
Connection Timeout: 60 seconds
Execution Timeout: 60 seconds
```

**測試命令**：
```bash
# 啟動單機 Redis
docker run -d --name redis-single -p 6379:6379 redis:7.0

# 測試連接
redis-cli -h 127.0.0.1 -p 6379 ping
```

---

### 2️⃣ **Redis 主從複製模式 (Master-Slave)**

#### 主節點連接
```
Connection Name: Redis Master
Host: 127.0.0.1
Port: 6379
Auth: (密码)
Connection Type: Standalone
```

#### 從節點連接（只讀）
```
Connection Name: Redis Slave 1
Host: 127.0.0.1
Port: 6380
Auth: (密码)
Connection Type: Standalone
Read Only: ✅ (勾選)
```

```
Connection Name: Redis Slave 2
Host: 127.0.0.1
Port: 6381
Auth: (密码)
Connection Type: Standalone
Read Only: ✅ (勾選)
```


---

### 3️⃣ **Redis 集群模式 (Cluster)**

**集群連接設定**：
```
Connection Name: Redis Cluster
Connection Type: Cluster ← 重要！必須選 Cluster
Cluster Nodes:
  - 127.0.0.1:7001
  - 127.0.0.1:7002
  - 127.0.0.1:7003

Auth: (留空，如果沒有密碼)
Connection Timeout: 60 seconds
Execution Timeout: 60 seconds
```

**重要設定**：
- ✅ Connection Type 必須選 "Cluster"
- ✅ 勾選 "Auto discover cluster nodes"
- ✅ 可以只添加一個節點 (127.0.0.1:7001)，ARDM 會自動發現其他節點
- 當前端口：7001-7003 (3 master 節點)

**ARDM 設定步驟**：
1. 新建連接 → Connection Type: **Cluster**
2. 添加節點：127.0.0.1:7001 (可選添加 7002, 7003)
3. 測試連接 → 成功後會顯示集群拓撲
4. 保存連接

**集群功能**：
- 📊 集群拓撲圖顯示
- 🔄 自動命令路由 
- 📈 實時節點監控
- 🗂️ Slot 分佈查看 (0-5460, 5461-10922, 10923-16383)

---

### 4️⃣ **Redis Sentinel 模式**

**⚠️ 重要提示**: 由於 Docker 網絡限制，ARDM 連接 Sentinel 可能會遇到問題。推薦使用以下解決方案：

#### 解決方案 A: 直接連接 Redis 實例（推薦）
```
連接 1 - Sentinel Master:
Connection Name: Redis Sentinel Master
Connection Type: Standalone
Host: 127.0.0.1
Port: 6382
Auth: (密码，如果有)
Connection Timeout: 60 seconds

連接 2 - Sentinel Slave:
Connection Name: Redis Sentinel Slave  
Connection Type: Standalone
Host: 127.0.0.1
Port: 6383
Read Only: ✅ (勾選)
Connection Timeout: 60 seconds
```

#### 解決方案 B: Sentinel 連接（可能需要額外配置）
```
Connection Name: Redis Sentinel
Connection Type: Sentinel
Sentinel Hosts:
  - 127.0.0.1:26379

Master Name: mymaster
Auth: (密码)
Connection Timeout: 60 seconds
```

**如果 Sentinel 連接失敗，常見原因**：
- Sentinel 返回內部 Docker IP (如 192.168.x.x)
- ARDM 無法解析內部 Docker 網絡地址
- **建議使用解決方案 A 直接連接**

---

## 🔍 **Another Redis Desktop Manager 操作技巧**

### 基本功能
1. **數據瀏覽**: 查看各種 Redis 數據類型
2. **即時編輯**: 直接修改 key-value
3. **命令行**: 內建 Redis CLI
4. **性能監控**: 實時監控 Redis 狀態
5. **批量操作**: 批量導入/導出數據

### 高級功能
1. **SSH 隧道**: 通過 SSH 連接遠程 Redis
2. **SSL/TLS**: 加密連接支持
3. **慢日誌分析**: 查看慢查詢
4. **內存分析**: 分析內存使用情況
5. **發布/訂閱**: 測試 pub/sub 功能

---

## 🚀 **連接測試命令**

### 測試單機連接
```bash
redis-cli -h 127.0.0.1 -p 6379 ping
redis-cli -h 127.0.0.1 -p 6379 info replication
```

### 測試集群連接
```bash
redis-cli -c -h 127.0.0.1 -p 7000 cluster info
redis-cli -c -h 127.0.0.1 -p 7000 cluster nodes
```

### 測試 Sentinel 連接
```bash
redis-cli -h 127.0.0.1 -p 26379 sentinel masters
redis-cli -h 127.0.0.1 -p 26379 sentinel slaves mymaster
```

---

## 🛠️ **故障排除**

### 常見問題

#### 1. Sentinel 連接超時 (您的問題)
**現象**: ARDM 連接 Sentinel 時出現 timeout
**原因**: Sentinel 返回內部 Docker IP，ARDM 無法訪問
**解決方案**: 
- ✅ 使用**解決方案 A** 直接連接 127.0.0.1:6382 (Master) 和 127.0.0.1:6383 (Slave)
- 或使用端口映射修正 Sentinel 配置

#### 2. 一般連接超時
- 檢查防火牆設定
- 確認端口映射正確
- 驗證 Redis 服務狀態

#### 3. 認證失敗
- 確認密碼正確
- 檢查 AUTH 設定
- 驗證 ACL 規則（Redis 6+）

#### 4. "Stream On Error: Connection is closed" (集群模式)
**現象**: ARDM 連接集群時出現連接關閉錯誤
**原因**: ARDM 版本兼容性問題或連接設定問題
**解決方案**:
- ✅ 先用 Standalone 模式測試單個節點 (127.0.0.1:7001)
- ✅ 調整 Connection/Execution Timeout 為 30 秒
- ✅ 取消勾選 "Auto discover cluster nodes"
- ✅ 或創建 3 個獨立的 Standalone 連接

#### 5. 集群節點發現失敗
- 確認所有節點都可訪問
- 檢查集群配置
- 驗證節點間通信

#### 5. Sentinel 主從切換問題
- 檢查 Sentinel 配置
- 確認法定人數設定
- 驗證網絡連通性

---

## 📊 **推薦連接配置**

| 模式 | 適用場景 | 連接類型 | 端口範圍 |
|------|----------|----------|----------|
| 單機 | 開發測試 | Standalone | 6379 |
| 主從 | 讀寫分離 | Standalone × 3 | 6379-6381 |
| 集群 | 高可用 + 分片 | Cluster | 7000-7005 |
| Sentinel | 高可用 + 故障轉移 | Sentinel | 26379-26381 |

現在您可以根據您的 Redis 部署模式，在 Another Redis Desktop Manager 中進行相應的連接配置了！🎉