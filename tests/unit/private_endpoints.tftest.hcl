mock_provider "azurerm" {
  mock_resource "azurerm_managed_disk" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Compute/disks/disk-unit"
    }
  }
  mock_resource "azurerm_private_endpoint" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/privateEndpoints/pep-unit"
    }
  }
}

mock_provider "azapi" {
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [{
          id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
          role_name = "Reader"
        }]
      }
    }
  }
}

mock_provider "modtm" {}

mock_provider "random" {
  mock_resource "random_uuid" {
    defaults = {
      result = "22222222-2222-4222-8222-222222222222"
    }
  }
}

variables {
  create_option        = "Empty"
  location             = "uksouth"
  name                 = "disk-unit"
  resource_group_name  = "rg-unit"
  storage_account_type = "Standard_LRS"
  zone                 = "1"
  disk_access_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Compute/diskAccesses/access-unit"
  disk_size_gb         = 32
  enable_telemetry     = false
}

run "omitted_endpoints" {
  command = apply

  assert {
    condition = (
      length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 0 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0 &&
      length(azapi_resource.private_endpoint_locks) == 0 &&
      length(azapi_resource.private_endpoint_role_assignments) == 0 &&
      length(random_uuid.private_endpoint_role_assignments) == 0 &&
      length(data.azapi_resource_list.private_endpoint_role_definitions) == 0 &&
      length(azurerm_private_endpoint_application_security_group_association.this) == 0
    )
    error_message = "Omitting private_endpoints must create no endpoints or endpoint extension resources."
  }
}

run "null_endpoints" {
  command = apply

  variables {
    private_endpoints = null
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 0 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0 &&
      length(azapi_resource.private_endpoint_locks) == 0 &&
      length(azapi_resource.private_endpoint_role_assignments) == 0 &&
      length(data.azapi_resource_list.private_endpoint_role_definitions) == 0
    )
    error_message = "An explicit null private_endpoints input must retain the empty-map default."
  }
}

run "managed_defaults_and_nulls" {
  command = apply

  variables {
    lock = {
      kind = "ReadOnly"
    }
    tags = {
      root = "not-inherited"
    }
    private_endpoints = {
      omitted = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/default"
        ip_configurations = {
          static = {
            name               = "static"
            private_ip_address = "10.0.0.4"
          }
        }
      }
      nulls = {
        name                                    = null
        role_assignments                        = null
        lock                                    = null
        tags                                    = null
        subnet_resource_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/default"
        subresource_name                        = null
        private_dns_zone_group_name             = null
        private_dns_zone_resource_ids           = null
        application_security_group_associations = null
        private_service_connection_name         = null
        network_interface_name                  = null
        location                                = null
        resource_group_name                     = null
        ip_configurations = {
          static = {
            name               = "static"
            private_ip_address = "10.0.0.5"
            member_name        = null
          }
        }
      }
    }
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 2 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0 &&
      alltrue([for endpoint in azurerm_private_endpoint.this_managed_dns_zone_groups :
        endpoint.name == "pep-disk-unit" &&
        endpoint.location == "uksouth" &&
        endpoint.resource_group_name == "rg-unit" &&
        endpoint.tags == null &&
        endpoint.custom_network_interface_name == null &&
        length(endpoint.private_dns_zone_group) == 0 &&
        endpoint.private_service_connection[0].name == "pse-disk-unit" &&
        endpoint.private_service_connection[0].private_connection_resource_id == var.disk_access_id &&
        endpoint.private_service_connection[0].is_manual_connection == false &&
        endpoint.private_service_connection[0].subresource_names == tolist(["disks"]) &&
        endpoint.ip_configuration[0].subresource_name == "disks" &&
        endpoint.ip_configuration[0].member_name == "disks"
      ])
    )
    error_message = "Omitted and null endpoint settings must retain existing managed-DNS addresses and disk-specific defaults."
  }
  assert {
    condition = (
      length(azapi_resource.private_endpoint_locks) == 0 &&
      length(azapi_resource.private_endpoint_role_assignments) == 0 &&
      length(random_uuid.private_endpoint_role_assignments) == 0 &&
      length(data.azapi_resource_list.private_endpoint_role_definitions) == 0
    )
    error_message = "The root lock and tags must not create or configure endpoint locks or role assignments."
  }
}

