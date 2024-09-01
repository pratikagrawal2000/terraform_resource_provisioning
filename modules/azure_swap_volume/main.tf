resource "azurerm_managed_disk" "managed_disk" {
  name                   = local.swap_disk_name
  location               = var.linux_vm_location
  resource_group_name    = var.vm_resource_group_name
  storage_account_type   = "Premium_LRS"
  create_option          = "Empty"
  disk_size_gb           = var.swap_disk_size
  zone                   = var.vm_availability_zone != 0 ? var.vm_availability_zone : null
  disk_encryption_set_id = var.disk_encryption_set_id != null ? var.disk_encryption_set_id : null

  tags = merge(
    var.global_wk_tags,
    {
      "wk_data_classification" = var.wk_data_classification,
      "Name"                   = local.swap_disk_name
    }
  )

}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.managed_disk.id
  virtual_machine_id = var.vm_id
  lun                = 1
  caching            = "None"
  depends_on = [
    azurerm_managed_disk.managed_disk
  ]
}


resource "azurerm_virtual_machine_extension" "virtual_machine_extension" {
  name                 = "CustomScript"
  virtual_machine_id   = var.vm_id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  settings             = <<SETTINGS
    {
        "fileUris": ["https://vm-agent-setups.s3.amazonaws.com/AgentScript/Dev-Branch/LinuxScript/createswapdisk.sh"]
    }
  SETTINGS
  protected_settings   = <<PROTECTED_SETTINGS
      {
        "commandToExecute": "./createswapdisk.sh"
      }
    PROTECTED_SETTINGS

  tags = {
    environment = "Development"
  }
  depends_on = [azurerm_virtual_machine_data_disk_attachment.disk_attachment]
}
