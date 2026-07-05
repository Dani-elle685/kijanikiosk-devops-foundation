terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}



data "aws_ami" "ubuntu" {
  # If several images match my filters, return the newest one.
  most_recent = true
  # This is Canonical's AWS Account ID.
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  # Tells Terraform to only return images that are HVM (Hardware Virtual Machine) type. HVM is a virtualization type that allows the guest operating system to run 
  # directly on the host hardware, providing better performance compared to paravirtualization.
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  servers = {
    api = {
      instance_type = var.instance_type
    }

    payments = {
      instance_type = var.instance_type
    }

    logs = {
      instance_type = var.instance_type
    }
  }
}

module "app_servers" {
  source = "./modules/app_server"

  for_each = local.servers

  name          = each.key
  ami_id        = data.aws_ami.ubuntu.id
  instance_type = each.value.instance_type
  key_name         = var.key_name
  environment      = var.environment
  allowed_ssh_cidr = var.allowed_ssh_cidr
}
