output "keys" {
  description = <<DESCRIPTION
A map of key keys to key values. The map key is the key of the `var.keys` map entry (not
the name of the key itself). The key value is not the entire azurerm_key_vault_key
resource, only the attributes listed below are exposed.

The key value contains the following attributes, grouped by purpose:

Identifiers:
- id: The versioned data plane URI of the key, in the form `https://<vault-name>.vault.azure.net/keys/<key-name>/<key-version>`. This is the value most Azure services expect for a customer managed key.
- name: The name of the key.
- versionless_id: The versionless data plane URI of the key, in the form `https://<vault-name>.vault.azure.net/keys/<key-name>`. Use only where the consuming API documents that it accepts a versionless URI; supporting rotation does not imply this.
- resource_id: The versioned ARM resource ID of the key, in the form `/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/keys/<key-name>/versions/<key-version>`.
- resource_versionless_id: The versionless ARM resource ID of the key, in the form `/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/keys/<key-name>`.

Encoded public key, for RSA and for EC curves other than `P-256K`:
- public_key_pem: The PEM encoded public key of the key.
- public_key_openssh: The OpenSSH encoded public key of the key.

Raw RSA public key components, empty for EC keys. These are a pair:
- n: The RSA modulus of the key.
- e: The RSA public exponent of the key.

Raw EC public key components, empty for RSA keys. These are a pair:
- x: The EC X component of the key.
- y: The EC Y component of the key.

Release policy:
- release_policy_configured: Whether the key has a release policy configured.

For example, to pass a key to a service that expects a key vault key URI:
`module.key_vault.keys["<var.keys map key>"].id`
DESCRIPTION
  value       = module.keys
}

output "keys_resource_ids" {
  description = <<DESCRIPTION
A map of key keys to resource ids and key names. The map key is the key of the `var.keys`
map entry (not the name of the key itself). See the `keys` output for the exact shape of
each attribute: `id` and `versionless_id` are data plane URIs, `resource_id` and
`resource_versionless_id` are ARM resource IDs.
DESCRIPTION
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
  value       = azapi_resource.this.name
}

output "private_endpoints" {
  description = <<DESCRIPTION
A map of private endpoints. The map key is the key of the `var.private_endpoints` map entry. The
attributes below keep the names and shapes the AzureRM provider used, so references such as
`private_service_connection[0].private_ip_address` continue to work:

- `id` - The resource ID of the private endpoint.
- `name` - The name of the private endpoint.
- `location` - The Azure location of the private endpoint.
- `subnet_id` - The resource ID of the subnet the private endpoint is in.
- `tags` - The tags of the private endpoint.
- `custom_dns_configs` - A list of objects with `fqdn` and `ip_addresses`. Azure reports these only
  for a private endpoint that is not linked to a private DNS zone.
- `network_interface` - A list with the private endpoint's network interface, as an object with `id`
  and `name`.
- `private_dns_zone_group` - A list with the private DNS zone group this module manages, as an object
  with `id`, `name` and `private_dns_zone_ids`. Empty when the module does not manage it.
- `private_service_connection` - A list with the private service connection, as an object with
  `name`, `is_manual_connection`, `private_connection_resource_id`, `subresource_names` and
  `private_ip_address`.
DESCRIPTION
  value = {
    for key, endpoint in local.private_endpoint_resources : key => {
      custom_dns_configs = [
        for config in try(endpoint.output.properties.customDnsConfigs, []) : {
          fqdn         = config.fqdn
          ip_addresses = config.ipAddresses
        }
      ]
      id       = endpoint.id
      location = endpoint.location
      name     = endpoint.name
      network_interface = [
        for nic in try(endpoint.output.properties.networkInterfaces, []) : {
          id   = nic.id
          name = provider::azapi::parse_resource_id("Microsoft.Network/networkInterfaces", nic.id).name
        }
      ]
      private_dns_zone_group = [
        for group in try([azapi_resource.private_dns_zone_groups[key]], []) : {
          id                   = group.id
          name                 = group.name
          private_dns_zone_ids = tolist(var.private_endpoints[key].private_dns_zone_resource_ids)
        }
      ]
      private_service_connection = [
        {
          is_manual_connection           = false
          name                           = local.private_endpoints[key].body.properties.privateLinkServiceConnections[0].name
          private_connection_resource_id = azapi_resource.this.id
          private_ip_address             = data.azapi_resource.private_endpoint_network_interfaces[key].output.private_ip_address
          subresource_names              = local.private_endpoints[key].body.properties.privateLinkServiceConnections[0].properties.groupIds
        }
      ]
      subnet_id = var.private_endpoints[key].subnet_resource_id
      tags      = endpoint.tags
    }
  }
}

output "resource_id" {
  description = "The Azure resource id of the key vault."
  value       = azapi_resource.this.id
}

output "secrets" {
  description = <<DESCRIPTION
A map of secret keys to secret values. The map key is the key of the `var.secrets` map
entry (not the name of the secret itself). The secret value is not the entire
azurerm_key_vault_secret resource, only the attributes listed below are exposed.

The secret value contains the following attributes:
- id: The versioned data plane URI of the secret, in the form `https://<vault-name>.vault.azure.net/secrets/<secret-name>/<secret-version>`.
- name: The name of the secret.
- versionless_id: The versionless data plane URI of the secret, in the form `https://<vault-name>.vault.azure.net/secrets/<secret-name>`.
- resource_id: The versioned ARM resource ID of the secret, in the form `/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/secrets/<secret-name>/versions/<secret-version>`.
- resource_versionless_id: The versionless ARM resource ID of the secret, in the form `/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/secrets/<secret-name>`.
DESCRIPTION
  value       = module.secrets
}

output "secrets_resource_ids" {
  description = <<DESCRIPTION
A map of secret keys to resource ids and secret names. The map key is the key of the
`var.secrets` map entry (not the name of the secret itself). See the `secrets` output for
the exact shape of each attribute: `id` and `versionless_id` are data plane URIs,
`resource_id` and `resource_versionless_id` are ARM resource IDs.
DESCRIPTION
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
  value       = azapi_resource.this.output.properties.vaultUri
}
