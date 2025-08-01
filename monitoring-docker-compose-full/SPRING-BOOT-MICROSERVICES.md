# Spring Boot 微服務監控配置

## 🎯 概覽

更新的 Prometheus 配置專注於 **Spring Boot 微服務監控**，已移除 Spring Cloud 元件。此配置針對使用 Spring Boot Actuator 的微服務架構進行最佳化。

## 🔧 配置變更

### **移除的元件**
- ❌ Spring Cloud Gateway 監控
- ❌ Spring Boot Admin Server 監控  
- ❌ Spring Cloud 特定警報規則
- ❌ Gateway 特定儀表板

### **增強的微服務任務**

#### **1. 主要微服務任務** (`spring-boot-microservices`)
```yaml
targets:
  - 'user-service:8080'
  - 'order-service:8080'
  - 'payment-service:8080'
  - 'inventory-service:8080'
  - 'notification-service:8080'
  - 'auth-service:8080'
  - 'gateway-service:8080'
```
- **目的**: 監控核心微服務
- **間隔**: 15s
- **標籤**: `service_name`, `service_type=microservice`

#### **2. 服務發現任務** (`microservices-discovery`)
```yaml
dns_sd_configs:
  - names: ['microservices.local']
    type: 'A'
    port: 8080
```
- **目的**: 透過 DNS 動態服務發現
- **標籤**: `dns_name`, `discovery_method=dns`

#### **3. Docker Swarm 任務** (`microservices-swarm`)
```yaml
targets:
  - 'tasks.user-service:8080'
  - 'tasks.order-service:8080'
  - 'tasks.payment-service:8080'
```
- **目的**: Docker Swarm 服務發現
- **標籤**: `deployment_type=docker-swarm`

#### **4. JVM 專用任務** (`microservices-jvm`)
```yaml
metric_relabel_configs:
  - source_labels: [__name__]
    regex: 'jvm_.*|process_.*|system_.*|tomcat_.*'
    action: keep
```
- **目的**: JVM 效能監控
- **重點**: 記憶體、GC、執行緒、Tomcat 指標

#### **5. 業務指標任務** (`microservices-custom`)
```yaml
metric_relabel_configs:
  - source_labels: [__name__]
    regex: 'jvm_.*|process_.*|system_.*|tomcat_.*|http_server_requests_.*'
    action: drop
```
- **目的**: 僅自訂應用程式指標
- **重點**: 業務邏輯、自訂計數器、計時器

## 📊 微服務監控策略

### **服務分類**
1. **核心服務**: user, order, payment, inventory
2. **支援服務**: notification, auth
3. **基礎架構**: gateway (API 路由)

### **指標收集**
- **應用程式指標**: `/actuator/prometheus`
- **健康檢查**: `/actuator/health`
- **自訂指標**: 業務特定測量
- **JVM 指標**: 記憶體、GC、執行緒

### **標籤策略**
```
service_name: "user-service"
service_type: "microservice" 
metrics_focus: "jvm" | "business"
deployment_type: "docker-swarm" | "k8s"
discovery_method: "dns" | "static"
```

## 🚨 警報規則 (微服務導向)

### **服務健康**
- `SpringBootAppDown`: 微服務無法使用
- `SpringBootHealthCheckFailed`: 健康檢查失敗

### **JVM 效能**
- `SpringBootHighHeapUsage`: 記憶體壓力
- `SpringBootOutOfMemory`: 記憶體不足狀態
- `SpringBootHighGCTime`: GC 效能問題

### **HTTP 效能**
- `SpringBootHighResponseTime`: 延遲問題
- `SpringBootHighErrorRate`: 錯誤率激增
- `SpringBoot5xxErrors`: 伺服器錯誤警報

### **微服務通訊**
- `MicroserviceCircuitBreakerOpen`: 斷路器觸發
- `MicroserviceHighRetryRate`: 通訊問題
- `MicroserviceRateLimiterReject`: 速率限制啟用

## 🎮 使用範例

### **基本微服務監控**
```bash
# 在 prometheus.yml 中更新目標
- job_name: 'spring-boot-microservices'
  static_configs:
    - targets: 
        - 'your-service-1:8080'
        - 'your-service-2:8080'
        - 'your-service-3:8080'
```

### **服務發現**
```bash
# 基於 DNS 的發現
dig microservices.local

# 應該返回:
# user-service.microservices.local    A    10.0.1.10
# order-service.microservices.local   A    10.0.1.11
# payment-service.microservices.local A    10.0.1.12
```

### **Docker Swarm 服務**
```bash
# 在 swarm 模式下部署服務
docker service create --name user-service your-user-service:latest
docker service create --name order-service your-order-service:latest

# 服務透過 tasks.service-name 自動發現
```

### **測試配置**
```bash
# 測試個別服務指標
curl http://user-service:8080/actuator/prometheus

# 測試健康端點
curl http://order-service:8080/actuator/health

# 檢查 Prometheus 目標
curl "http://localhost:9091/api/v1/targets" | jq '.data.activeTargets[] | select(.labels.job == "spring-boot-microservices")'
```

## 📈 儀表板整合

### **微服務概覽儀表板**
- 服務狀態矩陣
- 服務間通訊
- 各服務資源使用率
- 各服務錯誤率

### **JVM 效能儀表板**  
- 各服務堆積使用量
- GC 效能比較
- 執行緒池使用率
- 連線池狀態

### **業務指標儀表板**
- 自訂應用程式指標
- 業務 KPI
- 特定服務測量

## 🔍 疑難排解

### **服務未出現在目標中**
```bash
# 檢查服務連接性
nslookup user-service
curl http://user-service:8080/actuator/health

# 驗證 Prometheus 配置
promtool check config prometheus.yml
```

### **缺少指標**
```bash
# 驗證 actuator 端點
curl http://service:8080/actuator | jq .

# 檢查 prometheus 端點是否啟用
curl http://service:8080/actuator/prometheus | head -20
```

### **高基數問題**
```bash
# 檢查指標基數
curl -s http://localhost:9091/api/v1/label/__name__/values | jq '.data | length'

# 使用 metric_relabel_configs 過濾問題指標
```

## 🎯 最佳實踐

### **服務設計**
1. **一致命名**: 使用標準服務命名慣例
2. **健康檢查**: 實施綜合健康指標
3. **自訂指標**: 新增業務相關測量
4. **資源限制**: 設定適當的 JVM 堆積大小

### **監控策略**
1. **分層監控**: 系統 → JVM → 應用程式 → 業務
2. **警報層次**: 關鍵 → 警告 → 資訊
3. **儀表板焦點**: 從概覽開始，深入細節
4. **指標保留**: 不同指標類型使用不同保留期

### **營運**
1. **服務發現**: 使用動態發現以提升可擴展性
2. **安全性**: 在生產環境中保護 actuator 端點
3. **效能**: 監控抓取持續時間和目標延遲
4. **文件記錄**: 記錄自訂指標及其業務含義

這個專注的微服務配置提供綜合監控，同時消除 Spring Cloud 元件的不必要複雜性。