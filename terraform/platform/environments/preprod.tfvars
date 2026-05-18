# ==============================================================================
# PRE-PRODUCTION ENVIRONMENT BLUEPRINT (preprod.tfvars)
# ==============================================================================
# Use this file to customize the hosting architecture for testing, staging, and UAT.
# Cost-optimized instance SKUs and smaller capacities are used by default.

# ------------------------------------------------------------------------------
# 1. Core Platform & Identification Parameters
# ------------------------------------------------------------------------------
project_name        = "shrdhosting"
location            = "West Europe"
environment         = "preprod"

tags = {
  Project     = "Shared Hosting Platform"
  Environment = "Pre-Production"
  ManagedBy   = "Terraform"
  Owner       = "Chinmay Jog"
}

# ------------------------------------------------------------------------------
# 2. Compute & Cluster Scaling Parameters
# ------------------------------------------------------------------------------
vm_count             = 2                  # Number of active web nodes in the load-balanced cluster
vm_size              = "Standard_B1s"     # Small burstable CPU instance for cost savings
vm_os_disk_size_gb   = 30                 # Boot OS disk size in GB
vm_data_disk_size_gb = 10                 # Local scratch block storage disk in GB
admin_username       = "azureuser"        # Admin SSH login username

# ------------------------------------------------------------------------------
# 3. Enterprise Shared Storage & NFS Parameters (Azure NetApp Files)
# ------------------------------------------------------------------------------
netapp_pool_size_tb   = 1                 # NetApp Capacity Pool size in TB (Set to 1 for cost-efficiency)
netapp_volume_size_gb = 100               # Size of the active NFS volume for site data
netapp_service_level  = "Standard"        # NetApp Performance Tier (Standard/Premium/Ultra)

# ------------------------------------------------------------------------------
# 4. Highly-Available Database Parameters (MySQL Flexible Server)
# ------------------------------------------------------------------------------
mysql_sku                   = "B_Standard_B1ms" # Burstable instance for preproduction workloads
mysql_storage_gb            = 20                 # Database storage volume size in GB (Min 20)
mysql_backup_retention_days = 7                  # Number of days to retain transaction backups

# ------------------------------------------------------------------------------
# 5. Networking & Security Gateway Parameters
# ------------------------------------------------------------------------------
vnet_address_space = ["10.0.0.0/16"]      # Virtual Network range
subnet_newbits     = 8                    # Bit size multiplier for platform subnets
hub_address_space  = ["10.10.0.0/16"]     # Hub network range housing the administrative Jumpbox
jumpbox_size       = "Standard_B1s"       # Size of the control-plane Ansible host
my_ip              = "*"                  # Permitted ingress IP for administrative access (Change to your home IP)
