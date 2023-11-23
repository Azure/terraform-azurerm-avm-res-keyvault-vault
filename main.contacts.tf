resource "azurerm_key_vault_certificate_contacts" "this" {
  count        = length(var.contacts) > 0 ? 1 : 0
  key_vault_id = azurerm_key_vault.this.id

  dynamic "contact" {
    for_each = var.contacts
    content {
      email = contact.value.email_address
      name  = contact.value.name
      phone = contact.value.phone
    }
  }

  depends_on = [time_sleep.wait_for_rbac_before_contact_operations]
}

resource "time_sleep" "wait_for_rbac_before_contact_operations" {
  count = length(var.role_assignments) > 0 && length(var.contacts) > 0 ? 1 : 0
  depends_on = [
    azurerm_role_assignment.this
  ]
  create_duration  = var.wait_for_rbac_before_contact_operations.create
  destroy_duration = var.wait_for_rbac_before_contact_operations.destroy

  triggers = {
    role_assignments = jsonencode(var.role_assignments)
  }
}
