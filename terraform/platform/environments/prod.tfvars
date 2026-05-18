# ==============================================================================
# PRODUCTION ENVIRONMENT BLUEPRINT (prod.tfvars)
# ==============================================================================
# Use this file to customize the hosting architecture for enterprise production scale.
# High-performance instance SKUs, redundant scaling, and larger storage sizes are enabled.

# ------------------------------------------------------------------------------
# 1. Core Platform & Identification Parameters
# ------------------------------------------------------------------------------
project_name        = "shrdhosting"
resource_group_name = "rg-shared-hosting-prod"
location            = "West Europe"
environment         = "prod"

tags = {
  Project     = "Shared Hosting Platform"
  Environment = "Production"
  ManagedBy   = "Terraform"
  Owner       = "Chinmay Jog"
}

# ------------------------------------------------------------------------------
# 2. Compute & Cluster Scaling Parameters
# ------------------------------------------------------------------------------
vm_count             = 4                  # Highly available cluster scale (4 active nodes behind Load Balancer)
vm_size              = "Standard_D2s_v5"  # High-throughput general purpose compute instance
vm_os_disk_size_gb   = 64                 # Professional production OS disk in GB
vm_data_disk_size_gb = 50                 # Enterprise-grade fast SSD block storage disk in GB
admin_username       = "azureadmin"       # Hardened SSH administration username

# ------------------------------------------------------------------------------
# 3. Enterprise Shared Storage & NFS Parameters (Azure NetApp Files)
# ------------------------------------------------------------------------------
netapp_pool_size_tb   = 4                 # NetApp Capacity Pool size in TB (Enterprise production minimum size)
netapp_volume_size_gb = 500               # Production scale volume size for shared PHP/HTML web code
netapp_service_level  = "Premium"         # Premium sub-millisecond IOPS performance tier

# ------------------------------------------------------------------------------
# 4. Highly-Available Database Parameters (MySQL Flexible Server)
# ------------------------------------------------------------------------------
mysql_sku                   = "GP_Standard_D2ds_v4" # General Purpose production class database instance
mysql_storage_gb            = 128                    # Production storage volume in GB
mysql_backup_retention_days = 30                     # Hardened 30-day transactional recovery lifespan

# ------------------------------------------------------------------------------
# 5. Networking & Security Gateway Parameters
# ------------------------------------------------------------------------------
vnet_address_space = ["10.100.0.0/16"]    # Custom isolated virtual network range for production segment
subnet_newbits     = 8                    # Bit size multiplier for platform subnets
hub_address_space  = ["10.200.0.0/16"]    # Production administrative Hub VNet
jumpbox_size       = "Standard_B2s"       # Premium size jumpbox hosting Ansible control-plane engines
my_ip              = "8.8.8.8"            # Restricted home/office corporate IP range for admin SSH access
