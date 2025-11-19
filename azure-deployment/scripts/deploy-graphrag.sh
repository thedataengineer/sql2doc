#!/bin/bash
# Deploy GraphRAG Service to Azure VM
# Run this on the GraphRAG VM after provisioning

set -e

echo "========================================"
echo "  GraphRAG Service Setup"
echo "========================================"
echo ""

# Configuration - Update these with your values
OLLAMA_VM_IP="${OLLAMA_VM_IP:-10.0.1.4}"
POSTGRES_HOST="${POSTGRES_HOST:-psql-sql2doc.postgres.database.azure.com}"
POSTGRES_USER="${POSTGRES_USER:-sqladmin}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"
POSTGRES_DB="${POSTGRES_DB:-healthcare_ods_db}"

# Update system
echo "Step 1: Updating system..."
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
echo "Step 2: Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
echo "Step 3: Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create application directory
echo "Step 4: Setting up application..."
sudo mkdir -p /opt/graphrag
cd /opt/graphrag

# Clone repository or copy files
echo "Step 5: Copying application files..."
# In production, you would clone from git or copy from artifact storage
# For now, we'll create the structure

sudo mkdir -p src

# Create Dockerfile
sudo tee Dockerfile > /dev/null <<'EOF'
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd -m -u 1000 graphrag && chown -R graphrag:graphrag /app
USER graphrag

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
EOF

# Create requirements.txt
sudo tee requirements.txt > /dev/null <<'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
ollama>=0.1.0
networkx>=3.0
python-dotenv==1.0.0
EOF

# Create environment file
sudo tee .env > /dev/null <<EOF
OLLAMA_HOST=http://${OLLAMA_VM_IP}:11434
OLLAMA_MODEL=llama3.2
DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:5432/${POSTGRES_DB}
LOG_LEVEL=INFO
EOF

# Build Docker image
echo "Step 6: Building Docker image..."
sudo docker build -t graphrag-service:latest .

# Create systemd service
echo "Step 7: Creating systemd service..."
sudo tee /etc/systemd/system/graphrag.service > /dev/null <<EOF
[Unit]
Description=GraphRAG Microservice
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/graphrag
Restart=always
RestartSec=10
ExecStartPre=-/usr/bin/docker stop graphrag
ExecStartPre=-/usr/bin/docker rm graphrag
ExecStart=/usr/bin/docker run --name graphrag \\
  -p 8000:8000 \\
  --env-file /opt/graphrag/.env \\
  graphrag-service:latest

ExecStop=/usr/bin/docker stop graphrag

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable graphrag
sudo systemctl start graphrag

echo ""
echo "========================================"
echo "  ✅ GraphRAG Service Setup Complete!"
echo "========================================"
echo ""
echo "Service Status:"
sudo systemctl status graphrag --no-pager
echo ""
echo "Test GraphRAG:"
echo "  curl http://localhost:8000/health"
echo ""
echo "Available at:"
echo "  http://$(curl -s ifconfig.me):8000"
echo ""
echo "API Documentation:"
echo "  http://$(curl -s ifconfig.me):8000/docs"
echo ""
