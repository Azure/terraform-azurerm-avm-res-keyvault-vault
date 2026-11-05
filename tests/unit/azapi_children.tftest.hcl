mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
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
        results = [
          {
            id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/11111111-1111-1111-1111-111111111111"
            role_name = "Key Vault Secrets User"
          },
          {
            id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/33333333-3333-3333-3333-333333333333"
            role_name = "Key Vault Crypto User"
          },
        ]
      }
    }
  }
}
mock_provider "azurerm" {
  mock_resource "azurerm_key_vault_key" {
    defaults = {
      resource_versionless_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test/keys/cmk"
    }
  }
  mock_resource "azurerm_key_vault_secret" {
    defaults = {
      resource_versionless_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test/secrets/app"
    }
  }
}
mock_provider "random" {}
mock_provider "time" {}

variables {
  enable_telemetry = false
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test"
  name             = "test"
  location         = "eastus"
  tenant_id        = "00000000-0000-0000-0000-000000000000"
}

run "certificate_contacts_use_data_plane" {
  command = apply

  variables {
    contacts = {
      first = {
        email = "first@contoso.com"
        name  = "First"
      }
      second = {
        email = "second@contoso.com"
        phone = "0123456789"
      }
    }
  }

  assert {
    condition     = azapi_data_plane_resource.certificate_contacts[0].parent_id == "test.vault.azure.net"
    error_message = "Certificate contacts MUST target the vault's data plane host."
  }

  assert {
    condition     = azapi_data_plane_resource.certificate_contacts[0].type == "Microsoft.KeyVault/vaults/certificates/contacts@7.4"
    error_message = "Certificate contacts MUST use the type from var.resource_types."
  }

  assert {
    condition     = length(azapi_data_plane_resource.certificate_contacts[0].body.contacts) == 2
    error_message = "Every contact MUST be sent in the body."
  }
}

run "certificate_contacts_absent" {
  command = plan

  assert {
    condition     = length(azapi_data_plane_resource.certificate_contacts) == 0
    error_message = "No certificate contacts resource MUST be planned when var.contacts is empty."
  }
}

run "key_role_assignment_by_name" {
  command = apply

  module {
    source = "./modules/key"
  }

  variables {
    key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
    name                  = "cmk"
    type                  = "RSA"
    size                  = 2048
    role_assignments = {
      crypto = {
        role_definition_id_or_name = "Key Vault Crypto User"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["crypto"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/33333333-3333-3333-3333-333333333333"
    error_message = "Key role assignments MUST resolve the role name to its definition ID."
  }
}

run "secret_role_assignment_by_name" {
  command = apply

  module {
    source = "./modules/secret"
  }

  variables {
    key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
    name                  = "app"
    value                 = "value"
    role_assignments = {
      reader = {
        role_definition_id_or_name = "Key Vault Secrets User"
        principal_id               = "00000000-0000-0000-0000-000000000002"
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["reader"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/11111111-1111-1111-1111-111111111111"
    error_message = "Secret role assignments MUST resolve the role name to its definition ID."
  }
}
