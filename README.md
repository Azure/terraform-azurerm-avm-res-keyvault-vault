<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-keyvault-vault

Module to deploy key vaults, keys and secrets in Azure.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.71.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

- <a name="requirement_time"></a> [time](#requirement\_time) (>= 0.9.1)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (3.71.0)

- <a name="provider_random"></a> [random](#provider\_random) (3.5.1)

- <a name="provider_time"></a> [time](#provider\_time) (0.9.1)

## Resources

The following resources are used by this module:

- [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_key_vault_key.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key) (resource)
- [azurerm_key_vault_secret.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [azurerm_role_assignment.keys](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.secrets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [random_id.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)
- [time_sleep.wait_for_rbac_before_key_operations](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [time_sleep.wait_for_rbac_before_secret_operations](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: The Azure location where the resources will be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the Key Vault.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

### <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id)

Description: The Azure tenant ID used for authenticating requests to Key Vault. You can use the `azurerm_client_config` data source to retrieve it.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_contacts"></a> [contacts](#input\_contacts)

Description: A map of contacts for the Key Vault. The map key is deliberately arbitrary to avoid issues where may keys maybe unknown at plan time.

Type:

```hcl
map(object({
    email = string
    name  = optional(string, null)
    phone = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetry.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_enabled_for_deployment"></a> [enabled\_for\_deployment](#input\_enabled\_for\_deployment)

Description: Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the vault.

Type: `bool`

Default: `false`

### <a name="input_enabled_for_disk_encryption"></a> [enabled\_for\_disk\_encryption](#input\_enabled\_for\_disk\_encryption)

Description: Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.

Type: `bool`

Default: `false`

### <a name="input_enabled_for_template_deployment"></a> [enabled\_for\_template\_deployment](#input\_enabled\_for\_template\_deployment)

Description: Specifies whether Azure Resource Manager is permitted to retrieve secrets from the vault.

Type: `bool`

Default: `false`

### <a name="input_keys"></a> [keys](#input\_keys)

Description: A map of keys to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where may keys maybe unknown at plan time.

- `name` - The name of the key.
- `key_type` - The type of the key. Possible values are `EC` and `RSA`.
- `key_opts` - A list of key options. Possible values are `decrypt`, `encrypt`, `sign`, `unwrapKey`, `verify`, and `wrapKey`.
- `key_size` - The size of the key. Required for `RSA` keys.
- `curve` - The curve of the key. Required for `EC` keys.  Possible values are `P-256`, `P-256K`, `P-384`, and `P-521`. The API will default to `P-256` if nothing is specified.
- `not_before_date` - The not before date of the key.
- `expiration_date` - The expiration date of the key.
- `tags` - A mapping of tags to assign to the key.
- `rotation_policy` - The rotation policy of the key.
  - `automatic` - The automatic rotation policy of the key.
    - `time_after_creation` - The time after creation of the key before it is automatically rotated.
    - `time_before_expiry` - The time before expiry of the key before it is automatically rotated.
  - `expire_after` - The time after which the key expires.
  - `notify_before_expiry` - The time before expiry of the key when notification emails will be sent.

Supply role assignments in the same way as for `var.role_assignments`.

Type:

```hcl
map(object({
    name     = string
    key_type = string
    key_opts = optional(list(string), ["sign", "verify"])

    key_size        = optional(number, null)
    curve           = optional(string, null)
    not_before_date = optional(string, null)
    expiration_date = optional(string, null)
    tags            = optional(map(any), null)

    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})

    rotation_policy = optional(object({
      automatic = optional(object({
        time_after_creation = optional(string, null)
        time_before_expiry  = optional(string, null)
      }), null)
      expire_after         = optional(string, null)
      notify_before_expiry = optional(string, null)
    }), null)
  }))
```

Default: `{}`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: The lock level to apply to the Key Vault. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.

Type:

```hcl
object({
    name = optional(string, null)
    kind = optional(string, "None")
  })
```

Default: `{}`

### <a name="input_network_acls"></a> [network\_acls](#input\_network\_acls)

Description: n/a

Type:

```hcl
object({
    bypass                     = optional(string, "None")
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
```

Default: `null`

### <a name="input_private_endpoints"></a> [private\_endpoints](#input\_private\_endpoints)

Description: n/a

Type:

```hcl
map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
    lock = optional(object({
      name = optional(string, null)
      kind = optional(string, "None")
    }), {})
    tags                                    = optional(map(any), null)
    subnet_resource_id                      = string
    private_dns_zone_group_name             = optional(string, null)
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_resource_ids = optional(set(string), [])
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
```

Default: `{}`

### <a name="input_purge_protection_enabled"></a> [purge\_protection\_enabled](#input\_purge\_protection\_enabled)

Description: Specifies whether protection against purge is enabled for this Key Vault. Note once enabled this cannot be disabled.

Type: `bool`

Default: `true`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: A map of role assignments to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where may keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

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
  }))
```

Default: `{}`

### <a name="input_secrets"></a> [secrets](#input\_secrets)

Description: A map of secrets to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where may keys maybe unknown at plan time.

- `name` - The name of the secret.
- `content_type` - The content type of the secret.
- `tags` - A mapping of tags to assign to the secret.
- `not_before_date` - The not before date of the secret.
- `expiration_date` - The expiration date of the secret.

Supply role assignments in the same way as for `var.role_assignments`.

> Note: the `value` of the secret is supplied via the `var.secrets_value` variable. Make sure to use the same map key.

Type:

```hcl
map(object({
    name            = string
    content_type    = optional(string, null)
    tags            = optional(map(any), null)
    not_before_date = optional(string, null)
    expiration_date = optional(string, null)

    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
  }))
```

Default: `{}`

### <a name="input_secrets_value"></a> [secrets\_value](#input\_secrets\_value)

Description: A map of secret keys to values.  
The map key is the supplied input to var.secrets.  
The map value is the secret value.

This is a separate variable to var.secrets because it is sensitive and therefore cannot be used in a for\_each loop.

Type: `map(string)`

Default: `{}`

### <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name)

Description: The SKU name of the Key Vault. Possible values are `standard` and `premium`.

Type: `string`

Default: `"standard"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Map of tags to assign to the Key Vault resource.

Type: `map(any)`

Default: `null`

### <a name="input_wait_for_rbac_before_key_operations"></a> [wait\_for\_rbac\_before\_key\_operations](#input\_wait\_for\_rbac\_before\_key\_operations)

Description: This variable controls the amount of time to wait before performing key operations.  
It only applies when `var.role_assignments` and `var.keys` are both set.  
This is useful when you are creating role assignments on the key vault and immediately creating keys in it.  
The default is 30 seconds for create and 0 seconds for destroy.

Type:

```hcl
object({
    create  = optional(string, "30s")
    destroy = optional(string, "0s")
  })
```

Default: `{}`

### <a name="input_wait_for_rbac_before_secret_operations"></a> [wait\_for\_rbac\_before\_secret\_operations](#input\_wait\_for\_rbac\_before\_secret\_operations)

Description: This variable controls the amount of time to wait before performing secret operations.  
It only applies when `var.role_assignments` and `var.secrets` are both set.  
This is useful when you are creating role assignments on the key vault and immediately creating secrets in it.  
The default is 30 seconds for create and 0 seconds for destroy.

Type:

```hcl
object({
    create  = optional(string, "30s")
    destroy = optional(string, "0s")
  })
```

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_private_endpoints"></a> [private\_endpoints](#output\_private\_endpoints)

Description: A map of private endpoints. The map key is the supplied input to var.private\_endpoints. The map value is the entire azurerm\_private\_endpoint resource.

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The Key Vault resource.

### <a name="output_resource_keys"></a> [resource\_keys](#output\_resource\_keys)

Description: A map of key objects. The map key is the supplied input to var.keys. The map value is the entire azurerm\_key\_vault\_key resource.

### <a name="output_resource_secrets"></a> [resource\_secrets](#output\_resource\_secrets)

Description: A map of secret objects. The map key is the supplied input to var.secrets. The map value is the entire azurerm\_key\_vault\_secret resource.

## Modules

No modules.


<!-- END_TF_DOCS -->