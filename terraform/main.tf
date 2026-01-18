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

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "lenden-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  
  tags = {
    Name = "lenden-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "lenden-igw"
  }
}

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
    description = "Allow HTTP/HTTPS outbound"
    from_port   = 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "secure-sg"
    Remediated  = "true"
    Student     = "Sanskruti-Thakur"
  }
}

resource "aws_instance" "web_server" {
  ami                    = "ami-0f5ee92e2d63afc18"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg_secure.id]
  
  key_name = "lenden-key"
  
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              
              docker run -d -p 5000:5000 --name lenden-app hello-world
              EOF

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "lenden-web-server"
  }
}

resource "aws_eip" "web_ip" {
  instance = aws_instance.web_server.id
}

resource "aws_cloudwatch_log_group" "vpc_flow" {
  name              = "/aws/vpc/lenden-vpc"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.vpc_logs.arn
}

resource "aws_kms_key" "vpc_logs" {
  description             = "KMS key for VPC Flow Logs"
  deletion_window_in_days = 7
}

resource "aws_flow_log" "vpc_flow" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  log_destination = aws_cloudwatch_log_group.vpc_flow.arn
}

output "application_url" {
  value = "http://${aws_eip.web_ip.public_ip}:5000"
}
