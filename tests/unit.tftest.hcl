mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

variables {
  enable_telemetry = false
}


run "default" {
  variables {
    name                = "test"
    location            = "test"
    resource_group_name = "test"
    tenant_id           = "00000000-0000-0000-0000-000000000000"
  }
}
