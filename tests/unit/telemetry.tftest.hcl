mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {}

mock_provider "random" {}

mock_provider "time" {}

run "vault_telemetry_enabled" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test"
    name      = "test"
    location  = "eastus"
    tenant_id = "00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 1 && length(terraform_data.telemetry) == 1
    error_message = "The vault must enable deployment telemetry by default."
  }
}

run "vault_telemetry_disabled" {
  command = plan

  variables {
    parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test"
    name             = "test"
    location         = "eastus"
    tenant_id        = "00000000-0000-0000-0000-000000000000"
    enable_telemetry = false
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 0 && length(terraform_data.telemetry) == 0
    error_message = "Disabling telemetry must omit the vault telemetry resources."
  }
}

run "key_telemetry_enabled" {
  command = plan

  module {
    source = "./modules/key"
  }

  variables {
    key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
    name                  = "key"
    type                  = "RSA"
    size                  = 2048
    location              = "eastus"
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 1 && length(terraform_data.telemetry) == 1
    error_message = "The key submodule must enable deployment telemetry by default."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
  }
}

run "key_telemetry_disabled" {
  command = plan

  module {
    source = "./modules/key"
  }

  variables {
    key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
    name                  = "key"
    type                  = "RSA"
    size                  = 2048
    enable_telemetry      = false
    location              = "eastus"
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 0 && length(terraform_data.telemetry) == 0
    error_message = "Disabling telemetry must omit the key telemetry resources."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
  }
}


run "secret_telemetry_enabled" {
  command = plan

  module {
    source = "./modules/secret"
  }

  variables {
    key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
    name                  = "secret"
    value                 = "test"
    location              = "eastus"
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 1 && length(terraform_data.telemetry) == 1
    error_message = "The secret submodule must enable deployment telemetry by default."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
  }
}

run "secret_telemetry_disabled" {
  command = plan

  module {
    source = "./modules/secret"
  }

  variables {
    key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
    name                  = "secret"
    value                 = "test"
    enable_telemetry      = false
    location              = "eastus"
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 0 && length(terraform_data.telemetry) == 0
    error_message = "Disabling telemetry must omit the secret telemetry resources."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
  }
}

