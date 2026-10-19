module "keys" {
  source   = "./modules/key"
  for_each = var.keys

  key_vault_resource_id = azapi_resource.this.id
  location              = var.location
  name                  = each.value.name
  type                  = each.value.key_type
  curve                 = each.value.curve
  enable_telemetry      = var.enable_telemetry
  expiration_date       = each.value.expiration_date
  not_before_date       = each.value.not_before_date
  opts                  = each.value.key_opts
  release_policy        = each.value.release_policy
  role_assignments      = each.value.role_assignments
  rotation_policy       = each.value.rotation_policy
  size                  = each.value.key_size
  tags                  = each.value.tags

  # Keys are created through the private endpoints once their DNS records exist.
  depends_on = [
    azapi_resource.private_dns_zone_groups,
    azapi_resource.private_endpoints,
    azapi_resource.private_endpoints_unmanaged_dns_zone_groups,
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
    azapi_resource.role_assignments
  ]
}
