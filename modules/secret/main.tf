resource "azapi_resource" "this" {
  type      = "Microsoft.KeyVault/vaults/secrets@2023-07-01"
  name      = var.name
  parent_id = var.key_vault_resource_id
  tags      = var.tags

  body = {
    properties = {
      value       = var.value
      contentType = var.content_type
      attributes = {
        enabled = true
        nbf     = var.not_before_date != null ? formatdate("YYYY-MM-DD", var.not_before_date) : null
        exp     = var.expiration_date != null ? formatdate("YYYY-MM-DD", var.expiration_date) : null
      }
    }
  }
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
