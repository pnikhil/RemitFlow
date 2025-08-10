# RemitFlow - Global Money Transfer Platform

A sophisticated, globe-scale money transfer platform built with microservices architecture, designed to handle millions of transactions per day with sub-second latency.

## 🏗 Architecture

- **5 Core Microservices** with clear separation of concerns
- **Event-driven architecture** using Apache Kafka
- **Sub-second latency** through strategic caching and reactive programming
- **Production-ready** with comprehensive monitoring and observability

## Technology Stack

### Core Technologies
- **Java 21** with Virtual Threads for massive concurrency
- **Spring Boot 3.3.x** with Spring Cloud 2023.0.x
- **Spring WebFlux** for reactive programming
- **PostgreSQL 15** with partitioning and read replicas
- **Redis 7** for distributed caching and session management
- **Apache Kafka** for event streaming and async messaging

### Microservices Infrastructure
- **Spring Cloud Gateway** for API gateway and routing
- **Netflix Eureka** for service discovery
- **Spring Cloud Config** for centralized configuration
- **Resilience4j** for circuit breakers and fault tolerance
- **OpenFeign** for declarative REST clients

### Development & Code Quality
- **JHipster 8.1.0** for microservice generation
- **MapStruct** for object mapping
- **Lombok** for boilerplate reduction
- **Liquibase/Flyway** for database migrations
- **OpenAPI 3.0 (Swagger)** for API documentation
- **JUnit 5 & Mockito** for testing
- **Testcontainers** for integration testing
- **Gradle 8.5** for build automation

### Observability & Monitoring
- **Micrometer** for metrics collection
- **Prometheus** for metrics aggregation
- **Grafana** for visualization and dashboards
- **Zipkin** for distributed tracing
- **Spring Cloud Sleuth** for trace/span management
- **ELK Stack** (Elasticsearch, Logstash, Kibana) for centralized logging
- **Spring Boot Actuator** for health checks and metrics endpoints

### Container & Orchestration
- **Docker** for containerization
- **Docker Compose** for local development
- **Kubernetes** for production orchestration
- **Helm** for Kubernetes package management
- **Istio** (optional) for service mesh

### Security
- **Spring Security** with OAuth 2.0 / JWT
- **Keycloak** (optional) for identity management
- **HashiCorp Vault** for secrets management
- **TLS 1.3** for encryption in transit
- **AES-256** for encryption at rest

### Performance & Scaling
- **HikariCP** for connection pooling
- **Caffeine** for local caching
- **Virtual Threads** (Project Loom) for lightweight concurrency
- **Reactive Streams** for backpressure handling
- **Database partitioning** for horizontal scaling

### CI/CD & Infrastructure as Code
- **GitHub Actions** for CI/CD pipelines
- **Terraform** for infrastructure provisioning
- **ArgoCD** for GitOps deployment
- **SonarQube** for code quality analysis

## 📦 Services

1. **Gateway Service** - API Gateway with rate limiting and routing
2. **Transaction Orchestrator** - Core transaction lifecycle management
3. **Banking Partner Gateway** - Multi-bank integration with intelligent routing
4. **Fraud Detection Service** - Real-time ML-based fraud prevention
5. **Currency Exchange Engine** - Real-time FX rates and conversion
6. **Audit & Compliance Service** - Regulatory compliance and audit trails

## 🎯 Complete Setup Guide

### Quick Start (Automatic Setup)

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/remitflow.git
cd remitflow

# Run automatic setup (installs missing tools, configures everything, starts services)
make quickstart
```

This single command will:
- ✅ Install any missing prerequisites (Java 21, Docker, Node.js, JHipster)
- ✅ Run secure setup (generate passwords, create configs)
- ✅ Start Docker Desktop (on macOS)
- ✅ Launch all infrastructure services
- ✅ Verify everything is running

### Manual Setup (Step by Step)

If you prefer to set up manually or the automatic setup fails:

#### Step 1: Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/remitflow.git
cd remitflow
```

#### Step 2: Check and Install Prerequisites

```bash
# This will check what's missing and install only what's needed
make install-tools

# To see what will be installed first:
make verify
```

#### Step 3: Run Setup

```bash
# Creates project structure, generates passwords, configures everything
make setup
```

#### Step 4: Start Docker

**macOS:**
```bash
make docker-start  # Starts Docker Desktop automatically
```

**Linux:**
```bash
sudo systemctl start docker
```

#### Step 5: Start Infrastructure

```bash
make infra-up
```

#### Step 6: Verify Everything is Running

```bash
make infra-status
```

### Prerequisites (Reference)

The `make install-tools` command will automatically install these if missing:

- **Java 21** - Required for microservices
- **Docker** - Required for running services
- **Node.js 18+** - Required for JHipster
- **JHipster** - For generating microservices

To manually check what's installed:
```bash
make verify
```

