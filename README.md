# Azure IaC — App Service + Container Registry

Infraestructura como código en Terraform para desplegar un contenedor en Azure App Service con imágenes desde Azure Container Registry (ACR).

## Estructura

```
az-iac/
├── terraform/
│   ├── main.tf                    # Recursos principales
│   ├── variables.tf               # Variables de entrada
│   ├── locals.tf                  # Locals (tags, etc.)
│   ├── outputs.tf                 # Outputs
│   └── terraform.tfvars.example   # Ejemplo de variables
└── pipelines/
    └── terraform-pipeline.yml     # Pipeline de Azure DevOps
```

## Recursos que crea

| Recurso | Descripción |
|---------|-------------|
| `azurerm_resource_group` | Resource Group contenedor |
| `azurerm_container_registry` | ACR (SKU Basic) con admin deshabilitado |
| `azurerm_service_plan` | App Service Plan Linux |
| `azurerm_linux_web_app` | Web App con contenedor Docker |
| `azurerm_role_assignment` | Rol AcrPull asignado al App Service (Managed Identity) |

## Pre-requisitos

### 1. Backend de Terraform (Storage Account)

Crea el backend manualmente antes del primer `terraform init`:

```bash
az group create --name rg-tfstate --location eastus2

az storage account create \
  --name satfstate \
  --resource-group rg-tfstate \
  --sku Standard_LRS \
  --min-tls-version TLS1_2

az storage container create \
  --name tfstate \
  --account-name satfstate
```

> Ajusta el nombre del storage account (debe ser globalmente único) y actualiza `backend "azurerm"` en `main.tf`.

### 2. Service Principal para Terraform

```bash
az ad sp create-for-rbac \
  --name sp-terraform \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>
```

Guarda el output: `appId`, `password`, `tenant`.

## Uso local

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edita terraform.tfvars con tus valores

terraform init
terraform plan
terraform apply
```

## Pipeline de Azure DevOps

### Variable Groups

Crea un variable group llamado `terraform-<ambiente>` (ej. `terraform-dev`) en Azure DevOps > Pipelines > Library con estas variables:

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `AZURE_SERVICE_CONNECTION` | Nombre de la service connection en ADO | `sc-azure-dev` |
| `TF_BACKEND_RG` | Resource group del backend | `rg-tfstate` |
| `TF_BACKEND_SA` | Storage account del backend | `satfstate` |
| `TF_BACKEND_CONTAINER` | Container del backend | `tfstate` |
| `APP_NAME` | Nombre de la app | `myapp` |
| `AZURE_LOCATION` | Región de Azure | `eastus2` |
| `DOCKER_IMAGE_NAME` | Nombre de la imagen | `myapp` |
| `DOCKER_IMAGE_TAG` | Tag de la imagen | `latest` |
| `APP_SERVICE_SKU` | SKU del App Service Plan | `B1` |
| `CONTAINER_PORT` | Puerto del contenedor | `8080` |

### Service Connection

En Azure DevOps > Project Settings > Service Connections, crea una Azure Resource Manager service connection con el Service Principal creado anteriormente.

### Stages del pipeline

| Stage | Trigger | Descripción |
|-------|---------|-------------|
| **Validate** | Siempre | `fmt -check` + `validate` |
| **Plan** | Tras Validate | Genera y publica el plan como artifact |
| **Apply** | Solo en `main` + acción `apply` | Aplica el plan (requiere approval gate) |
| **Destroy** | Solo acción `destroy` | Destruye la infra (approval gate separado) |

### Approval Gates

Configura approvals en Azure DevOps > Environments para `dev`, `stg`, `prod` y `prod-destroy` según necesites.

## Flujo típico

1. **PR** → se ejecutan `Validate` + `Plan` automáticamente.
2. **Merge a main** → se puede ejecutar el pipeline manualmente eligiendo `action: apply`.
3. Aprobador valida el plan y aprueba en el Environment gate.
4. Se ejecuta `terraform apply` con el plan ya generado.

## Push de imagen al ACR

Una vez creada la infraestructura:

```bash
az acr login --name acr<app_name><environment>

docker tag myapp:latest acr<app_name><environment>.azurecr.io/myapp:latest
docker push acr<app_name><environment>.azurecr.io/myapp:latest
```
