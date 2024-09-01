output "swap_volume_id" {
  value       = azurerm_managed_disk.managed_disk.id
  description = "Volume ID"
}