run "unmanaged_defaults_and_associations" {
  command = apply

  variables {
    private_endpoints_manage_dns_zone_group = false
    private_endpoints = {
      endpoint = {
        subnet_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/default"
        subresource_name                = null
        role_assignments                = null
        lock                            = null
        tags                            = null
        ip_configurations               = null
        private_dns_zone_resource_ids   = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"]
        private_service_connection_name = null
        application_security_group_associations = {
          app = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/applicationSecurityGroups/asg-unit"
        }
      }
    }
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 0 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 1 &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].name == "pep-disk-unit" &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].location == "uksouth" &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].resource_group_name == "rg-unit" &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].tags == null &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].private_service_connection[0].name == "pse-disk-unit" &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].private_service_connection[0].subresource_names == tolist(["disks"]) &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].private_dns_zone_group) == 0 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].ip_configuration) == 0
    )
    error_message = "Unmanaged-DNS endpoints must retain their existing address, defaults, and externally managed DNS groups."
  }
  assert {
    condition = (
      azurerm_private_endpoint_application_security_group_association.this["endpoint-app"].private_endpoint_id == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].id &&
      output.private_endpoints["endpoint"].id == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].id &&
      length(azapi_resource.private_endpoint_locks) == 0 &&
      length(azapi_resource.private_endpoint_role_assignments) == 0
    )
    error_message = "The existing association address and output must use the selected unmanaged-DNS endpoint."
  }
}

run "managed_explicit_settings" {
  command = apply

  variables {
    tags = {
      root = "not-inherited"
    }
    private_endpoints = {
      endpoint = {
        name                            = "pep-custom"
        location                        = "ukwest"
        resource_group_name             = "rg-endpoint"
        subnet_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/default"
        subresource_name                = "custom-subresource"
        network_interface_name          = "nic-custom"
        private_service_connection_name = "connection-custom"
        private_dns_zone_group_name     = "dns-custom"
        private_dns_zone_resource_ids   = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"]
        tags = {
          endpoint = "only"
        }
        ip_configurations = {
          static = {
            name               = "ip-custom"
            private_ip_address = "10.0.0.6"
            member_name        = "custom-member"
          }
        }
        lock = {
          kind  = "CanNotDelete"
          name  = "lock-custom"
          notes = "Keep this endpoint."
        }
        role_assignments = {
          named = {
            name                                   = "33333333-3333-4333-8333-333333333333"
            role_definition_id_or_name             = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            principal_id                           = "11111111-1111-4111-8111-111111111111"
            principal_type                         = "Group"
            skip_service_principal_aad_check       = true
            description                            = "Endpoint reader."
            condition                              = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'example'"
            condition_version                      = "2.0"
            delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.ManagedIdentity/userAssignedIdentities/identity-unit"
          }
          generated = {
            name                             = null
            role_definition_id_or_name       = "Reader"
            principal_id                     = "44444444-4444-4444-8444-444444444444"
            skip_service_principal_aad_check = true
          }
        }
        application_security_group_associations = {
          app = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/applicationSecurityGroups/asg-unit"
        }
      }
    }
  }

  assert {
    condition = (
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].name == "pep-custom" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].location == "ukwest" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].resource_group_name == "rg-endpoint" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].custom_network_interface_name == "nic-custom" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].tags == tomap({ endpoint = "only" }) &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].private_service_connection[0].name == "connection-custom" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].private_service_connection[0].subresource_names == tolist(["custom-subresource"]) &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].ip_configuration[0].subresource_name == "custom-subresource" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].ip_configuration[0].member_name == "custom-member" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].private_dns_zone_group[0].name == "dns-custom" &&
      azurerm_private_endpoint_application_security_group_association.this["endpoint-app"].private_endpoint_id == azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].id
    )
    error_message = "Managed-DNS endpoints must bind the canonical fields without changing existing endpoint-specific settings."
  }
  assert {
    condition = (
      azapi_resource.private_endpoint_locks["endpoint"].name == "lock-custom" &&
      azapi_resource.private_endpoint_locks["endpoint"].parent_id == azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].id &&
      azapi_resource.private_endpoint_locks["endpoint"].type == "Microsoft.Authorization/locks@2020-05-01" &&
      azapi_resource.private_endpoint_locks["endpoint"].body.properties.level == "CanNotDelete" &&
      azapi_resource.private_endpoint_locks["endpoint"].body.properties.notes == "Keep this endpoint."
    )
    error_message = "Explicit endpoint lock settings must create the requested lock, including its name and notes."
  }
  assert {
    condition = (
      length(azapi_resource.private_endpoint_role_assignments) == 2 &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "named"])].name == "33333333-3333-4333-8333-333333333333" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "named"])].parent_id == azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].id &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "named"])].type == "Microsoft.Authorization/roleAssignments@2022-04-01" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "named"])].body.properties.principalId == "11111111-1111-4111-8111-111111111111" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "named"])].body.properties.principalType == "Group" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "named"])].body.properties.description == "Endpoint reader." &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "named"])].body.properties.condition == var.private_endpoints["endpoint"].role_assignments["named"].condition &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "named"])].body.properties.conditionVersion == "2.0" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "named"])].body.properties.delegatedManagedIdentityResourceId == var.private_endpoints["endpoint"].role_assignments["named"].delegated_managed_identity_resource_id &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "generated"])].name == "22222222-2222-4222-8222-222222222222" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "generated"])].body.properties.principalType == "ServicePrincipal" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "generated"])].body.properties.roleDefinitionId == azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "named"])].body.properties.roleDefinitionId
    )
    error_message = "Endpoint role assignments must bind every declared field and resolve role names as well as IDs."
  }
}

