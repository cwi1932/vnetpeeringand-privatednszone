output "resource_group_name" {
  description = "The name of the generated Resource Group"
  value       = azurerm_resource_group.rg.name
}




output "Azurerm_windows_virtual_machine_name" {
  description = "The name of the generated Resource Group"
  value       = azurerm_windows_virtual_machine.App1VMDEV[*].name
}

output "Azurerm_linux_virtual_machine_name" {
  description = "The name of the generated Resource Group"
  value = {
    linux_vm_name     = azurerm_linux_virtual_machine.App1VMPROD[*].name
    network_interface = azurerm_network_interface.App1VMNIC[*].id

  }

}
output "ssh_private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}
output "azurerm_linux_virtual_machine_private_IP_address" {
  description = "The private IP address of the generated Resource Group"

  value = {
    vm_name                          = azurerm_linux_virtual_machine.App1VMPROD[*].name
    Linux_VM_IP                      = azurerm_linux_virtual_machine.App1VMPROD[*].private_ip_address
    Resource_Group_Name_for_linux_VM = azurerm_resource_group.rg.name
    Currrent_subscription_ID         = data.azurerm_client_config.current.subscription_id
    sensitive                        = true
  }
}
output "azurerm_windows_virtual_machine_private_IP_address" {
  description = "The private IP address of the generated Resource Group"
  value       = azurerm_windows_virtual_machine.App1VMDEV[*].private_ip_address
  sensitive   = true
}

output "azurerm_storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.storage.name
}

output "azurerm_key_vault_name" {
  description = "The name of the key vault"
  value       = azurerm_key_vault.keyvault.name
}

