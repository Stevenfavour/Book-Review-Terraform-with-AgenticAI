variable "location" {
  description = "Azure region"
  default     = "Norway East"
}

variable "resource_group_name" {
  description = "Resource group name"
  default     = "bookreview-rg"
}

variable "admin_username" {
  description = "Admin username for VMs"
  default     = "adminuser"
}

variable "azureuser" {
  description = "Admin username for VMs"
  default     = "azureuser"
}

variable "app_vm_password" {
  description = "Admin password for the app VM"
  type        = string
  sensitive   = true
}

# variable "admin_password" {
#   description = "Admin password for VMs"
#   type        = string
#   sensitive   = false
# }

variable "db_password" {
  description = "MySQL admin password"
  type        = string
  sensitive   = true
}
