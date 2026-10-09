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
  # The private endpoints accept a resource group name, defaulting to the vault's own resource group.
  resource_group_name = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id).name
}

# Private endpoint application security group associations
locals {
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
}
