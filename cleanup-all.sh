#!/bin/bash

# cleanup-all.sh - Complete cleanup of RemitFlow
# Run this to remove all Docker resources and generated files

set -e

echo "🧹 Money Transfer Platform - Complete Cleanup"
echo "============================================="
echo ""

# Color codes (macOS compatible)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}⚠️  WARNING: This will remove:${NC}"
echo "  • All Docker containers with 'money-platform' prefix"
echo "  • All Docker volumes (YOUR DATA WILL BE LOST)"
echo "  • All Docker networks"
echo "  • Generated .env files"
echo "  • Build artifacts"
echo "  • Temporary files"
echo ""
echo -e "${RED}This action cannot be undone!${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}Step 1: Stopping all Docker containers...${NC}"

# Stop and remove containers using docker-compose if file exists
if [ -f infrastructure/docker/docker-compose.yml ]; then
    echo "  Stopping via docker-compose..."
    docker-compose -f infrastructure/docker/docker-compose.yml down 2>/dev/null || true
fi

# Stop and remove any containers with money-platform in the name
echo "  Removing money-platform containers..."
docker ps -a --format '{{.Names}}' | grep -i money-platform | xargs -r docker rm -f 2>/dev/null || true

# Also check for containers created by the services
for service in postgres redis zookeeper kafka zipkin prometheus grafana elasticsearch kibana; do
    container_name="money-platform-${service}"
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "  Removing ${container_name}..."
        docker rm -f ${container_name} 2>/dev/null || true
    fi
done

echo -e "${GREEN}✓ Containers removed${NC}"

echo ""
echo -e "${BLUE}Step 2: Removing Docker volumes...${NC}"

# Remove volumes created by docker-compose
if [ -f infrastructure/docker/docker-compose.yml ]; then
    echo "  Removing docker-compose volumes..."
    docker-compose -f infrastructure/docker/docker-compose.yml down -v 2>/dev/null || true
fi

# Remove named volumes
for volume in postgres_data redis_data prometheus_data grafana_data elasticsearch_data; do
    full_volume_name="money-transfer-platform_${volume}"
    if docker volume ls --format '{{.Name}}' | grep -q "^${full_volume_name}$"; then
        echo "  Removing volume: ${full_volume_name}"
        docker volume rm ${full_volume_name} 2>/dev/null || true
    fi
    # Also try without prefix
    if docker volume ls --format '{{.Name}}' | grep -q "^${volume}$"; then
        echo "  Removing volume: ${volume}"
        docker volume rm ${volume} 2>/dev/null || true
    fi
done

# Remove any other volumes that might match
docker volume ls --format '{{.Name}}' | grep -i money | xargs -r docker volume rm 2>/dev/null || true

echo -e "${GREEN}✓ Volumes removed${NC}"

echo ""
echo -e "${BLUE}Step 3: Removing Docker networks...${NC}"

# Remove custom network
docker network ls --format '{{.Name}}' | grep -i money-platform | xargs -r docker network rm 2>/dev/null || true

echo -e "${GREEN}✓ Networks removed${NC}"

echo ""
echo -e "${BLUE}Step 4: Cleaning up configuration files...${NC}"

# Remove sensitive files
files_to_remove=(
    ".env"
    ".env.local"
    ".env.template"
    ".credentials.txt"
    ".credentials.backup"
    ".env.old.backup"
)

for file in "${files_to_remove[@]}"; do
    if [ -f "$file" ]; then
        echo "  Removing $file"
        rm -f "$file"
    fi
done

echo -e "${GREEN}✓ Configuration files removed${NC}"

echo ""
echo -e "${BLUE}Step 5: Cleaning build artifacts...${NC}"

# Clean Gradle build artifacts
if [ -f gradlew ]; then
    echo "  Running Gradle clean..."
    ./gradlew clean 2>/dev/null || true
fi

# Remove build directories
find . -type d -name "build" -not -path "./.git/*" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "target" -not -path "./.git/*" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "node_modules" -not -path "./.git/*" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name ".gradle" -not -path "./.git/*" -exec rm -rf {} + 2>/dev/null || true

# Remove log files
find . -type f -name "*.log" -not -path "./.git/*" -delete 2>/dev/null || true

echo -e "${GREEN}✓ Build artifacts cleaned${NC}"

echo ""
echo -e "${BLUE}Step 6: Docker system cleanup...${NC}"

# Prune unused Docker resources
echo "  Pruning unused Docker images..."
docker image prune -f 2>/dev/null || true

echo "  Pruning unused Docker networks..."
docker network prune -f 2>/dev/null || true

echo -e "${GREEN}✓ Docker system cleaned${NC}"

echo ""
echo "============================================="
echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo ""
echo "Docker resources status:"
echo "------------------------"
echo "Containers running: $(docker ps -q | wc -l | tr -d ' ')"
echo "Total containers: $(docker ps -aq | wc -l | tr -d ' ')"
echo "Volumes: $(docker volume ls -q | wc -l | tr -d ' ')"
echo "Networks: $(docker network ls --format '{{.Name}}' | grep -v -E '^(bridge|host|none)$' | wc -l | tr -d ' ')"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run the secure setup script to start fresh:"
echo "   ${GREEN}./scripts/setup/secure-setup.sh${NC}"
echo ""
echo "2. Or manually create a new .env file:"
echo "   ${GREEN}cp .env.example .env${NC}"
echo "   Then edit .env with secure passwords"
echo ""
echo "3. Start infrastructure again:"
echo "   ${GREEN}make infra-up${NC}"
echo "============================================="