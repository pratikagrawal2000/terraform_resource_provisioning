variable "subscription_id" {
  description = "Subscription id"
  type        = string
}
variable "os_version" {
  description = "Operating System version"
  type        = string
}

variable "tenant_id" {
  description = "Tenant id"
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

variable "accelerated_networking" {
  description = "Enable accelerated networking for the virtual machine"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Virtual Network subnet Id"
  type        = string
}

variable "os_image" {
  description = "Operating System image"
  type = map(object({
    os_type   = string,
    publisher = string,
    offer     = string,
    sku       = string,
    version   = optional(string),
    plan = optional(object({
      name      = string,
      product   = string,
      publisher = string
    }))
  }))
  default = {
    "RHEL-8.1"         = { os_type = "linux", publisher = "RedHat", offer = "RHEL", sku = "81gen2" },
    "RHEL-8.2"         = { os_type = "linux", publisher = "RedHat", offer = "RHEL", sku = "82gen2" },
    "RHEL-8.4"         = { os_type = "linux", publisher = "RedHat", offer = "RHEL", sku = "84-gen2" },
    "RHEL-8.6"         = { os_type = "linux", publisher = "RedHat", offer = "RHEL", sku = "86-gen2" },
    "RHEL-8.8"         = { os_type = "linux", publisher = "RedHat", offer = "RHEL", sku = "88-gen2" },
    "RHEL-9.0"         = { os_type = "linux", publisher = "RedHat", offer = "RHEL", sku = "90-gen2" },
    "Ubuntu-18.04-LTS" = { os_type = "linux", publisher = "Canonical", offer = "UbuntuServer", sku = "18.04-LTS" },
    "Ubuntu-20.04-LTS" = { os_type = "linux", publisher = "Canonical", offer = "0001-com-ubuntu-server-focal", sku = "20_04-lts-gen2" },
    "OracleLinux-8.3"  = { os_type = "linux", publisher = "Oracle", offer = "Oracle-Linux", sku = "ol83-lvm-gen2" },
    "OracleLinux-8.9"  = { os_type = "linux", publisher = "Oracle", offer = "Oracle-Linux", sku = "ol89-lvm-gen2" },
    "RockyLinux-9"     = { os_type = "linux", publisher = "erockyenterprisesoftwarefoundationinc1653071250513", offer = "rockylinux-9", sku = "rockylinux-9", version = "9.1.20230215", plan = { name = "rockylinux-9", product = "rockylinux-9", publisher = "erockyenterprisesoftwarefoundationinc1653071250513" } }
  }
  validation {
    condition = alltrue([
      for key in keys(var.os_image) : can(regex("^(RHEL-8.1|RHEL-8.2|RHEL-8.4|RHEL-8.6|RHEL-8.8|RHEL-9.0|Ubuntu-18.04-LTS|Ubuntu-20.04-LTS|OracleLinux-8.3|OracleLinux-8.9|RockyLinux-9)$", key))
    ])
    error_message = "Invalid os_image key. Please use one of the following os types as keys: (RHEL-8.1|RHEL-8.2|RHEL-8.4|RHEL-8.6|RHEL-8.8|RHEL-9.0|Ubuntu-18.04-LTS|Ubuntu-20.04-LTS|OracleLinux-8.3|OracleLinux-8.9|RockyLinux-9)."
  }
}

variable "root_volume_size" {
  description = "vm os size"
  type        = number
  validation {
    condition     = var.root_volume_size >= 128
    error_message = "The OS disk size must be greater than or equal to 128."
  }
}

variable "vm_name" {
  description = "Virtual Machine fullname"
  type        = string
}
variable "vm_resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "availability_set_resource_id" {
  description = "Availability Set Resource ID"
  type        = string
}

variable "vm_availability_zone" {
  description = "Availability Zone"
  type        = number
  default     = 1
  validation {
    condition     = can(regex("^[0|1|2|3]$", tostring(var.vm_availability_zone)))
    error_message = "Availability Zone variable should have value [0-3]"
  }
}

variable "vm_type" {
  description = "Virtual Machine Type"
  type        = string
}

variable "storage_account_primary_endpoint" {
  description = "Storage Account Path"
  type        = string
}

variable "encryption_key_name" {
  description = "The name of the Encryption Key"
  type        = string
}


variable "key_vault_id" {
  description = "Name of the Key Vault ID"
  type        = string
}

variable "global_wk_tags" {
  description = "Global WK resources tags"
  type        = map(any)
}

//VM Service Related tags
variable "wk_data_classification" {
  description = "Virtual Machine Data Classification"
  type        = string
}

variable "wk_patch_class" {
  description = "Wk Patch Class"
  type        = string
}

variable "wk_backup_policy" {
  description = "Wk Backup Policy"
  type        = string
}