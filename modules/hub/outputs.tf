output  "rg_name" {
    value       = azurerm_resource_group.hub_rg.name
}

output "vnet_id" {
    value = azurerm_virtual_network.hub_vnet.id
}

output "vnet_name" {
    value = azurerm_virtual_network.hub_vnet.name
}

output "dns_zone_id" {
    value = azurerm_private_dns_zone.blob_dns_zone.id
}

output "jumpbox_public_ip" {
  value = azurerm_public_ip.jumpbox_pip.ip_address
}