run "unmanaged_explicit_settings" {
  command = apply

  variables {
    private_endpoints_manage_dns_zone_group = false
    resource_types                          = null
    ignore_body_changes                     = null
    retry                                   = null
    timeouts                                = null
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/default"
        subresource_name   = "custom-subresource"
        ip_configurations = {
          static = {
            name               = "static"
            private_ip_address = "10.0.0.7"
            member_name        = "custom-member"
          }
        }
        lock = {
          kind  = "ReadOnly"
          name  = null
          notes = null
        }
        role_assignments = {
          reader = {
            role_definition_id_or_name = "Reader"
            principal_id               = "11111111-1111-4111-8111-111111111111"
          }
          conditional = {
            role_definition_id_or_name = "Reader"
            principal_id               = "44444444-4444-4444-8444-444444444444"
            condition                  = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'example'"
          }
        }
      }
    }
  }

  assert {
    condition = (
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].private_service_connection[0].subresource_names == tolist(["custom-subresource"]) &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].ip_configuration[0].subresource_name == "custom-subresource" &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].ip_configuration[0].member_name == "custom-member" &&
      azapi_resource.private_endpoint_locks["endpoint"].parent_id == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].id &&
      azapi_resource.private_endpoint_locks["endpoint"].name == "lock-ReadOnly" &&
      azapi_resource.private_endpoint_locks["endpoint"].body.properties.notes == null &&
      data.azapi_resource_list.private_endpoint_role_definitions["endpoint"].parent_id == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].id &&
      alltrue([for assignment in azapi_resource.private_endpoint_role_assignments : assignment.parent_id == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].id])
    )
    error_message = "Both endpoint branches must apply the new fields and scope extensions to the selected endpoint."
  }
  assert {
    condition = (
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "reader"])].body.properties.principalType == null &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "reader"])].body.properties.description == null &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "reader"])].body.properties.condition == null &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "reader"])].body.properties.conditionVersion == null &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "reader"])].body.properties.delegatedManagedIdentityResourceId == null &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "conditional"])].body.properties.conditionVersion == "2.0"
    )
    error_message = "Nullable role assignment settings must remain null, except a supplied condition defaults to syntax version 2.0."
  }
}

