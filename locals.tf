# TODO: insert locals here.
locals {
  # Private endpoint application security group associations.
  # We merge the nested maps from private endpoints and application security group associations into a single map.
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
  private_endpoint_ids = merge(
    { for key, endpoint in azurerm_private_endpoint.this_managed_dns_zone_groups : key => endpoint.id },
    { for key, endpoint in azurerm_private_endpoint.this_unmanaged_dns_zone_groups : key => endpoint.id }
  )
  private_endpoint_role_assignments = {
    for assignment in flatten([
      for pe_key, endpoint in var.private_endpoints : [
        for ra_key, role_assignment in endpoint.role_assignments : {
          pe_key     = pe_key
          ra_key     = ra_key
          assignment = role_assignment
        }
      ]
    ]) : jsonencode([assignment.pe_key, assignment.ra_key]) => assignment
  }
  private_endpoint_role_definition_ids = {
    for key, definitions in data.azapi_resource_list.private_endpoint_role_definitions : key => {
      for definition in definitions.output.results : definition.role_name => definition.id
    }
  }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
