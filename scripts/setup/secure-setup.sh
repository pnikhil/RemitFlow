#!/bin/bash

# secure-setup.sh - Idempotent secure project setup (macOS/Linux compatible)
# Safe to run multiple times - only creates what's missing

set -e

echo "🚀 RemitFlow - Secure Setup"
echo "============================"
echo ""

# Color codes (macOS compatible)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Track what was done
CREATED_STRUCTURE=false
CREATED_ENV_EXAMPLE=false
CREATED_ENV=false
CREATED_GITIGNORE=false
CREATED_MAKEFILE=false
CREATED_BUILD_FILES=false
CREATED_DB_INIT=false

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
fi

echo -e "${BLUE}Detected OS: $OS${NC}"
echo ""

# Function to generate secure password
generate_password() {
    if command -v openssl &> /dev/null; then
        openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
    elif command -v uuidgen &> /dev/null; then
        echo "$(uuidgen)$(uuidgen)" | tr -d '-' | cut -c1-25
    else
        date +%s%N | sha256sum | base64 | head -c 25
    fi
}

# Function to generate JWT secret (256 bits base64 encoded)
generate_jwt_secret() {
    if command -v openssl &> /dev/null; then
        openssl rand -base64 64 | tr -d '\n'
    else
        echo "$(uuidgen)$(uuidgen)$(uuidgen)$(uuidgen)" | tr -d '-' | base64
    fi
}

# Step 1: Create directory structure (only if missing)
echo -e "${YELLOW}Step 1: Checking project structure...${NC}"

directories=(
    "infrastructure/docker"
    "infrastructure/docker/config"
    "infrastructure/docker/init-scripts"
    "infrastructure/docker/grafana/dashboards"
    "infrastructure/docker/grafana/datasources"
    "infrastructure/kubernetes/base"
    "infrastructure/kubernetes/overlays/dev"
    "infrastructure/kubernetes/overlays/staging"
    "infrastructure/kubernetes/overlays/prod"
    "infrastructure/terraform/modules"
    "infrastructure/terraform/environments"
    "config-server/src/main/resources/configurations"
    "shared-libraries/common-dto"
    "shared-libraries/security-utils"
    "shared-libraries/messaging-contracts"
    "monitoring/prometheus"
    "monitoring/grafana"
    "monitoring/elk-stack"
    "scripts/setup"
    "scripts/deployment"
    "scripts/testing"
    "docs/architecture"
    "docs/api-specs"
    "docs/runbooks"
    ".github/workflows"
    "gateway-service"
    "discovery-service"
    "transaction-orchestrator-service"
    "banking-partner-service"
    "fraud-detection-service"
    "currency-exchange-service"
    "audit-compliance-service"
)

DIRS_CREATED=0
for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        CREATED_STRUCTURE=true
        ((DIRS_CREATED++))
    fi
done

if [ "$CREATED_STRUCTURE" = true ]; then
    echo -e "${GREEN}✓ Created $DIRS_CREATED directories${NC}"
else
    echo -e "${GREEN}✓ Project structure already exists${NC}"
fi

# Step 2: Create .env.example (only if missing or update if changed)
echo -e "${YELLOW}Step 2: Checking .env.example...${NC}"

if [ ! -f .env.example ]; then
    cat > .env.example << 'EOF'
# .env.example - Template for environment variables (SAFE TO COMMIT)
# Copy this file to .env and replace all CHANGE_ME values with secure passwords

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=moneyplatform
DB_PASSWORD=CHANGE_ME_USE_STRONG_PASSWORD

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=CHANGE_ME_USE_STRONG_PASSWORD

# Kafka Configuration
KAFKA_BOOTSTRAP_SERVERS=localhost:9092

# Service Ports
CONFIG_SERVER_PORT=8888
DISCOVERY_SERVER_PORT=8761
GATEWAY_PORT=8080
TRANSACTION_SERVICE_PORT=8081
BANKING_SERVICE_PORT=8082
FRAUD_SERVICE_PORT=8083
EXCHANGE_SERVICE_PORT=8084
AUDIT_SERVICE_PORT=8085

