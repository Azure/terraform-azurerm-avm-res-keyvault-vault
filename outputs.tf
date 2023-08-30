output "uri" {
  value       = azurerm_key_vault.this.vault_uri
  description = "The URI of the Key Vault, used for performing operations on keys and secrets."
}

output "id" {
  value       = azurerm_key_vault.this.id
  description = "The Azure resource id of the Key Vault."
}
