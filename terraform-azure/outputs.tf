output "web_lb_public_ip" {
  description = "Public IP address of the web load balancer"
  value       = azurerm_public_ip.web_lb_ip.ip_address
}

output "app_lb_private_ip" {
  description = "Private IP address of the internal app load balancer"
  value       = azurerm_lb.app_lb.frontend_ip_configuration[0].private_ip_address
}

output "primary_db_fqdn" {
  description = "FQDN of the primary MySQL flexible server"
  value       = azurerm_mysql_flexible_server.mysql.fqdn
}

output "replica_db_fqdn" {
  description = "FQDN of the read‑replica MySQL server"
  value       = azurerm_mysql_flexible_server.mysql_replica.fqdn
}

output "resource_group_name" {
  description = "Name of the Azure resource group"
  value       = azurerm_resource_group.rg.name
}
