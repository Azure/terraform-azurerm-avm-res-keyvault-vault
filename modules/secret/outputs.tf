output "id" {
  description = "The Key Vault Secret ID"
  value       = azurerm_key_vault_secret.this.id
}

output "resource_id" {
  description = "The Azure resource id of the secret."
  value       = azurerm_key_vault_secret.this.resource_id
}

output "resource_versionless_id" {
  description = "The versionless Azure resource id of the secret."
  value       = azurerm_key_vault_secret.this.resource_versionless_id
}

output "versionless_id" {
  description = "The Base ID of the Key Vault Secret"
  value       = azurerm_key_vault_secret.this.versionless_id
}
