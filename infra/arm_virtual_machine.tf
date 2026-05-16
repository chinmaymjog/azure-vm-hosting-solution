# In this block, we define Azure provider to be used by terraform.
provider "azurerm" {
  features {}
}
# This data block will read information about the image named "rockylinux-9-docker" in "RG-IMAGE-CI" resource group.
data "azurerm_image" "source_image" {
  resource_group_name = "RG-IMAGE-CI"
  name                = "rockylinux-9-docker"
}
# Create a new resource group 
resource "azurerm_resource_group" "rg" {
  name     = "rg-vm"
  location = "Central India"
}
# Create a virtual network 
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["192.168.1.0/24"]
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
# Create a subnet in the virtual network 
resource "azurerm_subnet" "snet_vm" {
  name                 = "snet_vm"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}
# Create a network security group
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  # Rule to allow SSH traffic
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
# Associate network security group to subnet
resource "azurerm_subnet_network_security_group_association" "nsg_asso_vm" {
  subnet_id                 = azurerm_subnet.snet_vm.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
# Create Public IP for virtual machine
resource "azurerm_public_ip" "pip" {
  name                = "pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}
# Create a network interface & assign the above public IP
resource "azurerm_network_interface" "nic" {
  name                = "nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet_vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}
# Create the virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("../ssh-key.pub")
  }
  # Here we are passing id of our custom image
  source_image_id = data.azurerm_image.source_image.id
  # We have to pass plan information for the image used from the marketplace
  plan {
    name      = "rockylinux-9"
    product   = "rockylinux-9"
    publisher = "erockyenterprisesoftwarefoundationinc1653071250513"
  }

  os_disk {
    name                 = "osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface_ids = [azurerm_network_interface.nic.id]
}

# Outputs public IP of our virtual machine
output "VM_Public_IP" {
  value = azurerm_linux_virtual_machine.vm.public_ip_address
}