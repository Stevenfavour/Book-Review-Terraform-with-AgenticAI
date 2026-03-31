variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "admin_username" {
  description = "Admin username for instances"
  type        = string
  default     = "ec2user"
}

variable "admin_password" {
  description = "Admin password for instances (if needed)"
  type        = string
  sensitive   = true
}

variable "app_vm_password" {
  description = "Password for the app VM (if needed)"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}



variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "mysql_admin_user" {
  description = "MySQL admin login"
  type        = string
  default     = "mysqladmin"
}


variable "db_password" {
  description = "RDS MySQL admin password"
  type        = string
  sensitive   = true
}



variable "web_user_data" {
  description = "Cloud‑init script for the web VM"
  type        = string
  default = <<-EOF
#!/bin/bash
# Update and install dependencies
apt-get update -y
apt-get install -y nginx git curl

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs

# Install PM2 globally
npm install -g pm2

# Configure Nginx Reverse Proxy
cat <<EOT > /etc/nginx/sites-available/bookreview
server {
    listen 80;
    server_name _;

    # Frontend Next.js App
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Backend API via Internal Load Balancer
    location /api {
        proxy_pass http://10.0.4.100:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOT

# Restart Nginx to apply changes
systemctl restart nginx
systemctl enable nginx
EOF
}

# variable "app_user_data" {
#   description = "Cloud‑init script for the app VM"
#   type        = string
#   default = <<-EOF
# #!/bin/bash
# # Update and install dependencies
# apt-get update -y
# apt-get install -y git curl mysql-client

# # Install Node.js 20
# curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
# apt-get install -y nodejs

# # Install PM2 globally
# npm install -g pm2



# # Clone the repository and install dependencies
# git clone https://github.com/pravinmishraaws/book-review-app
# cd backend/ && npm install
# touch .env

# cat <<EOT > /.env

# DB_HOST=${db_host}
# DB_READ_HOST=${db_read_host}
# DB_USER=mysqladmin
# DB_PASS="${db_pass}"
# DB_NAME=bookreview
# DB_PORT=3306

# PORT=3001
# JWT_SECRET=mysecretkey
# ALLOWED_ORIGINS=http://${aws_lb.my_alb.dns_name},http://localhost:3000
# EOT
# pm2 start server.js --name "backend-api" --port 3001
# EOF
# }

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}
