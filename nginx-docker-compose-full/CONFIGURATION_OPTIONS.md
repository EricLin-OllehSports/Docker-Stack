# NGINX Docker Compose - 配置選項詳細說明

## 📋 目錄
- [Docker Compose 配置選項](#docker-compose-配置選項)
- [NGINX 主配置選項](#nginx-主配置選項)
- [HAProxy 配置選項](#haproxy-配置選項)
- [環境變數參考](#環境變數參考)
- [部署模式選擇](#部署模式選擇)
- [性能調優建議](#性能調優建議)

## Docker Compose 配置選項

### 🐳 容器映像選擇

#### NGINX 映像選項
```yaml
# 輕量級 Alpine 版本 (推薦)
image: nginx:1.25-alpine     # 穩定版，體積小
image: nginx:mainline-alpine # 最新功能
image: nginx:stable-alpine   # 長期支援版

# 完整 Debian 版本
image: nginx:1.25           # 更多工具，體積較大
image: nginx:latest         # 最新版本
```

#### HAProxy 映像選項
```yaml
image: haproxy:2.8-alpine   # LTS 版本 (推薦)
image: haproxy:2.9-alpine   # 最新穩定版
image: haproxy:lts-alpine   # 長期支援
```

### 🔌 網路配置選項

#### 網路驅動選擇
```yaml
networks:
  nginx-network:
    driver: bridge     # 預設，適用單機
    driver: overlay    # 適用 Docker Swarm
    driver: host       # 直接使用主機網路
    driver: macvlan    # 為容器分配 MAC 地址
```

#### 進階網路配置
```yaml
networks:
  nginx-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
    driver_opts:
      com.docker.network.bridge.name: nginx-br
      com.docker.network.bridge.enable_icc: "true"
```

### 💾 存儲卷選項

#### 卷驅動類型
```yaml
volumes:
  nginx-logs:
    driver: local        # 本地存儲 (預設)
    driver: nfs          # NFS 網路存儲
    driver: rexray       # REX-Ray 插件
```

#### 綁定掛載配置
```yaml
volumes:
  - type: bind
    source: ./nginx/conf.d
    target: /etc/nginx/conf.d
    bind:
      propagation: rprivate
  - type: volume
    source: nginx-logs
    target: /var/log/nginx
    volume:
      nocopy: true
```

### 🚀 部署配置選項

#### 重啟策略選擇
```yaml
restart: no               # 不自動重啟
restart: always          # 總是重啟
restart: on-failure      # 失敗時重啟
restart: unless-stopped  # 除非手動停止 (推薦)
```

#### 健康檢查配置
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost/health"]
  interval: 30s      # 檢查間隔: 10s-300s
  timeout: 10s       # 超時時間: 1s-60s
  retries: 3         # 重試次數: 1-5
  start_period: 60s  # 啟動寬限期: 0s-300s
  disable: true      # 禁用健康檢查
```

## NGINX 主配置選項

### ⚙️ 全域設定

#### Worker 進程配置
```nginx
# Worker 進程數量選項
worker_processes auto;     # 自動檢測 CPU 核心數 (推薦)
worker_processes 1;        # 單核或低負載
worker_processes 4;        # 四核 CPU
worker_processes 8;        # 高性能伺服器

# Worker 連接數配置
worker_connections 1024;   # 預設，適用一般網站
worker_connections 4096;   # 高流量網站 (推薦)
worker_connections 8192;   # 極高負載
```

#### 記憶體和檔案限制
```nginx
# 檔案描述符限制
worker_rlimit_nofile 65535;    # 高負載 (推薦)
worker_rlimit_nofile 8192;     # 中等負載
worker_rlimit_nofile 1024;     # 低負載

# 用戶端請求體大小
client_max_body_size 1M;       # 小檔案上傳
client_max_body_size 16M;      # 一般檔案上傳 (推薦)
client_max_body_size 100M;     # 大檔案上傳
client_max_body_size 1G;       # 超大檔案上傳
```

### 🔒 安全配置選項

#### SSL/TLS 協議版本
```nginx
ssl_protocols TLSv1.2;                    # 基本安全
ssl_protocols TLSv1.2 TLSv1.3;          # 推薦配置
ssl_protocols TLSv1.3;                   # 僅最新協議
```

#### 加密套件選擇
```nginx
# 現代瀏覽器 (推薦)
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;

# 相容舊瀏覽器
ssl_ciphers HIGH:!aNULL:!MD5;

# 最高安全性
ssl_ciphers ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256;
```

### 📊 效能調優選項

#### 快取配置
```nginx
# 開放檔案快取
open_file_cache max=1000 inactive=20s;     # 一般網站
open_file_cache max=10000 inactive=60s;    # 高流量網站
open_file_cache off;                       # 禁用快取

# 快取驗證
open_file_cache_valid 30s;     # 30秒重新驗證
open_file_cache_valid 300s;    # 5分鐘重新驗證
```

#### 壓縮設定
```nginx
# 壓縮等級選擇
gzip_comp_level 1;    # 最快壓縮，最低比率
gzip_comp_level 6;    # 平衡效能與壓縮比 (推薦)
gzip_comp_level 9;    # 最高壓縮比，最慢速度

# 壓縮最小檔案大小
gzip_min_length 20;      # 極小檔案也壓縮
gzip_min_length 1000;    # 推薦設定
gzip_min_length 10240;   # 僅壓縮較大檔案
```

### 🛡️ 安全頭配置選項

```nginx
# X-Frame-Options 選項
add_header X-Frame-Options "DENY";                    # 完全禁止框架
add_header X-Frame-Options "SAMEORIGIN";              # 僅允許同源框架
add_header X-Frame-Options "ALLOW-FROM https://trusted.com"; # 允許特定來源

# Content-Security-Policy 選項
add_header Content-Security-Policy "default-src 'self'";                        # 嚴格策略
add_header Content-Security-Policy "default-src 'self' 'unsafe-inline'";       # 允許內聯腳本
add_header Content-Security-Policy "default-src 'self'; script-src 'self' https://cdnjs.cloudflare.com"; # 允許 CDN

# HSTS 選項
add_header Strict-Transport-Security "max-age=31536000";                     # 基本 HSTS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains"; # 包含子網域
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"; # 預載入清單
```

## HAProxy 配置選項

### ⚖️ 負載均衡算法

```haproxy
# 負載均衡演算法選擇
balance roundrobin    # 輪詢 (預設)
balance leastconn     # 最少連接 (推薦動態內容)
balance source        # 來源 IP 雜湊
balance uri           # URI 雜湊
balance hdr(Host)     # 基於 HTTP 頭
balance rdp-cookie    # RDP Cookie
balance first         # 第一個可用伺服器
```

### 🏥 健康檢查選項

```haproxy
# 健康檢查配置
option httpchk GET /health                    # HTTP 健康檢查
option httpchk GET /health HTTP/1.1\r\nHost:\ example.com  # 帶 Host 頭
option tcp-check                              # TCP 連接檢查
option ssl-hello-chk                          # SSL 握手檢查

# 檢查參數
check inter 2000ms    # 檢查間隔: 1000-10000ms
check rise 2          # 恢復需要的成功次數: 1-5
check fall 3          # 失敗需要的錯誤次數: 1-10
```

### 🔧 超時配置選項

```haproxy
# 連接超時選項
timeout connect 5000      # 連接後端超時: 1000-10000ms
timeout client 50000      # 用戶端超時: 10000-300000ms
timeout server 50000      # 伺服器回應超時: 10000-300000ms

# 特殊超時
timeout http-request 10s   # HTTP 請求超時
timeout http-keep-alive 2s # Keep-alive 超時
timeout check 10s          # 健康檢查超時
timeout tunnel 3600s       # WebSocket/隧道超時
```

## 環境變數參考

### 🌍 核心環境變數

```bash
# 網域配置
DOMAIN=example.com
STATIC_DOMAIN=static.example.com
API_DOMAIN=api.example.com

# 連接埠配置
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
HAPROXY_STATS_PORT=8404

# 效能配置
WORKER_PROCESSES=auto
WORKER_CONNECTIONS=4096
CLIENT_MAX_BODY_SIZE=16M

# 安全配置
SSL_PROTOCOLS="TLSv1.2 TLSv1.3"
LOG_LEVEL=warn

# 快取配置
GZIP_ENABLED=on
GZIP_COMP_LEVEL=6
KEEPALIVE_TIMEOUT=65
```

### 📊 監控和記錄變數

```bash
# 記錄配置
ACCESS_LOG_FORMAT=json_combined
ERROR_LOG_LEVEL=warn
FLUENT_LOG_LEVEL=info

# 監控配置
PROMETHEUS_METRICS_PORT=9113
FLUENT_HTTP_PORT=2020
HEALTH_CHECK_INTERVAL=30s
```

## 部署模式選擇

### 🎯 使用場景對應

#### 開發環境
```bash
# 單一 NGINX 實例
docker-compose --profile default up -d

# 推薦環境變數
WORKER_PROCESSES=1
WORKER_CONNECTIONS=1024
LOG_LEVEL=debug
GZIP_COMP_LEVEL=1
```

#### 測試環境
```bash
# 負載均衡測試
docker-compose --profile reverse-proxy up -d

# 推薦環境變數
WORKER_PROCESSES=2
WORKER_CONNECTIONS=2048
LOG_LEVEL=info
CLIENT_MAX_BODY_SIZE=50M
```

#### 生產環境
```bash
# 高可用性部署
docker-compose --profile ha --profile monitoring up -d

# 推薦環境變數
WORKER_PROCESSES=auto
WORKER_CONNECTIONS=4096
LOG_LEVEL=warn
KEEPALIVE_TIMEOUT=65
GZIP_COMP_LEVEL=6
```

### 🏗️ Profile 組合建議

```bash
# 靜態網站 + 監控
docker-compose --profile static-site --profile monitoring up -d

# API Gateway + 記錄
docker-compose --profile reverse-proxy --profile logging up -d

# 完整 HA 環境
docker-compose --profile ha --profile monitoring --profile logging up -d
```

## 性能調優建議

### 🚀 高流量優化

#### NGINX 配置
```nginx
# 高效能設定
worker_processes auto;
worker_connections 8192;
worker_rlimit_nofile 65535;

# 進階緩衝區
client_body_buffer_size 128k;
client_header_buffer_size 3m;
large_client_header_buffers 4 256k;

# 快取優化
open_file_cache max=200000 inactive=20s;
open_file_cache_valid 30s;
open_file_cache_min_uses 2;
open_file_cache_errors on;
```

#### HAProxy 調優
```haproxy
# 高併發設定
global
    maxconn 4096
    nbthread 4
    
defaults
    timeout connect 3s
    timeout client 30s
    timeout server 30s
```

### 💾 記憶體優化

```nginx
# 記憶體友善設定
worker_processes 2;
worker_connections 2048;
client_max_body_size 8M;
client_body_buffer_size 16k;
```

### 🔐 安全強化

```nginx
# 安全頭全套
add_header X-Frame-Options "DENY" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;
```

---

## 🔧 自訂配置範例

### 電商網站配置
```bash
# 環境變數
WORKER_PROCESSES=4
WORKER_CONNECTIONS=4096
CLIENT_MAX_BODY_SIZE=50M
GZIP_COMP_LEVEL=6
KEEPALIVE_TIMEOUT=65

# 部署指令
docker-compose --profile ha --profile monitoring up -d
```

### API 服務配置
```bash
# 環境變數
WORKER_PROCESSES=auto
WORKER_CONNECTIONS=8192
CLIENT_MAX_BODY_SIZE=100M
LOG_LEVEL=info
RATE_LIMIT_API=1000r/m

# 部署指令
docker-compose --profile reverse-proxy --profile logging up -d
```

### 內容交付網路 (CDN)
```bash
# 環境變數
WORKER_PROCESSES=auto
WORKER_CONNECTIONS=8192
GZIP_COMP_LEVEL=9
GZIP_MIN_LENGTH=500

# 部署指令
docker-compose --profile static-site --profile monitoring up -d
```

此文件提供了完整的配置選項參考，可根據具體需求選擇適合的配置組合。