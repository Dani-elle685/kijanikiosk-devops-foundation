# Environment Setup

## Overview

This project was completed using the AWS cloud provisioning path. Infrastructure was provisioned with Terraform, configured with Ansible, and deployed from an Ubuntu Linux workstation.

---

## Operating System

| Component | Version |
|----------|---------|
| OS | Ubuntu 24.04 LTS (64-bit) |
| Kernel | Linux 6.x |

Verify with:

```bash
lsb_release -a
uname -r
```

---

## Terraform

| Component | Version |
|----------|---------|
| Terraform | v1.15.7 |

Verify with:

```bash
terraform version
```

Example output:

```text
Terraform v1.15.7
on linux_amd64
```

---

## AWS CLI

| Component | Version |
|----------|---------|
| AWS CLI | 2.35.15  |

Verify with:

```bash
aws --version
```

Example:

```text
aws-cli/2.35.15 Python/3.14.5 Linux/6.17.0-35-generic exe/x86_64.ubuntu.24
```

---

## Ansible

| Component | Version |
|----------|---------|
| ansible-core |  2.21.1 |

Verify with:

```bash
ansible --version
```

Example:

```text
ansible [core 2.21.1]
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/home/daniel/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3/dist-packages/ansible
  ansible collection location = /home/daniel/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/bin/ansible
  python version = 3.12.3 (main, Mar 23 2026, 19:04:32) [GCC 13.3.0] (/usr/bin/python3)
  jinja version = 3.1.2
  pyyaml version = 6.0.1 (with libyaml v0.2.5)
```

---

## Python

| Component | Version |
|----------|---------|
| Python | 3.12.3 |

Verify with:

```bash
python3 --version
```


---

## Remote Infrastructure

| Component | Value |
|----------|------|
| Cloud Provider | AWS |
| Region | us-east-1 |
| Instance Type | t3.micro |
| Operating System | Ubuntu Server 24.04 LTS |
| Number of Servers | 3 |

The Terraform configuration provisions the following servers:

- kijanikiosk-api
- kijanikiosk-payments
- kijanikiosk-logs

---

## Terraform Backend

The project currently uses Terraform's local backend for storing state.

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

### Backend Characteristics

- State is stored locally in `terraform.tfstate`.
- Suitable for local development and testing.
- Does not support remote collaboration.
- Does not provide state locking.
- Not recommended for production deployments.

For production environments, a remote backend such as AWS S3 with DynamoDB locking (or an equivalent backend) should be used to prevent concurrent state modifications.

---

## Terraform Providers

Provider used:

- hashicorp/aws

Provider plugins are automatically installed during:

```bash
terraform init
```

---

## Required Software

Install the following before running the project:

- Terraform
- AWS CLI
- Ansible
- Python 3

---

## AWS Authentication

AWS credentials are configured using the AWS CLI.

Verify access:

```bash
aws sts get-caller-identity
```

Expected output:

```json
{
  "UserId": "...",
  "Account": "...",
  "Arn": "..."
}
```

---

## SSH Configuration

Terraform provisions EC2 instances using an existing AWS Key Pair.

Ansible connects using the matching private key stored locally.

Example inventory configuration:

```ini
[kijanikiosk:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
```

Connectivity can be verified using:

```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@<public-ip>
```

---

## Project Structure

```
week4/friday/
│
├── terraform/
│   ├── modules/
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
│
├── ansible/
│   ├── roles/
│   ├── group_vars/
│   ├── host_vars/
│   ├── templates/
│   ├── inventory.ini
│   └── kijanikiosk.yml
│
├── pipeline.sh
├── pipeline-run1.log
├── pipeline-run2.log
├── hardening-decisions.md
├── destroy-output.txt
└── environment-setup.md
```

---

## Validation Commands

Validate Terraform configuration:

```bash
terraform fmt -recursive
terraform validate
terraform plan
```

Validate Ansible inventory:

```bash
ansible all -i inventory.ini -m ping
```

Validate the playbook syntax:

```bash
ansible-playbook -i inventory.ini kijanikiosk.yml --syntax-check
```

Perform a dry run:

```bash
ansible-playbook -i inventory.ini kijanikiosk.yml --check
```

Execute the complete deployment pipeline:

```bash
./pipeline.sh
```

---

## Notes

- Infrastructure is provisioned using reusable Terraform modules and `for_each`.
- Terraform state is stored remotely to support collaborative workflows.
- Ansible configures all servers from a clean Ubuntu installation.
