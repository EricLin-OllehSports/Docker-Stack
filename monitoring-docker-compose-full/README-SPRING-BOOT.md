# Spring Boot Actuator 監控整合

使用 Spring Boot Actuator 端點與 Prometheus 和 Grafana 的完整 Spring Boot 應用程式監控設定。

## 🏗️ Spring Boot 監控架構

```
Spring Boot 監控堆疊
├── Prometheus (指標收集)
│   ├── /actuator/prometheus 端點
│   ├── JVM 指標
│   ├── HTTP 請求指標
│   ├── 資料庫連線池指標
│   └── 自訂應用程式指標
│
├── Grafana 儀表板
│   ├── JVM 記憶體與 GC
│   ├── HTTP 請求效能
│   ├── 執行緒管理
│   ├── 資料庫連線
│   └── 自訂應用程式指標
│
└── 警報規則
    ├── 應用程式健康狀態
    ├── 記憶體使用量
    ├── 回應時間
    ├── 錯誤率
    └── JVM 效能
```

## 📊 監控能力

### **1. JVM 指標**
- **記憶體使用量**: 堆積、非堆積、記憶體池
- **垃圾收集**: GC 時間、頻率、類型
- **執行緒資訊**: 活躍執行緒、守護執行緒、狀態
- **類別載入**: 已載入的類別、已卸載的類別

### **2. HTTP 指標**
- **請求率**: 依端點計算的每秒請求數
- **回應時間**: 百分位數 (50th, 95th, 99th)
- **錯誤率**: 4xx 和 5xx 錯誤
- **狀態碼分佈**: 成功與錯誤率

### **3. 資料庫指標**
- **連線池**: 活躍、閒置、最大連線數
- **連線使用量**: 池使用率百分比
- **連線逾時**: 失敗的連線嘗試

### **4. 應用程式指標**
- **健康指標**: 資料庫、磁碟空間等
- **自訂指標**: 業務特定指標
- **斷路器**: Resilience4j 指標
- **快取指標**: 命中率、未命中率

### **5. 容器指標**
- **資源使用量**: 容器層級的 CPU、記憶體
- **網路 I/O**: 容器網路統計
- **磁碟 I/O**: 容器儲存使用量

## 🚀 快速開始

### **1. 基本 Spring Boot 監控**
```bash
# 啟動 Prometheus + Grafana + Spring Boot 示範應用程式
docker-compose -f docker-compose-unified.yml --profile spring-boot-demo up -d

# 存取網址:
# 示範應用程式 1: http://localhost:8081
# 示範應用程式 2: http://localhost:8082
# Actuator (應用程式 1): http://localhost:8081/actuator
# Prometheus 指標: http://localhost:8081/actuator/prometheus
```

### **2. Spring Boot Admin (選用)**
```bash
# 啟動 Spring Boot Admin 伺服器以增強監控
docker-compose -f docker-compose-unified.yml --profile spring-boot-admin up -d

# 存取 Spring Boot Admin: http://localhost:8080
```

### **3. 監控您的應用程式**
在 Prometheus 配置中更新您的應用程式端點：

```yaml
# 在 prometheus-unified.yml 中
- job_name: 'my-spring-app'
  static_configs:
    - targets: ['my-app:8080']
  scrape_interval: 15s
  metrics_path: /actuator/prometheus
```

## 📋 Spring Boot 應用程式設定

### **1. 必需的相依性**

新增這些相依性到您的 `pom.xml`：

```xml
<dependencies>
    <!-- Spring Boot Actuator -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
    
    <!-- Micrometer Prometheus Registry -->
    <dependency>
        <groupId>io.micrometer</groupId>
        <artifactId>micrometer-registry-prometheus</artifactId>
    </dependency>
    
    <!-- 選用: Spring Boot Admin Client -->
    <dependency>
        <groupId>de.codecentric</groupId>
        <artifactId>spring-boot-admin-starter-client</artifactId>
        <version>3.1.8</version>
    </dependency>
</dependencies>
```

### **2. 應用程式配置**

配置 `application.yml`：

