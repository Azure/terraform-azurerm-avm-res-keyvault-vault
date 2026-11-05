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
  description = "The type of the key. Possible values are `EC`, `EC-HSM`, `RSA`, and `RSA-HSM`. The values are case-sensitive. The HSM-backed types (`EC-HSM` and `RSA-HSM`) require a Key Vault with the `premium` SKU, or a Managed HSM."
  nullable    = false

  validation {
    error_message = "The key type must be one of `EC`, `EC-HSM`, `RSA`, or `RSA-HSM` (case-sensitive). The HSM-backed types require a Key Vault with the `premium` SKU, or a Managed HSM."
    condition     = contains(["EC", "EC-HSM", "RSA", "RSA-HSM"], var.type)
  }
}

variable "curve" {
  type        = string
  default     = null
  description = "The curve of the EC key. Required if `type` is `EC` or `EC-HSM`. Possible values are `P-256`, `P-256K`, `P-384`, and `P-521`. This field will be required in a future release if key_type is EC or EC-HSM. The API will default to `P-256` if nothing is specified."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
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

variable "location" {
  type        = string
  default     = null
  description = "The Azure region for this module's resources or telemetry deployment."

  validation {
    condition     = !var.enable_telemetry || var.location != null
    error_message = "The location must not be null when telemetry is enabled."
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

variable "release_policy" {
  type = object({
    json      = string
    immutable = optional(bool, false)
  })
  default     = null
  description = <<DESCRIPTION
The release policy for a secure key release. Requires an `EC-HSM` or `RSA-HSM` key in a Premium Key Vault. The provider automatically makes a key with a release policy exportable. Adding, changing, or removing a release policy on an existing key replaces the key because the provider marks the block `ForceNew`; key replacement destroys the existing key and creates new key material.

- `json` - The release policy as JSON text; use `jsonencode` to construct it.
- `immutable` - Whether the release policy is immutable. Defaults to `false`.
DESCRIPTION
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
  description = "The size of the RSA key, e.g. `2048` or `4096`. Required if `type` is `RSA` or `RSA-HSM`."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "The tags to assign to the key."
}

variable "ignore_body_changes" {
  type = object({
    authorization_role_assignments = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Paths in each resource's `body` whose changes the AzAPI provider ignores. See the root module's `ignore_body_changes` for the semantics.

- `authorization_role_assignments` - The role assignments.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    authorization_role_assignments = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the module, in `<provider>/<resource>@<api-version>` form.

- `authorization_role_assignments` - The role assignments.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to every `azapi` resource managed by the module. Defaults to `null` (no custom retry).

- `error_message_regex`  - (Optional) A list of regex patterns matching error messages that trigger a retry.
- `interval_seconds`     - (Optional) Initial interval between retries in seconds.
- `max_interval_seconds` - (Optional) Maximum interval between retries in seconds.
DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Per-operation timeouts applied to every `azapi` resource managed by the module. Defaults to `null` (provider defaults). Each value is a Go duration string (e.g. `30m`, `1h`).
DESCRIPTION
}
