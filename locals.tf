locals {
  # Azure reports a diagnostic setting with every category and category group it offers, so the
  # module sends the full set with explicit enabled flags rather than only the selected entries.
  diagnostic_categories = try(data.azapi_resource_list.diagnostic_categories[0].output.categories, [])
  available_log_categories = sort([
    for category in local.diagnostic_categories : category.name if category.category_type == "Logs"
  ])
  available_log_category_groups = sort(distinct(flatten([
    for category in local.diagnostic_categories : coalesce(category.groups, []) if category.category_type == "Logs"
  ])))
  available_metric_categories = sort([
    for category in local.diagnostic_categories : category.name if category.category_type == "Metrics"
  ])
  # Access policies are only managed when the legacy path is enabled. Under RBAC authorization Azure
  # ignores them, and the module leaves whatever is on the vault in place.
  legacy_access_policies = var.legacy_access_policies_enabled ? var.legacy_access_policies : {}
  # The access policy placeholder in the body is ignored unless the module manages the policies, so a
  # PUT re-reads and resends the live values rather than clearing them.
  keyvault_vaults_ignore_body_changes = distinct(concat(
    var.legacy_access_policies_enabled ? [] : ["properties.accessPolicies"],
    var.ignore_body_changes.keyvault_vaults,
  ))
  # Role names are matched case-insensitively, as the AzureRM provider matched them.
  role_definition_ids_by_name = length(var.role_assignments) > 0 ? {
    for definition in data.azapi_resource_list.role_definitions[0].output.results : lower(definition.role_name) => definition.id...
  } : {}
  role_definition_resource_substring = "/providers/microsoft.authorization/roledefinitions/"
  role_assignments = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      # The AzureRM provider sent this principal type when the flag was set, which skips the Entra ID
      # existence check that fails for newly created service principals.
      principal_type = assignment.principal_type == null && assignment.skip_service_principal_aad_check ? "ServicePrincipal" : assignment.principal_type
      # Names resolve to IDs. Tenant-level IDs are qualified with the subscription, which is the form
      # Azure returns, so that the configuration and the deployed assignment compare equal.
      role_definition_id_or_name = (
        !strcontains(lower(assignment.role_definition_id_or_name), local.role_definition_resource_substring) ? try(local.role_definition_ids_by_name[lower(assignment.role_definition_id_or_name)][0], assignment.role_definition_id_or_name) :
        startswith(lower(assignment.role_definition_id_or_name), "/providers/") ? "/subscriptions/${local.subscription_id}${assignment.role_definition_id_or_name}" :
        assignment.role_definition_id_or_name
      )
    })
  }
  subscription_id = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id).subscription_id
}

locals {
  # Every private endpoint, whichever of the two resources in main.private_endpoint.tf manages it.
  private_endpoint_resources = merge(azapi_resource.private_endpoints, azapi_resource.private_endpoints_unmanaged_dns_zone_groups)
  # The configuration of each private endpoint. It reproduces what the AzureRM provider sent, so that
  # upgrading moves the existing private endpoints without changing them.
  private_endpoints = {
    for key, endpoint in var.private_endpoints : key => {
      body = {
        properties = merge(
          {
            # Empty lists are sent rather than omitted, so that removing the last application security
            # group or IP configuration removes it from Azure.
            applicationSecurityGroups = [
              for asg_resource_id in values(endpoint.application_security_group_associations) : { id = asg_resource_id }
            ]
            ipConfigurations = [
              for ip_configuration in values(endpoint.ip_configurations) : {
                name = ip_configuration.name
                properties = {
                  groupId          = coalesce(endpoint.subresource_name, "vault")
                  memberName       = coalesce(ip_configuration.member_name, "default")
                  privateIPAddress = ip_configuration.private_ip_address
                }
              }
            ]
            privateLinkServiceConnections = [
              {
                name = coalesce(endpoint.private_service_connection_name, "pse-${var.name}")
                properties = {
                  groupIds             = [coalesce(endpoint.subresource_name, "vault")]
                  privateLinkServiceId = azapi_resource.this.id
                }
              }
            ]
            subnet = {
              id = endpoint.subnet_resource_id
            }
          },
          # Azure stores an unset custom network interface name as an empty string, so the property is
          # sent only when it is set. Sending null would report a difference on every plan.
          endpoint.network_interface_name == null ? {} : { customNetworkInterfaceName = endpoint.network_interface_name },
        )
      }
      location = coalesce(endpoint.location, var.location)
      name     = coalesce(endpoint.name, "pe-${var.name}")
      # `resource_group_name` is a resource group in the key vault's subscription, as it was with the
      # AzureRM provider.
      parent_id = endpoint.resource_group_name == null ? var.parent_id : "/subscriptions/${local.subscription_id}/resourceGroups/${endpoint.resource_group_name}"
    }
  }
}
