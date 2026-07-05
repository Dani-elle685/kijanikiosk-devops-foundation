variable "name" {
  description = "Server name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "key_name" {
  description = "AWS key pair"
  type        = string
}

# variable "subnet_id" {
#   description = "Subnet ID"
#   type        = string
# }

# variable "vpc_id" {
#   description = "VPC ID"
#   type        = string
# }

variable "allowed_ssh_cidr" {
  description = "Allowed SSH CIDR"
  type        = string
}