output "keys" {
  description = <<DESCRIPTION
A map of key keys to key values. The key value is not the entire azurerm_key_vault_key resource, only the attributes listed below are exposed.

The key value contains the following attributes:
- e: The RSA public exponent of the key. Empty for EC keys.
- id: The Key Vault Key ID
- n: The RSA modulus of the key. Empty for EC keys.
- name: The name of the key.
- public_key_openssh: The OpenSSH encoded public key of the key. Empty for `P-256K` keys.
- public_key_pem: The PEM encoded public key of the key. Empty for `P-256K` keys.
- resource_id: The Azure resource id of the key.
- resource_versionless_id: The versionless Azure resource id of the key.
- versionless_id: The Base ID of the Key Vault Key
- x: The EC X component of the key. Empty for RSA keys.
- y: The EC Y component of the key. Empty for RSA keys.
DESCRIPTION
  value       = module.keys
}

output "keys_resource_ids" {
  description = "A map of key keys to resource ids and key names."
  value = { for kk, kv in module.keys : kk => {
    id                      = kv.id
    name                    = kv.name
    resource_id             = kv.resource_id
    resource_versionless_id = kv.resource_versionless_id
    versionless_id          = kv.versionless_id
    }
  }
}

output "name" {
  description = "The name of the key vault."
  value       = azurerm_key_vault.this.name
}

output "private_endpoints" {
  description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}

output "resource_id" {
  description = "The Azure resource id of the key vault."
  value       = azurerm_key_vault.this.id
}

output "secrets" {
  description = <<DESCRIPTION
A map of secret keys to secret values. The secret value is not the entire azurerm_key_vault_secret resource, only the attributes listed below are exposed.

The secret value contains the following attributes:
- id: The Key Vault Secret ID
- name: The name of the secret.
- resource_id: The Azure resource id of the secret.
- resource_versionless_id: The versionless Azure resource id of the secret.
- versionless_id: The Base ID of the Key Vault Secret
DESCRIPTION
  value       = module.secrets
}

output "secrets_resource_ids" {
  description = "A map of secret keys to resource ids and secret names."
  value = { for sk, sv in module.secrets : sk => {
    id                      = sv.id
    name                    = sv.name
    resource_id             = sv.resource_id
    resource_versionless_id = sv.resource_versionless_id
    versionless_id          = sv.versionless_id
    }
  }
}

output "uri" {
  description = "The URI of the vault for performing operations on keys and secrets"
  value       = azurerm_key_vault.this.vault_uri
}
