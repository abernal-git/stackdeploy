#!/bin/bash
# ============================================================
#  StackDeploy — Script 00: Dashboard de Estado
#  Vista general de todos los artículos en el pipeline
# ============================================================
 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'
 
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)/stackdeploy-content"
 
clear
echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║       STACKDEPLOY — CONTENT DASHBOARD         ║"
echo "  ║         by Andres Bernal @abernal093           ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${DIM}$(date '+%A, %d %B %Y — %H:%M:%S')${NC}\n"
 
# ── CONTADORES ─────────────────────────────────────────────
D1=$(ls "$BASE_DIR/01_drafts"/*.txt 2>/dev/null | wc -l | tr -d ' ')
D2=$(ls "$BASE_DIR/02_review"/*.txt 2>/dev/null | wc -l | tr -d ' ')
D3=$(ls "$BASE_DIR/03_design"/*.txt 2>/dev/null | wc -l | tr -d ' ')
D4=$(ls "$BASE_DIR/04_ready"/*.txt 2>/dev/null | wc -l | tr -d ' ')
D5=$(ls "$BASE_DIR/05_published"/*.txt 2>/dev/null | wc -l | tr -d ' ')
TOTAL=$((D1 + D2 + D3 + D4 + D5))
 
echo -e "  ${BOLD}RESUMEN DEL PIPELINE${NC}\n"
echo -e "  ✍️  ${YELLOW}01 DRAFTS${NC}      →  ${BOLD}$D1${NC} artículos"
echo -e "  🔍 ${BLUE}02 REVIEW${NC}      →  ${BOLD}$D2${NC} artículos"
echo -e "  🎨 ${MAGENTA}03 DESIGN${NC}      →  ${BOLD}$D3${NC} artículos"
echo -e "  ✅ ${GREEN}04 READY${NC}       →  ${BOLD}$D4${NC} artículos"
echo -e "  🚀 ${CYAN}05 PUBLISHED${NC}   →  ${BOLD}$D5${NC} artículos"
echo -e "  ─────────────────────────────────"
echo -e "  📚 ${BOLD}TOTAL${NC}          →  ${BOLD}$TOTAL${NC} artículos\n"
 
# ── BARRA DE PROGRESO POR FASE ─────────────────────────────
show_articles() {
  local DIR=$1
  local LABEL=$2
  local COLOR=$3
  local FILES=($(ls "$DIR"/*.txt 2>/dev/null))
 
  if [[ ${#FILES[@]} -gt 0 ]]; then
    echo -e "  ${COLOR}${BOLD}── $LABEL ──${NC}"
    for f in "${FILES[@]}"; do
      FNAME=$(basename "$f")
      TITLE=$(grep "^TÍTULO:" "$f" | head -1 | sed 's/TÍTULO://;s/^ *//')
      CAT=$(grep "^CATEGORÍA:" "$f" | head -1 | sed 's/CATEGORÍA://;s/^ *//')
      FECHA=$(grep "^FECHA:" "$f" | head -1 | sed 's/FECHA://;s/^ *//')
      echo -e "    ${BOLD}•${NC} $TITLE"
      echo -e "      ${DIM}$CAT  |  $FECHA${NC}"
    done
    echo ""
  fi
}
 
show_articles "$BASE_DIR/01_drafts"    "BORRADORES"  "$YELLOW"
show_articles "$BASE_DIR/02_review"    "EN REVISIÓN" "$BLUE"
show_articles "$BASE_DIR/03_design"    "EN DISEÑO"   "$MAGENTA"
show_articles "$BASE_DIR/04_ready"     "LISTOS"      "$GREEN"
show_articles "$BASE_DIR/05_published" "PUBLICADOS"  "$CYAN"
 
# ── ACCIONES RÁPIDAS ───────────────────────────────────────
echo -e "  ${BOLD}ACCIONES RÁPIDAS${NC}\n"
echo -e "  ${CYAN}[1]${NC} Crear nuevo artículo     → 01_crear_articulo.sh"
echo -e "  ${BLUE}[2]${NC} Revisar artículo         → 02_revisar_articulo.sh"
echo -e "  ${MAGENTA}[3]${NC} Diseño y assets          → 03_diseño_articulo.sh"
echo -e "  ${GREEN}[4]${NC} Aprobar para publicar    → 04_aprobar_publicacion.sh"
echo -e "  ${NC}[0]${NC} Salir\n"
 
read -p "  → Selecciona acción: " ACTION
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
 
case $ACTION in
  1) bash "$SCRIPTS_DIR/01_crear_articulo.sh" ;;
  2) bash "$SCRIPTS_DIR/02_revisar_articulo.sh" ;;
  3) bash "$SCRIPTS_DIR/03_diseño_articulo.sh" ;;
  4) bash "$SCRIPTS_DIR/04_aprobar_publicacion.sh" ;;
  0) echo -e "\n  Hasta luego! 🚀\n" ;;
  *) echo -e "\n${RED}  Opción inválida.${NC}\n" ;;
esac
 
