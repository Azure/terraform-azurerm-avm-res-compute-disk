## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "~> 0.3"
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
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
  tags     = local.tags
}

data "azurerm_client_config" "current" {}

# This is the module call
module "disk" {
  source = "../../"
  # source             = "Azure/avm-res-compute-disk/azurerm"
  # ...
  location            = azurerm_resource_group.this.location
  name                = module.naming.managed_disk.name_unique
  resource_group_name = azurerm_resource_group.this.name
  zone                = random_integer.zone.result

  enable_telemetry      = var.enable_telemetry # see variables.tf
  create_option         = "Empty"
  storage_account_type  = "Premium_LRS"
  disk_size_gb          = 1024
  tags                  = local.tags
  network_access_policy = "AllowAll"

  # Uncomment the code below to implement a VMSS Lock
  #lock = {
  #  name = "VMSSNoDelete"
  #  kind = "CanNotDelete"
  #}

  # Example role assignment
  role_assignments = {
    role_assignment = {
      principal_id               = data.azurerm_client_config.current.object_id
      role_definition_id_or_name = "Reader"
      description                = "Assign the Reader role to the deployment user on this disk resource scope."
    }
  }
}
