resource "random_pet" "APP_RG1" {
  length    = 2
  separator = ""
}
resource "azurerm_resource_group" "rg" {
  name     = random_pet.APP_RG1.id
  location = var.location
}

data "azurerm_client_config" "current" {}

resource "random_password" "windows_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}




resource "azurerm_storage_account" "storage" {

  name                     = "st${random_pet.APP_RG1.id}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_private_endpoint" "pe" {

  name                = "pe-${random_pet.APP_RG1.id}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = azurerm_subnet.subnetA_APP_RG1.id

  private_service_connection {
    name                           = "psp-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

}


resource "azurerm_user_assigned_identity" "vm_identity" {
  name                = "vm-identity-${random_pet.APP_RG1.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}



resource "azurerm_key_vault" "keyvault" {

  name                       = "kv-${random_pet.APP_RG1.id}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  rbac_authorization_enabled = true
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

}
resource "azurerm_key_vault_secret" "windows_admin_password" {
  name         = "windows-admin-password"
  value        = random_password.windows_admin_password.result
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on = [
    azurerm_role_assignment.terraform_user_kv_role
  ]
}



resource "azurerm_role_assignment" "linux_vm_kv_role" {
  scope                = azurerm_key_vault.keyvault.id
  principal_id         = azurerm_user_assigned_identity.vm_identity.principal_id
  role_definition_name = "Key Vault Administrator"
}
resource "azurerm_role_assignment" "terraform_user_kv_role" {
  scope                = azurerm_key_vault.keyvault.id
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Secrets Officer"
}

