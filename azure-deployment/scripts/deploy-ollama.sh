#!/bin/bash
# Deploy Ollama Service to Azure VM
# Run this on the Ollama VM after provisioning

set -e

echo "========================================"
echo "  Ollama VM Setup"
echo "========================================"
echo ""

# Update system
echo "Step 1: Updating system..."
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
echo "Step 2: Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install NVIDIA drivers (for GPU support)
echo "Step 3: Installing NVIDIA drivers..."
if lspci | grep -i nvidia; then
    echo "NVIDIA GPU detected, installing drivers..."
    sudo apt-get install -y nvidia-driver-535 nvidia-utils-535

    # Install NVIDIA Container Toolkit
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo systemctl restart docker

    echo "✅ NVIDIA drivers installed"
else
    echo "⚠️  No NVIDIA GPU detected, will run on CPU"
fi

# Pull Ollama image
echo "Step 4: Pulling Ollama Docker image..."
sudo docker pull ollama/ollama:latest

# Create Ollama data directory
sudo mkdir -p /opt/ollama/data

# Create systemd service
echo "Step 5: Creating Ollama systemd service..."
sudo tee /etc/systemd/system/ollama.service > /dev/null <<EOF
[Unit]
Description=Ollama LLM Service
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=root
Restart=always
RestartSec=10
ExecStartPre=-/usr/bin/docker stop ollama
ExecStartPre=-/usr/bin/docker rm ollama
ExecStart=/usr/bin/docker run --name ollama \\
  --gpus all \\
  -p 11434:11434 \\
  -v /opt/ollama/data:/root/.ollama \\
  -e OLLAMA_HOST=0.0.0.0 \\
  ollama/ollama:latest

ExecStop=/usr/bin/docker stop ollama

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama

# Wait for Ollama to start
echo "Step 6: Waiting for Ollama to start..."
sleep 10

# Pull llama3.2 model
echo "Step 7: Pulling llama3.2 model..."
sudo docker exec ollama ollama pull llama3.2

echo ""
echo "========================================"
echo "  ✅ Ollama Setup Complete!"
echo "========================================"
echo ""
echo "Service Status:"
sudo systemctl status ollama --no-pager
echo ""
echo "Test Ollama:"
echo "  curl http://localhost:11434/api/tags"
echo ""
echo "Available externally at:"
echo "  http://$(curl -s ifconfig.me):11434"
echo ""
