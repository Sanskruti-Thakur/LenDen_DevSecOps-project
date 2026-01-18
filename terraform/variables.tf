# terraform/variables.tf
variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["49.36.99.58/32"]  
}
