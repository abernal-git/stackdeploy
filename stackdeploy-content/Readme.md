============================================================
StackDeploy Blog — README
============================================================
🚀 StackDeploy Blog
Know Your Infra. Build Your Dream.
Blog técnico sobre Linux, RHEL, Docker, Cloud, Automatización y Ansible.
by @abernal093

📁 Estructura del proyecto
stackdeploy/
├── .github/
│   └── workflows/
│       └── deploy.yml          ← Pipeline CI/CD principal
├── docker/
│   └── Dockerfile              ← Multi-stage build
├── nginx/
│   ├── nginx.conf              ← Config nginx
│   └── default.conf            ← Virtual host
├── scripts/
│   ├── setup_azure.sh          ← Setup inicial Azure
│   └── entrypoint.sh           ← Entrypoint del container
├── stackdeploy-content/        ← Sistema de artículos
│   ├── 01_drafts/
│   ├── 02_review/
│   ├── 03_design/
│   ├── 04_ready/
│   └── 05_published/
├── stackdeploy-scripts/        ← Scripts de gestión de contenido
│   ├── 00_dashboard.sh
│   ├── 01_crear_articulo.sh
│   ├── 02_revisar_articulo.sh
│   ├── 03_diseño_articulo.sh
│   └── 04_aprobar_publicacion.sh
├── docker-compose.yml          ← Dev local
└── README.md

🔄 Pipeline CI/CD
Push a develop  →  Build only (sin deploy)
Push a main     →  Build + Deploy STAGING automático
Tag v1.0.0      →  Build + Deploy PRODUCTION (requiere aprobación)
Ambientes
AmbienteTriggerURLAprobaciónDEVLocal (docker compose up)localhost:3000NoSTAGINGPush a mainstackdeploy-staging.azurecontainerapps.ioNoPRODUCTIONTag v*.*.*stackdeploy.dev✅ Sí

🚀 Setup rápido
1. Clonar y configurar localmente
bashgit clone https://github.com/abernal093/stackdeploy.git
cd stackdeploy

# Dev local con Docker
docker compose up --build
# Abre: http://localhost:3000
2. Setup inicial Azure (una sola vez)
bash# Instalar Azure CLI si no lo tienes
# https://docs.microsoft.com/cli/azure/install-azure-cli

az login
bash scripts/setup_azure.sh
3. Configurar GitHub Secrets
En tu repo: Settings → Secrets → Actions → New repository secret
SecretDescripciónAZURE_CLIENT_IDService Principal IDAZURE_CLIENT_SECRETService Principal SecretAZURE_TENANT_IDAzure Tenant IDAZURE_SUBSCRIPTION_IDAzure Subscription IDACR_LOGIN_SERVERstackdeployacr.azurecr.ioACR_USERNAMEACR usernameACR_PASSWORDACR passwordSTAGING_APP_NAMEstackdeploy-stagingPROD_APP_NAMEstackdeploy-prodAZURE_RESOURCE_GROUPstackdeploy-rg
4. Configurar GitHub Environments
En tu repo: Settings → Environments

Crear environment staging (sin restricciones)
Crear environment production → Agregar Required reviewers (tu usuario)


✍️ Flujo de creación de artículos
bash# Panel de control
bash stackdeploy-scripts/00_dashboard.sh

# O paso a paso:
bash stackdeploy-scripts/01_crear_articulo.sh    # Crear borrador
bash stackdeploy-scripts/02_revisar_articulo.sh  # Revisar
bash stackdeploy-scripts/03_diseño_articulo.sh   # Assets
bash stackdeploy-scripts/04_aprobar_publicacion.sh # Aprobar

📦 Deploy manual
bash# Deploy a staging manualmente
git push origin main

# Deploy a producción
git tag v1.0.0
git push origin v1.0.0

🛠️ Comandos útiles
bash# Ver logs del container local
docker compose logs -f blog

# Entrar al container
docker compose exec blog sh

# Rebuild sin cache
docker compose build --no-cache

# Ver estado de Azure Container Apps
az containerapp show --name stackdeploy-staging --resource-group stackdeploy-rg

# Ver logs de producción en Azure
az containerapp logs show --name stackdeploy-prod --resource-group stackdeploy-rg --follow

📊 Plan de crecimiento
FaseMesesMetaFundación0–20–500 visitas/mesTracción2–4500–2K visitas/mesEscala4–62K–5K visitas/mesExpansión6+Podcast + Videos

Built with ❤️ by Andres Bernal — StackDeploy.dev