```yaml
# 基本 Actuator 配置
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    prometheus:
      enabled: true
    health:
      show-details: always
  metrics:
    export:
      prometheus:
        enabled: true
    distribution:
      percentiles-histogram:
        http.server.requests: true
      percentiles:
        http.server.requests: 0.5, 0.95, 0.99
        
# 應用程式資訊
info:
  app:
    name: @project.name@
    version: @project.version@
    description: 帶監控的 Spring Boot 應用程式

# 選用: 自訂管理埠
management:
  server:
    port: 9001  # 管理端點的獨立埠
```

### **3. 自訂指標範例**

```java
@Component
public class CustomMetrics {
    
    private final Counter customCounter;
    private final Gauge customGauge;
    private final Timer customTimer;
    
    public CustomMetrics(MeterRegistry meterRegistry) {
        this.customCounter = Counter.builder("custom_requests_total")
            .description("總自訂請求數")
            .tag("type", "business")
            .register(meterRegistry);
            
        this.customGauge = Gauge.builder("custom_queue_size")
            .description("目前佇列大小")
            .register(meterRegistry, this, CustomMetrics::getQueueSize);
            
        this.customTimer = Timer.builder("custom_operation_duration")
            .description("自訂操作持續時間")
            .register(meterRegistry);
    }
    
    public void incrementCounter() {
        customCounter.increment();
    }
    
    public double getQueueSize() {
        // 返回實際佇列大小
        return 42.0;
    }
    
    @EventListener
    public void handleCustomEvent(CustomEvent event) {
        Timer.Sample sample = Timer.start();
        try {
            // 處理事件
            processEvent(event);
        } finally {
            sample.stop(customTimer);
        }
    }
}
```

## 📈 可用儀表板

### **1. Spring Boot 應用程式儀表板**
- **網址**: http://localhost:3000/d/spring-boot
- **功能**:
  - 應用程式狀態概覽
  - JVM 記憶體使用量（堆積/非堆積）
  - 垃圾收集指標
  - HTTP 請求率和回應時間
  - 執行緒資訊
  - 資料庫連線池
  - 自訂應用程式指標

### **2. JVM 專用儀表板**
- **指標**: 記憶體池、GC 效能、執行緒狀態
- **警報**: 記憶體洩漏、GC 壓力、執行緒死鎖

### **3. HTTP 效能儀表板**  
- **指標**: 請求率、回應時間、錯誤率
- **分解**: 依端點、方法、狀態碼

## 🚨 Spring Boot 警報規則

### **應用程式健康警報**
- `SpringBootAppDown`: 應用程式無法使用
- `SpringBootHealthCheckFailed`: 健康檢查失敗

### **JVM 效能警報**
- `SpringBootHighHeapUsage`: 堆積使用率 > 85%
- `SpringBootOutOfMemory`: 堆積使用率 > 95%
- `SpringBootHighGCTime`: GC 時間 > CPU 的 10%
- `SpringBootDeadlockedThreads`: 偵測到執行緒死鎖

### **HTTP 效能警報**
- `SpringBootHighResponseTime`: 95 百分位數 > 2 秒
- `SpringBootHighErrorRate`: 錯誤率 > 10%
- `SpringBoot5xxErrors`: 5xx 錯誤 > 0.5/秒

### **資料庫警報**
- `SpringBootHighDBConnections`: 連線使用率 > 80%
- `SpringBootDBConnectionTimeout`: 連線逾時

## 🔧 進階配置

### **1. 安全配置**

如果您的 actuator 端點有安全保護：

```yaml
# 在 prometheus-unified.yml 中
- job_name: 'secured-spring-app'
  static_configs:
    - targets: ['secure-app:8080']
  basic_auth:
    username: 'actuator'
    password: 'secure-password'
  metrics_path: /actuator/prometheus
```

### **2. 服務發現**

用於動態服務發現：

```yaml
# 基於 DNS 的發現
- job_name: 'spring-boot-discovery'
  dns_sd_configs:
    - names: ['spring-apps.local']
      type: 'A'
      port: 8080
  metrics_path: /actuator/prometheus
```

### **3. 自訂管理埠**

```yaml
# 獨立管理埠
- job_name: 'spring-boot-management'
  static_configs:
    - targets: ['app-mgmt:9001']
  metrics_path: /actuator/prometheus
```

### **4. 微服務模式**

