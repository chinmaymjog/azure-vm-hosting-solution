resource "azurerm_availability_set" "avset" {
  name                         = "avset-web-${var.environment}"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags                         = var.tags
}

resource "azurerm_network_interface" "nics" {
  count               = var.vm_count
  name                = "nic-web-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet_compute.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Discover the Storage Account via Tags
data "azurerm_resources" "backup_storage" {
  resource_group_name = "rg-${var.project_name}-hub"
  type                = "Microsoft.Storage/storageAccounts"
  
  required_tags = {
    Role = "SharedBackup"
  }
}

data "azurerm_storage_account" "st_backups" {
  name                = data.azurerm_resources.backup_storage.resources[0].name
  resource_group_name = "rg-${var.project_name}-hub"
}

# Discover the Shared Hub SSH Public Key via Tags
data "azurerm_resources" "hub_ssh_key" {
  resource_group_name = "rg-${var.project_name}-hub"
  type                = "Microsoft.Compute/sshPublicKeys"
  
  required_tags = {
    Role = "SharedSSH"
  }
}

data "azurerm_ssh_public_key" "shared" {
  name                = data.azurerm_resources.hub_ssh_key.resources[0].name
  resource_group_name = "rg-${var.project_name}-hub"
}

resource "azurerm_linux_virtual_machine" "vms" {
  count               = var.vm_count
  name                = "webvm-${count.index + 1}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = var.admin_username
  availability_set_id = azurerm_availability_set.avset.id
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.nics[count.index].id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = data.azurerm_ssh_public_key.shared.public_key
  }

  user_data = base64encode(templatefile("${path.module}/ubuntu_provisioner.sh", {
    netapp_ip            = azurerm_netapp_volume.na_volume.mount_ip_addresses[0]
    netapp_path          = azurerm_netapp_volume.na_volume.volume_path
    backup_nfs_host      = "${data.azurerm_storage_account.st_backups.name}.file.core.windows.net"
    storage_account_name = data.azurerm_storage_account.st_backups.name
  }))

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.vm_os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "azurerm_managed_disk" "data_disks" {
  count                = var.vm_count
  name                 = "webvm-data-${count.index + 1}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.vm_data_disk_size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attach" {
  count              = var.vm_count
  managed_disk_id    = azurerm_managed_disk.data_disks[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.vms[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}

output "vm_private_ips" {
  value = azurerm_linux_virtual_machine.vms[*].private_ip_address
}
