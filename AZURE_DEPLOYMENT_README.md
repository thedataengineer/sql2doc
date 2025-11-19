# Azure Microservices Deployment - Complete Package

🎉 **You now have a production-ready, cloud-native microservices architecture for SQL2Doc!**

## What Was Created

### **1. Microservices Architecture**
```
Ollama VM (GPU)  →  GraphRAG Service  →  UI Service  →  Users
      ↓                    ↓                  ↓
      └────────────────────┴──────────────────┘
                           ↓
                  Azure PostgreSQL
```

### **2. Three Docker Services**

#### **GraphRAG Service** (`graphrag-service/`)
- FastAPI REST API
- Knowledge graph builder
- AI-enhanced documentation generator
- Relationship path finder
- **Port**: 8000
- **Files**:
  - `Dockerfile` - Container definition
  - `api.py` - FastAPI application (600+ lines)
  - `requirements.txt` - Python dependencies
  - `src/graphrag_engine.py` - Core engine

#### **UI Service** (`ui-service/`)
- Streamlit web interface
- Interactive table explorer
- Documentation generator UI
- Relationship visualizer
- **Port**: 8501
- **Files**:
  - `Dockerfile` - Container definition
  - `app.py` - Streamlit application (800+ lines)
  - `requirements.txt` - Python dependencies

#### **Ollama Service** (Docker Hub)
- LLM inference engine
- Llama3.2 model
- **Port**: 11434
- Pre-built official image

### **3. Azure Infrastructure (Terraform)**

#### **Virtual Network**
- **VNet**: 10.0.0.0/16
- **Subnets**:
  - Ollama: 10.0.1.0/24
  - GraphRAG: 10.0.2.0/24
  - UI: 10.0.3.0/24
  - Database: 10.0.4.0/24

#### **3 Virtual Machines**
- **VM1 (Ollama)**: Standard_NC6s_v3 (GPU)
- **VM2 (GraphRAG)**: Standard_D4s_v3 (4 vCPU, 16GB RAM)
- **VM3 (UI)**: Standard_B2s (2 vCPU, 4GB RAM)

#### **Networking**
- 3 Public IPs
- 3 Network Security Groups (NSGs)
- Firewall rules configured
- Internal VM communication enabled

#### **Database**
- Azure Database for PostgreSQL (Flexible Server)
- 2 Databases: healthcare_ods_db, telecom_ocdm_db
- Private network access
- Automated backups

### **4. Deployment Scripts**

#### **Terraform** (`azure-deployment/terraform/`)
- `main.tf` - Complete infrastructure as code (500+ lines)
- Provisions all Azure resources
- Outputs connection information

#### **Service Deployment** (`azure-deployment/scripts/`)
- `deploy-ollama.sh` - Installs and configures Ollama
- `deploy-graphrag.sh` - Deploys GraphRAG service
- `deploy-ui.sh` - Deploys UI service
- All include systemd service definitions

#### **One-Command Deploy** (`azure-deployment/deploy.sh`)
- Interactive deployment wizard
- Handles entire process end-to-end
- Generates SSH keys
- Creates configuration files
- Deploys all services

### **5. Docker Compose** (`docker-compose.microservices.yml`)
- Local testing environment
- Mirrors Azure architecture
- All services networked together
- Use before Azure deployment

### **6. Documentation**

#### **AZURE_DEPLOYMENT_GUIDE.md** (1000+ lines)
Complete deployment guide with:
- Architecture diagrams
- Resource requirements
- Step-by-step instructions
- Security configuration
- Monitoring setup
- Troubleshooting
- Cost optimization
- Backup/DR procedures

#### **GRAPHRAG_GUIDE.md** (500+ lines)
GraphRAG feature documentation

#### **GRAPHRAG_IMPLEMENTATION_SUMMARY.md**
Technical implementation details

## 🚀 Quick Start

### Option 1: One-Command Deployment (Easiest)

```bash
cd azure-deployment
./deploy.sh
```

The script will:
1. ✅ Check prerequisites
2. ✅ Login to Azure
3. ✅ Generate SSH keys
4. ✅ Gather configuration
5. ✅ Deploy infrastructure with Terraform
6. ✅ Deploy all services
7. ✅ Test connectivity

**Total time**: ~30 minutes

### Option 2: Step-by-Step Deployment

