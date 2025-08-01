#!/usr/bin/make -f

# Monitoring Stack Management Makefile

# Default target
.PHONY: help
help:
	@echo "Monitoring Stack Management Commands:"
	@echo ""
	@echo "Basic Commands:"
	@echo "  make start          - Start core monitoring (Prometheus, Grafana, Node Exporter)"
	@echo "  make stop           - Stop all services"
	@echo "  make restart        - Restart all services"
	@echo "  make logs           - Show logs from all services"
	@echo "  make status         - Show status of all services"
	@echo "  make clean          - Stop and remove all containers and volumes"
	@echo ""
	@echo "Profile-based Deployments:"
	@echo "  make start-basic    - Start with basic system monitoring"
	@echo "  make start-database - Start with database monitoring"
	@echo "  make start-messaging- Start with messaging queue monitoring"
	@echo "  make start-web      - Start with web server monitoring"
	@echo "  make start-search   - Start with search engine monitoring"
	@echo "  make start-all      - Start with all exporters"
	@echo ""
	@echo "Testing:"
	@echo "  make test           - Run comprehensive test suite"
	@echo "  make test-core      - Test core services only"
	@echo "  make health         - Check health of all services"
	@echo ""
	@echo "Monitoring URLs:"
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Grafana:    http://localhost:3000 (admin/admin123)"
	@echo "  AlertManager: http://localhost:9093"

# Core services
.PHONY: start
start:
	docker compose up -d prometheus grafana node_exporter
	@echo "Core monitoring started. Access:"
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Grafana: http://localhost:3000 (admin/admin123)"

.PHONY: stop
stop:
	docker compose down

.PHONY: restart
restart: stop start

.PHONY: logs
logs:
	docker compose logs -f

.PHONY: status
status:
	docker compose ps

.PHONY: clean
clean:
	docker compose down -v
	docker system prune -f

# Profile-based deployments
.PHONY: start-basic
start-basic:
	docker compose --profile basic up -d
	@echo "Basic monitoring started (System metrics)"

.PHONY: start-database
start-database:
	docker compose --profile database up -d
	@echo "Database monitoring started (MySQL, Redis, MongoDB)"

.PHONY: start-messaging
start-messaging:
	docker compose --profile messaging up -d
	@echo "Messaging monitoring started (Kafka, RabbitMQ)"

.PHONY: start-web
start-web:
	docker compose --profile web up -d
	@echo "Web server monitoring started (Nginx)"

.PHONY: start-search
start-search:
	docker compose --profile search up -d
	@echo "Search engine monitoring started (Elasticsearch)"

.PHONY: start-all
start-all:
	docker compose --profile all up -d
	@echo "All monitoring services started"

# Testing
.PHONY: test
test:
	./test-monitoring.sh

.PHONY: test-core
test-core:
	@echo "Testing core services..."
	@docker compose up -d prometheus grafana node_exporter
	@sleep 10
	@curl -s http://localhost:9090/-/healthy > /dev/null && echo "✓ Prometheus healthy" || echo "✗ Prometheus unhealthy"
	@curl -s http://localhost:3000/api/health | jq -r '.database' | grep -q "ok" && echo "✓ Grafana healthy" || echo "✗ Grafana unhealthy"
	@curl -s http://localhost:9100/metrics > /dev/null && echo "✓ Node Exporter responding" || echo "✗ Node Exporter not responding"

.PHONY: health
health:
	@echo "=== Service Health Check ==="
	@docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker compose ps
	@echo ""
	@echo "=== Core Services ==="
	@curl -s http://localhost:9090/-/healthy > /dev/null && echo "✓ Prometheus" || echo "✗ Prometheus"
	@curl -s http://localhost:3000/api/health > /dev/null && echo "✓ Grafana" || echo "✗ Grafana"
	@curl -s http://localhost:9100/metrics > /dev/null && echo "✓ Node Exporter" || echo "✗ Node Exporter"

# Configuration management
.PHONY: config-check
config-check:
	@echo "Checking configuration files..."
	@docker compose config > /dev/null && echo "✓ Docker Compose config valid" || echo "✗ Docker Compose config invalid"
	@promtool check config prometheus/prometheus.yml && echo "✓ Prometheus config valid" || echo "✗ Prometheus config invalid"

.PHONY: reload-prometheus
reload-prometheus:
	@echo "Reloading Prometheus configuration..."
	@curl -s -X POST http://localhost:9090/-/reload && echo "✓ Prometheus config reloaded" || echo "✗ Failed to reload Prometheus"

# Backup and restore
.PHONY: backup
backup:
	@echo "Creating backup..."
	@mkdir -p backups
	@docker compose exec prometheus sh -c "tar -czf - /prometheus" > backups/prometheus-$(shell date +%Y%m%d-%H%M%S).tar.gz
	@docker compose exec grafana sh -c "tar -czf - /var/lib/grafana" > backups/grafana-$(shell date +%Y%m%d-%H%M%S).tar.gz
	@echo "Backup completed in backups/"

# Development helpers
.PHONY: shell-prometheus
shell-prometheus:
	docker compose exec prometheus sh

.PHONY: shell-grafana
shell-grafana:
	docker compose exec grafana bash