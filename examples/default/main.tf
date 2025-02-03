provider "azurerm" {
  features {}
}

terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.87"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# We need the tenant id for the key vault.
data "azurerm_client_config" "this" {}

# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.1.0"
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

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# This is the module call
module "keyvault" {
  source = "../../"
  # source              = "Azure/avm-res-keyvault-vault/azurerm"
  name                           = module.naming.key_vault.name_unique
  enable_telemetry               = var.enable_telemetry
  location                       = azurerm_resource_group.this.location
  resource_group_name            = azurerm_resource_group.this.name
  tenant_id                      = data.azurerm_client_config.this.tenant_id
  legacy_access_policies_enabled = true
  legacy_access_policies = {
    test = {
      object_id          = data.azurerm_client_config.this.object_id
      tenant_id          = data.azurerm_client_config.this.tenant_id
      secret_permissions = ["Get", "List"]
    }
  }
}
