# Hashicorp Configuration Language (HCL) Syntax
A Terraform project is a directory containing .tf files written in HashiCorp Configuration Language. Terraform reads all .tf files in the working directory as a single configuration. File names are conventions, not requirements, but following them makes your project navigable to any engineer who has worked with Terraform before


Standard Project Layout
A minimal Terraform project for a single environment uses three files. This is the layout you will create before the lab.

kijanikiosk-infra/
├── main.tf          # Resource definitions
├── variables.tf     # Input variable declarations
├── outputs.tf       # Output value declarations
├── terraform.tfvars # Variable values (never commit to version control)
└── .gitignore       # Must exclude .tfvars and .tfstate
Set up .gitignore before your first commit
The terraform.tfvars file often contains sensitive values. The .tfstate file always contains sensitive infrastructure details. Both must be excluded from version control. Create the .gitignore file before your first commit, not after you have already pushed credentials.

For the primary lab path using Multipass, your state file (terraform.tfstate) contains the Multipass VM IP address and connection details. While less sensitive than a cloud state file, it should still be excluded from version control using the *.tfstate entry.

# .gitignore
*.tfvars
*.tfstate
*.tfstate.backup
.terraform/
Do NOT add .terraform.lock.hcl to .gitignore
.terraform.lock.hcl should be committed to version control. It pins provider versions so all team members use identical provider binaries. Adding it to .gitignore breaks reproducible builds.

Try this now: create the project structure
mkdir -p ~/kijanikiosk-infra && cd ~/kijanikiosk-infra
touch main.tf variables.tf outputs.tf terraform.tfvars
cat > .gitignore << 'EOF'
*.tfvars
*.tfstate
*.tfstate.backup
.terraform/
EOF
ls -la
You should see five files. The directory is empty but correctly structured. Before you write any HCL, run git init && git add .gitignore && git commit -m "Initial Terraform project structure" to record the gitignore before any sensitive files are created.


The Provider Block
The provider block tells Terraform which plugin to download and how to authenticate with the cloud platform. It lives in main.tf.

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"    # Accept any 2.x version
    }
  }
}

provider "local" {
  # No authentication needed — operates on local filesystem
}
Cloud provider blocks: When you are ready to target a real cloud provider, replace the local provider with your chosen cloud provider — the HCL syntax for variables, outputs, and resource blocks is identical. The only differences are the provider name, the resource type names, and the credentials method.
Version constraints
The ~> 5.0 constraint means "5.x but not 6.0". This is the safest pattern for production configurations: it allows minor version updates (which contain bug fixes and new features) but blocks major version updates (which may contain breaking changes). Always pin provider versions in production code. Never use an unconstrained version in a shared repository.

Try this now: write the provider block and run init
Add the provider block to main.tf for your cloud provider. Then run:

terraform init
Watch the output. Terraform downloads the provider plugin and creates a .terraform/ directory and a .terraform.lock.hcl file. The lock file pins the exact provider version that was downloaded. Run cat .terraform.lock.hcl and note the version and the hash. This file should be committed to version control: it ensures every team member uses the identical provider binary, eliminating "works on my machine" provider version differences.


Variables: The Decisions That Change Between Environments
Variables parameterise your configuration. Anything that differs between environments (region, instance type, key pair name) belongs in a variable. Anything that is the same everywhere (port numbers, naming conventions) can be a local value or a hardcoded literal.

# variables.tf
variable "aws_region" {
  description = "AWS region to deploy infrastructure into"
  type        = string
  default     = "eu-west-1"    # Frankfurt - closest to Nairobi with EC2 free tier
}

variable "instance_type" {
  description = "EC2 instance type for KijaniKiosk application servers"
  type        = string
  default     = "t2.micro"    # Free tier eligible
}

variable "environment" {
  description = "Deployment environment: staging or production"
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be staging or production."
  }
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair to attach to instances"
  type        = string
  # No default: this must be provided explicitly per environment
}
Variables without defaults
A variable with no default is required. Terraform will error at plan time if it is not provided. This is intentional: the SSH key pair name is different per environment and should never be silently defaulted. Making it required forces the engineer to think about it explicitly. Use required variables for anything where a default would be wrong in some environments.

