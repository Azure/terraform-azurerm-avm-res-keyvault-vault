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

  response_export_values = ["*"]
}

resource "azapi_resource" "role_assignment" {
  for_each = var.role_assignments

  type = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name = uuidv5("oid", "${each.value.principal_id}-${azapi_resource.this.id}/versions-${strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : data.azurerm_role_definition.this[each.key].id}")
  parent_id = "${azapi_resource.this.id}/versions"

  body = {
    properties = {
      principalId      = each.value.principal_id
      principalType    = each.value.principal_type
      roleDefinitionId = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : data.azurerm_role_definition.this[each.key].id
      condition        = each.value.condition
      conditionVersion = each.value.condition_version
      delegatedManagedIdentityResourceId = each.value.delegated_managed_identity_resource_id
    }
  }

  depends_on = [azapi_resource.this]
}

# Data source to get role definition ID when role definition name is provided
data "azurerm_role_definition" "this" {
  for_each = { for k, v in var.role_assignments : k => v if !strcontains(lower(v.role_definition_id_or_name), lower(local.role_definition_resource_substring)) }
  
  name  = each.value.role_definition_id_or_name
  scope = azapi_resource.this.id
}
