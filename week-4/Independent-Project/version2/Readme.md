## Pipeline Validation Stages (pipeline.sh)

The deployment pipeline performs a series of validation and deployment steps to ensure both the infrastructure and configuration are correct before provisioning and configuring the servers.

| Stage | Command | Purpose |
|-------|---------|---------|
| **1** | `terraform fmt -check -recursive` | Verifies that all Terraform files follow the standard HashiCorp formatting conventions. |
| **2** | `terraform init`<br>`terraform validate` | Initializes the Terraform working directory, downloads required providers/modules, and validates the configuration syntax. |
| **3** | `terraform plan` | Generates an execution plan showing the infrastructure changes Terraform intends to make. |
| **4** | `terraform apply` | Creates or updates the AWS infrastructure based on the approved execution plan. |
| **5** | `terraform output` | Retrieves the public IP addresses of the provisioned EC2 instances for use by Ansible. |
| **6** | `ansible-inventory --graph` | Validates the generated inventory file and confirms hosts are grouped correctly. |
| **7** | `ansible-playbook --syntax-check` | Performs a syntax validation of the Ansible playbook without executing any tasks. |
| **8** | `ansible all -m ping` | Verifies SSH connectivity and confirms Python is available on every managed server. |
| **9** | `ansible-playbook -i inventory.ini kijanikiosk.yml` | Applies the Ansible configuration to provision and configure all servers. |

---

## Terraform Variables

Create a `terraform.tfvars` file in the Terraform directory with the following values:

```hcl
environment      = "staging"
aws_region       = "us-east-1"

# Name of an existing AWS EC2 Key Pair
key_name         = "your-keypair-name"

# CIDR block allowed to SSH into the instances
allowed_ssh_cidr = "0.0.0.0/0"

# AWS credentials
aws_access_key   = "YOUR_AWS_ACCESS_KEY"
aws_secret_key   = "YOUR_AWS_SECRET_ACCESS_KEY"
```

> **Important**
>
> - `key_name` must be the **name of an existing AWS EC2 Key Pair**, **not** the path to your local private key.
> - The corresponding private key (for example, `~/.ssh/id_ed25519`) is used by Ansible to connect to the provisioned instances.
> - Never commit `terraform.tfvars` or AWS credentials to source control. Add the following entry to your `.gitignore`:
>
> ```text
> terraform.tfvars
> *.tfvars
> ```
>
> Alternatively, export your AWS credentials as environment variables:
>
> ```bash
> export AWS_ACCESS_KEY_ID="<your-access-key>"
> export AWS_SECRET_ACCESS_KEY="<your-secret-key>"
> export AWS_DEFAULT_REGION="us-east-1"
> ```
>
> This approach is more secure than storing credentials in a file.