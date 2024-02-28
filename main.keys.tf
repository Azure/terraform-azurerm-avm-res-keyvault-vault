resource "azurerm_key_vault_key" "this" {
  for_each        = var.keys
  name            = each.value.name
  key_vault_id    = azurerm_key_vault.this.id
  key_type        = each.value.key_type
  key_size        = each.value.key_size
  curve           = each.value.curve
  key_opts        = each.value.key_opts
  not_before_date = each.value.not_before_date
  expiration_date = each.value.expiration_date
  tags            = each.value.tags

  dynamic "rotation_policy" {
    for_each = each.value.rotation_policy != null ? { this = each.value.rotation_policy } : {}
    content {
      expire_after         = rotation_policy.value.expire_after
      notify_before_expiry = rotation_policy.value.notify_before_expiry

      dynamic "automatic" {
        for_each = rotation_policy.value.automatic != null ? { this = rotation_policy.value.automatic } : {}
        content {
          time_after_creation = automatic.value.time_after_creation
          time_before_expiry  = automatic.value.time_before_expiry
        }
      }
    }
  }

  depends_on = [
    time_sleep.wait_for_rbac_before_key_operations,
  ]
}

resource "azurerm_role_assignment" "keys" {
  for_each                               = local.keys_role_assignments
  scope                                  = azurerm_key_vault_key.this[each.value.key_key].resource_versionless_id
  role_definition_id                     = strcontains(lower(each.value.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_assignment.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_assignment.role_definition_id_or_name
  principal_id                           = each.value.role_assignment.principal_id
  condition                              = each.value.role_assignment.condition
  condition_version                      = each.value.role_assignment.condition_version
  skip_service_principal_aad_check       = each.value.role_assignment.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.role_assignment.delegated_managed_identity_resource_id
}

resource "time_sleep" "wait_for_rbac_before_key_operations" {
  count = var.role_assignments != {} && var.keys != {} ? 1 : 0
  depends_on = [
    azurerm_role_assignment.this
  ]
  create_duration  = var.wait_for_rbac_before_key_operations.create
  destroy_duration = var.wait_for_rbac_before_key_operations.destroy

  triggers = {
    role_assignments = jsonencode(var.role_assignments)
  }
}
