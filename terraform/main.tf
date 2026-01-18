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
  region     = ap-south-1
}


variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["YOUR_IP/32"]  # Replace with your IP
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "lenden-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "lenden-public-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "lenden-igw" }
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
    cidr_blocks = ["0.0.0.0/0"]  # Public access for app
  }

  egress {
    description = "Allow internal HTTPS only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Restrict egress to internal network
  }

  tags = {
    Name        = "secure-sg"
    Remediated  = "true"
    Student     = "Sanskruti-Thakur"
  }
}

resource "aws_instance" "web_server" {
  ami                    = "ami-0c94855ba95c71c99"  # Amazon Linux 2
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg_secure.id]
  key_name               = "lenden-key"

  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              docker run -d -p 5000:5000 --name lenden-app hello-world
              EOF

  tags = {
    Name = "lenden-web-server"
  }
}

output "application_url" {
  value = "http://${aws_instance.web_server.public_ip}:5000"
}
