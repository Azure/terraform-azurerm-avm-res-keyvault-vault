# terraform-azurerm-avm-res-keyvault-vault//secret

Module to deploy key vault secrets in Azure.

## Usage

This sub-module can be called directly to add secrets to an existing key vault:

```terraform
module "keyvault_secret" {
  source = "Azure/avm-res-keyvault-vault/azurerm//modules/secret"

  key_vault_resource_id = azurerm_key_vault.this.id
  name                  = "my-secret"
  value                 = "my-secret-value"

  # Optional
  content_type = "text/plain"
  tags = {
    environment = "prod"
  }
  role_assignments = {
    secrets_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = data.azurerm_client_config.this.object_id
    }
  }
}
```
