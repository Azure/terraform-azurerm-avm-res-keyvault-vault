# Azure Verified Modules (AVM) Terraform Copilot Instructions

This file contains comprehensive instructions for developing Azure Verified Modules (AVM) Terraform modules based on the official AVM specifications. Follow these guidelines strictly when working on any AVM Terraform module.

## Development Workflow

### Issue-Based Development
1. **Always start with an issue analysis**: Fetch and analyze the GitHub issue to understand the request type
2. **Categorize the work**: Determine if this is `bug`, `feature`, `docs`, or `maint`
3. **Create a feature branch**: Use `git checkout -b <category>/<issue-number>`
4. **Create todo.md**: Write analysis and detailed plan in the root directory
5. **Track progress**: Update todo.md as you make progress
6. **Pre-commit validation**: Always run `./avm pre-commit` before committing
7. **Clean up**: Remove todo.md after successful completion
8. **Commit and PR**: Use conventional commit style messages and propose a Pull Request, the PR title should also use conventional commit style.

### Schema and Provider Consultation
- **Always consult MCP server** for Terraform schema and provider information before creating/updating Terraform blocks
- Use `query_` prefixed tools for general schema/document queries
- Use `query_azapi_` prefixed tools for Azure API provider resource schemas

## Core Terraform Specifications (TF*)

### TFFR1 - Cross-Referencing Modules (MUST)
- **MUST** use only HashiCorp Terraform registry references with pinned versions
- **MUST NOT** use git references to modules
- **MUST NOT** contain references to non-AVM modules

```terraform
# ✅ Correct
module "other-module" {
  source  = "Azure/xxx/azurerm"
  version = "1.2.3"
}

# ❌ Incorrect
module "other-module" {
  source = "git::https://xxx.yyy/xxx.git"
}
```

### TFFR2 - Additional Terraform Outputs (SHOULD)
- **SHOULD NOT** output entire resource objects (security risk and schema stability)
- **SHOULD** output computed attributes as discrete outputs (anti-corruption layer)
- **SHOULD NOT** output values that are already inputs (except `name`)

```terraform
# ✅ Correct - computed attributes only
output "foo" {
  description = "MyResource foo attribute"
  value       = azurerm_resource_myresource.foo
}

# ✅ Correct - sensitive output
output "bar" {
  description = "MyResource bar attribute"
  value       = azurerm_resource_myresource.bar
  sensitive   = true
}
```

### TFFR3 - Providers - Permitted Versions (MUST)
- **MUST** only use approved provider versions for deploying Azure resources (other providers such as random, time, etc. are permitted):
  - `azurerm`: `>= 4.0, < 5.0`
  - `azapi`: `>= 2.0, < 3.0`
- **MUST** use `required_providers` block with pessimistic version constraints

```terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}
```

## Non-Functional Requirements (TFNFR*)

### TFNFR1 - Descriptions (MUST)
- **MAY** provide multi-line descriptions using HEREDOC format with embedded markdown
- Target audience is module users, not developers

### TFNFR2 - Module Documentation Generation (MUST)
- **MUST** use Terraform Docs for automatic documentation generation
- **MUST** include `.terraform-docs.yml` file in module root

### TFNFR4 - Code Styling - Lower Snake_Casing (MUST)
- **MUST** use lower snake_casing for:
  - Locals
  - Variables
  - Outputs
  - Resources (symbolic names)
  - Modules (symbolic names)

```terraform
# ✅ Correct
variable "snake_casing_example" {
  description = "Example variable"
  type        = string
}
```

### TFNFR16 - Variable Naming Rules (SHOULD)
- **SHOULD** follow HashiCorp's naming rules
- **SHOULD** use positive statements for feature switches: `xxx_enabled` instead of `xxx_disabled`
- Avoid double negatives

### TFNFR17 - Variables with Descriptions (SHOULD)
- **SHOULD** precisely describe the input parameter's purpose and expected data type
- **SHOULD NOT** contain information for module developers (use code comments)
- **MAY** use HEREDOC format for complex object descriptions

```terraform
variable "kubernetes_cluster_key_management_service" {
  type = object({
    key_vault_key_id         = string
    key_vault_network_access = optional(string)
  })
  default     = null
  description = <<-EOT
  - `key_vault_key_id` - (Required) Identifier of Azure Key Vault key.
  - `key_vault_network_access` - (Optional) Network access of the key vault. Defaults to `Public`.
EOT
}
```

## Shared Functional Requirements (SFR*)

### SFR2 - WAF Aligned (SHOULD)
- **SHOULD** prioritize availability best-practices and security over cost optimization
- **MUST** allow overrides by module consumers
- Consider recommendations from:
  - Well-Architected Framework (WAF)
  - Reliability Hub
  - Azure Proactive Resiliency Library (APRL)
  - Microsoft Defender for Cloud (MDFC)

## Shared Non-Functional Requirements (SNFR*)

### SNFR17 - Semantic Versioning (MUST)
- **MUST** use semantic versioning (semver) pattern: `vX.Y.Z`
- **MUST** start with version `v0.1.0` for initial release
- **MUST NOT** bump major version until `v1.0.0` is appropriate
- Before `v1.0.0`: breaking changes increment minor version, not major

