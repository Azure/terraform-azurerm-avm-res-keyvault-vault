module "regions" {
  source  = "Azure/regions/azurerm"
  version = "0.4.0"
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
  # source             = "Azure/avm-res-keyvault-vault/azurerm"
  name                          = module.naming.key_vault.name_unique
  location                      = azurerm_resource_group.this.location
  enable_telemetry              = var.enable_telemetry
  resource_group_name           = azurerm_resource_group.this.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  public_network_access_enabled = true
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
      key_type     = "RSA"
      key_vault_id = module.key_vault.resource.id
      name         = "cmk-for-storage-account"
      key_size     = 2048
    }
  }
  role_assignments = {
    deployment_user_kv_admin = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }
  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }
  network_acls = {
    bypass   = "AzureServices"
    ip_rules = ["${data.http.ip.response_body}/32"]
  }
}
