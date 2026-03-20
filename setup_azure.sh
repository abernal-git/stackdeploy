#!/bin/bash
# ============================================================
#  StackDeploy — setup_azure.sh
#  Script de configuración inicial de Azure
#  Crea todos los recursos necesarios para el pipeline
#
#  Uso: bash scripts/setup_azure.sh
#  Requisitos: Azure CLI instalado y logueado (az login)
# ============================================================
 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'
 
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   STACKDEPLOY — Azure Setup Inicial      ║"
echo "  ║   by Andres Bernal @abernal093           ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}\n"
 
# ── CONFIGURACIÓN — Edita estos valores ────────────────────
RESOURCE_GROUP="stackdeploy-rg"
LOCATION="eastus"                        # Cambia a tu región preferida
ACR_NAME="stackdeployacr"               # Nombre único del Container Registry
ENVIRONMENT_NAME="stackdeploy-env"      # Azure Container Apps Environment
STAGING_APP="stackdeploy-staging"       # Nombre del Container App staging
PROD_APP="stackdeploy-prod"             # Nombre del Container App producción
LOG_WORKSPACE="stackdeploy-logs"        # Log Analytics Workspace
# ───────────────────────────────────────────────────────────
 
echo -e "${YELLOW}  Configuración:${NC}"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location:       $LOCATION"
echo "  ACR:            $ACR_NAME"
echo ""
read -p "  ¿Continuar con esta configuración? [s/n]: " CONFIRM
[[ "$CONFIRM" != "s" ]] && echo "Cancelado." && exit 0
 
# ── VERIFICAR AZ CLI ───────────────────────────────────────
if ! command -v az &>/dev/null; then
  echo -e "${RED}  ✗ Azure CLI no instalado.${NC}"
  echo "    Instalar: https://docs.microsoft.com/cli/azure/install-azure-cli"
  exit 1
fi
 
# Verificar login
ACCOUNT=$(az account show --query name -o tsv 2>/dev/null)
if [[ -z "$ACCOUNT" ]]; then
  echo -e "${YELLOW}  No estás logueado en Azure. Corriendo az login...${NC}"
  az login
fi
 
echo -e "\n${GREEN}  ✓ Logueado como: $ACCOUNT${NC}\n"
 
# ── 1. RESOURCE GROUP ─────────────────────────────────────
echo -e "${CYAN}  [1/7] Creando Resource Group...${NC}"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags app=stackdeploy owner=abernal093 \
  --output none
echo -e "${GREEN}  ✓ Resource Group: $RESOURCE_GROUP${NC}"
 
# ── 2. AZURE CONTAINER REGISTRY ───────────────────────────
echo -e "\n${CYAN}  [2/7] Creando Azure Container Registry (ACR)...${NC}"
az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Basic \
  --admin-enabled true \
  --output none
echo -e "${GREEN}  ✓ ACR creado: $ACR_NAME.azurecr.io${NC}"
 
# Obtener credenciales ACR
ACR_SERVER="${ACR_NAME}.azurecr.io"
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query "passwords[0].value" -o tsv)
 
# ── 3. LOG ANALYTICS WORKSPACE ────────────────────────────
echo -e "\n${CYAN}  [3/7] Creando Log Analytics Workspace...${NC}"
az monitor log-analytics workspace create \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$LOG_WORKSPACE" \
  --output none
 
LOG_WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$LOG_WORKSPACE" \
  --query customerId -o tsv)
 
LOG_WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$LOG_WORKSPACE" \
  --query primarySharedKey -o tsv)
 
echo -e "${GREEN}  ✓ Log Analytics: $LOG_WORKSPACE${NC}"
 
# ── 4. CONTAINER APPS ENVIRONMENT ─────────────────────────
echo -e "\n${CYAN}  [4/7] Creando Container Apps Environment...${NC}"
az containerapp env create \
  --name "$ENVIRONMENT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --logs-workspace-id "$LOG_WORKSPACE_ID" \
  --logs-workspace-key "$LOG_WORKSPACE_KEY" \
  --output none
echo -e "${GREEN}  ✓ Container Apps Environment: $ENVIRONMENT_NAME${NC}"
 
