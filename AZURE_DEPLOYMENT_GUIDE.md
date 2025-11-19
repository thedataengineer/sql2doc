

# Azure Deployment Guide - SQL2Doc Microservices

Complete guide for deploying SQL2Doc as microservices across multiple Azure VMs.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Azure Cloud                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐   │
│  │   VM 1       │     │   VM 2       │     │   VM 3       │   │
│  │              │     │              │     │              │   │
│  │   Ollama     │────▶│  GraphRAG    │────▶│     UI       │   │
│  │   (LLM)      │     │   Service    │     │  (Streamlit) │   │
│  │              │     │  (FastAPI)   │     │              │   │
│  │ Port: 11434  │     │  Port: 8000  │     │  Port: 8501  │   │
│  │ GPU-enabled  │     │  CPU-only    │     │  CPU-only    │   │
│  └──────────────┘     └──────────────┘     └──────────────┘   │
│         │                     │                     │          │
│         └─────────────────────┴─────────────────────┘          │
│                              │                                 │
│                   ┌──────────▼──────────┐                      │
│                   │  Azure Database     │                      │
│                   │  for PostgreSQL     │                      │
│                   │  (Managed Service)  │                      │
│                   └─────────────────────┘                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Resource Requirements

### VM 1: Ollama (LLM Inference)
- **Size**: Standard_NC6s_v3 (GPU-enabled)
  - 6 vCPUs
  - 112 GB RAM
  - 1 x NVIDIA Tesla V100 GPU
- **OS**: Ubuntu 22.04 LTS
- **Disk**: 128 GB Premium SSD
- **Estimated Cost**: ~$1,000/month

### VM 2: GraphRAG Service
- **Size**: Standard_D4s_v3
  - 4 vCPUs
  - 16 GB RAM
- **OS**: Ubuntu 22.04 LTS
- **Disk**: 64 GB Premium SSD
- **Estimated Cost**: ~$150/month

### VM 3: UI Service
- **Size**: Standard_B2s
  - 2 vCPUs
  - 4 GB RAM
- **OS**: Ubuntu 22.04 LTS
- **Disk**: 32 GB Standard SSD
- **Estimated Cost**: ~$50/month

### Azure Database for PostgreSQL
- **Tier**: General Purpose
- **Compute**: Standard_D2s_v3 (2 vCPUs, 8 GB RAM)
- **Storage**: 32 GB
- **Estimated Cost**: ~$120/month

**Total Estimated Cost**: ~$1,320/month

## Prerequisites

1. **Azure Account** with active subscription
2. **Azure CLI** installed locally
3. **Terraform** installed (v1.0+)
4. **SSH Key Pair** generated
5. **Git** for cloning repository

## Deployment Steps

### Option 1: Terraform Deployment (Recommended)

#### 1. Setup Terraform

```bash
# Clone repository
git clone <your-repo-url>
cd sql2doc/azure-deployment/terraform

# Initialize Terraform
terraform init
```

#### 2. Configure Variables

Create `terraform.tfvars`:

```hcl
resource_group_name = "rg-sql2doc-prod"
location            = "eastus"
environment         = "production"
admin_username      = "azureuser"
admin_ssh_key       = "ssh-rsa AAAAB3Nza... your-public-key"
postgres_admin_password = "YourSecurePassword123!"
```

#### 3. Review Plan

```bash
terraform plan
```

#### 4. Deploy Infrastructure

```bash
terraform apply
```

This will create:
- Resource Group
- Virtual Network with 4 subnets
- 3 Virtual Machines
- Network Security Groups
- Public IPs
- Azure Database for PostgreSQL
- All networking configuration

Deployment takes approximately 15-20 minutes.

#### 5. Note Output Values

After deployment, Terraform will output:

```
ollama_public_ip    = "20.X.X.X"
graphrag_public_ip  = "20.Y.Y.Y"
ui_public_ip        = "20.Z.Z.Z"
postgres_fqdn       = "psql-sql2doc.postgres.database.azure.com"
```

Save these values for the next steps.

### Option 2: Manual Azure CLI Deployment

See `azure-deployment/scripts/manual-deploy.sh` for step-by-step Azure CLI commands.

## Service Configuration

### 1. Deploy Ollama Service

SSH into Ollama VM:

```bash
ssh azureuser@<ollama_public_ip>
```

Copy and run deployment script:

```bash
# Upload script
scp azure-deployment/scripts/deploy-ollama.sh azureuser@<ollama_public_ip>:~/

# SSH and run
ssh azureuser@<ollama_public_ip>
chmod +x deploy-ollama.sh
./deploy-ollama.sh
```

This script will:
- Install Docker
- Install NVIDIA drivers (if GPU available)
- Pull Ollama image
- Pull llama3.2 model
- Create systemd service
- Start Ollama

**Verification:**
```bash
curl http://localhost:11434/api/tags
```

