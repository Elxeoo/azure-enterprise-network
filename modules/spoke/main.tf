resource "azurerm_resource_group" "spoke_rg" {
  name     = "rg-enterprise-spoke"
  location = var.location
}

resource "azurerm_virtual_network" "spoke_vnet" {
  name                = "vnet-enterprise-spoke"
  location            = azurerm_resource_group.spoke_rg.location
  address_space       = var.spoke_address_space
  resource_group_name = azurerm_resource_group.spoke_rg.name
}

resource "azurerm_subnet" "spoke_ai_subnet" {
  name                 = "snet-ai-workload"
  resource_group_name  = azurerm_resource_group.spoke_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "spoke_pe_subnet" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.spoke_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["10.1.2.0/24"]
}

resource "azurerm_network_security_group" "ai_nsg" {
  name                = "nsg-ai-workload"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
}

resource "azurerm_subnet_network_security_group_association" "ai_nsg_assoc" {
  subnet_id                 = azurerm_subnet.spoke_ai_subnet.id
  network_security_group_id = azurerm_network_security_group.ai_nsg.id
}



resource "azurerm_route_table" "spoke_rt" {
  name                = "rt-enterprise-spoke"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name

  route {
    name                   = "route-to-hub"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"

  }
}

resource "azurerm_subnet_route_table_association" "spoke_rt_assoc" {
  subnet_id      = azurerm_subnet.spoke_ai_subnet.id
  route_table_id = azurerm_route_table.spoke_rt.id
}

resource "azurerm_storage_account" "spoke_storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.spoke_rg.name
  location                 = azurerm_resource_group.spoke_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access    = "Disabled"
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
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [var.hub_dns_zone_id]
  }
}

resource "azurerm_network_interface" "nic_worker" {
  name                = "nic-worker"
  resource_group_name = azurerm_resource_group.spoke_rg.name
  location            = azurerm_resource_group.spoke_rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke_ai_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "tls_private_key" "workload_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "azurerm_linux_virtual_machine" "workload_vm" {
  name                  = "workload-vm"
  resource_group_name   = azurerm_resource_group.spoke_rg.name
  location              = azurerm_resource_group.spoke_rg.location
  size                  = "Standard_D2s_v5"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic_worker.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.workload_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "azurerm_storage_container" "ai_storage_container" {
  name                  = "ai-input-data"
  storage_account_id    = azurerm_storage_account.spoke_storage.id
  container_access_type = "private"
}