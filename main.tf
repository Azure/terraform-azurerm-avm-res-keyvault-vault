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

resource "azapi_resource" "management_lock" {
  count = var.lock != null ? 1 : 0

  type      = "Microsoft.Authorization/locks@2020-05-01"
  name      = coalesce(var.lock.name, "lock-${var.name}")
  parent_id = azapi_resource.this.id

  body = {
    properties = {
      level = var.lock.kind
      notes = "Managed by Terraform - Key Vault resource lock"
    }
  }

  depends_on = [azapi_resource.this]
}

resource "azapi_resource" "role_assignment" {
  for_each = var.role_assignments

  type = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name = uuidv5("oid", "${each.value.principal_id}-${azapi_resource.this.id}-${strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : data.azurerm_role_definition.this[each.key].id}")
  parent_id = azapi_resource.this.id

  body = {
    properties = {
      principalId      = each.value.principal_id
      principalType    = each.value.principal_type
      roleDefinitionId = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : data.azurerm_role_definition.this[each.key].id
      condition        = each.value.condition
      conditionVersion = each.value.condition_version
      delegatedManagedIdentityResourceId = each.value.delegated_managed_identity_resource_id
    }
  }

  depends_on = [azapi_resource.this]
}

# Data source to get role definition ID when role definition name is provided
data "azurerm_role_definition" "this" {
  for_each = { for k, v in var.role_assignments : k => v if !strcontains(lower(v.role_definition_id_or_name), lower(local.role_definition_resource_substring)) }
  
  name  = each.value.role_definition_id_or_name
  scope = azapi_resource.this.id
}

resource "azapi_resource" "diagnostic_setting" {
  for_each = var.diagnostic_settings

  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
  name      = each.value.name != null ? each.value.name : "diag-${var.name}"
  parent_id = azapi_resource.this.id

  body = jsonencode({
    properties = {
      eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
      eventHubName                = each.value.event_hub_name
      logAnalyticsDestinationType = each.value.log_analytics_destination_type
      workspaceId                 = each.value.workspace_resource_id
      marketplacePartnerId        = each.value.marketplace_partner_resource_id
      storageAccountId            = each.value.storage_account_resource_id
      logs = concat(
        [for category in each.value.log_categories : {
          category = category
          enabled  = true
        }],
        [for group in each.value.log_groups : {
          categoryGroup = group
          enabled       = true
        }]
      )
      metrics = [for category in each.value.metric_categories : {
        category = category
        enabled  = true
      }]
    }
  })
}

# Certificate contacts are handled via azapi_update_resource to update the Key Vault's certificateContacts property
resource "azapi_update_resource" "certificate_contacts" {
  count = length(var.contacts) > 0 ? 1 : 0

  type        = "Microsoft.KeyVault/vaults@2023-07-01"
  resource_id = azapi_resource.this.id

  body = {
    properties = {
      certificateContacts = [
        for contact in var.contacts : {
          email = contact.email
          name  = contact.name
          phone = contact.phone
        }
      ]
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

  depends_on = [azapi_resource.role_assignment]
}