To manually install specific tools:
- **Java 21**: [Adoptium Temurin](https://adoptium.net/temurin/releases/?version=21)
- **Docker Desktop** (macOS): [Download](https://www.docker.com/products/docker-desktop/)
- **Docker** (Linux): `curl -fsSL https://get.docker.com | sh`
- **Node.js**: [Download](https://nodejs.org/)

#### Step 8: Access Monitoring Dashboards

Once all services are running:

- **Grafana**: http://localhost:3000
    - Username: `admin`
    - Password: Check `GRAFANA_ADMIN_PASSWORD` in `.env`
- **Zipkin**: http://localhost:9411
- **Prometheus**: http://localhost:9090

**Quick access commands:**

macOS:
```bash
make open-grafana
make open-zipkin
make open-prometheus
```

Linux:
```bash
# The make commands will display URLs
make open-grafana
# Then manually open in browser
firefox http://localhost:3000  # or your preferred browser
```

## Quick Start (One Command)

For a complete setup from scratch:

```bash
# This will install tools, setup, and start everything
make quickstart
```

## Performance Targets

- **Availability**: 99.99%
- **Transaction Latency P50**: <100ms
- **Transaction Latency P99**: <500ms
- **Throughput**: 10,000 TPS per service

## Useful Commands

### Cross-Platform Commands (Make)

```bash
# Initial Setup
make install-tools    # Install missing dependencies
make setup           # Run complete setup
make verify          # Verify environment

# Infrastructure
make infra-up        # Start all services
make infra-down      # Stop services (preserve data)
make infra-restart   # Restart all services
make infra-status    # Check service status
make infra-logs      # View service logs
make infra-clean     # Remove everything (DESTRUCTIVE)
make infra-force-clean # Force clean everything

# Database Access
make db-connect      # Connect to PostgreSQL
make redis-cli       # Connect to Redis

# Development
make services-build  # Build all microservices
make services-test   # Run all tests
make clean          # Clean build artifacts

# Utilities
make check-ports    # Check port availability
```

### Direct Docker Commands

For users who prefer not using Make:

```bash
# Start services
docker-compose -f infrastructure/docker/docker-compose.yml up -d

# Stop services
docker-compose -f infrastructure/docker/docker-compose.yml down

# View logs
docker-compose -f infrastructure/docker/docker-compose.yml logs -f

# Check status
docker ps

# Linux users: prefix with 'sudo' if needed
```

## Building Microservices

Once infrastructure is running:

```bash
# Install JHipster
npm install -g generator-jhipster@8.1.0

# Generate a microservice (example: gateway-service)
cd gateway-service
jhipster --skip-client --skip-user-management

# Build all services
./gradlew buildAll

# Run tests
./gradlew test
```

## 🧹 Complete Cleanup

To remove everything (containers, volumes, data):

```bash
# Using Make
make clean-all

# Or directly
chmod +x cleanup-all.sh
./cleanup-all.sh
```

## Security Notes

- **Never commit `.env`** files with real passwords
- **`.env.example`** contains templates (safe to commit)
- All sensitive files are in `.gitignore`
- Passwords are auto-generated using cryptographically secure methods
- For production, use proper secret management:
    - Kubernetes Secrets
    - HashiCorp Vault
    - AWS Secrets Manager
    - Azure Key Vault

## Project Structure

```
remitflow/
├── infrastructure/           # Docker and Kubernetes configurations
│   ├── docker/              # Docker Compose and configs
│   └── kubernetes/          # K8s manifests
├── gateway-service/         # API Gateway
├── discovery-service/       # Service Discovery (Eureka)
├── transaction-orchestrator-service/  # Core transactions
├── banking-partner-service/          # Bank integrations
├── fraud-detection-service/          # Fraud prevention
├── currency-exchange-service/        # FX rates
├── audit-compliance-service/         # Compliance
├── shared-libraries/        # Common code
├── monitoring/             # Monitoring configs
├── scripts/               # Utility scripts
│   └── setup/            # Setup scripts
└── docs/                 # Documentation
```

## Troubleshooting

### Docker Issues

**macOS:**
```bash
# Docker not running
open -a Docker
# Wait 30-60 seconds

# Reset Docker Desktop
# Docker Desktop → Preferences → Reset → Reset to factory defaults
```

**Linux:**
```bash
# Docker not running
sudo systemctl start docker
sudo systemctl enable docker

# Permission denied
sudo usermod -aG docker $USER
# Log out and back in

# Check Docker daemon
sudo systemctl status docker
```

### Port Conflicts
```bash
# Check which ports are in use
make check-ports

# Or manually
lsof -i :5432  # Check specific port (macOS)
sudo netstat -tulpn | grep :5432  # Linux

# Change ports in .env file if needed
```

### Environment Issues
```bash
# Missing .env file
cp .env.example .env
# Edit and replace CHANGE_ME placeholders

# Or regenerate everything
./scripts/setup/secure-setup.sh
```

### Permission Issues

**macOS/Linux:**
```bash
# Fix script permissions
chmod +x scripts/setup/*.sh
chmod +x *.sh
```

**Linux specific:**
```bash
# If getting permission denied on Docker commands
sudo docker ps  # Test with sudo

# If that works, add user to docker group
sudo usermod -aG docker $USER
newgrp docker  # Or log out and back in
```

## 🎓 Platform-Specific Tips

### macOS Tips
- Allocate at least 4GB RAM to Docker Desktop (Preferences → Resources)
- Use Docker Desktop's dashboard for easy container management
- `open` command works for launching URLs in browser

### Linux Tips
- Use `sudo` for Docker commands if not in docker group
- Use `systemctl` to manage Docker service
- Install `xdg-utils` for browser opening: `sudo apt-get install xdg-utils`
- Consider using Docker rootless mode for better security

## Documentation

- [Architecture Overview](docs/architecture/README.md)
- [API Documentation](docs/api-specs/README.md)
- [Deployment Guide](docs/runbooks/deployment.md)
- [Security Guide](docs/runbooks/security.md)

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Verify prerequisites: `make verify`
3. Check Docker logs: `make infra-logs`
4. Try complete cleanup and restart:
   ```bash
   make clean-all
   make setup
   make infra-up
   ```

## System Requirements

- **RAM**: Minimum 8GB, Recommended 16GB
- **CPU**: Minimum 4 cores, Recommended 8 cores
- **Disk**: 20GB free space
- **OS**: macOS 12+, Ubuntu 20.04+, RHEL 8+