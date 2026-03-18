output "app_service_url" {
  description = "URL pública del App Service"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "acr_login_server" {
  description = "Login server del Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  description = "Nombre del Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "resource_group_name" {
  description = "Nombre del Resource Group"
  value       = azurerm_resource_group.main.name
}

output "app_service_name" {
  description = "Nombre del App Service"
  value       = azurerm_linux_web_app.main.name
}
