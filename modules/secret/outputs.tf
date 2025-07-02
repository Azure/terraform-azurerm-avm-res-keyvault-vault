output "id" {
  description = "The Key Vault Secret ID (URI)"
  value       = azapi_resource.this.output.properties.secretUriWithVersion
}

output "resource_id" {
  description = "The Azure resource id of the secret."
  value       = azapi_resource.this.id
}

output "versionless_id" {
  description = "The Base ID (URI) of the Key Vault Secret"
  value       = azapi_resource.this.output.properties.secretUri
}
