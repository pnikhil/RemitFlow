#!/bin/bash

set -u

echo "RemitFlow - Environment Verification"
echo "==================================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ALL_GOOD=true

# ---------- OS detection (single pass) ----------
OS="other"
case "$OSTYPE" in
  darwin*) OS="mac";;
  linux*)  OS="linux";;
esac

# ---------- helpers ----------
ok()   { echo -e "${GREEN}$1${NC}"; }
warn() { echo -e "${YELLOW}$1${NC}"; }
err()  { echo -e "${RED}$1${NC}"; ALL_GOOD=false; }

version_of() { $1 2>&1 | head -n 1; }

# cmd, label, version_cmd, install_url_or_note
check_command() {
  local cmd="$1" label="$2" vcmd="${3:-}" install="${4:-}"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$label is installed"
    [ -n "$vcmd" ] && echo "   Version: $($vcmd)"
    return 0
  else
    err "$label is not installed"
    [ -n "$install" ] && echo "   Installation: $install"
    return 1
  fi
}

check_java_21() {
  if command -v java >/dev/null 2>&1; then
    local raw ver
    raw="$(java -version 2>&1 | head -n1)"
    # Extract first integer before the dot or quote, e.g. 21 from "21.0.3"
    ver="$(echo "$raw" | sed -nE 's/.*"([0-9]+).*/\1/p')"
    if [ -n "${ver:-}" ] && [ "$ver" -ge 21 ]; then
      ok "Java 21+ is installed"
      echo "   $raw"
      return 0
    else
      warn "Java is installed but version is less than 21"
      echo "   Current: $raw"
      echo "   Required: Java 21 or higher"
      echo "   Installation: https://adoptium.net/temurin/releases/?version=21"
      ALL_GOOD=false
      return 1
    fi
  else
    err "Java is not installed"
    echo "   Installation: https://adoptium.net/temurin/releases/?version=21"
    return 1
  fi
}

# Port check uses mac-safe lsof; on Linux prefer ss with lsof/netstat fallback
check_port() {
  local port="$1" label="$2"
  case "$OS" in
    mac)
      if lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
        err "Port $port is in use ($label)"
      else
        ok "Port $port is available ($label)"
      fi
      ;;
    linux)
      if command -v ss >/dev/null 2>&1; then
        if ss -ln "sport = :$port" 2>/dev/null | grep -q ":$port"; then
          err "Port $port is in use ($label)"
        else
          ok "Port $port is available ($label)"
        fi
      elif command -v netstat >/dev/null 2>&1; then
        if netstat -ln 2>/dev/null | grep -q ":$port "; then
          err "Port $port is in use ($label)"
        else
          ok "Port $port is available ($label)"
        fi
      else
        # Fallback to lsof if available
        if command -v lsof >/dev/null 2>&1 && lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
          err "Port $port is in use ($label)"
        else
          warn "Port $port status unknown ($label)"
        fi
      fi
      ;;
    *)
      warn "Port $port status unknown ($label)"
      ;;
  esac
}

# ---------- 1. Core Requirements ----------
echo "1. Checking Core Requirements"
echo "------------------------------"

check_java_21
check_command "docker" "Docker" "docker --version" "https://docs.docker.com/get-docker/"

COMPOSE_BIN=""
if docker compose version >/dev/null 2>&1; then
  COMPOSE_BIN="docker compose"
  ok "Docker Compose is installed (docker compose)"
  docker compose version
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_BIN="docker-compose"
  ok "Docker Compose is installed (docker-compose)"
  docker-compose --version
else
  err "Docker Compose is not installed"
  echo "   Installation: Included with Docker Desktop"
fi

check_command "git" "Git" "git --version" "https://git-scm.com/downloads"

# ---------- 2. Build Tools ----------
echo ""
echo "2. Checking Build Tools"
echo "------------------------"

if command -v gradle >/dev/null 2>&1; then
  ok "Gradle is installed (optional)"
  gradle --version | head -n 3
else
  warn "Gradle not installed globally (wrapper will be used)"
fi

check_command "node" "Node.js" "node --version" "https://nodejs.org/"
check_command "npm" "npm" "npm --version" "Comes with Node.js"

# ---------- 3. Dev Tools ----------
echo ""
echo "3. Checking Development Tools"
echo "------------------------------"

if npm list -g generator-jhipster >/dev/null 2>&1; then
  ok "JHipster is installed"
  npm list -g generator-jhipster | grep generator-jhipster || true
else
  warn "JHipster is not installed"
  echo "   Install with: npm install -g generator-jhipster@8.1.0"
fi

if command -v kubectl >/dev/null 2>&1; then
  ok "kubectl is installed (optional)"
  kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null
else
  warn "kubectl not installed (needed for Kubernetes deployment)"
fi

if command -v helm >/dev/null 2>&1; then
  ok "Helm is installed (optional)"
  helm version --short 2>/dev/null || helm version 2>/dev/null
else
  warn "Helm not installed (needed for Kubernetes deployment)"
fi

# ---------- 4. Ports ----------
echo ""
echo "4. Checking Ports Availability"
echo "-------------------------------"

