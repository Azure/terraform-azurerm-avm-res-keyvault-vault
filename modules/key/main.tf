resource "azapi_resource" "this" {
  type      = "Microsoft.KeyVault/vaults/keys@2023-07-01"
  name      = var.name
  parent_id = var.key_vault_resource_id
  tags      = var.tags

  body = {
    properties = {
      kty    = var.type
      keyOps = var.opts
      attributes = {
        enabled = true
        nbf     = var.not_before_date != null ? formatdate("YYYY-MM-DD", var.not_before_date) : null
        exp     = var.expiration_date != null ? formatdate("YYYY-MM-DD", var.expiration_date) : null
      }
      rotationPolicy = var.rotation_policy != null ? {
        lifetimeActions = [{
          action = { type = "rotate" }
          trigger = {
            timeAfterCreate  = var.rotation_policy.automatic != null ? var.rotation_policy.automatic.time_after_creation : null
            timeBeforeExpiry = var.rotation_policy.automatic != null ? var.rotation_policy.automatic.time_before_expiry : null
          }
        }]
        attributes = {
          expiryTime = var.rotation_policy.expire_after
        }
      } : null
    }
  }
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = "${azapi_resource.this.id}/versions"
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
