# SQL2Doc Azure Deployment - Terraform Configuration
# Deploys microservices architecture across 3 VMs + Azure Database

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-sql2doc-prod"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_key" {
  description = "SSH public key for VM access"
  type        = string
  sensitive   = true
}

variable "postgres_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "SQL2Doc"
    ManagedBy   = "Terraform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-sql2doc"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
  }
}

# Subnets
resource "azurerm_subnet" "ollama" {
  name                 = "subnet-ollama"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "graphrag" {
  name                 = "subnet-graphrag"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "ui" {
  name                 = "subnet-ui"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "database" {
  name                 = "subnet-database"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.4.0/24"]

  delegation {
    name = "postgresql-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "ollama" {
  name                = "nsg-ollama"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-Ollama"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "11434"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "graphrag" {
  name                = "nsg-graphrag"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-API"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "ui" {
  name                = "nsg-ui"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Streamlit"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8501"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Public IPs
resource "azurerm_public_ip" "ollama" {
  name                = "pip-ollama"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Service = "Ollama"
  }
}

resource "azurerm_public_ip" "graphrag" {
  name                = "pip-graphrag"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Service = "GraphRAG"
  }
}

resource "azurerm_public_ip" "ui" {
  name                = "pip-ui"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Service = "UI"
  }
}

# Network Interfaces
resource "azurerm_network_interface" "ollama" {
  name                = "nic-ollama"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ollama.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ollama.id
  }
}

resource "azurerm_network_interface" "graphrag" {
  name                = "nic-graphrag"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.graphrag.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.graphrag.id
  }
}

resource "azurerm_network_interface" "ui" {
  name                = "nic-ui"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ui.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ui.id
  }
}

# Associate NSGs with NICs
resource "azurerm_network_interface_security_group_association" "ollama" {
  network_interface_id      = azurerm_network_interface.ollama.id
  network_security_group_id = azurerm_network_security_group.ollama.id
}

resource "azurerm_network_interface_security_group_association" "graphrag" {
  network_interface_id      = azurerm_network_interface.graphrag.id
  network_security_group_id = azurerm_network_security_group.graphrag.id
}

resource "azurerm_network_interface_security_group_association" "ui" {
  network_interface_id      = azurerm_network_interface.ui.id
  network_security_group_id = azurerm_network_security_group.ui.id
}

# VM 1: Ollama (LLM Inference) - GPU-enabled
resource "azurerm_linux_virtual_machine" "ollama" {
  name                = "vm-ollama"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_NC6s_v3"  # GPU-enabled for better LLM performance
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.ollama.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Service = "Ollama-LLM"
  }
}

# VM 2: GraphRAG Service
resource "azurerm_linux_virtual_machine" "graphrag" {
  name                = "vm-graphrag"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_D4s_v3"  # 4 vCPU, 16 GB RAM
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.graphrag.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Service = "GraphRAG-API"
  }
}

# VM 3: UI Service
resource "azurerm_linux_virtual_machine" "ui" {
  name                = "vm-ui"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B2s"  # 2 vCPU, 4 GB RAM
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.ui.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 32
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Service = "Streamlit-UI"
  }
}

# Azure Database for PostgreSQL
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-sql2doc"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "15"
  delegated_subnet_id    = azurerm_subnet.database.id
  administrator_login    = "sqladmin"
  administrator_password = var.postgres_admin_password
  zone                   = "1"

  storage_mb = 32768
  sku_name   = "GP_Standard_D2s_v3"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = {
    Service = "PostgreSQL"
  }
}

resource "azurerm_postgresql_flexible_server_database" "healthcare" {
  name      = "healthcare_ods_db"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_database" "telecom" {
  name      = "telecom_ocdm_db"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Outputs
output "ollama_public_ip" {
  value       = azurerm_public_ip.ollama.ip_address
  description = "Public IP of Ollama VM"
}

output "graphrag_public_ip" {
  value       = azurerm_public_ip.graphrag.ip_address
  description = "Public IP of GraphRAG VM"
}

output "ui_public_ip" {
  value       = azurerm_public_ip.ui.ip_address
  description = "Public IP of UI VM"
}

output "postgres_fqdn" {
  value       = azurerm_postgresql_flexible_server.main.fqdn
  description = "FQDN of PostgreSQL server"
  sensitive   = true
}

output "connection_instructions" {
  value = <<EOF
SSH Connection:
  Ollama VM:   ssh ${var.admin_username}@${azurerm_public_ip.ollama.ip_address}
  GraphRAG VM: ssh ${var.admin_username}@${azurerm_public_ip.graphrag.ip_address}
  UI VM:       ssh ${var.admin_username}@${azurerm_public_ip.ui.ip_address}

Service URLs:
  UI:       http://${azurerm_public_ip.ui.ip_address}:8501
  GraphRAG: http://${azurerm_public_ip.graphrag.ip_address}:8000
  Ollama:   http://${azurerm_public_ip.ollama.ip_address}:11434

Database:
  Host: ${azurerm_postgresql_flexible_server.main.fqdn}
  Port: 5432
  User: sqladmin
EOF
}
