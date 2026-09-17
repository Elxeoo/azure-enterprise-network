output "spoke_rg_name" { value = azurerm_resource_group.spoke_rg.name }
output "spoke_vnet_id" { value = azurerm_virtual_network.spoke_vnet.id }
output "spoke_vnet_name" { value = azurerm_virtual_network.spoke_vnet.name }
output "storage_account_id" { value = azurerm_storage_account.spoke_storage.id }
output "storage_primary_blob_endpoint" { value = azurerm_storage_account.spoke_storage.primary_blob_endpoint }
output "workload_private_ip" { value = azurerm_network_interface.nic_worker.private_ip_address }
output "ai_container_name" { value = azurerm_storage_container.ai_storage_container.name }