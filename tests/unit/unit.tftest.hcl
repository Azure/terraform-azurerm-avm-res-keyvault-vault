mock_provider "azapi" {}
mock_provider "azurerm" {
  override_data {
    target = data.azurerm_client_config.current
    values = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

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