PORTS=(
  "5432:PostgreSQL"
  "6379:Redis"
  "9092:Kafka"
  "2181:Zookeeper"
  "8761:Eureka"
  "8888:Config Server"
  "8080:Gateway"
  "9411:Zipkin"
  "9090:Prometheus"
  "3000:Grafana"
)

for p in "${PORTS[@]}"; do
  IFS=":" read -r port label <<< "$p"
  check_port "$port" "$label"
done

# ---------- 5. System Requirements ----------
echo ""
echo "5. System Requirements"
echo "----------------------"

TOTAL_RAM="Unknown"
CPU_CORES="Unknown"
DISK_SPACE="Unknown"

if [ "$OS" = "mac" ]; then
  # RAM in GB using hw.memsize (bytes)
  if command -v sysctl >/dev/null 2>&1; then
    mem_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo "")"
    if [ -n "$mem_bytes" ]; then
      TOTAL_RAM="$(( (mem_bytes/1024/1024/1024) ))"
    fi
    CPU_CORES="$(sysctl -n hw.ncpu 2>/dev/null || echo "Unknown")"
  fi
  # Disk space available on current volume in GB
  if df -g . >/dev/null 2>&1; then
    DISK_SPACE="$(df -g . | awk 'NR==2{print $4}')"
  else
    # fallback human-readable, remove suffix
    DISK_SPACE="$(df -h . | awk 'NR==2{print $4}' | sed 's/[^0-9]*//g')"
  fi
elif [ "$OS" = "linux" ]; then
  if command -v free >/dev/null 2>&1; then
    TOTAL_RAM="$(free -g | awk 'NR==2{print $2}')"
  fi
  if command -v nproc >/dev/null 2>&1; then
    CPU_CORES="$(nproc)"
  else
    CPU_CORES="$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "Unknown")"
  fi
  DISK_SPACE="$(df -BG . | awk 'NR==2{gsub(/G/,"",$4);print $4}')"
fi

if [ "$TOTAL_RAM" != "Unknown" ] && [ -n "$TOTAL_RAM" ]; then
  if [ "$TOTAL_RAM" -ge 16 ]; then
    ok "RAM: ${TOTAL_RAM}GB (Recommended: 16GB+)"
  elif [ "$TOTAL_RAM" -ge 8 ]; then
    warn "RAM: ${TOTAL_RAM}GB (Minimum: 8GB, Recommended: 16GB+)"
  else
    err "RAM: ${TOTAL_RAM}GB (Insufficient, need at least 8GB)"
  fi
else
  warn "RAM: Could not detect (Recommended: 16GB+)"
fi

if [ "$DISK_SPACE" != "Unknown" ] && [ -n "$DISK_SPACE" ]; then
  echo "   Disk Space Available: ${DISK_SPACE}GB (Recommended: 20GB+)"
else
  echo "   Disk Space Available: Could not detect (Recommended: 20GB+)"
fi

if [ "$CPU_CORES" != "Unknown" ] && [ -n "$CPU_CORES" ]; then
  echo "   CPU Cores: $CPU_CORES (Recommended: 4+)"
else
  echo "   CPU Cores: Could not detect (Recommended: 4+)"
fi

# ---------- Summary ----------
echo ""
echo "======================================================"
if [ "$ALL_GOOD" = true ]; then
  ok "All requirements are met! You're ready to start."
  echo ""
  echo "Next steps:"
  echo "1. Run the project setup script: ./project-setup.sh"
  echo "2. Start infrastructure: ${COMPOSE_BIN:-docker compose} -f infrastructure/docker/docker-compose.yml up -d"
  echo "3. Generate your first microservice with JHipster"
else
  err "Some requirements are missing. Please install them first."
fi
echo "======================================================"

# Optional quick installer (only when something is missing)
if [ "$ALL_GOOD" = false ]; then
  echo ""
  echo "Creating quick-install.sh for missing dependencies..."
  cat > quick-install.sh << 'INSTALL_EOF'
#!/bin/bash
set -e
echo "Installing missing dependencies..."

case "$OSTYPE" in
  darwin*)
    if ! command -v brew >/dev/null 2>&1; then
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install openjdk@21 node
    brew install --cask docker
    echo "Start Docker Desktop from Applications after installation."
    ;;
  linux*)
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update
      sudo apt-get install -y openjdk-21-jdk nodejs npm docker.io docker-compose
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y java-21-openjdk nodejs npm docker docker-compose
    elif command -v yum >/dev/null 2>&1; then
      sudo yum install -y java-21-openjdk nodejs npm docker docker-compose
    else
      echo "Unsupported Linux package manager. Install Java 21, Node.js, Docker, and Docker Compose manually."
    fi
    ;;
  *)
    echo "Unsupported OS for quick-install. Install prerequisites manually."
    ;;
esac

npm install -g generator-jhipster@8.1.0
echo "Installation complete. Re-run ./verify-setup.sh."
INSTALL_EOF

  chmod +x quick-install.sh
  warn "Run ./quick-install.sh to install missing dependencies"
fi
