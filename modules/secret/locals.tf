locals {
  secret_id             = azapi_resource.this.output.properties.secretUriWithVersion
  secret_versionless_id = azapi_resource.this.output.properties.secretUri
}
