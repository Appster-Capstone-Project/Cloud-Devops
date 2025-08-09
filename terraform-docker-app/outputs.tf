# Output the name of the created Azure Resource Group.
output "resource_group_name" {
  description = "The name of the Azure Resource Group created."
  value       = azurerm_resource_group.rg.name
}

# Output the public IP address of the backend VM.
output "backend_vm_public_ip" {
  description = "The public IP address of the backend VM."
  value       = azurerm_public_ip.backend_public_ip.ip_address
}

# Output the public IP address of the frontend VM.
output "frontend_vm_public_ip" {
  description = "The public IP address of the frontend VM."
  value       = azurerm_public_ip.frontend_public_ip.ip_address
}

# Output the Azure region where the VM is deployed.
# This refers to the 'location' input variable used in main.tf.
output "vm_location" {
  description = "The Azure region where the VM is deployed."
  value       = var.location
}
