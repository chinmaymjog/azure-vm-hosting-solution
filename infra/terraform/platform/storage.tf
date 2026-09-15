# Website Storage (Azure Files Premium NFS)
resource "random_id" "website_storage_suffix" {
  byte_length = 4
}

resource "azurerm_storage_account" "st_website" {
  name                       = "stweb${lower(random_id.website_storage_suffix.hex)}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  account_tier               = "Premium"
  account_replication_type   = "LRS"
  account_kind               = "FileStorage"
  https_traffic_only_enabled = false # Required for NFS

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.snet_compute.id]
    ip_rules                   = [data.http.client_ip.response_body]
    bypass                     = ["AzureServices"]
  }

  tags = var.tags
}

resource "azurerm_storage_share" "nfs_website" {
  name                 = "websites"
  storage_account_name = azurerm_storage_account.st_website.name
  quota                = var.website_storage_gb
  enabled_protocol     = "NFS"
}

output "website_nfs_host" {
  value = "${azurerm_storage_account.st_website.name}.file.core.windows.net"
}

output "website_storage_account_name" {
  value = azurerm_storage_account.st_website.name
}
