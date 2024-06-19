output "keys_resource_ids" {
  description = "A map of key keys to resource ids."
  value = { for kk, kv in module.keys : kk => {
    resource_id             = kv.resource_id
    resource_versionless_id = kv.resource_versionless_id
    id                      = kv.id
    versionless_id          = kv.versionless_id
    }
  }
}

output "private_endpoints" {
  description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
  value       = azurerm_private_endpoint.this
}

output "resource_id" {
  description = "The Azure resource id of the key vault."
  value       = azurerm_key_vault.this.id
}

output "secrets_resource_ids" {
  description = "A map of secret keys to resource ids."
  value = { for sk, sv in module.secrets : sk => {
    resource_id             = sv.resource_id
    resource_versionless_id = sv.resource_versionless_id
    id                      = sv.id
    versionless_id          = sv.versionless_id
    }
  }
}

output "uri" {
  description = "The URI of the vault for performing operations on keys and secrets"
  value       = azurerm_key_vault.this.vault_uri
}
