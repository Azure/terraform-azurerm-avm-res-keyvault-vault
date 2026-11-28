locals {
  key_vault = provider::azapi::parse_resource_id("Microsoft.KeyVault/vaults", var.key_vault_resource_id)
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
        startswith(lower(assignment.role_definition_id_or_name), "/providers/") ? "/subscriptions/${local.key_vault.subscription_id}${assignment.role_definition_id_or_name}" :
        assignment.role_definition_id_or_name
      )
    })
  }
}
