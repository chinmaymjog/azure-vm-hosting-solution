# Private Endpoint for the Shared Hub Backup Storage
resource "azurerm_private_endpoint" "backup_pe" {
  name                = "pe-shared-backups-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.snet_compute.id

  private_service_connection {
    name                           = "psc-shared-backups"
    private_connection_resource_id = data.azurerm_storage_account.st_backups.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  # Automatic DNS Registration
  private_dns_zone_group {
    name                 = "dns-group-backups"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_dns.id]
  }
}

# Private DNS Zone for File Storage
resource "azurerm_private_dns_zone" "storage_dns" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Link the Private DNS Zone to the Spoke VNet
resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "link-to-spoke-vnet"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
