# Push to Git Repository & Deploy to Azure

Step-by-step guide to push your code to a Git repository and deploy to Azure VM.

---

## Option 1: GitHub

### 1. Create GitHub Repository

**Via GitHub Web:**
1. Go to https://github.com/new
2. Repository name: `sql2doc`
3. Description: "SQL Data Dictionary Generator with AI"
4. Public or Private: Your choice
5. **DO NOT** initialize with README
6. Click "Create repository"

### 2. Push Code to GitHub

```bash
# In your local sql2doc directory
cd /Users/karteek/dev/personal/experiments/experiment/sql2doc

# Add GitHub remote
git remote add origin https://github.com/YOUR_USERNAME/sql2doc.git

# Or if using SSH:
git remote add origin git@github.com:YOUR_USERNAME/sql2doc.git

# Push code
git push -u origin main

# Enter your GitHub credentials when prompted
```

### 3. Verify Upload

Visit: https://github.com/YOUR_USERNAME/sql2doc

---

## Option 2: Azure DevOps

### 1. Create Azure DevOps Repository

**Via Azure DevOps Web:**
1. Go to https://dev.azure.com
2. Create new project: `sql2doc`
3. Go to Repos → Files
4. Copy the clone URL

### 2. Push Code to Azure DevOps

```bash
# In your local sql2doc directory
cd /Users/karteek/dev/personal/experiments/experiment/sql2doc

# Add Azure DevOps remote
git remote add origin https://YOUR_ORG@dev.azure.com/YOUR_ORG/sql2doc/_git/sql2doc

# Or use the URL from Azure DevOps
git remote add origin <YOUR_AZURE_DEVOPS_REPO_URL>

# Push code
git push -u origin main

# Authenticate with Azure DevOps credentials
```

---

## Option 3: GitLab

### 1. Create GitLab Repository

**Via GitLab Web:**
1. Go to https://gitlab.com/projects/new
2. Project name: `sql2doc`
3. Visibility: Your choice
4. **Uncheck** "Initialize repository with a README"
5. Click "Create project"

### 2. Push Code to GitLab

```bash
# In your local sql2doc directory
cd /Users/karteek/dev/personal/experiments/experiment/sql2doc

# Add GitLab remote
git remote add origin https://gitlab.com/YOUR_USERNAME/sql2doc.git

# Or if using SSH:
git remote add origin git@gitlab.com:YOUR_USERNAME/sql2doc.git

# Push code
git push -u origin main
```

---

## Deploy to Azure VM

### Quick Method (5 minutes)

Once your code is in a Git repository:

```bash
# 1. SSH into your Azure VM
ssh azureuser@<YOUR_VM_IP>

# 2. Run the setup script (one-time)
curl -fsSL https://raw.githubusercontent.com/thedataengineer/sql2doc/main/deploy/vm_setup.sh | bash

# 3. Logout and login
exit
ssh azureuser@<YOUR_VM_IP>

# 4. Clone your repository
sudo mkdir -p /opt/sql2doc
sudo chown -R $USER:$USER /opt/sql2doc
cd /opt/sql2doc
git clone https://github.com/thedataengineer/sql2doc.git .

# 5. Configure environment
cp .env.example .env

# 6. Deploy!
docker-compose up -d

# 7. Check status
docker-compose ps
docker-compose logs -f
```

### Access Your Application

Open browser: `http://YOUR_VM_IP:8501`

---

## Automated Deployment Script

For easier deployments, use the provided script:

```bash
# On Azure VM
cd /opt/sql2doc
./deploy/deploy.sh
```

This script will:
- Backup database
- Pull latest code
- Rebuild containers
- Restart services
- Run health checks

---

## Setup Continuous Deployment (Optional)

### GitHub Actions (for GitHub)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Azure VM

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to VM
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.VM_HOST }}
          username: azureuser
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /opt/sql2doc
            git pull
            ./deploy/deploy.sh
```

Add secrets in GitHub:
- `VM_HOST`: Your VM public IP
- `SSH_PRIVATE_KEY`: Your SSH private key

### Azure DevOps Pipeline

Create `azure-pipelines.yml`:

```yaml
trigger:
  - main

