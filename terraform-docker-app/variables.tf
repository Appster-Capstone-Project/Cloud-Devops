variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
  default     = "East US"
}

variable "prefix" {
  description = "A prefix for naming Azure resources."
  type        = string
  default     = "flatcar-docker"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file (e.g., ~/.ssh/id_rsa.pub) for initial VM access."
  type        = string
}

variable "aad_group_object_id" {
  description = "The Object ID of the Azure AD (Entra ID) group that will have 'Virtual Machine Administrator Login' access."
  type        = string
}

variable "environment_name" {
  description = "The target environment name (e.g., dev, prod) for resource naming and segregation."
  type        = string
  default     = "dev" # Default for local runs
}