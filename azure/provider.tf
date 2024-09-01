terraform {
  required_version = ">=1.5.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.31.1"
    }
  }
}

provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret

  features {}
}

provider "azurerm" {
  alias = "ssh_subid"  #Alias
  features {}
  subscription_id = "ee2c05db-ecf5-4710-bef6-4d59794c55aa" # SubscriptionID of other Subscription
  tenant_id       = var.tenant_id  
  client_id       = var.client_id
  client_secret   = var.client_secret
}
