resource "azurerm_private_endpoint" "this" {
  for_each            = var.private_endpoints
  name                = each.value.name != null ? each.value.name : "pe-${var.name}"
  location            = each.value.location != null ? each.value.location : var.location
  resource_group_name = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id           = each.value.subnet_resource_id

  private_service_connection {
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["vault"]

  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      subresource_name   = "vault"
      member_name        = "vault"
      private_ip_address = ip_configuration.value.private_ip_address
    }
  }
}
