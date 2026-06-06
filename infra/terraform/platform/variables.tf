variable "project_name" {
  description = "The unique project prefix used for naming and state storage"
  type        = string
  default     = "shrdhosting"
}


variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "West Europe"
}

variable "environment" {
  description = "Environment name (prod/preprod)"
  type        = string
  default     = "preprod"
}

variable "tags" {
  description = "A mapping of tags to assign to the resources"
  type        = map(string)
  default     = {
    Project     = "Shared Hosting Platform"
    ManagedBy   = "Terraform"
    Owner       = "Chinmay Jog"
  }
}

# --- Network Variables ---
variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_newbits" {
  description = "Number of additional bits with which to extend the VNet prefix"
  type        = number
  default     = 8
}

# --- Compute Variables ---
variable "vm_count" {
  description = "Number of VMs to deploy in the cluster"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Size of the virtual machines (Smallest: Standard_B1s)"
  type        = string
  default     = "Standard_B1s"
}

variable "vm_os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
  default     = 30
}

variable "vm_data_disk_size_gb" {
  description = "Size of the Data disk in GB (Min for testing)"
  type        = number
  default     = 10
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

# --- Database Variables ---
variable "mysql_sku" {
  description = "SKU for MySQL Flexible Server (Burstable: B_Standard_B1ms)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "mysql_storage_gb" {
  description = "Storage size for MySQL in GB (Min 20)"
  type        = number
  default     = 20
}

variable "mysql_backup_retention_days" {
  description = "Number of days to retain backups for MySQL"
  type        = number
  default     = 7
}

# --- NetApp Variables ---
variable "netapp_pool_size_tb" {
  description = "Size of the NetApp Pool in TB (Absolute Min 4)"
  type        = number
  default     = 4
}

variable "netapp_volume_size_gb" {
  description = "Size of the NetApp Volume in GB"
  type        = number
  default     = 100
}

variable "netapp_service_level" {
  description = "Service level for NetApp (Standard is most cost-effective)"
  type        = string
  default     = "Standard"
}

# --- Front Door Variables ---
variable "afd_sku" {
  description = "SKU for Azure Front Door"
  type        = string
  default     = "Standard_AzureFrontDoor"
}

# --- Hub & Management Variables ---
variable "hub_address_space" {
  description = "Address space for the Hub VNet"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "my_ip" {
  description = "Your Home/Office IP for restricted Jumpbox access (e.g. 1.2.3.4)"
  type        = string
  default     = "*" # WARNING: Change this to your real IP for security
}

variable "jumpbox_size" {
  description = "Size of the Jumpbox/Ansible VM"
  type        = string
  default     = "Standard_B1s"
}

variable "backup_nfs_host" {
  description = "The FQDN of the shared Hub backup storage account"
  type        = string
  default     = "stsharedbackupshub.file.core.windows.net"
}
