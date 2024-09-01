locals {
  availability_set_id           = var.vm_availability_zone == 0 && var.availability_set_resource_id != "NA" ? var.availability_set_resource_id : null
  zone                          = var.vm_availability_zone != 0 ? var.vm_availability_zone : null
  vnet_name                     = element(split("/", var.subnet_id), 8)
  vnet_rg                       = element(split("/", var.subnet_id), 4)
  vault_name                    = var.key_vault_id != "NA" ? element(split("/", var.key_vault_id), 8) : "NA"
  key_vault_resource_group_name = var.key_vault_id != "NA" ? element(split("/", var.key_vault_id), 4) : "NA"
}