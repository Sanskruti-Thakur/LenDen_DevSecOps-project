# DevSecOps Assignment: Secure Web Application Deployment

## Project Overview
This project demonstrates DevOps and DevSecOps principles:
- containerized a web application
- provide cloud infrastructure using Terraform
- automated the deployment using Jenkins
- leveraged AI tools for security scanning and code remediation

### Architecture
Local Docker App
     |
     |
     ---> Terraform (IaC) 
     |
     |
     ---> AWS Cloud (EC2 + VPC + Security Groups)
     |
     |
     ---> Jenkins Pipeline
     |
     |
     ---> Trivy Scan
     |
     |
     ---> AI Remediation
     |
     |
     ---> Terraform Apply


**Cloud Provider:** AWS (us-east-1)  
**Tools & Technologies:** Docker, docker-compose, Node.js, Terraform, Jenkins, Trivy, AI (ChatGPT/GenAI)

---

## Web Application & Docker
- Web app implemented using Node.js (or Python).  
- Dockerized using `Dockerfile` and `docker-compose.yml`.  
- Application verified to run locally in Docker.

---

## Infrastructure as Code (Terraform)

### Initial Vulnerable Configuration
- SSH open to 0.0.0.0/0  
- Application port open to 0.0.0.0/0  
- Egress unrestricted  

```hcl
# first.tf
resource "aws_security_group" "web_sg" {
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

Secured Configuration (AI Remediated)
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Security group for web server"

  ingress {
    description = "SSH access from trusted IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["49.36.99.58/32"]
  }

  ingress {
    description = "App access from internal network"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "HTTPS outbound to internal resources"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}
````

CI/CD Pipeline (Jenkins)

Pipeline Stages:

Checkout: Pull code from GitHub

Infrastructure Security Scan: Run Trivy on Terraform

Pipeline fails if HIGH/CRITICAL vulnerabilities are detected

AI analyzes report and recommends code fixes

Terraform Plan: Generate execution plan for secure deployment

Trivy Report (Before Fix):

<img width="569" height="391" alt="image" src="https://github.com/user-attachments/assets/20f646ba-40cb-4ea6-984f-c9d629d3d74d" />

AI Prompt:
The Trivy scan for terraform code identified these vulnerabilities, analyze the console output and suggest changes to improve security and fix the vulnerabilities.

The AI analyzed the Trivy security report and identified two critical vulnerabilities in the Terraform code: SSH (port 22) and the application port (5000) were open to the public internet (0.0.0.0/0), and the egress rules allowed unrestricted outbound traffic. It recommended restricting SSH access to a trusted IP, limiting application port access to the internal VPC network, and constraining egress traffic to only necessary ports (HTTPS 443). Implementing these changes eliminated the HIGH and CRITICAL risks, ensuring the infrastructure is secure by default while maintaining required functionality.

Outcome:
1. SSH restricted to trusted IP
2. App port restricted to internal network
3. Egress limited to required port (HTTPS 443)
4. Jenkins pipeline passes, no HIGH or CRITICAL issues remain.

Final successful run:

<img width="1600" height="853" alt="image" src="https://github.com/user-attachments/assets/a2927e01-813f-4503-bd6a-1946ad557b3d" />

Web App on public IP:

<img width="1918" height="1022" alt="image" src="https://github.com/user-attachments/assets/e213b456-481d-4c37-bb48-17e020d1ae1b" />

AWS Application:

<img width="1919" height="910" alt="image" src="https://github.com/user-attachments/assets/cdec12db-d373-4cc3-b858-6fbfd4bdebdd" />


