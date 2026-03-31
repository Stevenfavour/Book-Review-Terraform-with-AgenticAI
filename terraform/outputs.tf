output "web_alb_dns_name" {
  description = "Public DNS name of the web Application Load Balancer"
  value       = aws_lb.web_alb.dns_name
}

output "app_nlb_private_ip" {
  description = "Fixed private IP of the internal Network Load Balancer"
  value       = "10.0.3.100"
}

output "primary_db_endpoint" {
  description = "Primary RDS MySQL endpoint"
  value       = aws_db_instance.primary.endpoint
}

output "replica_db_endpoint" {
  description = "Read‑replica RDS MySQL endpoint"
  value       = aws_db_instance.replica.endpoint
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "web_vm_public_ip" {
  description = "The public IP address of the Web VM (Jump Server)"
  value       = aws_instance.web_vm.public_ip
}

# Optional: Output the pre-formatted SSH command for convenience
output "ssh_command" {
  description = "Copy and paste this to login"
  value       = "ssh -i ./.ssh/id_rsa ubuntu@${aws_instance.web_vm.public_ip}"
}