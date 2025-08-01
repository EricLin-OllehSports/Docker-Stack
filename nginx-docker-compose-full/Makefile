# NGINX Docker Compose Makefile

.DEFAULT_GOAL := help

# Variables
COMPOSE_FILE = docker-compose.yml
PROJECT_NAME = nginx-stack

## Help
help: ## Display this help screen
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

## Development Commands
dev: ## Start development environment (single NGINX)
	docker-compose --profile default up -d

dev-logs: ## Follow development logs
	docker-compose logs -f nginx

## Production Commands
prod: ## Start production environment (HA mode)
	docker-compose --profile ha --profile monitoring up -d

prod-logs: ## Follow production logs
	docker-compose logs -f haproxy nginx-1 nginx-2 nginx-3

## SSL Commands
ssl-generate: ## Generate self-signed SSL certificates
	./scripts/generate-ssl.sh localhost 365

ssl-check: ## Check SSL certificate validity
	@if [ -f "./nginx/ssl/localhost.crt" ]; then \
		openssl x509 -in ./nginx/ssl/localhost.crt -text -noout | grep -A2 "Validity"; \
	else \
		echo "SSL certificate not found. Run 'make ssl-generate' first."; \
	fi

## Service Management
start: ## Start all services
	docker-compose up -d

stop: ## Stop all services
	docker-compose down

restart: ## Restart all services
	docker-compose restart

status: ## Show service status
	docker-compose ps

## Monitoring
stats: ## Open HAProxy statistics page
	@echo "Opening HAProxy stats at http://localhost:8404/stats"
	@which open >/dev/null && open http://localhost:8404/stats || echo "Open http://localhost:8404/stats in your browser"

metrics: ## Show Prometheus metrics
	curl -s http://localhost:9113/metrics | head -20

health: ## Check service health
	@echo "Checking NGINX health..."
	@curl -f http://localhost/health || echo "Health check failed"
	@echo "\nChecking HAProxy health..."
	@curl -f http://localhost:8404/stats || echo "HAProxy stats unavailable"

## Testing
test-load: ## Simple load test
	@echo "Running simple load test..."
	@for i in {1..10}; do curl -s http://localhost/ >/dev/null && echo "Request $$i: OK" || echo "Request $$i: FAILED"; done

## Cleanup
clean: ## Clean up containers and volumes
	docker-compose down -v
	docker system prune -f

clean-all: ## Clean up everything including images
	docker-compose down -v --rmi all
	docker system prune -af

## Logs
logs: ## Show all logs
	docker-compose logs

logs-follow: ## Follow all logs
	docker-compose logs -f

logs-nginx: ## Show NGINX logs only
	docker-compose logs nginx

logs-haproxy: ## Show HAProxy logs only
	docker-compose logs haproxy

.PHONY: help dev dev-logs prod prod-logs ssl-generate ssl-check start stop restart status stats metrics health test-load clean clean-all logs logs-follow logs-nginx logs-haproxy