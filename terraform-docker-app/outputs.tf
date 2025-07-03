output "vm_public_ip_address" {
  description = "The public IP address of the deployed Flatcar VM."
  value       = azurerm_public_ip.public_ip.ip_address
}

output "ssh_connect_command_aad" {
  description = "Command to connect to the VM using Azure AD (Entra ID) credentials."
  value       = "az ssh vm --ip ${azurerm_public_ip.public_ip.ip_address}"
}

output "ssh_connect_command_key" {
  description = "Command to connect to the VM using the initial SSH key (user 'core')."
  value       = "ssh -i ${var.ssh_public_key_path} core@${azurerm_public_ip.public_ip.ip_address}"
}