# terraform/main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "lenden-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  
  tags = {
    Name = "lenden-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "lenden-igw"
  }
}

# Security Group
resource "aws_security_group" "web_sg_secure" {
  name        = "lenden-secure-sg"
  description = "Secure SG after AI remediation"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from approved IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  ingress {
    description = "Web app on port 5000"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"  # Optional: Restrict if possible
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "secure-sg"
    Remediated = "true"
    Student    = "Sanskruti-Thakur"
  }
}

# EC2 Instance
resource "aws_instance" "web_server" {
  ami           = "ami-0f5ee92e2d63afc18"  # Ubuntu 22.04 in ap-south-1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg_secure.id]
  key_name      = "lenden-key"

  # IMDS v2 enforced
  metadata_options {
    http_tokens = "required"
  }

  # Root volume encryption
  root_block_device {
    encrypted = true
  }

  # User data to deploy docker container
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              
              docker run -d -p 5000:5000 --name lenden-app hello-world
              EOF

  tags = {
    Name = "lenden-web-server"
  }
}

# Elastic IP
resource "aws_eip" "web_ip" {
  instance = aws_instance.web_server.id
  vpc      = true
}

# VPC Flow Logs
resource "aws_iam_role" "flow_log_role" {
  name = "vpc-flow-log-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "flow_log_attach" {
  role       = aws_iam_role.flow_log_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonVPCFlowLogsRole"
}

resource "aws_flow_log" "vpc_flow" {
  vpc_id        = aws_vpc.main.id
  traffic_type  = "ALL"
  log_group_name = "/aws/vpc/lenden-vpc"
  iam_role_arn   = aws_iam_role.flow_log_role.arn
}

# Output
output "application_url" {
  value = "http://${aws_eip.web_ip.public_ip}:5000"
}