```bash
# 1. Deploy infrastructure
cd azure-deployment/terraform
terraform init
terraform plan
terraform apply

# 2. Deploy Ollama
ssh azureuser@<ollama-ip> < ../scripts/deploy-ollama.sh

# 3. Deploy GraphRAG
scp -r ../../graphrag-service azureuser@<graphrag-ip>:~/
ssh azureuser@<graphrag-ip> < ../scripts/deploy-graphrag.sh

# 4. Deploy UI
scp -r ../../ui-service azureuser@<ui-ip>:~/
ssh azureuser@<ui-ip> < ../scripts/deploy-ui.sh
```

### Option 3: Local Testing First

```bash
# Test everything locally
docker-compose -f docker-compose.microservices.yml up

# Access services
# UI:       http://localhost:8501
# GraphRAG: http://localhost:8000
# Ollama:   http://localhost:11434
```

## 📊 Architecture Features

### **1. Service Isolation**
- Each service runs independently
- Can scale horizontally
- Can be updated without downtime
- Can be monitored separately

### **2. Inter-Service Communication**
```
UI → GraphRAG (HTTP REST)
GraphRAG → Ollama (HTTP REST)
GraphRAG → PostgreSQL (TCP)
```

### **3. Security**
- Network Security Groups (NSGs) restrict traffic
- Internal communication on private network
- Public IPs only where needed
- SSH key authentication
- PostgreSQL private access

### **4. High Availability**
- Each service can be replicated
- Azure managed PostgreSQL (99.99% SLA)
- Health checks on all services
- Systemd auto-restart on failure

### **5. Monitoring Ready**
- Health check endpoints
- Systemd logging (journalctl)
- Ready for Azure Monitor integration
- Application Insights compatible

## 📁 File Structure

```
sql2doc/
├── graphrag-service/           # GraphRAG FastAPI Service
│   ├── Dockerfile
│   ├── api.py                  # REST API (600 lines)
│   ├── requirements.txt
│   └── src/
│       └── graphrag_engine.py  # Core engine
│
├── ui-service/                 # Streamlit UI Service
│   ├── Dockerfile
│   ├── app.py                  # Streamlit app (800 lines)
│   └── requirements.txt
│
├── azure-deployment/           # Azure Deployment
│   ├── terraform/
│   │   └── main.tf             # Infrastructure (500 lines)
│   ├── scripts/
│   │   ├── deploy-ollama.sh
│   │   ├── deploy-graphrag.sh
│   │   └── deploy-ui.sh
│   └── deploy.sh               # One-command deploy
│
├── docker-compose.microservices.yml  # Local testing
├── AZURE_DEPLOYMENT_GUIDE.md         # Complete guide
└── test_data/                        # Sample databases
    ├── healthcare_ods_*.sql
    └── telecom_ocdm_*.sql
```

## 💰 Cost Estimate

| Resource | Size | Monthly Cost |
|----------|------|-------------|
| VM1 (Ollama w/ GPU) | Standard_NC6s_v3 | ~$1,000 |
| VM2 (GraphRAG) | Standard_D4s_v3 | ~$150 |
| VM3 (UI) | Standard_B2s | ~$50 |
| PostgreSQL | GP, 2 vCore | ~$120 |
| Network/Storage | - | ~$20 |
| **Total** | | **~$1,340/month** |

### Cost Optimization Options:

1. **CPU-only Ollama**: Use Standard_D8s_v3 instead of GPU
   - Saves: ~$800/month
   - Trade-off: 5-10x slower LLM inference

2. **Reserved Instances** (1-year commitment)
   - Saves: ~30% ($400/month)

3. **Auto-shutdown** (nights/weekends)
   - Saves: ~50% of VM costs

4. **Spot Instances** (non-production)
   - Saves: ~60-90% of VM costs
   - Trade-off: Can be evicted

## 🔐 Security Best Practices

### Before Production:

1. **Restrict NSGs to your IP**:
```bash
az network nsg rule update \
  --resource-group rg-sql2doc-prod \
  --nsg-name nsg-ui \
  --name Allow-SSH \
  --source-address-prefixes "YOUR_IP/32"
```

2. **Enable SSL/TLS**:
```bash
# Install Let's Encrypt certificate
sudo certbot --nginx -d yourdomain.com
```

