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

  private_endpoints = {
    pe1 = {
      subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
      application_security_group_associations = {
        asg1 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg1"
      }
    }
  }
}

run "asg_association_with_managed_dns_zone_group" {
  command = plan

  variables {
    private_endpoints_manage_dns_zone_group = true
  }

  assert {
    error_message = "Managed DNS zone group private endpoint should be created"
    condition     = keys(azapi_resource.private_endpoints) == ["pe1"]
  }
  assert {
    error_message = "Unmanaged DNS zone group private endpoint should not be created"
    condition     = length(azapi_resource.private_endpoints_unmanaged_dns_zone_groups) == 0
  }
  assert {
    error_message = "The application security group should be associated in the private endpoint's body"
    condition     = one(azapi_resource.private_endpoints["pe1"].body.properties.applicationSecurityGroups).id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg1"
  }
}

# The defaults reproduce what the AzureRM provider deployed, so that upgrading changes nothing in Azure.
run "private_endpoint_defaults_match_azurerm" {
  command = plan

  assert {
    error_message = "The private endpoint name should default to pe-<key vault name>"
    condition     = azapi_resource.private_endpoints["pe1"].name == "pe-keyvault"
  }
  assert {
    error_message = "The private service connection name should default to pse-<key vault name>"
    condition     = one(azapi_resource.private_endpoints["pe1"].body.properties.privateLinkServiceConnections).name == "pse-keyvault"
  }
  assert {
    error_message = "The subresource should default to vault"
    condition     = one(one(azapi_resource.private_endpoints["pe1"].body.properties.privateLinkServiceConnections).properties.groupIds) == "vault"
  }
  assert {
    error_message = "An unset custom network interface name should not be sent, because Azure stores it as an empty string"
    condition     = !contains(keys(azapi_resource.private_endpoints["pe1"].body.properties), "customNetworkInterfaceName")
  }
  assert {
    error_message = "The private endpoint should be deployed to the key vault's resource group"
    condition     = azapi_resource.private_endpoints["pe1"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name"
  }
}

run "private_endpoint_overrides_are_applied" {
  command = plan

  variables {
    private_endpoints = {
      pe1 = {
        name                            = "pe-custom"
        network_interface_name          = "nic-custom"
        private_service_connection_name = "psc-custom"
        resource_group_name             = "other_resource_group"
        subnet_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
      }
    }
  }

  assert {
    error_message = "The configured private endpoint name should be used"
    condition     = azapi_resource.private_endpoints["pe1"].name == "pe-custom"
  }
  assert {
    error_message = "The configured custom network interface name should be sent"
    condition     = azapi_resource.private_endpoints["pe1"].body.properties.customNetworkInterfaceName == "nic-custom"
  }
  assert {
    error_message = "The configured private service connection name should be used"
    condition     = one(azapi_resource.private_endpoints["pe1"].body.properties.privateLinkServiceConnections).name == "psc-custom"
  }
  assert {
    error_message = "A configured resource group name should resolve to that resource group in the key vault's subscription"
    condition     = azapi_resource.private_endpoints["pe1"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/other_resource_group"
  }
}

run "private_endpoint_interface_fields_are_applied" {
  command = plan

  variables {
    private_endpoints = {
      pe1 = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
        subresource_name   = "custom-subresource"
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.4"
            member_name        = "custom-member"
          }
        }
      }
    }
  }

  assert {
    error_message = "The configured subresource name should be passed to the private service connection"
    condition     = one(one(azapi_resource.private_endpoints["pe1"].body.properties.privateLinkServiceConnections).properties.groupIds) == "custom-subresource"
  }
  assert {
    error_message = "The configured member name should be passed to the IP configuration"
    condition     = one(azapi_resource.private_endpoints["pe1"].body.properties.ipConfigurations).properties.memberName == "custom-member"
  }
  assert {
    error_message = "The configured subresource name should be passed to the IP configuration"
    condition     = one(azapi_resource.private_endpoints["pe1"].body.properties.ipConfigurations).properties.groupId == "custom-subresource"
  }
}

