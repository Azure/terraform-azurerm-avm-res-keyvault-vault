provider "azurerm" {
  features {}
}

terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.117"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Get current IP address for use in KV firewall rules
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

data "azurerm_client_config" "current" {}

module "key_vault" {
  source = "../../"

  location = azurerm_resource_group.this.location
  # source             = "Azure/avm-res-keyvault-vault/azurerm"
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  enable_telemetry    = var.enable_telemetry
  keys = {
    cmk_for_storage_account = {
      key_opts = [
        "decrypt",
        "encrypt",
        "sign",
        "unwrapKey",
        "verify",
        "wrapKey"
      ]
      key_type = "RSA"
      name     = "cmk-for-storage-account"
      key_size = 2048
    }
    # HSM-backed keys require a Key Vault with the `premium` SKU. This example sets
    # `sku_name` explicitly below rather than relying on the module default.
    hsm_cmk_for_storage_account = {
      key_opts = [
        "decrypt",
        "encrypt",
        "sign",
        "unwrapKey",
        "verify",
        "wrapKey"
      ]
      key_type = "RSA-HSM"
      name     = "hsm-cmk-for-storage-account"
      key_size = 2048
    }
  }
  network_acls = {
    bypass   = "AzureServices"
    ip_rules = ["${data.http.ip.response_body}/32"]
  }
  public_network_access_enabled = true
  role_assignments = {
    deployment_user_kv_admin = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }
  # Required for the HSM-backed key above. Also the module default, but set
  # explicitly so the example does not silently break if that default changes.
  sku_name = "premium"
  wait_for_rbac_before_key_operations = {
    create = "60s"
  }
}

# The created key is referenced through the `keys` output, indexed by the *map key* used in
# `var.keys` above (`cmk_for_storage_account`), not by the key's `name`
# (`cmk-for-storage-account`).
#
# Use `.id` for the versioned data plane URI that services expect for a customer managed key:
#   https://<vault-name>.vault.azure.net/keys/<key-name>/<key-version>
#
# For example, the `transparent_data_encryption_key_vault_key_id` input of
# `Azure/avm-res-sql-server/azurerm` takes:
#
#   module.key_vault.keys["cmk_for_storage_account"].id
#
# That input requires the fully versioned key URL. Note that Azure SQL does support key
# rotation, but it is enabled by a separate setting on that module rather than by passing
# a versionless URI, so `.versionless_id` is not the right value here.
#
# A working end-to-end configuration also needs a managed identity on the SQL server and a
# `Key Vault Crypto Service Encryption User` role assignment for it on the vault. That is
# out of scope for this example — see the avm-res-sql-server module's own TDE example for a
# complete, tested configuration. The `outputs.tf` file here shows the other identifier
# forms this module exposes.
