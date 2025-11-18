# Database Driver Installation Guide

This guide provides installation instructions for all supported database drivers.

## Quick Start

```bash
# Install core dependencies
pip install -r requirements.txt
```

---

## SQL Databases

### PostgreSQL ✅
**Pre-installed via:** `psycopg2-binary`

**Connection String:**
```
postgresql://username:password@localhost:5432/database
```

---

### MySQL ✅
**Pre-installed via:** `pymysql`

**Connection String:**
```
mysql+pymysql://username:password@localhost:3306/database
```

---

### SQLite ✅
**Pre-installed via:** SQLAlchemy (built-in)

**Connection String:**
```
sqlite:///path/to/database.db
```

---

### SQL Server

#### macOS (Recommended: FreeTDS)

SQL Server support on macOS uses FreeTDS, an open-source TDS protocol implementation.

**Install FreeTDS:**
```bash
brew install unixodbc freetds
```

**Install pyodbc:**
```bash
pip install pyodbc
```

**Connection String:**
```
mssql+pyodbc://username:password@localhost:1433/database?driver=FreeTDS&TDS_Version=7.4
```

**Verify Installation:**
```bash
# Check ODBC drivers
odbcinst -q -d

# Should show FreeTDS
```

**Troubleshooting:**
If FreeTDS isn't detected, configure it manually:

```bash
# Edit odbcinst.ini
nano /opt/homebrew/etc/odbcinst.ini

# Add this section:
[FreeTDS]
Description = FreeTDS Driver
Driver = /opt/homebrew/lib/libtdsodbc.so
Setup = /opt/homebrew/lib/libtdsodbc.so
```

#### Linux (Ubuntu/Debian)

**Install Microsoft ODBC Driver:**
```bash
# Add Microsoft repository
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list

# Install driver
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18

# Install pyodbc
pip install pyodbc
```

**Connection String:**
```
mssql+pyodbc://username:password@localhost:1433/database?driver=ODBC+Driver+18+for+SQL+Server
```

#### Windows

**Install ODBC Driver:**
1. Download from: https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server
2. Run installer (ODBC Driver 18 for SQL Server)

**Install pyodbc:**
```bash
pip install pyodbc
```

**Connection String:**
```
mssql+pyodbc://username:password@localhost:1433/database?driver=ODBC+Driver+18+for+SQL+Server
```

---

## NoSQL Databases

### MongoDB

**Install Driver:**
```bash
pip install pymongo
```

**Connection String:**
```
# With authentication
mongodb://username:password@localhost:27017/database

# Without authentication (local dev)
mongodb://localhost:27017/database
```

**Local MongoDB Installation (optional):**
```bash
# macOS
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community

# Linux
sudo apt-get install mongodb

# Verify
mongo --version
```

---

### Neo4j

**Install Driver:**
```bash
pip install neo4j
```

**Connection Details:**
- **Connection String:** `neo4j://localhost:7687`
- **Authentication:** Provided separately (username/password fields in UI)
- **Default Credentials:** neo4j/password (change after first login)

**Local Neo4j Installation (optional):**
```bash
# macOS
brew install neo4j
brew services start neo4j

# Access Neo4j Browser
open http://localhost:7474

# Linux
wget -O - https://debian.neo4j.com/neotechnology.gpg.key | sudo apt-key add -
echo 'deb https://debian.neo4j.com stable latest' | sudo tee /etc/apt/sources.list.d/neo4j.list
sudo apt update
sudo apt install neo4j
sudo systemctl start neo4j

# Verify
neo4j --version
```

---

## Verification

### Test Database Connections

**PostgreSQL:**
```bash
psql -h localhost -U postgres -d mydb
```

**MySQL:**
```bash
mysql -h localhost -u root -p
```

**SQL Server (via FreeTDS):**
```bash
tsql -H localhost -p 1433 -U sa -P password -D mydb
```

**MongoDB:**
```bash
mongosh mongodb://localhost:27017/mydb
```

**Neo4j:**
```bash
cypher-shell -a neo4j://localhost:7687 -u neo4j -p password
```

---

## Docker Alternative (All Databases)

If you prefer Docker for local development:

### PostgreSQL
```bash
docker run --name postgres -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres:15
```

### MySQL
```bash
docker run --name mysql -e MYSQL_ROOT_PASSWORD=password -p 3306:3306 -d mysql:8
```

### SQL Server
```bash
docker run --name sqlserver -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=YourStrong@Pass' -p 1433:1433 -d mcr.microsoft.com/mssql/server:2022-latest
```

### MongoDB
```bash
docker run --name mongodb -p 27017:27017 -d mongo:7
```

### Neo4j
```bash
docker run --name neo4j -p 7474:7474 -p 7687:7687 -e NEO4J_AUTH=neo4j/password -d neo4j:5
```

---

## Troubleshooting

### pyodbc Issues (SQL Server)

**Error: "Can't open lib"**
- Solution: Ensure FreeTDS is installed and configured
- Check: `odbcinst -q -d` shows FreeTDS

**Error: "Driver not found"**
- macOS: Use `driver=FreeTDS` in connection string
- Linux/Windows: Use `driver=ODBC+Driver+18+for+SQL+Server`

### MongoDB Connection Issues

**Error: "Server selection timeout"**
- Check MongoDB is running: `brew services list` (macOS) or `systemctl status mongodb` (Linux)
- Verify port 27017 is open: `lsof -i :27017`

### Neo4j Connection Issues

**Error: "Unable to retrieve routing table"**
- Ensure Neo4j is running: `brew services list` (macOS)
- Check port 7687 is open: `lsof -i :7687`
- Verify credentials (default: neo4j/password)

---

## Optional: Make SQL Server Driver Optional

If you don't need SQL Server support, comment it out in requirements.txt:

```
# pyodbc>=5.0.0  # SQL Server (commented out)
```

The app will gracefully handle the missing driver and still work for other databases.

---

## Support

For database-specific connection issues, refer to:
- PostgreSQL: https://www.postgresql.org/docs/
- MySQL: https://dev.mysql.com/doc/
- SQL Server: https://learn.microsoft.com/en-us/sql/
- MongoDB: https://www.mongodb.com/docs/
- Neo4j: https://neo4j.com/docs/