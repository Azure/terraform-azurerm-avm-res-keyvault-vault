# The private endpoints are split across two resources because each one is the destination of a `moved`
# block from its AzureRM counterpart, and Terraform allows only one source per destination. The two are
# configured identically: the private DNS zone group is a separate child resource in AzAPI, so the
# private endpoint itself no longer differs between the modes.

# The private endpoints when the module manages their private DNS zone groups.
resource "azapi_resource" "private_endpoints" {
  for_each = { for key, endpoint in local.private_endpoints : key => endpoint if var.private_endpoints_manage_dns_zone_group }

  location               = each.value.location
  name                   = each.value.name
  parent_id              = each.value.parent_id
  type                   = var.resource_types.network_private_endpoints
  body                   = each.value.body
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  response_export_values = ["properties.customDnsConfigs", "properties.networkInterfaces"]
  retry                  = var.retry
  # Each private endpoint takes its own tags, as the standard private endpoint interface defines.
  # TFFR9 requires a consumer-settable tags expression, and the rule accepts any from ruleset v1.1.0;
  # the v1.0.0 ruleset that Avm.Authoring pins still requires `var.tags` exactly.
  # tflint-ignore: avm_azapi_resource_tags_required
  tags = var.private_endpoints[each.key].tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

moved {
  from = azurerm_private_endpoint.this
  to   = azapi_resource.private_endpoints
}

# The private endpoints when their private DNS zone groups are managed elsewhere, for example by Azure
# Policy.
resource "azapi_resource" "private_endpoints_unmanaged_dns_zone_groups" {
  for_each = { for key, endpoint in local.private_endpoints : key => endpoint if !var.private_endpoints_manage_dns_zone_group }

  location               = each.value.location
  name                   = each.value.name
  parent_id              = each.value.parent_id
  type                   = var.resource_types.network_private_endpoints
  body                   = each.value.body
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  response_export_values = ["properties.customDnsConfigs", "properties.networkInterfaces"]
  retry                  = var.retry
  # See the matching comment on azapi_resource.private_endpoints.
  # tflint-ignore: avm_azapi_resource_tags_required
  tags = var.private_endpoints[each.key].tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

moved {
  from = azurerm_private_endpoint.this_unmanaged_dns_zone_groups
  to   = azapi_resource.private_endpoints_unmanaged_dns_zone_groups
}

# Application security groups are part of the private endpoint's body from this version. The
# association resources the AzureRM provider used are dropped from the state without being deleted, so
# the private endpoints keep their application security groups.
removed {
  from = azurerm_private_endpoint_application_security_group_association.this

  lifecycle {
    destroy = false
  }
}

resource "azapi_resource" "private_dns_zone_groups" {
  for_each = { for key, endpoint in var.private_endpoints : key => endpoint if var.private_endpoints_manage_dns_zone_group && length(endpoint.private_dns_zone_resource_ids) > 0 }

  name      = each.value.private_dns_zone_group_name
  parent_id = azapi_resource.private_endpoints[each.key].id
  type      = var.resource_types.network_private_endpoints_private_dns_zone_groups
  body = {
    properties = {
      # Each configuration is named after its zone, as the AzureRM provider named them.
      privateDnsZoneConfigs = [
        for private_dns_zone_resource_id in each.value.private_dns_zone_resource_ids : {
          name = provider::azapi::parse_resource_id("Microsoft.Network/privateDnsZones", private_dns_zone_resource_id).name
          properties = {
            privateDnsZoneId = private_dns_zone_resource_id
          }
        }
      ]
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups) > 0 ? var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

# The AzureRM provider read each private endpoint's private IP address from its network interface. The
# private endpoint reports the address itself only when it is not linked to a private DNS zone, so the
# network interface is read here as well.
data "azapi_resource" "private_endpoint_network_interfaces" {
  for_each = local.private_endpoint_resources

  resource_id = each.value.output.properties.networkInterfaces[0].id
  type        = "Microsoft.Network/networkInterfaces@2025-05-01"
  response_export_values = {
    private_ip_address = "properties.ipConfigurations[0].properties.privateIPAddress"
  }
}

# The locks for the private endpoints when the module manages their private DNS zone groups.
resource "azapi_resource" "private_endpoint_locks" {
  for_each = { for key, endpoint in var.private_endpoints : key => endpoint if endpoint.lock != null && var.private_endpoints_manage_dns_zone_group }

  name      = coalesce(each.value.lock.name, "lock-${azapi_resource.private_endpoints[each.key].name}")
  parent_id = azapi_resource.private_endpoints[each.key].id
  type      = var.resource_types.authorization_locks
  body = {
    # Notes are sent only when they are set, which is how the AzureRM provider left the locks it created.
    properties = merge(
      { level = each.value.lock.kind },
      each.value.lock.notes == null ? {} : { notes = each.value.lock.notes },
    )
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  # Create the locks last and remove them first. A ReadOnly lock blocks changes to the private endpoint
  # and its DNS zone group.
  depends_on = [time_sleep.private_endpoint_lock_removal]
}

moved {
  from = azurerm_management_lock.private_endpoints
  to   = azapi_resource.private_endpoint_locks
}

# The locks for the private endpoints when their private DNS zone groups are managed elsewhere.
resource "azapi_resource" "private_endpoint_locks_unmanaged_dns_zone_groups" {
  for_each = { for key, endpoint in var.private_endpoints : key => endpoint if endpoint.lock != null && !var.private_endpoints_manage_dns_zone_group }

  name      = coalesce(each.value.lock.name, "lock-${azapi_resource.private_endpoints_unmanaged_dns_zone_groups[each.key].name}")
  parent_id = azapi_resource.private_endpoints_unmanaged_dns_zone_groups[each.key].id
  type      = var.resource_types.authorization_locks
  body = {
    properties = merge(
      { level = each.value.lock.kind },
      each.value.lock.notes == null ? {} : { notes = each.value.lock.notes },
    )
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [time_sleep.private_endpoint_lock_removal]
}

moved {
  from = azurerm_management_lock.private_endpoints_unmanaged_dns_zone_groups
  to   = azapi_resource.private_endpoint_locks_unmanaged_dns_zone_groups
}

# Azure keeps enforcing a deleted lock for a few seconds, and the AzureRM provider waited for each lock
# to be gone before it continued. This pause does the same: it is destroyed after the locks and before
# the private endpoints and their DNS zone groups, so they are not deleted while a lock still applies.
resource "time_sleep" "private_endpoint_lock_removal" {
  count = anytrue([for endpoint in var.private_endpoints : endpoint.lock != null]) ? 1 : 0

  destroy_duration = "30s"

  depends_on = [
    azapi_resource.private_dns_zone_groups,
    azapi_resource.private_endpoints,
    azapi_resource.private_endpoints_unmanaged_dns_zone_groups,
  ]
}
