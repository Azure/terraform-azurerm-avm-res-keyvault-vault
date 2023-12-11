terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0, < 5.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# We need the tenant id for the key vault.
data "azurerm_client_config" "this" {}

data "http" "this_ip" {
  url = "http://whatismyip.akamai.com/"
}

# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  min = 0
  max = length(module.regions.regions) - 1
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group.name_unique
  location = module.regions.regions[random_integer.region_index.result].name
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "this" {
  private_key_pem = tls_private_key.this.private_key_pem

  subject {
    common_name  = "azureverfiedmodules.com"
    organization = "Azure Verified Modules"
  }

  validity_period_hours = 12

  allowed_uses = [
    "server_auth"
  ]
}

# This is the module call
module "keyvault" {
  source = "../../"
  # source             = "Azure/avm-res-keyvault-vault/azurerm"
  name                = module.naming.key_vault.name_unique
  enable_telemetry    = var.enable_telemetry
  sku_name            = "standard"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.this.tenant_id
  role_assignments = {
    "key_vault_admin" = {
      principal_id               = data.azurerm_client_config.this.object_id
      role_definition_id_or_name = "Key Vault Administrator"
    }
  }
  network_acls = {
    ip_rules = ["${data.http.this_ip.response_body}/32"]
  }
  certificates = {
    import = {
      name = "import"
      certificate = {
        contents = trimspace(format("%s%s", tls_self_signed_cert.this.cert_pem, tls_private_key.this.private_key_pem_pkcs8))
      }
    }
  }
}

resource "local_file" "this" {
  filename = "cert2.pem"
  content  = trimspace(format("%s%s", tls_self_signed_cert.this.cert_pem, tls_private_key.this.private_key_pem_pkcs8))
}