### 2. Deploy GraphRAG Service

Copy application code to VM:

```bash
# Upload GraphRAG service files
scp -r graphrag-service/ azureuser@<graphrag_public_ip>:/tmp/

# Upload deployment script
scp azure-deployment/scripts/deploy-graphrag.sh azureuser@<graphrag_public_ip>:~/
```

SSH and deploy:

```bash
ssh azureuser@<graphrag_public_ip>

# Set environment variables
export OLLAMA_VM_IP="10.0.1.4"  # Internal IP of Ollama VM
export POSTGRES_HOST="psql-sql2doc.postgres.database.azure.com"
export POSTGRES_USER="sqladmin"
export POSTGRES_PASSWORD="YourSecurePassword123!"
export POSTGRES_DB="healthcare_ods_db"

# Run deployment
chmod +x deploy-graphrag.sh
./deploy-graphrag.sh
```

**Verification:**
```bash
curl http://localhost:8000/health
```

### 3. Deploy UI Service

Copy application code:

```bash
# Upload UI service files
scp -r ui-service/ azureuser@<ui_public_ip>:/tmp/

# Upload deployment script
scp azure-deployment/scripts/deploy-ui.sh azureuser@<ui_public_ip>:~/
```

SSH and deploy:

```bash
ssh azureuser@<ui_public_ip>

# Set environment variables
export GRAPHRAG_VM_IP="10.0.2.4"  # Internal IP of GraphRAG VM
export POSTGRES_HOST="psql-sql2doc.postgres.database.azure.com"
export POSTGRES_USER="sqladmin"
export POSTGRES_PASSWORD="YourSecurePassword123!"
export POSTGRES_DB="healthcare_ods_db"

# Run deployment
chmod +x deploy-ui.sh
./deploy-ui.sh
```

**Verification:**
```bash
curl http://localhost:8501/_stcore/health
```

### 4. Load Sample Data

SSH into any VM with PostgreSQL access:

```bash
# Upload SQL files
scp test_data/*.sql azureuser@<graphrag_public_ip>:~/

# SSH and load data
ssh azureuser@<graphrag_public_ip>

# Load healthcare schema
psql -h psql-sql2doc.postgres.database.azure.com \
     -U sqladmin \
     -d healthcare_ods_db \
     -f healthcare_ods_schema.sql

psql -h psql-sql2doc.postgres.database.azure.com \
     -U sqladmin \
     -d healthcare_ods_db \
     -f healthcare_ods_sample_data.sql

psql -h psql-sql2doc.postgres.database.azure.com \
     -U sqladmin \
     -d healthcare_ods_db \
     -f healthcare_ods_procedures.sql

# Load telecom schema
psql -h psql-sql2doc.postgres.database.azure.com \
     -U sqladmin \
     -d telecom_ocdm_db \
     -f telecom_ocdm_schema.sql

# ... (repeat for other files)
```

## Testing the Deployment

### 1. Test Inter-Service Communication

```bash
# From GraphRAG VM, test Ollama
curl http://10.0.1.4:11434/api/tags

# From UI VM, test GraphRAG
curl http://10.0.2.4:8000/health
```

### 2. Test GraphRAG API

```bash
# Build knowledge graph
curl -X POST http://<graphrag_public_ip>:8000/graph/build \
  -H "Content-Type: application/json" \
  -d '{
    "database_id": "healthcare",
    "database_url": "postgresql://sqladmin:pass@psql-sql2doc.postgres.database.azure.com:5432/healthcare_ods_db"
  }'

# Get tables
curl http://<graphrag_public_ip>:8000/graph/healthcare/tables

# Generate documentation
curl -X POST http://<graphrag_public_ip>:8000/documentation/generate \
  -H "Content-Type: application/json" \
  -d '{
    "database_id": "healthcare",
    "table_name": "patients"
  }'
```

### 3. Test UI

Open browser and navigate to:
```
http://<ui_public_ip>
```

## Security Configuration

### 1. Update Network Security Groups

```bash
# Restrict SSH access to your IP only
az network nsg rule update \
  --resource-group rg-sql2doc-prod \
  --nsg-name nsg-ollama \
  --name Allow-SSH \
  --source-address-prefixes "YOUR_IP/32"

# Repeat for other NSGs
```

### 2. Enable SSL/TLS

For production, enable HTTPS:

```bash
# On UI VM, install certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d your-domain.com
```

### 3. Configure Azure Firewall Rules

```bash
# Limit PostgreSQL access to specific IPs
az postgres flexible-server firewall-rule create \
  --resource-group rg-sql2doc-prod \
  --name psql-sql2doc \
  --rule-name AllowGraphRAGVM \
  --start-ip-address 10.0.2.4 \
  --end-ip-address 10.0.2.4
```

### 4. Enable Azure Monitor

