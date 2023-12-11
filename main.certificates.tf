resource "azurerm_key_vault_certificate" "this" {
  for_each     = var.certificates
  name         = each.value.name
  key_vault_id = azurerm_key_vault.this.id

  dynamic "certificate" {
    for_each = each.value.certificate != null ? [1] : []
    content {
      contents = each.value.certificate.contents
      password = lookup(var.certificates_passwords[each.key], null)
    }
  }

  dynamic "certificate_policy" {
    for_each = each.value.policy != null ? [1] : []
    content {
      issuer_parameters {
        name = each.value.policy.issuer_parameters.name
      }
      key_properties {
        exportable = each.value.policy.key_properties.exportable
        key_size   = each.value.policy.key_properties.key_size
        key_type   = each.value.policy.key_properties.key_type
        reuse_key  = each.value.policy.key_properties.reuse_key
        curve      = each.value.policy.key_properties.curve
      }
      secret_properties {
        content_type = each.value.policy.secret_properties.content_type
      }

      dynamic "lifetime_action" {
        for_each = each.value.policy.lifetime_action != null ? [1] : []
        content {
          action {
            action_type = each.value.policy.lifetime_actions.action.action_type
          }
          trigger {
            days_before_expiry  = each.value.policy.lifetime_actions.trigger.days_before_expiry
            lifetime_percentage = each.value.policy.lifetime_actions.trigger.lifetime_percentage
          }
        }
      }

      dynamic "x509_certificate_properties" {
        for_each = each.value.policy.x509_certificate_properties != null ? [1] : []
        content {
          subject            = each.value.policy.x509_certificate_properties.subject
          key_usage          = each.value.policy.x509_certificate_properties.key_usage
          extended_key_usage = each.value.policy.x509_certificate_properties.extended_key_usage
          validity_in_months = each.value.policy.x509_certificate_properties.validity_in_months

          dynamic "subject_alternative_names" {
            for_each = each.value.policy.x509_certificate_properties.subject_alternative_names != null ? [1] : []
            content {
              dns_names = each.value.policy.x509_certificate_properties.subject_alternative_names.dns_names
              emails    = each.value.policy.x509_certificate_properties.subject_alternative_names.emails
              upns      = each.value.policy.x509_certificate_properties.subject_alternative_names.upns
            }
          }
        }
      }
    }
  }
  depends_on = [time_sleep.wait_for_rbac_before_certificate_operations]
}


resource "azurerm_role_assignment" "certificates" {
  for_each                               = local.certificates_role_assignments
  scope                                  = azurerm_key_vault_certificate.this[each.value.certificate_key].resource_manager_versionless_id
  role_definition_id                     = strcontains(lower(each.value.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_assignment.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_assignment.role_definition_id_or_name
  principal_id                           = each.value.role_assignment.principal_id
  condition                              = each.value.role_assignment.condition
  condition_version                      = each.value.role_assignment.condition_version
  skip_service_principal_aad_check       = each.value.role_assignment.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.role_assignment.delegated_managed_identity_resource_id
}

resource "time_sleep" "wait_for_rbac_before_certificate_operations" {
  count = length(var.role_assignments) > 0 && length(var.certificates) > 0 ? 1 : 0
  depends_on = [
    azurerm_role_assignment.this
  ]
  create_duration  = var.wait_for_rbac_before_certificate_operations.create
  destroy_duration = var.wait_for_rbac_before_certificate_operations.destroy

  triggers = {
    role_assignments = jsonencode(var.role_assignments)
  }
}
