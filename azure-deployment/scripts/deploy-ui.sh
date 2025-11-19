#!/bin/bash
# Deploy UI Service to Azure VM
# Run this on the UI VM after provisioning

set -e

echo "========================================"
echo "  UI Service Setup"
echo "========================================"
echo ""

# Configuration - Update these with your values
GRAPHRAG_VM_IP="${GRAPHRAG_VM_IP:-10.0.2.4}"
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

# Create application directory
echo "Step 3: Setting up application..."
sudo mkdir -p /opt/ui
cd /opt/ui

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

RUN useradd -m -u 1000 streamlit && chown -R streamlit:streamlit /app
USER streamlit

EXPOSE 8501

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8501/_stcore/health || exit 1

CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0", "--server.headless=true"]
EOF

# Create requirements.txt
sudo tee requirements.txt > /dev/null <<'EOF'
streamlit==1.29.0
requests==2.31.0
pandas==2.1.4
plotly==5.18.0
python-dotenv==1.0.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
EOF

# Create environment file
sudo tee .env > /dev/null <<EOF
GRAPHRAG_API_URL=http://${GRAPHRAG_VM_IP}:8000
DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:5432/${POSTGRES_DB}
EOF

# Build Docker image
echo "Step 4: Building Docker image..."
sudo docker build -t ui-service:latest .

# Create systemd service
echo "Step 5: Creating systemd service..."
sudo tee /etc/systemd/system/ui.service > /dev/null <<EOF
[Unit]
Description=SQL2Doc UI Service
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ui
Restart=always
RestartSec=10
ExecStartPre=-/usr/bin/docker stop ui
ExecStartPre=-/usr/bin/docker rm ui
ExecStart=/usr/bin/docker run --name ui \\
  -p 8501:8501 \\
  --env-file /opt/ui/.env \\
  ui-service:latest

ExecStop=/usr/bin/docker stop ui

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable ui
sudo systemctl start ui

# Optional: Setup nginx reverse proxy
echo "Step 6: Setting up Nginx reverse proxy..."
sudo apt-get install -y nginx

sudo tee /etc/nginx/sites-available/sql2doc > /dev/null <<'NGINX'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:8501;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

sudo ln -sf /etc/nginx/sites-available/sql2doc /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

echo ""
echo "========================================"
echo "  ✅ UI Service Setup Complete!"
echo "========================================"
echo ""
echo "Service Status:"
sudo systemctl status ui --no-pager
echo ""
echo "Test UI:"
echo "  curl http://localhost:8501/_stcore/health"
echo ""
echo "Access UI:"
echo "  http://$(curl -s ifconfig.me)"
echo "  http://$(curl -s ifconfig.me):8501 (direct)"
echo ""
