variable "parent_id" {
  type        = string
  description = "The resource ID of the Key Vault where the secret should be created."
  nullable    = false

  validation {
    error_message = "Value must be a valid Azure Key Vault resource ID."
    condition     = can(regex("\\/subscriptions\\/[a-f\\d]{4}(?:[a-f\\d]{4}-){4}[a-f\\d]{12}\\/resourceGroups\\/[^\\/]+\\/providers\\/Microsoft.KeyVault\\/vaults\\/[^\\/]+$", var.parent_id))
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
  default     = null

  validation {
    error_message = "One of `value` or `value_wo` must be set."
    condition     = var.value != null || var.value_wo != null
  }
}

variable "value_wo" {
  type        = string
  description = "The write-only value for the secret. This value is ephemeral and will not be stored in the state file."
  ephemeral   = true
  default     = null
}

variable "content_type" {
  type        = string
  default     = null
  description = "The content type of the secret."
}

variable "expiration_date" {
  type        = string
  default     = null
  description = "The expiration date of the secret as a RFC 3339 UTC datetime (Y-m-d'T'H:M:S'Z')."

  validation {
    error_message = "Value must be a RFC 3339 UTC datetime (Y-m-d'T'H:M:S'Z')."
    condition     = var.expiration_date == null || can(provider::time::rfc3339_parse(var.expiration_date))
  }
}

variable "not_before_date" {
  type        = string
  default     = null
  description = "Secret not usable before as a RFC 3339 UTC datetime (Y-m-d'T'H:M:S'Z')."

  validation {
    error_message = "Value must be a RFC 3339 UTC datetime (Y-m-d'T'H:M:S'Z')."
    condition     = var.not_before_date == null || can(provider::time::rfc3339_parse(var.not_before_date))
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
