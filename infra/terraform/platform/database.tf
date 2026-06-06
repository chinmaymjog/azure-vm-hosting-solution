resource "azurerm_private_dns_zone" "mysql_dns" {
  name                = "mysql-${var.environment}.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql_dns_link" {
  name                  = "mysql-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Discover Hub VNet to link DNS
data "azurerm_virtual_network" "hub_vnet" {
  name                = "vnet-${var.project_name}-hub"
  resource_group_name = "rg-${var.project_name}-hub"
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql_dns_hub_link" {
  name                  = "mysql-dns-hub-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql_dns.name
  virtual_network_id    = data.azurerm_virtual_network.hub_vnet.id
}

# Discover the Shared Hub Key Vault via Tags
data "azurerm_resources" "hub_vault" {
  resource_group_name = "rg-${var.project_name}-hub"
  type                = "Microsoft.KeyVault/vaults"
  
  required_tags = {
    Role = "SharedVault"
  }
}

data "azurerm_key_vault" "hub" {
  name                = data.azurerm_resources.hub_vault.resources[0].name
  resource_group_name = "rg-${var.project_name}-hub"
}

data "azurerm_key_vault_secret" "db_password" {
  name         = "mysql-admin-password"
  key_vault_id = data.azurerm_key_vault.hub.id
}

resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = "mysql-shared-${var.environment}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  administrator_login    = "dbadmin"
  administrator_password = data.azurerm_key_vault_secret.db_password.value
  sku_name               = var.mysql_sku
  
  storage {
    size_gb = var.mysql_storage_gb
  }
  
  backup_retention_days = var.mysql_backup_retention_days
  delegated_subnet_id    = azurerm_subnet.snet_database.id
  private_dns_zone_id    = azurerm_private_dns_zone.mysql_dns.id
  tags                   = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql_dns_link]
}

resource "azurerm_mysql_flexible_server_configuration" "disable_ssl" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  value               = "OFF"
}

resource "azurerm_mysql_flexible_database" "db" {
  name                = "websites_db"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

output "mysql_host" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}
