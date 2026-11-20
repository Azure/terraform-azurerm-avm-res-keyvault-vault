terraform {
  required_version = ">= 1.11, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    # TFFR3 data-plane exception, scoped to the single azurerm block in main.tf.
    # Key Vault secrets: `azapi_data_plane_resource` cannot move state from `azurerm_key_vault_secret`, so moving would recreate every secret and fail on the soft-deleted name.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81, < 5.0"
    }
  }
}
