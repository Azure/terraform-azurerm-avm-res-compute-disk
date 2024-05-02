# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

# This is the module call
module "disk" {
  source = "../../"
  # source             = "Azure/avm-res-compute-disk/azurerm"
  # ...
  location            = azurerm_resource_group.this.location
  name                = module.naming.managed_disk.name_unique
  resource_group_name = azurerm_resource_group.this.name

  enable_telemetry = var.enable_telemetry # see variables.tf
  create_option = "Empty"
  storage_account_type = "Premium_LRS"
  disk_size_gb = 1024
}

/*
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
*/