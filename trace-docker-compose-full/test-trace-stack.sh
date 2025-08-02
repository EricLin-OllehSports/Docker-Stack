#!/bin/bash

# 追踪系統測試腳本
# 用於測試 OpenTelemetry + Jaeger 分散式追踪堆疊

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函數
print_header() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# 檢查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 未安裝"
        exit 1
    fi
}

# 等待服務就緒
wait_for_service() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=1
    
    print_info "等待 $service_name 服務就緒..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f -o /dev/null "$url"; then
            print_success "$service_name 服務已就緒"
            return 0
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    echo
    print_error "$service_name 服務啟動超時"
    return 1
}

# 發送測試追踪數據
send_test_traces() {
    print_info "發送測試追踪數據..."
    
    # 使用 curl 發送 OTLP 格式的追踪數據
    curl -X POST http://localhost:4318/v1/traces \
        -H "Content-Type: application/json" \
        -d '{
            "resourceSpans": [{
                "resource": {
                    "attributes": [{
                        "key": "service.name",
                        "value": {"stringValue": "test-service"}
                    }]
                },
                "scopeSpans": [{
                    "scope": {"name": "test-tracer"},
                    "spans": [{
                        "traceId": "5b8aa5a2d2c872e8321cf37308d69df2",
                        "spanId": "051581bf3cb55c13",
                        "parentSpanId": "0000000000000000",
                        "name": "test-operation",
                        "kind": 2,
                        "startTimeUnixNano": 1544712660000000000,
                        "endTimeUnixNano": 1544712661000000000,
                        "attributes": [{
                            "key": "http.method",
                            "value": {"stringValue": "GET"}
                        }],
                        "status": {
                            "code": 1
                        }
                    }]
                }]
            }]
        }' 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_success "測試追踪數據已發送"
    else
        print_error "發送測試追踪數據失敗"
    fi
}

# 檢查追踪數據
check_traces_in_jaeger() {
    print_info "檢查 Jaeger 中的追踪數據..."
    
    # 查詢 Jaeger API
    response=$(curl -s "http://localhost:16686/api/services")
    
    if echo "$response" | grep -q "test-service"; then
        print_success "在 Jaeger 中找到測試服務"
        
        # 獲取追踪詳情
        traces=$(curl -s "http://localhost:16686/api/traces?service=test-service&limit=1")
        if echo "$traces" | grep -q "test-operation"; then
            print_success "找到測試操作的追踪"
        else
            print_warning "未找到測試操作的追踪"
        fi
    else
        print_error "在 Jaeger 中未找到測試服務"
    fi
}

# 測試健康檢查端點
test_health_endpoints() {
    print_header "測試健康檢查端點"
    
    # Jaeger 健康檢查
    if curl -s -f -o /dev/null "http://localhost:14269/"; then
        print_success "Jaeger 健康檢查通過"
    else
        print_error "Jaeger 健康檢查失敗"
    fi
    
    # OpenTelemetry Collector 健康檢查
    if curl -s -f -o /dev/null "http://localhost:13133/"; then
        print_success "OpenTelemetry Collector 健康檢查通過"
    else
        print_error "OpenTelemetry Collector 健康檢查失敗"
    fi
}

# 測試 UI 訪問
test_ui_access() {
    print_header "測試 UI 訪問"
    
    # Jaeger UI
    if curl -s -f -o /dev/null "http://localhost:16686/"; then
        print_success "Jaeger UI 可訪問: http://localhost:16686/"
    else
        print_error "Jaeger UI 無法訪問"
    fi
    
    # Grafana UI
    if curl -s -f -o /dev/null "http://localhost:3000/"; then
        print_success "Grafana UI 可訪問: http://localhost:3000/ (admin/admin)"
    else
        print_warning "Grafana UI 無法訪問（可能未啟用 metrics profile）"
    fi
    
    # Prometheus UI
    if curl -s -f -o /dev/null "http://localhost:9090/"; then
        print_success "Prometheus UI 可訪問: http://localhost:9090/"
    else
        print_warning "Prometheus UI 無法訪問（可能未啟用 metrics profile）"
    fi
    
    # Zipkin UI
    if curl -s -f -o /dev/null "http://localhost:9412/"; then
        print_success "Zipkin UI 可訪問: http://localhost:9412/"
    else
        print_warning "Zipkin UI 無法訪問（可能未啟用 zipkin profile）"
    fi
}

# 顯示服務狀態
show_service_status() {
    print_header "服務狀態"
    docker-compose ps
}

# 顯示使用說明
show_usage() {
    print_header "使用說明"
    echo "啟動完整堆疊:"
    echo "  docker-compose --profile full up -d"
    echo ""
    echo "只啟動 Jaeger:"
    echo "  docker-compose --profile jaeger up -d"
    echo ""
    echo "只啟動 OpenTelemetry Collector:"
    echo "  docker-compose --profile otel up -d"
    echo ""
    echo "啟動帶指標的完整堆疊:"
    echo "  docker-compose --profile full --profile metrics up -d"
    echo ""
    echo "停止所有服務:"
    echo "  docker-compose down"
    echo ""
    echo "查看日誌:"
    echo "  docker-compose logs -f [service_name]"
}

# 主測試流程
main() {
    print_header "分散式追踪系統測試"
    
    # 檢查必要的命令
    check_command docker
    check_command docker-compose
    check_command curl
    
    # 顯示當前服務狀態
    show_service_status
    
    # 檢查核心服務
    if docker-compose ps | grep -q "jaeger.*Up"; then
        print_info "檢測到 Jaeger 正在運行"
        
        # 等待服務就緒
        wait_for_service "Jaeger" "http://localhost:14269/"
        
        if docker-compose ps | grep -q "otel-collector.*Up"; then
            print_info "檢測到 OpenTelemetry Collector 正在運行"
            wait_for_service "OpenTelemetry Collector" "http://localhost:13133/"
            
            # 執行測試
            test_health_endpoints
            send_test_traces
            sleep 3  # 等待數據處理
            check_traces_in_jaeger
            test_ui_access
        else
            print_warning "OpenTelemetry Collector 未運行"
            print_info "建議運行: docker-compose --profile otel up -d"
        fi
    else
        print_error "Jaeger 未運行"
        print_info "請先啟動服務："
        echo "  docker-compose --profile jaeger up -d"
        echo "或"
        echo "  docker-compose --profile full up -d"
        exit 1
    fi
    
    # 顯示使用說明
    show_usage
    
    print_header "測試完成"
}

# 執行主程序
main