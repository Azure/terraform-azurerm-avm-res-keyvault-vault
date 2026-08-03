mock_provider "azurerm" {}
mock_provider "modtm" {}

variables {
  enable_telemetry    = false
  resource_group_name = "test"
  name                = "test"
  location            = "eastus"
  tenant_id           = "00000000-0000-0000-0000-000000000000"
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
