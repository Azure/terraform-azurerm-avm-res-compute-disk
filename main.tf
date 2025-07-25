# required AVM resources interfaces
data "azurerm_client_config" "current" {}

# Data source to retrieve disk encryption set properties when disk_encryption_set is provided
data "azapi_resource" "disk_encryption_set" {
  count = var.disk_encryption_set != null ? 1 : 0

  resource_id            = var.disk_encryption_set.id
  type                   = "Microsoft.Compute/diskEncryptionSets@2025-01-02"
  response_export_values = ["properties.encryptionType"]
}

locals {
  disk_access_id                = var.network_access_policy == "AllowPrivate" ? try("/subscriptions/${local.disk_access_id_object.subscription_id}/resourceGroups/${upper(local.disk_access_id_object.resource_group_name)}/providers/Microsoft.Compute/diskAccesses/${local.disk_access_id_object.name}", null) : null
  disk_access_id_object         = try(provider::azapi::parse_resource_id("Microsoft.Compute/diskAccesses", var.disk_access_id), null)
  disk_encryption_set_id        = var.disk_encryption_set != null ? try("/subscriptions/${local.disk_encryption_set_id_object.subscription_id}/resourceGroups/${upper(local.disk_encryption_set_id_object.resource_group_name)}/providers/Microsoft.Compute/diskEncryptionSets/${local.disk_encryption_set_id_object.name}", null) : null
  disk_encryption_set_id_object = try(provider::azapi::parse_resource_id("Microsoft.Compute/diskEncryptionSets", var.disk_encryption_set != null ? var.disk_encryption_set.id : null), null)
  # Map the retrieved encryption type to the correct value for disk encryption
  disk_encryption_type = var.disk_encryption_set != null ? try(data.azapi_resource.disk_encryption_set[0].output.properties.encryptionType, "EncryptionAtRestWithCustomerKey") : "EncryptionAtRestWithPlatformKey"
}

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.Compute/disks@2024-03-02"
  body = { for k, v in {
    properties = { for k, v in {
      creationData = { for k, v in {
        createOption      = var.create_option
        performancePlus   = var.performance_plus_enabled
        logicalSectorSize = var.logical_sector_size
        sourceResourceId  = var.source_resource_id
        sourceUri         = var.source_uri
        storageAccountId  = var.storage_account_id
        uploadSizeBytes   = var.upload_size_bytes
        imageReference = var.image_reference_id != null ? {
          id = var.image_reference_id
        } : null
        galleryImageReference = var.gallery_image_reference_id != null ? {
          id = var.gallery_image_reference_id
        } : null
      } : k => v if v != null }
      # Basic disk properties
      diskSizeGB                 = var.disk_size_gb
      osType                     = var.os_type
      hyperVGeneration           = var.hyper_v_generation
      tier                       = var.tier
      maxShares                  = var.max_shares
      diskIOPSReadWrite          = var.disk_iops_read_write
      diskMBpsReadWrite          = var.disk_mbps_read_write
      diskIOPSReadOnly           = var.disk_iops_read_only
      diskMBpsReadOnly           = var.disk_mbps_read_only
      burstingEnabled            = var.on_demand_bursting_enabled
      optimizedForFrequentAttach = var.optimized_frequent_attach_enabled
      networkAccessPolicy        = var.network_access_policy
      publicNetworkAccess        = var.public_network_access_enabled == false ? "Disabled" : "Enabled"
      diskAccessId               = local.disk_access_id
      encryption = var.disk_encryption_set != null ? {
        type                = local.disk_encryption_type
        diskEncryptionSetId = local.disk_encryption_set_id
        } : {
        type = "EncryptionAtRestWithPlatformKey"
      }
      # Security profile
      securityProfile = (var.security_type != null || var.trusted_launch_enabled == true) ? {
        securityType                = var.trusted_launch_enabled == true ? "TrustedLaunch" : var.security_type
        secureVMDiskEncryptionSetId = var.secure_vm_disk_encryption_set_id
      } : null
      encryptionSettingsCollection = var.encryption_settings != null ? {
        enabled = true
        encryptionSettings = [{
          diskEncryptionKey = try(var.encryption_settings.disk_encryption_key, null) != null ? {
            secretUrl = try(var.encryption_settings.disk_encryption_key.secret_url, null)
            sourceVault = {
              id = try(var.encryption_settings.disk_encryption_key.source_vault_id, null)
            }
          } : null
          keyEncryptionKey = try(var.encryption_settings.key_encryption_key, null) != null ? {
            keyUrl = try(var.encryption_settings.key_encryption_key.key_url, null)
            sourceVault = {
              id = try(var.encryption_settings.key_encryption_key.source_vault_id, null)
            }
          } : null
        }]
      } : null
    } : k => v if v != null }
    sku = {
      name = var.storage_account_type
    }
    tags  = var.tags
    zones = var.zone != null ? [var.zone] : null
    extendedLocation = var.edge_zone != null ? {
      name = var.edge_zone
      type = "EdgeZone"
    } : null
  } : k => v if v != null }
}

# State migration block - ensures seamless transition from azurerm_managed_disk to azapi_resource
moved {
  from = azurerm_managed_disk.this
  to   = azapi_resource.this
}

