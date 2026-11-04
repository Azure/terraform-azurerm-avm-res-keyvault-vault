# terraform-azurerm-avm-res-keyvault-vault//key

Module to deploy key vault keys.

## Usage

This sub-module can be called directly to add keys to an existing key vault:

Telemetry is enabled by default and requires `location`. Existing direct callers upgrading from
versions that did not have this input must provide it or set `enable_telemetry = false`.

```terraform
module "keyvault_key" {
  source  = "Azure/avm-res-keyvault-vault/azurerm//modules/key"
  version = "0.#.#" # Replace with your desired version

  key_vault_resource_id = azurerm_key_vault.this.id
  location              = azurerm_key_vault.this.location
  name                  = "my-key"
  type                  = "RSA"

  # Optional
  size = 2048
  opts = ["sign", "verify"]
  rotation_policy = {
    automatic = {
      time_before_expiry = "P30D"
    }
    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
  role_assignments = {
    crypto_user = {
      role_definition_id_or_name = "Key Vault Crypto User"
      principal_id               = data.azurerm_client_config.this.object_id
    }
  }
}
```
