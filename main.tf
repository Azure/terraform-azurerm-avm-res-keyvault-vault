resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.keyvault_vaults
  body = {
    properties = {
      # A PUT resets every property it omits, so the access policies are always sent. When RBAC
      # authorization is in use the module does not manage them, and the placeholder below is ignored
      # (see `ignore_body_changes`) so the provider re-reads the vault and sends the live values
      # instead of clearing policies another configuration may have set.
      accessPolicies = [
        for key, policy in local.legacy_access_policies : {
          applicationId = policy.application_id
          objectId      = policy.object_id
          permissions = {
            certificates = tolist(policy.certificate_permissions)
            keys         = tolist(policy.key_permissions)
            secrets      = tolist(policy.secret_permissions)
            storage      = tolist(policy.storage_permissions)
          }
          tenantId = var.tenant_id
        }
      ]
      enabledForDeployment         = var.enabled_for_deployment
      enabledForDiskEncryption     = var.enabled_for_disk_encryption
      enabledForTemplateDeployment = var.enabled_for_template_deployment
      # Azure rejects `false`: the property is write-once and cannot be turned off again.
      enablePurgeProtection   = var.purge_protection_enabled ? true : null
      enableRbacAuthorization = !var.legacy_access_policies_enabled
      networkAcls = var.network_acls == null ? null : {
        bypass        = var.network_acls.bypass
        defaultAction = var.network_acls.default_action
        ipRules       = [for rule in var.network_acls.ip_rules : { value = rule }]
        virtualNetworkRules = [
          for subnet_id in var.network_acls.virtual_network_subnet_ids : { id = subnet_id }
        ]
      }
      publicNetworkAccess       = var.public_network_access_enabled ? "Enabled" : "Disabled"
      sku                       = { family = "A", name = var.sku_name }
      softDeleteRetentionInDays = var.soft_delete_retention_days
      tenantId                  = var.tenant_id
    }
  }
  ignore_body_changes = length(local.keyvault_vaults_ignore_body_changes) > 0 ? local.keyvault_vaults_ignore_body_changes : null
  # Properties the caller leaves unset are not managed, so Azure's own defaults (for example a 90 day
  # soft delete retention, or purge protection left off) do not read back as a permanent difference.
  ignore_null_property   = true
  response_export_values = ["properties.vaultUri"]
  retry                  = var.retry
  tags                   = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

moved {
  from = azurerm_key_vault.this
  to   = azapi_resource.this
}

# Access policies are part of the vault's body from this version. Azure models them as an operation
# on the vault rather than as addressable child resources, so there is no address to move the old
# per-policy resources to. They are dropped from the state without being deleted, and the vault keeps
# the policies themselves, so no manual state surgery is needed to upgrade.
removed {
  from = azurerm_key_vault_access_policy.this

  lifecycle {
    destroy = false
  }
}

# Role definitions are resolved here, case-insensitively as the AzureRM provider did, rather than by
# the interfaces module, whose lookup is case-sensitive. They are listed in the resource group rather
# than on the key vault, so the lookup does not wait for pending changes to the key vault and a role
# name that does not exist fails during plan.
data "azapi_resource_list" "role_definitions" {
  count = length(var.role_assignments) > 0 ? 1 : 0

  parent_id = var.parent_id
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}

module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.7.0"

  enable_telemetry                          = var.enable_telemetry
  role_assignment_definition_lookup_enabled = false
  role_assignments                          = local.role_assignments
}

resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.name}")
  parent_id = azapi_resource.this.id
  type      = var.resource_types.authorization_locks
  body = {
    properties = {
      level = var.lock.kind
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  # Create the lock last and remove it first. A ReadOnly lock blocks changes to the child resources.
  depends_on = [time_sleep.lock_removal]
}

# Azure keeps enforcing a deleted lock for a few seconds, and the AzureRM provider waited for the lock
# to be gone before it continued. This pause does the same: it is destroyed after the lock and before
# the key vault and the resources under it, so they are not deleted while the lock still applies.
resource "time_sleep" "lock_removal" {
  count = var.lock != null ? 1 : 0

  destroy_duration = "30s"

  depends_on = [
    azapi_resource.diagnostic_settings,
    azapi_resource.role_assignments,
    azapi_resource.this,
  ]
}

moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.lock
}

resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  name                 = module.avm_interfaces.role_assignments_azapi[each.key].name
  parent_id            = azapi_resource.this.id
  type                 = var.resource_types.authorization_role_assignments
  body                 = module.avm_interfaces.role_assignments_azapi[each.key].body
  ignore_body_changes  = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  ignore_casing        = true
  ignore_null_property = true
  # The AzureRM provider replaced a role assignment whenever one of its inputs changed. The inputs are
  # compared, rather than body paths or the resolved role definition ID: Azure normalises role
  # definition IDs, and the role definition lookup is deferred to apply whenever the resource group is
  # not yet known. While the prior value is null, as it is straight after upgrading from AzureRM,
  # nothing is replaced.
  replace_triggers_external_values = {
    condition                              = each.value.condition
    condition_version                      = each.value.condition_version
    delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
    description                            = each.value.description
    principal_id                           = lower(each.value.principal_id)
    principal_type                         = local.role_assignments[each.key].principal_type
    role_definition_id_or_name             = lower(each.value.role_definition_id_or_name)
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    # Upgraded assignments keep the GUID azurerm generated, while the interfaces module generates a
    # new one. Replacing the assignment would fail with ScopeLocked under a CanNotDelete lock.
    ignore_changes = [name]

    precondition {
      condition     = strcontains(lower(local.role_assignments[each.key].role_definition_id_or_name), local.role_definition_resource_substring)
      error_message = "The role definition `${each.value.role_definition_id_or_name}` was not found in the resource group. Use the name of a role definition that can be assigned there, or the role definition's resource ID."
    }
  }
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}

resource "azapi_resource" "diagnostic_settings" {
  for_each = var.diagnostic_settings

  name      = each.value.name != null ? each.value.name : "diag-${var.name}"
  parent_id = azapi_resource.this.id
  type      = var.resource_types.insights_diagnostic_settings
  body = {
    properties = {
      eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
      eventHubName                = each.value.event_hub_name
      # This module has always sent "Dedicated" as null, which leaves the choice to Azure.
      logAnalyticsDestinationType = each.value.log_analytics_destination_type == "Dedicated" ? null : each.value.log_analytics_destination_type
      # Azure echoes every category or category group it offers, including the ones that are switched
      # off, so the full set is sent with explicit flags. Sending only the enabled entries leaves the
      # disabled ones in the response and reports a difference on every plan. Groups and individual
      # categories cannot be combined in one diagnostic setting, so only the dimension the caller
      # uses is expanded.
      logs = tolist(concat(
        [for group in local.available_log_category_groups : {
          category      = null
          categoryGroup = group
          enabled       = contains(each.value.log_groups, group)
        } if length(each.value.log_groups) > 0],
        [for category in local.available_log_categories : {
          category      = category
          categoryGroup = null
          enabled       = contains(each.value.log_categories, category)
        } if length(each.value.log_categories) > 0],
      ))
      marketplacePartnerId = each.value.marketplace_partner_resource_id
      metrics = tolist([for category in local.available_metric_categories : {
        category = category
        enabled  = contains(each.value.metric_categories, category)
      }])
      storageAccountId = each.value.storage_account_resource_id
      workspaceId      = each.value.workspace_resource_id
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.insights_diagnostic_settings) > 0 ? var.ignore_body_changes.insights_diagnostic_settings : null
  # Azure picks its own destination type when none is requested.
  ignore_null_property   = true
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

moved {
  from = azurerm_monitor_diagnostic_setting.this
  to   = azapi_resource.diagnostic_settings
}

# The categories and category groups a key vault offers. Azure echoes all of them in a diagnostic
# setting, so the module needs the full set to send explicit enabled flags for each one.
data "azapi_resource_list" "diagnostic_categories" {
  count = length(var.diagnostic_settings) > 0 ? 1 : 0

  parent_id = azapi_resource.this.id
  type      = "Microsoft.Insights/diagnosticSettingsCategories@2021-05-01-preview"
  response_export_values = {
    categories = "value[].{name: name, category_type: properties.categoryType, groups: properties.categoryGroups}"
  }
}

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

  depends_on = [azapi_resource.role_assignments]
}
