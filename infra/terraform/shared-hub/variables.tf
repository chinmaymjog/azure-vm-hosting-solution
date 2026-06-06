variable "project_name" {
  description = "The unique project prefix used for naming and state storage"
  type        = string
  default     = "shrdhosting"
}

variable "location" {
  description = "Azure region for the Hub"
  type        = string
  default     = "West Europe"
}

variable "tags" {
  description = "Tags for the Hub"
  type        = map(string)
  default     = {
    Project   = "Shared Hosting Platform"
    Layer     = "Management Hub"
    ManagedBy = "Terraform"
  }
}

variable "hub_address_space" {
  description = "Address space for the Hub VNet"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "admin_username" {
  description = "Admin username"
  type        = string
  default     = "azureuser"
}

variable "jumpbox_size" {
  description = "Size of the Jumpbox"
  type        = string
  default     = "Standard_B1s"
}

variable "my_ip" {
  description = "Your Home/Office IP"
  type        = string
  default     = "*"
}
