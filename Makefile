# Makefile for RemitFlow
# Convenient shortcuts for common commands

.PHONY: help
help: ## Show this help message
	@echo 'RemitFlow - Available Commands'
	@echo '=============================================='
	@echo ''
	@echo 'Initial Setup:'
	@echo '  make install-tools   - Install missing dependencies'
	@echo '  make setup          - Run complete project setup'
	@echo '  make verify         - Verify environment'
	@echo ''
	@echo 'Infrastructure:'
	@echo '  make infra-up       - Start all services'
	@echo '  make infra-down     - Stop all services'
	@echo '  make infra-restart  - Restart all services'
	@echo '  make infra-status   - Check service status'
	@echo '  make infra-logs     - View service logs'
	@echo ''
	@echo 'Database Access:'
	@echo '  make db-connect     - Connect to PostgreSQL'
	@echo '  make redis-cli      - Connect to Redis'
	@echo ''
	@echo 'Monitoring:'
	@echo '  make open-grafana   - Open Grafana dashboard'
	@echo '  make open-zipkin    - Open Zipkin tracing'
	@echo '  make open-prometheus - Open Prometheus'
	@echo ''
	@echo 'Cleanup:'
	@echo '  make clean          - Clean build artifacts'
	@echo '  make clean-all      - Complete cleanup (DESTRUCTIVE)'

##@ Initial Setup

.PHONY: install-tools
install-tools: ## Install missing dependencies (Java, Docker, Node.js, JHipster)
	@echo "Checking and installing dependencies..."
	@chmod +x scripts/setup/quick-install.sh 2>/dev/null || true
	@./scripts/setup/quick-install.sh

.PHONY: setup
setup: ## Complete project setup (structure + passwords + config)
	@echo "Running complete project setup..."
	@chmod +x scripts/setup/secure-setup.sh 2>/dev/null || true
	@./scripts/setup/secure-setup.sh

.PHONY: verify
verify: ## Verify your environment is properly configured
	@echo "Verifying environment setup..."
	@chmod +x scripts/setup/verify-setup.sh 2>/dev/null || true
	@./scripts/setup/verify-setup.sh

##@ Docker Infrastructure

.PHONY: infra-up
infra-up: ## Start all infrastructure services
	@echo "Starting RemitFlow infrastructure services..."
	@if [ ! -f .env ]; then \
		echo ".env file not found!"; \
		echo ""; \
		echo "Run this first:"; \
		echo "  make setup"; \
		echo ""; \
		exit 1; \
	fi
	@if ! docker info > /dev/null 2>&1; then \
		echo "Docker is not running!"; \
		echo ""; \
		echo "Start Docker Desktop:"; \
		echo "  open -a Docker"; \
		echo ""; \
		exit 1; \
	fi
	@cd infrastructure/docker && docker compose --env-file ../../.env up -d
	@echo "Infrastructure starting..."
	@sleep 5
	@echo "Checking status..."
	@cd infrastructure/docker && docker compose --env-file ../../.env ps

.PHONY: infra-down
infra-down: ## Stop all infrastructure services
	@echo "Stopping RemitFlow infrastructure..."
	@if [ -f .env ]; then \
		cd infrastructure/docker && docker compose --env-file ../../.env down 2>/dev/null || true; \
	else \
		echo ".env not found, forcing container removal..."; \
		docker rm -f $$(docker ps -a -q --filter name=remitflow) 2>/dev/null || true; \
		docker rm -f $$(docker ps -a -q --filter name=money-platform) 2>/dev/null || true; \
	fi
	@echo "Infrastructure stopped!"

.PHONY: infra-force-clean
infra-force-clean: ## Force remove all containers and volumes (no env needed)
	@echo "Force cleaning RemitFlow infrastructure..."
	@docker rm -f $$(docker ps -a -q --filter name=remitflow) 2>/dev/null || true
	@docker rm -f $$(docker ps -a -q --filter name=money-platform) 2>/dev/null || true
	@docker volume rm $$(docker volume ls -q --filter name=remitflow) 2>/dev/null || true
	@docker volume rm $$(docker volume ls -q --filter name=docker_) 2>/dev/null || true
	@docker network rm remitflow-net 2>/dev/null || true
	@docker network rm docker_money-platform-net 2>/dev/null || true
	@echo "Force clean complete!"

.PHONY: infra-restart
infra-restart: ## Restart all infrastructure services
	@echo "Restarting infrastructure..."
	@make infra-down
	@sleep 2
	@make infra-up

.PHONY: infra-status
infra-status: ## Show status of all services
	@echo "RemitFlow Infrastructure Status:"
	@echo "==================================="
	@cd infrastructure/docker && docker compose --env-file ../../.env ps 2>/dev/null || docker ps --filter name=remitflow

.PHONY: infra-logs
infra-logs: ## Show logs from all services (follow mode)
	@docker-compose -f infrastructure/docker/docker-compose.yml logs -f

.PHONY: infra-logs-tail
infra-logs-tail: ## Show last 100 lines of logs from all services
	@docker-compose -f infrastructure/docker/docker-compose.yml logs --tail=100

