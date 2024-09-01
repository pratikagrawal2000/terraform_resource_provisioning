module "common" {
  source                 = "../modules/common"
  wk_division_code       = var.wk_division_code
  wk_bu_code             = var.wk_bu_code
  wk_application_name    = var.wk_application_name
  wk_application_bit_id  = var.wk_application_bit_id
  wk_requestor           = var.wk_requestor
  wk_business_owner      = var.wk_business_owner
  wk_technical_owner     = var.wk_technical_owner
  wk_app_support_group   = var.wk_app_support_group
  wk_infra_support_group = var.wk_infra_support_group
  wk_environment_name    = var.wk_environment_name
  wk_resource_class      = var.wk_resource_class
  wk_resource_name       = var.wk_resource_name

}

module "compute" {
  source = "../modules/azure_compute"

  subscription_id                  = var.subscription_id
  tenant_id                        = var.tenant_id
  client_id                        = var.client_id
  client_secret                    = var.client_secret
  os_version                       = var.os_version
  subnet_id                        = var.subnet_id
  vm_name                          = var.vm_name
  vm_resource_group_name           = var.vm_resource_group_name
  vm_availability_zone             = var.vm_availability_zone
  availability_set_resource_id     = var.availability_set_resource_id
  vm_type                          = var.vm_type
  root_volume_size                 = var.root_volume_size
  storage_account_primary_endpoint = var.storage_account_primary_endpoint
  encryption_key_name              = var.encryption_key_name
  key_vault_id                     = var.key_vault_id
  accelerated_networking           = var.accelerated_networking
  global_wk_tags                   = module.common.global_wk_tags
  wk_data_classification           = var.wk_data_classification
  wk_patch_class                   = var.wk_patch_class
  wk_backup_policy                 = local.backup_schedule[var.wk_backup_policy]
}


module "swap_disk" {
  source                 = "../modules/azure_swap_volume"
  vm_resource_group_name = var.vm_resource_group_name
  vm_name                = var.vm_name
  swap_disk_size         = var.swap_disk_size
  vm_availability_zone   = var.vm_availability_zone
  count                  = (local.enable_swap_volume && var.swap_disk_size > 0) ? 1 : 0
  disk_encryption_set_id = module.compute.disk_encryption_set_id
  vm_id                  = module.compute.vm_id
  linux_vm_location      = module.compute.linux_vm_location
  wk_data_classification = var.wk_data_classification
  global_wk_tags         = module.common.global_wk_tags
  depends_on             = [module.compute]
}