# Configure the Azure Resource Manager (AzureRM) provider
provider "azurerm" {
  features {}
}

# Define Terraform settings for the current configuration.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    # Backend configuration details supplied by GitHub Actions
  }
}

# --- Azure Resource Group ---
resource "azurerm_resource_group" "rg" {
  name     = "docker-vm-rg-${var.environment_name}"
  location = var.location
}

# --- Azure Network Security Group (NSG) ---
resource "azurerm_network_security_group" "security_group" {
  name                = "${var.prefix}-docker-vm-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                        = "AllowSSH"
    priority                    = 100
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*" # REFINE THIS IN PRODUCTION
    destination_address_prefix  = "*"
  }

  security_rule {
    name                        = "AllowHTTP"
    priority                    = 110
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "80"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
}

# --- Azure Virtual Network (VNet) ---
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-docker-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# --- Azure Subnet ---
resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-docker-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# --- Azure Public IP Address ---
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.prefix}-docker-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# --- Azure Network Interface (NIC) ---
resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-docker-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# --- Associate NIC with NSG ---
resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.security_group.id
}

# --- Azure Linux Virtual Machine ---
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "${var.prefix}-docker-vm-${var.environment_name}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B1s"
  admin_username                  = "core" # Flatcar's default user
  network_interface_ids           = [azurerm_network_interface.nic.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = "core"
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "${var.prefix}-docker-os-disk"
  }

  source_image_reference {
    publisher = "kinvolk"
    offer     = "flatcar-container-linux-free"
    sku       = "stable-gen2"
    version   = "latest"
  }

  plan {
    name    = "stable-gen2"
    publisher = "kinvolk"
    product = "flatcar-container-linux-free"
  }

  custom_data = filebase64("${path.module}/ignition/docker-vm.json")

  identity {
    type = "SystemAssigned"
  }
}

# --- Azure AD (Entra ID) SSH Login Extension ---
resource "azurerm_virtual_machine_extension" "aad_ssh_login" {
  name                 = "AADSSHLoginForLinux"
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = "1.0"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  auto_upgrade_minor_version = true
}

# --- Azure RBAC Role Assignment for Entra ID SSH Login ---
resource "azurerm_role_assignment" "aad_ssh_admin_role" {
  scope                = azurerm_linux_virtual_machine.vm.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = var.aad_group_object_id
}