# JWT Secret (Generate with: openssl rand -base64 64)
JWT_SECRET=CHANGE_ME_GENERATE_WITH_OPENSSL_MINIMUM_256_BITS

# Config Server Encryption Key
CONFIG_SERVER_ENCRYPT_KEY=CHANGE_ME_USE_STRONG_PASSWORD

# Grafana Admin Password
GRAFANA_ADMIN_PASSWORD=CHANGE_ME_USE_STRONG_PASSWORD

# Environment
ENVIRONMENT=development

# Feature Flags
ENABLE_DEBUG=false
ENABLE_METRICS=true
ENABLE_TRACING=true
EOF
    CREATED_ENV_EXAMPLE=true
    echo -e "${GREEN}✓ .env.example created${NC}"
else
    echo -e "${GREEN}✓ .env.example already exists${NC}"
fi

# Step 3: Create .env file (only if missing)
echo -e "${YELLOW}Step 3: Checking .env file...${NC}"

if [ ! -f .env ]; then
    echo -e "${BLUE}Generating secure passwords...${NC}"

    DB_PASSWORD=$(generate_password)
    REDIS_PASSWORD=$(generate_password)
    GRAFANA_PASSWORD=$(generate_password)
    JWT_SECRET=$(generate_jwt_secret)
    CONFIG_SERVER_ENCRYPT_KEY=$(generate_password)

    cat > .env << EOF
# .env - Environment variables with generated passwords
# This file is git-ignored and should NEVER be committed

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=moneyplatform
DB_PASSWORD=${DB_PASSWORD}

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=${REDIS_PASSWORD}

# Kafka Configuration
KAFKA_BOOTSTRAP_SERVERS=localhost:9092

# Service Ports
CONFIG_SERVER_PORT=8888
DISCOVERY_SERVER_PORT=8761
GATEWAY_PORT=8080
TRANSACTION_SERVICE_PORT=8081
BANKING_SERVICE_PORT=8082
FRAUD_SERVICE_PORT=8083
EXCHANGE_SERVICE_PORT=8084
AUDIT_SERVICE_PORT=8085

# JWT Secret (Base64 encoded, min 256 bits)
JWT_SECRET=${JWT_SECRET}

# Config Server Encryption Key
CONFIG_SERVER_ENCRYPT_KEY=${CONFIG_SERVER_ENCRYPT_KEY}

# Grafana Admin Password
GRAFANA_ADMIN_PASSWORD=${GRAFANA_PASSWORD}

# Environment
ENVIRONMENT=development

