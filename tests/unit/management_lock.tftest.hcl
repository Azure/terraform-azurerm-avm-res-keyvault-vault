mock_provider "azurerm" {}
mock_provider "modtm" {}

variables {
  enable_telemetry    = false
  resource_group_name = "test"
  name                = "test"
  location            = "eastus"
  tenant_id           = "00000000-0000-0000-0000-000000000000"
}

run "management_lock_dependencies" {
  command = plan

  variables {
    lock = {
      kind = "CanNotDelete"
      name = "test-lock"
    }
    role_assignments = {
      "test" = {
        role_definition_id_or_name = "Key Vault Administrator"
        principal_id               = "00000000-0000-0000-0000-000000000000"
      }
    }
    diagnostic_settings = {
      "test" = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.OperationalInsights/workspaces/test"
      }
    }
  }

  # Verify that the management lock resource is planned
  assert {
    condition     = length(azurerm_management_lock.this) == 1
    error_message = "Management lock should be created when lock variable is provided"
  }

  # Verify that the lock has proper dependencies on child resources
  assert {
    condition     = contains(azurerm_management_lock.this[0].depends_on, azurerm_role_assignment.this)
    error_message = "Management lock should depend on role assignments for proper destroy order"
  }

  # Verify that child resources do not depend on the lock
  assert {
    condition     = !contains(coalesce(azurerm_role_assignment.this["test"].depends_on, []), azurerm_management_lock.this)
    error_message = "Role assignments should not depend on management lock - dependencies should be reversed"
  }
}

run "no_management_lock" {
  command = plan

  variables {
    lock = null
    role_assignments = {
      "test" = {
        role_definition_id_or_name = "Key Vault Administrator"
        principal_id               = "00000000-0000-0000-0000-000000000000"
      }
    }
  }

  # Verify that no management lock resource is planned when lock is null
  assert {
    condition     = length(azurerm_management_lock.this) == 0
    error_message = "Management lock should not be created when lock variable is null"
  }

  # Verify that role assignments still work without management lock
  assert {
    condition     = can(azurerm_role_assignment.this)
    error_message = "Role assignments should still be plannable when no management lock is configured"
  }
}