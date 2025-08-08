# Input variable for the Azure region where resources will be deployed.
# Using a variable makes your Terraform configuration reusable for different regions.
variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
  default     = "East US" # Default value for the location, can be overridden.
}
variable "prefix" {
  description = "A prefix for naming Azure resources."
  type        = string
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

variable "cloudflare_api_token" {
  description = "Cloudflare API token with DNS Edit permissions for the target zone"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_name" {
  description = "Cloudflare zone name (apex/root domain), e.g., example.com"
  type        = string
}

variable "cloudflare_record_name" {
  description = "DNS record name relative to the zone (e.g., 'app' or '@' for root)"
  type        = string
  default     = "@"
}

variable "cloudflare_proxied" {
  description = "Whether Cloudflare proxy (orange cloud) should be enabled for the record"
  type        = bool
  default     = true
}

variable "cloudflare_ttl" {
  description = "TTL for the DNS record (ignored when proxied is true). Use 1 for 'auto'."
  type        = number
  default     = 300
}
