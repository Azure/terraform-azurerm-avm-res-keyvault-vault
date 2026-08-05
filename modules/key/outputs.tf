output "id" {
  description = <<DESCRIPTION
The versioned data plane URI of the key, in the form
`https://<vault-name>.vault.azure.net/keys/<key-name>/<key-version>`.

This is the value most Azure services expect when configuring a customer managed key,
for example the `transparent_data_encryption_key_vault_key_id` input of the
`Azure/avm-res-sql-server/azurerm` module. It pins a specific key version. Note that
supporting key rotation does not imply accepting a versionless URI — Azure SQL, for
example, requires this versioned form and is told to follow rotation by a separate
setting. Use `versionless_id` only where the consuming API documents that it accepts a
versionless URI.
DESCRIPTION
  value       = azurerm_key_vault_key.this.id
}

output "name" {
  description = "The name of the Key Vault Key."
  value       = azurerm_key_vault_key.this.name
}

output "resource_id" {
  description = <<DESCRIPTION
The versioned Azure Resource Manager (ARM) resource ID of the key, in the form
`/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/keys/<key-name>/versions/<key-version>`.

This is an ARM resource ID, not a data plane URI. Use `id` when a service asks for a
key vault key URI or identifier such as `https://<vault-name>.vault.azure.net/keys/...`.
DESCRIPTION
  value       = azurerm_key_vault_key.this.resource_id
}

output "resource_versionless_id" {
  description = <<DESCRIPTION
The versionless Azure Resource Manager (ARM) resource ID of the key, in the form
`/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/keys/<key-name>`.

This is an ARM resource ID, not a data plane URI. Because it does not pin a key version,
services that support it will pick up new key versions automatically.
DESCRIPTION
  value       = azurerm_key_vault_key.this.resource_versionless_id
}

output "versionless_id" {
  description = <<DESCRIPTION
The versionless data plane URI of the key, in the form
`https://<vault-name>.vault.azure.net/keys/<key-name>`.

Because it does not pin a key version, services that support it will pick up new key
versions automatically. Use `id` when a service requires a specific key version.
DESCRIPTION
  value       = azurerm_key_vault_key.this.versionless_id
}
