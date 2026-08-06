output "key_resource_id" {
  description = <<DESCRIPTION
The versioned ARM resource ID of the key, in the form
`/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/keys/<key-name>/versions/<key-version>`.

This is an ARM resource ID, not a data plane URI. Use `key_uri` when a service asks for a
key vault key URI.
DESCRIPTION
  value       = module.key_vault.keys["cmk_for_storage_account"].resource_id
}

output "key_uri" {
  description = <<DESCRIPTION
The versioned data plane URI of the key, in the form
`https://<vault-name>.vault.azure.net/keys/<key-name>/<key-version>`.

This is the value to pass to services that expect a customer managed key URI, such as the
`transparent_data_encryption_key_vault_key_id` input of the
`Azure/avm-res-sql-server/azurerm` module.
DESCRIPTION
  value       = module.key_vault.keys["cmk_for_storage_account"].id
}

output "key_versionless_uri" {
  description = <<DESCRIPTION
The versionless data plane URI of the key, in the form
`https://<vault-name>.vault.azure.net/keys/<key-name>`.

Use this instead of `key_uri` only where the consuming API documents that it accepts a
versionless URI. Supporting key rotation does not imply this — Azure SQL supports
rotation but requires the versioned `key_uri`.
DESCRIPTION
  value       = module.key_vault.keys["cmk_for_storage_account"].versionless_id
}
