locals {
  tags = {
    environment = var.environment
    app         = var.app_name
    managed_by  = "terraform"
  }
}
