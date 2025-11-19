#!/bin/bash
# One-Command Azure Deployment Script
# Deploys entire SQL2Doc microservices architecture to Azure

set -e

echo "=========================================="
echo "  SQL2Doc Azure Deployment"
echo "=========================================="
echo ""

# Check prerequisites
command -v az >/dev/null 2>&1 || { echo "❌ Azure CLI not installed. Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform not installed. Install from: https://www.terraform.io/downloads"; exit 1; }
command -v ssh-keygen >/dev/null 2>&1 || { echo "❌ ssh-keygen not found."; exit 1; }

echo "✅ Prerequisites check passed"
echo ""

# Login to Azure
echo "Step 1: Azure Login"
if ! az account show >/dev/null 2>&1; then
    echo "Please login to Azure..."
    az login
fi

SUBSCRIPTION=$(az account show --query name -o tsv)
echo "✅ Logged in to Azure"
echo "   Subscription: $SUBSCRIPTION"
echo ""

# Generate SSH key if not exists
if [ ! -f ~/.ssh/id_rsa_sql2doc ]; then
    echo "Step 2: Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_sql2doc -N "" -C "sql2doc-azure"
    echo "✅ SSH key generated"
else
    echo "Step 2: Using existing SSH key"
fi
SSH_PUBLIC_KEY=$(cat ~/.ssh/id_rsa_sql2doc.pub)
echo ""

# Prompt for configuration
echo "Step 3: Configuration"
read -p "Resource Group Name [rg-sql2doc-prod]: " RG_NAME
RG_NAME=${RG_NAME:-rg-sql2doc-prod}

read -p "Azure Region [eastus]: " LOCATION
LOCATION=${LOCATION:-eastus}

read -p "Admin Username [azureuser]: " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-azureuser}

read -sp "PostgreSQL Admin Password: " POSTGRES_PASSWORD
echo ""

if [ -z "$POSTGRES_PASSWORD" ]; then
    echo "❌ PostgreSQL password is required"
    exit 1
fi

echo ""
echo "Configuration:"
echo "  Resource Group: $RG_NAME"
echo "  Location: $LOCATION"
echo "  Admin User: $ADMIN_USER"
echo ""

read -p "Proceed with deployment? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Create Terraform variables file
echo "Step 4: Creating Terraform configuration..."
cd terraform

cat > terraform.tfvars <<EOF
resource_group_name      = "$RG_NAME"
location                 = "$LOCATION"
environment              = "production"
admin_username           = "$ADMIN_USER"
admin_ssh_key            = "$SSH_PUBLIC_KEY"
postgres_admin_password  = "$POSTGRES_PASSWORD"
EOF

echo "✅ Configuration created"
echo ""

# Initialize Terraform
echo "Step 5: Initializing Terraform..."
terraform init
echo ""

# Plan deployment
echo "Step 6: Planning deployment..."
terraform plan -out=tfplan
echo ""

