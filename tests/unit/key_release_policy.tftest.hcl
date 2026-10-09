mock_provider "azurerm" {}
mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

override_resource {
  target = azurerm_key_vault.this
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
  }
}

run "root_key_without_release_policy" {
  command = plan

  variables {
    enable_telemetry    = false
    resource_group_name = "test"
    name                = "test"
    location            = "eastus"
    tenant_id           = "00000000-0000-0000-0000-000000000000"
    keys = {
      ordinary = {
        name     = "ordinary"
        key_type = "RSA"
        key_size = 2048
      }
    }
  }

  assert {
    condition     = module.keys["ordinary"].release_policy_configured == false
    error_message = "Omitting a release policy at the root must leave the key without a release policy."
  }
}

run "root_key_with_release_policy" {
  command = plan

  variables {
    enable_telemetry    = false
    resource_group_name = "test"
    name                = "test"
    location            = "eastus"
    tenant_id           = "00000000-0000-0000-0000-000000000000"
    keys = {
      confidential = {
        name     = "confidential"
        key_type = "RSA-HSM"
        key_size = 2048
        release_policy = {
          json      = jsonencode({ version = "1.0.0", anyOf = [{ authority = "https://example.com" }] })
          immutable = true
        }
      }
    }
  }

  assert {
    condition     = module.keys["confidential"].release_policy_configured == true
    error_message = "The configured root release policy must reach the key submodule."
  }
}

run "root_rejects_software_key_release_policy" {
  command = plan

  variables {
    enable_telemetry    = false
    resource_group_name = "test"
    name                = "test"
    location            = "eastus"
    tenant_id           = "00000000-0000-0000-0000-000000000000"
    keys = {
      invalid = {
        name     = "invalid"
        key_type = "RSA"
        key_size = 2048
        release_policy = {
          json = jsonencode({ version = "1.0.0" })
        }
      }
    }
  }

  expect_failures = [var.keys]
}

run "root_rejects_release_policy_on_standard_vault" {
  command = plan

  variables {
    enable_telemetry    = false
    resource_group_name = "test"
    name                = "test"
    location            = "eastus"
    tenant_id           = "00000000-0000-0000-0000-000000000000"
    sku_name            = "standard"
    keys = {
      invalid = {
        name     = "invalid"
        key_type = "RSA-HSM"
        key_size = 2048
        release_policy = {
          json = jsonencode({ version = "1.0.0" })
        }
      }
    }
  }

  expect_failures = [var.keys]
}

run "key_without_release_policy" {
  command = plan

  module {
    source = "./modules/key"
  }

  variables {
    key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
    name                  = "ordinary"
    type                  = "RSA"
    size                  = 2048
  }

  assert {
    condition     = length(azurerm_key_vault_key.this.release_policy) == 0
    error_message = "Omitting a release policy must leave the provider block absent."
  }
}

run "key_with_release_policy" {
  command = plan

  module {
    source = "./modules/key"
  }

  variables {
    key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
    name                  = "confidential"
    type                  = "EC-HSM"
    curve                 = "P-256"
    release_policy = {
      json      = jsonencode({ version = "1.0.0", anyOf = [{ authority = "https://example.com" }] })
      immutable = true
    }
  }

  assert {
    condition     = azurerm_key_vault_key.this.release_policy[0].json == var.release_policy.json && azurerm_key_vault_key.this.release_policy[0].immutable == true
    error_message = "The configured release policy must reach the key resource unchanged."
  }
}

run "key_release_policy_defaults_to_mutable" {
  command = plan

  module {
    source = "./modules/key"
  }

  variables {
    key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
    name                  = "confidential"
    type                  = "RSA-HSM"
    size                  = 2048
    release_policy = {
      json = jsonencode({ version = "1.0.0" })
    }
  }

  assert {
    condition     = azurerm_key_vault_key.this.release_policy[0].immutable == false
    error_message = "Omitting immutable must preserve the provider's mutable default."
  }
}
