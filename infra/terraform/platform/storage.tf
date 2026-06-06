resource "azurerm_netapp_account" "na_account" {
  name                = "na-account-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_netapp_pool" "na_pool" {
  name                = "na-pool-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_netapp_account.na_account.name
  service_level       = var.netapp_service_level
  size_in_tb          = var.netapp_pool_size_tb
  tags                = var.tags
}

resource "azurerm_netapp_volume" "na_volume" {
  name                = "na-vol-websites"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_netapp_account.na_account.name
  pool_name           = azurerm_netapp_pool.na_pool.name
  volume_path         = "netappwebsites-${var.environment}"
  service_level       = var.netapp_service_level
  subnet_id           = azurerm_subnet.snet_netapp.id
  protocols           = ["NFSv4.1"]
  storage_quota_in_gb = var.netapp_volume_size_gb
  tags                = var.tags
  
  export_policy_rule {
    rule_index          = 1
    allowed_clients     = ["0.0.0.0/0"]
    protocols_enabled   = ["NFSv4.1"]
    unix_read_only      = false
    unix_read_write     = true
    root_access_enabled = true
  }
}

output "netapp_mount_ip" {
  value = azurerm_netapp_volume.na_volume.mount_ip_addresses[0]
}
