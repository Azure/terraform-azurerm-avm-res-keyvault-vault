output "keys" {
  description = <<DESCRIPTION
A map of key keys to key values. The map key is the key of the `var.keys` map entry (not
the name of the key itself). The key value is the entire azurerm_key_vault_key resource.

The key value contains the following attributes:
- id: The versioned data plane URI of the key, in the form `https://<vault-name>.vault.azure.net/keys/<key-name>/<key-version>`. This is the value most Azure services expect for a customer managed key.
- versionless_id: The versionless data plane URI of the key, in the form `https://<vault-name>.vault.azure.net/keys/<key-name>`. Use this where the consuming service supports automatic key rotation.
- resource_id: The versioned ARM resource ID of the key, in the form `/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/keys/<key-name>/versions/<key-version>`.
- resource_versionless_id: The versionless ARM resource ID of the key, in the form `/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/keys/<key-name>`.

For example, to pass a key to a service that expects a key vault key URI:
`module.key_vault.keys["<var.keys map key>"].id`
DESCRIPTION
  value       = module.keys
}

output "keys_resource_ids" {
  description = <<DESCRIPTION
A map of key keys to resource ids. The map key is the key of the `var.keys` map entry
(not the name of the key itself). See the `keys` output for the exact shape of each
attribute: `id` and `versionless_id` are data plane URIs, `resource_id` and
`resource_versionless_id` are ARM resource IDs.
DESCRIPTION
  value = { for kk, kv in module.keys : kk => {
    resource_id             = kv.resource_id
    resource_versionless_id = kv.resource_versionless_id
    id                      = kv.id
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
A map of secret keys to secret values. The map key is the key of the `var.secrets` map
entry (not the name of the secret itself). The secret value is the entire
azurerm_key_vault_secret resource.

The secret value contains the following attributes:
- id: The versioned data plane URI of the secret, in the form `https://<vault-name>.vault.azure.net/secrets/<secret-name>/<secret-version>`.
- versionless_id: The versionless data plane URI of the secret, in the form `https://<vault-name>.vault.azure.net/secrets/<secret-name>`.
- resource_id: The versioned ARM resource ID of the secret, in the form `/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/secrets/<secret-name>/versions/<secret-version>`.
- resource_versionless_id: The versionless ARM resource ID of the secret, in the form `/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/secrets/<secret-name>`.
DESCRIPTION
  value       = module.secrets
}

output "secrets_resource_ids" {
  description = <<DESCRIPTION
A map of secret keys to resource ids. The map key is the key of the `var.secrets` map
entry (not the name of the secret itself). See the `secrets` output for the exact shape
of each attribute: `id` and `versionless_id` are data plane URIs, `resource_id` and
`resource_versionless_id` are ARM resource IDs.
DESCRIPTION
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
