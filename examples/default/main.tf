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
  tags     = local.tags
}

# A vnet is required for the private endpoint.
resource "azurerm_virtual_network" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["192.168.0.0/24"]
  tags                = local.tags
}

resource "azurerm_subnet" "this" {
  address_prefixes     = ["192.168.0.0/24"]
  name                 = module.naming.subnet.name_unique
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_disk_access" "this" {
  location            = azurerm_resource_group.this.location
  name                = replace(azurerm_resource_group.this.name, "rg", "da") # Naming module does not support disk access
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

# This is the module call
module "disk" {
  source = "../../"

  create_option = "Empty"
  # source             = "Azure/avm-res-compute-disk/azurerm"
  # ...
  location              = azurerm_resource_group.this.location
  name                  = module.naming.managed_disk.name_unique
  resource_group_name   = azurerm_resource_group.this.name
  storage_account_type  = "Premium_LRS"
  zone                  = random_integer.zone.result
  disk_access_id        = azurerm_disk_access.this.id
  disk_size_gb          = 1024
  enable_telemetry      = var.enable_telemetry # see variables.tf
  network_access_policy = "AllowPrivate"
  private_endpoints = {
    pe_endpoint = {
      name                            = module.naming.private_endpoint.name_unique
      private_dns_zone_resource_ids   = [azurerm_private_dns_zone.this.id]
      private_service_connection_name = "pse-${module.naming.private_endpoint.name_unique}"
      subnet_resource_id              = azurerm_subnet.this.id
    }
  }
  tags = local.tags
}