# Feature Flags
ENABLE_DEBUG=false
ENABLE_METRICS=true
ENABLE_TRACING=true
EOF

    CREATED_ENV=true
    echo -e "${GREEN}✓ .env file created with secure passwords${NC}"

    # Show generated passwords for first-time setup
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}Generated Passwords (saved in .env file):${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo "Database Password: ${DB_PASSWORD}"
    echo "Redis Password: ${REDIS_PASSWORD}"
    echo "Grafana Admin Password: ${GRAFANA_PASSWORD}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
else
    echo -e "${GREEN}✓ .env file already exists (keeping existing passwords)${NC}"

    # Check if .env has placeholder values
    if grep -q "CHANGE_ME" .env; then
        echo -e "${YELLOW}⚠️  Warning: .env contains CHANGE_ME placeholders${NC}"
        echo -e "${YELLOW}   Consider regenerating with: rm .env && ./secure-setup.sh${NC}"
    fi
fi

# Step 4: Create .gitignore (only if missing or incomplete)
echo -e "${YELLOW}Step 4: Checking .gitignore...${NC}"

if [ ! -f .gitignore ]; then
    cat > .gitignore << 'EOF'
# Security - NEVER commit these
.env
.env.local
.env.*.local
*.env
!.env.example
.credentials.txt
.credentials.backup
secrets/
*.key
*.pem
*.p12
*.jks

# Gradle
.gradle/
build/
!gradle/wrapper/gradle-wrapper.jar

# IDE
.idea/
*.iws
*.iml
*.ipr
out/
.vscode/
.project
.classpath
.settings/
bin/

# OS
.DS_Store
Thumbs.db

# Logs and temp files
*.log
logs/
target/
*.tmp
*.temp
*.swp

# Docker
docker/volumes/

# Node
node_modules/

# Testing
test-results/
coverage/
EOF
    CREATED_GITIGNORE=true
    echo -e "${GREEN}✓ .gitignore created${NC}"
else
    # Check if .env is in gitignore
    if ! grep -q "^\.env$" .gitignore; then
        echo ".env" >> .gitignore
        echo -e "${YELLOW}✓ Added .env to .gitignore${NC}"
    else
        echo -e "${GREEN}✓ .gitignore already configured${NC}"
    fi
fi

# Step 5: Create database initialization script (only if missing)
DB_INIT_SCRIPT="infrastructure/docker/init-scripts/01-init-databases.sql"
if [ ! -f "$DB_INIT_SCRIPT" ]; then
    cat > "$DB_INIT_SCRIPT" << 'EOF'
-- Create databases for each service
CREATE DATABASE transactions;
CREATE DATABASE banking;
CREATE DATABASE fraud;
CREATE DATABASE exchange;
CREATE DATABASE audit;
CREATE DATABASE config_server;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE transactions TO moneyplatform;
GRANT ALL PRIVILEGES ON DATABASE banking TO moneyplatform;
GRANT ALL PRIVILEGES ON DATABASE fraud TO moneyplatform;
GRANT ALL PRIVILEGES ON DATABASE exchange TO moneyplatform;
GRANT ALL PRIVILEGES ON DATABASE audit TO moneyplatform;
GRANT ALL PRIVILEGES ON DATABASE config_server TO moneyplatform;
EOF
    CREATED_DB_INIT=true
    echo -e "${GREEN}✓ Database initialization script created${NC}"
else
    echo -e "${GREEN}✓ Database initialization script already exists${NC}"
fi

# Step 6: Create Makefile (only if missing)
echo -e "${YELLOW}Step 6: Checking Makefile...${NC}"

if [ ! -f "Makefile" ]; then
    cat > Makefile << 'EOF'
# Makefile for Money Transfer Platform
# Convenient shortcuts for common commands

.PHONY: help
help: ## Show this help message
	@echo '🚀 RemitFlow - Available Commands'
	@echo '================================='
	@echo ''
	@echo 'Initial Setup:'
	@echo '  make install-tools   - Install missing dependencies'
	@echo '  make setup          - Run complete project setup'
	@echo '  make verify         - Verify environment'
	@echo ''
	@echo 'Infrastructure:'
	@echo '  make infra-up       - Start all services'
	@echo '  make infra-down     - Stop all services'
	@echo '  make infra-status   - Check service status'
	@echo '  make infra-logs     - View service logs'
	@echo ''
	@echo 'Cleanup:'
	@echo '  make clean-all      - Complete cleanup (DESTRUCTIVE)'

.PHONY: setup
setup: ## Run complete setup
	@./scripts/setup/secure-setup.sh

.PHONY: verify
verify: ## Verify environment
	@./verify-setup.sh

.PHONY: infra-up
infra-up: ## Start all services
	@docker compose -f infrastructure/docker/docker-compose.yml up -d

.PHONY: infra-down
infra-down: ## Stop all services
	@docker compose -f infrastructure/docker/docker-compose.yml down

.PHONY: infra-status
infra-status: ## Check status
	@docker compose -f infrastructure/docker/docker-compose.yml ps

.PHONY: infra-logs
infra-logs: ## View logs
	@docker compose -f infrastructure/docker/docker-compose.yml logs -f

.PHONY: clean-all
clean-all: ## Clean everything
	@./cleanup-all.sh
EOF
    CREATED_MAKEFILE=true
    echo -e "${GREEN}✓ Makefile created${NC}"
else
    echo -e "${GREEN}✓ Makefile already exists${NC}"
fi

# Step 9: Create Gradle build files (only if missing)
echo -e "${YELLOW}Step 7: Checking build configuration...${NC}"

if [ ! -f "settings.gradle.kts" ]; then
    cat > settings.gradle.kts << 'EOF'
rootProject.name = "money-transfer-platform"

include("config-server")
include("discovery-service")
include("gateway-service")
include("transaction-orchestrator-service")
include("banking-partner-service")
include("fraud-detection-service")
include("currency-exchange-service")
include("audit-compliance-service")
include("shared-libraries:common-dto")
include("shared-libraries:security-utils")
include("shared-libraries:messaging-contracts")
EOF
    CREATED_BUILD_FILES=true
    echo -e "${GREEN}✓ Gradle settings created${NC}"
else
    echo -e "${GREEN}✓ Gradle settings already exist${NC}"
fi

if [ ! -f "build.gradle.kts" ]; then
    cat > build.gradle.kts << 'EOF'
plugins {
    id("java")
    id("org.springframework.boot") version "3.3.0" apply false
    id("io.spring.dependency-management") version "1.1.5" apply false
}

group = "com.moneytransfer"
version = "1.0.0-SNAPSHOT"

java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}

