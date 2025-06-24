moved {
  from = azurerm_key_vault_secret.this
  to   = azapi_resource.this
}

resource "azapi_resource" "this" {
  parent_id = var.parent_id
  type      = "Microsoft.KeyVault/vaults/secrets@2024-11-01"
  name      = var.name
  body = {
    properties = {
      contentType = var.content_type
      attributes = {
        enabled = true
        exp     = var.expiration_date == null ? null : provider::time::rfc3339_parse(var.expiration_date).unix
        nbf     = var.not_before_date == null ? null : provider::time::rfc3339_parse(var.not_before_date).unix
      }
    }
    tags = var.tags
  }
  sensitive_body = {
    properties = {
      value = coalesce(var.value_wo, var.value)
    }
  }
  schema_validation_enabled = false

}

module "interfaces" {
  source                                    = "Azure/avm-utl-interfaces/azure"
  version                                   = "0.2.0"
  role_assignment_definition_scope          = var.parent_id
  role_assignment_definition_lookup_enabled = true
  role_assignments                          = var.role_assignments
}

resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  parent_id = var.parent_id
  type      = each.value.type
  name      = each.value.name
  body      = each.value.body
}
