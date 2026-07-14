resource "azurerm_linux_virtual_machine" "App1VMPROD" {
  count                 = 3
  name                  = "App1VM-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.App1VMNIC[count.index].id]
  size                  = "Standard_B2s"
  admin_username        = "azureuser"
  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.ssh.public_key_openssh

  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-22_04-lts"
    sku       = "22_04-lts"
    version   = "latest"
  }


}

resource "azurerm_windows_virtual_machine" "App1VMDEV" {
  count                 = 2
  name                  = "App1VM-${count.index + 1}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.App1VMNIC[count.index].id]
  size                  = "Standard_B2s"
  admin_username        = "azureuser"
  admin_password        = "P@ssword1234!"





  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-windows-server-22_04-lts"
    sku       = "22_04-lts"
    version   = "latest"
  }

}

resource "azurerm_network_interface" "App1VMNIC" {
  count               = 3
  name                = "App1VMNIC-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetA_APP_RG1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "AppVMNIC" {
  count               = 2
  name                = "App1VMNIC-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetB_APP_RG1.id
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_network_security_group" "App1VMNSG" {
  name                = "App1VMNSG-${random_pet.APP_RG1.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"

  }

}


resource "azurerm_network_security_group" "AppVMNSG" {
  name                = "AppVMNSG-${random_pet.APP_RG1.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"

  }

}
resource "azurerm_subnet_network_security_group_association" "_AppVMNSG" {
  subnet_id                 = azurerm_subnet.subnetA_APP_RG1.id
  network_security_group_id = azurerm_network_security_group.AppVMNSG.id
}

resource "azurerm_subnet_network_security_group_association" "_App1VMNSG" {
  subnet_id                 = azurerm_subnet.subnetB_APP_RG1.id
  network_security_group_id = azurerm_network_security_group.App1VMNSG.id
}
