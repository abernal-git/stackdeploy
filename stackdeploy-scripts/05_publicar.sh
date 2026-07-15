#!/bin/bash
# ============================================================
#  StackDeploy — Script 05: Publicar
#  Corre build_blog.py, hace commit y push a main.
#  Uso:  ./05_publicar.sh "mensaje de commit opcional"
# ============================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

# Raíz del repo (un nivel arriba de este script)
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo -e "${CYAN}${BOLD}  StackDeploy — Publicar${NC}"
echo -e "  ─────────────────────────────\n"

# Limpiar lock huérfano por si una corrida previa quedó a medias
[[ -f .git/index.lock ]] && rm -f .git/index.lock

# 1. Build: 04_ready -> HTML + index + mueve a 05_published
echo -e "${YELLOW}[1/3] Generando el sitio (build_blog.py)...${NC}"
python3 build_blog.py

# 2. Commit
echo -e "\n${YELLOW}[2/3] Commit...${NC}"
git add -A
if git diff --cached --quiet; then
  echo -e "  ${YELLOW}Nada nuevo que commitear.${NC}"
else
  MSG="${1:-chore: publish articles $(date +%F)}"
  git commit -m "$MSG"
  echo -e "  ${GREEN}Commit creado:${NC} $MSG"
fi

# 3. Push -> dispara GitHub Actions -> deploy Azure
echo -e "\n${YELLOW}[3/3] Push a main...${NC}"
if git push origin main; then
  echo -e "\n${GREEN}${BOLD}  ✓ Publicado. GitHub Actions desplegará a Azure.${NC}\n"
else
  echo -e "\n${RED}  ✗ Push falló. Revisa credenciales/red y reintenta.${NC}\n"
  exit 1
fi
