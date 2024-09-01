provider "azurerm" {
  alias = "ssh_subid"  #Alias
  features {}
  subscription_id = "ee2c05db-ecf5-4710-bef6-4d59794c55aa" # SubscriptionID of other Subscription
  tenant_id       = var.tenant_id  
  client_id       = var.client_id
  client_secret   = var.client_secret
  
}