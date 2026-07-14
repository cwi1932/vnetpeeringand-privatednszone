resource "azurerm_virtual_network" "vnetA" {
  name                = "vnetA-${random_pet.APP_RG1.id}"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnetA_APP_RG1" {
  name                 = "subnetA-${random_pet.APP_RG1.id}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnetA.name
  address_prefixes     = ["192.168.1.0/24"]

}

resource "azurerm_virtual_network" "vnetB" {
  name                = "vnetB-${random_pet.APP_RG1.id}"
  address_space       = ["10.12.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}



resource "azurerm_subnet" "subnetB_APP_RG1" {
  name                 = "subnetB-${random_pet.APP_RG1.id}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnetB.name
  address_prefixes     = ["10.12.2.0/24"]

}


resource "azurerm_virtual_network_peering" "vnetA-to-vnetB" {
  name                      = "vnetA-to-vnetB"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnetA.name
  remote_virtual_network_id = azurerm_virtual_network.vnetB.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}

resource "azurerm_virtual_network_peering" "vnetB-to-vnetA" {
  name                      = "vnetB-to-vnetA"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnetB.name
  remote_virtual_network_id = azurerm_virtual_network.vnetA.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_private_dns_zone" "pvszone" {
  name                = "private_dns_zone-${random_pet.APP_RG1.id}"
  resource_group_name = azurerm_resource_group.rg.name

}

resource "azurerm_private_dns_zone_virtual_network_link" "pvlink" {
  name                  = "pvlink-${random_pet.APP_RG1.id}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pvszone.name
  virtual_network_id    = azurerm_virtual_network.vnetA.id

  registration_enabled = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "pvl" {
  name                  = "pvlink-${random_pet.APP_RG1.id}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pvszone.name
  virtual_network_id    = azurerm_virtual_network.vnetB.id
  registration_enabled  = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "pv" {
  name                  = "pv-${random_pet.APP_RG1.id}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pvszone.id
  virtual_network_id    = azurerm_virtual_network.vnetB.id
}

resource "azurerm_private_dns_a_record" "privatednsrecord" {
  name                = "privatednsrecord"
  resource_group_name = azurerm_resource_group.rg.name
  zone_name           = azurerm_private_dns_zone.pvszone.name
  ttl                 = 300
  records             = azurerm_linux_virtual_machine.App1VMPROD[*].private_ip_address


}