## Example Development Standards

### File Structure
- Use `main.tf` for primary resources
- Use `variables.tf` for input variables
- Use `outputs.tf` for output values
- Use `locals.tf` for local values only
- Use `terraform.tf` for provider requirements
- Use `main.telemetry.tf` for telemetry configuration

### Documentation
- **MUST NOT** edit README.md directly as it is auto-generated
- **MUST** include data collection notice
- **MUST** auto-generate docs with `./avm pre-commit`
- **SHOULD** include usage examples
- **MUST** include `_header.md` and `_footer.md` for examples
- **MUST** include following content at the end of `_footer.md`:

  ```markdown
  <!-- markdownlint-disable-next-line MD041 -->
  ## Data Collection

  The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
  ```

### Testing
- **MUST** include comprehensive test coverage
- **MUST** use prescribed testing frameworks
- **SHOULD** include both unit and integration tests
- **MUST** validate with pre-commit hooks

## Resource Module Specifications

These refer to module containing the name `avm-res-<resource-provider>-<resource-type>`.
They can be ignored if the module is a not a resource module.

### RMFR1 - Single Resource Only (MUST)
- **MUST** deploy only a single instance of the primary resource per module instance
- Multiple instances of the module **MUST** be used to scale out
- No bundling of multiple primary resources in one module

### RMFR2 - No Resource Wrapper Modules (MUST)
- **MUST** add value by including additional features on top of the primary resource
- **MUST NOT** be simple wrappers around resources without added functionality
- Should provide meaningful abstraction and standardization

### RMFR3 - Resource Groups (MUST)
- **MUST NOT** create Resource Groups for resources that require them
- **MUST** have input variable called:
  - `resource_group_name` - for azurerm modules that require a Resource Group
  - `parent_id` - for azapi modules that require a parent resource, this is the resource ID of the parent resource
- Resource Group is expected to exist prior to module deployment

### RMFR4 - AVM Consistent Feature & Extension Resources (MUST/SHOULD)
**MUST** support these optional features with standardized variable names:

| Feature | Terraform Variable Name | Requirement |
|---------|-------------------------|-------------|
| Diagnostic Settings | `diagnostic_settings` | MUST |
| Role Assignments | `role_assignments` | MUST |
| Resource Locks | `lock` | MUST |
| Tags | `tags` | MUST |
| Managed Identities | `managed_identities` | MUST |
| Private Endpoints | `private_endpoints` | MUST |
| Customer Managed Keys | `customer_managed_key` | MUST |
| Azure Monitor Alerts | `alerts` | SHOULD |

- **MUST NOT** deploy required/dependent resources for these features
- Dependent resources must pre-exist (e.g., Log Analytics Workspace for diagnostics)

### RMFR6 - Parameter/Variable Naming (MUST)
- Parameters for primary resource **MUST NOT** include resource type in name
- Use `sku` instead of `virtualmachine_sku`
- Preserve original property names when RP includes resource type (e.g., Key Vault's `keySize`)

### RMFR7 - Minimum Required Outputs (MUST)
**MUST** output these minimum outputs:

| Output | Terraform Name | Description |
|--------|----------------|-------------|
| Resource Name | `name` | Name of the deployed resource |
| Resource ID | `resource_id` | Azure Resource ID |
| System Assigned MI Principal ID | `system_assigned_mi_principal_id` | If supported by resource |


### RMNFR2 - Standard Inputs (MUST)
**MUST** use these standard input variables:
- `name` (no default value)
- `location` (no default value)

## Pattern Module Specifications (PM*)

### PMFR1 - Resource Group Creation (MAY)
- Pattern modules **MAY** create Resource Group(s)
- Unlike Resource Modules, Pattern Modules can manage Resource Groups

### PMNFR2 - Use Resource Modules to Build Pattern Modules (SHOULD)
- **SHOULD** be built from AVM Resource Modules for standardization
- **MAY** contain native resources only when necessary for valid reasons:
  - Avoiding ARM scaling limitations
  - Time constraints when required Resource Modules aren't available
- **MUST NOT** contain references to non-AVM modules
- **SHOULD** update to use Resource Modules when they become available

### PMNFR5 - Parameter/Variable Naming (SHOULD)
- Parameter names **SHOULD** contain the resource to which they pertain
- Use `virtualmachine_sku` instead of just `sku` (opposite of Resource Modules)
- Provides clarity in multi-resource patterns

## Key Principles

1. **Security First**: Default to secure configurations
2. **Usability**: Make modules easy to consume
3. **Consistency**: Follow naming and structural conventions
4. **Documentation**: Comprehensive and auto-generated
5. **Testing**: Rigorous validation and testing
6. **Compliance**: Align with Azure Well-Architected Framework
7. **Telemetry**: Enable usage tracking for Microsoft

## Resources

- [AVM Specifications](https://azure.github.io/Azure-Verified-Modules/llms.txt)
- [Terraform Registry](https://registry.terraform.io/namespaces/Azure)
- [HashiCorp Best Practices](https://www.terraform.io/docs/extend/best-practices/)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)

Remember: These are the standards for Azure Verified Modules. Always prioritize compliance with these specifications over other coding preferences when working on AVM modules.
