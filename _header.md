# terraform-azurerm-avm-res-keyvault-vault

Module to deploy key vaults, keys and secrets in Azure.

## Upgrading from a version that used the AzureRM provider for the key vault

Versions up to 0.11.x managed the key vault itself with the AzureRM provider. This version manages
the key vault, its access policies, lock, role assignments and diagnostic settings with AzAPI, and
includes `moved` blocks so the key vault, its lock, role assignments and diagnostic settings move to
their AzAPI addresses without being recreated.

Keys, secrets, certificate contacts and private endpoints still use the AzureRM provider and are
migrated in a later release.

1. Replace `resource_group_name` with `parent_id`, the resource ID of the resource group:

   ```hcl
   parent_id = "/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>"
   ```

1. Run `terraform init -upgrade`, then `terraform plan`.
1. Expect in-place updates while AzAPI takes over the existing resources. None of the resources the
   plan adds creates anything in Azure: a `time_sleep` resource when a lock is configured, and the
   interfaces utility module's telemetry resources when `enable_telemetry` is true. Nothing should be
   destroyed or replaced; do not apply a plan that destroys or replaces any of these resources.
1. Apply the plan. A second plan reports no changes.

Access policies need no action. Azure models them as an operation on the vault rather than as
addressable child resources, so from this version they are sent in the vault's own body and the old
`azurerm_key_vault_access_policy` resources are dropped from the state without being deleted. The
plan reports them as "will no longer be managed by Terraform, but will not be destroyed", and the
vault keeps the policies themselves.

When `legacy_access_policies_enabled` is false the module does not manage access policies at all. It
re-reads whatever is on the vault and sends it back unchanged, so policies set by another
configuration are left in place.

Two cases need extra steps:

- **`ReadOnly` lock.** The upgrade updates the key vault in place, which a `ReadOnly` lock blocks.
  Before upgrading, apply your configuration with `lock = null` using the old version, then upgrade
  and restore the lock.

- **Cross-tenant role assignments** (those that set `delegated_managed_identity_resource_id`, for
  example with Azure Lighthouse). The AzureRM provider stored their ID with a `|<tenant-id>` suffix
  that the `moved` block cannot convert. Before planning, remove each one from the state, then import
  it at its new address with an `import` block in your root module:

  ```pwsh
  terraform state rm 'module.<module-name>.azurerm_role_assignment.this["<key>"]'
  ```

  ```hcl
  import {
    to = module.<module-name>.azapi_resource.role_assignments["<key>"]
    id = "<role assignment resource ID, without the |<tenant-id> suffix>"
  }
  ```

The `uri` output is now read from the key vault's `properties.vaultUri` rather than the AzureRM
`vault_uri` attribute, and returns the same value.