pool:
  vmImage: ubuntu-latest

steps:
- task: SSH@0
  inputs:
    sshEndpoint: 'Azure VM'
    runOptions: 'commands'
    commands: |
      cd /opt/sql2doc
      git pull
      ./deploy/deploy.sh
```

---

## Update Deployment Scripts with Your Repository URL

After creating your repository, update these files:

### 1. Update QUICKSTART.md

```bash
# Edit line 51
nano QUICKSTART.md

# Change:
git clone https://github.com/yourusername/sql2doc.git .

# To:
git clone https://github.com/YOUR_ACTUAL_USERNAME/sql2doc.git .
```

### 2. Update AZURE_DEPLOYMENT.md

```bash
# Edit deployment examples
nano AZURE_DEPLOYMENT.md

# Update all repository URLs
```

### 3. Commit and push changes

```bash
git add .
git commit -m "Update deployment URLs"
git push
```

---

## Verify Everything Works

### On Azure VM:

```bash
# Check all services are running
docker-compose ps

# Expected output:
# NAME                     STATUS
# sql2doc_postgres         Up (healthy)
# sql2doc_ollama           Up
# sql2doc_streamlit        Up

# Test database connection
docker exec -it sql2doc_postgres psql -U legal_admin -d legal_collections_db -c "SELECT COUNT(*) FROM cases;"

# Test Ollama
docker exec sql2doc_ollama ollama list

# View application logs
docker-compose logs streamlit --tail=50
```

### From Your Browser:

1. Open: `http://YOUR_VM_IP:8501`
2. You should see SQL2Doc interface
3. Try connecting to the database:
   ```
   postgresql://legal_admin:legal_collections_pass@localhost:5432/legal_collections_db
   ```
4. Generate a data dictionary
5. Test AI features (if Ollama is ready)

---

## Common Issues

### Permission Denied on VM

```bash
# Fix ownership
sudo chown -R $USER:$USER /opt/sql2doc
```

### Docker Group Not Active

```bash
# Logout and login again
exit
ssh azureuser@<VM_IP>

# Or add to group manually
sudo usermod -aG docker $USER
```

### Port 8501 Not Accessible

```bash
# Check firewall
sudo ufw status

# Allow port if needed
sudo ufw allow 8501/tcp

# Check Azure NSG in portal
```

### Git Authentication Issues

```bash
# Use personal access token instead of password
# Generate at: https://github.com/settings/tokens

# Or setup SSH keys
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub
# Add to GitHub: https://github.com/settings/keys
```

---

## Repository Structure After Push

```
sql2doc/
├── .github/workflows/        # CI/CD (if using GitHub Actions)
├── deploy/
│   ├── deploy.sh            # Deployment script
│   ├── vm_setup.sh          # VM initialization
│   ├── nginx/
│   │   └── sql2doc.conf     # Nginx config
│   └── systemd/
│       └── sql2doc.service  # Systemd service
├── src/                     # Application code
├── test_data/              # Sample database
├── docker-compose.yml      # Container orchestration
├── Dockerfile             # Application image
├── .env.example           # Environment template
├── AZURE_DEPLOYMENT.md    # Detailed deployment guide
└── QUICKSTART.md          # Quick start guide
```

---

## Next Steps

1. ✅ Push code to Git repository
2. ✅ Create Azure VM
3. ✅ Run setup script
4. ✅ Deploy application
5. 🔧 Configure custom domain (optional)
6. 🔒 Setup SSL with Let's Encrypt
7. 📊 Configure monitoring
8. 💾 Setup automated backups

---

## Cost Tracking

Monitor your Azure costs:

```bash
# Via Azure CLI
az consumption usage list --query "[].{Date:usageStart, Cost:pretaxCost}"

# Or check Azure Portal:
# Cost Management + Billing → Cost Analysis
```

---

## Support

If you encounter issues:

1. Check logs: `docker-compose logs -f`
2. Verify services: `docker-compose ps`
3. Review documentation: `AZURE_DEPLOYMENT.md`
4. Check Azure VM diagnostics in portal

---

**Ready to deploy!** 🚀

Follow the steps above to push your code and get sql2doc running on Azure.