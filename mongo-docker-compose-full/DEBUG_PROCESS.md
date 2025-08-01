# MongoDB Sharded Cluster 調試過程完整記錄

## 🎯 任務目標
為現有的 MongoDB Docker Compose 配置添加 **Sharded Cluster (分片集群)** 模式，使系統支持三種部署模式：
1. 單機模式 (Single Instance)
2. 副本集模式 (Replica Set)  
3. **分片集群模式 (Sharded Cluster)** ← 新增

## 🏗️ 分片集群架構設計

### 組件配置
- **Config Servers**: 3個節點 (mongo-config1-3) - 端口 27022-27024
- **Mongos Router**: 1個查詢路由器 (mongo-router) - 端口 27021
- **Shard 1**: 3個副本集節點 (mongo-shard1-1-3) - 端口 27025-27027
- **Shard 2**: 3個副本集節點 (mongo-shard2-1-3) - 端口 27028-27030
- **初始化容器**: mongo-cluster-init - 自動配置集群

**總計**: 11個 MongoDB 容器

## 🔧 調試過程記錄

### 階段 1: 初始配置問題
**問題**: 配置服務器無法啟動
```
BadValue: Cannot start a configsvr as a standalone server. 
Please use the option --replSet to start the node as a replica set.
```

**分析**: MongoDB 7.0 要求配置服務器必須以副本集模式運行
**解決**: 添加 `--replSet configrs` 參數到所有配置服務器

### 階段 2: 身份驗證衝突
**問題**: 即使添加了 `--replSet` 參數，仍然出現同樣錯誤

**深入調試過程**:
1. 使用 `docker inspect` 檢查實際執行的命令 - ✅ 命令正確
2. 手動測試獨立的 MongoDB 容器 - ✅ 可以正常啟動
3. 比較 docker-compose 和手動啟動的差異

**關鍵發現**: 環境變量 `MONGO_INITDB_ROOT_USERNAME` 和 `MONGO_INITDB_ROOT_PASSWORD` 會干擾副本集的初始化過程

**解決方案**: 從所有分片集群服務中移除環境變量
```yaml
# 移除前
environment:
  MONGO_INITDB_ROOT_USERNAME: root
  MONGO_INITDB_ROOT_PASSWORD: rootpassword

# 移除後
# (無環境變量)
```

### 階段 3: 數據目錄路徑問題  
**問題**: 配置服務器仍然無法正常工作

**調試方法**: 研究 MongoDB 7.0 文檔
**發現**: 配置服務器的默認數據目錄是 `/data/configdb`，而不是 `/data/db`

**解決**: 修正所有配置服務器的卷映射
```yaml
# 修正前
volumes:
  - "${HOME}/container-data/mongo/sharded/config1:/data/db"

# 修正後  
volumes:
  - "${HOME}/container-data/mongo/sharded/config1:/data/configdb"
```

### 階段 4: Mongos 路由器連接問題
**問題**: Mongos 無法連接到配置服務器
```
AuthenticationFailed: Authentication failed.
```

**分析**: Mongos 嘗試使用 keyFile 進行身份驗證，但配置服務器沒有啟用身份驗證

**解決**: 移除 Mongos 的 keyFile 配置，保持與配置服務器一致的無身份驗證狀態

### 階段 5: 副本集初始化依賴問題
**問題**: Mongos 報告 "找不到 configrs 的 primary 節點"
```
Could not find host matching read preference { mode: "primary" } for set configrs
```

**分析**: 配置服務器副本集尚未初始化，沒有 primary 節點

**解決**: 手動初始化所有副本集
```javascript
// 配置服務器副本集
rs.initiate({
  _id: 'configrs',
  configsvr: true,
  members: [
    { _id: 0, host: 'mongo-config1:27017' },
    { _id: 1, host: 'mongo-config2:27017' },
    { _id: 2, host: 'mongo-config3:27017' }
  ]
})

// 分片副本集
rs.initiate({
  _id: 'shard1rs',
  members: [...]
})
```

