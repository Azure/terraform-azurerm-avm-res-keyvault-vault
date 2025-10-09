module "secrets" {
  source   = "./modules/secret"
  for_each = var.secrets

  key_vault_resource_id = azurerm_key_vault.this.id
  name                  = each.value.name
  value                 = var.secrets_value[each.key]
  content_type          = each.value.content_type
  expiration_date       = each.value.expiration_date
  not_before_date       = each.value.not_before_date
  role_assignments      = each.value.role_assignments
  tags                  = each.value.tags

  depends_on = [
    azurerm_private_endpoint.this,
    azurerm_private_endpoint.this_unmanaged_dns_zone_groups,
    time_sleep.wait_for_rbac_before_secret_operations
  ]
}

resource "time_sleep" "wait_for_rbac_before_secret_operations" {
  count = length(var.role_assignments) != 0 && length(var.secrets) != 0 ? 1 : 0

  create_duration  = var.wait_for_rbac_before_secret_operations.create
  destroy_duration = var.wait_for_rbac_before_secret_operations.destroy
  triggers = {
    role_assignments = jsonencode(var.role_assignments)
  }

  depends_on = [
    azurerm_role_assignment.this
  ]
}
