resource "azapi_resource" "key" {
  name = var.name
  tags = var.tags
  type = "Microsoft.KeyVault/vaults/keys@2023-07-01" 

  properties =   {
    attributes  = {
      enabled = true
      exp = var.expiration_date
      nbf = var.not_before_date
    }
    curveName = var.curve
    keyOps = var.opts
    keySize = var.size
    kty = var.type
    contentType = var.content_type
    value = var.value
    rotation_policy = var.rotation_policy != null ? jsonencode({
      expire_after = var.rotation_policy.expire_after,
      notify_before_expiry = var.rotation_policy.notify_before_expiry,

      automatic = {
        time_before_expiry = var.rotation_policy.automatic.time_before_expiry  
      }
    }) : null,

  }
  parent_id = "${var.key_vault_resource_id}"
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.key.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
