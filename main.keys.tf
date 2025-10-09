module "keys" {
  source   = "./modules/key"
  for_each = var.keys

  key_vault_resource_id = azurerm_key_vault.this.id
  name                  = each.value.name
  type                  = each.value.key_type
  curve                 = each.value.curve
  expiration_date       = each.value.expiration_date
  not_before_date       = each.value.not_before_date
  opts                  = each.value.key_opts
  role_assignments      = each.value.role_assignments
  rotation_policy       = each.value.rotation_policy
  size                  = each.value.key_size
  tags                  = each.value.tags

  depends_on = [
    azurerm_private_endpoint.this,
    azurerm_private_endpoint.this_unmanaged_dns_zone_groups,
    time_sleep.wait_for_rbac_before_key_operations
  ]
}

resource "time_sleep" "wait_for_rbac_before_key_operations" {
  count = length(var.role_assignments) != 0 && length(var.keys) != 0 ? 1 : 0

  create_duration  = var.wait_for_rbac_before_key_operations.create
  destroy_duration = var.wait_for_rbac_before_key_operations.destroy
  triggers = {
    role_assignments = jsonencode(var.role_assignments)
  }

  depends_on = [
    azurerm_role_assignment.this
  ]
}
