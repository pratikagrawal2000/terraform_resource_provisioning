output "vm_private_ip" {
  value       = module.compute.vm_private_ip
  description = "Private IP Address"
}
output "vm_os_type" {
  value       = module.compute.vm_os_type
  description = "OS Type"
}
output "vm_name" {
  value       = var.vm_name
  description = "VM Name"
}

output "vm_id" {
  value       = module.compute.vm_id
  description = "Virtual Machine ID"
}

output "linux_vm_location" {
  value       = module.compute.linux_vm_location
  description = "VM location"
}