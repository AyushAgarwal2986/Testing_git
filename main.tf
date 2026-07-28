terraform {
  required_providers {
  azurerm = {
source = "hashicorp/azurerm"
version= "4.76.0"

  }

  }
}

provider "azurerm" {
 features { }
}

resource "azurerm_resource_group" "lab-practise" {
 name = "rg-lab"
 location = "japaneast"
}

resource "azurerm_virtual_network" "lab-vnet" {
  name                = "lab-network"
  location            = azurerm_resource_group.lab-practise.location
  resource_group_name = azurerm_resource_group.lab-practise.name
  address_space       = ["10.18.0.0/16"]
  }

  resource "azurerm_subnet" "lab-subnet" {
    depends_on = [ azurerm_virtual_network.lab-vnet ]
  name                 = "lab-subnet"
  resource_group_name  = azurerm_resource_group.lab-practise.name
  virtual_network_name = azurerm_virtual_network.lab-vnet.name
  address_prefixes     = ["10.18.1.0/24"]
}

resource "azurerm_network_security_group" "NSG" {
  name                = "Lab-NSG"
  location            = azurerm_resource_group.lab-practise.location
  resource_group_name = azurerm_resource_group.lab-practise.name

  security_rule {
    name                       = "RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_public_ip" "public_ip" {
  name                = "lab-publicip"
  resource_group_name = azurerm_resource_group.lab-practise.name
  location            = azurerm_resource_group.lab-practise.location
  allocation_method   = "Static"
}
resource "azurerm_network_interface" "NIC" {
  name                = "lab-nic"
  location            = azurerm_resource_group.lab-practise.location
  resource_group_name = azurerm_resource_group.lab-practise.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
    
  }
}
resource "azurerm_network_interface_security_group_association" "nsg-connect" {
  network_interface_id      = azurerm_network_interface.NIC.id
  network_security_group_id = azurerm_network_security_group.NSG.id
}

resource "azurerm_windows_virtual_machine" "lab-vm" {
  name                = "lab-vm"
  resource_group_name = azurerm_resource_group.lab-practise.name
  location            = azurerm_resource_group.lab-practise.location
  size                = "Standard_D2_v3"
  admin_username      = "labadmin"
  admin_password      = "password@123"
  network_interface_ids = [azurerm_network_interface.NIC.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}