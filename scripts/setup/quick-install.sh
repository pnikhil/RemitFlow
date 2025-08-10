#!/bin/bash

# quick-install.sh - Smart installation of missing dependencies
# Only installs what's actually missing

set -e

echo "🔧 Install missing dependencies"
echo "================================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Track what needs to be installed
NEED_JAVA=false
NEED_DOCKER=false
NEED_NODE=false
NEED_JHIPSTER=false

# Function to check if command exists
check_command() {
    if command -v $1 &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to check Java version
check_java_version() {
    if check_command java; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
        if [ "$JAVA_VERSION" = "" ]; then
            JAVA_VERSION=$(java -version 2>&1 | grep -oE '[0-9]+' | head -1)
        fi
        if [ "$JAVA_VERSION" -ge 21 ] 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

echo -e "${BLUE}Checking installed dependencies...${NC}"
echo ""

# Check Java
if check_java_version; then
    echo -e "${GREEN}✅ Java 21+ is already installed${NC}"
else
    echo -e "${YELLOW}⚠️  Java 21+ not found${NC}"
    NEED_JAVA=true
fi

# Check Docker
if check_command docker; then
    echo -e "${GREEN}✅ Docker is already installed${NC}"
else
    echo -e "${YELLOW}⚠️  Docker not found${NC}"
    NEED_DOCKER=true
fi

# Check Node.js
if check_command node; then
    echo -e "${GREEN}✅ Node.js is already installed${NC}"
else
    echo -e "${YELLOW}⚠️  Node.js not found${NC}"
    NEED_NODE=true
fi

# Check JHipster
if npm list -g generator-jhipster &> /dev/null; then
    echo -e "${GREEN}✅ JHipster is already installed${NC}"
else
    echo -e "${YELLOW}⚠️  JHipster not found${NC}"
    NEED_JHIPSTER=true
fi

# Check if anything needs to be installed
if [ "$NEED_JAVA" = false ] && [ "$NEED_DOCKER" = false ] && [ "$NEED_NODE" = false ] && [ "$NEED_JHIPSTER" = false ]; then
    echo ""
    echo -e "${GREEN}✅ All dependencies are already installed!${NC}"
    echo ""
    echo "Run './verify-setup.sh' to verify your setup."
    exit 0
fi

echo ""
echo -e "${BLUE}Installing missing dependencies...${NC}"
echo ""

# Detect OS and install accordingly
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS Installation
    echo -e "${BLUE}Detected macOS${NC}"

    # Check and install Homebrew if needed
    if ! check_command brew; then
        echo -e "${YELLOW}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi

    # Install missing tools
    if [ "$NEED_JAVA" = true ]; then
        echo -e "${YELLOW}Installing Java 21...${NC}"
        brew install openjdk@21

        # Set up Java path
        echo -e "${YELLOW}Setting up Java path...${NC}"
        sudo ln -sfn /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-21.jdk 2>/dev/null || true
        echo 'export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"' >> ~/.zshrc
        export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
    fi

    if [ "$NEED_NODE" = true ]; then
        echo -e "${YELLOW}Installing Node.js...${NC}"
        brew install node
    fi

    if [ "$NEED_DOCKER" = true ]; then
        echo -e "${YELLOW}Installing Docker...${NC}"
        brew install --cask docker
        echo ""
        echo -e "${YELLOW}⚠️  Docker Desktop has been installed.${NC}"
        echo -e "${YELLOW}Please start Docker Desktop manually:${NC}"
        echo -e "${BLUE}  open -a Docker${NC}"
        echo ""
    fi

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux Installation
    echo -e "${BLUE}Detected Linux${NC}"

    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        echo -e "${YELLOW}Using apt-get package manager${NC}"

        # Update package list
        sudo apt-get update

        if [ "$NEED_JAVA" = true ]; then
            echo -e "${YELLOW}Installing Java 21...${NC}"
            sudo apt-get install -y openjdk-21-jdk
        fi

        if [ "$NEED_NODE" = true ]; then
            echo -e "${YELLOW}Installing Node.js...${NC}"
            # Install Node.js 18.x
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi

        if [ "$NEED_DOCKER" = true ]; then
            echo -e "${YELLOW}Installing Docker...${NC}"
            # Install Docker using official script
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            rm get-docker.sh

            # Install Docker Compose
            sudo apt-get install -y docker-compose

            echo ""
            echo -e "${YELLOW}⚠️  Docker installed. You may need to log out and back in for group changes.${NC}"
        fi

    elif command -v yum &> /dev/null; then
        # RHEL/CentOS
        echo -e "${YELLOW}Using yum package manager${NC}"

        if [ "$NEED_JAVA" = true ]; then
            echo -e "${YELLOW}Installing Java 21...${NC}"
            sudo yum install -y java-21-openjdk-devel
        fi

        if [ "$NEED_NODE" = true ]; then
            echo -e "${YELLOW}Installing Node.js...${NC}"
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            sudo yum install -y nodejs
        fi

        if [ "$NEED_DOCKER" = true ]; then
            echo -e "${YELLOW}Installing Docker...${NC}"
            sudo yum install -y docker
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER

            # Install Docker Compose
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose

            echo ""
            echo -e "${YELLOW}⚠️  Docker installed. You may need to log out and back in for group changes.${NC}"
        fi
    else
        echo -e "${RED}❌ Unsupported Linux distribution${NC}"
        echo "Please install the following manually:"
        [ "$NEED_JAVA" = true ] && echo "  - Java 21"
        [ "$NEED_NODE" = true ] && echo "  - Node.js 18+"
        [ "$NEED_DOCKER" = true ] && echo "  - Docker and Docker Compose"
        exit 1
    fi
else
    echo -e "${RED}❌ Unsupported operating system: $OSTYPE${NC}"
    exit 1
fi

# Install JHipster if needed (cross-platform)
if [ "$NEED_JHIPSTER" = true ]; then
    if check_command npm; then
        echo ""
        echo -e "${YELLOW}Installing JHipster...${NC}"
        npm install -g generator-jhipster@8.1.0
    else
        echo -e "${RED}❌ npm not available. Please install Node.js first.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}✅ Installation complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Final verification
echo -e "${BLUE}Verifying installations...${NC}"
echo ""

if check_java_version; then
    echo -e "${GREEN}✅ Java 21+:${NC} $(java -version 2>&1 | head -n 1)"
else
    echo -e "${RED}❌ Java 21+ not found${NC}"
fi

if check_command docker; then
    echo -e "${GREEN}✅ Docker:${NC} $(docker --version 2>/dev/null || echo 'Installed')"
else
    echo -e "${RED}❌ Docker not found${NC}"
fi

if check_command node; then
    echo -e "${GREEN}✅ Node.js:${NC} $(node --version)"
else
    echo -e "${RED}❌ Node.js not found${NC}"
fi

if npm list -g generator-jhipster &> /dev/null; then
    echo -e "${GREEN}✅ JHipster:${NC} $(npm list -g generator-jhipster --depth=0 2>/dev/null | grep generator-jhipster | cut -d'@' -f2)"
else
    echo -e "${RED}❌ JHipster not found${NC}"
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. If Docker was just installed, start it:"
echo "   ${BLUE}open -a Docker${NC} (macOS)"
echo "   ${BLUE}sudo systemctl start docker${NC} (Linux)"
echo ""
echo "2. Run verification:"
echo "   ${BLUE}./verify-setup.sh${NC}"
echo ""
echo "3. Run setup:"
echo "   ${BLUE}./scripts/setup/secure-setup.sh${NC}"
echo -e "${GREEN}================================================${NC}"