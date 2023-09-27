# TODO: insert locals here.
locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}

# Role assignments for keys
locals {
  keys_role_assignments = { for ra in flatten([
    for kk, kv in var.keys : [
      for rk, rv in kv.role_assignments : {
        key_key         = kk
        ra_key          = rk
        role_assignment = rv
      }
    ]
  ]) : "${ra.key_key}-${ra.ra_key}" => ra }
}

# Role assignments for secrets
locals {
  secrets_role_assignments = { for ra in flatten([
    for sk, sv in var.secrets : [
      for rk, rv in sv.role_assignments : {
        secret_key      = sk
        ra_key          = rk
        role_assignment = rv
      }
    ]
  ]) : "${ra.secret_key}-${ra.ra_key}" => ra }
}

# Private endpoint application security group associations
locals {
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
}
