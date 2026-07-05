variable "aws_region" {
  description = "AWS deployment region"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "staging"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "AWS key pair name"
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
  description = "CIDR allowed to SSH"
  type        = string
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
}