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
  tenant_id           = "00000000-0000-0000-0000-000000000000"
  name                = "keyvault"
  location            = "location"
  resource_group_name = "resource_group_name"
}

run "certificate_correct" {
  command = plan
  variables {
    legacy_access_policies_enabled = true
    legacy_access_policies = {
      test = {
        object_id               = "00000000-0000-0000-0000-000000000000"
        certificate_permissions = ["Backup", "Create", "Delete"]
      }
    }
  }
  assert {
    error_message = "Access policy not as expected"
    condition     = contains([for policy in jsondecode(azapi_resource.this.body).properties.accessPolicies : policy.permissions.certificates], ["Backup", "Create", "Delete"])
  }
}

run "certificate_incorrect" {
  command = plan
  variables {
    legacy_access_policies_enabled = true
    legacy_access_policies = {
      test = {
        object_id               = "00000000-0000-0000-0000-000000000000"
        certificate_permissions = ["Backup", "Create", "NotFound"]
      }
    }
  }
  expect_failures = [var.legacy_access_policies]
}

run "certificate_empty" {
  command = plan
  variables {
    legacy_access_policies_enabled = true
    legacy_access_policies = {
      test = {
        object_id               = "00000000-0000-0000-0000-000000000000"
        certificate_permissions = []
        secret_permissions      = ["Get"]
      }
    }
  }
}

run "object_id_correct" {
  command = plan
  variables {
    legacy_access_policies_enabled = true
    legacy_access_policies = {
      test = {
        object_id          = "00000000-0000-0000-0000-000000000000"
        secret_permissions = ["Get"]
      }
    }
  }
  assert {
    error_message = "Access policy object id not as expected"
    condition     = contains([for policy in jsondecode(azapi_resource.this.body).properties.accessPolicies : policy.objectId], "00000000-0000-0000-0000-000000000000")
  }
}

run "object_id_invalid" {
  command = plan
  variables {
    legacy_access_policies_enabled = true
    legacy_access_policies = {
      test = {
        object_id = "nonsense"
      }
    }
  }
  expect_failures = [var.legacy_access_policies]
}
