output "vm_private_ip" {
  value       = join("", azurerm_network_interface.network_interface.*.private_ip_address)
  description = "Private IP."
}
output "vm_os_type" {
  value       = var.os_image[var.os_version].os_type
  description = "OS Type."
}
output "vm_full_name" {
  value       = var.vm_name
  description = "VM full name."
}

output "vm_id" {
  value       = azurerm_linux_virtual_machine.linux_virtual_machine[0].id
  description = "VM ID."
}

output "linux_vm_location" {
  value       = azurerm_linux_virtual_machine.linux_virtual_machine[0].location
  description = "Linux VM location"
}

output "disk_encryption_set_id" {
  value       = length(azurerm_disk_encryption_set.disk_encryption_set) > 0 ? azurerm_disk_encryption_set.disk_encryption_set[0].id : null
  description = "Encryption Set Id"
}