variable "app_name" {
  description = "Nombre de la aplicación (sin espacios, minúsculas)"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "El ambiente debe ser: dev, stg o prod."
  }
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "eastus2"
}

variable "app_service_sku" {
  description = "SKU del App Service Plan (B1, B2, P1v3, etc.)"
  type        = string
  default     = "B1"
}

variable "docker_image_name" {
  description = "Nombre de la imagen Docker (sin tag)"
  type        = string
}

variable "docker_image_tag" {
  description = "Tag de la imagen Docker"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Puerto expuesto por el contenedor"
  type        = string
  default     = "8000"
}

variable "dummy_var" {
  description = "Puerto expuesto por el contenedor"
  type        = string
  default     = "8000"
}
