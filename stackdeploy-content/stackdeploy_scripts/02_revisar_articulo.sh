#!/bin/bash
# ============================================================
#  StackDeploy — Script 02: Revisar Artículo
#  Mueve artículos de 01_drafts → 02_review
#  Verifica ortografía y marca checklist
# ============================================================
 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'
 
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)/stackdeploy-content"
DRAFTS="$BASE_DIR/01_drafts"
REVIEW="$BASE_DIR/02_review"
 
clear
echo -e "${CYAN}${BOLD}"
echo "  ██████╗ ███████╗██╗   ██╗██╗███████╗██╗ ██████╗ ███╗   ██╗"
echo "  ██╔══██╗██╔════╝██║   ██║██║██╔════╝██║██╔═══██╗████╗  ██║"
echo "  ██████╔╝█████╗  ██║   ██║██║███████╗██║██║   ██║██╔██╗ ██║"
echo "  ██╔══██╗██╔══╝  ╚██╗ ██╔╝██║╚════██║██║██║   ██║██║╚██╗██║"
echo "  ██║  ██║███████╗ ╚████╔╝ ██║███████║██║╚██████╔╝██║ ╚████║"
echo "  ╚═╝  ╚═╝╚══════╝  ╚═══╝  ╚═╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝"
echo -e "${NC}"
echo -e "${BOLD}  Script 02: Revisión de Artículos${NC}"
echo -e "  ─────────────────────────────────────────\n"
 