3. **Configure Azure Firewall**:
```bash
az postgres flexible-server firewall-rule create \
  --resource-group rg-sql2doc-prod \
  --name psql-sql2doc \
  --rule-name AllowGraphRAGVM \
  --start-ip-address <graphrag-internal-ip> \
  --end-ip-address <graphrag-internal-ip>
```

4. **Enable Azure AD Authentication** (instead of passwords)

5. **Set up Azure Key Vault** for secrets management

## 📈 Monitoring & Observability

### Health Check URLs:

```bash
# UI Service
curl http://<ui-ip>:8501/_stcore/health

# GraphRAG Service
curl http://<graphrag-ip>:8000/health

# Ollama Service
curl http://<ollama-ip>:11434/api/tags
```

### Service Logs:

```bash
# SSH to any VM
ssh azureuser@<vm-ip>

# View logs
sudo journalctl -u ollama -f
sudo journalctl -u graphrag -f
sudo journalctl -u ui -f
```

### Azure Monitor Integration:

```bash
# Enable diagnostic settings
az monitor diagnostic-settings create \
  --resource <vm-resource-id> \
  --name DiagSettings \
  --logs '[{"category": "Administrative", "enabled": true}]'
```

## 🧪 Testing

### 1. Test Inter-Service Communication

```bash
# From GraphRAG VM
ssh azureuser@<graphrag-ip>
curl http://10.0.1.4:11434/api/tags  # Test Ollama

# From UI VM
ssh azureuser@<ui-ip>
curl http://10.0.2.4:8000/health    # Test GraphRAG
```

### 2. Test GraphRAG API

```bash
# Build knowledge graph
curl -X POST http://<graphrag-ip>:8000/graph/build \
  -H "Content-Type: application/json" \
  -d '{"database_id": "test", "database_url": "..."}'

# Generate documentation
curl -X POST http://<graphrag-ip>:8000/documentation/generate \
  -H "Content-Type: application/json" \
  -d '{"database_id": "test", "table_name": "patients"}'
```

### 3. Access UI

Open browser: `http://<ui-ip>:8501`

## 🔄 CI/CD Integration

### GitHub Actions Example:

```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Login to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy with Terraform
        run: |
          cd azure-deployment/terraform
          terraform init
          terraform apply -auto-approve
```

## 📚 Documentation Index

1. **AZURE_DEPLOYMENT_GUIDE.md** - Complete deployment guide
2. **GRAPHRAG_GUIDE.md** - GraphRAG features and usage
3. **GRAPHRAG_IMPLEMENTATION_SUMMARY.md** - Technical details
4. **README.md** - Project overview (this file)

## 🆘 Troubleshooting

### Issue: Terraform fails with "quota exceeded"

**Solution**: Request quota increase in Azure Portal

### Issue: Services can't communicate

**Solution**: Check NSG rules and internal IPs

```bash
az vm show -d -g rg-sql2doc-prod -n vm-ollama --query privateIps
```

### Issue: Ollama out of memory

**Solution**: Upgrade to larger GPU VM or use CPU-only

### Issue: High costs

**Solution**: Enable auto-shutdown and use Reserved Instances

```bash
az vm auto-shutdown --resource-group rg-sql2doc-prod \
  --name vm-ollama --time 1900
```

## 🚨 Support

For issues:
1. Check service logs (see Monitoring section)
2. Review Azure Monitor metrics
3. Test health endpoints
4. Check AZURE_DEPLOYMENT_GUIDE.md
5. File GitHub issue with logs

## 🎯 Next Steps

### Immediate:
- [ ] Deploy to Azure using `./deploy.sh`
- [ ] Load sample data
- [ ] Test all services
- [ ] Access UI and generate docs

### Short-term:
- [ ] Configure SSL/TLS
- [ ] Set up monitoring alerts
- [ ] Enable auto-backups
- [ ] Configure auto-shutdown

### Long-term:
- [ ] Set up CI/CD pipeline
- [ ] Migrate to AKS (Kubernetes)
- [ ] Add API Gateway
- [ ] Implement caching layer
- [ ] Multi-region deployment

## 🎉 Success Criteria

You've successfully deployed when:
- ✅ All 3 VMs are running
- ✅ Health checks pass for all services
- ✅ UI accessible via browser
- ✅ Knowledge graph builds successfully
- ✅ AI documentation generates correctly
- ✅ Inter-service communication works

**Congratulations! You now have a production-ready, cloud-native SQL2Doc deployment!** 🎊
