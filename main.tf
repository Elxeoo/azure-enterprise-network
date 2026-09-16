resource "azurerm_resource_group" "hub_rg" {
    name     = "rg-enterprise-hub"
    location = var.location
}

resource "azurerm_virtual_network" "hub_vnet" {
    name                = "vnet-enterprise-hub"
    resource_group_name = azurerm_resource_group.hub_rg.name
    location            = azurerm_resource_group.hub_rg.location
    address_space       = var.hub_address_space
}

resource "azurerm_subnet" "gateway_subnet" {
    name                 = "GatewaySubnet"
    resource_group_name  = azurerm_resource_group.hub_rg.name
    virtual_network_name = azurerm_virtual_network.hub_vnet.name
    address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "azurefirewall_subnet" {
    name                 = "AzureFirewallSubnet"
    resource_group_name  = azurerm_resource_group.hub_rg.name
    virtual_network_name = azurerm_virtual_network.hub_vnet.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "snetmanagement_subnet" {
    name                 = "snet-management"
    resource_group_name  = azurerm_resource_group.hub_rg.name
    virtual_network_name = azurerm_virtual_network.hub_vnet.name
    address_prefixes     = ["10.0.10.0/24"]
}

resource "azurerm_resource_group" "spoke_rg" {
    name    = "rg-enterprise-spoke"
    location = azurerm_resource_group.hub_rg.location
}

resource "azurerm_virtual_network" "spoke_vnet" {
    name    = "vnet-enterprise-spoke"
    location = azurerm_resource_group.spoke_rg.location
    address_space = var.spoke_address_space
    resource_group_name = azurerm_resource_group.spoke_rg.name
}

resource "azurerm_subnet" "spoke_ai_subnet" {
    name    = "snet-ai-workload"
    resource_group_name = azurerm_resource_group.spoke_rg.name
    virtual_network_name = azurerm_virtual_network.spoke_vnet.name
    address_prefixes = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "spoke_pe_subnet" {
    name    = "snet-private-endpoints"
    resource_group_name = azurerm_resource_group.spoke_rg.name
    virtual_network_name = azurerm_virtual_network.spoke_vnet.name
    address_prefixes = ["10.1.2.0/24"]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
    name    = "peer-hub-to-spoke"
    resource_group_name = azurerm_resource_group.hub_rg.name
    virtual_network_name = azurerm_virtual_network.hub_vnet.name
    remote_virtual_network_id = azurerm_virtual_network.spoke_vnet.id
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
    name    = "peer-spoke-to-hub"
    resource_group_name = azurerm_resource_group.spoke_rg.name
    virtual_network_name = azurerm_virtual_network.spoke_vnet.name
    remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
}

resource "azurerm_network_security_group" "mgmt_nsg" {
    name    = "nsg-management"
    location = azurerm_resource_group.hub_rg.location
    resource_group_name = azurerm_resource_group.hub_rg.name
}

resource "azurerm_subnet_network_security_group_association" "mgmt_nsg_assoc" {
    subnet_id = azurerm_subnet.snetmanagement_subnet.id
    network_security_group_id = azurerm_network_security_group.mgmt_nsg.id
}

resource "azurerm_network_security_group" "ai_nsg" {
    name    = "nsg-ai-workload"
    location = azurerm_resource_group.spoke_rg.location
    resource_group_name = azurerm_resource_group.spoke_rg.name
}

resource "azurerm_subnet_network_security_group_association" "ai_nsg_assoc" {
    subnet_id = azurerm_subnet.spoke_ai_subnet.id
    network_security_group_id = azurerm_network_security_group.ai_nsg.id
    }

resource "azurerm_network_security_rule" "allow_ssh" {
    name    = "Allow-SSH-Inbound"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = azurerm_resource_group.hub_rg.name
    network_security_group_name = azurerm_network_security_group.mgmt_nsg.name
}

resource "azurerm_route_table" "spoke_rt" {
    name    = "rt-enterprise-spoke"
    location = azurerm_resource_group.spoke_rg.location
    resource_group_name = azurerm_resource_group.spoke_rg.name
    
    route {
        name = "route-to-hub"
        address_prefix = "0.0.0.0/0"
        next_hop_type = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.1.4"

    }
}

resource "azurerm_subnet_route_table_association" "spoke_rt_assoc" {
    subnet_id = azurerm_subnet.spoke_ai_subnet.id
    route_table_id = azurerm_route_table.spoke_rt.id
}

resource "azurerm_storage_account" "spoke_storage" {
    name = var.storage_account_name
    resource_group_name = azurerm_resource_group.spoke_rg.name
    location = azurerm_resource_group.spoke_rg.location
    account_tier = "Standard"
    account_replication_type = "LRS"
    public_network_access = "Disabled" 
}

resource "azurerm_private_endpoint" "storage_pe" {
    name                = "pe-storage-blob"
    location            = azurerm_resource_group.spoke_rg.location
    resource_group_name = azurerm_resource_group.spoke_rg.name
    subnet_id           = azurerm_subnet.spoke_pe_subnet.id

    private_service_connection {
        name                           = "psc-storage-blob"
        private_connection_resource_id = azurerm_storage_account.spoke_storage.id
        subresource_names              = ["blob"]
        is_manual_connection          = false 
    }

    private_dns_zone_group {
        name                 = "blob-dns-zone-group"
        private_dns_zone_ids = [azurerm_private_dns_zone.blob_dns_zone.id]
    }
}

resource "azurerm_private_dns_zone" "blob_dns_zone" {
    name = "privatelink.blob.core.windows.net"
    resource_group_name = azurerm_resource_group.hub_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_dns_link" {
    name                  = "link-to-spoke-vnet"
    private_dns_zone_id   = azurerm_private_dns_zone.blob_dns_zone.id
    virtual_network_id    = azurerm_virtual_network.spoke_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_dns_link" {
    name                  = "link-to-hub-vnet"
    private_dns_zone_id   = azurerm_private_dns_zone.blob_dns_zone.id
    virtual_network_id    = azurerm_virtual_network.hub_vnet.id
}

resource "azurerm_public_ip" "jumpbox_pip" {
    name = "pip-jumpbox-hub"
    resource_group_name = azurerm_resource_group.hub_rg.name
    location = azurerm_resource_group.hub_rg.location
    allocation_method = "Static"
    sku = "Standard"
}

resource "azurerm_network_interface" "jumpbox_nic" {
    name = "nic-jumpbox-hub"
    location = azurerm_resource_group.hub_rg.location
    resource_group_name = azurerm_resource_group.hub_rg.name
    
    ip_configuration {
        name = "internal"
        subnet_id = azurerm_subnet.snetmanagement_subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.jumpbox_pip.id
    }
}

resource "azurerm_linux_virtual_machine" "jumpbox_vm" {
    name = "vm-jumpbox-hub"
    resource_group_name = azurerm_resource_group.hub_rg.name
    location = azurerm_resource_group.hub_rg.location
    size = "Standard_D2s_v5"
    admin_username = "azureuser"
    network_interface_ids = [azurerm_network_interface.jumpbox_nic.id]

    admin_ssh_key {
        username = "azureuser"
        public_key = file("~/.ssh/id_rsa.pub")
    }

    os_disk {
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
       publisher = "Canonical"
       offer = "0001-com-ubuntu-server-jammy"
       sku = "22_04-lts"
       version = "latest"
    }
}

resource "azurerm_network_interface" "nic_worker" {
    name = "nic-worker"
    resource_group_name = azurerm_resource_group.spoke_rg.name
    location = azurerm_resource_group.spoke_rg.location

    ip_configuration {
        name = "internal"
        subnet_id = azurerm_subnet.spoke_ai_subnet.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_linux_virtual_machine" "workload_vm" {
    name = "workload-vm"
    resource_group_name = azurerm_resource_group.spoke_rg.name
    location = azurerm_resource_group.spoke_rg.location
    size = "Standard_D2s_v5"
    admin_username = "azureuser"
    network_interface_ids = [azurerm_network_interface.nic_worker.id]
    admin_ssh_key {
        username = "azureuser"
        public_key = file("~/.ssh/id_rsa.pub")
    }

    os_disk {
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
       publisher = "Canonical"
       offer = "0001-com-ubuntu-server-jammy"
       sku = "22_04-lts"
       version = "latest"
    }
}

resource "azurerm_storage_container" "ai_storage_container" {
    name = "ai-input-data"
    storage_account_id = azurerm_storage_account.spoke_storage.id
    container_access_type = "private"
}

