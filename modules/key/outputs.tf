output "id" {
  description = "The Key Vault Key ID"
  value       = azapi_resource.this.id
}

output "resource_id" {
  description = "The Azure resource id of the secret."
  value       = azapi_resource.this.id
}

output "resource_versionless_id" {
  description = "The versionless Azure resource id of the secret."
  value       = azapi_resource.this.id
}

output "versionless_id" {
  description = "The versionless ID of the Key Vault key."
  value       = azapi_resource.this.output.properties.keyUri
}
