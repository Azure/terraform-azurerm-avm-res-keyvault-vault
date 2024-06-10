variable "key_vault_resource_id" {
  type        = string
  description = "The ID of the Key Vault where the key should be created."
  nullable    = false

  validation {
    error_message = "Value must be a valid Azure Key Vault resource ID."
    condition     = can(regex("\\/subscriptions\\/[a-f\\d]{4}(?:[a-f\\d]{4}-){4}[a-f\\d]{12}\\/resourceGroups\\/[^\\/]+\\/providers\\/Microsoft.KeyVault\\/vaults\\/[^\\/]+$", var.key_vault_resource_id))
  }
}

variable "name" {
  type        = string
  description = "The name of the key."
  nullable    = false
}

variable "type" {
  type        = string
  description = "The type of the key. Possible values are `EC` and `RSA`."
  nullable    = false
}

variable "curve" {
  type        = string
  default     = null
  description = "The curve of the EC key. Required if `type` is `EC`. Possible values are `P-256`, `P-256K`, `P-384`, and `P-521`. This field will be required in a future release if key_type is EC or EC-HSM. The API will default to `P-256` if nothing is specified."
}

variable "expiration_date" {
  type        = string
  default     = null
  description = "The expiration date of the key as a UTC datetime (Y-m-d'T'H:M:S'Z')."

  validation {
    error_message = "Value must be a UTC datetime (Y-m-d'T'H:M:S'Z')."
    condition     = var.expiration_date == null ? true : can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", var.expiration_date))
  }
}

variable "not_before_date" {
  type        = string
  default     = null
  description = "key not usable before as a UTC datetime (Y-m-d'T'H:M:S'Z')."

  validation {
    error_message = "Value must be a UTC datetime (Y-m-d'T'H:M:S'Z')."
    condition     = var.not_before_date == null ? true : can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", var.not_before_date))
  }
}

variable "opts" {
  type        = list(string)
  default     = []
  description = "The options to apply to the key. Possible values are `decrypt`, `encrypt`, `sign`, `wrapKey`, `unwrapKey`, and `verify`."
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
A map of role assignments to create on the key. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

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

variable "rotation_policy" {
  type = object({
    automatic = optional(object({
      time_after_creation = optional(string, null)
      time_before_expiry  = optional(string, null)
    }), null)
    expire_after         = optional(string, null)
    notify_before_expiry = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
The rotation policy of the key:

- `automatic` - The automatic rotation policy of the key.
  - `time_after_creation` - The time after creation of the key before it is automatically rotated as an ISO 8601 duration.
  - `time_before_expiry` - The time before expiry of the key before it is automatically rotated as an ISO 8601 duration.
- `expire_after` - The time after which the key expires.
- `notify_before_expiry` - The time before expiry of the key when notification emails will be sent as an ISO 8601 duration.
DESCRIPTION
}

variable "size" {
  type        = number
  default     = null
  description = "The size of the RSA key. Required if `type` is `RSA` or `RSA-HSM`."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "The tags to assign to the key."
}