```bash
# Enable diagnostic settings for each VM
az monitor diagnostic-settings create \
  --resource /subscriptions/<sub-id>/resourceGroups/rg-sql2doc-prod/providers/Microsoft.Compute/virtualMachines/vm-ollama \
  --name DiagSettings \
  --logs '[{"category": "Administrative", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]'
```

## Monitoring and Maintenance

### View Logs

```bash
# Ollama logs
ssh azureuser@<ollama_public_ip>
sudo journalctl -u ollama -f

# GraphRAG logs
ssh azureuser@<graphrag_public_ip>
sudo journalctl -u graphrag -f

# UI logs
ssh azureuser@<ui_public_ip>
sudo journalctl -u ui -f
```

### Service Management

```bash
# Restart services
sudo systemctl restart ollama
sudo systemctl restart graphrag
sudo systemctl restart ui

# Check status
sudo systemctl status ollama
sudo systemctl status graphrag
sudo systemctl status ui
```

### Update Services

```bash
# On GraphRAG VM
cd /opt/graphrag
git pull  # or copy new files
sudo docker build -t graphrag-service:latest .
sudo systemctl restart graphrag

# Similar for UI
```

## Scaling Considerations

### Horizontal Scaling

1. **UI Service**: Deploy multiple UI VMs behind Azure Load Balancer
2. **GraphRAG Service**: Use Azure Container Instances or AKS for auto-scaling
3. **Ollama**: Consider multiple Ollama instances with load balancing

### Vertical Scaling

```bash
# Resize VM (requires downtime)
az vm deallocate --resource-group rg-sql2doc-prod --name vm-graphrag
az vm resize --resource-group rg-sql2doc-prod --name vm-graphrag --size Standard_D8s_v3
az vm start --resource-group rg-sql2doc-prod --name vm-graphrag
```

## Backup and Disaster Recovery

### Database Backups

Azure Database for PostgreSQL provides automatic backups.

**Manual backup:**
```bash
pg_dump -h psql-sql2doc.postgres.database.azure.com \
        -U sqladmin \
        -d healthcare_ods_db \
        > backup_$(date +%Y%m%d).sql
```

### VM Snapshots

```bash
# Create snapshot
az snapshot create \
  --resource-group rg-sql2doc-prod \
  --name snapshot-vm-ollama-$(date +%Y%m%d) \
  --source /subscriptions/<sub-id>/resourceGroups/rg-sql2doc-prod/providers/Microsoft.Compute/disks/vm-ollama-disk
```

## Cost Optimization

1. **Auto-shutdown**: Configure VMs to shut down during off-hours
2. **Reserved Instances**: Purchase 1-3 year reservations for 30-60% savings
3. **Spot Instances**: Use for non-critical workloads
4. **Right-sizing**: Monitor usage and adjust VM sizes

```bash
# Enable auto-shutdown
az vm auto-shutdown \
  --resource-group rg-sql2doc-prod \
  --name vm-ollama \
  --time 1900
```

## Troubleshooting

### Issue: GraphRAG can't connect to Ollama

```bash
# Check Ollama is accessible
curl http://10.0.1.4:11434/api/tags

# Check NSG rules
az network nsg rule list \
  --resource-group rg-sql2doc-prod \
  --nsg-name nsg-ollama \
  --output table

# Check GraphRAG logs
ssh azureuser@<graphrag_public_ip>
sudo journalctl -u graphrag -n 100
```

### Issue: UI can't connect to GraphRAG

```bash
# Test from UI VM
ssh azureuser@<ui_public_ip>
curl http://10.0.2.4:8000/health

# Check GraphRAG service status
ssh azureuser@<graphrag_public_ip>
sudo systemctl status graphrag
```

### Issue: Database connection failures

```bash
# Test PostgreSQL connectivity
psql -h psql-sql2doc.postgres.database.azure.com \
     -U sqladmin \
     -d healthcare_ods_db \
     -c "SELECT version();"

# Check firewall rules
az postgres flexible-server firewall-rule list \
  --resource-group rg-sql2doc-prod \
  --name psql-sql2doc
```

## Cleanup

To destroy all resources:

```bash
# Using Terraform
cd azure-deployment/terraform
terraform destroy

# Or manually
az group delete --name rg-sql2doc-prod --yes
```

## Support

For issues or questions:
1. Check logs first (see Monitoring section)
2. Review Azure Monitor metrics
3. Check service health endpoints
4. File an issue in the repository

## Next Steps

1. **CI/CD Pipeline**: Set up Azure DevOps or GitHub Actions for automated deployments
2. **Container Orchestration**: Migrate to Azure Kubernetes Service (AKS)
3. **API Gateway**: Add Azure API Management for rate limiting and caching
4. **CDN**: Use Azure CDN for static assets
5. **Monitoring**: Integrate Application Insights for detailed telemetry
