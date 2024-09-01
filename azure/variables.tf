#####Login data############
variable "tenant_id" {
  description = "Tenant id"
  type        = string
}
variable "subscription_id" {
  description = "Subscription Id"
  type        = string
}
variable "client_id" {
  description = "Client Id"
  type        = string
}
variable "client_secret" {
  description = "Client Secret"
  type        = string
}

##############################
#   Encryption Variables     #
##############################

variable "encryption_key_name" {
  description = "Encryption Set Name"
  type        = string
}

// variable "key_vault_resource_group_name" {
//   description = "Resource Group Name of key"
//   type        = string
// }

variable "key_vault_id" {
  description = "Key Vault ID"
  type        = string
}

##############################
#   VM Service Variables     #
##############################

# VM related variables
variable "os_version" {
  description = "Operating System version"
  type        = string
}

variable "accelerated_networking" {
  description = "Accelerated Networking"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Virtual Network subnet Id"
  type        = string
}

variable "storage_account_primary_endpoint" {
  description = "Storage Account Primary endpoint"
  type        = string
}

variable "root_volume_size" {
  description = "Root OS Disk Size"
  type        = number
}

variable "vm_name" {
  description = "Virtual Machine name"
  type        = string

  validation {
    condition     = can(regex("^([a-zA-Z\\d\\s.-]{1,15})$", var.vm_name))
    error_message = "Virtual Machine name should be less or equal 15 characters."
  }
}
variable "vm_resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "vm_availability_zone" {
  description = "Availability Zone"
  type        = number
}

variable "availability_set_resource_id" {
  description = "Availability Set Resource ID"
  type        = string
}

variable "vm_type" {
  description = "Virtual Machine size"
  type        = string
}

##############################
#   Common tags              #
##############################

variable "wk_division_code" {
  description = "Division Code"
  type        = string
}

variable "wk_bu_code" {
  description = "WK BU Code"
  type        = string
}

variable "wk_application_name" {
  description = "Application Name"
  type        = string
}

variable "wk_requestor" {
  description = "WK Requestor"
  type        = string
}

variable "wk_business_owner" {
  description = "WK Bussines Owner"
  type        = string
}

variable "wk_technical_owner" {
  description = "WK Technical Owner"
  type        = string
}

variable "wk_app_support_group" {
  description = "WK App Support Group"
  type        = string
}
variable "wk_infra_support_group" {
  description = "WK Infra Support Group"
  type        = string
}

variable "wk_application_bit_id" {
  description = "Application bit id"
  type        = string
}

variable "wk_environment_name" {
  description = "Virtual Machine environment"
  type        = string
}

variable "wk_resource_class" {
  description = "WK Resource Class"
  type        = string
}

variable "wk_resource_name" {
  description = "WK Resource Name"
  type        = string
}

###############################
#         Swap Disk           #
###############################

variable "swap_disk_size" {
  description = "Swap Disk Size"
  type        = number
}

##############################
#   VM Service Related tags  #
##############################

variable "wk_data_classification" {
  description = "Virtual Machine Data Classification"
  type        = string
  validation {
    condition     = can(regex("^(public|internal|confidential|restricted)$", var.wk_data_classification))
    error_message = "Please provide any one of the value (public|internal|confidential|restricted)."
  }
}

variable "wk_patch_class" {
  description = "Wk Patch Class"
  type        = string
  validation {
    condition     = can(regex("(.*_BF$)", var.wk_patch_class))
    error_message = "Please provide value like (eg:c2w2tg2z1.NET_BF)"
  }
}

variable "wk_backup_policy" {
  description = "Wk Backup Policy"
  type        = string
  validation {
    condition     = can(regex("^(no|days|weekly|monthly)$", var.wk_backup_policy))
    error_message = "Please provide any one of the value (no|days|weekly|monthly)."
  }
}

