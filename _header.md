# terraform-azurerm-avm-res-keyvault-vault

Module to deploy key vaults, keys and secrets in Azure.

## Upgrading from a version that used the AzureRM provider for the key vault

Versions up to 0.12.x managed the key vault itself with the AzureRM provider. This version manages
the key vault, its access policies, lock, role assignments, diagnostic settings and private endpoints
with AzAPI, and includes `moved` blocks so the key vault, its lock, role assignments, diagnostic
settings, private endpoints and their locks move to their AzAPI addresses without being recreated.

Keys, secrets and certificate contacts still use the AzureRM provider and are migrated in a later
release.

1. Replace `resource_group_name` with `parent_id`, the resource ID of the resource group:

   ```hcl
   parent_id = "/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>"
   ```

1. If the module manages private DNS zone groups, add the `import` block described below.
1. Run `terraform init -upgrade`, then `terraform plan`.
1. Expect in-place updates while AzAPI takes over the existing resources. None of the resources the
   plan adds creates anything in Azure: `time_sleep` resources when a lock is configured on the key
   vault or a private endpoint, and the interfaces utility module's telemetry resources when
   `enable_telemetry` is true. Nothing should be destroyed or replaced; do not apply a plan that
   destroys or replaces any of these resources.
1. Apply the plan. A second plan reports no changes.

Access policies and application security groups need no action. Azure models both as part of their
parent rather than as addressable child resources, so from this version they are sent in the body of
the key vault and the private endpoint respectively. The old `azurerm_key_vault_access_policy` and
`azurerm_private_endpoint_application_security_group_association` resources are dropped from the
state without being deleted: the plan reports them as "will no longer be managed by Terraform, but
will not be destroyed", and Azure keeps the policies and associations themselves.

When `legacy_access_policies_enabled` is false the module does not manage access policies at all. It
re-reads whatever is on the vault and sends it back unchanged, so policies set by another
configuration are left in place.

Three cases need extra steps:

- **Private DNS zone groups managed by the module** (`private_endpoints_manage_dns_zone_group` is
  true, the default, and a private endpoint sets `private_dns_zone_resource_ids`). The AzureRM
  provider kept the zone group inside the private endpoint, so there is no separate address for a
  `moved` block to start from, and AzAPI does not take over an existing resource it did not create.
  Import each zone group once with an `import` block in your root module:

  ```hcl
  import {
    to = module.<module-name>.azapi_resource.private_dns_zone_groups["<key>"]
    id = "/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.Network/privateEndpoints/<private-endpoint-name>/privateDnsZoneGroups/<zone-group-name>?api-version=2025-05-01"
  }
  ```

  `<key>` is the key of the `private_endpoints` entry, `<private-endpoint-name>` is its `name`
  (`pe-<key vault name>` by default), and `<zone-group-name>` is its `private_dns_zone_group_name`
  (`default` by default). The import leaves the zone group and its DNS records unchanged. Without it,
  the apply stops with `Resource already exists` after upgrading everything else, and nothing in Azure
  is removed; add the block and apply again. Remove the block once the upgrade is applied.

- **`ReadOnly` lock.** The upgrade updates the key vault and its private endpoints in place, which a
  `ReadOnly` lock on either blocks. Before upgrading, apply your configuration without those locks
  using the old version, then upgrade and restore the locks.

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

The `private_endpoints` output no longer returns the entire AzureRM resource. It returns the
attributes listed in its description, under the names and shapes the AzureRM provider used, so
references such as `id`, `name` and `private_service_connection[0].private_ip_address` return the same
values as before.
