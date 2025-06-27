# Input variable for the Azure region where resources will be deployed.
# Using a variable makes your Terraform configuration reusable for different regions.
variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
  default     = "East US" # Default value for the location, can be overridden.
}

# Variables for Azure Service Principal authentication
# These variables will be populated from GitHub Secrets via environment variables (TF_VAR_*)
# in your GitHub Actions workflow.
variable "azure_client_id" {
  description = "The Client ID (App ID) of the Azure AD Application/Service Principal used for authentication."
  type        = string
  sensitive   = true # Mark as sensitive to prevent its value from appearing in logs
}

variable "azure_tenant_id" {
  description = "The Tenant ID of your Azure subscription."
  type        = string
  sensitive   = true # Mark as sensitive
}

variable "azure_subscription_id" {
  description = "The Subscription ID to deploy resources into."
  type        = string
  sensitive   = true # Mark as sensitive
}


# Example: You might want to define other variables for flexibility.
# variable "vm_size" {
#   description = "Size of the virtual machine."
#   type        = string
#   default     = "Standard_B1s"
# }

# variable "admin_username" {
#   description = "Admin username for the VM."
#   type        = string
#   default     = "azureuser"
# }

# IMPORTANT: For production, do NOT hardcode passwords. Use a secure method like Azure Key Vault.
# Mark sensitive variables to prevent them from being shown in logs.
# variable "admin_password" {
#   description = "Admin password for the VM. Highly recommend using Key Vault for production!"
#   type        = string
#   sensitive   = true # This prevents the value from being printed in Terraform logs.
# }
