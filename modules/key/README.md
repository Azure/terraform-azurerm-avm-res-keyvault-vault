<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-keyvault-vault//key

Module to deploy key vault keys.

```hcl
resource "azurerm_key_vault_key" "this" {
  key_opts        = var.opts
  key_type        = var.type
  key_vault_id    = var.key_vault_resource_id
  name            = var.name
  curve           = var.curve
  expiration_date = var.expiration_date
  key_size        = var.size
  not_before_date = var.not_before_date
  tags            = var.tags

  dynamic "rotation_policy" {
    for_each = var.rotation_policy != null ? [var.rotation_policy] : []
    content {
      expire_after         = rotation_policy.value.expire_after
      notify_before_expiry = rotation_policy.value.notify_before_expiry

      automatic {
        time_before_expiry = rotation_policy.value.automatic.time_before_expiry
      }
    }
  }
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_key_vault_key.this.resource_versionless_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.6)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.71)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.71)

## Resources

The following resources are used by this module:

- [azurerm_key_vault_key.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_key_vault_resource_id"></a> [key\_vault\_resource\_id](#input\_key\_vault\_resource\_id)

Description: The ID of the Key Vault where the key should be created.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the key.

Type: `string`

### <a name="input_type"></a> [type](#input\_type)

Description: The type of the key. Possible values are `EC` and `RSA`.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_curve"></a> [curve](#input\_curve)

Description: The curve of the EC key. Required if `type` is `EC`. Possible values are `P-256`, `P-256K`, `P-384`, and `P-521`. This field will be required in a future release if key\_type is EC or EC-HSM. The API will default to `P-256` if nothing is specified.

Type: `string`

Default: `null`

### <a name="input_expiration_date"></a> [expiration\_date](#input\_expiration\_date)

Description: The expiration date of the key as a UTC datetime (Y-m-d'T'H:M:S'Z').

Type: `string`

Default: `null`

### <a name="input_not_before_date"></a> [not\_before\_date](#input\_not\_before\_date)

Description: key not usable before as a UTC datetime (Y-m-d'T'H:M:S'Z').

Type: `string`

Default: `null`

### <a name="input_opts"></a> [opts](#input\_opts)

Description: The options to apply to the key. Possible values are `decrypt`, `encrypt`, `sign`, `wrapKey`, `unwrapKey`, and `verify`.

Type: `list(string)`

Default: `[]`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: A map of role assignments to create on the key. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. If you are using a condition, valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_rotation_policy"></a> [rotation\_policy](#input\_rotation\_policy)

Description: The rotation policy of the key:

- `automatic` - The automatic rotation policy of the key.
  - `time_after_creation` - The time after creation of the key before it is automatically rotated as an ISO 8601 duration.
  - `time_before_expiry` - The time before expiry of the key before it is automatically rotated as an ISO 8601 duration.
- `expire_after` - The time after which the key expires.
- `notify_before_expiry` - The time before expiry of the key when notification emails will be sent as an ISO 8601 duration.

Type:

```hcl
object({
    automatic = optional(object({
      time_after_creation = optional(string, null)
      time_before_expiry  = optional(string, null)
    }), null)
    expire_after         = optional(string, null)
    notify_before_expiry = optional(string, null)
  })
```

Default: `null`

### <a name="input_size"></a> [size](#input\_size)

Description: The size of the RSA key. Required if `type` is `RSA` or `RSA-HSM`.

Type: `number`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: The tags to assign to the key.

Type: `map(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_id"></a> [id](#output\_id)

Description: The Key Vault Key ID

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The Azure resource id of the secret.

### <a name="output_resource_versionless_id"></a> [resource\_versionless\_id](#output\_resource\_versionless\_id)

Description: The versionless Azure resource id of the secret.

### <a name="output_versionless_id"></a> [versionless\_id](#output\_versionless\_id)

Description: The Base ID of the Key Vault Key

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->