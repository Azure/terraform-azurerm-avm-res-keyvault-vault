resource "azapi_resource" "secret" {
  type      = "Microsoft.KeyVault/vaults/secrets@2023-07-01"
  name      = var.name
  parent_id = var.key_vault_resource_id
  body = {
    properties = {
      attributes = {
        enabled = true
        exp     = var.expiration_date
        nbf     = var.not_before_date
      }
      contentType = var.content_type
      value       = var.value
    }
  }
  tags = var.tags
}

moved {
  from = azurerm_key_vault_secret.this
  to   = azapi_resource.secret
}

module "interfaces" {
  source                           = "Azure/avm-utl-interfaces/azure"
  version                          = "0.1.0"
  role_assignment_definition_scope = local.subscription_resource_id
  role_assignments                 = var.role_assignments
}

resource "azapi_resource" "role_assignments" {
  for_each  = module.interfaces.role_assignments_azapi
  type      = each.value.type
  name      = each.value.name
  parent_id = azapi_resource.secret.id
  body      = each.value.body
}
