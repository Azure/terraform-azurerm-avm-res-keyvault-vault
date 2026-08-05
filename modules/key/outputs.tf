output "e" {
  description = "The RSA public exponent of the Key Vault Key. Use together with `n`, which carries the modulus. Empty for EC keys."
  value       = azurerm_key_vault_key.this.e
}

output "id" {
  description = "The Key Vault Key ID"
  value       = azurerm_key_vault_key.this.id
}

output "n" {
  description = "The RSA modulus of the Key Vault Key. Use together with `e`, which carries the public exponent. Empty for EC keys."
  value       = azurerm_key_vault_key.this.n
}

output "name" {
  description = "The name of the Key Vault Key."
  value       = azurerm_key_vault_key.this.name
}

output "public_key_openssh" {
  description = "The OpenSSH encoded public key of the Key Vault Key. Empty for `P-256K` keys, which the provider does not derive a public key for."
  value       = azurerm_key_vault_key.this.public_key_openssh
}

output "public_key_pem" {
  description = "The PEM encoded public key of the Key Vault Key. Empty for `P-256K` keys, which the provider does not derive a public key for."
  value       = azurerm_key_vault_key.this.public_key_pem
}

output "resource_id" {
  description = "The Azure resource id of the key."
  value       = azurerm_key_vault_key.this.resource_id
}

output "resource_versionless_id" {
  description = "The versionless Azure resource id of the key."
  value       = azurerm_key_vault_key.this.resource_versionless_id
}

output "versionless_id" {
  description = "The Base ID of the Key Vault Key"
  value       = azurerm_key_vault_key.this.versionless_id
}

output "x" {
  description = "The EC X component of the Key Vault Key. Use together with `y`, which carries the Y component. Empty for RSA keys."
  value       = azurerm_key_vault_key.this.x
}

output "y" {
  description = "The EC Y component of the Key Vault Key. Use together with `x`, which carries the X component. Empty for RSA keys."
  value       = azurerm_key_vault_key.this.y
}
