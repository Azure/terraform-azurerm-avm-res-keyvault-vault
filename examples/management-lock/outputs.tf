output "resource_id" {
  description = "The resource ID of the Key Vault."
  value       = module.test.resource_id
}

output "name" {
  description = "The name of the Key Vault."
  value       = module.test.name
}

output "uri" {
  description = "The URI of the Key Vault."
  value       = module.test.uri
}