allprojects {
    repositories {
        mavenCentral()
        maven { url = uri("https://repo.spring.io/milestone") }
    }
}

subprojects {
    apply(plugin = "java")
    apply(plugin = "io.spring.dependency-management")

    java {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }
}
EOF
    CREATED_BUILD_FILES=true
    echo -e "${GREEN}✓ Gradle build file created${NC}"
else
    echo -e "${GREEN}✓ Gradle build file already exists${NC}"
fi

# Final summary
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Show what was done
echo "Summary of actions:"
[ "$CREATED_STRUCTURE" = true ] && echo "  • Created $DIRS_CREATED directories"
[ "$CREATED_ENV_EXAMPLE" = true ] && echo "  • Created .env.example template"
[ "$CREATED_ENV" = true ] && echo "  • Created .env with secure passwords"
[ "$CREATED_GITIGNORE" = true ] && echo "  • Created .gitignore"
[ "$CREATED_DB_INIT" = true ] && echo "  • Created database initialization script"
[ "$CREATED_MAKEFILE" = true ] && echo "  • Created Makefile"
[ "$CREATED_BUILD_FILES" = true ] && echo "  • Created Gradle build files"

# If nothing was created
if [ "$CREATED_STRUCTURE" = false ] && [ "$CREATED_ENV_EXAMPLE" = false ] && [ "$CREATED_ENV" = false ] && \
   [ "$CREATED_GITIGNORE" = false ]  && [ "$CREATED_MAKEFILE" = false ] && \
   [ "$CREATED_BUILD_FILES" = false ] && [ "$CREATED_DB_INIT" = false ]; then
    echo "  • Everything was already set up!"
fi

echo ""
printf "${YELLOW}Next steps:${NC}\n"
echo "1. Ensure Docker Desktop is running:"
printf "   ${BLUE}open -a Docker${NC} (macOS)\n"
echo ""
echo "2. Start infrastructure:"
printf "   ${BLUE}make infra-up${NC}\n"
echo ""
echo "3. Verify services are running:"
printf "   ${BLUE}make infra-status${NC}\n"
echo ""

if [ "$CREATED_ENV" = true ]; then
    echo -e "${GREEN}Your passwords are saved in the .env file${NC}"
    echo -e "${YELLOW}Remember: Never commit the .env file to Git!${NC}"
fi

echo -e "${GREEN}================================================${NC}"