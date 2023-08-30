resource "azurerm_key_vault" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  sku_name                        = var.sku_name
  location                        = var.location
  enable_rbac_authorization       = true
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  purge_protection_enabled        = var.purge_protection_enabled
  tags                            = var.tags

  dynamic "contact" {
    for_each = var.contacts
    content {
      name  = contact.value.name
      email = contact.value.email
      phone = contact.value.phone
    }
  }

  dynamic "network_acls" {
    for_each = var.network_acls != {} ? { this = var.network_acls } : {}
    content {
      bypass                     = network_acls.value.ip_rules.bypass
      default_action             = network_acls.value.ip_rules.default_action
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.ip_rules.virtual_network_subnet_ids
    }
  }
}

resource "azurerm_management_lock" "this" {
  for_each   = var.lock != "" ? toset(["this"]) : []
  name       = "lock-${var.name}"
  scope      = azurerm_key_vault.this.id
  lock_level = var.lock
}
