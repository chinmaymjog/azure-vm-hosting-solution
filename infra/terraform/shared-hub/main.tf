# Shared Management Hub
resource "azurerm_resource_group" "hub_rg" {
  name     = "rg-${var.project_name}-hub"
  location = var.location
  tags     = var.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "hub_vnet" {
  name                = "vnet-${var.project_name}-hub"
  address_space       = var.hub_address_space
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "snet_hub_mgmt" {
  name                 = "snet-mgmt"
  resource_group_name  = azurerm_resource_group.hub_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = [cidrsubnet(var.hub_address_space[0], 8, 1)]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

# --- 🔐 Shared Key Vault ---
resource "azurerm_key_vault" "hub_vault" {
  name                        = "kv-${var.project_name}-${lower(random_id.storage_suffix.hex)}"
  location                    = azurerm_resource_group.hub_rg.location
  resource_group_name         = azurerm_resource_group.hub_rg.name
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days      = 7
  purge_protection_enabled        = false
  sku_name                        = "standard"

  # 1. Access for the deployment principal (You)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions      = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
    certificate_permissions = ["Get", "List", "Create", "Import", "Update", "Delete"]
  }

  # 2. Access for Azure Front Door (to fetch certificates)
  # This is the well-known ID for the Front Door service principal
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "ad0e1c04-45a3-4b6d-8196-ad7434727851" # Microsoft.Azure.FrontDoor

    secret_permissions      = ["Get"]
    certificate_permissions = ["Get"]
  }

  # 3. Access for the Jumpbox User Assigned Identity
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.jumpbox_id.principal_id

    secret_permissions = ["Get", "List"]
  }

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    
    # Allow the Hub Management Subnet
    virtual_network_subnet_ids = [azurerm_subnet.snet_hub_mgmt.id]
    
    # Allow the local machine running Terraform
    ip_rules = [data.http.client_ip.response_body]
  }

  tags = merge(var.tags, {
    Role = "SharedVault"
  })
}

# Generate Random DB Password
resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!#$%"
}

# Store in Vault
resource "azurerm_key_vault_secret" "db_password" {
  name         = "mysql-admin-password"
  value        = random_password.db_password.result
  key_vault_id = azurerm_key_vault.hub_vault.id
}

# --- 🔑 Cloud-Native SSH Key Management ---
resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store Private Key in Vault (Disaster Recovery)
resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "ssh-private-key"
  value        = tls_private_key.global_key.private_key_pem
  key_vault_id = azurerm_key_vault.hub_vault.id
}

# Register Public Key as a Managed Azure Resource
resource "azurerm_ssh_public_key" "shared_key" {
  name                = "ssh-key-${var.project_name}-shared"
  resource_group_name = azurerm_resource_group.hub_rg.name
  location            = azurerm_resource_group.hub_rg.location
  public_key          = tls_private_key.global_key.public_key_openssh

  tags = merge(var.tags, {
    Role = "SharedSSH"
  })
}

# --- 💾 Shared Backup Storage (Azure Files NFS) ---
resource "random_id" "storage_suffix" {
  byte_length = 4
}

# Discover the public IP of the machine running Terraform
data "http" "client_ip" {
  url = "https://ifconfig.me/ip"
}

resource "azurerm_storage_account" "st_backups" {
  name                     = "stbackup${lower(random_id.storage_suffix.hex)}"
  resource_group_name      = azurerm_resource_group.hub_rg.name
  location                 = azurerm_resource_group.hub_rg.location
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "FileStorage"
  https_traffic_only_enabled = false # Required for NFS
  
  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.snet_hub_mgmt.id]
    ip_rules                   = [data.http.client_ip.response_body]
    bypass                     = ["AzureServices"]
  }

  tags = merge(var.tags, {
    Role = "SharedBackup"
  })
}

resource "azurerm_storage_share" "nfs_backups" {
  name                 = "backups"
  storage_account_name = azurerm_storage_account.st_backups.name
  quota                = 100
  enabled_protocol     = "NFS"
}

# Jumpbox Public IP
resource "azurerm_public_ip" "jumpbox_pip" {
  name                = "pip-jumpbox-shared"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Jumpbox NIC
resource "azurerm_network_interface" "jumpbox_nic" {
  name                = "nic-jumpbox-shared"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet_hub_mgmt.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox_pip.id
  }
}

# Jumpbox VM
resource "azurerm_user_assigned_identity" "jumpbox_id" {
  name                = "id-${var.project_name}-jumpbox"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "vm-${var.project_name}-jumpbox"
  resource_group_name = azurerm_resource_group.hub_rg.name
  location            = azurerm_resource_group.hub_rg.location
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.jumpbox_nic.id,
  ]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.jumpbox_id.id]
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.global_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  user_data = base64encode(templatefile("${path.module}/jumpbox_provisioner.sh", {
    backup_nfs_host      = "${azurerm_storage_account.st_backups.name}.file.core.windows.net"
    storage_account_name = azurerm_storage_account.st_backups.name
  }))
}



output "ssh_command_jumpbox" {
  description = "Command to SSH into the Jumpbox"
  value       = "ssh -i ../../ssh-key ${var.admin_username}@${azurerm_public_ip.jumpbox_pip.ip_address}"
}

output "backup_nfs_host" {
  value = "${azurerm_storage_account.st_backups.name}.file.core.windows.net"
}

output "hub_vault_name" {
  value = azurerm_key_vault.hub_vault.name
}

output "jumpbox_identity_client_id" {
  value = azurerm_user_assigned_identity.jumpbox_id.client_id
}

resource "azurerm_role_assignment" "vault_secrets_user" {
  scope                = azurerm_key_vault.hub_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.jumpbox_id.principal_id
}
