# Data Source for Shared Hub
data "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.project_name}-hub"
  resource_group_name = "rg-${var.project_name}-hub"
}

# Peering: Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "spoke-to-hub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.hub.id
  allow_virtual_network_access = true

  # Avoid parallel PutSubnetOperation lock on the spoke VNet
  depends_on = [
    azurerm_subnet.snet_compute,
    azurerm_subnet.snet_database,
    azurerm_subnet.snet_netapp
  ]
}

# Peering: Hub to Spoke
# Note: Hub is shared, so we create the reverse peering in the Hub's RG
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-${var.environment}"
  resource_group_name       = "rg-${var.project_name}-hub"
  virtual_network_name      = data.azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true

  # Avoid parallel PutSubnetOperation lock on the spoke VNet
  depends_on = [
    azurerm_subnet.snet_compute,
    azurerm_subnet.snet_database,
    azurerm_subnet.snet_netapp
  ]
}
