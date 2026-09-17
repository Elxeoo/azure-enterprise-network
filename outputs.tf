

output "spoke_rg_name" {
  description = "Name of the Spoke Resource Group"
  value       = module.spoke.spoke_rg_name
}

output "hub_vnet_id" {
  description = "ID of the Hub Virtual Network"
  value       = module.hub.vnet_id
}

output "spoke_vnet_id" {
  description = "ID of the Spoke Virtual Network"
  value       = module.spoke.spoke_vnet_id
}

output "storage_account_id" {
  value = module.spoke.storage_account_id
}

output "storage_primary_blob_endpoint" {
  value = module.spoke.storage_primary_blob_endpoint
}

output "jumpbox_public_ip" {
  description = "Public IP address of the Hub Jumpbox"
  value       = module.hub.jumpbox_public_ip
}

output "workload_private_ip" {
  value = module.spoke.workload_private_ip
}

output "ai_container_name" {
  value = module.spoke.ai_container_name
}