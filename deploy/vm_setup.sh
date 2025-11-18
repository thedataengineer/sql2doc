#!/bin/bash

# SQL2Doc VM Setup Script
# Run this script on a fresh Ubuntu 22.04 VM to set up the environment

set -e  # Exit on any error

echo "=================================="
echo "SQL2Doc VM Setup Script"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as non-root user
if [ "$EUID" -eq 0 ]; then
    log_error "Please run this script as a non-root user with sudo privileges"
    exit 1
fi

log_info "Starting VM setup..."

# Update system
log_info "Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install essential tools
log_info "Installing essential tools..."
sudo apt install -y \
    git \
    curl \
    wget \
    vim \
    htop \
    net-tools \
    unzip \
    build-essential

# Install Docker
log_info "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    log_info "Docker installed successfully"
else
    log_warn "Docker already installed"
fi

# Install Docker Compose
log_info "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo apt install -y docker-compose
    log_info "Docker Compose installed successfully"
else
    log_warn "Docker Compose already installed"
fi

# Install Nginx (optional, for reverse proxy)
log_info "Installing Nginx..."
if ! command -v nginx &> /dev/null; then
    sudo apt install -y nginx
    log_info "Nginx installed successfully"
else
    log_warn "Nginx already installed"
fi

# Configure firewall
log_info "Configuring UFW firewall..."
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8501/tcp  # Streamlit
sudo ufw --force enable

# Create application directory
log_info "Creating application directory..."
sudo mkdir -p /opt/sql2doc
sudo chown $USER:$USER /opt/sql2doc

log_info "Setup complete!"
echo ""
echo "=================================="
echo "Next Steps:"
echo "=================================="
echo "1. Logout and login again for Docker group to take effect:"
echo "   exit"
echo "   ssh user@hostname"
echo ""
echo "2. Clone the repository:"
echo "   cd /opt/sql2doc"
echo "   git clone <your-repo-url> ."
echo ""
echo "3. Configure environment:"
echo "   cp .env.example .env"
echo "   nano .env"
echo ""
echo "4. Start the application:"
echo "   docker-compose up -d"
echo ""
echo "=================================="