# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_managed_disk.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_managed_disk.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azurerm_managed_disk" "this" {
  create_option                     = var.create_option
  location                          = var.location
  name                              = var.name
  resource_group_name               = var.resource_group_name
  storage_account_type              = var.storage_account_type
  disk_access_id                    = var.disk_access_id
  disk_encryption_set_id            = var.disk_encryption_set_id
  disk_iops_read_only               = var.disk_iops_read_only
  disk_iops_read_write              = var.disk_iops_read_write
  disk_mbps_read_only               = var.disk_mbps_read_only
  disk_mbps_read_write              = var.disk_mbps_read_write
  disk_size_gb                      = var.disk_size_gb
  edge_zone                         = var.edge_zone
  gallery_image_reference_id        = var.gallery_image_reference_id
  hyper_v_generation                = var.hyper_v_generation
  image_reference_id                = var.image_reference_id
  logical_sector_size               = var.logical_sector_size
  max_shares                        = var.max_shares
  network_access_policy             = var.network_access_policy
  on_demand_bursting_enabled        = var.on_demand_bursting_enabled
  optimized_frequent_attach_enabled = var.optimized_frequent_attach_enabled
  os_type                           = var.os_type
  performance_plus_enabled          = var.performance_plus_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  secure_vm_disk_encryption_set_id  = var.secure_vm_disk_encryption_set_id
  security_type                     = var.security_type
  source_resource_id                = var.source_resource_id
  source_uri                        = var.source_uri
  storage_account_id                = var.storage_account_id
  tags                              = var.tags
  tier                              = var.tier
  trusted_launch_enabled            = var.trusted_launch_enabled
  upload_size_bytes                 = var.upload_size_bytes
  zone                              = var.zone

  dynamic "encryption_settings" {
    for_each = var.encryption_settings == null ? [] : [var.encryption_settings]
    content {
      enabled = encryption_settings.value.enabled

      dynamic "disk_encryption_key" {
        for_each = encryption_settings.value.disk_encryption_key == null ? [] : [encryption_settings.value.disk_encryption_key]
        content {
          secret_url      = disk_encryption_key.value.secret_url
          source_vault_id = disk_encryption_key.value.source_vault_id
        }
      }
      dynamic "key_encryption_key" {
        for_each = encryption_settings.value.key_encryption_key == null ? [] : [encryption_settings.value.key_encryption_key]
        content {
          key_url         = key_encryption_key.value.key_url
          source_vault_id = key_encryption_key.value.source_vault_id
        }
      }
    }
  }
}