# ── 5. STAGING CONTAINER APP ──────────────────────────────
echo -e "\n${CYAN}  [5/7] Creando Container App STAGING...${NC}"
az containerapp create \
  --name "$STAGING_APP" \
  --resource-group "$RESOURCE_GROUP" \
  --environment "$ENVIRONMENT_NAME" \
  --image "nginx:alpine" \
  --target-port 80 \
  --ingress external \
  --registry-server "$ACR_SERVER" \
  --registry-username "$ACR_USERNAME" \
  --registry-password "$ACR_PASSWORD" \
  --min-replicas 1 \
  --max-replicas 3 \
  --cpu 0.25 \
  --memory 0.5Gi \
  --env-vars ENVIRONMENT=staging \
  --tags app=stackdeploy environment=staging \
  --output none
echo -e "${GREEN}  ✓ Staging App: $STAGING_APP${NC}"
 
# ── 6. PRODUCTION CONTAINER APP ───────────────────────────
echo -e "\n${CYAN}  [6/7] Creando Container App PRODUCTION...${NC}"
az containerapp create \
  --name "$PROD_APP" \
  --resource-group "$RESOURCE_GROUP" \
  --environment "$ENVIRONMENT_NAME" \
  --image "nginx:alpine" \
  --target-port 80 \
  --ingress external \
  --registry-server "$ACR_SERVER" \
  --registry-username "$ACR_USERNAME" \
  --registry-password "$ACR_PASSWORD" \
  --min-replicas 1 \
  --max-replicas 5 \
  --cpu 0.5 \
  --memory 1.0Gi \
  --env-vars ENVIRONMENT=production \
  --tags app=stackdeploy environment=production \
  --output none
echo -e "${GREEN}  ✓ Production App: $PROD_APP${NC}"
 
# ── 7. OBTENER URLS ───────────────────────────────────────
echo -e "\n${CYAN}  [7/7] Obteniendo URLs...${NC}"
STAGING_URL=$(az containerapp show \
  --name "$STAGING_APP" \
  --resource-group "$RESOURCE_GROUP" \
  --query "properties.configuration.ingress.fqdn" -o tsv)
 
PROD_URL=$(az containerapp show \
  --name "$PROD_APP" \
  --resource-group "$RESOURCE_GROUP" \
  --query "properties.configuration.ingress.fqdn" -o tsv)
 
# ── RESUMEN FINAL ──────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║          ✓ SETUP COMPLETADO EXITOSAMENTE            ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${BOLD}Recursos creados:${NC}"
echo -e "  📦 ACR:           $ACR_SERVER"
echo -e "  🟡 Staging URL:   https://$STAGING_URL"
echo -e "  🟢 Prod URL:      https://$PROD_URL"
echo ""
echo -e "  ${BOLD}${YELLOW}Agrega estos GitHub Secrets en tu repo:${NC}"
echo "  ┌─────────────────────────────────────────────────────"
echo "  │ AZURE_CLIENT_ID       → (de tu Service Principal)"
echo "  │ AZURE_CLIENT_SECRET   → (de tu Service Principal)"
echo "  │ AZURE_TENANT_ID       → $(az account show --query tenantId -o tsv)"
echo "  │ AZURE_SUBSCRIPTION_ID → $(az account show --query id -o tsv)"
echo "  │ ACR_LOGIN_SERVER      → $ACR_SERVER"
echo "  │ ACR_USERNAME          → $ACR_USERNAME"
echo "  │ ACR_PASSWORD          → [ver abajo]"
echo "  │ STAGING_APP_NAME      → $STAGING_APP"
echo "  │ PROD_APP_NAME         → $PROD_APP"
echo "  │ AZURE_RESOURCE_GROUP  → $RESOURCE_GROUP"
echo "  └─────────────────────────────────────────────────────"
echo ""
echo -e "  ${BOLD}ACR Password:${NC} $ACR_PASSWORD"
echo ""
echo -e "  ${CYAN}Próximo paso:${NC} Crea un Service Principal con:"
echo "  az ad sp create-for-rbac \\"
echo "    --name stackdeploy-sp \\"
echo "    --role contributor \\"
echo "    --scopes /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP"
echo ""
 
