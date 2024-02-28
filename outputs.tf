output "resource" {
  value       = azurerm_key_vault.this
  description = "The Key Vault resource."

  depends_on = [
    azurerm_key_vault_key.this,
    azurerm_key_vault_secret.this
  ]
}

output "resource_keys" {
  value       = azurerm_key_vault_key.this
  description = "A map of key objects. The map key is the supplied input to var.keys. The map value is the entire azurerm_key_vault_key resource."
}

output "resource_secrets" {
  value       = azurerm_key_vault_secret.this
  description = "A map of secret objects. The map key is the supplied input to var.secrets. The map value is the entire azurerm_key_vault_secret resource."
}

output "private_endpoints" {
  value       = azurerm_private_endpoint.this
  description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
}
