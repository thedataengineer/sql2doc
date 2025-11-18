# SQL2Doc Quick Start Guide

Get sql2doc running on Azure VM in 15 minutes.

---

## Prerequisites

- Azure account
- SSH key pair
- Git repository (GitHub/GitLab/Azure DevOps)

---

## 1. Create Azure VM (5 minutes)

### Via Azure Portal:
1. Go to https://portal.azure.com
2. Create VM:
   - **Image:** Ubuntu 22.04 LTS
   - **Size:** Standard_B2s (minimum)
   - **Authentication:** SSH key
   - **Ports:** 22, 80, 443, 8501
3. Note the Public IP address

---

## 2. Initial Setup (5 minutes)

```bash
# SSH into VM
ssh azureuser@<YOUR_VM_IP>

# Run setup script
curl -fsSL https://raw.githubusercontent.com/yourusername/sql2doc/main/deploy/vm_setup.sh | bash

# Logout and login (for Docker group)
exit
ssh azureuser@<YOUR_VM_IP>
```

---

## 3. Deploy Application (5 minutes)

```bash
# Clone repository
cd /opt
sudo chown -R $USER:$USER sql2doc
cd sql2doc
git clone https://github.com/yourusername/sql2doc.git .

# Configure environment
cp .env.example .env
nano .env  # Edit if needed

# Deploy
docker-compose up -d

# Wait for services
sleep 30

# Check status
docker-compose ps
```

---

## 4. Access Application

Open browser: **http://YOUR_VM_IP:8501**

### Connect to Test Database:
```
Host: localhost
Port: 5432
Database: legal_collections_db
Username: legal_admin
Password: legal_collections_pass

Connection String:
postgresql://legal_admin:legal_collections_pass@localhost:5432/legal_collections_db
```

---

## Quick Commands

```bash
# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop services
docker-compose down

# Start services
docker-compose up -d

# Pull latest code and redeploy
git pull && docker-compose down && docker-compose up -d --build
```

---

## Setup Nginx (Optional)

```bash
# Copy Nginx config
sudo cp deploy/nginx/sql2doc.conf /etc/nginx/sites-available/sql2doc
sudo ln -s /etc/nginx/sites-available/sql2doc /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Access via: http://YOUR_VM_IP (port 80)
```

---

## Setup SSL (Optional)

```bash
# Install certbot
sudo apt install -y certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal is configured
# Access via: https://your-domain.com
```

---

## Troubleshooting

**Services not starting:**
```bash
docker-compose logs streamlit
docker-compose logs postgres
```

**Cannot access application:**
```bash
# Check if running
docker-compose ps

# Check firewall
sudo ufw status

# Check port
sudo netstat -tlnp | grep 8501
```

**Database connection issues:**
```bash
# Check PostgreSQL
docker exec -it sql2doc_postgres psql -U legal_admin -d legal_collections_db
```

---

## Cost Optimization

- Enable auto-shutdown for dev/test VMs
- Use B-series VMs for cost efficiency
- Stop VM when not in use: `az vm deallocate`

---

## Next Steps

- Configure custom domain
- Setup monitoring
- Implement backup strategy
- Review security settings
- Test all features

---

**That's it! Your SQL2Doc instance is ready.**

For detailed documentation: See AZURE_DEPLOYMENT.md