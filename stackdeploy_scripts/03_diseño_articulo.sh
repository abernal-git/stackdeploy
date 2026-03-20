#!/bin/bash
# ============================================================
#  StackDeploy — Script 03: Diseño de Artículo
#  Mueve artículos de 02_review → 03_design
#  Checklist de imágenes, diagramas y assets visuales
# ============================================================
 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'
 
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)/stackdeploy-content"
REVIEW="$BASE_DIR/02_review"
DESIGN="$BASE_DIR/03_design"
 
clear
echo -e "${MAGENTA}${BOLD}"
echo "  ██████╗ ██╗███████╗███████╗███╗   ██╗ ██████╗ "
echo "  ██╔══██╗██║██╔════╝██╔════╝████╗  ██║██╔═══██╗"
echo "  ██║  ██║██║███████╗█████╗  ██╔██╗ ██║██║   ██║"
echo "  ██║  ██║██║╚════██║██╔══╝  ██║╚██╗██║██║   ██║"
echo "  ██████╔╝██║███████║███████╗██║ ╚████║╚██████╔╝"
echo "  ╚═════╝ ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ "
echo -e "${NC}"
echo -e "${BOLD}  Script 03: Diseño y Assets Visuales${NC}"
echo -e "  ─────────────────────────────────────────\n"
 
