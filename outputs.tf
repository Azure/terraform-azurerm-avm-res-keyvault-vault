output "private_endpoints" {
  description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
  value       = azurerm_private_endpoint.this
}

output "resource_id" {
  description = "The Key Vault resource id."
  value       = azurerm_key_vault.this.id
}

output "keys_resource_ids" {
  description = "A map of key keys to resource ids."
  value       = { for kk, kv in azurerm_key_vault_key.this : kk => kv.id }
}

output "secrets_resource_ids" {
  description = "A map of secret keys to resource ids."
  value       = { for sk, sv in azurerm_key_vault_key.this : sk => sv.id }
}