run "private_endpoint_interface_fields_are_applied_with_unmanaged_dns" {
  command = plan

  variables {
    private_endpoints_manage_dns_zone_group = false

    private_endpoints = {
      pe1 = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet"
        subresource_name   = "custom-subresource"
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.4"
            member_name        = "custom-member"
          }
        }
      }
    }
  }

  assert {
    error_message = "The configured subresource name should be passed to the unmanaged-DNS private service connection"
    condition     = one(one(azapi_resource.private_endpoints_unmanaged_dns_zone_groups["pe1"].body.properties.privateLinkServiceConnections).properties.groupIds) == "custom-subresource"
  }
  assert {
    error_message = "The configured member name should be passed to the unmanaged-DNS IP configuration"
    condition     = one(azapi_resource.private_endpoints_unmanaged_dns_zone_groups["pe1"].body.properties.ipConfigurations).properties.memberName == "custom-member"
  }
}

run "asg_association_with_unmanaged_dns_zone_group" {
  command = plan

  variables {
    private_endpoints_manage_dns_zone_group = false
  }

  assert {
    error_message = "Managed DNS zone group private endpoint should not be created"
    condition     = length(azapi_resource.private_endpoints) == 0
  }
  assert {
    error_message = "Unmanaged DNS zone group private endpoint should be created"
    condition     = keys(azapi_resource.private_endpoints_unmanaged_dns_zone_groups) == ["pe1"]
  }
  assert {
    error_message = "The application security group should be associated in the unmanaged private endpoint's body"
    condition     = one(azapi_resource.private_endpoints_unmanaged_dns_zone_groups["pe1"].body.properties.applicationSecurityGroups).id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg1"
  }
}

# `private_endpoints_manage_dns_zone_group` is module-wide, so a single
# `var.private_endpoints` map can still mix endpoints that want a DNS zone
# group with ones that don't: under the managed resource the zone group is
# driven per-endpoint by `private_dns_zone_resource_ids`.
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
    condition     = toset(keys(azapi_resource.private_endpoints)) == toset(["with_zone", "without_zone"])
  }
  assert {
    error_message = "Unmanaged DNS zone group private endpoints should not be created"
    condition     = length(azapi_resource.private_endpoints_unmanaged_dns_zone_groups) == 0
  }
  assert {
    error_message = "Every application security group should be associated with its own endpoint"
    condition = (
      toset([for asg in azapi_resource.private_endpoints["with_zone"].body.properties.applicationSecurityGroups : asg.id]) == toset(["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg1"]) &&
      toset([for asg in azapi_resource.private_endpoints["without_zone"].body.properties.applicationSecurityGroups : asg.id]) == toset([
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg1",
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource_group_name/providers/Microsoft.Network/applicationSecurityGroups/asg2",
      ])
    )
  }
  assert {
    error_message = "A DNS zone group should be created only for the endpoint that has private DNS zones"
    condition     = keys(azapi_resource.private_dns_zone_groups) == ["with_zone"]
  }
  assert {
    error_message = "The DNS zone group should default to the name default"
    condition     = azapi_resource.private_dns_zone_groups["with_zone"].name == "default"
  }
  assert {
    error_message = "Each DNS zone configuration should be named after its zone, as the AzureRM provider named them"
    condition     = one(azapi_resource.private_dns_zone_groups["with_zone"].body.properties.privateDnsZoneConfigs).name == "privatelink.vaultcore.azure.net"
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
    condition     = length(azapi_resource.private_endpoints) == 0
  }
  assert {
    error_message = "Both endpoints should be created by the unmanaged resource"
    condition     = toset(keys(azapi_resource.private_endpoints_unmanaged_dns_zone_groups)) == toset(["with_zone", "without_zone"])
  }
  assert {
    error_message = "No DNS zone group should be created when the zone groups are managed elsewhere"
    condition     = length(azapi_resource.private_dns_zone_groups) == 0
  }
}
