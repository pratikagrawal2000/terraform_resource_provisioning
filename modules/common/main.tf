locals {
  global_wk_tags = {
    "wk_division_code"       = var.wk_division_code,
    "wk_bu_code"             = var.wk_bu_code,
    "wk_application_name"    = var.wk_application_name,
    "wk_application_bit_id"  = var.wk_application_bit_id,
    "wk_requestor"           = var.wk_requestor,
    "wk_business_owner"      = var.wk_business_owner,
    "wk_technical_owner"     = var.wk_technical_owner,
    "wk_app_support_group"   = var.wk_app_support_group,
    "wk_infra_support_group" = var.wk_infra_support_group,
    "wk_environment_name"    = var.wk_environment_name,
    "wk_resource_class"      = var.wk_resource_class,
    "wk_resource_name"       = var.wk_resource_name
  }
}