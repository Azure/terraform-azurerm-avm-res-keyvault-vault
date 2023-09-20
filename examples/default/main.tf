terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetry.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

provider "azurerm" {
  features {}
}

# We need the tenant id for the key vault.
data "azurerm_client_config" "this" {}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group.name_unique
  location = "northeurope"
}

# This is the module call itself
module "keyvault" {
  source              = "../../"
  name                = module.naming.key_vault.name_unique
  enable_telemetry    = var.enable_telemetry
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.this.tenant_id
  role_assignments = {
    test = {
      principal_id               = data.azurerm_client_config.this.object_id
      role_definition_id_or_name = "Key Vault Administrator"
    }
  }

  keys = {
    mykey = {
      name     = "sdlfhs"
      curve    = "P-256"
      key_type = "EC"
      key_opts = []
      role_assignments = {
        me = {
          principal_id               = data.azurerm_client_config.this.object_id
          role_definition_id_or_name = "Key Vault Crypto Officer"
        }
    } }
  }
}


output "this" {
  value       = module.keyvault.resource
  description = "The Key Vault resource."
}

output "keys" {
  value       = module.keyvault.resource_keys
  description = "The keys created by this module."
}

output "secrets" {
  value       = module.keyvault.resource_secrets
  description = "The keys created by this module."
}
