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

# This allows us to randomize the zone for the disk group.
resource "random_integer" "zone" {
  max = 3
  min = 1
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

# This is the module call
module "disk" {
  source = "../../"

  create_option = "Empty"
  # source             = "Azure/avm-res-compute-disk/azurerm"
  # ...
  location               = azurerm_resource_group.this.location
  name                   = module.naming.managed_disk.name_unique
  resource_group_name    = azurerm_resource_group.this.name
  storage_account_type   = "Premium_LRS"
  zone                   = random_integer.zone.result
  disk_encryption_set_id = azurerm_disk_encryption_set.this.id
  disk_size_gb           = 1024
  enable_telemetry       = var.enable_telemetry # see variables.tf
  network_access_policy  = "AllowAll"
}
