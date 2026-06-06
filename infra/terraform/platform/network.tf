resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project_name}-${var.environment}"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Subnet for Web/Compute VMs
resource "azurerm_subnet" "snet_compute" {
  name                 = "snet-compute"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], var.subnet_newbits, 1)]
  service_endpoints    = ["Microsoft.Storage"]
}

# Subnet for MySQL PaaS
resource "azurerm_subnet" "snet_database" {
  name                 = "snet-database"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], var.subnet_newbits, 2)]
  service_endpoints    = ["Microsoft.Storage"]
  
  delegation {
    name = "fs"
    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Subnet for NetApp Files (Requires Delegation)
resource "azurerm_subnet" "snet_netapp" {
  name                 = "snet-netapp"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], var.subnet_newbits, 3)]
  
  delegation {
    name = "netapp"
    service_delegation {
      name    = "Microsoft.Netapp/volumes"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Subnets are associated with NSGs in nsg.tf
