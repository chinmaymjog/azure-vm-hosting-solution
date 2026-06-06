terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stsharedhostingtfstate"
    container_name       = "tfstate"
    key                  = "shared-hub.tfstate"
  }
}

provider "azurerm" {
  features {
    netapp {
      prevent_volume_destruction = false
    }
  }
}
