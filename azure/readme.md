<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azure"></a> [azure](#requirement\_azure) | >=1.5.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azure"></a> [azure](#provider\_azure) | >= 2.31.1 |

## Modules

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="common"></a> [common](#module\_common) | ../common | n/a |
| <a name="azure_compute"></a> [azure_compute](#module\_azure_compute) | ../compute | n/a |
| <a name="azure_swap_volume"></a> [azure_swap_volume](#module\_azure_swap_volume) | ../azure_swap_volume | n/a |

## Resources

| Name | Type |
|------|------|
| [NA](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | Check each Modules |

| Name | Description | Type | Accepted Values | Required | Default |
|------|-------------|------|---------|-----------------|----------|
| <a name="input_swap_disk_size"></a> [swap_disk_size](#input\swap_disk_size) |Swap Disk Size | `number` | Size of the Swap volume  | Optional |  |
| <a name="input_vm_resource_group_name"></a> [vm_resource_group_name](#input\vm_resource_group_name) | VM Resource Group Name | `string` | Any Exisitng Resource Group Name | yes |	|
| <a name="input_subnet_id"></a> [subnet_id](#input\subnet_id) | Existing Subnet Id | `string` | Exisitng Subnet Id | yes | |
| <a name="input_vm_name"></a> [vm_name](#input\vm_name) | VM Name | `string` | Any VM Name | yes |	|
| <a name="input_os_version"></a> [os_version](#input\os_version) | OS Version | `string` | "RHEL-8.1", "RHEL-8.2", "RHEL-8.4", "RHEL-8.6", "RHEL-8.8","RHEL-9.0","Ubuntu-18.04-LTS", "Ubuntu-20.04-LTS", "OracleLinux-8.3","OracleLinux-8.9","RockyLinux-9" | yes | |
| <a name="input_root_volume_size"></a> [root_volume_size](#input\root_volume_size) | OS Disk Size | `number` | OS Disk Size | yes | 128 |
| <a name="input_vm_type"></a> [vm_type](#input\vm_type) | VM Type | `string` | Type of VM | yes | |
| <a name="input_vm_availability_zone"></a> [vm_availability_zone](#input\vm_availability_zone) | Virtual Machine Availability Zone | `number` | 0,1,2,3  | optional | 0 |
| <a name="input_availability_set_resource_id"></a> [availability_set_resource_id](#input\availability_set_resource_id) | Availability Set Resource Id | `string` | Availability Set Resource Id | optional |	|
| <a name="input_storage_account_primary_endpoint"></a> [storage_account_primary_endpoint](#input\storage_account_primary_endpoint) | storage_account_primary_endpoint | `string` | storage_account_primary_endpoint | yes | |
| <a name="input_encryption_key_name"></a> [encryption_key_name](#input\encryption_key_name) | Encryption Key Name | `string` | Encryption Key Name  | optional |  |
| <a name="input_key_vault_id"></a> [key_vault_id](#input\key_vault_id) | Key Vault Id | `string` | Key Vault Id | optional |	|
| <a name="input_accelerated_networking_enabled"></a> [accelerated_networking_enabled](#input\accelerated_networking_enabled) | Accelerated Networking | `string` | Accelerated Networking | optional | false |
| <a name="input_wk_data_classification"></a> [wk_data_classification](#input\_wk_data_classification) | WK Data Classification | `string` | Provide any one of the value (public, internal, confidential, restricted) | yes | |
| <a name="input_wk_patch_class"></a> [wk_patch_class](#input\_wk_patch_class) | WK Patch Class | `string` | Please refer the SOP document and provide correct patch class tag value. Make sure it should end with *_BF | yes |  |
| <a name="input_wk_backup_policy"></a> [wk_backup_policy](#input\_wk_backup_policy) | WK Backup Policy | `string` | Please mention backup policy values like [no- NoBKP / days - 30daysBKP / weekly - 13WeekBKP / monthly - 24MonthBKP] | yes |  |
| <a name="input_wk_division_code"></a> [wk\_division\_code](#input\_wk\_division\_code) | WK Divison Code | `string` | Start with 'd' followed by three digits (e.g.,d123).| yes |
| <a name="input_wk_bu_code"></a> [wk\_bu_code](#input\wk\_bu_\code) | WK BU Code. | `string` | Start with 'b' followed by three digits (e.g., b123).| yes |
| <a name="input_wk_application_bit_id"></a> [wk_application_bit_id](#input\_wk_application_bit_id) | WK Application Bit ID | `string` | Exactly 12 characters long and can contain letters and digits.| yes |
| <a name="input_wk_application_name"></a> [wk_application_name](#input\_wk_application_name) | WK Application Name | `string` | Start and end with a lowercase letter or digit and can only contain lowercase letters, digits, spaces, dots, underscores and hyphens.| yes |
| <a name="input_wk_environment_name"></a> [wk_environment_name](#input\_wk_environment_name) | WK Environment Name | `string` | Accepts any one of the value dev, tst, int, qae, stg, uat, prd, dre, non, lte.| yes |
| <a name="input_wk_resource_class"></a> [wk_resource_class](#input\_wk_resource_class) | WK Resource Class | `string` | Start and end with an alphanumeric character and can contain alphanumeric characters, underscores, dots, hyphens and spaces in between.| yes |
| <a name="input_wk_resource_name"></a> [wk_resource_name](#input\_wk_resource_name) | WK Resource Name | `string` | Start and end with an alphanumeric character and can contain alphanumeric characters, underscores, dots, hyphens and spaces in between.| yes |
| <a name="input_wk_requestor"></a> [wk_requestor](#input\_wk_requestor) | WK Requestor mail id. | `string` | Email.id should be firstname.lastname@wolterskluwer.com.| yes |
| <a name="input_wk_business_owner"></a> [wk_business_owner](#input\_wk_business_owner) | WK Business Owner mail id | `string` | Email.id should be firstname.lastname@wolterskluwer.com.| yes |
| <a name="input_wk_technical_owner"></a> [wk_technical_owner](#input\_wk_technical_owner) | WK Technical Owner mail id | `string` | Email.id should be firstname.lastname@wolterskluwer.com.| yes |
| <a name="input_wk_app_support_group"></a> [wk_app_support_group](#input\_wk_app_support_group) | WK App Support Group | `string` | Provide valid Rainier assignment group.| yes |
| <a name="input_wk_infra_support_group"></a> [wk_infra_support_group](#input\_wk_infra_support_group) | WK Infra Support Group | `string` | Provide valid Rainier assignment group.| yes |


## Outputs

| Name | Description |
|------|-------------|
| <a name="vm_private_ip"></a> [vm_private_ip](#output\vm_private_ip) | VM Private IP |
| <a name="vm_os_type"></a> [vm_os_type](#output\vm_os_type) | VM OS Type |
| <a name="vm_full_name"></a> [vm_full_name](#output\vm_full_name) | VM full Name |
| <a name="vm_id"></a> [vm_id](#output\vm_id) | VM ID |
| <a name="linux_vm_location"></a> [linux_vm_location](#output\linux_vm_location) | Linux VM Location |

<!-- END_TF_DOCS -->