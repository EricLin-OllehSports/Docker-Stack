# NGINX Docker Compose - Complete Configuration

全功能 NGINX Docker Compose 配置，包含 HA 模式、負載均衡、SSL 終止、API Gateway 等完整範例。

## 🏗️ 架構概覽

### High Availability (HA) 模式
- **HAProxy** 作為前端負載均衡器
- **3個 NGINX 實例** 提供高可用性
- **健康檢查** 和自動故障轉移
- **會話持久性** 支援

### 支援的使用場景

1. **靜態網站伺服器** - 高效能靜態資源服務
2. **反向代理** - 後端服務代理與負載分散
3. **負載均衡器** - 多後端服務負載均衡
4. **SSL 終止** - SSL/TLS 加密終止處理
5. **API Gateway** - 完整的 API 閘道功能
6. **內容改寫與路由** - 智能內容處理和路由
7. **Sidecar 模式** - 微服務網格支援

## 🚀 快速開始

### 基本模式（單一 NGINX）
```bash
# 靜態網站
docker-compose --profile static-site up -d

# 反向代理
docker-compose --profile reverse-proxy up -d

# 預設模式
docker-compose --profile default up -d
```

### HA 模式（高可用性）
```bash
# 啟動 HA 模式（HAProxy + 3x NGINX）
docker-compose --profile ha up -d

# 檢查服務狀態
docker-compose --profile ha ps

# 查看 HAProxy 統計
open http://localhost:8404/stats
```

### 監控模式
```bash
# 啟動監控和日誌收集
docker-compose --profile monitoring --profile logging up -d

# 檢查 NGINX 指標
curl http://localhost:9113/metrics
```

## 📁 目錄結構

```
nginx-docker-compose-full/
├── docker-compose.yml          # 主要 compose 配置
├── haproxy/
│   └── haproxy.cfg            # HAProxy 負載均衡配置
├── nginx/
│   ├── nginx.conf             # 主要 NGINX 配置
│   ├── ssl/                   # SSL 證書目錄
│   ├── html/                  # 靜態網站文件
│   ├── backend-apps/          # 後端應用範例
│   └── conf.d/                # 虛擬主機配置
│       ├── 01-static-site.conf      # 靜態網站配置
│       ├── 02-reverse-proxy.conf    # 反向代理配置
│       ├── 03-load-balancer.conf    # 負載均衡配置
│       ├── 04-ssl-termination.conf  # SSL 終止配置
│       ├── 05-api-gateway.conf      # API Gateway 配置
│       ├── 06-content-rewrite-routing.conf  # 內容改寫路由
│       └── 07-sidecar-internal.conf # Sidecar 內部配置
├── fluent-bit/
│   └── fluent-bit.conf        # 日誌收集配置
└── README.md                  # 本文件
```

## 🔧 配置範例

### 1. 靜態網站伺服器
- **功能**: 高效能靜態資源服務
- **特色**: 
  - Gzip 壓縮
  - 瀏覽器快取優化
  - 安全頭設置
  - HTTPS 強制重定向

```nginx
# 範例配置片段
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### 2. 反向代理
- **功能**: 後端服務代理與負載分散
- **特色**:
  - WebSocket 支援
  - 健康檢查
  - 會話持久性
  - CORS 支援

### 3. 負載均衡器
- **功能**: 多後端服務負載均衡
- **演算法**: round_robin, least_conn, ip_hash, hash
- **特色**:
  - 故障轉移
  - 連接池
  - 會話親和性

### 4. SSL 終止
- **功能**: SSL/TLS 加密終止處理
- **特色**:
  - TLS 1.2/1.3 支援
  - OCSP Stapling
  - HSTS 安全頭
  - 用戶端證書驗證

### 5. API Gateway
- **功能**: 完整的 API 閘道功能
- **特色**:
  - 認證授權
  - 速率限制
  - API 版本控制
  - 請求轉換

### 6. 內容改寫與路由
- **功能**: 智能內容處理和路由
- **特色**:
  - 地理位置路由
  - 設備檢測
  - A/B 測試
  - URL 重寫

### 7. Sidecar 內部模式
- **功能**: 微服務網格支援
- **特色**:
  - 服務發現
  - 內部通信
  - 分散式追蹤
  - 斷路器模式

## 🎯 使用場景

### 開發環境
```bash
# 基本開發模式
docker-compose --profile default up -d
```

### 測試環境
```bash
# 負載均衡測試
docker-compose --profile reverse-proxy up -d
```

### 生產環境
```bash
# 高可用性部署
docker-compose --profile ha --profile monitoring up -d
```

## 🔐 SSL 設置

### 生成自簽證書（開發用）
```bash
# 建立 SSL 目錄
mkdir -p nginx/ssl

# 生成自簽證書
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/example.com.key \
  -out nginx/ssl/example.com.crt \
  -subj "/CN=example.com"
```

### Let's Encrypt 證書（生產用）
```bash
# 安裝 certbot
sudo apt-get install certbot

# 獲取證書
sudo certbot certonly --webroot -w nginx/html -d example.com
```

## 📊 監控與日誌

### 監控端點
- **HAProxy 統計**: http://localhost:8404/stats
- **NGINX 狀態**: http://localhost:8080/nginx_status
- **健康檢查**: http://localhost/health
- **Prometheus 指標**: http://localhost:9113/metrics

### 日誌位置
- **NGINX 訪問日誌**: `/var/log/nginx/access.log`
- **NGINX 錯誤日誌**: `/var/log/nginx/error.log`
- **HAProxy 日誌**: `/var/log/haproxy/haproxy.log`

## 🔧 性能調優

### NGINX 調優
```nginx
worker_processes auto;
worker_connections 4096;
keepalive_timeout 65;
gzip on;
gzip_comp_level 6;
```

### HAProxy 調優
```
maxconn 4096
timeout connect 5s
timeout client 50s
timeout server 50s
```

## 🛡️ 安全配置

### 安全頭設置
```nginx
add_header X-Frame-Options "DENY" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Strict-Transport-Security "max-age=31536000" always;
```

### 速率限制
```nginx
limit_req_zone $binary_remote_addr zone=general:10m rate=1r/s;
limit_req zone=general burst=10 nodelay;
```

## 🚨 故障排除

### 常見問題

1. **連接被拒絕**
   ```bash
   # 檢查服務狀態
   docker-compose ps
   
   # 查看日誌
   docker-compose logs nginx
   ```

2. **SSL 證書錯誤**
   ```bash
   # 檢查證書
   openssl x509 -in nginx/ssl/example.com.crt -text -noout
   ```

3. **負載均衡不工作**
   ```bash
   # 檢查後端服務
   curl -H "Host: app.example.com" http://localhost/health
   ```

## 📚 更多資源

- [NGINX 官方文檔](https://nginx.org/en/docs/)
- [HAProxy 文檔](http://www.haproxy.org/#docs)
- [Docker Compose 參考](https://docs.docker.com/compose/)

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request 來改進這個配置範例。

## 📄 授權

MIT License - 詳見 LICENSE 文件