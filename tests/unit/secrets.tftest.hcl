mock_provider "azurerm" {}
mock_provider "modtm" {}

variables {
  enable_telemetry    = false
  resource_group_name = "test"
  name                = "test"
  location            = "eastus"
  tenant_id           = "00000000-0000-0000-0000-000000000000"
}

run "secrets_plain_value" {
  command = plan

  variables {
    secrets = {
      plain = {
        name = "plain-secret"
      }
    }
    secrets_value = {
      plain = "secret-value"
    }
  }
}

run "secrets_write_only_value" {
  command = plan

  variables {
    secrets = {
      wo = {
        name = "wo-secret"
      }
    }
    secrets_value_wo = {
      wo = "secret-value-wo"
    }
    secrets_value_wo_version = {
      wo = 1
    }
  }
}

run "secrets_plain_and_write_only_coexist" {
  command = plan

  variables {
    secrets = {
      plain = {
        name = "plain-secret"
      }
      wo = {
        name = "wo-secret"
      }
    }
    secrets_value = {
      plain = "secret-value"
    }
    secrets_value_wo = {
      wo = "secret-value-wo"
    }
    secrets_value_wo_version = {
      wo = 1
    }
  }
}

run "secrets_write_only_version_increment" {
  command = plan

  variables {
    secrets = {
      wo = {
        name = "wo-secret"
      }
    }
    secrets_value_wo = {
      wo = "rotated-value"
    }
    secrets_value_wo_version = {
      wo = 2
    }
  }
}
