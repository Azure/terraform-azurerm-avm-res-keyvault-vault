output "id" {
  description = "The Key Vault Key ID"
  value       = azapi_resource.key.id
}

output "resource_id" {
  description = "The Azure resource id of the secret."
  value       = azapi_resource.key.resource_id
}

output "resource_versionless_id" {
  description = "The versionless Azure resource id of the secret."
  value       = azapi_resource.key.resource_versionless_id
}

output "versionless_id" {
  description = "The Base ID of the Key Vault Key"
  value       = azapi_resource.key.versionless_id
}
