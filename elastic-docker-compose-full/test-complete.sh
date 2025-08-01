#!/bin/bash
# Elasticsearch Docker Compose 完整測試腳本
# 此腳本用於測試所有三種部署模式的功能

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 工具函數
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 等待服務就緒
wait_for_service() {
    local url="$1"
    local service_name="$2"
    local max_attempts=30
    local attempt=1
    
    log_info "等待 $service_name 服務就緒..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            log_success "$service_name 服務已就緒"
            return 0
        fi
        echo -n "."
        sleep 5
        ((attempt++))
    done
    
    log_error "$service_name 服務啟動失敗"
    return 1
}

# 等待安全服務就緒
wait_for_secure_service() {
    local url="$1"
    local service_name="$2"
    local max_attempts=30
    local attempt=1
    
    log_info "等待 $service_name 安全服務就緒..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s -k -u "elastic:changeme" "$url" > /dev/null 2>&1; then
            log_success "$service_name 安全服務已就緒"
            return 0
        fi
        echo -n "."
        sleep 5
        ((attempt++))
    done
    
    log_error "$service_name 安全服務啟動失敗"
    return 1
}

# 發送測試日誌
send_test_logs() {
    local port="$1"
    log_info "發送測試日誌到端口 $port..."
    
    echo '{"timestamp":"'$(date -Iseconds)'","level":"INFO","service":"test-service","message":"測試訊息 1"}' | nc localhost $port
    echo '{"timestamp":"'$(date -Iseconds)'","level":"ERROR","service":"test-service","message":"測試錯誤訊息","error_code":500}' | nc localhost $port
    echo '{"timestamp":"'$(date -Iseconds)'","level":"WARN","service":"test-service","message":"測試警告訊息"}' | nc localhost $port
    
    log_success "測試日誌已發送"
}

# 驗證索引
verify_indices() {
    local es_url="$1"
    local auth_header="$2"
    
    log_info "驗證 Elasticsearch 索引..."
    sleep 10  # 等待日誌被索引
    
    local indices_response
    if [ -n "$auth_header" ]; then
        indices_response=$(curl -s -k $auth_header "$es_url/_cat/indices?v" || echo "")
    else
        indices_response=$(curl -s "$es_url/_cat/indices?v" || echo "")
    fi
    
    if echo "$indices_response" | grep -q "logs-"; then
        log_success "發現日誌索引"
        echo "$indices_response" | grep "logs-"
    else
        log_warning "未發現日誌索引，可能需要更多時間"
    fi
}

# 測試單節點模式
test_single_node() {
    log_info "開始測試單節點模式..."
    
    # 清理環境
    docker-compose down -v > /dev/null 2>&1 || true
    
    # 啟動服務
    log_info "啟動單節點服務..."
    docker-compose up -d
    
    # 等待服務就緒
    wait_for_service "http://localhost:9200/_cluster/health" "Elasticsearch"
    wait_for_service "http://localhost:5601/api/status" "Kibana"
    
    # 檢查叢集狀態
    log_info "檢查叢集健康狀態..."
    local health=$(curl -s "http://localhost:9200/_cluster/health")
    echo "$health" | jq .
    
    if echo "$health" | jq -r .status | grep -q "yellow\|green"; then
        log_success "叢集健康狀態良好"
    else
        log_error "叢集健康狀態異常"
        return 1
    fi
    
    # 發送測試日誌
    send_test_logs 5001
    
    # 驗證索引
    verify_indices "http://localhost:9200"
    
    # 停止服務
    docker-compose down -v
    log_success "單節點模式測試完成"
}

# 測試三節點叢集模式
test_cluster_mode() {
    log_info "開始測試三節點叢集模式..."
    
    # 清理環境
    docker-compose -f docker-compose-cluster.yml down -v > /dev/null 2>&1 || true
    
    # 啟動服務
    log_info "啟動叢集服務..."
    docker-compose -f docker-compose-cluster.yml up -d
    
    # 等待服務就緒
    wait_for_service "http://localhost:9200/_cluster/health" "Elasticsearch Master"
    wait_for_service "http://localhost:5601/api/status" "Kibana"
    
    # 檢查叢集狀態
    log_info "檢查叢集健康狀態..."
    local health=$(curl -s "http://localhost:9200/_cluster/health")
    echo "$health" | jq .
    
    # 檢查節點數量
    local node_count=$(echo "$health" | jq -r .number_of_nodes)
    if [ "$node_count" = "3" ]; then
        log_success "三節點叢集配置正確"
    else
        log_error "節點數量不正確: $node_count"
        return 1
    fi
    
    # 檢查各節點狀態
    log_info "檢查各節點狀態..."
    curl -s "http://localhost:9200/_cat/nodes?v"
    curl -s "http://localhost:9201/_cat/nodes?v" > /dev/null 2>&1 && log_success "節點2連接正常" || log_warning "節點2連接失敗"
    curl -s "http://localhost:9202/_cat/nodes?v" > /dev/null 2>&1 && log_success "節點3連接正常" || log_warning "節點3連接失敗"
    
    # 發送測試日誌
    send_test_logs 5001
    
    # 驗證索引
    verify_indices "http://localhost:9200"
    
    # 測試故障恢復 - 停止一個節點
    log_info "測試故障恢復能力..."
    docker stop elasticsearch-03
    sleep 10
    
    local health_after=$(curl -s "http://localhost:9200/_cluster/health")
    local status_after=$(echo "$health_after" | jq -r .status)
    if [ "$status_after" = "yellow" ] || [ "$status_after" = "green" ]; then
        log_success "單節點故障後叢集仍然可用"
    else
        log_error "單節點故障後叢集不可用"
    fi
    
    # 重啟節點
    docker start elasticsearch-03
    sleep 15
    
    # 停止服務
    docker-compose -f docker-compose-cluster.yml down -v
    log_success "三節點叢集模式測試完成"
}

