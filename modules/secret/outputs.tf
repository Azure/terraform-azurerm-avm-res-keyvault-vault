output "id" {
  description = "The Key Vault Secret ID"
  value       = azapi_resource.this.output.properties.secretUri
}

output "resource_id" {
  description = "The Azure resource id of the secret."
  value       = azapi_resource.this.id
}

output "resource_versionless_id" {
  description = "The versionless Azure resource id of the secret."
  value       = azapi_resource.this.output.properties.secretUri
}

output "versionless_id" {
  description = "The Base ID of the Key Vault Secret"
  value       = azapi_resource.this.output.properties.secretUriWithVersion
}
