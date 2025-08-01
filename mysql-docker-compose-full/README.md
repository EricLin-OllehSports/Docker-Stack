# MySQL Docker Compose - Development Environment

本專案提供 MySQL 8.2 的兩種部署模式，適合本機開發和測試環境：**單機 (single)** 和 **主從複製 (replication)**。

## 🏗️ 目錄結構
```
.
├── docker-compose.yml          # 主配置文件 (統一管理兩種模式)
├── README.md                   # 使用說明和測試指令
└── scripts/                    # 初始化腳本
    ├── init-master.sql         # Master 複寫用戶設定
    ├── init-slave.sh           # Slave 自動配置腳本
    └── start-slave.sh          # Slave 容器啟動腳本
```

## 🚀 快速啟動

### 1️⃣ 單機模式 (開發測試)
```bash
docker-compose --profile single up -d
```
- **端口**: 3306
- **用途**: 日常開發、功能測試
- **特點**: 輕量級、快速啟動

### 2️⃣ 主從複製模式 (複寫測試)
```bash
docker-compose --profile replication up -d
```
- **端口**: Master 3307, Slave 3308
- **用途**: 複寫機制測試、讀寫分離測試
- **特點**: 自動配置 GTID 複寫

### 🔄 啟動所有模式 (演示用)
```bash
docker-compose up -d
```

## 🧪 測試指令

### 單機模式測試
```bash
# 連接測試
mysql -h 127.0.0.1 -P 3306 -u sa -psa -e "SHOW DATABASES;"

# 建立測試表
mysql -h 127.0.0.1 -P 3306 -u sa -psa -e "
CREATE TABLE ollehsports.users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"
```

### 主從複製測試
```bash
# 1. 在 Master 建立測試數據
mysql -h 127.0.0.1 -P 3307 -u root -proot -e "
CREATE TABLE ollehsports.test (
  id INT PRIMARY KEY AUTO_INCREMENT, 
  msg VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO ollehsports.test (msg) VALUES ('Hello from Master');
"

# 2. 檢查 Slave 複寫狀態
mysql -h 127.0.0.1 -P 3308 -u root -proot -e "SHOW SLAVE STATUS\G" | grep -E "(Running|Error)"

# 3. 驗證 Slave 數據同步
mysql -h 127.0.0.1 -P 3308 -u root -proot -e "SELECT * FROM ollehsports.test;"

# 4. 測試讀寫分離 (Slave 只讀)
mysql -h 127.0.0.1 -P 3308 -u root -proot -e "INSERT INTO ollehsports.test (msg) VALUES ('test');" 2>&1 | head -1
```

## 📝 重要事項

### 數據持久化
所有 MySQL 數據存儲在 `${HOME}/container-data/mysql/` 目錄：
- **單機**: `single/`
- **主從**: `master/`, `slave/`

### 自動化功能
- **健康檢查**: 所有服務包含自動健康監控
- **依賴管理**: Slave 等待 Master 健康後啟動
- **GTID 複寫**: 自動配置基於位置的複寫
- **錯誤處理**: 腳本包含重試機制和詳細日誌

### 清理和重建
```bash
# 停止所有服務
docker-compose down

# 清理數據目錄 (可選，會清除所有數據)
rm -rf ~/container-data/mysql

# 重新啟動
docker-compose --profile <mode> up -d
```

### 開發環境特點
- **簡單密碼**: root/root, sa/sa (僅適合開發)
- **UTF8MB4**: 預設支援完整 Unicode
- **複寫容錯**: 開啟錯誤跳過 (僅開發環境)
- **專用網路**: 服務間隔離通訊
