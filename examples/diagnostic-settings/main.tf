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
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

# This is the module call
module "disk" {
  source = "../../"
  # source             = "Azure/avm-res-compute-disk/azurerm"
  # ...
  location            = azurerm_resource_group.this.location
  name                = module.naming.managed_disk.name_unique
  resource_group_name = azurerm_resource_group.this.name

  enable_telemetry     = var.enable_telemetry # see variables.tf
  create_option        = "Empty"
  storage_account_type = "PremiumV2_LRS"
  disk_size_gb         = 1024
  tags                 = local.tags
  diagnostic_settings = {
    to_la = {
      name                  = "to-la"
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
    }
  }
}