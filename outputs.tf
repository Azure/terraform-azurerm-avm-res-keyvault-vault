output "keys_resource_ids" {
  description = "A map of key keys to resource ids."
  value = { for kk, kv in module.keys : kk => {
    resource_id             = kv.resource_id
    resource_versionless_id = kv.resource_versionless_id

    }
  }
}

output "private_endpoints" {
  description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
  value       = azurerm_private_endpoint.this
}

output "secrets_resource_ids" {
  description = "A map of secret keys to resource ids."
  value = { for sk, sv in module.secrets : sk => {
    resource_id             = sv.resource_id
    resource_versionless_id = sv.resource_versionless_id
    }
  }
}
