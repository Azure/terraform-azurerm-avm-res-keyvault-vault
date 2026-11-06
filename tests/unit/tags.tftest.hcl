mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
      output = {
        properties = {
          vaultUri = "https://test.vault.azure.net/"
        }
      }
    }
  }
}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

variables {
  enable_telemetry = false
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test"
  name             = "test"
  location         = "eastus"
  tenant_id        = "00000000-0000-0000-0000-000000000000"
}

run "inherit_parent_tags" {
  command = apply

  variables {
    tags = { environment = "test", owner = "platform" }
    keys = {
      omitted = {
        name     = "omitted"
        key_type = "RSA"
        key_size = 2048
      }
      explicit_null = {
        name     = "explicit-null"
        key_type = "RSA"
        key_size = 2048
        tags     = null
      }
    }
    secrets = {
      omitted = {
        name = "omitted"
      }
      explicit_null = {
        name = "explicit-null"
        tags = null
      }
    }
    secrets_value = {
      omitted = "unit-test-value"
    }
    secrets_value_wo = {
      explicit_null = "unit-test-write-only-value"
    }
    secrets_value_wo_version = {
      explicit_null = 1
    }
  }

  assert {
    condition     = output.keys["omitted"].tags == var.tags
    error_message = "keys: omitted tags must follow the documented fallback and replacement semantics."
  }

  assert {
    condition     = output.keys["explicit_null"].tags == var.tags
    error_message = "keys: explicit_null tags must follow the documented fallback and replacement semantics."
  }

  assert {
    condition     = output.secrets["omitted"].tags == var.tags
    error_message = "secrets: omitted tags must follow the documented fallback and replacement semantics."
  }

  assert {
    condition     = output.secrets["explicit_null"].tags == var.tags
    error_message = "secrets: explicit_null tags must follow the documented fallback and replacement semantics."
  }
}

run "child_tags_replace_parent" {
  command = apply

  variables {
    tags = { environment = "test", owner = "platform" }
    keys = {
      override = {
        name     = "override"
        key_type = "RSA"
        key_size = 2048
        tags     = { owner = "application" }
      }
      empty = {
        name     = "empty"
        key_type = "RSA"
        key_size = 2048
        tags     = {}
      }
    }
    secrets = {
      override = {
        name = "override"
        tags = { owner = "application" }
      }
      empty = {
        name = "empty"
        tags = {}
      }
    }
    secrets_value = {
      override = "unit-test-value"
    }
    secrets_value_wo = {
      empty = "unit-test-write-only-value"
    }
    secrets_value_wo_version = {
      empty = 1
    }
  }

  assert {
    condition     = output.keys["override"].tags == tomap({ owner = "application" })
    error_message = "keys: override tags must follow the documented fallback and replacement semantics."
  }

  assert {
    condition     = try(length(output.keys["empty"].tags), -1) == 0
    error_message = "keys: empty tags must follow the documented fallback and replacement semantics."
  }

  assert {
    condition     = output.secrets["override"].tags == tomap({ owner = "application" })
    error_message = "secrets: override tags must follow the documented fallback and replacement semantics."
  }

  assert {
    condition     = try(length(output.secrets["empty"].tags), -1) == 0
    error_message = "secrets: empty tags must follow the documented fallback and replacement semantics."
  }
}

run "null_parent_tags" {
  command = apply

  variables {
    tags = null
    keys = {
      omitted = {
        name     = "omitted"
        key_type = "RSA"
        key_size = 2048
      }
      override = {
        name     = "override"
        key_type = "RSA"
        key_size = 2048
        tags     = { owner = "application" }
      }
    }
    secrets = {
      omitted = {
        name = "omitted"
      }
      override = {
        name = "override"
        tags = { owner = "application" }
      }
    }
    secrets_value = {
      omitted = "unit-test-value"
    }
    secrets_value_wo = {
      override = "unit-test-write-only-value"
    }
    secrets_value_wo_version = {
      override = 1
    }
  }

  assert {
    condition     = output.keys["omitted"].tags == null
    error_message = "keys: omitted tags must follow the documented fallback and replacement semantics."
  }

  assert {
    condition     = output.keys["override"].tags == tomap({ owner = "application" })
    error_message = "keys: override tags must follow the documented fallback and replacement semantics."
  }

  assert {
    condition     = output.secrets["omitted"].tags == null
    error_message = "secrets: omitted tags must follow the documented fallback and replacement semantics."
  }

  assert {
    condition     = output.secrets["override"].tags == tomap({ owner = "application" })
    error_message = "secrets: override tags must follow the documented fallback and replacement semantics."
  }
}

run "empty_parent_tags" {
  command = apply

  variables {
    tags = {}
    keys = {
      omitted = {
        name     = "omitted"
        key_type = "RSA"
        key_size = 2048
      }
      explicit_null = {
        name     = "explicit-null"
        key_type = "RSA"
        key_size = 2048
        tags     = null
      }
    }
    secrets = {
      omitted = {
        name = "omitted"
      }
      explicit_null = {
        name = "explicit-null"
        tags = null
      }
    }
    secrets_value = {
      omitted = "unit-test-value"
    }
    secrets_value_wo = {
      explicit_null = "unit-test-write-only-value"
    }
    secrets_value_wo_version = {
      explicit_null = 1
    }
  }

  assert {
    condition     = try(length(output.keys["omitted"].tags), -1) == 0
    error_message = "keys: omitted tags must follow the documented fallback and replacement semantics."
  }

  assert {
    condition     = try(length(output.keys["explicit_null"].tags), -1) == 0
    error_message = "keys: explicit_null tags must follow the documented fallback and replacement semantics."
  }

  assert {
    condition     = try(length(output.secrets["omitted"].tags), -1) == 0
    error_message = "secrets: omitted tags must follow the documented fallback and replacement semantics."
  }

  assert {
    condition     = try(length(output.secrets["explicit_null"].tags), -1) == 0
    error_message = "secrets: explicit_null tags must follow the documented fallback and replacement semantics."
  }
}
