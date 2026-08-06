# Create key

This example shows how to deploy the module and create a key using Azure RBAC.

It also shows how to consume the key from another module. Keys are exposed through the
module's `keys` output, indexed by the **map key** used in `var.keys`
(`cmk_for_storage_account` below), not by the key's `name`
(`cmk-for-storage-account`). Each entry exposes four identifiers, which are easy to
confuse:

| Attribute | Shape | Use it for |
| - | - | - |
| `id` | `https://<vault-name>.vault.azure.net/keys/<key-name>/<key-version>` | Data plane URI pinned to a version. This is what most Azure services want for a customer managed key, including the `transparent_data_encryption_key_vault_key_id` input of `Azure/avm-res-sql-server/azurerm`. |
| `versionless_id` | `https://<vault-name>.vault.azure.net/keys/<key-name>` | Data plane URI without a version. Use only where the consuming API documents that it accepts a versionless URI — several services that support rotation still require the versioned form and discover new versions separately. |
| `resource_id` | `/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/keys/<key-name>/versions/<key-version>` | ARM resource ID pinned to a version. |
| `resource_versionless_id` | `/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.KeyVault/vaults/<vault-name>/keys/<key-name>` | ARM resource ID without a version. This is the scope this module uses for key role assignments. |

The data plane URIs above are shown for public Azure. Sovereign clouds use a different
Key Vault DNS suffix, for example `.vault.usgovcloudapi.net`.

So the versioned key URI is:

```hcl
module.key_vault.keys["cmk_for_storage_account"].id
```