# ── LISTAR ARTÍCULOS EN REVISIÓN ───────────────────────────
REVIEW_LIST=($(ls "$REVIEW"/*.txt 2>/dev/null))
 
if [[ ${#REVIEW_LIST[@]} -eq 0 ]]; then
  echo -e "${YELLOW}  ⚠ No hay artículos en 02_review/.${NC}"
  echo -e "     Corre primero ${CYAN}02_revisar_articulo.sh${NC}\n"
  exit 0
fi
 
echo -e "${YELLOW}  Artículos aprobados en revisión:${NC}\n"
for i in "${!REVIEW_LIST[@]}"; do
  FNAME=$(basename "${REVIEW_LIST[$i]}")
  TITLE_LINE=$(grep "^TÍTULO:" "${REVIEW_LIST[$i]}" | head -1 | sed 's/TÍTULO://;s/^ *//')
  CATEGORY=$(grep "^CATEGORÍA:" "${REVIEW_LIST[$i]}" | head -1 | sed 's/CATEGORÍA://;s/^ *//')
  echo -e "  ${BOLD}[$((i+1))]${NC} $FNAME"
  echo -e "       📌 $TITLE_LINE"
  echo -e "       🏷  $CATEGORY\n"
done
 
read -p "  Selecciona artículo para diseño [1-${#REVIEW_LIST[@]}]: " SELECTION
SELECTION=$((SELECTION-1))
 
if [[ $SELECTION -lt 0 || $SELECTION -ge ${#REVIEW_LIST[@]} ]]; then
  echo -e "\n${RED}  ✗ Selección inválida.${NC}\n"
  exit 1
fi
 
SELECTED_FILE="${REVIEW_LIST[$SELECTION]}"
FNAME=$(basename "$SELECTED_FILE")
TITLE_LINE=$(grep "^TÍTULO:" "$SELECTED_FILE" | head -1 | sed 's/TÍTULO://;s/^ *//')
 
echo -e "\n${BLUE}  Artículo seleccionado:${NC} ${BOLD}$TITLE_LINE${NC}\n"
 
# ── CREAR CARPETA DE ASSETS ────────────────────────────────
SLUG=$(grep "^SLUG:" "$SELECTED_FILE" | head -1 | sed 's/SLUG://;s/^ *//')
ASSETS_DIR="$DESIGN/assets_${SLUG}"
mkdir -p "$ASSETS_DIR"
 
echo -e "${YELLOW}  📁 Carpeta de assets creada:${NC}"
echo -e "     $ASSETS_DIR\n"
echo -e "  Coloca aquí las imágenes y diagramas del artículo.\n"
 
# ── CHECKLIST DE DISEÑO ────────────────────────────────────
echo -e "${YELLOW}  CHECKLIST DE DISEÑO${NC}"
echo -e "  Responde s/n para cada punto:\n"
 
DESIGN_CHECKS=()
DESIGN_LABELS=(
  "¿Tiene imagen de portada (hero image)? 1200x630px"
  "¿Los diagramas de arquitectura están creados?"
  "¿Los screenshots del lab están en alta resolución?"
  "¿Los bloques de código tienen syntax highlighting?"
  "¿Los comandos tienen su output real del lab?"
  "¿El alt text de imágenes incluye keywords SEO?"
  "¿Las imágenes pesan menos de 200KB (WebP optimizado)?"
)
 
DESIGN_ALL_OK=true
for label in "${DESIGN_LABELS[@]}"; do
  read -p "  → $label [s/n]: " RESP
  if [[ "$RESP" =~ ^[sS]$ ]]; then
    DESIGN_CHECKS+=("✓")
  else
    DESIGN_CHECKS+=("✗")
    DESIGN_ALL_OK=false
  fi
done
 
# ── REGISTRAR ASSETS ───────────────────────────────────────
echo -e "\n${YELLOW}  ¿Cuántas imágenes/diagramas tiene el artículo?${NC}"
read -p "  → Número de assets: " ASSET_COUNT
 
echo -e "\n${YELLOW}  Describe brevemente cada asset (ej: 'diagrama-cluster.png - Arquitectura HA'):${NC}"
ASSETS_DESC=""
for ((a=1; a<=ASSET_COUNT; a++)); do
  read -p "  → Asset $a: " ASSET_DESC
  ASSETS_DESC+="  $a. $ASSET_DESC"$'\n'
done
 
# ── HERRAMIENTAS SUGERIDAS ─────────────────────────────────
echo -e "\n${CYAN}  💡 Herramientas recomendadas para diagramas:${NC}"
echo "  • draw.io (diagrams.net) — diagramas de arquitectura"
echo "  • Excalidraw — diagramas estilo sketch"
echo "  • Carbon.now.sh — screenshots de código bonitos"
echo "  • Squoosh.app — optimizar imágenes a WebP"
echo ""
 
# ── ACTUALIZAR ARCHIVO ─────────────────────────────────────
DESIGN_DATE=$(date '+%Y-%m-%d %H:%M:%S')
DESIGN_BLOCK="
========================================================
  DISEÑO Y ASSETS — $DESIGN_DATE
========================================================
  [${DESIGN_CHECKS[0]}] Imagen de portada (hero 1200x630px)
  [${DESIGN_CHECKS[1]}] Diagramas de arquitectura
  [${DESIGN_CHECKS[2]}] Screenshots del lab en alta resolución
  [${DESIGN_CHECKS[3]}] Syntax highlighting en código
  [${DESIGN_CHECKS[4]}] Outputs reales del lab incluidos
  [${DESIGN_CHECKS[5]}] Alt text con keywords SEO
  [${DESIGN_CHECKS[6]}] Imágenes optimizadas (<200KB WebP)
 
  ASSETS ($ASSET_COUNT total):
$ASSETS_DESC
  CARPETA ASSETS: assets_${SLUG}/
  FECHA DISEÑO: $DESIGN_DATE
========================================================"
 
if $DESIGN_ALL_OK; then
  sed -i '' 's/ESTADO:       EN REVISIÓN/ESTADO:       EN DISEÑO/' "$SELECTED_FILE" 2>/dev/null || \
  sed -i 's/ESTADO:       EN REVISIÓN/ESTADO:       EN DISEÑO/' "$SELECTED_FILE"
  echo "$DESIGN_BLOCK" >> "$SELECTED_FILE"
  mv "$SELECTED_FILE" "$DESIGN/$FNAME"
  echo -e "${GREEN}${BOLD}  ✓ Artículo listo para diseño final${NC}"
  echo -e "\n  📁 Movido a: ${BOLD}03_design/${NC}"
  echo -e "  📁 Assets en: ${BOLD}03_design/assets_${SLUG}/${NC}"
  echo -e "  Próximo paso: corre ${CYAN}04_aprobar_publicacion.sh${NC}\n"
else
  echo "$DESIGN_BLOCK" >> "$SELECTED_FILE"
  echo -e "${YELLOW}${BOLD}  ⚠ Faltan assets. Artículo permanece en 02_review/${NC}"
  echo -e "     Completa el diseño y vuelve a correr este script.\n"
fi
