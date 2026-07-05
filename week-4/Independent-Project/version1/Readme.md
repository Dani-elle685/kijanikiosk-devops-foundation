What each stage validates
Stage	Command	Purpose
1	terraform fmt -check -recursive	Ensures all Terraform files follow standard formatting.
2	terraform init + terraform validate	Downloads providers/modules and validates Terraform syntax and configuration.
3	terraform plan	Shows what changes Terraform intends to make.
4	terraform apply	Provisions or updates infrastructure.
5	terraform output	Retrieves the new EC2 public IP addresses.
6	ansible-inventory --graph	Verifies the generated inventory is valid and hosts are grouped correctly.
7	ansible-playbook --syntax-check	Checks the playbook for YAML and Ansible syntax errors without executing tasks.
8	ansible all -m ping	Confirms SSH connectivity and Python availability on all servers.
9	ansible-playbook	Configures the servers.
10	ansible-playbook (second run)	Confirms idempotency by ensuring no further changes are needed (changed=0).


# contents to ad in terraform.tfvars
`    environment = "staging"
    aws_region  = "us-east-1"
    key_name = "your ssh key"
    allowed_ssh_cidr = "0.0.0.0/0"
    aws_access_key = "aws access key"
    aws_secret_key = "aws secret key"
`
