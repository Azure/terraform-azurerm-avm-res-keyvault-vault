output "id" {
  description = "The Key Vault Secret ID"
  value       = azapi_resource.secret.id
}

output "resource_id" {
  description = "The Azure resource id of the secret."
  value = "${azapi_resource.secret.output.id}/${
    replace(
      jsondecode(azapi_resource.secret.output).properties.secretUriWithVersion, 
      "/(.+)$","$1"
    )
  }" 
}

output "resource_versionless_id" {
 description = "The versionless Azure resource id of the secret."
 value       = azapi_resource.secret.output.properties.id
}

output "versionless_id" {
  description = "The Base ID of the Key Vault Secret"
  value       = azapi_resource.secret.output.properties.secretUri
}
