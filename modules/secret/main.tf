resource "azapi_resource" "secret" {
  name = var.name
  tags = var.tags
  type = "Microsoft.KeyVault/vaults/secrets@2023-07-01" 
  body = jsonencode({
    properties =   {
      contentType = var.content_type
      value = var.value
      attributes  = jsonencode({
        enabled = true
        exp = jsonencode(var.expiration_date)
        nbf = jsonencode(var.not_before_date)
      })
    }  
  })
  parent_id = "${var.key_vault_resource_id}"
  response_export_values = ["*"]
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.secret.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
