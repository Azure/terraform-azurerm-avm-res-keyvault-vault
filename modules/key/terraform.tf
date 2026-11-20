terraform {
  required_version = ">= 1.11, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    # TFFR3 data-plane exception, scoped to the single azurerm block in main.tf.
    # Key Vault keys: `azapi_data_plane_resource` cannot manage key rotation policies (Azure/terraform-provider-azapi#1042) and cannot move state from `azurerm_key_vault_key`, so moving would create new key material.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81, < 5.0"
    }
  }
}
