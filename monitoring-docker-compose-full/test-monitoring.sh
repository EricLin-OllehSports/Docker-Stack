#!/bin/bash

set -e

echo "=== Monitoring Stack Test Suite ==="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test results
PASSED=0
FAILED=0

test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((FAILED++))
    fi
}

wait_for_service() {
    local service=$1
    local port=$2
    local timeout=${3:-60}
    
    echo "Waiting for $service on port $port..."
    for i in $(seq 1 $timeout); do
        if curl -s http://localhost:$port > /dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    return 1
}

echo "1. Testing Core Services"
echo "========================"

# Test 1: Start core services
echo "Starting core monitoring services..."
docker compose up -d prometheus grafana alertmanager node_exporter
sleep 10

# Test 2: Check if services are running
echo "Checking if services are running..."
docker compose ps | grep -E "(prometheus|grafana|alertmanager|node_exporter)"

# Test 3: Wait for services to be ready
wait_for_service "prometheus" 9090 60
test_result $? "Prometheus service is accessible"

wait_for_service "grafana" 3000 60  
test_result $? "Grafana service is accessible"

wait_for_service "alertmanager" 9093 60
test_result $? "AlertManager service is accessible"

wait_for_service "node_exporter" 9100 30
test_result $? "Node Exporter service is accessible"

# Test 4: Test Prometheus targets
echo
echo "Testing Prometheus configuration..."
TARGETS=$(curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets | length')
test_result $? "Prometheus targets API responds"

if [ "$TARGETS" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Found $TARGETS active targets"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} No active targets found"
    ((FAILED++))
fi

# Test 5: Test Grafana health
echo
echo "Testing Grafana health..."
GRAFANA_HEALTH=$(curl -s http://localhost:3000/api/health | jq -r '.database')
if [ "$GRAFANA_HEALTH" = "ok" ]; then
    test_result 0 "Grafana database is healthy"
else
    test_result 1 "Grafana database check failed"
fi

echo
echo "2. Testing Database Exporters"
echo "=============================="

# Test MySQL Exporter
echo "Testing MySQL exporter profile..."
docker compose --profile mysql up -d mysql_exporter
sleep 5

if docker compose ps mysql_exporter | grep -q "Up"; then
    wait_for_service "mysql_exporter" 9104 30
    test_result $? "MySQL Exporter with profile"
else
    test_result 1 "MySQL Exporter failed to start"
fi

# Test Redis Exporter  
echo "Testing Redis exporter profile..."
docker compose --profile redis up -d redis_exporter
sleep 5

if docker compose ps redis_exporter | grep -q "Up"; then
    wait_for_service "redis_exporter" 9121 30
    test_result $? "Redis Exporter with profile"
else
    test_result 1 "Redis Exporter failed to start"
fi

# Test MongoDB Exporter
echo "Testing MongoDB exporter profile..."
docker compose --profile mongodb up -d mongodb_exporter  
sleep 5

if docker compose ps mongodb_exporter | grep -q "Up"; then
    wait_for_service "mongodb_exporter" 9216 30
    test_result $? "MongoDB Exporter with profile"
else
    test_result 1 "MongoDB Exporter failed to start"
fi

echo
echo "3. Testing Message Queue Exporters"
echo "=================================="

# Test Kafka Exporter
echo "Testing Kafka exporter profile..."
docker compose --profile kafka up -d kafka_exporter
sleep 5

if docker compose ps kafka_exporter | grep -q "Up"; then
    wait_for_service "kafka_exporter" 9308 30
    test_result $? "Kafka Exporter with profile"
else
    test_result 1 "Kafka Exporter failed to start"
fi

# Test RabbitMQ Exporter
echo "Testing RabbitMQ exporter profile..."
docker compose --profile rabbitmq up -d rabbitmq_exporter
sleep 5

if docker compose ps rabbitmq_exporter | grep -q "Up"; then
    wait_for_service "rabbitmq_exporter" 9419 30
    test_result $? "RabbitMQ Exporter with profile"
else
    test_result 1 "RabbitMQ Exporter failed to start"
fi

echo
echo "4. Testing Web Server Exporters"
echo "==============================="

# Test Nginx Exporter
echo "Testing Nginx exporter profile..."
docker compose --profile nginx up -d nginx_exporter
sleep 5

if docker compose ps nginx_exporter | grep -q "Up"; then
    wait_for_service "nginx_exporter" 9113 30
    test_result $? "Nginx Exporter with profile"
else
    test_result 1 "Nginx Exporter failed to start"
fi

# Test Elasticsearch Exporter
echo "Testing Elasticsearch exporter profile..."
docker compose --profile elasticsearch up -d elasticsearch_exporter
sleep 5

if docker compose ps elasticsearch_exporter | grep -q "Up"; then
    wait_for_service "elasticsearch_exporter" 9114 30
    test_result $? "Elasticsearch Exporter with profile"
else
    test_result 1 "Elasticsearch Exporter failed to start"
fi

echo
echo "5. Testing All Profile"
echo "====================="

echo "Testing all exporters with --profile all..."
docker compose --profile all up -d
sleep 10

# Count running exporters
RUNNING_EXPORTERS=$(docker compose ps | grep -E "exporter" | wc -l)
echo "Running exporters: $RUNNING_EXPORTERS"

if [ "$RUNNING_EXPORTERS" -ge 7 ]; then
    test_result 0 "All exporters started with --profile all"
else
    test_result 1 "Not all exporters started with --profile all"
fi

echo
echo "6. Testing Health Checks"
echo "========================"

echo "Checking health status of all services..."
HEALTHY_SERVICES=0
TOTAL_SERVICES=0

for service in prometheus grafana alertmanager; do
    ((TOTAL_SERVICES++))
    if docker compose exec -T $service sh -c "exit 0" 2>/dev/null; then
        ((HEALTHY_SERVICES++))
        echo -e "${GREEN}✓${NC} $service is healthy"
    else
        echo -e "${RED}✗${NC} $service health check failed"
    fi
done

test_result $((HEALTHY_SERVICES == TOTAL_SERVICES)) "Core services health checks"

echo
echo "7. Testing Metrics Collection"
echo "============================="

# Test if Prometheus is collecting metrics
METRICS_COUNT=$(curl -s http://localhost:9090/api/v1/query?query=up | jq -r '.data.result | length')
if [ "$METRICS_COUNT" -gt 0 ]; then
    test_result 0 "Prometheus is collecting metrics ($METRICS_COUNT targets)"
else
    test_result 1 "Prometheus is not collecting metrics"
fi

# Test specific metric queries
UP_SERVICES=$(curl -s "http://localhost:9090/api/v1/query?query=up==1" | jq -r '.data.result | length')
echo "Services reporting as up: $UP_SERVICES"

echo
echo "8. Cleanup Test"
echo "==============="

echo "Testing cleanup functionality..."
docker compose down
sleep 5

RUNNING_CONTAINERS=$(docker compose ps -q | wc -l)
if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
    test_result 0 "All containers stopped successfully"
else
    test_result 1 "Some containers are still running"
fi

echo
echo "=== Test Summary ==="
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo -e "Total:  $((PASSED + FAILED))"
echo

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! 🎉${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please check the output above.${NC}"
    exit 1
fi