mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

variables {
  enable_telemetry = false
  tenant_id        = "00000000-0000-0000-0000-000000000000"
  name             = "keyvault"
  location         = "eastus"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name"
}

# A lock on an endpoint has to land on whichever private endpoint resource is
# active, so both DNS zone group modes get the same coverage.
run "lock_with_managed_dns_zone_group" {
  command = plan

  variables {
    private_endpoints_manage_dns_zone_group = true

    private_endpoints = {
      pe1 = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
        lock = {
          kind  = "CanNotDelete"
          notes = "Managed endpoint lock"
        }
      }
    }
  }

  assert {
    error_message = "Lock should be created for the managed private endpoint"
    condition     = keys(azapi_resource.private_endpoint_locks) == ["pe1"]
  }
  assert {
    error_message = "No lock should be created for the unmanaged private endpoint"
    condition     = length(azapi_resource.private_endpoint_locks_unmanaged_dns_zone_groups) == 0
  }
  assert {
    error_message = "Lock level should come from the lock kind"
    condition     = azapi_resource.private_endpoint_locks["pe1"].body.properties.level == "CanNotDelete"
  }
  assert {
    error_message = "Lock name should default to the generated private endpoint name"
    condition     = azapi_resource.private_endpoint_locks["pe1"].name == "lock-pe-keyvault"
  }
  assert {
    error_message = "Lock notes should be passed to the managed private endpoint lock"
    condition     = azapi_resource.private_endpoint_locks["pe1"].body.properties.notes == "Managed endpoint lock"
  }
  assert {
    error_message = "A lock should be removed, and Azure given time to stop enforcing it, before the private endpoint is deleted"
    condition     = length(time_sleep.private_endpoint_lock_removal) == 1
  }
}

run "lock_with_unmanaged_dns_zone_group" {
  command = plan

  variables {
    private_endpoints_manage_dns_zone_group = false

    private_endpoints = {
      pe1 = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
        lock = {
          kind  = "ReadOnly"
          notes = "Unmanaged endpoint lock"
        }
      }
    }
  }

  assert {
    error_message = "Lock should be created for the unmanaged private endpoint"
    condition     = keys(azapi_resource.private_endpoint_locks_unmanaged_dns_zone_groups) == ["pe1"]
  }
  assert {
    error_message = "No lock should be created for the managed private endpoint"
    condition     = length(azapi_resource.private_endpoint_locks) == 0
  }
  assert {
    error_message = "Lock level should come from the lock kind"
    condition     = azapi_resource.private_endpoint_locks_unmanaged_dns_zone_groups["pe1"].body.properties.level == "ReadOnly"
  }
  assert {
    error_message = "Lock name should default to the generated private endpoint name"
    condition     = azapi_resource.private_endpoint_locks_unmanaged_dns_zone_groups["pe1"].name == "lock-pe-keyvault"
  }
  assert {
    error_message = "Lock notes should be passed to the unmanaged private endpoint lock"
    condition     = azapi_resource.private_endpoint_locks_unmanaged_dns_zone_groups["pe1"].body.properties.notes == "Unmanaged endpoint lock"
  }
}

# The AzureRM provider left notes unset when none were configured, so they are not sent.
run "lock_without_notes_sends_none" {
  command = plan

  variables {
    private_endpoints = {
      pe1 = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
        lock = {
          kind = "CanNotDelete"
        }
      }
    }
  }

  assert {
    error_message = "Lock notes should not be sent when none are configured"
    condition     = !contains(keys(azapi_resource.private_endpoint_locks["pe1"].body.properties), "notes")
  }
}

run "lock_name_override_and_custom_endpoint_name" {
  command = plan

  variables {
    private_endpoints = {
      named = {
        name               = "pe-custom"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
        lock = {
          kind = "CanNotDelete"
          name = "my-lock"
        }
      }
      derived = {
        name               = "pe-derived"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
        lock = {
          kind = "CanNotDelete"
        }
      }
    }
  }

  assert {
    error_message = "An explicit lock name should win over the generated one"
    condition     = azapi_resource.private_endpoint_locks["named"].name == "my-lock"
  }
  assert {
    error_message = "A generated lock name should follow the private endpoint name"
    condition     = azapi_resource.private_endpoint_locks["derived"].name == "lock-pe-derived"
  }
}

# Endpoints without a lock must not drag an unwanted lock along with them.
run "endpoints_without_a_lock_get_none" {
  command = plan

  variables {
    private_endpoints = {
      locked = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
        lock = {
          kind = "CanNotDelete"
        }
      }
      unlocked = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
      }
    }
  }

  assert {
    error_message = "Only the endpoint that asked for a lock should get one"
    condition     = keys(azapi_resource.private_endpoint_locks) == ["locked"]
  }
  assert {
    error_message = "Both private endpoints should still be created"
    condition     = length(azapi_resource.private_endpoints) == 2
  }
}

run "no_private_endpoints_means_no_locks" {
  command = plan

  assert {
    error_message = "No locks should be created without private endpoints"
    condition     = length(azapi_resource.private_endpoint_locks) == 0
  }
  assert {
    error_message = "No locks should be created without private endpoints"
    condition     = length(azapi_resource.private_endpoint_locks_unmanaged_dns_zone_groups) == 0
  }
  assert {
    error_message = "No lock removal pause should be created without private endpoint locks"
    condition     = length(time_sleep.private_endpoint_lock_removal) == 0
  }
}

run "lock_rejects_unknown_kind" {
  command = plan

  variables {
    private_endpoints = {
      pe1 = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
        lock = {
          kind = "None"
        }
      }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "lock_kind_is_case_sensitive" {
  command = plan

  variables {
    private_endpoints = {
      pe1 = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
        lock = {
          kind = "cannotdelete"
        }
      }
    }
  }

  expect_failures = [var.private_endpoints]
}
