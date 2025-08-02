# 分散式追踪系統測試計劃

## 測試目標

確保分散式追踪系統的所有組件正常運作，包括數據收集、處理、存儲和視覺化功能。

## 測試環境

- Docker Desktop 或 Docker Engine
- docker-compose 1.29.0+
- 至少 4GB 可用記憶體
- 測試主機需要以下端口可用：3000, 4317, 4318, 6831, 9090, 9411, 9412, 14250, 14268, 14269, 16686

## 測試場景

### 1. 基礎功能測試

#### 1.1 服務啟動測試
**目的**：驗證所有服務能夠正確啟動

**步驟**：
```bash
# 啟動基本服務
docker-compose --profile jaeger --profile otel up -d

# 檢查服務狀態
docker-compose ps

# 驗證所有服務都是 "Up" 狀態
```

**預期結果**：
- Jaeger 和 OpenTelemetry Collector 成功啟動
- 沒有錯誤日誌

#### 1.2 健康檢查測試
**目的**：驗證健康檢查端點正常工作

**步驟**：
```bash
# Jaeger 健康檢查
curl -f http://localhost:14269/

# OpenTelemetry Collector 健康檢查
curl -f http://localhost:13133/

# 運行自動化測試
./test-trace-stack.sh
```

**預期結果**：
- 所有健康檢查返回成功狀態
- 測試腳本顯示所有檢查通過

### 2. 追踪數據收集測試

#### 2.1 OTLP 協議測試
**目的**：驗證 OTLP 協議的追踪數據收集

**步驟**：
```bash
# 發送測試追踪數據 (gRPC)
grpcurl -plaintext -d '{
  "resource_spans": [{
    "resource": {
      "attributes": [{
        "key": "service.name",
        "value": {"string_value": "test-grpc"}
      }]
    },
    "scope_spans": [{
      "spans": [{
        "trace_id": "AAAAAAAAAAAAAAAAAAAAAg==",
        "span_id": "AAAAAAAAAAI=",
        "name": "test-span",
        "start_time_unix_nano": 1000000000,
        "end_time_unix_nano": 2000000000
      }]
    }]
  }]
}' localhost:4317 opentelemetry.proto.collector.trace.v1.TraceService/Export

# 發送測試追踪數據 (HTTP)
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d @- << EOF
{
  "resourceSpans": [{
    "resource": {
      "attributes": [{
        "key": "service.name",
        "value": {"stringValue": "test-http"}
      }]
    },
    "scopeSpans": [{
      "spans": [{
        "traceId": "32304a3864306630",
        "spanId": "3233343536373839",
        "name": "http-test-span",
        "startTimeUnixNano": 1000000000,
        "endTimeUnixNano": 2000000000
      }]
    }]
  }]
}
EOF
```

**預期結果**：
- 請求返回成功
- 在 Jaeger UI 中能看到追踪數據

#### 2.2 Jaeger 協議測試
**目的**：驗證 Jaeger 原生協議支援

**步驟**：
```bash
# 使用 Jaeger 客戶端發送數據
docker run --rm --network trace-docker-compose-full_trace-network \
  jaegertracing/jaeger-agent:latest \
  --reporter.grpc.host-port=jaeger:14250 \
  --processor.jaeger-compact.server-host-port=0.0.0.0:6831
```

**預期結果**：
- Jaeger 能接收並顯示追踪數據

### 3. 數據處理測試

#### 3.1 批次處理測試
**目的**：驗證批次處理器正常工作

**步驟**：
```bash
# 發送多個追踪數據
for i in {1..100}; do
  curl -X POST http://localhost:4318/v1/traces \
    -H "Content-Type: application/json" \
    -d "{
      \"resourceSpans\": [{
        \"resource\": {
          \"attributes\": [{
            \"key\": \"service.name\",
            \"value\": {\"stringValue\": \"batch-test-$i\"}
          }]
        },
        \"scopeSpans\": [{
          \"spans\": [{
            \"traceId\": \"$(openssl rand -hex 16)\",
            \"spanId\": \"$(openssl rand -hex 8)\",
            \"name\": \"batch-span-$i\",
            \"startTimeUnixNano\": $(date +%s)000000000,
            \"endTimeUnixNano\": $(date +%s)000000001
          }]
        }]
      }]
    }" 2>/dev/null
done
```

**預期結果**：
- 數據被批次處理而非逐個處理
- 查看 Collector 日誌確認批次處理

