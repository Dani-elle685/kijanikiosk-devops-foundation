output "api_server_ip" {
  description = "Public IP of the API server"
  value       = module.app_servers["api"].public_ip
}

output "payments_server_ip" {
  description = "Public IP of the Payments server"
  value       = module.app_servers["payments"].public_ip
}

output "logs_server_ip" {
  description = "Public IP of the Logs server"
  value       = module.app_servers["logs"].public_ip
}

output "ssh_commands" {
  description = "SSH commands for all servers"

  value = {
    api      = "ssh -i ~/.ssh/id_ed25519 ubuntu@${module.app_servers["api"].public_ip}"
    payments = "ssh -i ~/.ssh/id_ed25519 ubuntu@${module.app_servers["payments"].public_ip}"
    logs     = "ssh -i ~/.ssh/id_ed25519 ubuntu@${module.app_servers["logs"].public_ip}"
  }
}