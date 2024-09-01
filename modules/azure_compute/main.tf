resource "azurerm_network_interface" "network_interface" {
  name                = "${var.vm_name}-NIC"
  location            = data.azurerm_virtual_network.virtual_network.location
  resource_group_name = var.vm_resource_group_name

  ip_configuration {
    name      = "ipconfig"
    subnet_id = var.subnet_id

    private_ip_address_allocation = "Dynamic"
  }
  accelerated_networking_enabled = var.accelerated_networking
  tags                           = var.global_wk_tags

}
resource "azurerm_disk_encryption_set" "disk_encryption_set" {
  count               = local.vault_name != "NA" ? 1 : 0
  name                = "${var.vm_name}-des"
  resource_group_name = var.vm_resource_group_name                            //var.key_vault_resource_group_name
  location            = data.azurerm_virtual_network.virtual_network.location //data.azurerm_key_vault.existing_key_vault[0].location
  key_vault_key_id    = data.azurerm_key_vault_key.key_vault_key[0].id

  identity {
    type = "SystemAssigned"
  }
  tags = var.global_wk_tags
}
//Accessing the policy to encryption_set
resource "azurerm_key_vault_access_policy" "key_vault_access_policy" {
  count        = local.vault_name != "NA" ? 1 : 0
  key_vault_id = data.azurerm_key_vault.existing_key_vault[0].id

  tenant_id = azurerm_disk_encryption_set.disk_encryption_set[0].identity[0].tenant_id
  object_id = azurerm_disk_encryption_set.disk_encryption_set[0].identity[0].principal_id

  key_permissions = [
    "WrapKey",
    "UnwrapKey",
    "Get"
  ]
  depends_on = [azurerm_disk_encryption_set.disk_encryption_set[0]]
}


resource "azurerm_linux_virtual_machine" "linux_virtual_machine" {
  count = var.os_image[var.os_version].os_type == "linux" ? 1 : 0

  name                  = var.vm_name
  computer_name         = lower(var.vm_name)
  resource_group_name   = var.vm_resource_group_name
  location              = data.azurerm_virtual_network.virtual_network.location
  size                  = var.vm_type
  admin_username        = "localadm"
  network_interface_ids = [azurerm_network_interface.network_interface.id]

  admin_ssh_key {
    username   = "localadm"
    public_key = data.azurerm_ssh_public_key.SshPublicKey.public_key
  }

  os_disk {
    name                   = "${var.vm_name}-OS-DISK"
    caching                = "ReadWrite"
    disk_size_gb           = var.root_volume_size
    storage_account_type   = length(regexall("Standard_[\\w-^s]+[sS]+[\\w-^s]*", var.vm_type)) > 0 ? "Premium_LRS" : "StandardSSD_LRS"
    disk_encryption_set_id = local.vault_name != "NA" ? azurerm_disk_encryption_set.disk_encryption_set[0].id : null
  }

  source_image_reference {
    publisher = var.os_image[var.os_version].publisher
    offer     = var.os_image[var.os_version].offer
    sku       = var.os_image[var.os_version].sku
    version   = "latest"
  }

  dynamic "plan" {
    for_each = lookup(var.os_image[var.os_version], "plan", null) != null ? [1] : []
    content {
      name      = var.os_image[var.os_version].plan.name
      product   = var.os_image[var.os_version].plan.product
      publisher = var.os_image[var.os_version].plan.publisher
    }
  }

  tags = merge(
    var.global_wk_tags,
    {
      "wk_data_classification" = var.wk_data_classification,
      "wk_patch_class"         = var.wk_patch_class,
      "wk_backup_policy"       = var.wk_backup_policy
    }
  )

  boot_diagnostics {
    storage_account_uri = var.storage_account_primary_endpoint
  }

  availability_set_id = local.availability_set_id
  zone                = local.zone

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [azurerm_key_vault_access_policy.key_vault_access_policy[0]]
}
