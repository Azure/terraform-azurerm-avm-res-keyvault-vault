---
description: " Azure Verified Modules (AVM) and Terraform"
applyTo: "**/*.terraform, **/*.tf, **/*.tfvars, **/*.tfstate, **/*.tflint.hcl, **/*.tf.json, **/*.tfvars.json"
---

# Azure Verified Modules (AVM) Terraform

This repository uses Azure Verified Modules (AVM) for Terraform.
For detailed module guidance, use the [AVM Terraform agent](.github/agents/avm-tf.agent.md) and load only the relevant skills under [.github/skills](.github/skills/).

## AVM Specifications

The authoritative source for every AVM rule (Bicep, Terraform, shared) is the spec index:

- **Index of all specs and docs (raw markdown URLs):** `https://azure.github.io/Azure-Verified-Modules/llms.txt`
- **Rendered docs site:** `https://azure.github.io/Azure-Verified-Modules/`

When a spec ID is mentioned (e.g. `TFFR3`, `RMFR4`, `SNFR1`), fetch `llms.txt` once, look up the raw markdown URL for that ID, and read the current text. Do not cite a spec from memory.

## Terraform Provider Requirement

Every new AVM Terraform module that deploys Azure resources MUST use `Azure/azapi` for its primary resource and primary implementation. AzureRM MUST NOT be selected as a convenience, as an easier schema, or as the module's primary provider.

AzureRM is permitted only for an individual resource whose functionality has no equivalent in `azapi_resource`, `azapi_data_plane_resource`, `azapi_resource_action`, or `azapi_update_resource`, and only when every TFFR3 exception requirement is met. A permitted resource-level exception does not make an AzureRM-based module acceptable.

## Module Discovery

- **Terraform Registry**: Search for "avm" + resource name, filter by "Partner" tag
- **Terraform Resource Modules Index**: `https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/`
- **Terraform Pattern Modules Index**: `https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-pattern-modules/`

## New Module Naming Conventions

- **Resource Modules**: `Azure/avm-res-{service}-{resource}/azure`
- **Pattern Modules**: `Azure/avm-ptn-{pattern}/azure`
- **Utility Modules**: `Azure/avm-utl-{utility}/azure`
- Use kebab-case for services and resources
- Follow Azure service names (e.g., `storage-storageaccount`, `network-virtualnetwork`)

Existing modules can retain legacy `terraform-azurerm-avm-*` repository names and `/azurerm` Registry namespaces. Those names are publication identifiers and do not permit new modules to use AzureRM for their primary implementation.

## Module Usage

When using AVM modules:

1. Pin to a specific version: `version = "1.2.3"`
2. Map enable telemetry to root variable: `enable_telemetry = var.enable_telemetry`
3. For providers, use pessimistic constraints: `version = "~> 1.0"`
4. Start from official examples in the module documentation
5. Replace `source = "../../"` with the registry source when copying examples

## Module Sources

- **Registry for new modules**: `https://registry.terraform.io/modules/Azure/{module}/azure/latest`
- **GitHub for new modules**: `https://github.com/Azure/terraform-azure-avm-{type}-{service}-{resource}`
- **Versions API**: `https://registry.terraform.io/v1/modules/Azure/{module}/[azurerm|azure]/versions`
