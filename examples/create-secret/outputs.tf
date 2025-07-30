output "secrets" {
  value = module.key_vault.secrets
}

output "secrets_resource_ids" {
  description = "Demonstrates the new name field in secrets output"
  value = module.key_vault.secrets_resource_ids
}
