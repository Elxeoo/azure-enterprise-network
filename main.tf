module "hub" {
  source            = "./modules/hub"
  location          = var.location
  hub_address_space = var.hub_address_space
}

module "spoke" {
  source               = "./modules/spoke"
  location             = var.location
  spoke_address_space  = var.spoke_address_space
  storage_account_name = var.storage_account_name
  hub_dns_zone_id      = module.hub.dns_zone_id
}


resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-spoke"
  resource_group_name       = module.hub.rg_name
  virtual_network_name      = module.hub.vnet_name
  remote_virtual_network_id = module.spoke.spoke_vnet_id
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-spoke-to-hub"
  resource_group_name       = module.spoke.spoke_rg_name
  virtual_network_name      = module.spoke.spoke_vnet_name
  remote_virtual_network_id = module.hub.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_dns_link" {
  name                = "link-to-spoke-vnet"
  private_dns_zone_id = module.hub.dns_zone_id
  virtual_network_id  = module.spoke.spoke_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_dns_link" {
  name                = "link-to-hub-vnet"
  private_dns_zone_id = module.hub.dns_zone_id
  virtual_network_id  = module.hub.vnet_id
}



