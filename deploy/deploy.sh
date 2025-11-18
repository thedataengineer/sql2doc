#!/bin/bash

# SQL2Doc Deployment Script
# Automates deployment to Azure VM

set -e

echo "=================================="
echo "SQL2Doc Deployment Script"
echo "=================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
APP_DIR="/opt/sql2doc"
BACKUP_DIR="/opt/sql2doc_backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Check if .env file exists
if [ ! -f .env ]; then
    log_warn ".env file not found, creating from .env.example"
    cp .env.example .env
    log_info "Please edit .env file with your configuration"
    exit 1
fi

# Source environment variables
source .env

log_info "Starting deployment..."

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup current database (if exists)
log_info "Backing up database..."
if docker ps | grep -q sql2doc_postgres; then
    docker exec sql2doc_postgres pg_dump \
        -U ${POSTGRES_USER} \
        ${POSTGRES_DB} > $BACKUP_DIR/backup_$TIMESTAMP.sql
    log_info "Database backed up to $BACKUP_DIR/backup_$TIMESTAMP.sql"
else
    log_warn "PostgreSQL container not running, skipping backup"
fi

# Pull latest code
log_info "Pulling latest code..."
git pull origin main

# Stop running containers
log_info "Stopping containers..."
docker-compose down

# Pull latest images
log_info "Pulling latest Docker images..."
docker-compose pull

# Build custom images
log_info "Building application image..."
docker-compose build

# Start services
log_info "Starting services..."
docker-compose up -d

# Wait for services to be healthy
log_info "Waiting for services to start..."
sleep 10

# Check service health
log_info "Checking service health..."
docker-compose ps

# Load test database if fresh install
if [ ! -f "$BACKUP_DIR/.db_initialized" ]; then
    log_info "Loading test database..."
    sleep 15  # Wait for PostgreSQL to be ready

    docker exec sql2doc_postgres psql \
        -U ${POSTGRES_USER} \
        -d postgres \
        -f /docker-entrypoint-initdb.d/legal_collections_schema.sql || true

    docker exec sql2doc_postgres psql \
        -U ${POSTGRES_USER} \
        -d ${POSTGRES_DB} \
        -f /docker-entrypoint-initdb.d/legal_collections_procedures.sql || true

    docker exec sql2doc_postgres psql \
        -U ${POSTGRES_USER} \
        -d ${POSTGRES_DB} \
        -f /docker-entrypoint-initdb.d/legal_collections_sample_data.sql || true

    touch "$BACKUP_DIR/.db_initialized"
    log_info "Test database loaded"
fi

# Pull Ollama model (if not exists)
log_info "Checking Ollama model..."
docker exec sql2doc_ollama ollama list | grep -q ${OLLAMA_MODEL} || \
    docker exec sql2doc_ollama ollama pull ${OLLAMA_MODEL}

# Show logs
log_info "Deployment complete!"
echo ""
echo "=================================="
echo "Deployment Summary"
echo "=================================="
echo "Application: http://$(hostname -I | awk '{print $1}'):8501"
echo "PostgreSQL: localhost:5432"
echo "Ollama: localhost:11434"
echo ""
echo "View logs:"
echo "  docker-compose logs -f"
echo ""
echo "Check status:"
echo "  docker-compose ps"
echo "=================================="