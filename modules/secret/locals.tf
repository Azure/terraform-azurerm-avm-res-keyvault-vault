# TODO: insert locals here.
locals {
  resource_id_segments = split("/", var.key_vault_resource_id)
  subscription_resource_id = "/${local.resource_id_segments[1]}/${local.resource_id_segments[2]}"
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
