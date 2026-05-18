terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stsharedhostingtfstate"
    container_name       = "tfstate"
    key                  = "hosting-platform.tfstate"
  }
}
