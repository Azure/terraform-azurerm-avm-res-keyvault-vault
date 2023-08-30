<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-keyvault-vault

Module to deploy key vaults in Azure.

> Note this module does not support access policies and requires authorization by Azure role assignment.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.71.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (3.71.0)

- <a name="provider_random"></a> [random](#provider\_random) (3.5.1)

## Resources

The following resources are used by this module:

- [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [random_id.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)

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

### <a name="input_network_acls"></a> [network\_acls](#input\_network\_acls)

Description: n/a

Type:

```hcl
optional(object({
    bypass                     = optional(string, "None")
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  }), {})
```

Default: `{}`

### <a name="input_purge_protection_enabled"></a> [purge\_protection\_enabled](#input\_purge\_protection\_enabled)

Description: Specifies whether protection against purge is enabled for this Key Vault. Note once enabled this cannot be disabled.

Type: `bool`

Default: `true`

### <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name)

Description: The SKU name of the Key Vault. Possible values are `standard` and `premium`.

Type: `string`

Default: `"standard"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Map of tags to assign to the Key Vault resource.

Type: `map(any)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_id"></a> [id](#output\_id)

Description: The Azure resource id of the Key Vault.

### <a name="output_uri"></a> [uri](#output\_uri)

Description: The URI of the Key Vault, used for performing operations on keys and secrets.

## Modules

No modules.


<!-- END_TF_DOCS -->