mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "azapi" {}
mock_provider "random" {}
mock_provider "time" {}

override_resource {
  target = azurerm_key_vault.this
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
  }
}

variables {
  enable_telemetry    = false
  resource_group_name = "test"
  name                = "test"
  location            = "eastus"
  tenant_id           = "00000000-0000-0000-0000-000000000000"
}

run "role_assignment_descriptions" {
  command = plan

  variables {
    role_assignments = {
      described = {
        role_definition_id_or_name = "Key Vault Secrets User"
        principal_id               = "11111111-1111-1111-1111-111111111111"
        description                = "Read secrets for the application"
      }
      omitted = {
        role_definition_id_or_name = "Key Vault Reader"
        principal_id               = "22222222-2222-2222-2222-222222222222"
      }
      explicit_null = {
        role_definition_id_or_name = "Key Vault Crypto User"
        principal_id               = "33333333-3333-3333-3333-333333333333"
        description                = null
      }
    }
  }

  assert {
    condition     = azurerm_role_assignment.this["described"].description == var.role_assignments["described"].description
    error_message = "The role assignment must preserve the supplied description."
  }

  assert {
    condition     = azurerm_role_assignment.this["omitted"].description == null
    error_message = "An omitted role assignment description must remain null."
  }

  assert {
    condition     = azurerm_role_assignment.this["explicit_null"].description == null
    error_message = "An explicit null role assignment description must remain null."
  }
}

run "name_regex_length_long" {
  command = plan

  variables {
    name = "abcdefghijklmnopqrstuvwxy"
  }

  expect_failures = [var.name]
}

run "name_regex_length_short" {
  command = plan

  variables {
    name = "ab"
  }

  expect_failures = [var.name]
}

run "name_regex_no_double_dashes" {
  command = plan

  variables {
    name = "ab--2"
  }

  expect_failures = [var.name]
}

run "name_regex_must_start_with_letter" {
  command = plan

  variables {
    name = "6test"
  }

  expect_failures = [var.name]
}

run "name_regex_must_end_with_letter_or_number" {
  command = plan

  variables {
    name = "test-"
  }

  expect_failures = [var.name]
}

run "keys_accepts_all_key_types" {
  command = plan

  variables {
    keys = {
      ec = {
        name     = "ec-key"
        key_type = "EC"
        curve    = "P-256"
      }
      ec_hsm = {
        name     = "ec-hsm-key"
        key_type = "EC-HSM"
        curve    = "P-256"
      }
      rsa = {
        name     = "rsa-key"
        key_type = "RSA"
        key_size = 2048
      }
      rsa_hsm = {
        name     = "rsa-hsm-key"
        key_type = "RSA-HSM"
        key_size = 2048
      }
    }
  }
}

run "keys_rejects_unknown_key_type" {
  command = plan

  variables {
    keys = {
      invalid = {
        name     = "invalid-key"
        key_type = "AES"
      }
    }
  }

  expect_failures = [var.keys]
}

run "keys_key_type_is_case_sensitive" {
  command = plan

  variables {
    keys = {
      lowercase = {
        name     = "rsa-hsm-key"
        key_type = "rsa-hsm"
        key_size = 2048
      }
    }
  }

  expect_failures = [var.keys]
}

run "keys_hsm_type_rejected_on_standard_sku" {
  command = plan

  variables {
    sku_name = "standard"
    keys = {
      hsm = {
        name     = "hsm-key"
        key_type = "RSA-HSM"
        key_size = 2048
      }
    }
  }

  expect_failures = [var.keys]
}

run "keys_non_hsm_type_allowed_on_standard_sku" {
  command = plan

  variables {
    sku_name = "standard"
    keys = {
      rsa = {
        name     = "rsa-key"
        key_type = "RSA"
        key_size = 2048
      }
    }
  }
}