# 測試安全模式
test_security_mode() {
    log_info "開始測試安全模式..."
    
    # 清理環境
    docker-compose -f docker-compose-security.yml down -v > /dev/null 2>&1 || true
    
    # 啟動服務
    log_info "啟動安全服務 (這可能需要較長時間)..."
    docker-compose -f docker-compose-security.yml up -d
    
    # 等待 setup 容器完成
    log_info "等待 SSL 證書生成..."
    docker-compose -f docker-compose-security.yml logs -f setup &
    SETUP_PID=$!
    
    # 等待服務就緒
    wait_for_secure_service "https://localhost:9200/_cluster/health" "Elasticsearch"
    wait_for_service "https://localhost:5601/api/status" "Kibana"
    
    kill $SETUP_PID 2>/dev/null || true
    
    # 測試未認證訪問 (應該失敗)
    log_info "測試未認證訪問..."
    if curl -f -s -k "https://localhost:9200/_cluster/health" > /dev/null 2>&1; then
        log_error "安全設定失效 - 未認證訪問成功"
        return 1
    else
        log_success "安全設定正常 - 未認證訪問被拒絕"
    fi
    
    # 測試認證訪問
    log_info "測試認證訪問..."
    local health=$(curl -s -k -u "elastic:changeme" "https://localhost:9200/_cluster/health")
    echo "$health" | jq .
    
    if echo "$health" | jq -r .status | grep -q "yellow\|green"; then
        log_success "認證訪問成功，叢集健康狀態良好"
    else
        log_error "認證訪問失敗或叢集狀態異常"
        return 1
    fi
    
    # 發送測試日誌
    send_test_logs 5001
    
    # 驗證索引
    verify_indices "https://localhost:9200" "-u elastic:changeme"
    
    # 停止服務
    docker-compose -f docker-compose-security.yml down -v
    log_success "安全模式測試完成"
}

# 主菜單
show_menu() {
    echo ""
    echo "Elasticsearch Docker Compose 測試選項："
    echo "1) 測試單節點模式"
    echo "2) 測試三節點叢集模式"
    echo "3) 測試安全模式"
    echo "4) 運行完整測試套件"
    echo "5) 僅測試當前運行的服務"
    echo "6) 退出"
    echo ""
}

# 測試當前運行的服務
test_current_services() {
    log_info "檢測當前運行的服務..."
    
    # 檢查單節點模式
    if docker-compose ps | grep -q "Up"; then
        log_info "檢測到單節點模式運行中..."
        
        if curl -f -s "http://localhost:9200/_cluster/health" > /dev/null 2>&1; then
            log_success "Elasticsearch 運行正常"
            curl -s "http://localhost:9200/_cluster/health" | jq .
        fi
        
        if curl -f -s "http://localhost:5601/api/status" > /dev/null 2>&1; then
            log_success "Kibana 運行正常"
        fi
        
        send_test_logs 5001
        verify_indices "http://localhost:9200"
        return
    fi
    
    # 檢查叢集模式
    if docker-compose -f docker-compose-cluster.yml ps | grep -q "Up"; then
        log_info "檢測到叢集模式運行中..."
        
        if curl -f -s "http://localhost:9200/_cluster/health" > /dev/null 2>&1; then
            log_success "Elasticsearch 叢集運行正常"
            curl -s "http://localhost:9200/_cluster/health" | jq .
            curl -s "http://localhost:9200/_cat/nodes?v"
        fi
        
        send_test_logs 5001
        verify_indices "http://localhost:9200"
        return
    fi
    
    # 檢查安全模式
    if docker-compose -f docker-compose-security.yml ps | grep -q "Up"; then
        log_info "檢測到安全模式運行中..."
        
        if curl -f -s -k -u "elastic:changeme" "https://localhost:9200/_cluster/health" > /dev/null 2>&1; then
            log_success "Elasticsearch 安全模式運行正常"
            curl -s -k -u "elastic:changeme" "https://localhost:9200/_cluster/health" | jq .
        fi
        
        send_test_logs 5001
        verify_indices "https://localhost:9200" "-u elastic:changeme"
        return
    fi
    
    log_warning "未檢測到運行中的服務"
}

# 主程序
main() {
    echo "Elasticsearch Docker Compose 完整測試工具"
    echo "============================================="
    
    # 檢查必要工具
    command -v curl >/dev/null 2>&1 || { log_error "curl 未安裝"; exit 1; }
    command -v jq >/dev/null 2>&1 || { log_error "jq 未安裝"; exit 1; }
    command -v nc >/dev/null 2>&1 || { log_error "netcat 未安裝"; exit 1; }
    
    if [ $# -eq 0 ]; then
        show_menu
        read -p "請選擇測試選項 [1-6]: " choice
    else
        choice=$1
    fi
    
    case $choice in
        1)
            test_single_node
            ;;
        2)
            test_cluster_mode
            ;;
        3)
            test_security_mode
            ;;
        4)
            log_info "開始完整測試套件..."
            test_single_node
            echo ""
            test_cluster_mode
            echo ""
            test_security_mode
            log_success "完整測試套件執行完成"
            ;;
        5)
            test_current_services
            ;;
        6)
            log_info "退出測試工具"
            exit 0
            ;;
        *)
            log_error "無效選項，請選擇 1-6"
            main
            ;;
    esac
}

# 執行主程序
main "$@"