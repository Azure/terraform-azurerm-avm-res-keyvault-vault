mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

variables {
  enable_telemetry    = false
  tenant_id           = "00000000-0000-0000-0000-000000000000"
  name                = "keyvault"
  location            = "eastus"
  resource_group_name = "resource_group_name"

  private_endpoints = {
    pe1 = {
      subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
      application_security_group_associations = {
        asg1 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg1"
      }
    }
  }
}

# The association resource indexes into one of the two private endpoint
# resources, so planning it at all proves the reference resolves.
run "asg_association_with_managed_dns_zone_group" {
  command = plan

  variables {
    private_endpoints_manage_dns_zone_group = true
  }

  assert {
    error_message = "Managed DNS zone group private endpoint should be created"
    condition     = keys(azurerm_private_endpoint.this) == ["pe1"]
  }
  assert {
    error_message = "Unmanaged DNS zone group private endpoint should not be created"
    condition     = length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0
  }
  assert {
    error_message = "ASG association should be created for the managed private endpoint"
    condition     = keys(azurerm_private_endpoint_application_security_group_association.this) == ["pe1-asg1"]
  }
  assert {
    error_message = "ASG association should reference the supplied application security group"
    condition     = azurerm_private_endpoint_application_security_group_association.this["pe1-asg1"].application_security_group_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg1"
  }
}

run "asg_association_with_unmanaged_dns_zone_group" {
  command = plan

  variables {
    private_endpoints_manage_dns_zone_group = false
  }

  assert {
    error_message = "Managed DNS zone group private endpoint should not be created"
    condition     = length(azurerm_private_endpoint.this) == 0
  }
  assert {
    error_message = "Unmanaged DNS zone group private endpoint should be created"
    condition     = keys(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == ["pe1"]
  }
  assert {
    error_message = "ASG association should be created for the unmanaged private endpoint"
    condition     = keys(azurerm_private_endpoint_application_security_group_association.this) == ["pe1-asg1"]
  }
  assert {
    error_message = "ASG association should reference the supplied application security group"
    condition     = azurerm_private_endpoint_application_security_group_association.this["pe1-asg1"].application_security_group_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg1"
  }
}

# `private_endpoints_manage_dns_zone_group` is module-wide, so a single
# `var.private_endpoints` map can still mix endpoints that want a DNS zone
# group with ones that don't: under the managed resource the zone group block
# is driven per-endpoint by `private_dns_zone_resource_ids`. Both endpoints
# still live in the same resource address, which is what the association
# lookup depends on.
run "asg_associations_mixed_zone_usage_managed" {
  command = plan

  variables {
    private_endpoints_manage_dns_zone_group = true

    private_endpoints = {
      with_zone = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"]
        application_security_group_associations = {
          asg1 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg1"
        }
      }
      without_zone = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
        application_security_group_associations = {
          asg1 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg1"
          asg2 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg2"
        }
      }
    }
  }

  assert {
    error_message = "Both endpoints should be created by the managed resource regardless of zone usage"
    condition     = toset(keys(azurerm_private_endpoint.this)) == toset(["with_zone", "without_zone"])
  }
  assert {
    error_message = "Unmanaged DNS zone group private endpoints should not be created"
    condition     = length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0
  }
  assert {
    error_message = "Every ASG association should be created, keyed by endpoint and ASG"
    condition     = toset(keys(azurerm_private_endpoint_application_security_group_association.this)) == toset(["with_zone-asg1", "without_zone-asg1", "without_zone-asg2"])
  }
}

run "asg_associations_mixed_zone_usage_unmanaged" {
  command = plan

  variables {
    private_endpoints_manage_dns_zone_group = false

    private_endpoints = {
      with_zone = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"]
        application_security_group_associations = {
          asg1 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg1"
        }
      }
      without_zone = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
        application_security_group_associations = {
          asg1 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg1"
          asg2 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg2"
        }
      }
    }
  }

  assert {
    error_message = "Managed DNS zone group private endpoints should not be created"
    condition     = length(azurerm_private_endpoint.this) == 0
  }
  assert {
    error_message = "Both endpoints should be created by the unmanaged resource"
    condition     = toset(keys(azurerm_private_endpoint.this_unmanaged_dns_zone_groups)) == toset(["with_zone", "without_zone"])
  }
  assert {
    error_message = "Every ASG association should be created, keyed by endpoint and ASG"
    condition     = toset(keys(azurerm_private_endpoint_application_security_group_association.this)) == toset(["with_zone-asg1", "without_zone-asg1", "without_zone-asg2"])
  }
}