```yaml
# 微服務監控
- job_name: 'microservices'
  static_configs:
    - targets:
        - 'user-service:8080'
        - 'order-service:8080'
        - 'payment-service:8080'
  metrics_path: /actuator/prometheus
  relabel_configs:
    - source_labels: [__address__]
      target_label: service_name
      regex: '([^:]+):.*'
      replacement: '${1}'
```

## 🧪 測試 Spring Boot 監控

### **1. 測試 Actuator 端點**
```bash
# 檢查應用程式健康狀態
curl http://localhost:8081/actuator/health

# 檢查指標端點
curl http://localhost:8081/actuator/metrics

# 檢查 Prometheus 指標
curl http://localhost:8081/actuator/prometheus
```

### **2. 測試自訂指標**
```bash
# 產生負載以查看指標
for i in {1..100}; do
  curl http://localhost:8081/api/test
  sleep 0.1
done

# 在 Prometheus 中檢查自訂指標
curl "http://localhost:9091/api/v1/query?query=custom_requests_total"
```

### **3. 驗證 Prometheus 目標**
```bash
# 檢查 Prometheus 中的 Spring Boot 目標
curl http://localhost:9091/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job | contains("spring"))'
```

## 📊 關鍵指標參考

### **JVM 指標**
```
jvm_memory_used_bytes{area="heap"}           # 堆積記憶體使用量
jvm_memory_max_bytes{area="heap"}            # 最大堆積記憶體
jvm_gc_collection_seconds_sum                # 總 GC 時間
jvm_gc_collection_seconds_count              # GC 頻率
jvm_threads_live_threads                     # 活躍執行緒數
jvm_threads_daemon_threads                   # 守護執行緒數
```

### **HTTP 指標**
```
http_server_requests_total                   # 總 HTTP 請求
http_server_requests_seconds_bucket          # 回應時間直方圖
http_server_requests_seconds_sum             # 總回應時間
http_server_requests_seconds_count           # 請求計數
```

### **資料庫指標**
```
hikaricp_connections_active                  # 活躍資料庫連線
hikaricp_connections_idle                    # 閒置資料庫連線
hikaricp_connections_max                     # 最大資料庫連線
hikaricp_connections_timeout_total           # 連線逾時
```

### **自訂指標**
```
application_*                                # 自訂應用程式指標
resilience4j_circuitbreaker_state           # 斷路器狀態
cache_gets{result="hit"}                     # 快取命中計數
cache_gets{result="miss"}                    # 快取未命中計數
```

## 🔍 疑難排解

### **1. Actuator 端點無法使用**
```bash
# 檢查 actuator 是否啟用
curl http://localhost:8080/actuator

# 常見問題:
# - 缺少 spring-boot-starter-actuator 相依性
# - 端點未在配置中暴露
# - 安全性阻擋存取
```

### **2. Prometheus 指標無法使用**
```bash
# 檢查 Prometheus 端點
curl http://localhost:8080/actuator/prometheus

# 常見問題:
# - 缺少 micrometer-registry-prometheus 相依性  
# - Prometheus 端點未啟用
# - Prometheus 配置中的指標路徑錯誤
```

### **3. 沒有自訂指標**
```bash
# 驗證自訂指標已註冊
curl http://localhost:8080/actuator/metrics | grep custom

# 常見問題:
# - MeterRegistry 未注入
# - 指標未正確註冊
# - 錯誤的指標名稱或標籤
```

## 🎯 最佳實踐

### **1. 安全性**
- **保護 Actuator 端點**: 在生產環境中使用身份驗證
- **獨立管理埠**: 隔離管理端點
- **網路安全**: 限制對監控埠的存取

### **2. 效能**
- **選擇性指標**: 僅暴露需要的指標
- **合理的抓取間隔**: 平衡新鮮度與開銷
- **資源限制**: 設定適當的記憶體/CPU 限制

### **3. 監控策略**
- **健康檢查**: 實施綜合健康指標
- **自訂指標**: 新增業務相關指標
- **警報調整**: 設定適當的閾值和持續時間

### **4. 營運**
- **一致命名**: 在各服務間使用標準指標名稱
- **服務發現**: 使用動態發現以提升可擴展性
- **文件記錄**: 記錄自訂指標及其含義

這個 Spring Boot 監控設定為您的 Java 應用程式提供綜合可觀測性，配置開銷最小。