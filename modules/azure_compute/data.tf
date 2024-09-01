data "azurerm_virtual_network" "virtual_network" {
  name                = local.vnet_name
  resource_group_name = local.vnet_rg
}

data "azurerm_ssh_public_key" "SshPublicKey" {
  provider            = azurerm.ssh_subid
  name                = "ZUSE1-GBS-SSH-VMPUBKEY"
  resource_group_name = "ZUSE1-GBS-RGP-P1-SSHKEYS1"
}
 
data "azurerm_key_vault" "existing_key_vault" {
  count               = local.vault_name != "NA" ? 1 : 0
  name                = local.vault_name
  resource_group_name = local.key_vault_resource_group_name
}
 
data "azurerm_key_vault_key" "key_vault_key" {
  count        = local.vault_name != "NA" ? 1 : 0
  name         = var.encryption_key_name
  key_vault_id = data.azurerm_key_vault.existing_key_vault[0].id
  depends_on   = [data.azurerm_key_vault.existing_key_vault[0]]
}