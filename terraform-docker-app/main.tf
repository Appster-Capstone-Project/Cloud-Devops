# Configure the Azure Resource Manager (AzureRM) provider
# This block sets up the necessary provider for interacting with Azure.
provider "azurerm" {
  features {} # Required for the AzureRM provider

  # When ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, and ARM_USE_OIDC
  # environment variables are set in the CI/CD pipeline, the provider will
  # automatically authenticate using OpenID Connect (OIDC).
  # No explicit client_id, tenant_id, subscription_id, or use_oidc flags
  # are needed here if using environment variables.
}

# Define Terraform settings for the current configuration.
# This includes declaring required providers and configuring the backend for state storage.
terraform {
  # Declare the AzureRM provider as a required provider for this configuration.
  # Pinning the version helps ensure consistent behavior and avoids unexpected changes
  # due to new provider versions.
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Specifies that any 3.x version is acceptable
    }
  }

  # Configure the Azure Blob Storage backend for storing Terraform state.
  # This makes your state file remote and shareable, which is essential for CI/CD.
  # The actual values for resource_group_name, storage_account_name, and container_name
  # will be supplied at runtime by your GitHub Actions workflow via `-backend-config`.
  # This block only declares the type of backend.
  backend "azurerm" {
    # No values needed here. They are supplied by GitHub Actions secrets/variables.
  }
}

# --- Azure Resource Group ---
# A logical container for your Azure resources.
resource "azurerm_resource_group" "rg" {
  name     = "docker-vm-rg" # Name of the resource group
  location = var.location   # Uses the 'location' variable defined in variables.tf
}

# --- Azure Virtual Network (VNet) ---
# The private network in Azure where your VM and other resources will reside.
resource "azurerm_virtual_network" "vnet" {
  name                = "docker-vnet"      # Name of the virtual network
  address_space       = ["10.0.0.0/16"]    # CIDR block for the VNet
  location            = azurerm_resource_group.rg.location # Deploys in the same location as the resource group
  resource_group_name = azurerm_resource_group.rg.name   # Associates with the created resource group
}

# --- Azure Subnet ---
# A segment within the VNet where your virtual machines will connect.
resource "azurerm_subnet" "subnet" {
  name                 = "docker-subnet"                      # Name of the subnet
  resource_group_name  = azurerm_resource_group.rg.name       # Associates with the resource group
  virtual_network_name = azurerm_virtual_network.vnet.name    # Associates with the VNet
  address_prefixes     = ["10.0.1.0/24"]                      # CIDR block for the subnet
}

# --- Azure Public IP Address ---
# A public IP address to allow external access to your VM (e.g., for SSH or web traffic).
resource "azurerm_public_ip" "public_ip" {
  name                = "docker-public-ip"                     # Name of the public IP
  location            = azurerm_resource_group.rg.location   # Same location as RG
  resource_group_name = azurerm_resource_group.rg.name       # Associates with the resource group
  allocation_method   = "Static"                               # Static IP address (doesn't change on VM restart)
  sku                 = "Standard"                             # Standard SKU for production-grade usage
}

# --- Azure Network Interface (NIC) ---
# Connects the virtual machine to the virtual network and assigns an IP address.
resource "azurerm_network_interface" "nic" {
  name                = "docker-nic"                           # Name of the network interface
  location            = azurerm_resource_group.rg.location   # Same location as RG
  resource_group_name = azurerm_resource_group.rg.name       # Associates with the resource group

  # IP configuration for the NIC
  ip_configuration {
    name                          = "internal"                 # Name of the IP configuration
    subnet_id                     = azurerm_subnet.subnet.id   # Connects to the created subnet
    private_ip_address_allocation = "Dynamic"                  # Dynamically assigns a private IP from the subnet
    public_ip_address_id          = azurerm_public_ip.public_ip.id # Associates the public IP
  }
}

# --- Azure Linux Virtual Machine ---
# The core compute resource where your Docker application will run.
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "docker-vm"                          # Name of the virtual machine
  resource_group_name   = azurerm_resource_group.rg.name       # Associates with the resource group
  location              = azurerm_resource_group.rg.location   # Same location as RG
  size                  = "Standard_B1s"                         # VM size (e.g., Standard_B1s is a small, economical size)
  admin_username        = "azureuser"                            # Administrator username for SSH access
  network_interface_ids = [azurerm_network_interface.nic.id]   # Attaches the created network interface

  # WARNING: Hardcoding passwords directly in Terraform is highly INSECURE for production environments.
  # For production, consider using Azure Key Vault to store and retrieve passwords securely,
  # or use SSH key authentication only (`admin_ssh_key` block instead of `admin_password`).
  admin_password                = "P@ssword1234!" # INSECURE! Replace with a strong, secret-managed password.
  disable_password_authentication = false           # Set to true if using SSH keys only

  os_disk {
    caching              = "ReadWrite"    # Caching setting for the OS disk
    storage_account_type = "Standard_LRS" # Standard Locally Redundant Storage
    name                 = "docker-os-disk" # Name of the OS disk
  }

  # Source image for the VM (Fedora-based image from official community gallery)
  source_image_reference {
    publisher = "kinvolk"               # Publisher for Flatcar Container Linux
    offer     = "flatcar-container-linux-free" # Offer name for Flatcar
    sku       = "stable-gen2"           # SKU for the stable channel, Generation 2 VM
    version   = "latest"                # Always use the latest available version
  }

  # Custom data to execute a script on the VM after it's provisioned.
  # This typically includes commands to install Docker, pull images, and start containers.
  custom_data = base64encode(file("${path.module}/docker-startup.sh"))
}