Try this now: add your variables and observe what happens without a value
Add the variable declarations to variables.tf. Include ssh_key_name without a default. Then run:

terraform plan
Terraform will prompt you for the value of ssh_key_name interactively because there is no default and no .tfvars file yet. Enter any placeholder value to see what happens.

Then create terraform.tfvars with your real key pair name and run terraform plan again. Notice the interactive prompt disappears.

This is the mechanism that makes the same configuration deployable to multiple environments without changing any source code.


Outputs: Exposing Values After Apply
Output values are printed after a successful apply and stored in the state file. They expose resource attributes that other configurations or scripts need to know: the VM's public IP, the VPC ID, the SSH command.

# outputs.tf
output "api_server_public_ip" {
  description = "Public IP address of the KijaniKiosk API server"
  value       = aws_instance.kk_api.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the API server"
  value       = "ssh -i ~/.ssh/kijanikiosk ubuntu@${aws_instance.kk_api.public_ip}"
  sensitive   = false   # Set to true for outputs that contain secrets
}

After apply, run terraform output to see all outputs, or terraform output api_server_public_ip for a single value. This is how Ansible and other downstream tools consume Terraform results without reading the state file directl


# Terraform Workflow
Every Terraform operation follows the same three-command sequence. Understanding what each command does, what it reads, and what it changes is the foundation for operating Terraform safely in teams and in CI pipelines.


terraform init: Prepare the Working Directory
terraform init must be run once when you first create a project and again whenever you add or change provider requirements. It does three things:

Downloads the provider plugins specified in the required_providers block
Creates the .terraform/ directory to store downloaded plugins
Writes or updates .terraform.lock.hcl to pin provider versions
terraform init

# Output:
# Initializing the backend...
# Initializing provider plugins...
# - Finding hashicorp/aws versions matching "~> 5.0"...
# - Installing hashicorp/aws v5.31.0...
# - Installed hashicorp/aws v5.31.0 (signed by HashiCorp)
#
# Terraform has been successfully initialized!
When to re-run init
You need to run terraform init again when: you add a new provider, you change the provider version constraint, you add a new module reference, or you clone the repository on a new machine (the .terraform/ directory is gitignored and must be recreated). A common error is forgetting to run init after pulling changes from a team member who added a new provider.


terraform plan: The Safety Check
terraform plan compares your configuration against the current state and generates a preview of every change that terraform apply would make. It changes nothing. It is safe to run any number of times.

terraform plan

# Plan output symbols:
# + resource will be CREATED (green)
# - resource will be DESTROYED (red)
# ~ resource will be UPDATED IN-PLACE (yellow, less disruptive)
# -/+ resource will be DESTROYED and RECREATED (red/green, most disruptive)
# <= data source will be READ

