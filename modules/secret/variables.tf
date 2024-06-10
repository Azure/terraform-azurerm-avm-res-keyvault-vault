variable "key_vault_resource_id" {
  type        = string
  description = "The ID of the Key Vault where the secret should be created."
  nullable    = false

  validation {
    error_message = "Value must be a valid Azure Key Vault resource ID."
    condition     = can(regex("\\/subscriptions\\/[a-f\\d]{4}(?:[a-f\\d]{4}-){4}[a-f\\d]{12}\\/resourceGroups\\/[^\\/]+\\/providers\\/Microsoft.KeyVault\\/vaults\\/[^\\/]+$", var.key_vault_resource_id))
  }
}

variable "name" {
  type        = string
  description = "The name of the secret."
  nullable    = false

  validation {
    error_message = "Secret names may only contain alphanumerics and hyphens, and be between 1 and 127 characters in length."
    condition     = can(regex("^[A-Za-z0-9-]{1,127}$", var.name))
  }
}

variable "value" {
  type        = string
  description = "The value for the secret."
  sensitive   = true
}

variable "content_type" {
  type        = string
  default     = null
  description = "The content type of the secret."
}

variable "expiration_date" {
  type        = string
  default     = null
  description = "The expiration date of the secret as a UTC datetime (Y-m-d'T'H:M:S'Z')."

  validation {
    error_message = "Value must be a UTC datetime (Y-m-d'T'H:M:S'Z')."
    condition     = var.expiration_date == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", var.expiration_date))
  }
}

variable "not_before_date" {
  type        = string
  default     = null
  description = "Secret not usable before as a UTC datetime (Y-m-d'T'H:M:S'Z')."

  validation {
    error_message = "Value must be a UTC datetime (Y-m-d'T'H:M:S'Z')."
    condition     = var.not_before_date == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", var.not_before_date))
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
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on the secret. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. If you are using a condition, valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "The tags to assign to the secret."
}
