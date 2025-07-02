<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-keyvault-vault//secret

Module to deploy key vault secrets in Azure.

```hcl
# moved {
#   from = azurerm_key_vault_secret.this
#   to   = azapi_resource.this
# }

resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.key_vault_resource_id
  type      = "Microsoft.KeyVault/vaults/secrets@2024-11-01"
  body = {
    properties = {
      attributes = {
        enabled = var.enabled
        exp     = var.expiration_date != null ? provider::time::rfc3339_parse(var.expiration_date).unix : null
        nbf     = var.not_before_date != null ? provider::time::rfc3339_parse(var.not_before_date).unix : null
      }
      contentType = var.content_type
    }
  }
  response_export_values = [
    "properties.secretUri",
    "properties.secretUriWithVersion",
  ]
  sensitive_body = {
    properties = {
      value = coalesce(var.value_wo, var.value)
    }
  }
  sensitive_body_version = {
    "properties.value" = var.value_wo_version
  }
  tags = var.tags
}

module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.3.0"

  role_assignment_definition_lookup_enabled = var.role_definition_lookup_enabled
  role_assignment_definition_scope          = var.key_vault_resource_id
  role_assignment_name_use_random_uuid      = true
  role_assignments                          = var.role_assignments
}

resource "azapi_resource" "role_assignments" {
  for_each = module.avm_interfaces.role_assignments_azapi

  name      = each.value.name
  parent_id = azapi_resource.this.id
  type      = each.value.type
  body      = each.value.body
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.5)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.13)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 2.5)

## Resources

The following resources are used by this module:

- [azapi_resource.role_assignments](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_key_vault_resource_id"></a> [key\_vault\_resource\_id](#input\_key\_vault\_resource\_id)

Description: The ID of the Key Vault where the secret should be created.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the secret.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_content_type"></a> [content\_type](#input\_content\_type)

Description: The content type of the secret.

Type: `string`

Default: `null`

### <a name="input_enabled"></a> [enabled](#input\_enabled)

Description: Whether the secret is enabled. Defaults to `true`.

Type: `bool`

Default: `true`

### <a name="input_expiration_date"></a> [expiration\_date](#input\_expiration\_date)

Description: The expiration date of the secret as a UTC datetime (Y-m-d'T'H:M:S'Z').

Type: `string`

Default: `null`

### <a name="input_not_before_date"></a> [not\_before\_date](#input\_not\_before\_date)

Description: Secret not usable before as a UTC datetime (Y-m-d'T'H:M:S'Z').

Type: `string`

Default: `null`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: A map of role assignments to create on the secret. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

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

### <a name="input_role_definition_lookup_enabled"></a> [role\_definition\_lookup\_enabled](#input\_role\_definition\_lookup\_enabled)

Description: If set to false, role definition lookup will be disabled. You must then supply only valid role definition IDs in `role_assignments`. Defaults to `true`.

Type: `bool`

Default: `true`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: The tags to assign to the secret.

Type: `map(string)`

Default: `null`

### <a name="input_value"></a> [value](#input\_value)

Description: The value for the secret.

Type: `string`

Default: `null`

### <a name="input_value_wo"></a> [value\_wo](#input\_value\_wo)

Description: Value for the secret, write only attribute. This value will not be stored in state, or returned in the plan or apply output.

Type: `string`

Default: `null`

### <a name="input_value_wo_version"></a> [value\_wo\_version](#input\_value\_wo\_version)

Description: The version of the write-only attribute value. Changing this value will indicate to Terraform that the value has changed, and will trigger an update to the secret.

Type: `string`

Default: `"0"`

## Outputs

The following outputs are exported:

### <a name="output_id"></a> [id](#output\_id)

Description: The Key Vault Secret ID (URI)

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The Azure resource id of the secret.

### <a name="output_versionless_id"></a> [versionless\_id](#output\_versionless\_id)

Description: The Base ID (URI) of the Key Vault Secret

## Modules

The following Modules are called:

### <a name="module_avm_interfaces"></a> [avm\_interfaces](#module\_avm\_interfaces)

Source: Azure/avm-utl-interfaces/azure

Version: 0.3.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->