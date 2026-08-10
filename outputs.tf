output "default_host_name" {
  description = "The *.azurestaticapps.net hostname."
  value       = azurerm_static_web_app.site.default_host_name
}

output "resource_group" {
  value = azurerm_resource_group.site.name
}

output "deployment_token" {
  description = "Put this in the site repo's GitHub secret AZURE_STATIC_WEB_APPS_API_TOKEN."
  value       = azurerm_static_web_app.site.api_key
  sensitive   = true
}
