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
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 0 && length(terraform_data.telemetry) == 0
    error_message = "Disabling telemetry must omit the key telemetry resources."
  }
}

run "key_telemetry_requires_location" {
  command = plan

  module {
    source = "./modules/key"
  }

  variables {
    key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
    name                  = "key"
    type                  = "RSA"
    size                  = 2048
  }

  expect_failures = [var.location]
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
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 0 && length(terraform_data.telemetry) == 0
    error_message = "Disabling telemetry must omit the secret telemetry resources."
  }
}

run "secret_telemetry_requires_location" {
  command = plan

  module {
    source = "./modules/secret"
  }

  variables {
    key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
    name                  = "secret"
    value                 = "test"
  }

  expect_failures = [var.location]
}
