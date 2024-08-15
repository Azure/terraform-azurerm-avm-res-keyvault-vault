resource "azurerm_key_vault_access_policy" "this" {
  for_each = var.legacy_access_policies_enabled ? var.legacy_access_policies : {}

  key_vault_id            = azurerm_key_vault.this.id
  object_id               = each.value.object_id
  tenant_id               = var.tenant_id
  application_id          = each.value.application_id
  certificate_permissions = each.value.certificate_permissions
  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  storage_permissions     = each.value.storage_permissions
}
