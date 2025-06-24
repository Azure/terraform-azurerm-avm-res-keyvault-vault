output "id" {
  description = "The Key Vault Secret ID"
  value       = azapi_resource.this.output.properties.secretUriWithVersion
}

output "resource_id" {
  description = "The Azure resource id of the secret."
  value       = "${azapi_resource.this.id}/${basename(azapi_resource.this.output.properties.secretUriWithVersion)}"
}

output "resource_versionless_id" {
  description = "The versionless Azure resource id of the secret."
  value       = azapi_resource.this.id
}

output "versionless_id" {
  description = "The Base ID of the Key Vault Secret"
  value       = azapi_resource.this.output.properties.secretUri
}
