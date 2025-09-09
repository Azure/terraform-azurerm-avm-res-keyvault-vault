# The PE resource when we are managing the private_dns_zone_group block:
resource "azapi_resource" "private_endpoint" {
  for_each = { for k, v in var.private_endpoints : k => v if var.private_endpoints_manage_dns_zone_group }

  type      = "Microsoft.Network/privateEndpoints@2023-05-01"
  name      = each.value.name != null ? each.value.name : "pe-${var.name}"
  location  = each.value.location != null ? each.value.location : var.location
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name}"
  tags      = each.value.tags

  body = {
    properties = {
      subnet = {
        id = each.value.subnet_resource_id
      }
      customNetworkInterfaceName = each.value.network_interface_name
      privateLinkServiceConnections = [
        {
          name = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
          properties = {
            privateLinkServiceId = azapi_resource.this.id
            groupIds            = ["vault"]
          }
        }
      ]
      ipConfigurations = length(each.value.ip_configurations) > 0 ? [
        for ip_config in each.value.ip_configurations : {
          name = ip_config.name
          properties = {
            privateIPAddress = ip_config.private_ip_address
            memberName      = "default"
            groupId         = "vault"
          }
        }
      ] : []
    }
  }

  depends_on = [azapi_resource.this]
}

# Create private DNS zone group as a separate resource if needed
resource "azapi_resource" "private_dns_zone_group" {
  for_each = { for k, v in var.private_endpoints : k => v if var.private_endpoints_manage_dns_zone_group && length(v.private_dns_zone_resource_ids) > 0 }

  type      = "Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01"
  name      = each.value.private_dns_zone_group_name
  parent_id = azapi_resource.private_endpoint[each.key].id

  body = {
    properties = {
      privateDnsZoneConfigs = [
        for idx, dns_zone_id in each.value.private_dns_zone_resource_ids : {
          name = "config-${idx}"
          properties = {
            privateDnsZoneId = dns_zone_id
          }
        }
      ]
    }
  }

  depends_on = [azapi_resource.private_endpoint]
}

# The PE resource when we are **not** managing the private_dns_zone_group block, such as when using Azure Policy:
resource "azapi_resource" "private_endpoint_unmanaged_dns" {
  for_each = { for k, v in var.private_endpoints : k => v if !var.private_endpoints_manage_dns_zone_group }

  type      = "Microsoft.Network/privateEndpoints@2023-05-01"
  name      = each.value.name != null ? each.value.name : "pe-${var.name}"
  location  = each.value.location != null ? each.value.location : var.location
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name}"
  tags      = each.value.tags

  body = {
    properties = {
      subnet = {
        id = each.value.subnet_resource_id
      }
      customNetworkInterfaceName = each.value.network_interface_name
      privateLinkServiceConnections = [
        {
          name = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
          properties = {
            privateLinkServiceId = azapi_resource.this.id
            groupIds            = ["vault"]
          }
        }
      ]
      ipConfigurations = length(each.value.ip_configurations) > 0 ? [
        for ip_config in each.value.ip_configurations : {
          name = ip_config.name
          properties = {
            privateIPAddress = ip_config.private_ip_address
            memberName      = "default"
            groupId         = "vault"
          }
        }
      ] : []
    }
  }

  # Equivalent to lifecycle ignore_changes for private_dns_zone_group
  ignore_missing_property = true

  depends_on = [azapi_resource.this]
}

# Application Security Group associations for private endpoints
# Note: azapi doesn't have direct support for ASG associations like azurerm
# This uses azurerm for now as it's a management plane operation
resource "azurerm_private_endpoint_application_security_group_association" "this" {
  for_each = local.private_endpoint_application_security_group_associations

  application_security_group_id = each.value.asg_resource_id
  private_endpoint_id           = var.private_endpoints_manage_dns_zone_group ? azapi_resource.private_endpoint[each.value.pe_key].id : azapi_resource.private_endpoint_unmanaged_dns[each.value.pe_key].id
}
