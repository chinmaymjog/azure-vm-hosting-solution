resource "azurerm_network_security_group" "nsg_compute" {
  name                = "nsg-compute-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  # --- INBOUND RULES ---

  # Allow HTTP from Azure Front Door Backend
  security_rule {
    name                       = "AllowAFD"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "AzureFrontDoor.Backend"
    destination_address_prefix = "*"
  }

  # Allow HTTP/HTTPS directly from User's Public IP for Load Balancer verification
  security_rule {
    name                       = "AllowWebFromUser"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = data.http.client_ip.response_body
    destination_address_prefix = "*"
  }

  # Allow SSH from Hub VNet ONLY
  security_rule {
    name                       = "AllowSSHFromHub"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.hub_address_space[0]
    destination_address_prefix = "*"
  }

  # --- OUTBOUND RULES ---

  # Allow Outbound for Updates (HTTP/HTTPS)
  security_rule {
    name                       = "AllowOutboundUpdates"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.snet_compute.id
  network_security_group_id = azurerm_network_security_group.nsg_compute.id
}

# Discover the public IP of the machine running Terraform dynamically
data "http" "client_ip" {
  url = "https://ifconfig.me/ip"
}

# Jumpbox NSG is now managed in shared-hub layer
