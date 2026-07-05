#!/bin/bash

set -euo pipefail

ROOT_DIR=$(pwd)

echo "================================="
echo "Terraform Apply"
echo "================================="

cd terraform

terraform init

terraform plan -out=tfplan

terraform apply -auto-approve tfplan

API_IP=$(terraform output -raw api_server_ip)
PAYMENTS_IP=$(terraform output -raw payments_server_ip)
LOGS_IP=$(terraform output -raw logs_server_ip)

echo "================================="
echo "Generating Inventory"
echo "================================="

cat > ../ansible/inventory.ini << EOF
[kijanikiosk]
api-staging ansible_host=${API_IP}
payments-staging ansible_host=${PAYMENTS_IP}
logs-staging ansible_host=${LOGS_IP}

[kijanikiosk:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
EOF

echo "================================="
echo "Running Ansible"
echo "================================="

cd ../ansible

ansible-playbook -i inventory.ini kijanikiosk.yml

echo "================================="
echo "Pipeline Complete"
echo "================================="