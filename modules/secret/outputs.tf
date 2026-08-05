output "id" {
  description = <<DESCRIPTION
The versioned data plane URI of the secret, in the form
`https://<vault-name>.vault.azure.net/secrets/<secret-name>/<secret-version>`.

Because it pins a specific secret version, consumers will not pick up new versions
automatically; use `versionless_id` instead if that is required.
DESCRIPTION
  value       = azurerm_key_vault_secret.this.id
}

output "name" {
  description = "The name of the Key Vault Secret."
  value       = azurerm_key_vault_secret.this.name
}

output "resource_id" {
  description = <<DESCRIPTION
The versioned Azure Resource Manager (ARM) resource ID of the secret, in the form
`/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/secrets/<secret-name>/versions/<secret-version>`.

This is an ARM resource ID, not a data plane URI. Use `id` when a service asks for a
key vault secret URI such as `https://<vault-name>.vault.azure.net/secrets/...`.
DESCRIPTION
  value       = azurerm_key_vault_secret.this.resource_id
}

output "resource_versionless_id" {
  description = <<DESCRIPTION
The versionless Azure Resource Manager (ARM) resource ID of the secret, in the form
`/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/secrets/<secret-name>`.

This is an ARM resource ID, not a data plane URI. Because it does not pin a secret
version, consumers that support it will pick up new secret versions automatically.
DESCRIPTION
  value       = azurerm_key_vault_secret.this.resource_versionless_id
}

output "versionless_id" {
  description = <<DESCRIPTION
The versionless data plane URI of the secret, in the form
`https://<vault-name>.vault.azure.net/secrets/<secret-name>`.

Because it does not pin a secret version, consumers that support it will pick up new
secret versions automatically. Use `id` when a specific version is required.
DESCRIPTION
  value       = azurerm_key_vault_secret.this.versionless_id
}
