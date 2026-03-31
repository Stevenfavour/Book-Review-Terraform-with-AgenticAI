# Infrastructure Template Specification: BookReview Environment

This document outlines the architectural specifications for the BookReview application infrastructure on Azure, managed via Terraform.

Generate these files in the `terraform/` directory:

---
**terraform/main.tf:**
##  Provider & Resource Group
* **Terraform Provider:** `azurerm` version `~> 4.0`
* **Resource Group Name:** `bookreview-rg`
* **Location:** `Norway-East`

---

##  Networking Architecture
The infrastructure is contained within a single Virtual Network (VNet) with the address space **10.0.0.0/16**.

### Subnets & Segmentation
| Subnet Name | Address Prefix | Tier | Purpose |
| :--- | :--- | :--- | :--- |
| `web-subnet-1` | `10.0.1.0/24` | Public/Web | Hosts Nginx reverse proxies |
| `app-subnet-1` | `10.0.3.0/24` | Private/App | Hosts Node.js backend services |
| `db-subnet-1`  | `10.0.5.0/24` | Data | Delegated to `Microsoft.DBforMySQL/flexibleServers` |

### Security Groups (NSG)
* **web-nsg:** Allows inbound traffic on **Port 80** specifically from the Public Load Balancer.
* **app-nsg:** Allows inbound traffic on **Port 3001** restricted to the `web-subnet-1` CIDR.
* **db-nsg:** Allows inbound traffic on **Port 3306** restricted to the `app-subnet-1` CIDR.
* *Note: All subnets are associated with their respective NSGs.*

---

##  Load Balancing
### Public Load Balancer (`web-public-lb`)
* **Frontend IP:** Static Public IP.
* **Backend Pool:** Web Tier VMs.
* **Health Probe:** HTTP on Port 80.

### Internal Load Balancer (`app-internal-lb`)
* **Frontend IP:** Static Private IP **10.0.4.100**.
* **Backend Pool:** App Tier VMs.
* **Health Probe:** TCP on Port 3001.

---

##  Compute & Database
### Virtual Machines (Ubuntu 22.04 LTS)
* **Web Tier:**
    * Automated setup via `user_data`.
    * Software: **Nginx** (configured as a proxy) and **PM2**.
* **App Tier:**
    * No Public IP (Private access only).
    * Software: **Node.js** running on **Port 3001**.

### MySQL Flexible Server
* **Primary Server:** `bookreview-mysql` (deployed in `db-subnet-1`).
* **High Availability:** Read Replica named `bookreview-mysql-replica`.
* **DNS:** Integrated with Private DNS Zone `privatelink.mysql.database.azure.com`.

---

**terraform/outputs.tf:**
Upon successful `terraform apply`, the following values are exposed:

| Output Name | Description |
| :--- | :--- |
| `web_lb_public_ip` | The entry point for browser-based access. |
| `app_lb_private_ip` | The internal IP for the backend (Fixed: 10.0.4.100). |
| `primary_db_fqdn` | The primary MySQL connection string. |
| `replica_db_fqdn` | The read-only replica connection string. |
| `resource_group_name` | The Azure Resource Group hosting the environment. |