##@ Database Management

.PHONY: db-connect
db-connect: ## Connect to PostgreSQL database
	@echo "Connecting to PostgreSQL..."
	@echo "Password is in your .env file (DB_PASSWORD)"
	@docker exec -it money-platform-postgres psql -U moneyplatform -d moneyplatform

.PHONY: redis-cli
redis-cli: ## Connect to Redis CLI
	@echo "Connecting to Redis..."
	@docker exec -it money-platform-redis redis-cli -a $$(grep REDIS_PASSWORD .env | cut -d '=' -f2)

##@ Monitoring Tools

.PHONY: open-grafana
open-grafana: ## Open Grafana dashboard
	@echo "Opening Grafana..."
	@echo "  URL: http://localhost:3000"
	@echo "  Username: admin"
	@echo "  Password: Check GRAFANA_ADMIN_PASSWORD in .env"
	@echo ""
	@if [[ "$$(uname)" == "Darwin" ]]; then \
		open http://localhost:3000; \
	else \
		echo "Open http://localhost:3000 in your browser"; \
	fi

.PHONY: open-zipkin
open-zipkin: ## Open Zipkin tracing UI
	@echo "Opening Zipkin..."
	@echo "  URL: http://localhost:9411"
	@echo ""
	@if [[ "$$(uname)" == "Darwin" ]]; then \
		open http://localhost:9411; \
	else \
		echo "Open http://localhost:9411 in your browser"; \
	fi

.PHONY: open-prometheus
open-prometheus: ## Open Prometheus metrics
	@echo "Opening Prometheus..."
	@echo "  URL: http://localhost:9090"
	@echo ""
	@if [[ "$$(uname)" == "Darwin" ]]; then \
		open http://localhost:9090; \
	else \
		echo "Open http://localhost:9090 in your browser"; \
	fi

##@ Service Development

.PHONY: services-build
services-build: ## Build all microservices
	@echo "Building all services..."
	@if [ -f gradlew ]; then \
		./gradlew clean build; \
	else \
		echo "Gradle wrapper not found. Services not yet created?"; \
	fi

.PHONY: services-test
services-test: ## Run tests for all services
	@echo "Running tests..."
	@if [ -f gradlew ]; then \
		./gradlew test; \
	else \
		echo "Gradle wrapper not found. Services not yet created?"; \
	fi

##@ Cleanup

.PHONY: clean
clean: ## Clean build artifacts only
	@echo "Cleaning build artifacts..."
	@if [ -f gradlew ]; then \
		./gradlew clean 2>/dev/null || true; \
	fi
	@find . -type d -name "build" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "target" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "node_modules" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".gradle" -exec rm -rf {} + 2>/dev/null || true
	@echo "Clean complete!"

.PHONY: clean-all
clean-all: ## Complete cleanup - removes everything including Docker volumes (DESTRUCTIVE!)
	@echo "WARNING: This will remove ALL data including Docker volumes!"
	@echo ""
	@read -p "Are you sure? Type 'yes' to continue: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		chmod +x cleanup-all.sh 2>/dev/null || true; \
		./cleanup-all.sh; \
	else \
		echo "Cleanup cancelled."; \
	fi

##@ Utilities

.PHONY: check-ports
check-ports: ## Check if required ports are available
	@echo "Checking port availability..."
	@for port in 5432 6379 9092 2181 8761 8888 8080 9411 9090 3000; do \
		if lsof -Pi :$$port -sTCP:LISTEN -t >/dev/null 2>&1; then \
			echo "Port $$port is in use"; \
		else \
			echo "Port $$port is available"; \
		fi; \
	done

.PHONY: docker-start
docker-start: ## Start Docker Desktop (macOS only)
	@echo "Starting Docker Desktop..."
	@if [[ "$$(uname)" == "Darwin" ]]; then \
		open -a Docker; \
		echo "Waiting for Docker to start..."; \
		sleep 10; \
		while ! docker info > /dev/null 2>&1; do \
			echo "Still waiting for Docker..."; \
			sleep 5; \
		done; \
		echo "Docker is running!"; \
	else \
		echo "Please start Docker manually on your system"; \
	fi

##@ Quick Start

.PHONY: quickstart
quickstart: ## Complete quickstart from scratch
	@echo "RemitFlow Platform - Quick Start"
	@echo "======================================="
	@echo ""
	@echo "This will:"
	@echo "1. Install missing tools"
	@echo "2. Run complete setup"
	@echo "3. Start infrastructure"
	@echo ""
	@read -p "Continue? (y/n): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		make install-tools; \
		make setup; \
		make docker-start; \
		make infra-up; \
		echo ""; \
		echo "Quick start complete!"; \
		echo ""; \
		echo "Access points:"; \
		echo "  Grafana: http://localhost:3000"; \
		echo "  Zipkin:  http://localhost:9411"; \
		echo "  Prometheus: http://localhost:9090"; \
	else \
		echo "Quick start cancelled."; \
	fi
