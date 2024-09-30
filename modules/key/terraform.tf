terraform {
  required_version = "~> 1.9"
  required_providers {
    azapi = {
      source = "Azure/azapi"
      version = ">= 1.9.0, < 2.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71"
    }
  }
}