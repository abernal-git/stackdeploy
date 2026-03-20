#!/bin/bash
# ============================================================
#  StackDeploy — Script 04: Aprobar para Publicación
#  Mueve artículos de 03_design → 04_ready
#  Aprobación final antes del pipeline de deploy
# ============================================================
 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'
 
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)/stackdeploy-content"
DESIGN="$BASE_DIR/03_design"
READY="$BASE_DIR/04_ready"
 
clear
echo -e "${GREEN}${BOLD}"
echo "  ██████╗ ███████╗ █████╗ ██████╗ ██╗   ██╗"
echo "  ██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝"
echo "  ██████╔╝█████╗  ███████║██║  ██║ ╚████╔╝ "
echo "  ██╔══██╗██╔══╝  ██╔══██║██║  ██║  ╚██╔╝  "
echo "  ██║  ██║███████╗██║  ██║██████╔╝   ██║   "
echo "  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝    ╚═╝   "
echo -e "${NC}"
echo -e "${BOLD}  Script 04: Aprobación Final → LISTO PARA PUBLICAR${NC}"
echo -e "  ─────────────────────────────────────────\n"
 
# ── LISTAR ARTÍCULOS EN DISEÑO ──────────────────────────────
DESIGN_LIST=($(ls "$DESIGN"/*.txt 2>/dev/null))
 
if [[ ${#DESIGN_LIST[@]} -eq 0 ]]; then
  echo -e "${YELLOW}  ⚠ No hay artículos en 03_design/.${NC}"
  echo -e "     Corre primero ${CYAN}03_diseño_articulo.sh${NC}\n"
  exit 0
fi
 
echo -e "${YELLOW}  Artículos listos para aprobación final:${NC}\n"
for i in "${!DESIGN_LIST[@]}"; do
  FNAME=$(basename "${DESIGN_LIST[$i]}")
  TITLE_LINE=$(grep "^TÍTULO:" "${DESIGN_LIST[$i]}" | head -1 | sed 's/TÍTULO://;s/^ *//')
  CATEGORY=$(grep "^CATEGORÍA:" "${DESIGN_LIST[$i]}" | head -1 | sed 's/CATEGORÍA://;s/^ *//')
  LEVEL=$(grep "^NIVEL:" "${DESIGN_LIST[$i]}" | head -1 | sed 's/NIVEL://;s/^ *//')
  echo -e "  ${BOLD}[$((i+1))]${NC} $FNAME"
  echo -e "       📌 $TITLE_LINE"
  echo -e "       🏷  $CATEGORY  |  🎯 $LEVEL\n"
done
 
read -p "  Selecciona artículo para aprobación final [1-${#DESIGN_LIST[@]}]: " SELECTION
SELECTION=$((SELECTION-1))
 
if [[ $SELECTION -lt 0 || $SELECTION -ge ${#DESIGN_LIST[@]} ]]; then
  echo -e "\n${RED}  ✗ Selección inválida.${NC}\n"
  exit 1
fi
 
SELECTED_FILE="${DESIGN_LIST[$SELECTION]}"
FNAME=$(basename "$SELECTED_FILE")
TITLE_LINE=$(grep "^TÍTULO:" "$SELECTED_FILE" | head -1 | sed 's/TÍTULO://;s/^ *//')
SLUG=$(grep "^SLUG:" "$SELECTED_FILE" | head -1 | sed 's/SLUG://;s/^ *//')
DATE=$(grep "^FECHA:" "$SELECTED_FILE" | head -1 | sed 's/FECHA://;s/^ *//')
CATEGORY=$(grep "^CATEGORÍA:" "$SELECTED_FILE" | head -1 | sed 's/CATEGORÍA://;s/^ *//')
EXCERPT=$(grep -A1 "DESCRIPCIÓN SEO:" "$SELECTED_FILE" | tail -1)
 
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${BOLD}RESUMEN DEL ARTÍCULO${NC}\n"
echo -e "  📌 Título:    $TITLE_LINE"
echo -e "  🗂  Categoría: $CATEGORY"
echo -e "  📅 Fecha:     $DATE"
echo -e "  🔗 Slug:      $SLUG"
echo -e "  📝 Excerpt:   $EXCERPT"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
 
# ── CHECKLIST FINAL ────────────────────────────────────────
echo -e "${YELLOW}  CHECKLIST FINAL DE PUBLICACIÓN${NC}\n"
 
FINAL_CHECKS=()
FINAL_LABELS=(
  "¿El artículo pasó revisión de ortografía?"
  "¿Todos los assets/imágenes están completos?"
  "¿El archivo HTML/Markdown del artículo está listo?"
  "¿El slug es correcto para la URL?"
  "¿La descripción SEO está completa?"
  "¿Se publicará en redes sociales al momento del deploy?"
  "¿El artículo tiene internal links a otros posts?"
)
 
FINAL_ALL_OK=true
for label in "${FINAL_LABELS[@]}"; do
  read -p "  → $label [s/n]: " RESP
  if [[ "$RESP" =~ ^[sS]$ ]]; then
    FINAL_CHECKS+=("✓")
  else
    FINAL_CHECKS+=("✗")
    FINAL_ALL_OK=false
  fi
done
 
# ── FECHA DE PUBLICACIÓN ───────────────────────────────────
echo -e "\n${YELLOW}  ¿Cuándo se publicará este artículo?${NC}"
echo "  1) Inmediatamente (al hacer deploy)"
echo "  2) Fecha programada"
read -p "  → [1/2]: " PUB_OPTION
 
if [[ "$PUB_OPTION" == "2" ]]; then
  read -p "  → Fecha de publicación (YYYY-MM-DD): " PUB_DATE
else
  PUB_DATE=$(date +%Y-%m-%d)
fi
 
# ── REDES SOCIALES ─────────────────────────────────────────
echo -e "\n${YELLOW}  Texto para redes sociales:${NC}"
echo -e "  (Será usado en X/Twitter y LinkedIn al publicar)\n"
read -p "  → Tweet/Post (máx 280 chars): " SOCIAL_TEXT
 
# ── APROBAR O RECHAZAR ─────────────────────────────────────
FINAL_DATE=$(date '+%Y-%m-%d %H:%M:%S')
FINAL_BLOCK="
========================================================
  APROBACIÓN FINAL — $FINAL_DATE
========================================================
  [${FINAL_CHECKS[0]}] Revisión ortografía completada
  [${FINAL_CHECKS[1]}] Assets completos
  [${FINAL_CHECKS[2]}] Archivo HTML/Markdown listo
  [${FINAL_CHECKS[3]}] Slug correcto
  [${FINAL_CHECKS[4]}] Descripción SEO completa
  [${FINAL_CHECKS[5]}] Publicación en redes programada
  [${FINAL_CHECKS[6]}] Internal links incluidos
 
  FECHA DE PUBLICACIÓN: $PUB_DATE
  SOCIAL TEXT: $SOCIAL_TEXT
  APROBADO POR: Andres Bernal
  FECHA APROBACIÓN: $FINAL_DATE
========================================================"
 
echo ""
if $FINAL_ALL_OK; then
  sed -i '' 's/ESTADO:       EN DISEÑO/ESTADO:       LISTO PARA PUBLICAR/' "$SELECTED_FILE" 2>/dev/null || \
  sed -i 's/ESTADO:       EN DISEÑO/ESTADO:       LISTO PARA PUBLICAR/' "$SELECTED_FILE"
  echo "$FINAL_BLOCK" >> "$SELECTED_FILE"
  mv "$SELECTED_FILE" "$READY/$FNAME"
 
  # Crear también un archivo de metadata JSON para el pipeline
  cat > "$READY/${SLUG}_meta.json" <<METAJSON
{
  "title": "$TITLE_LINE",
  "slug": "$SLUG",
  "category": "$CATEGORY",
  "publish_date": "$PUB_DATE",
  "excerpt": "$EXCERPT",
  "social_text": "$SOCIAL_TEXT",
  "approved_by": "Andres Bernal",
  "approved_at": "$FINAL_DATE",
  "status": "ready"
}
METAJSON
 
  echo -e "${GREEN}${BOLD}  ✓✓✓ ARTÍCULO APROBADO PARA PUBLICACIÓN${NC}"
  echo -e "\n  📁 Movido a:  ${BOLD}04_ready/${NC}"
  echo -e "  📋 Metadata:  ${BOLD}${SLUG}_meta.json${NC}"
  echo -e "\n  ${CYAN}Próximo paso:${NC} Corre el ${BOLD}pipeline de GitHub Actions${NC}"
  echo -e "  o ejecuta ${CYAN}05_publicar.sh${NC} para deploy manual.\n"
else
  echo "$FINAL_BLOCK" >> "$SELECTED_FILE"
  echo -e "${YELLOW}${BOLD}  ⚠ Artículo requiere ajustes. Permanece en 03_design/${NC}\n"
fi
 
