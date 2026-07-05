#!/usr/bin/env bash

set -euo pipefail

echo "======================================"
echo "KijaniKiosk Infrastructure Pipeline"
echo "======================================"

TERRAFORM_DIR="./terraform"
ANSIBLE_DIR="./ansible"

##############################################
# Stage 1 - Terraform Formatting
##############################################

echo
echo "Stage 1: Checking Terraform formatting..."

terraform -chdir="$TERRAFORM_DIR" fmt -check -recursive

echo "Terraform formatting OK"

##############################################
# Stage 2 - Terraform Validation
##############################################

echo
echo "Stage 2: Initializing Terraform..."

terraform -chdir="$TERRAFORM_DIR" init

echo
echo "Validating Terraform configuration..."

terraform -chdir="$TERRAFORM_DIR" validate

echo "Terraform validation OK"

##############################################
# Stage 3 - Terraform Plan
##############################################

echo
echo "Stage 3: Terraform Plan"

terraform -chdir="$TERRAFORM_DIR" plan \
-out=tfplan

##############################################
# Stage 4 - Terraform Apply
##############################################

echo
echo "Stage 4: Terraform Apply"

terraform -chdir="$TERRAFORM_DIR" apply \
-auto-approve tfplan

##############################################
# Stage 5 - Generate Inventory
##############################################

echo
echo "Stage 5: Generating Ansible inventory..."

API_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw api_server_ip)
PAYMENTS_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw payments_server_ip)
LOGS_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw logs_server_ip)

cat > "$ANSIBLE_DIR/inventory.ini" <<EOF
[kijanikiosk]
api-staging ansible_host=$API_IP
payments-staging ansible_host=$PAYMENTS_IP
logs-staging ansible_host=$LOGS_IP

[kijanikiosk:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=$HOME/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
EOF

echo "Inventory generated."

##############################################
# Stage 6 - Validate Inventory
##############################################

echo
echo "Stage 6: Validating inventory..."

ansible-inventory \
-i "$ANSIBLE_DIR/inventory.ini" \
--graph

echo
echo "Inventory variables"

ansible-inventory \
-i "$ANSIBLE_DIR/inventory.ini" \
--list >/dev/null

echo "Inventory OK"

##############################################
# Stage 7 - Validate Playbook
##############################################

echo
echo "Stage 7: Validating playbook syntax..."

ansible-playbook \
-i "$ANSIBLE_DIR/inventory.ini" \
"$ANSIBLE_DIR/kijanikiosk.yml" \
--syntax-check

echo "Playbook syntax OK"

##############################################
# Stage 8 - Connectivity Test
##############################################

echo
echo "Stage 8: Testing SSH connectivity..."

ansible all \
-i "$ANSIBLE_DIR/inventory.ini" \
-m ping

echo "All hosts reachable"

##############################################
# Stage 9 - Run Playbook
##############################################

echo
echo "Stage 9: Configuring Servers"

ansible-playbook \
-i "$ANSIBLE_DIR/inventory.ini" \
"$ANSIBLE_DIR/kijanikiosk.yml"


echo
echo "======================================"
echo "Pipeline completed successfully."
echo "======================================"