# ── LISTAR DRAFTS ──────────────────────────────────────────
DRAFTS_LIST=($(ls "$DRAFTS"/*.txt 2>/dev/null))
 
if [[ ${#DRAFTS_LIST[@]} -eq 0 ]]; then
  echo -e "${YELLOW}  ⚠ No hay artículos en 01_drafts/ para revisar.${NC}"
  echo -e "     Corre primero ${CYAN}01_crear_articulo.sh${NC}\n"
  exit 0
fi
 
echo -e "${YELLOW}  Artículos en borrador:${NC}\n"
for i in "${!DRAFTS_LIST[@]}"; do
  FNAME=$(basename "${DRAFTS_LIST[$i]}")
  # Extraer título del archivo
  TITLE_LINE=$(grep "^TÍTULO:" "${DRAFTS_LIST[$i]}" | head -1 | sed 's/TÍTULO://;s/^ *//')
  echo -e "  ${BOLD}[$((i+1))]${NC} $FNAME"
  echo -e "       → $TITLE_LINE"
  echo ""
done
 
read -p "  Selecciona artículo a revisar [1-${#DRAFTS_LIST[@]}]: " SELECTION
SELECTION=$((SELECTION-1))
 
if [[ $SELECTION -lt 0 || $SELECTION -ge ${#DRAFTS_LIST[@]} ]]; then
  echo -e "\n${RED}  ✗ Selección inválida.${NC}\n"
  exit 1
fi
 
SELECTED_FILE="${DRAFTS_LIST[$SELECTION]}"
FNAME=$(basename "$SELECTED_FILE")
 
# ── MOSTRAR CONTENIDO ──────────────────────────────────────
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
cat "$SELECTED_FILE"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
 
# ── VERIFICACIÓN DE ORTOGRAFÍA ─────────────────────────────
echo -e "${YELLOW}  Verificando ortografía...${NC}"
 
# Verificar si aspell está disponible
if command -v aspell &> /dev/null; then
  echo -e "\n  ${BOLD}Posibles errores ortográficos (Español):${NC}"
  # Extraer solo el cuerpo para revisar
  BODY_TEXT=$(sed -n '/CUERPO DEL ARTÍCULO:/,/======/p' "$SELECTED_FILE" | head -n -3)
  ERRORS=$(echo "$BODY_TEXT" | aspell --lang=es list 2>/dev/null | sort -u)
  if [[ -z "$ERRORS" ]]; then
    echo -e "  ${GREEN}  ✓ Sin errores detectados${NC}"
  else
    echo -e "  ${RED}  Palabras no reconocidas:${NC}"
    echo "$ERRORS" | while read -r word; do
      echo "    • $word"
    done
  fi
else
  echo -e "  ${YELLOW}  ⚠ aspell no instalado. Revisión manual requerida.${NC}"
  echo -e "     Instalar: ${CYAN}brew install aspell${NC} (Mac) o ${CYAN}sudo apt install aspell aspell-es${NC}"
fi
 
# ── CHECKLIST INTERACTIVO ──────────────────────────────────
echo -e "\n${YELLOW}  CHECKLIST DE REVISIÓN${NC}"
echo -e "  Responde s/n para cada punto:\n"
 
CHECKS=()
LABELS=(
  "¿La ortografía está correcta?"
  "¿Los comandos fueron verificados en lab real?"
  "¿Los links externos funcionan?"
  "¿La estructura de headings es correcta (H1→H2→H3)?"
  "¿El título incluye la keyword principal?"
  "¿La descripción SEO tiene menos de 160 caracteres?"
  "¿El contenido aporta valor real (no es genérico)?"
  "¿Hay al menos un ejemplo práctico o output de lab?"
)
 
ALL_OK=true
for label in "${LABELS[@]}"; do
  read -p "  → $label [s/n]: " RESP
  if [[ "$RESP" =~ ^[sS]$ ]]; then
    CHECKS+=("✓")
  else
    CHECKS+=("✗")
    ALL_OK=false
  fi
done
 
# ── NOTAS ADICIONALES ──────────────────────────────────────
echo -e "\n${YELLOW}  Notas adicionales del revisor (opcional):${NC}"
read -p "  → " REVIEWER_NOTES
 
# ── ACTUALIZAR ARCHIVO CON RESULTADOS ──────────────────────
REVIEW_DATE=$(date '+%Y-%m-%d %H:%M:%S')
REVIEWER_BLOCK="
========================================================
  RESULTADO DE REVISIÓN — $REVIEW_DATE
========================================================
  [${CHECKS[0]}] Ortografía correcta
  [${CHECKS[1]}] Comandos verificados en lab
  [${CHECKS[2]}] Links externos funcionando
  [${CHECKS[3]}] Estructura de headings correcta
  [${CHECKS[4]}] Keyword en título
  [${CHECKS[5]}] Descripción SEO < 160 caracteres
  [${CHECKS[6]}] Contenido de valor real
  [${CHECKS[7]}] Ejemplo práctico incluido
 
  NOTAS: $REVIEWER_NOTES
  REVISOR: Andres Bernal
  FECHA REVISIÓN: $REVIEW_DATE
========================================================"
 
# ── DECIDIR DESTINO ────────────────────────────────────────
echo ""
if $ALL_OK; then
  echo -e "${GREEN}${BOLD}  ✓ Revisión completada — Artículo APROBADO${NC}"
  # Actualizar ESTADO en el archivo
  sed -i '' 's/ESTADO:       DRAFT/ESTADO:       EN REVISIÓN/' "$SELECTED_FILE" 2>/dev/null || \
  sed -i 's/ESTADO:       DRAFT/ESTADO:       EN REVISIÓN/' "$SELECTED_FILE"
  echo "$REVIEWER_BLOCK" >> "$SELECTED_FILE"
  mv "$SELECTED_FILE" "$REVIEW/$FNAME"
  echo -e "\n  📁 Movido a: ${BOLD}02_review/${NC}"
  echo -e "  Próximo paso: corre ${CYAN}03_diseño_articulo.sh${NC}\n"
else
  echo -e "${YELLOW}${BOLD}  ⚠ Revisión incompleta — Artículo requiere correcciones${NC}"
  echo "$REVIEWER_BLOCK" >> "$SELECTED_FILE"
  echo -e "\n  📁 Artículo permanece en: ${BOLD}01_drafts/${NC}"
  echo -e "  Edítalo y vuelve a correr este script.\n"
fi
 
