data "azurerm_client_config" "telemetry" {
}

resource "modtm_telemetry" "this" {
  count = var.enable_telemetry ? 1 : 0
  tags = {
    subscription_id = data.azurerm_client_config.telemetry.subscription_id
    tenant_id       = data.azurerm_client_config.telemetry.tenant_id
    module_name     = local.module_name
    module_type     = local.module_type
    module_version  = local.module_version
  }
}

removed {
  from = azurerm_resource_group_template_deployment.telemetry
  lifecycle {
    destroy = false
  }
}
