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
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        categories = [
          { name = "AuditEvent", category_type = "Logs", groups = ["audit", "allLogs"] },
          { name = "AllMetrics", category_type = "Metrics", groups = null },
        ]
      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {}

mock_provider "random" {}

mock_provider "time" {}

variables {
  enable_telemetry = false
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test"
  name             = "test"
  location         = "eastus"
  tenant_id        = "00000000-0000-0000-0000-000000000000"
}

run "subnet_ids_are_sent_in_the_case_azure_returns" {
  command = plan

  variables {
    network_acls = {
      bypass                     = "AzureServices"
      default_action             = "Deny"
      virtual_network_subnet_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/RG-Network/providers/Microsoft.Network/virtualNetworks/VNet/subnets/Apps"]
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkAcls.virtualNetworkRules[0].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/rg-network/providers/microsoft.network/virtualnetworks/vnet/subnets/apps"
    error_message = "Subnet IDs MUST be sent in lower case, the form Azure returns, so that the plan shows no case-only difference."
  }
}

run "dedicated_destination_type_is_sent_as_given" {
  command = plan

  variables {
    diagnostic_settings = {
      audit = {
        log_categories        = ["AuditEvent"]
        log_groups            = []
        metric_categories     = []
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.OperationalInsights/workspaces/law"
      }
    }
  }

  assert {
    condition     = azapi_resource.diagnostic_settings["audit"].body.properties.logAnalyticsDestinationType == "Dedicated"
    error_message = "The default Dedicated destination type MUST be sent, as the AzureRM-based releases did, so that upgrading keeps the log destination."
  }
}
