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

| Name | Source | Version |
|------|--------|---------|
| <a name="common"></a> [common](#module\_common) | ../common | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine) | resource |

| Name | Description | Type | Accepted Values | Required | Default |
|------|-------------|------|---------|-----------------|----------|
| <a name="input_vm_resource_group_name"></a> [vm_resource_group_name](#input\vm_resource_group_name) | VM Resource Group Name | `string` | Any Exisitng Resource Group Name | yes |	|
| <a name="input_subnet_id"></a> [subnet_id](#input\subnet_id) | Existing Subnet Id | `string` | Exisitng Subnet Id | yes | |
| <a name="input_vm_name"></a> [vm_name](#input\vm_name) | VM Name | `string` | Any VM Name | yes |	|
| <a name="input_os_version"></a> [os_version](#input\os_version) | OS Version | `string` | "RHEL-8.1", "RHEL-8.2", "RHEL-8.4", "RHEL-8.6", "RHEL-8.8","RHEL-9.0","Ubuntu-18.04-LTS", "Ubuntu-20.04-LTS", "OracleLinux-8.3","OracleLinux-8.9","RockyLinux-9" | yes | |
| <a name="input_root_volume_size"></a> [root_volume_size](#input\root_volume_size) | OS Disk Size | `number` | OS Disk Size | yes | |
| <a name="input_vm_availability_zone"></a> [vm_availability_zone](#input\vm_availability_zone) | Virtual Machine Availability Zone | `number` | 0,1,2,3  | optional |  |
| <a name="input_availability_set_resource_id"></a> [availability_set_resource_id](#input\availability_set_resource_id) | Availability Set Resource Id | `string` | Availability Set Resource Id | optional |	|
| <a name="input_storage_account_primary_endpoint"></a> [storage_account_primary_endpoint](#input\storage_account_primary_endpoint) | storage_account_primary_endpoint | `string` | storage_account_primary_endpoint | yes | |
| <a name="input_encryption_key_name"></a> [encryption_key_name](#input\encryption_key_name) | Encryption Key Name | `string` | Encryption Key Name  | optional |  |
| <a name="input_key_vault_id"></a> [key_vault_id](#input\key_vault_id) | Key Vault Id | `string` | Key Vault Id | optional |	|
| <a name="input_wk_data_classification"></a> [wk_data_classification](#input\_wk_data_classification) | WK Data Classification | `string` | Provide any one of the value (public, internal, confidential, restricted) | yes | |
| <a name="input_wk_patch_class"></a> [wk_patch_class](#input\_wk_patch_class) | WK Patch Class | `string` | Please refer the SOP document and provide correct patch class tag value. Make sure it should end with *_BF | yes |  |
| <a name="input_wk_backup_policy"></a> [wk_backup_policy](#input\_wk_backup_policy) | WK Backup Policy | `string` | Please mention backup policy values like [no- NoBKP / days - 30daysBKP / weekly - 13WeekBKP / monthly - 24MonthBKP] | yes |  |
 
 

## Outputs

| Name | Description |
|------|-------------|
| <a name="vm_private_ip"></a> [vm_private_ip](#output\vm_private_ip) | VM Private IP |
| <a name="vm_os_type"></a> [vm_os_type](#output\vm_os_type) | VM OS Type |
| <a name="vm_full_name"></a> [vm_full_name](#output\vm_full_name) | VM full Name |
| <a name="vm_id"></a> [vm_id](#output\vm_id) | VM ID |
| <a name="linux_vm_location"></a> [linux_vm_location](#output\linux_vm_location) | Linux VM Location |
| <a name="disk_encryption_set_id"></a> [disk_encryption_set_id](#output\disk_encryption_set_id) | Disk Encryption Set Id |


<!-- END_TF_DOCS -->