resource "azurerm_resource_group" "site" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# The Static Web App that hosts cloud-architecture.co.uk.
# Deployment is decoupled: the site repo's GitHub Actions workflow deploys to it
# using the deployment_token output below (BYO workflow, no repo linkage here).
resource "azurerm_static_web_app" "site" {
  name                = var.static_web_app_name
  resource_group_name = azurerm_resource_group.site.name
  location            = var.location
  sku_tier            = var.sku_tier
  sku_size            = var.sku_size
  tags                = var.tags
}

resource "azurerm_static_web_app_custom_domain" "custom" {
  count             = var.custom_domain == "" ? 0 : 1
  static_web_app_id = azurerm_static_web_app.site.id
  domain_name       = var.custom_domain
  validation_type   = "cname-delegation"
}
