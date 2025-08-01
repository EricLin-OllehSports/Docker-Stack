#!/bin/bash

set -e

echo "=== Docker Stack Complete - Unified Monitoring Test Suite ==="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

create_external_networks() {
    echo -e "${BLUE}Creating external networks for stack integration...${NC}"
    
    # Create networks if they don't exist
    docker network create redis-docker-compose-full_redis-network 2>/dev/null || true
    docker network create mysql-docker-compose-full_mysql-network 2>/dev/null || true
    docker network create mongo-docker-compose-full_mongo-network 2>/dev/null || true
    docker network create kafka-docker-compose-full_default 2>/dev/null || true
    docker network create rabbitmq-docker-compose-full_default 2>/dev/null || true
    docker network create nginx-docker-compose-full_default 2>/dev/null || true
    docker network create elastic-docker-compose-full_elastic 2>/dev/null || true
    
    echo "External networks created successfully"
}

test_stack_integration() {
    local stack=$1
    local profile=$2
    
    echo -e "${BLUE}Testing $stack integration...${NC}"
    
    # Start the specific stack first
    cd "../../${stack}"
    if [ -f "docker-compose.yml" ]; then
        if [ -n "$profile" ]; then
            docker compose --profile $profile up -d > /dev/null 2>&1
        else
            docker compose up -d > /dev/null 2>&1
        fi
        sleep 10
        
        # Check if services are running
        RUNNING_SERVICES=$(docker compose ps -q | wc -l)
        if [ "$RUNNING_SERVICES" -gt 0 ]; then
            test_result 0 "$stack services started successfully"
        else
            test_result 1 "$stack services failed to start"
        fi
    fi
    
    cd - > /dev/null
}

echo "1. Pre-flight Checks"
echo "===================="

# Check if Docker is running
docker version > /dev/null 2>&1
test_result $? "Docker is running"

# Check if docker-compose is available
docker compose version > /dev/null 2>&1
test_result $? "Docker Compose is available"

# Create external networks
create_external_networks

echo
echo "2. Testing Unified Monitoring Core"
echo "=================================="

# Start unified monitoring
echo "Starting unified monitoring stack..."
docker-compose -f docker-compose-unified.yml up -d prometheus grafana alertmanager node_exporter cadvisor

sleep 15

# Test core services
wait_for_service "unified-prometheus" 9090 60
test_result $? "Unified Prometheus is accessible"

wait_for_service "unified-grafana" 3000 60
test_result $? "Unified Grafana is accessible"

wait_for_service "unified-alertmanager" 9093 60
test_result $? "Unified AlertManager is accessible"

wait_for_service "unified-node-exporter" 9100 30
test_result $? "Unified Node Exporter is accessible"

wait_for_service "unified-cadvisor" 8080 30
test_result $? "Unified cAdvisor is accessible"

echo
echo "3. Testing Stack Integrations"
echo "============================="

# Test Redis Integration
test_stack_integration "redis-docker-compose-full" "single"

# Start Redis monitoring
docker-compose -f docker-compose-unified.yml --profile redis-single up -d redis_exporter_single
sleep 5
if curl -s http://localhost:9121/metrics > /dev/null; then
    test_result 0 "Redis monitoring integration"
else
    test_result 1 "Redis monitoring integration"
fi

# Test MySQL Integration
test_stack_integration "mysql-docker-compose-full" "single"

# Start MySQL monitoring
docker-compose -f docker-compose-unified.yml --profile mysql-single up -d mysql_exporter_single
sleep 5
if docker-compose -f docker-compose-unified.yml ps mysql_exporter_single | grep -q "Up"; then
    test_result 0 "MySQL monitoring integration"
else
    test_result 1 "MySQL monitoring integration"
fi

# Test MongoDB Integration
test_stack_integration "mongo-docker-compose-full" "single"

# Start MongoDB monitoring
docker-compose -f docker-compose-unified.yml --profile mongo-single up -d mongodb_exporter_single
sleep 5
if docker-compose -f docker-compose-unified.yml ps mongodb_exporter_single | grep -q "Up"; then
    test_result 0 "MongoDB monitoring integration"
else
    test_result 1 "MongoDB monitoring integration"
fi

echo
echo "4. Testing Prometheus Targets"
echo "============================="

