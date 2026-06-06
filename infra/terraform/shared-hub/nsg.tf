resource "azurerm_network_security_group" "nsg_jumpbox" {
  name                = "nsg-jumpbox-shared"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  tags                = var.tags

  security_rule {
    name                       = "AllowSSHFromUser"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowWeb8080FromUser"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = data.http.client_ip.response_body
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = azurerm_subnet.snet_hub_mgmt.id
  network_security_group_id = azurerm_network_security_group.nsg_jumpbox.id
}
