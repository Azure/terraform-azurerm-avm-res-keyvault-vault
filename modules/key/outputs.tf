output "resource_id" {
  description = "The Azure resource id of the secret."
  value       = azurerm_key_vault_key.this.resource_id
}

output "resource_versionless_id" {
  description = "The versionless Azure resource id of the secret."
  value       = azurerm_key_vault_key.this.resource_versionless_id
}
