variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetry.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "name" {
  type        = string
  description = "The name of the Key Vault."
  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.name))
    error_message = "The name must be between 3 and 24 characters long and can only contain lowercase letters, numbers and dashes."
  }
}

variable "location" {
  type        = string
  description = "The Azure location where the resources will be deployed."
}

variable "sku_name" {
  type        = string
  description = "The SKU name of the Key Vault. Possible values are `standard` and `premium`."
  default     = "standard"
  validation {
    condition     = can(regex("^standard$|^premium$", var.sku_name))
    error_message = "The SKU name must be either `standard` or `premium`."
  }
}

variable "enabled_for_disk_encryption" {
  type        = bool
  description = "Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys."
  default     = false
}

variable "enabled_for_deployment" {
  type        = bool
  description = "Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the vault."
  default     = false
}

variable "enabled_for_template_deployment" {
  type        = bool
  description = "Specifies whether Azure Resource Manager is permitted to retrieve secrets from the vault."
  default     = false
}

variable "tenant_id" {
  type        = string
  description = "The Azure tenant ID used for authenticating requests to Key Vault. You can use the `azurerm_client_config` data source to retrieve it."
  validation {
    condition     = can(regex("^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$", var.tenant_id))
    error_message = "The tenant ID must be a valid GUID."
  }
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Specifies whether protection against purge is enabled for this Key Vault. Note once enabled this cannot be disabled."
  default     = true
}

variable "tags" {
  type        = map(any)
  description = "Map of tags to assign to the Key Vault resource."
  default     = {}
}

variable "contacts" {
  type = map(object({
    email = string
    name  = optional(string, null)
    phone = optional(string, null)
  }))
  description = "A map of contacts for the Key Vault. The map key is deliberately arbitrary to avoid issues where may keys maybe unknown at plan time."
  default     = {}
}

variable "network_acls" {
  type = object({
    bypass                     = optional(string, "None")
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default  = null
  nullable = true

  validation {
    condition     = var.network_acls == null || can(regex("^AzureServices$|^None$", var.network_acls.bypass))
    error_message = "The bypass value must be either `AzureServices` or `None`."
  }

  validation {
    condition     = var.network_acls == null || can(regex("^Allow$|^Deny$", var.network_acls.default_action))
    error_message = "The default_action value must be either `Allow` or `Deny`."
  }
}

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = optional(string, "None")
  })
  description = "The lock level to apply to the Key Vault. Possible values are `CanNotDelete` and `ReadOnly`. Leave blank to not apply a lock."
  default     = {}
  validation {
    condition     = can(regex("^CanNotDelete$|^ReadOnly$|^None$", var.lock.kind))
    error_message = "The lock level must be either `\"None\"`, `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where may keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
}
