terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "satfstate"
    container_name       = "tfstate"
    key                  = "app.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# --- Resource Group ---
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.app_name}-${var.environment}"
  location = var.location
  tags     = local.tags
}

# --- Azure Container Registry ---
resource "azurerm_container_registry" "acr" {
  name                = "acr${var.app_name}${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = local.tags
}

# --- App Service Plan ---
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.app_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  tags                = local.tags
}

# --- App Service (Web App for Containers) ---
resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.app_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  tags                = local.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = true

    application_stack {
      docker_image_name   = "${var.docker_image_name}:${var.docker_image_tag}"
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
    }
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    DOCKER_REGISTRY_SERVER_URL          = "https://${azurerm_container_registry.acr.login_server}"
    WEBSITES_PORT                       = var.container_port
  }
}

# --- Role Assignment: App Service puede leer del ACR ---
resource "azurerm_role_assignment" "app_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}