read -p "Review the plan above. Continue with apply? (yes/no): " APPLY_CONFIRM
if [ "$APPLY_CONFIRM" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Apply Terraform
echo "Step 7: Deploying infrastructure (this will take 15-20 minutes)..."
terraform apply tfplan

# Get outputs
echo ""
echo "Step 8: Retrieving deployment information..."
OLLAMA_IP=$(terraform output -raw ollama_public_ip)
GRAPHRAG_IP=$(terraform output -raw graphrag_public_ip)
UI_IP=$(terraform output -raw ui_public_ip)
POSTGRES_FQDN=$(terraform output -raw postgres_fqdn)

echo "✅ Infrastructure deployed successfully"
echo ""
echo "Deployment Information:"
echo "  Ollama VM:   $OLLAMA_IP"
echo "  GraphRAG VM: $GRAPHRAG_IP"
echo "  UI VM:       $UI_IP"
echo "  PostgreSQL:  $POSTGRES_FQDN"
echo ""

# Save connection info
cat > ../connection_info.txt <<EOF
SQL2Doc Azure Deployment - Connection Information

SSH Connections:
  Ollama VM:   ssh $ADMIN_USER@$OLLAMA_IP -i ~/.ssh/id_rsa_sql2doc
  GraphRAG VM: ssh $ADMIN_USER@$GRAPHRAG_IP -i ~/.ssh/id_rsa_sql2doc
  UI VM:       ssh $ADMIN_USER@$UI_IP -i ~/.ssh/id_rsa_sql2doc

Service URLs:
  UI Dashboard: http://$UI_IP
  GraphRAG API: http://$GRAPHRAG_IP:8000
  API Docs:     http://$GRAPHRAG_IP:8000/docs

Database:
  Host: $POSTGRES_FQDN
  Port: 5432
  User: sqladmin
  Password: <saved in terraform.tfvars>

Deployment Date: $(date)
EOF

echo "✅ Connection info saved to: connection_info.txt"
echo ""

# Deploy services
echo "=========================================="
echo "  Deploying Services"
echo "=========================================="
echo ""

read -p "Deploy Ollama service now? (yes/no): " DEPLOY_OLLAMA
if [ "$DEPLOY_OLLAMA" == "yes" ]; then
    echo "Deploying Ollama..."
    scp -i ~/.ssh/id_rsa_sql2doc ../scripts/deploy-ollama.sh $ADMIN_USER@$OLLAMA_IP:~/
    ssh -i ~/.ssh/id_rsa_sql2doc $ADMIN_USER@$OLLAMA_IP 'chmod +x deploy-ollama.sh && ./deploy-ollama.sh'
    echo "✅ Ollama deployed"
fi

read -p "Deploy GraphRAG service now? (yes/no): " DEPLOY_GRAPHRAG
if [ "$DEPLOY_GRAPHRAG" == "yes" ]; then
    echo "Deploying GraphRAG..."
    # Copy service files
    scp -i ~/.ssh/id_rsa_sql2doc -r ../../graphrag-service $ADMIN_USER@$GRAPHRAG_IP:~/
    scp -i ~/.ssh/id_rsa_sql2doc ../scripts/deploy-graphrag.sh $ADMIN_USER@$GRAPHRAG_IP:~/

    # Get internal IPs
    OLLAMA_INTERNAL_IP=$(az vm show -d -g $RG_NAME -n vm-ollama --query privateIps -o tsv)

    # Deploy
    ssh -i ~/.ssh/id_rsa_sql2doc $ADMIN_USER@$GRAPHRAG_IP \
        "export OLLAMA_VM_IP=$OLLAMA_INTERNAL_IP && \
         export POSTGRES_HOST=$POSTGRES_FQDN && \
         export POSTGRES_USER=sqladmin && \
         export POSTGRES_PASSWORD='$POSTGRES_PASSWORD' && \
         chmod +x deploy-graphrag.sh && \
         ./deploy-graphrag.sh"
    echo "✅ GraphRAG deployed"
fi

read -p "Deploy UI service now? (yes/no): " DEPLOY_UI
if [ "$DEPLOY_UI" == "yes" ]; then
    echo "Deploying UI..."
    # Copy service files
    scp -i ~/.ssh/id_rsa_sql2doc -r ../../ui-service $ADMIN_USER@$UI_IP:~/
    scp -i ~/.ssh/id_rsa_sql2doc ../scripts/deploy-ui.sh $ADMIN_USER@$UI_IP:~/

    # Get internal IPs
    GRAPHRAG_INTERNAL_IP=$(az vm show -d -g $RG_NAME -n vm-graphrag --query privateIps -o tsv)

    # Deploy
    ssh -i ~/.ssh/id_rsa_sql2doc $ADMIN_USER@$UI_IP \
        "export GRAPHRAG_VM_IP=$GRAPHRAG_INTERNAL_IP && \
         export POSTGRES_HOST=$POSTGRES_FQDN && \
         export POSTGRES_USER=sqladmin && \
         export POSTGRES_PASSWORD='$POSTGRES_PASSWORD' && \
         chmod +x deploy-ui.sh && \
         ./deploy-ui.sh"
    echo "✅ UI deployed"
fi

echo ""
echo "=========================================="
echo "  ✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "Access your SQL2Doc deployment:"
echo "  UI:  http://$UI_IP"
echo "  API: http://$GRAPHRAG_IP:8000/docs"
echo ""
echo "Connection details saved to: connection_info.txt"
echo ""
echo "Next steps:"
echo "  1. Load sample data (see AZURE_DEPLOYMENT_GUIDE.md)"
echo "  2. Configure SSL/TLS for production"
echo "  3. Set up monitoring and alerts"
echo ""
