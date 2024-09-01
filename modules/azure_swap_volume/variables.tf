variable "vm_resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "vm_name" {
  description = "Virtual Machine Full name"
  type        = string
}

variable "vm_availability_zone" {
  description = "VM Availability Zone"
  type        = number
}

variable "swap_disk_size" {
  description = "Swap Disk Size"
  type        = number
}

variable "vm_id" {
  description = "vm_id from compute module"
  type        = string
}

variable "linux_vm_location" {
  description = "VM location"
  type        = string
}

variable "disk_encryption_set_id" {
  description = "Disk Encryption Set Id"
  type        = string
}

variable "global_wk_tags" {
  description = "Global WK resources tags"
  type        = map(string)
  default     = {}
}
variable "wk_data_classification" {
  description = "Data Classification"
  type        = string
}