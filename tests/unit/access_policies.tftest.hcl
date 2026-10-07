mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

variables {
  enable_telemetry = false
  tenant_id        = "00000000-0000-0000-0000-000000000000"
  name             = "keyvault"
  location         = "location"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name"
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
    condition     = toset(azapi_resource.this.body.properties.accessPolicies[0].permissions.certificates) == toset(["Backup", "Create", "Delete"])
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
    condition     = azapi_resource.this.body.properties.accessPolicies[0].objectId == "00000000-0000-0000-0000-000000000000"
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

run "storage_permissions_correct" {
  command = plan
  variables {
    legacy_access_policies_enabled = true
    legacy_access_policies = {
      test = {
        object_id           = "00000000-0000-0000-0000-000000000000"
        storage_permissions = ["Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"]
      }
    }
  }
  assert {
    error_message = "Storage permissions not as expected"
    condition     = toset(azapi_resource.this.body.properties.accessPolicies[0].permissions.storage) == toset(["Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"])
  }
}

run "storage_permissions_incorrect" {
  command = plan
  variables {
    legacy_access_policies_enabled = true
    legacy_access_policies = {
      test = {
        object_id           = "00000000-0000-0000-0000-000000000000"
        storage_permissions = ["Backup", "Invalid", "ListSAS"]
      }
    }
  }
  expect_failures = [var.legacy_access_policies]
}

run "access_policies_absent_when_legacy_disabled" {
  command = plan
  variables {
    legacy_access_policies_enabled = false
    legacy_access_policies = {
      test = {
        object_id          = "00000000-0000-0000-0000-000000000000"
        secret_permissions = ["Get"]
      }
    }
  }
  assert {
    error_message = "RBAC authorization should be enabled when legacy access policies are disabled"
    condition     = azapi_resource.this.body.properties.enableRbacAuthorization == true
  }
  assert {
    error_message = "Access policies should not be managed when the legacy path is disabled"
    condition     = length(azapi_resource.this.body.properties.accessPolicies) == 0
  }
}
