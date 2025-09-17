terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = module.naming.resource_group.name_unique
}

# Get current client configuration (for tenant_id and object_id)
data "azurerm_client_config" "current" {}

# This is the module call
module "test" {
  source = "../.."

  # Resource group
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  # Key Vault configuration
  name      = module.naming.key_vault.name_unique
  tenant_id = data.azurerm_client_config.current.tenant_id

  # Enable RBAC for data plane
  legacy_access_policies_enabled = false

  # Configure management lock
  lock = {
    kind = "CanNotDelete"
    name = "kv-lock"
  }

  # Configure role assignments to test the dependency
  role_assignments = {
    "test_assignment" = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }

  # Tags
  tags = var.tags
}