resource "azurerm_key_vault_secret" "this" {
  key_vault_id     = var.key_vault_resource_id
  name             = var.name
  content_type     = var.content_type
  expiration_date  = var.expiration_date
  not_before_date  = var.not_before_date
  tags             = var.tags
  value            = var.value
  value_wo         = var.value_wo
  value_wo_version = var.value_wo_version
}
