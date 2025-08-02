# 分散式追踪系統 (Distributed Tracing Stack)

這是一個完整的分散式追踪解決方案，整合了 OpenTelemetry、Jaeger、Zipkin、Prometheus 和 Grafana。

## 系統架構

```
┌─────────────┐     ┌──────────────────┐     ┌─────────┐
│ Applications│────▶│ OpenTelemetry    │────▶│ Jaeger  │
└─────────────┘     │ Collector        │     └─────────┘
                    │                  │
                    │ - Receivers      │     ┌─────────┐
                    │ - Processors     │────▶│ Zipkin  │
                    │ - Exporters      │     └─────────┘
                    └──────────────────┘
                             │
                             ▼
                    ┌──────────────────┐     ┌─────────┐
                    │ Prometheus       │────▶│ Grafana │
                    └──────────────────┘     └─────────┘
```

## 快速開始

### 1. 啟動基本追踪系統 (Jaeger + OpenTelemetry)
```bash
docker-compose --profile jaeger --profile otel up -d
```

### 2. 啟動完整堆疊
```bash
docker-compose --profile full up -d
```

### 3. 啟動完整堆疊 + 指標監控
```bash
docker-compose --profile full --profile metrics up -d
```

## 服務端口

| 服務 | 端口 | 說明 |
|------|------|------|
| **Jaeger** | | |
| Jaeger UI | 16686 | Web 介面 |
| Jaeger Collector | 14268 | HTTP 接收器 |
| Jaeger gRPC | 14250 | gRPC 接收器 |
| **OpenTelemetry** | | |
| OTLP gRPC | 4317 | OTLP gRPC 接收器 |
| OTLP HTTP | 4318 | OTLP HTTP 接收器 |
| Health Check | 13133 | 健康檢查 |
| zPages | 55679 | 調試頁面 |
| **Prometheus** | | |
| Prometheus UI | 9090 | Web 介面 |
| **Grafana** | | |
| Grafana UI | 3000 | Web 介面 (admin/admin) |
| **Zipkin** | | |
| Zipkin UI | 9412 | Web 介面 |

## 使用 Profiles

Docker Compose profiles 允許您選擇性地啟動服務：

- `jaeger`: 只啟動 Jaeger
- `otel`: 只啟動 OpenTelemetry Collector
- `zipkin`: 啟動 Zipkin
- `metrics`: 啟動 Prometheus 和 Grafana
- `demo`: 啟動演示應用
- `full`: 啟動所有核心服務

## 發送追踪數據

### 使用 OTLP (推薦)
```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# 設置追踪
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# 配置 OTLP 導出器
otlp_exporter = OTLPSpanExporter(
    endpoint="localhost:4317",
    insecure=True
)

# 添加批次處理器
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# 創建追踪
with tracer.start_as_current_span("test-operation"):
    print("執行操作...")
```

### 使用 Jaeger 原生協議
```python
from jaeger_client import Config

config = Config(
    config={
        'sampler': {
            'type': 'const',
            'param': 1,
        },
        'local_agent': {
            'reporting_host': 'localhost',
            'reporting_port': '6831',
        },
        'logging': True,
    },
    service_name='your-service-name',
)

tracer = config.initialize_tracer()
```

## 測試追踪系統

運行測試腳本來驗證系統是否正常運作：

```bash
./test-trace-stack.sh
```

這個腳本會：
1. 檢查所有服務的健康狀態
2. 發送測試追踪數據
3. 驗證數據是否正確接收
4. 顯示所有可用的 UI 端點

## 配置說明

### OpenTelemetry Collector 配置

配置文件：`otel-collector-config.yaml`

主要功能：
- **接收器**: OTLP, Jaeger, Zipkin, Prometheus
- **處理器**: 批次處理、記憶體限制、資源屬性、過濾
- **導出器**: Jaeger, Zipkin, Prometheus, Debug

### 資源限制

所有服務都配置了合理的資源限制：

| 服務 | CPU 限制 | 記憶體限制 | CPU 預留 | 記憶體預留 |
|------|----------|------------|----------|------------|
| OpenTelemetry | 1 core | 512MB | 0.5 core | 256MB |
| Jaeger | - | - | - | - |
| Zipkin | 0.5 core | 512MB | 0.25 core | 256MB |
| Prometheus | 0.5 core | 512MB | 0.25 core | 256MB |
| Grafana | 0.5 core | 256MB | 0.25 core | 128MB |

### 健康檢查

所有服務都配置了健康檢查，確保服務穩定運行：
- 間隔：30 秒
- 超時：10 秒
- 重試：3 次
- 啟動期：40 秒

## 監控和警報

### Prometheus 指標

Prometheus 配置為抓取以下目標：
- OpenTelemetry Collector 內部指標
- Jaeger 指標
- Grafana 指標
- Zipkin 指標

### 預設警報規則

`prometheus/rules/trace-alerts.yml` 包含以下警報：
- 服務停機警報
- 高記憶體使用警報
- 丟棄 span 警報
- 追踪錯誤率警報

### Grafana 儀表板

預配置的儀表板：
- OpenTelemetry Collector 監控儀表板
- 服務追踪概覽儀表板

## 故障排除

### 1. 服務無法啟動
```bash
# 檢查服務狀態
docker-compose ps

# 查看服務日誌
docker-compose logs [service-name]
```

### 2. 追踪數據未顯示
- 確認 OpenTelemetry Collector 正在運行
- 檢查應用程式的 endpoint 配置
- 查看 debug 導出器的輸出

### 3. 記憶體不足
調整 `docker-compose.yml` 中的資源限制

### 4. 端口衝突
修改 `docker-compose.yml` 中的端口映射

## 進階配置

### 添加自定義處理器

在 `otel-collector-config.yaml` 中添加：
```yaml
processors:
  custom_processor:
    # 處理器配置
```

### 配置持久化存儲

為 Jaeger 配置 Elasticsearch：
```yaml
jaeger:
  environment:
    - SPAN_STORAGE_TYPE=elasticsearch
    - ES_SERVER_URLS=http://elasticsearch:9200
```

### 擴展到多節點

使用 Docker Swarm 或 Kubernetes 部署多個 Collector 實例。

## 安全建議

1. **生產環境**：
   - 啟用 TLS/SSL
   - 配置認證
   - 限制網絡訪問

2. **敏感數據**：
   - 使用屬性處理器過濾敏感信息
   - 避免在 span 中包含密碼或 token

3. **資源保護**：
   - 配置速率限制
   - 設置適當的批次大小
   - 監控資源使用情況

## 維護建議

1. **定期更新**：
   - 更新 Docker 映像版本
   - 檢查安全補丁

2. **監控**：
   - 設置警報閾值
   - 定期檢查儀表板

3. **備份**：
   - 備份配置文件
   - 如使用持久化存儲，定期備份數據

## 相關資源

- [OpenTelemetry 官方文檔](https://opentelemetry.io/docs/)
- [Jaeger 官方文檔](https://www.jaegertracing.io/docs/)
- [Zipkin 官方文檔](https://zipkin.io/pages/documentation.html)
- [Grafana 追踪文檔](https://grafana.com/docs/grafana/latest/datasources/jaeger/)

## 授權

本專案採用 MIT 授權。詳見 LICENSE 文件。