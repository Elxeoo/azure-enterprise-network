output  "hub_rg_name" {
    description = "Name of the Hub Resource Group"
    value       = azurerm_resource_group.hub_rg.name
}

output "spoke_rg_name" {
    description = "Name of the Spoke Resource Group"
    value       = azurerm_resource_group.spoke_rg.name
}

output "hub_vnet_id" {
    description = "ID of the Hub Virtual Network"
    value       = azurerm_virtual_network.hub_vnet.id
}

output "spoke_vnet_id" {
    description = "ID of the Spoke Virtual Network"
    value = azurerm_virtual_network.spoke_vnet.id 
}

output "storage_account_id" {
   value = azurerm_storage_account.spoke_storage.id
}

output "storage_primary_blob_endpoint" {
    value = azurerm_storage_account.spoke_storage.primary_blob_endpoint
}

output "jumpbox_public_ip" {
    description = "Public IP address of the Hub Jumpbox"
    value       = azurerm_public_ip.jumpbox_pip.ip_address
}

output "workload_private_ip" {
    value = azurerm_network_interface.nic_worker.private_ip_address
}

output "ai_container_name" {
    value = azurerm_storage_container.ai_storage_container.name   
}