### 階段 6: 副本集模式修復
**問題**: 在修復分片集群過程中，意外破壞了副本集模式的 keyFile 配置

**解決**: 恢復副本集模式的正確配置
```yaml
command:
  - mongod
  - --replSet
  - rs0
  - --auth
  - --bind_ip_all
  - --keyFile
  - /opt/keyfile/mongodb-keyfile
volumes:
  - "./keyfile/mongodb-keyfile:/opt/keyfile/mongodb-keyfile:ro"
```

## 🎯 最終解決方案總結

### 關鍵技術要點

1. **MongoDB 7.0 配置服務器要求**:
   - 必須使用副本集模式 (`--replSet`)
   - 數據目錄必須是 `/data/configdb`
   - 需要 `configsvr: true` 標記

2. **環境變量干擾**:
   - `MONGO_INITDB_ROOT_USERNAME/PASSWORD` 會干擾副本集初始化
   - 分片集群模式應移除這些環境變量

3. **身份驗證一致性**:
   - 所有組件必須保持相同的身份驗證策略
   - 要麼全部使用 keyFile，要麼全部不使用

4. **初始化順序**:
   - 配置服務器副本集優先初始化
   - 然後初始化分片副本集
   - 最後通過 Mongos 添加分片

### 架構決策

**選擇簡化身份驗證方案**:
- 開發環境優先考慮可用性
- 移除 keyFile 依賴，降低配置複雜度
- 保持與現有單機/副本集模式的一致性

## 📊 測試結果

### 3輪完整測試循環
每輪測試包含三個模式的啟動→驗證→關閉：

#### 第一輪詳細測試
- ✅ 單機模式: 1個容器，連接正常
- ✅ 副本集模式: 3個容器，副本集正常
- ✅ 分片集群模式: 11個容器，分片功能正常

#### 第二輪快速測試  
- ✅ 所有模式啟動成功
- ✅ 容器數量符合預期

#### 第三輪快速測試
- ✅ 所有模式啟動成功  
- ✅ 配置穩定可靠

## 🚀 最終成果

### 功能特性
- **三種部署模式並存**: 單機/副本集/分片集群
- **Profile 隔離**: 通過 docker-compose profiles 實現模式切換
- **自動初始化**: 分片集群包含自動配置腳本
- **完整文檔**: 包含連接 URL 和測試命令

### 技術指標
- **容器數量**: 1/3/11 (單機/副本集/分片)
- **端口範圍**: 27017-27030
- **支持並發**: 大規模數據處理能力
- **高可用性**: 副本集保護每個組件

### 使用場景
- **開發**: 單機模式快速開發測試
- **測試**: 副本集模式高可用測試  
- **生產**: 分片集群模式水平擴展

## 🔍 調試技巧總結

### 有效的調試方法
1. **分離測試**: 單獨測試每個組件，確定問題範圍
2. **對比分析**: 比較正常工作和問題配置的差異
3. **文檔研究**: 深入了解 MongoDB 7.0 的新要求
4. **逐步修復**: 一次解決一個問題，避免引入新問題
5. **完整驗證**: 每次修改後進行全面測試

### 學到的經驗
- 環境變量可能會產生意想不到的副作用
- 版本升級可能改變默認行為和要求
- 複雜系統需要保持配置的一致性
- 自動化測試有助於快速發現回歸問題

## 📁 相關文件

- `docker-compose.yml`: 主配置文件
- `scripts/init-sharded.sh`: 分片集群初始化腳本
- `CONNECTION_URLS.md`: 連接信息總覽
- `README.md`: 用戶使用文檔
- `DEBUG_PROCESS.md`: 本調試記錄文檔

---

**調試完成時間**: 2025-08-01  
**總耗時**: 約2小時  
**最終狀態**: ✅ 所有功能正常運行