run "member_fallback_and_disabled_lock" {
  command = apply

  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/default"
        subresource_name   = "custom-subresource"
        ip_configurations = {
          omitted = {
            name               = "omitted"
            private_ip_address = "10.0.0.8"
          }
          nulls = {
            name               = "nulls"
            private_ip_address = "10.0.0.9"
            member_name        = null
          }
        }
        lock = {
          kind  = "None"
          name  = "not-created"
          notes = "not-created"
        }
      }
    }
  }

  assert {
    condition = (
      alltrue([for ip in azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].ip_configuration : ip.member_name == "custom-subresource"]) &&
      length(azapi_resource.private_endpoint_locks) == 0
    )
    error_message = "Omitted or null members must follow the selected subresource, and a None lock must create no resource."
  }
}

run "azapi_controls" {
  command = apply

  variables {
    resource_types = {
      authorization_locks            = "Microsoft.Authorization/locks@2017-04-01"
      authorization_role_assignments = "Microsoft.Authorization/roleAssignments@2020-10-01-preview"
    }
    retry = {
      error_message_regex  = ["AuthorizationFailed"]
      interval_seconds     = 10
      max_interval_seconds = 30
    }
    timeouts = {
      create = "30m"
      read   = "5m"
      update = "20m"
      delete = "10m"
    }
    ignore_body_changes = {
      authorization_locks            = ["properties.notes"]
      authorization_role_assignments = ["properties.description"]
    }
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/default"
        lock = {
          kind = "CanNotDelete"
        }
        role_assignments = {
          reader = {
            role_definition_id_or_name = "Reader"
            principal_id               = "11111111-1111-4111-8111-111111111111"
          }
        }
      }
    }
  }

  assert {
    condition = (
      azapi_resource.private_endpoint_locks["endpoint"].type == var.resource_types.authorization_locks &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "reader"])].type == var.resource_types.authorization_role_assignments &&
      azapi_resource.private_endpoint_locks["endpoint"].retry.interval_seconds == 10 &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "reader"])].retry.max_interval_seconds == 30 &&
      data.azapi_resource_list.private_endpoint_role_definitions["endpoint"].retry.error_message_regex == tolist(["AuthorizationFailed"]) &&
      azapi_resource.private_endpoint_locks["endpoint"].timeouts.create == "30m" &&
      azapi_resource.private_endpoint_locks["endpoint"].timeouts.delete == "10m" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["endpoint", "reader"])].timeouts.update == "20m" &&
      data.azapi_resource_list.private_endpoint_role_definitions["endpoint"].timeouts.read == "5m"
    )
    error_message = "Resource type, retry, and timeout controls must reach endpoint extensions and role lookup."
  }
}

run "reject_invalid_subnet" {
  command = plan

  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "not-a-subnet-id"
      }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "reject_invalid_dns_zone" {
  command = plan

  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/default"
        private_dns_zone_resource_ids = ["not-a-dns-zone-id"]
      }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "reject_invalid_security_group" {
  command = plan

  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/default"
        application_security_group_associations = {
          app = "not-an-asg-id"
        }
      }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "reject_invalid_delegated_identity" {
  command = plan

  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/default"
        role_assignments = {
          reader = {
            role_definition_id_or_name             = "Reader"
            principal_id                           = "11111111-1111-4111-8111-111111111111"
            delegated_managed_identity_resource_id = "not-a-managed-identity-id"
          }
        }
      }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "reject_condition_version_without_condition" {
  command = plan

  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/default"
        role_assignments = {
          reader = {
            role_definition_id_or_name = "Reader"
            principal_id               = "11111111-1111-4111-8111-111111111111"
            condition_version          = "2.0"
          }
        }
      }
    }
  }

  expect_failures = [azapi_resource.private_endpoint_role_assignments]
}
