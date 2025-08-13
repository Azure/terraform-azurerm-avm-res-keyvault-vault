resource "azapi_resource" "this" {
  type      = "Microsoft.KeyVault/vaults@2023-07-01"
  name      = var.name
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  location  = var.location
  tags      = var.tags

  body = {
    properties = {
      tenantId                    = var.tenant_id
      enableRbacAuthorization     = !var.legacy_access_policies_enabled
      enabledForDeployment        = var.enabled_for_deployment
      enabledForDiskEncryption    = var.enabled_for_disk_encryption
      enabledForTemplateDeployment = var.enabled_for_template_deployment
      publicNetworkAccess         = var.public_network_access_enabled ? "Enabled" : "Disabled"
      enablePurgeProtection       = var.purge_protection_enabled
      softDeleteRetentionInDays   = var.soft_delete_retention_days
      sku = {
        family = "A"
        name   = var.sku_name
      }
      accessPolicies = var.legacy_access_policies_enabled ? [
        for policy in var.legacy_access_policies : {
          tenantId    = var.tenant_id
          objectId    = policy.object_id
          applicationId = policy.application_id
          permissions = {
            certificates = policy.certificate_permissions
            keys         = policy.key_permissions
            secrets      = policy.secret_permissions
            storage      = policy.storage_permissions
          }
        }
      ] : []
      networkAcls = var.network_acls != null ? {
        bypass        = var.network_acls.bypass
        defaultAction = var.network_acls.default_action
        ipRules = [
          for ip in var.network_acls.ip_rules : {
            value = ip
          }
        ]
        virtualNetworkRules = [
          for subnet in var.network_acls.virtual_network_subnet_ids : {
            id = subnet
          }
        ]
      } : null
    }
  }
}

# Data source to get current client configuration
data "azurerm_client_config" "current" {}

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azapi_resource.this.id
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azapi_resource.this.id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  log_analytics_destination_type = each.value.log_analytics_destination_type
  log_analytics_workspace_id     = each.value.workspace_resource_id
  partner_solution_id            = each.value.marketplace_partner_resource_id
  storage_account_id             = each.value.storage_account_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories

    content {
      category = enabled_log.value
    }
  }
  dynamic "enabled_log" {
    for_each = each.value.log_groups

    content {
      category_group = enabled_log.value
    }
  }
  dynamic "metric" {
    for_each = each.value.metric_categories

    content {
      category = metric.value
    }
  }
}

# Certificate contacts are handled via azurerm provider as they are management plane operations
resource "azurerm_key_vault_certificate_contacts" "this" {
  count = length(var.contacts) > 0 ? 1 : 0

  key_vault_id = azapi_resource.this.id

  dynamic "contact" {
    for_each = var.contacts

    content {
      email = contact.value.email
      name  = contact.value.name
      phone = contact.value.phone
    }
  }

  depends_on = [time_sleep.wait_for_rbac_before_contact_operations]
}

resource "time_sleep" "wait_for_rbac_before_contact_operations" {
  count = length(var.contacts) != 0 ? 1 : 0

  create_duration  = var.wait_for_rbac_before_contact_operations.create
  destroy_duration = var.wait_for_rbac_before_contact_operations.destroy
  triggers = {
    contacts = jsonencode(var.contacts)
  }

  depends_on = [azurerm_role_assignment.this]
}