# Test if Prometheus can see all targets
TARGETS=$(curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets | length' 2>/dev/null || echo "0")
if [ "$TARGETS" -gt 5 ]; then
    test_result 0 "Prometheus has multiple active targets ($TARGETS)"
else
    test_result 1 "Prometheus has insufficient targets ($TARGETS)"
fi

# Test specific service targets
for service in "prometheus" "node-exporter" "cadvisor"; do
    TARGET_UP=$(curl -s "http://localhost:9090/api/v1/query?query=up{job=\"$service\"}" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
    if [ "$TARGET_UP" = "1" ]; then
        test_result 0 "$service target is up in Prometheus"
    else
        test_result 1 "$service target is down in Prometheus"
    fi
done

echo
echo "5. Testing Grafana Integration"
echo "============================="

# Test Grafana health
GRAFANA_HEALTH=$(curl -s http://localhost:3000/api/health | jq -r '.database' 2>/dev/null || echo "error")
if [ "$GRAFANA_HEALTH" = "ok" ]; then
    test_result 0 "Grafana database is healthy"
else
    test_result 1 "Grafana database check failed"
fi

# Test Grafana datasource
DATASOURCES=$(curl -s -u admin:admin123 http://localhost:3000/api/datasources | jq length 2>/dev/null || echo "0")
if [ "$DATASOURCES" -gt 0 ]; then
    test_result 0 "Grafana has configured datasources ($DATASOURCES)"
else
    test_result 1 "Grafana has no datasources configured"
fi

echo
echo "6. Testing Alert Rules"
echo "====================="

# Test if alert rules are loaded
ALERT_RULES=$(curl -s http://localhost:9090/api/v1/rules | jq '.data.groups | length' 2>/dev/null || echo "0")
if [ "$ALERT_RULES" -gt 0 ]; then
    test_result 0 "Prometheus has alert rules loaded ($ALERT_RULES groups)"
else
    test_result 1 "Prometheus has no alert rules loaded"
fi

# Test AlertManager
AM_STATUS=$(curl -s http://localhost:9093/api/v1/status | jq -r '.status' 2>/dev/null || echo "error")
if [ "$AM_STATUS" = "success" ]; then
    test_result 0 "AlertManager is responding"
else
    test_result 1 "AlertManager is not responding properly"
fi

echo
echo "7. Testing Multi-Stack Monitoring"
echo "================================="

# Start all exporters
echo "Starting all monitoring exporters..."
docker-compose -f docker-compose-unified.yml --profile all up -d

sleep 10

# Count running exporters
RUNNING_EXPORTERS=$(docker-compose -f docker-compose-unified.yml ps | grep -E "exporter.*Up" | wc -l)
TOTAL_EXPORTERS=$(docker-compose -f docker-compose-unified.yml ps | grep -E "exporter" | wc -l)

echo "Exporters status: $RUNNING_EXPORTERS/$TOTAL_EXPORTERS running"

if [ "$RUNNING_EXPORTERS" -ge 3 ]; then
    test_result 0 "Multiple exporters are running ($RUNNING_EXPORTERS)"
else
    test_result 1 "Insufficient exporters running ($RUNNING_EXPORTERS)"
fi

echo
echo "8. Testing Service Discovery"
echo "============================"

# Test if services can discover each other across networks
echo "Testing network connectivity between stacks..."

# Test Redis connectivity from monitoring
if docker-compose -f docker-compose-unified.yml exec -T prometheus sh -c "nc -z redis-single 6379" 2>/dev/null; then
    test_result 0 "Monitoring can reach Redis across networks"
else
    test_result 1 "Network connectivity issue between monitoring and Redis"
fi

# Test MySQL connectivity from monitoring
if docker-compose -f docker-compose-unified.yml exec -T prometheus sh -c "nc -z mysql-single 3306" 2>/dev/null; then
    test_result 0 "Monitoring can reach MySQL across networks"
else
    test_result 1 "Network connectivity issue between monitoring and MySQL"
fi

echo
echo "9. Performance Testing"
echo "====================="

# Test Prometheus query performance
QUERY_TIME=$(curl -w "%{time_total}" -s -o /dev/null "http://localhost:9090/api/v1/query?query=up")
if (( $(echo "$QUERY_TIME < 1.0" | bc -l) )); then
    test_result 0 "Prometheus queries are fast (${QUERY_TIME}s)"
else
    test_result 1 "Prometheus queries are slow (${QUERY_TIME}s)"
fi

# Test Grafana dashboard load time
GRAFANA_TIME=$(curl -w "%{time_total}" -s -o /dev/null "http://localhost:3000/api/dashboards/home")
if (( $(echo "$GRAFANA_TIME < 2.0" | bc -l) )); then
    test_result 0 "Grafana dashboards load quickly (${GRAFANA_TIME}s)"
else
    test_result 1 "Grafana dashboards load slowly (${GRAFANA_TIME}s)"
fi

echo
echo "10. Cleanup Test"
echo "==============="

# Test cleanup of monitoring stack
echo "Testing unified monitoring cleanup..."
docker-compose -f docker-compose-unified.yml down > /dev/null 2>&1

# Clean up individual stacks
for stack in "redis-docker-compose-full" "mysql-docker-compose-full" "mongo-docker-compose-full"; do
    if [ -d "../../$stack" ]; then
        cd "../../$stack"
        docker compose down > /dev/null 2>&1 || true
        cd - > /dev/null
    fi
done

RUNNING_CONTAINERS=$(docker-compose -f docker-compose-unified.yml ps -q | wc -l)
if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
    test_result 0 "All monitoring containers stopped successfully"
else
    test_result 1 "Some containers are still running"
fi

echo
echo "=== Unified Monitoring Test Summary ==="
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo -e "Total:  $((PASSED + FAILED))"
echo

# Display service endpoints
echo -e "${BLUE}=== Service Endpoints ===${NC}"
echo "Unified Prometheus:  http://localhost:9090"
echo "Unified Grafana:     http://localhost:3000 (admin/admin123)"
echo "Unified AlertManager: http://localhost:9093"
echo "cAdvisor:           http://localhost:8080"
echo

# Display available profiles
echo -e "${BLUE}=== Available Monitoring Profiles ===${NC}"
echo "Redis Single:       --profile redis-single"
echo "Redis Replication:  --profile redis-replication" 
echo "Redis Sentinel:     --profile redis-sentinel"
echo "Redis Cluster:      --profile redis-cluster"
echo "MySQL Single:       --profile mysql-single"
echo "MySQL Replication:  --profile mysql-replication"
echo "MongoDB Single:     --profile mongo-single"
echo "MongoDB Replica:    --profile mongo-replica"
echo "MongoDB Sharded:    --profile mongo-sharded"
echo "All Services:       --profile all"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All unified monitoring tests passed! 🎉${NC}"
    echo -e "${GREEN}Your Docker Stack Complete is ready for comprehensive monitoring!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please check the output above.${NC}"
    exit 1
fi