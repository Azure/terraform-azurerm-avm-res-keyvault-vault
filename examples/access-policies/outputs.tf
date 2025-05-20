output "access_policies_resource" {
  description = "The full resource output for the Keyvault access policies map resource."
  sensitive   = true
  value       = module.keyvault.access_policies_resource
}

output "resource" {
  description = "The full resource output for the Keyvault resource."
  sensitive   = true
  value       = module.keyvault.resource
}
