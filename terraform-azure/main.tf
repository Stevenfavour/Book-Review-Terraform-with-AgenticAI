terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "bookreview-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnets
resource "azurerm_subnet" "web" {
  name                 = "web-subnet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "app" {
  name                 = "app-subnet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "db" {
  name                 = "db-subnet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.5.0/24"]
  delegation {
    name = "mysql"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}




# Network Security Groups
resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTP"
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
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

   security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowAppPort"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3001"
    source_address_prefix      = azurerm_subnet.web.address_prefixes[0]
    destination_address_prefix = "*"
  }

security_rule {
    name                       = "Allow-SSH-Jump"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    # The guide requires the web-tier subnet as the source 
    source_address_prefix      = azurerm_subnet.web.address_prefixes[0]
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_security_group" "db_nsg" {
  name                = "db-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowMySQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = azurerm_subnet.app.address_prefixes[0]
    destination_address_prefix = "*"
  }
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "web_assoc" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "app_assoc" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "db_assoc" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}


resource "azurerm_public_ip" "natgw" {
  name                = "natgw-PIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "NATGW" {
  name                = "AppNatGateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "assoc" {
  nat_gateway_id       = azurerm_nat_gateway.NATGW.id
  public_ip_address_id = azurerm_public_ip.natgw.id
}

# Public IP for Web LB
resource "azurerm_public_ip" "web_lb_ip" {
  name                = "web-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Public Load Balancer (Web Tier)
resource "azurerm_lb" "web_lb" {
  name                = "web-public-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicFrontEnd"
    public_ip_address_id = azurerm_public_ip.web_lb_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "web_pool" {
  name                = "web-backend-pool"
  loadbalancer_id    = azurerm_lb.web_lb.id
}

resource "azurerm_lb_probe" "web_probe" {
  name                = "web-http-probe"
  loadbalancer_id     = azurerm_lb.web_lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
}

resource "azurerm_lb_rule" "web_rule" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.web_lb.id
  protocol                       = "Tcp"
  frontend_port                   = 80
  backend_port                    = 80
  frontend_ip_configuration_name  = "PublicFrontEnd"
}

# Internal Load Balancer (App Tier)
resource "azurerm_lb" "app_lb" {
  name                = "app-internal-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name      = "PrivateFrontEnd"
    private_ip_address = "10.0.4.100"
    subnet_id = azurerm_subnet.app.id
  }
}

resource "azurerm_lb_backend_address_pool" "app_pool" {
  name             = "app-backend-pool"
  loadbalancer_id  = azurerm_lb.app_lb.id
}

resource "azurerm_lb_probe" "app_probe" {
  name                = "app-tcp-probe"
  loadbalancer_id     = azurerm_lb.app_lb.id
  protocol            = "Tcp"
  port                = 3001
}

resource "azurerm_lb_rule" "app_rule" {
  name                           = "app-tcp-rule"
  loadbalancer_id                = azurerm_lb.app_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 3001
  backend_port                   = 3001
  frontend_ip_configuration_name = "PrivateFrontEnd"
}

# Linux Virtual Machines (Web Tier)
resource "azurerm_linux_virtual_machine" "web_vm" {
  name                = "web-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2ats_v2"
  admin_username      = var.azureuser
  admin_ssh_key {
  username   = "azureuser"
  public_key = file(".ssh/azure_key.pub")
  }


  custom_data = base64encode(file("${path.module}/web_user_data.sh"))
  network_interface_ids = [azurerm_network_interface.web_nic.id]

   source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_network_interface" "web_nic" {
  name                = "web-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "assoc" {
  network_interface_id    = azurerm_network_interface.web_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_pool.id
}


# Linux Virtual Machines (App Tier)
resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "app-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2ats_v2"
  admin_username      = var.admin_username
  admin_password = var.app_vm_password
  custom_data = base64encode(file("${path.module}/app_user_data.sh"))
  network_interface_ids = [azurerm_network_interface.app_nic.id]

  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_network_interface" "app_nic" {
  name                = "app-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "app_assoc" {
  network_interface_id    = azurerm_network_interface.app_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_pool.id
}

resource "azurerm_subnet_nat_gateway_association" "app1_nat_assoc" {
  subnet_id      = azurerm_subnet.app.id
  nat_gateway_id = azurerm_nat_gateway.NATGW.id
}

# MySQL Flexible Server

resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql_link" {
  name                  = "mysql-dns-link"
  resource_group_name    = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = true
}


resource "azurerm_mysql_flexible_server" "mysql" {
  name                = "bookreview-mysql"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  administrator_login = "mysqladmin"
  administrator_password = var.db_password
  version             = "8.4"
  sku_name            = "B_Standard_B1ms"
  backup_retention_days = 7
  create_mode = "Default"
  delegated_subnet_id = azurerm_subnet.db.id
  private_dns_zone_id = azurerm_private_dns_zone.mysql.id

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql_link]
}

# MySQL Read Replica
resource "azurerm_mysql_flexible_server" "mysql_replica" {
  name                = "bookreview-mysql-replica"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  create_mode         = "Replica"
  source_server_id    = azurerm_mysql_flexible_server.mysql.id
  sku_name            = "B_Standard_B1ms"
}
