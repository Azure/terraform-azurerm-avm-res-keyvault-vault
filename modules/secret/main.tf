# moved {
#   from = azurerm_key_vault_secret.this
#   to   = azapi_resource.this
# }

resource "azapi_resource" "this" {
  type      = "Microsoft.KeyVault/vaults/secrets@2024-11-01"
  name      = var.name
  parent_id = var.key_vault_resource_id

  body = {
    properties = {
      attributes = {
        enabled = var.enabled
        exp     = var.expiration_date != null ? provider::time::rfc3339_parse(var.expiration_date).unix : null
        nbf     = var.not_before_date != null ? provider::time::rfc3339_parse(var.not_before_date).unix : null
      }
      contentType = var.content_type
    }
  }
  sensitive_body = {
    properties = {
      value = coalesce(var.value_wo, var.value)
    }
  }
  sensitive_body_version = {
    "properties.value" = var.value_wo_version
  }
  tags = var.tags

  response_export_values = [
    "properties.secretUri",
    "properties.secretUriWithVersion",
  ]
}

module "avm_interfaces" {
  source                                    = "Azure/avm-utl-interfaces/azure"
  version                                   = "0.3.0"
  role_assignments                          = var.role_assignments
  role_assignment_definition_scope          = var.key_vault_resource_id
  role_assignment_definition_lookup_enabled = var.role_definition_lookup_enabled
  role_assignment_name_use_random_uuid      = true
}

resource "azapi_resource" "role_assignments" {
  for_each = module.avm_interfaces.role_assignments_azapi

  type      = each.value.type
  body      = each.value.body
  name      = each.value.name
  parent_id = azapi_resource.this.id
}
