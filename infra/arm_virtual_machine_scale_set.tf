# In this block, we define Azure provider to be used by terraform.
provider "azurerm" {
  features {}
}
# This data block will read information about the image named "rockylinux-9-docker" in "RG-IMAGE-CI" resource group.
data "azurerm_image" "source_image_vmss" {
  resource_group_name = "RG-IMAGE-CI"
  name                = "rockylinux-9-docker"
}
# Create a new resource group 
resource "azurerm_resource_group" "rg_vmss" {
  name     = "rg-vmss"
  location = "Central India"
}
# Create a virtual network 
resource "azurerm_virtual_network" "vnet_vmss" {
  name                = "vnet-vmss"
  address_space       = ["192.168.2.0/24"]
  resource_group_name = azurerm_resource_group.rg_vmss.name
  location            = azurerm_resource_group.rg_vmss.location
}
# Create a subnet in the virtual network 
resource "azurerm_subnet" "snet_vmss" {
  name                 = "snet-vmss"
  resource_group_name  = azurerm_resource_group.rg_vmss.name
  virtual_network_name = azurerm_virtual_network.vnet_vmss.name
  address_prefixes     = ["192.168.2.0/24"]
}
# Create a network security group
resource "azurerm_network_security_group" "nsg_vmss" {
  name                = "nsg-vmss"
  resource_group_name = azurerm_resource_group.rg_vmss.name
  location            = azurerm_resource_group.rg_vmss.location
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
resource "azurerm_subnet_network_security_group_association" "nsg_asso_vmss" {
  subnet_id                 = azurerm_subnet.snet_vmss.id
  network_security_group_id = azurerm_network_security_group.nsg_vmss.id
}
# Create Public IP for loadbalancer
resource "azurerm_public_ip" "pip_lbe" {
  name                = "pip-vmss"
  resource_group_name = azurerm_resource_group.rg_vmss.name
  location            = azurerm_resource_group.rg_vmss.location
  allocation_method   = "Static"
  sku                 = "Standard"
}
# Create Public loadbalancer
resource "azurerm_lb" "lb_vmss" {
  name                = "lbe-vmss"
  resource_group_name = azurerm_resource_group.rg_vmss.name
  location            = azurerm_resource_group.rg_vmss.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "FrontEndIP"
    public_ip_address_id = azurerm_public_ip.pip_lbe.id
  }
}
# Create loadbalancer backend pool
resource "azurerm_lb_backend_address_pool" "backend_vmss" {
  loadbalancer_id = azurerm_lb.lb_vmss.id
  name            = "backend"
}
# Create loadbalancer outbound rule for outgoing traffic from backend pool
resource "azurerm_lb_outbound_rule" "internet" {
  name                    = "internet"
  loadbalancer_id         = azurerm_lb.lb_vmss.id
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_vmss.id

  frontend_ip_configuration {
    name = "FrontEndIP"
  }
}
# Create virtual machine scale set
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmss"
  resource_group_name = azurerm_resource_group.rg_vmss.name
  location            = azurerm_resource_group.rg_vmss.location
  sku                 = "Standard_B2s"
  instances           = 2
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("../ssh-key.pub")
  }
  # Here we are passing id of our custom image
  source_image_id = data.azurerm_image.source_image_vmss.id
  # We have to pass plan information for the image used from the marketplace
  plan {
    name      = "rockylinux-9"
    product   = "rockylinux-9"
    publisher = "erockyenterprisesoftwarefoundationinc1653071250513"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic-vmss"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.snet_vmss.id
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.backend_vmss.id}"]
    }
  }
}