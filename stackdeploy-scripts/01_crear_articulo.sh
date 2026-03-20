#!/bin/bash
# ============================================================
#  StackDeploy — Script 01: Crear Artículo
#  Crea un nuevo artículo en 01_drafts/
# ============================================================
 
# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'
 
# Directorio base (relativo al script)
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)/stackdeploy-content"
DRAFTS="$BASE_DIR/01_drafts"
 
clear
echo -e "${CYAN}${BOLD}"
echo "  ███████╗████████╗ █████╗  ██████╗██╗  ██╗"
echo "  ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝"
echo "  ███████╗   ██║   ███████║██║     █████╔╝ "
echo "  ╚════██║   ██║   ██╔══██║██║     ██╔═██╗ "
echo "  ███████║   ██║   ██║  ██║╚██████╗██║  ██╗"
echo "  ╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝"
echo -e "${NC}"
echo -e "${BOLD}  DEPLOY  —  Script 01: Nuevo Artículo${NC}"
echo -e "  ─────────────────────────────────────────\n"
 
# ── 1. TÍTULO ──────────────────────────────────────────────
echo -e "${YELLOW}[1/6] TÍTULO DEL ARTÍCULO${NC}"
echo -e "      (Sé descriptivo, incluye la keyword principal)\n"
read -p "  → Título: " TITLE
 
if [[ -z "$TITLE" ]]; then
  echo -e "\n${RED}  ✗ El título no puede estar vacío.${NC}\n"
  exit 1
fi
 
# Generar slug (nombre de archivo)
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g')
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="${DATE}_${SLUG}.txt"
FILEPATH="$DRAFTS/$FILENAME"
 
# Verificar duplicado
if [[ -f "$FILEPATH" ]]; then
  echo -e "\n${RED}  ✗ Ya existe un artículo con ese nombre: $FILENAME${NC}\n"
  exit 1
fi
 
# ── 2. CATEGORÍA ───────────────────────────────────────────
echo -e "\n${YELLOW}[2/6] CATEGORÍA${NC}"
echo "  1) RHEL / Linux"
echo "  2) Docker / Containers"
echo "  3) Cloud (AWS / Azure / GCP)"
echo "  4) Ansible / Automatización"
echo "  5) CI/CD / DevOps"
echo "  6) Kubernetes"
echo "  7) Seguridad / SELinux"
echo "  8) Otro"
echo ""
read -p "  → Selecciona [1-8]: " CAT_NUM
 
case $CAT_NUM in
  1) CATEGORY="RHEL / Linux" ;;
  2) CATEGORY="Docker / Containers" ;;
  3) CATEGORY="Cloud" ;;
  4) CATEGORY="Ansible / Automatización" ;;
  5) CATEGORY="CI/CD / DevOps" ;;
  6) CATEGORY="Kubernetes" ;;
  7) CATEGORY="Seguridad / SELinux" ;;
  8) CATEGORY="Otro" ;;
  *) CATEGORY="Sin categoría" ;;
esac
 
# ── 3. NIVEL DE DIFICULTAD ─────────────────────────────────
echo -e "\n${YELLOW}[3/6] NIVEL DE DIFICULTAD${NC}"
echo "  1) Beginner"
echo "  2) Intermediate"
echo "  3) Advanced"
echo ""
read -p "  → Selecciona [1-3]: " LEVEL_NUM
 
case $LEVEL_NUM in
  1) LEVEL="Beginner" ;;
  2) LEVEL="Intermediate" ;;
  3) LEVEL="Advanced" ;;
  *) LEVEL="Intermediate" ;;
esac
 
# ── 4. DESCRIPCIÓN CORTA (SEO) ─────────────────────────────
echo -e "\n${YELLOW}[4/6] DESCRIPCIÓN CORTA (para SEO / excerpt)${NC}"
echo -e "      Máx. 160 caracteres. Resume el artículo.\n"
read -p "  → Descripción: " EXCERPT
 
# ── 5. KEYWORDS ────────────────────────────────────────────
echo -e "\n${YELLOW}[5/6] KEYWORDS SEO${NC}"
echo -e "      Separadas por coma. Ej: rhel 9, pacemaker, cluster\n"
read -p "  → Keywords: " KEYWORDS
 
# ── 6. CUERPO DEL ARTÍCULO ─────────────────────────────────
echo -e "\n${YELLOW}[6/6] CUERPO DEL ARTÍCULO${NC}"
echo -e "      Escribe el contenido. Cuando termines, escribe"
echo -e "      ${BOLD}FIN${NC} en una línea nueva y presiona Enter.\n"
echo -e "  ┌─────────────────────────────────────────────┐"
 
BODY=""
while IFS= read -r line; do
  [[ "$line" == "FIN" ]] && break
  BODY+="$line"$'\n'
done
 
# ── CREAR ARCHIVO ──────────────────────────────────────────
cat > "$FILEPATH" <<EOF
========================================================
  STACKDEPLOY — ARTÍCULO EN BORRADOR
========================================================
TÍTULO:       $TITLE
SLUG:         $SLUG
FECHA:        $DATE
CATEGORÍA:    $CATEGORY
NIVEL:        $LEVEL
ESTADO:       DRAFT
AUTOR:        Andres Bernal (@abernal093)
CREADO:       $TIMESTAMP
--------------------------------------------------------
DESCRIPCIÓN SEO:
$EXCERPT
 
KEYWORDS:
$KEYWORDS
========================================================
 
CUERPO DEL ARTÍCULO:
──────────────────────────────────────────────────────
 
$BODY
 
========================================================
  NOTAS PARA REVISIÓN:
  [ ] Ortografía revisada
  [ ] Comandos verificados en lab
  [ ] Links externos funcionando
  [ ] Estructura de headings correcta
  [ ] SEO revisado
========================================================
EOF
 
# ── CONFIRMACIÓN ───────────────────────────────────────────
echo -e "  └─────────────────────────────────────────────┘\n"
echo -e "${GREEN}${BOLD}  ✓ Artículo creado exitosamente${NC}"
echo -e "\n  📄 Archivo:    ${BOLD}$FILENAME${NC}"
echo -e "  📁 Ubicación:  ${BOLD}01_drafts/${NC}"
echo -e "  📌 Categoría:  $CATEGORY"
echo -e "  🎯 Nivel:      $LEVEL"
echo -e "\n  Próximo paso: corre ${CYAN}02_revisar_articulo.sh${NC} para enviarlo a revisión.\n"
