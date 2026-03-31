# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 1️⃣ Common Development Commands

| Scope | Command | Description |
|-------|---------|-------------|
| **Terraform (Azure)** | `terraform validate` | Verify Terraform configuration syntax. |
| | `terraform plan -out=main.tfplan` | Generate an execution plan and save it to `main.tfplan`. |
| | `terraform apply "main.tfplan"` | Apply the saved plan to provision Azure resources. |
| | `terraform destroy` | Tear‑down all Azure resources created by this configuration (use with caution). |
| | `terraform fmt` | Reformat Terraform files according to canonical style. |
| | `terraform init` | Initialise the working directory (download provider plugins). |

---

## 2️⃣ High‑Level Architecture

The Terraform code defines a three‑tier Azure infrastructure consisting of:

1. **Network Layer** – A virtual network (`10.0.0.0/16`) with three sub‑nets (web, app, db). Each subnet is associated with its own Network Security Group (NSG) controlling inbound traffic.
2. **Compute Layer** – Two Linux virtual machines (`web‑vm` and `app‑vm`) placed in the web and app subnets, respectively. Each VM is attached to a network interface that is linked to a load‑balancer backend pool.
3. **Load Balancing** –
   * Public Load Balancer (`web‑lb`) exposing port 80.
   * Internal Load Balancer (`app‑lb`) exposing port 3001 for intra‑VNet traffic.
4. **Database Layer** – A MySQL Flexible Server deployed into the db subnet via subnet delegation. A read‑replica is also provisioned.
5. **Supporting Resources** – NAT gateway for outbound traffic from the app subnet, private DNS zone for MySQL connectivity, and static public IPs for the load balancers.

The architecture enables isolation between tiers, with the web NSG allowing HTTP/HTTPS and SSH, the app NSG permitting traffic from the web subnet on the application port (3001), and the db NSG only accepting MySQL connections from the app subnet.

---

## 3️⃣ Development Workflow Summary

1. **Initialise** – Run `terraform init` once to download provider plugins.
2. **Validate** – Use `terraform validate` after any change to catch syntax errors.
3. **Plan** – Execute `terraform plan -out=main.tfplan` to preview changes.
4. **Apply** – Deploy with `terraform apply "main.tfplan"`.
5. **Inspect Outputs** – After apply, useful values are available via `terraform output` (e.g., public IPs, DB FQDNs).
6. **Destroy** – When the environment is no longer needed, run `terraform destroy`.

---

## 4️⃣ Important Project Files

| Path | Purpose |
|------|---------|
| `terraform/main.tf` | Core Terraform resources (VNet, subnets, NSGs, VMs, load balancers, MySQL). |
| `terraform/variables.tf` | Input variables (location, resource group, admin user, DB password). |
| `terraform/outputs.tf` | Exported values such as load balancer IPs and DB FQDNs. |
| `terraform/.terraform.lock.hcl` | Provider version lock file. |
| `terraform/.ssh/azure_key*` | SSH key pair used for VM access (do not commit secrets). |

---

## 5️⃣ Quick Reference for New Contributors

* **Start a new environment:**
  ```
  cd terraform
  terraform init
  terraform validate
  terraform plan -out=main.tfplan
  terraform apply "main.tfplan"
  ```
* **View useful outputs:** `terraform output` (e.g., `web_lb_public_ip`).
* **Tear down resources:** `terraform destroy`.
* **Refresh state after external changes:** `terraform refresh`.
* **Formatting:** `terraform fmt` to keep HCL files tidy.

---

*This CLAUDE.md file focuses on the concrete commands, architecture, and workflow that are unique to this repository.*