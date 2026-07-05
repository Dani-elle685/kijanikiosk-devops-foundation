# Imperative vs Declarative Infrastructure Management

The difference between imperative and declarative infrastructure management is not a philosophical debate. It is the difference between a system that works reliably at scale and one that accumulates invisible debt until it breaks in production.

The Imperative Model: How and What
An imperative approach to provisioning describes how to achieve a result: a sequence of steps executed in order. The bash provisioning script from Week 3 is a perfect example.

# Imperative: step-by-step instructions
`apt-get update
apt-get install -y nginx=1.24.0-1ubuntu2
useradd --system kk-api
mkdir -p /opt/kijanikiosk/api
chown kk-api:kk-api /opt/kijanikiosk/api
chmod 750 /opt/kijanikiosk/api
systemctl enable kk-api.service`

Each line tells the system what action to perform. If nginx is already installed at the right version, apt-get install still runs. If the user already exists, useradd fails. The script must explicitly handle every possible pre-existing condition.

Try this now: observe the imperative failure mode
Run these two commands in sequence:

`mkdir /tmp/iac-test
mkdir /tmp/iac-test`

The second run fails: cannot create directory '/tmp/iac-test': File exists. This is the core problem. Every imperative command assumes a specific starting state. In a script with forty commands across eight phases, any one of them can fail if the expected starting state does not hold. Your Week 3 script handled this with explicit guard conditions on each phase. That worked for one server. Multiply it by twelve and the guards themselves become the maintenance burden.


# The Declarative Model: What, Not How
A declarative approach describes what the result should be. The tool is responsible for figuring out how to get there from the current state. The engineer does not write steps: they write a specification.

# Declarative: desired end state
` resource "local_file" "test" {
  filename = "/tmp/iac-test/config.txt"
  content  = "kijanikiosk staging config"
  file_permission = "0640" 
}`

This block says: there should be a file at this path with this content and these permissions. Terraform figures out whether the file needs to be created, updated, or left alone. Run it ten times and the eleventh run is identical to the tenth.

Try this now: observe idempotency with Terraform
Create a working directory and your first Terraform configuration:
`
mkdir -p ~/iac-test && cd ~/iac-test

cat > main.tf << 'EOF'
terraform {
  required_providers {
    local = { source = "hashicorp/local" }
  }
}

resource "local_file" "test" {
  filename        = "/tmp/iac-test-output.txt"
  content         = "KijaniKiosk IaC test - created by Terraform"
  file_permission = "0640"
}
EOF
`
`
terraform init
terraform apply -auto-approve
`

Now run apply a second time:

terraform apply -auto-approve
The output shows 0 added, 0 changed, 0 destroyed. Terraform checked the current state against the desired state and found nothing to do. This is idempotency without a single guard condition in the configuration. Note the value: run it one hundred times, the result is always the same. Verify: cat /tmp/iac-test-output.txt.




# The Three Properties of Effective IaC
All mature IaC tools share three properties. Understanding them is the foundation for the rest of the week.

1. Idempotency
Running the same configuration multiple times produces the same result. The first run creates. Subsequent runs verify and correct if needed. No run causes unexpected side effects from being run twice.

You just observed this. The second terraform apply reported zero changes. The bash equivalent required explicit id user || useradd user guards to achieve the same property.
2. Desired State
The configuration describes the intended end state, not the steps to reach it. The tool owns the plan for how to get from the current state to the desired state. This separation means the engineer thinks about what the system should look like, not how to transition it.

3. Drift Detection
The tool can compare the current state of infrastructure to the declared desired state and report differences. This is the capability that makes scaling to twelve servers tractable.


# The IaC Landscape
IaC tools fall into three primary categories. Understanding the category tells you the problem the tool was designed to solve.

# Category	What it manages	Examples	Notes
## Infrastructure Provisioning	- 
Creates and destroys infrastructure resources (VMs, networks, storage)	Terraform (HashiCorp), Pulumi, AWS CDK	Terraform works identically across AWS, GCP, Azure, Hetzner, DigitalOcean, and local Multipass environments. CloudFormation (AWS-only) requires an AWS account even for learning exercises. This is why Terraform is the course tool.
## Configuration Management-
Installs software and manages configuration on existing machines	Ansible, Chef, Puppet, SaltStack	Ansible is agentless (SSH-based). Chef and Puppet require an agent installed on each managed node. Thursday's session covers Ansible in depth.

## Container Orchestration-
	Manages the scheduling, scaling, and networking of containerised workloads	Kubernetes, Docker Swarm, Nomad	Kubernetes manages what runs on the infrastructure. Terraform or another provisioning tool creates the infrastructure that Kubernetes runs on.

Tool categorisation answers:
Ansible → Configuration Management | 
CloudFormation → Infrastructure Provisioning (AWS-only) | 
Puppet → Configuration Management | 
Kubernetes → Container Orchestration | 
Terraform → Infrastructure Provisioning (multi-cloud)


# Terraform Architecture
Terraform has four components that work together every time you run a command:

1. Configuration files (.tf)
HCL files that declare the desired state. You write these. They describe what resources should exist and what their properties should be.

2. Providers
Plugins that know how to talk to a specific API (AWS, GCP, Azure, local filesystem, or Multipass via the null provider). A provider block tells Terraform which plugin to download and use.

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}
This example uses the hashicorp/local provider — the same one you used on Page 2. Cloud provider blocks are introduced on Tuesday when you have real credentials and resources to target.

3. State file (terraform.tfstate)
A JSON record of every resource Terraform has created. Terraform compares the current state file against your configuration to determine what changes to make. Never commit the state file to version control — it can contain sensitive values including IP addresses and connection details.

Run this in ~/iac-test before your first commit:
echo "*.tfstate" >> .gitignore
echo "*.tfstate.backup" >> .gitignore
The full .gitignore template is covered on Tuesday Page 2, but protecting the state file starts today.

4. Init, Plan and apply cycle
terraform plan computes the diff between current state and desired state and shows you every change before it happens. terraform apply executes those changes. Always read the plan output before applying.


# Reading Plan Output
Every line in a terraform plan output carries a symbol. These symbols are the most important thing to read before running terraform apply:

Symbol	Meaning	What to check before applying
+	Resource will be created	Confirm you intended to add this resource and the count is correct
~	Resource will be updated in place	Confirm the attribute change is intentional — some updates are harmless, others cause downtime
-	Resource will be destroyed	Is this destruction intentional? Check if any other resource depends on this one.
-/+	Resource will be destroyed and recreated	High risk: The resource cannot be updated in place. On a production database, this is a potential data-loss event if not handled carefully.

