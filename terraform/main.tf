terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -------------------------------------------------
# VPC and Subnets
# -------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "bookreview-vpc"
  }
}

resource "aws_subnet" "web" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "web-subnet"
  }
}

resource "aws_subnet" "app" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "app-subnet"
  }
}

resource "aws_subnet" "db2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "db2-subnet"
  }
}


resource "aws_subnet" "db" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "db-subnet"
  }
}


# -------------------------------------------------
# Internet Gateway and Routing
# -------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "bookreview-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "web_rt" {
  subnet_id      = aws_subnet.web.id
  route_table_id = aws_route_table.public.id
}

# -------------------------------------------------
# NAT Gateway for Private Subnets
# -------------------------------------------------
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.web.id
  tags = {
    Name = "bookreview-nat"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "app_rt" {
  subnet_id      = aws_subnet.app.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_rt" {
  subnet_id      = aws_subnet.db.id
  route_table_id = aws_route_table.private.id
}

# -------------------------------------------------
# Security Groups
# -------------------------------------------------
resource "aws_security_group" "sg_web" {
  name        = "web-sg"
  description = "Allow HTTP, HTTPS and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "sg-web"
  }
}

resource "aws_security_group" "sg_app" {
  name        = "app-sg"
  description = "Allow app traffic from web subnet"
  vpc_id      = aws_vpc.main.id


  ingress {
    description = "App port 3001 from web subnet"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.web.cidr_block]
  }

  # Allow SSH password login from web subnet (or any trusted source)
  ingress {
    description = "SSH from web subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.web.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "sg-app"
  }
}

resource "aws_security_group" "sg_db" {
  name        = "db-sg"
  description = "Allow MySQL from app subnet"
  vpc_id      = aws_vpc.main.id


  ingress {
    description = "MySQL from app subnet"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.app.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "sg-db"
  }
}

# -------------------------------------------------
# Load Balancers
# -------------------------------------------------
# Public ALB for web tier
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.web.id, aws_subnet.app.id]
  security_groups    = [aws_security_group.sg_web.id]
  enable_deletion_protection = false
  tags = {
    Name = "web-alb"
  }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Register Frontend VM with Public ALB Target Group
resource "aws_lb_target_group_attachment" "web_attachment" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_vm.id
  port             = 80
}

# Internal NLB for app tier with fixed private IP
resource "aws_lb" "app_nlb" {
  name               = "app-nlb"
  internal           = true
  load_balancer_type = "network"
  subnet_mapping {
    subnet_id         = aws_subnet.app.id
    private_ipv4_address = "10.0.3.100"
  }
  tags = {
    Name = "app-nlb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 3001
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id
  health_check {
    protocol            = "TCP"
    port                = "3001"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "app_tcp" {
  load_balancer_arn = aws_lb.app_nlb.arn
  port              = "3001"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Register Backend VM with Internal NLB Target Group
resource "aws_lb_target_group_attachment" "app_attachment" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_vm.id
  port             = 3001
}

# -------------------------------------------------
# EC2 Instances
# -------------------------------------------------
# Find latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Optional key pair (create from provided public key if none supplied)
resource "aws_key_pair" "deployer" {
  key_name   = var.ssh_public_key 
  public_key = file("${path.module}/.ssh/id_rsa.pub")
}

resource "aws_instance" "web_vm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.web.id
  vpc_security_group_ids      = [aws_security_group.sg_web.id]
  key_name                    = aws_key_pair.deployer.key_name
  user_data                   = var.web_user_data
  associate_public_ip_address = true
  tags = {
    Name = "web-vm"
  }
}



resource "aws_instance" "app_vm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.app.id
  vpc_security_group_ids      = [aws_security_group.sg_app.id]
  key_name                    = aws_key_pair.deployer.key_name
  user_data = templatefile("${path.module}/app_user_data.sh", {
    db_host        = aws_db_instance.primary.address
    db_read_host   = aws_db_instance.replica.address # or replica
    db_pass        = var.db_password
    # This line creates the dependency on the ALB
    allowed_origin = "http://${aws_lb.web_alb.dns_name}" 
  })
  associate_public_ip_address = false
  tags = {
    Name = "app-vm"
  }
depends_on = [
    aws_db_instance.primary,
    aws_db_instance.replica,
    aws_lb.web_alb
  ]

}

# -------------------------------------------------
# RDS MySQL Primary and Replica
# -------------------------------------------------
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "bookreview-db-subnet-group"
  subnet_ids = [aws_subnet.db.id, aws_subnet.db2.id]
  tags = {
    Name = "bookreview-db-subnet-group"
  }
}

resource "aws_db_instance" "primary" {
  identifier                = "bookreview-mysql"
  engine                    = "mysql"
  engine_version            = "8.0"
  instance_class            = var.db_instance_class
  allocated_storage         = 20
  backup_retention_period = 7
  apply_immediately       = true
  db_name                      = "bookreview"
  username                  = var.mysql_admin_user
  password                  = var.db_password
  db_subnet_group_name      = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.sg_db.id]
  skip_final_snapshot       = true
  publicly_accessible       = false
  multi_az                  = false
  tags = {
    Name = "primary-db"
  }
}

resource "aws_db_instance" "replica" {
  identifier                = "bookreview-mysql-replica"
  engine                    = "mysql"
  engine_version            = "8.0"
  instance_class            = var.db_instance_class
  replicate_source_db       = aws_db_instance.primary.arn
  db_subnet_group_name      = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.sg_db.id]
  skip_final_snapshot       = true
  publicly_accessible       = false
  multi_az                  = false
  tags = {
    Name = "replica-db"
  }
}

# -------------------------------------------------
# Private DNS (Route53 Private Hosted Zone)
# -------------------------------------------------
# Route53 private zone removed for simplicity

# DNS records for RDS removed (zone not created)

# -------------------------------------------------
# Data sources
# -------------------------------------------------
# Availability zones list
data "aws_availability_zones" "available" {}
