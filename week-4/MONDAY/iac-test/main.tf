
resource "local_file" "test" {
  filename        = "/tmp/iac-test-output.txt"
  content         = "KijaniKiosk IaC test - tested by Terraform"
  file_permission = "0640"
}