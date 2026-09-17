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

resource "azurerm_network_security_group" "mgmt_nsg" {
    name    = "nsg-management"
    location = azurerm_resource_group.hub_rg.location
    resource_group_name = azurerm_resource_group.hub_rg.name
}

resource "azurerm_subnet_network_security_group_association" "mgmt_nsg_assoc" {
    subnet_id = azurerm_subnet.snetmanagement_subnet.id
    network_security_group_id = azurerm_network_security_group.mgmt_nsg.id
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

resource "azurerm_private_dns_zone" "blob_dns_zone" {
    name = "privatelink.blob.core.windows.net"
    resource_group_name = azurerm_resource_group.hub_rg.name
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