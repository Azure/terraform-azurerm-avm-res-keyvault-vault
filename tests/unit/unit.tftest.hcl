provider "azurerm" {
  features {}
}

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

run "certificates_error_if_both_policy_and_certificate_are_set" {
  command = plan

  variables {
    certificates = {
      mycert = {
        name = "test"
        policy = {
          issuer_parameters = {
            name = "Self"
          }
          key_properties = {
            exportable = false
            key_type   = "RSA"
            reuse_key  = false
          }
          secret_properties = {
            content_type = "application/x-pkcs12"
          }
        }
        certificate = {
          contents = "test"
        }
      }
    }
  }

  expect_failures = [var.certificates]
}

run "certificates_error_if_neither_policy_nor_certificate_are_set" {
  command = plan

  variables {
    certificates = {
      mycert = {
        name = "test"
      }
    }
  }

  expect_failures = [var.certificates]
}