#### 3.2 過濾測試
**目的**：驗證過濾器排除健康檢查追踪

**步驟**：
```bash
# 發送健康檢查追踪
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{
    "resourceSpans": [{
      "scopeSpans": [{
        "spans": [{
          "traceId": "11111111111111111111111111111111",
          "spanId": "1111111111111111",
          "name": "health-check",
          "attributes": [{
            "key": "http.target",
            "value": {"stringValue": "/health"}
          }]
        }]
      }]
    }]
  }'
```

**預期結果**：
- 健康檢查追踪被過濾，不出現在 Jaeger UI 中

### 4. 監控和指標測試

#### 4.1 Prometheus 指標測試
**目的**：驗證指標收集正常

**步驟**：
```bash
# 啟動帶指標的堆疊
docker-compose --profile full --profile metrics up -d

# 檢查 Prometheus targets
curl http://localhost:9090/api/v1/targets

# 查詢 Collector 指標
curl http://localhost:9090/api/v1/query?query=otelcol_receiver_accepted_spans_total
```

**預期結果**：
- 所有 targets 狀態為 "up"
- 能查詢到 Collector 相關指標

#### 4.2 Grafana 儀表板測試
**目的**：驗證 Grafana 視覺化功能

**步驟**：
1. 訪問 http://localhost:3000 (admin/admin)
2. 檢查數據源配置
3. 查看預配置的儀表板
4. 驗證數據顯示正常

**預期結果**：
- 能成功登入 Grafana
- 數據源連接正常
- 儀表板顯示實時數據

### 5. 高負載測試

#### 5.1 併發測試
**目的**：測試系統在高併發下的表現

**步驟**：
```bash
# 使用 ab 或 wrk 進行壓力測試
docker run --rm --network host \
  williamyeh/wrk \
  -t4 -c100 -d30s \
  --script /dev/null \
  http://localhost:4318/v1/traces
```

**預期結果**：
- 系統保持穩定
- 沒有記憶體溢出
- 響應時間在可接受範圍內

#### 5.2 資源限制測試
**目的**：驗證資源限制設置有效

**步驟**：
```bash
# 監控資源使用
docker stats

# 發送大量數據觸發資源限制
# 觀察是否觸發記憶體限制器
```

**預期結果**：
- 資源使用不超過設定限制
- 記憶體限制器正常工作

### 6. 故障恢復測試

#### 6.1 服務重啟測試
**目的**：驗證服務重啟後能正常恢復

**步驟**：
```bash
# 停止 Jaeger
docker-compose stop jaeger

# 發送追踪數據
# 數據應該被緩存

# 重啟 Jaeger
docker-compose start jaeger

# 檢查數據是否最終到達
```

**預期結果**：
- 服務重啟後自動恢復
- 緩存的數據最終被處理

### 7. 整合測試

#### 7.1 多協議測試
**目的**：同時使用多種協議發送數據

**步驟**：
- 同時使用 OTLP、Jaeger、Zipkin 協議發送數據
- 驗證所有數據都能正確處理

**預期結果**：
- 不同協議的數據都能在 Jaeger 中查看

#### 7.2 端到端測試
**目的**：模擬真實應用場景

**步驟**：
1. 部署示例應用
2. 生成真實的追踪數據
3. 查看完整的追踪鏈路
4. 驗證服務依賴圖

**預期結果**：
- 能看到完整的請求鏈路
- 服務依賴關係正確顯示

## 測試檢查清單

- [ ] 所有服務成功啟動
- [ ] 健康檢查端點響應正常
- [ ] OTLP gRPC 追踪接收正常
- [ ] OTLP HTTP 追踪接收正常
- [ ] Jaeger UI 可訪問
- [ ] 追踪數據正確顯示
- [ ] 批次處理功能正常
- [ ] 過濾器正確過濾數據
- [ ] Prometheus 指標收集正常
- [ ] Grafana 儀表板顯示正常
- [ ] 資源限制生效
- [ ] 服務能自動恢復
- [ ] 多協議支援正常
- [ ] 警報規則觸發正常

## 問題記錄

記錄測試過程中發現的問題：

| 問題編號 | 描述 | 嚴重程度 | 狀態 | 解決方案 |
|---------|------|---------|------|----------|
| #001 | 範例 | 低 | 已解決 | 範例解決方案 |

## 測試結果總結

- 測試日期：
- 測試人員：
- 測試環境：
- 總體結果：通過/失敗
- 備註：