# Example plan output:
Terraform will perform the following actions:

  # aws_instance.kk_api will be created
  + resource "aws_instance" "kk_api" {
      + ami                    = "ami-0c94855ba95b798c7"
      + instance_type          = "t2.micro"
      + tags                   = {
          + "Environment" = "staging"
          + "Name"        = "kijanikiosk-api-staging"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
The -/+ destroy and recreate pattern
Some resource attributes cannot be changed in-place. For example, changing the AMI of a running EC2 instance requires destroying the old instance and creating a new one. If you see -/+ in a plan for a production database or a stateful server, stop. The plan is telling you that your change will cause downtime. Understand why before proceeding, and consider whether there is a less disruptive way to achieve the same result.

Try this now: run terraform plan and identify every symbol
Add a minimal resource block to your main.tf (a local_file resource works without cloud credentials) and run:

terraform plan -out=tfplan
The -out=tfplan flag saves the plan to a file. This is required in production pipelines: it ensures that the exact plan you reviewed is the one that gets applied, not a new plan that might differ if someone changed the configuration in between. Read every line of the output. Can you identify all the attributes Terraform will set? Which ones did you specify and which are Terraform's computed defaults?


terraform apply: Executing the Plan
terraform apply executes the changes shown in the plan. Without flags it will show the plan again and prompt for confirmation before making any changes.

# Apply and show plan before prompting (recommended for manual runs)
terraform apply

# Apply a previously saved plan file (required for CI/CD pipelines)
terraform apply tfplan

# Apply without confirmation prompt (use in automation only)
terraform apply -auto-approve
After apply: what changed in the state file
After apply completes, Terraform writes the result to terraform.tfstate. This file now contains the resource IDs, IP addresses, and all attributes of every resource Terraform just created. Run terraform show to see a human-readable version of the state, or cat terraform.tfstate to see the raw JSON. Find your VM's public IP address in both outputs.

Try this now: apply and inspect the state file
Apply your saved plan and then inspect what Terraform recorded:

Run terraform apply tfplan (using the plan file saved in the previous exercise). If you did not save a plan file, run terraform apply -auto-approve but note that in production you should always apply a saved plan to guarantee the plan you reviewed is exactly what executes.

terraform apply tfplan
terraform show
cat terraform.tfstate | python3 -m json.tool | head -40
Compare the terraform show output to what you see in the cloud console. They should match exactly. Find the resource's ID in the state file. That ID is how Terraform will identify this specific resource in all future plan and apply operations. Now answer this question before moving to Page 4: what would happen to the state file if you logged into the console and manually terminated the VM? Run terraform plan again and observe what Terraform sees.

Recovery procedure:
The state file still shows the resource as existing. Run terraform plan Terraform will attempt to refresh state and may show an error or tainted resource. Remove the orphaned entry:

terraform state rm resource.name
Then run terraform plan again to confirm Terraform will create a replacement. Never edit the state file directly.


terraform destroy: Tearing Down Infrastructure Safely
terraform destroy is the reverse of apply: it reads the state file, plans the destruction of every resource it manages, prompts for confirmation, and removes them. This is the correct way to clean up lab environments.

# Destroy all resources managed by this configuration
terraform destroy

# Destroy a specific resource only
terraform destroy -target=aws_instance.kk_api
Destroy vs manually deleting resources
If you delete a resource in the cloud console without running terraform destroy, the resource is gone but Terraform's state file still believes it exists. The next terraform plan will show an error trying to refresh the state for the deleted resource. Always use terraform destroy to remove resources Terraform manages. If you accidentally delete manually, use terraform state rm resource.name to remove the orphaned state entry.

Terraform Data Sources
Monday's reflection asked you to identify open questions in your desired-state specification. One of the most common was the AMI ID: a value that is region-specific, changes when a new Ubuntu release is published, and cannot be hardcoded without breaking the configuration the moment you deploy to a different region.

Data sources are Terraform's answer to this problem.


Scenario: The AMI Problem
Amina writes her first resource block with the AMI ID hardcoded from Monday's console session:

ami = "ami-0c94855ba95b798c7"   # Ubuntu 22.04 us-east-1
Tendo reviews the PR and leaves a comment: "This works today. It will break when Canonical publishes Ubuntu 22.04.2, because the new patch release has a different AMI ID. It will also break immediately if anyone tries to deploy this to eu-west-1. A hardcoded AMI is a ticking clock."

Amina looks up data sources in the Terraform documentation. The solution is two blocks instead of one string.


Resources vs Data Sources
Terraform has two types of blocks that represent infrastructure:

resource	data
Purpose	Creates and manages infrastructure	Reads existing infrastructure or external data
State	Recorded in state file, Terraform owns the lifecycle	Not recorded in state, Terraform just reads it
Plan symbol	+ create, ~ update, - destroy	<= will be read
Example use	Create an EC2 instance	Look up the latest Ubuntu 22.04 AMI ID

Data Source Syntax: The AMI Lookup
A data source block starts with data instead of resource. The block type and name follow the same pattern. The content is filter criteria that the provider uses to find the matching item.

Primary path — reading Multipass VM IP dynamically:

data "external" "vm_ip" {
  program = ["bash", "-c",
    "multipass info kijanikiosk-api --format json | python3 -c 'import sys,json; d=json.load(sys.stdin); print(json.dumps({"ip": d["info"]["kijanikiosk-api"]["ipv4"][0]}))'"
  ]
}

output "api_server_ip" {
  value = data.external.vm_ip.result.ip
}
This teaches data sources, dynamic values, and plan-time vs apply-time resolution — without requiring a cloud account. The concept is identical to a cloud image lookup: query external state to get a dynamic value rather than hardcoding it.

► Optional: Cloud Extension — AWS AMI data source
Try this now: run terraform plan with a data source
Add the AMI data source to your configuration and run terraform plan. Look for the <= symbol in the output:

terraform plan
You should see something like: # data.aws_ami.ubuntu_22_04 will be read during apply. Note that data sources are read at apply time, not at plan time, unless Terraform has all the information needed to resolve them during planning. Run terraform apply -auto-approve on a minimal test, then run terraform output to confirm the AMI ID that was resolved. Is it different from the one you hardcoded on Monday? Compare them.


The most_recent = true Risk
The most_recent = true argument tells the data source to return the newest matching AMI. This is convenient but has a specific risk in production environments.

Production scenario: unexpected recreation
Canonical publishes a new Ubuntu 22.04 patch release. The next time you run terraform plan, most_recent = true resolves to the new AMI ID. Since the AMI ID of a running EC2 instance cannot be changed in-place, Terraform shows a -/+ destroy-and-recreate plan for every instance using this data source. Your ten staging VMs are about to be destroyed and recreated if you apply without reading the plan.

The production pattern: Use most_recent = true in development. In staging and production, pin the AMI ID in a variable and update it deliberately as part of your change management process. The variable can reference the data source output, but the decision to update it is manual and tracked in version control.

Prerequisite: The data source must already be in your configuration and terraform init must have been run before terraform console can evaluate data source expressions.

Try this now: understand what most_recent resolves to
Run this to see the current most-recent Ubuntu 22.04 AMI for your region:

terraform console
At the prompt, type:

data.aws_ami.ubuntu_22_04.id
data.aws_ami.ubuntu_22_04.name
data.aws_ami.ubuntu_22_04.creation_date
The Terraform console is an interactive REPL for evaluating HCL expressions against your configuration and state. Press Ctrl+C to exit. Record the AMI ID and creation date in your notes. This is the value that will be written to the instance's state when you apply. On Wednesday, when you parameterise the configuration, you will convert this to a variable with this ID as the default.


Provider equivalents for the image lookup pattern:
AWS: data "aws_ami" -> query by owner and filter criteria
GCP: data "google_compute_image" -> query by family (e.g. ubuntu-2204-lts)
DigitalOcean: Uses image slugs (e.g. "ubuntu-22-04-x64") directly as string values -> no data source required. Slugs are stable identifiers.



Terraform Data Sources
Monday's reflection asked you to identify open questions in your desired-state specification. One of the most common was the AMI ID: a value that is region-specific, changes when a new Ubuntu release is published, and cannot be hardcoded without breaking the configuration the moment you deploy to a different region.

Data sources are Terraform's answer to this problem.


Scenario: The AMI Problem
Amina writes her first resource block with the AMI ID hardcoded from Monday's console session:

ami = "ami-0c94855ba95b798c7"   # Ubuntu 22.04 us-east-1
Tendo reviews the PR and leaves a comment: "This works today. It will break when Canonical publishes Ubuntu 22.04.2, because the new patch release has a different AMI ID. It will also break immediately if anyone tries to deploy this to eu-west-1. A hardcoded AMI is a ticking clock."

Amina looks up data sources in the Terraform documentation. The solution is two blocks instead of one string.


Resources vs Data Sources
Terraform has two types of blocks that represent infrastructure:

resource	data
Purpose	Creates and manages infrastructure	Reads existing infrastructure or external data
State	Recorded in state file, Terraform owns the lifecycle	Not recorded in state, Terraform just reads it
Plan symbol	+ create, ~ update, - destroy	<= will be read
Example use	Create an EC2 instance	Look up the latest Ubuntu 22.04 AMI ID

Data Source Syntax: The AMI Lookup
A data source block starts with data instead of resource. The block type and name follow the same pattern. The content is filter criteria that the provider uses to find the matching item.

Primary path — reading Multipass VM IP dynamically:

data "external" "vm_ip" {
  program = ["bash", "-c",
    "multipass info kijanikiosk-api --format json | python3 -c 'import sys,json; d=json.load(sys.stdin); print(json.dumps({"ip": d["info"]["kijanikiosk-api"]["ipv4"][0]}))'"
  ]
}

output "api_server_ip" {
  value = data.external.vm_ip.result.ip
}
This teaches data sources, dynamic values, and plan-time vs apply-time resolution — without requiring a cloud account. The concept is identical to a cloud image lookup: query external state to get a dynamic value rather than hardcoding it.

► Optional: Cloud Extension — AWS AMI data source
# data.tf (or add to main.tf)
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"]    # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Reference the data source result in your resource block:
resource "aws_instance" "kk_api" {
  ami           = data.aws_ami.ubuntu_22_04.id    # Dynamic, not hardcoded
  instance_type = var.instance_type
  # ...
}
The syntax data.aws_ami.ubuntu_22_04.id references the id attribute of the data source named ubuntu_22_04 of type aws_ami. Terraform resolves this at plan time by querying the AWS API.

Try this now: run terraform plan with a data source
Add the AMI data source to your configuration and run terraform plan. Look for the <= symbol in the output:

terraform plan
You should see something like: # data.aws_ami.ubuntu_22_04 will be read during apply. Note that data sources are read at apply time, not at plan time, unless Terraform has all the information needed to resolve them during planning. Run terraform apply -auto-approve on a minimal test, then run terraform output to confirm the AMI ID that was resolved. Is it different from the one you hardcoded on Monday? Compare them.


The most_recent = true Risk
The most_recent = true argument tells the data source to return the newest matching AMI. This is convenient but has a specific risk in production environments.

Production scenario: unexpected recreation
Canonical publishes a new Ubuntu 22.04 patch release. The next time you run terraform plan, most_recent = true resolves to the new AMI ID. Since the AMI ID of a running EC2 instance cannot be changed in-place, Terraform shows a -/+ destroy-and-recreate plan for every instance using this data source. Your ten staging VMs are about to be destroyed and recreated if you apply without reading the plan.

The production pattern: Use most_recent = true in development. In staging and production, pin the AMI ID in a variable and update it deliberately as part of your change management process. The variable can reference the data source output, but the decision to update it is manual and tracked in version control.

Prerequisite: The data source must already be in your configuration and terraform init must have been run before terraform console can evaluate data source expressions.

Try this now: understand what most_recent resolves to
Run this to see the current most-recent Ubuntu 22.04 AMI for your region:

terraform console
At the prompt, type:

data.aws_ami.ubuntu_22_04.id
data.aws_ami.ubuntu_22_04.name
data.aws_ami.ubuntu_22_04.creation_date
The Terraform console is an interactive REPL for evaluating HCL expressions against your configuration and state. Press Ctrl+C to exit. Record the AMI ID and creation date in your notes. This is the value that will be written to the instance's state when you apply. On Wednesday, when you parameterise the configuration, you will convert this to a variable with this ID as the default.


Provider equivalents for the image lookup pattern:
AWS: data "aws_ami" -> query by owner and filter criteria
GCP: data "google_compute_image" -> query by family (e.g. ubuntu-2204-lts)
DigitalOcean: Uses image slugs (e.g. "ubuntu-22-04-x64") directly as string values -> no data source required. Slugs are stable identifiers