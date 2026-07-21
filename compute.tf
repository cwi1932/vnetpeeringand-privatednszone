resource "azurerm_linux_virtual_machine" "App1VMPROD" {
  count                 = 1
  name                  = "App1VM-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.App1VMNIC[count.index].id]
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
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
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }


}

resource "azurerm_virtual_machine_extension" "App1VMNGINX" {
  count                = 1
  name                 = "App1VMNGINX-${count.index + 1}"
  virtual_machine_id   = azurerm_linux_virtual_machine.App1VMPROD[count.index].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"


  settings = <<SETTINGS
    {
      "commandToExecute": "export DEBIAN_FRONTEND=noninteractive && while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 5; done && sudo apt-get update -y && sudo apt-get install -y nginx"
    }
SETTINGS
}
resource "azurerm_windows_virtual_machine" "App1VMDEV" {
  count                 = 1
  name                  = "AppVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.AppVMNIC[count.index].id]
  size                  = "Standard_B1s"
  admin_username        = "azureuser"
  admin_password        = azurerm_key_vault_secret.windows_admin_password.value
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm_identity.id]
  }



  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

}

resource "azurerm_network_interface" "App1VMNIC" {
  count               = 1
  name                = "App1VMNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetA_APP_RG1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "AppVMNIC" {
  count               = 1
  name                = "AppVMNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetB_APP_RG1.id
    private_ip_address_allocation = "Dynamic"

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
  subnet_id                 = azurerm_subnet.subnetB_APP_RG1.id
  network_security_group_id = azurerm_network_security_group.AppVMNSG.id
}

resource "azurerm_subnet_network_security_group_association" "_App1VMNSG" {
  subnet_id                 = azurerm_subnet.subnetA_APP_RG1.id
  network_security_group_id = azurerm_network_security_group.App1VMNSG.id
}
