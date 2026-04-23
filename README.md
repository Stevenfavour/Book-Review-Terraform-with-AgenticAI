# Book Review App

## Overview

**Book Review App** is a modern, full-stack **three-tier web application** that allows users to browse books, read reviews, and submit their own. It demonstrates clean separation of concerns between frontend and backend, and is ideal for hands-on DevOps and cloud deployment practices.

# Book Review App: Production Azure Deployment

## 🎯 Project Goal
[cite_start]Deploy a high-availability, three-tier web application (Next.js, Node.js, MySQL) using Terraform on Azure with strict network isolation and load balancing.

## 🏗️ Architecture & Regions
- [cite_start]**Primary Region:** Central India.
- [cite_start]**Resource Group:** `bookreview-rg`.
- [cite_start]**Availability:** Multi-zone deployment (Zone 1 and Zone 2).

## 🌐 Networking Plan (VNet: 10.0.0.0/16)
| Subnet | CIDR | Purpose |
| :--- | :--- | :--- |
| `web-subnet-1` | 10.0.1.0/24 | [cite_start]Web Tier VMs (Public facing via LB)  |
| `app-subnet-1` | 10.0.3.0/24 | [cite_start]App Tier VMs (Private)  |
| `db-subnet-1` | 10.0.5.0/24 | [cite_start]MySQL Flexible Server (Private/Delegated)  |

## 🛡️ Security & Access Control
- [cite_start]**Web NSG (`web-nsg`):** Allow Inbound Port 80 from Public Load Balancer.
- [cite_start]**App NSG (`app-nsg`):** Allow Inbound Port 3001 only from Web Subnet.
- [cite_start]**DB NSG (`db-nsg`):** Allow Inbound Port 3306 only from App Subnet.
- [cite_start]**Isolation:** App and DB tiers must NOT have Public IPs.

## 🚀 Component Specifications
### 1. Web Tier (Next.js)
- [cite_start]**Image:** Ubuntu 22.04 LTS (Jammy).
- [cite_start]**Stack:** Nginx (Reverse Proxy) + PM2 (Process Manager).
- [cite_start]**Load Balancer:** `web-public-lb` with Static Public IP.

### 2. App Tier (Node.js)
- [cite_start]**Image:** Ubuntu 22.04 LTS.
- [cite_start]**Port:** 3001.
- [cite_start]**Load Balancer:** `app-internal-lb` (Static IP: 10.0.4.100).

### 3. Database Tier (MySQL)
- [cite_start]**Service:** Azure Database for MySQL Flexible Server.
- [cite_start]**High Availability:** Primary (`bookreview-mysql`) + Read Replica (`bookreview-mysql-replica`).
- [cite_start]**Connectivity:** Private DNS Zone integration required.

## 🤖 Agent Instructions (Strict)
- [cite_start]**Version Lock:** Use `azurerm` provider version `~> 4.0`.
- [cite_start]**Dependency Flow:** Ensure VNet and Subnets are created before NSG associations.
- [cite_start]**LB Config:** Always define Health Probes (HTTP 80 for Web, TCP 3001 for App) before Load Balancing Rules.
- [cite_start]**Variable Safety:** Use `sensitive = true` for `db_password` and `admin_password`.

## 🛠️ Essential Commands
- [cite_start]**Check Syntax:** `terraform validate` 
- [cite_start]**Dry Run:** `terraform plan -out=main.tfplan` 
- [cite_start]**Apply Change:** `terraform apply "main.tfplan"` 
- [cite_start]**Nginx Lint:** `sudo nginx -t`
