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
| [azurerm_disk_encryption_set](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/disk_encryption_set) | resource |
| [azurerm_virtual_machine_data_disk_attachment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_extension](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |


## Inputs

| Name | Description | Type | Accepted Values | Required | Default |
|------|-------------|------|---------|-----------------|----------|
| <a name="input_swap_disk_size"></a> [swap_disk_size](#input\swap_disk_size) |Swap Disk Size | `number` | Size of the Swap volume  | Optional |  |
| <a name="input_vm_availability_zone"></a> [vm_availability_zone](#input\vm_availability_zone) | Virtual Machine Availability Zone | `number` | 0,1,2,3  | optional |  |
| <a name="input_subnet_id"></a> [subnet_id](#input\subnet_id) | Existing Subnet Id | `string` | Exisitng Subnet Id | yes | |
| <a name="input_vm_name"></a> [vm_name](#input\vm_name) | VM Name | `string` | Any VM Name | yes |	|
| <a name="input_vm_resource_group_name"></a> [vm_resource_group_name](#input\vm_resource_group_name) | VM Resource Group Name | `string` | Any Exisitng Resource Group Name | yes |	|
| <a name="input_global_wk_tags"></a> [global_wk_tags](#input\global_wk_tags) | WK Mandotary Tags | `string` | WK Standard Tags | yes | |
| <a name="input_wk_data_classification"></a> [wk_data_classification](#input\_wk_data_classification) | WK Data Classification | `string` | Provide any one of the value (public, internal, confidential, restricted) | yes | |


## Outputs

| Name | Description |
|------|-------------|
| <a name="disk_id"></a> [disk_id](#output\disk_id) | Disk Id |

<!-- END_TF_DOCS -->