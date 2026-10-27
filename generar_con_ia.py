#!/usr/bin/env python3
# ============================================================
#  StackDeploy — generar_con_ia.py
#  Genera un artículo completo usando Google Gemini y lo publica
#
#  Uso:
#    python3 generar_con_ia.py "Docker Compose para desarrollo local"
#    python3 generar_con_ia.py "Ansible Playbooks" --categoria "Ansible" --nivel "Beginner"
#    python3 generar_con_ia.py "Kubernetes Pods" --dry-run
#
#  Requiere:
#    pip install google-generativeai
#    export GEMINI_API_KEY=...  (console.cloud.google.com o aistudio.google.com)
# ============================================================

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

try:
    from google import genai
except ImportError:
    print("\n  ERROR: Falta el paquete 'google-genai'")
    print("  Instala con: pip install google-genai\n")
    sys.exit(1)

# ── CONFIGURACION ──────────────────────────────────────────
BASE_DIR      = Path(__file__).parent
DRAFTS_DIR    = BASE_DIR / "stackdeploy-content" / "01_drafts"
REVIEW_DIR    = BASE_DIR / "stackdeploy-content" / "02_review"
DESIGN_DIR    = BASE_DIR / "stackdeploy-content" / "03_design"
READY_DIR     = BASE_DIR / "stackdeploy-content" / "04_ready"
PUBLISHED_DIR = BASE_DIR / "stackdeploy-content" / "05_published"

CATEGORIAS = [
    "RHEL / Linux",
    "Docker",
    "Cloud",
    "Ansible",
    "CI/CD",
    "Kubernetes",
    "Security",
    "Other",
]

NIVELES = ["Beginner", "Intermediate", "Advanced"]

MODEL = "gemini-3.1-flash-lite"

# ── DETECTAR CATEGORIA DESDE EL TEMA ──────────────────────
def detectar_categoria(tema: str) -> str:
    tema_lower = tema.lower()
    if any(k in tema_lower for k in ["rhel", "linux", "bash", "selinux", "rpm", "yum", "dnf", "systemd", "file", "permission", "directory"]):
        return "RHEL / Linux"
    if any(k in tema_lower for k in ["docker", "container", "compose", "dockerfile", "image"]):
        return "Docker"
    if any(k in tema_lower for k in ["kubernetes", "k8s", "pod", "deployment", "helm", "kubectl"]):
        return "Kubernetes"
    if any(k in tema_lower for k in ["ansible", "playbook", "inventory", "role", "task"]):
        return "Ansible"
    if any(k in tema_lower for k in ["ci/cd", "cicd", "pipeline", "github actions", "jenkins", "gitlab"]):
        return "CI/CD"
    if any(k in tema_lower for k in ["cloud", "aws", "azure", "gcp", "terraform", "iac"]):
        return "Cloud"
    if any(k in tema_lower for k in ["security", "firewall", "ssl", "tls", "cert", "vpn", "iptables"]):
        return "Security"
    return "RHEL / Linux"

# ── GENERAR SLUG ───────────────────────────────────────────
def generar_slug(titulo: str) -> str:
    slug = titulo.lower()
    slug = re.sub(r'[áàäâ]', 'a', slug)
    slug = re.sub(r'[éèëê]', 'e', slug)
    slug = re.sub(r'[íìïî]', 'i', slug)
    slug = re.sub(r'[óòöô]', 'o', slug)
    slug = re.sub(r'[úùüû]', 'u', slug)
    slug = re.sub(r'[ñ]', 'n', slug)
    slug = re.sub(r'[^a-z0-9\s-]', '', slug)
    slug = re.sub(r'\s+', '-', slug.strip())
    slug = re.sub(r'-+', '-', slug)
    return slug[:80]

# ── CARGAR EJEMPLO DE ARTICULO PUBLICADO ──────────────────
def cargar_ejemplo() -> str:
    if not PUBLISHED_DIR.exists():
        return ""
    txts = sorted(PUBLISHED_DIR.glob("*.txt"), reverse=True)
    if not txts:
        return ""
    with open(txts[0], encoding="utf-8") as f:
        content = f.read()
    # Devolver solo los primeros 3000 chars como referencia de estilo
    return content[:3000]

# ── LLAMAR A GEMINI API ────────────────────────────────────
def generar_articulo_con_ia(tema: str, categoria: str, nivel: str) -> dict:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("\n  ERROR: Variable GEMINI_API_KEY no encontrada")
        print("  Obtén tu key gratis en: aistudio.google.com/apikey")
        print("  Ejecuta: export GEMINI_API_KEY=AIza...\n")
        sys.exit(1)

    client = genai.Client(api_key=api_key)
    ejemplo = cargar_ejemplo()

    ejemplo_section = ""
    if ejemplo:
        ejemplo_section = f"""
Here is an example of the writing style and format from an existing article:

---EXAMPLE START---
{ejemplo}
---EXAMPLE END---
"""

    now = datetime.now()
    prompt = f"""You are a technical writer for StackDeploy, a blog focused on infrastructure, Linux, DevOps, and cloud engineering. Your articles are hands-on, practical, and written for system administrators and DevOps engineers.

Write a complete technical blog article about: **{tema}**

Category: {categoria}
Difficulty level: {nivel}
{ejemplo_section}

Your response MUST follow this EXACT format (do not add anything before or after):

========================================================
  STACKDEPLOY — ARTÍCULO EN BORRADOR
========================================================
TÍTULO:       [SEO-optimized English title]
SLUG:         [url-friendly-slug-in-english]
FECHA:        {now.strftime('%Y-%m-%d')}
CATEGORÍA:    {categoria}
NIVEL:        {nivel}
ESTADO:       LISTO PARA PUBLICAR
AUTOR:        Andres Bernal (@abernal093)
CREADO:       {now.strftime('%Y%m%d_%H%M%S')}
--------------------------------------------------------
DESCRIPCIÓN SEO:
[One sentence description, max 160 characters, includes primary keyword]

KEYWORDS:
[8-10 relevant keywords, comma-separated, lowercase]
========================================================

CUERPO DEL ARTÍCULO:
──────────────────────────────────────────────────────

[Full article body in Markdown. Requirements:
- Start with a # H1 matching the title
- Use ## H2 for main sections (minimum 5 sections)
- Use ### H3 for subsections
- Include real, runnable commands in ```bash code blocks
- Show expected command output where useful
- Use **bold** for important terms
- Use `inline code` for file names, commands, variables
- Include a practical lab/exercise section at the end
- Minimum 1200 words
- Write in English
- All code blocks must use correct syntax highlighting language tags]

========================================================
  NOTAS PARA REVISIÓN:
  [x] Spelling correct
  [x] Commands verified
  [x] SEO description under 160 chars
  [x] Heading structure correct
  [x] Title has main keyword
========================================================"""

    print(f"\n  Generando artículo con {MODEL}...")
    print(f"  Tema: {tema}")
    print(f"  Categoría: {categoria} | Nivel: {nivel}\n")

    response = client.models.generate_content(model=MODEL, contents=prompt)
    raw = response.text.strip()

    # Extraer campos del header para devolver metadatos
    titulo_match = re.search(r'^TÍTULO[:\s]+(.+)$', raw, re.MULTILINE | re.IGNORECASE)
    slug_match   = re.search(r'^SLUG[:\s]+(.+)$', raw, re.MULTILINE | re.IGNORECASE)
    titulo = titulo_match.group(1).strip() if titulo_match else tema
    slug   = slug_match.group(1).strip() if slug_match else generar_slug(tema)

    return {
        "raw": raw,
        "titulo": titulo,
        "slug": slug,
        "categoria": categoria,
        "nivel": nivel,
        "fecha": datetime.now().strftime("%Y-%m-%d"),
    }

# ── GUARDAR Y MOVER POR EL PIPELINE ───────────────────────
def mover_por_pipeline(articulo: dict) -> Path:
    fecha = articulo["fecha"]
    slug  = articulo["slug"]
    nombre_archivo = f"{fecha}_{slug}.txt"

    # Crear directorios si no existen
    for d in [DRAFTS_DIR, REVIEW_DIR, DESIGN_DIR, READY_DIR, PUBLISHED_DIR]:
        d.mkdir(parents=True, exist_ok=True)

    # 01_drafts
    draft_path = DRAFTS_DIR / nombre_archivo
    with open(draft_path, "w", encoding="utf-8") as f:
        f.write(articulo["raw"])
    print(f"  [01] Guardado en drafts: {nombre_archivo}")

    # 02_review → 03_design → 04_ready
    review_path = REVIEW_DIR / nombre_archivo
    design_path = DESIGN_DIR / nombre_archivo
    ready_path  = READY_DIR  / nombre_archivo

    shutil.move(str(draft_path), str(review_path))
    print(f"  [02] Movido a review")

    shutil.move(str(review_path), str(design_path))
    print(f"  [03] Movido a design")

    shutil.move(str(design_path), str(ready_path))
    print(f"  [04] Movido a ready — listo para build_blog.py")

    # Crear _meta.json para que build_blog.py lo procese correctamente
    meta_json = {
        "title":        articulo["titulo"],
        "slug":         slug,
        "category":     articulo["categoria"],
        "publish_date": fecha,
        "excerpt":      "",   # build_blog.py lo extrae del .txt
        "approved_by":  "Andres Bernal",
        "approved_at":  datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "status":       "ready",
    }
    meta_path = READY_DIR / f"{slug}_meta.json"
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta_json, f, ensure_ascii=False, indent=2)
    print(f"  [04] Meta JSON creado: {slug}_meta.json")

    return ready_path

# ── EJECUTAR BUILD_BLOG.PY ─────────────────────────────────
def ejecutar_build():
    print("\n  Ejecutando build_blog.py...")
    result = subprocess.run(
        [sys.executable, str(BASE_DIR / "build_blog.py")],
        capture_output=True, text=True, cwd=str(BASE_DIR)
    )
    if result.stdout:
        for line in result.stdout.strip().splitlines():
            print(f"  {line}")
    if result.returncode != 0:
        print(f"\n  ERROR en build_blog.py:\n{result.stderr}")
        sys.exit(1)

# ── GIT COMMIT Y PUSH ──────────────────────────────────────
def git_push(titulo: str):
    print("\n  Haciendo commit y push...")
    commit_msg = f"feat: Article - {titulo}"

    commands = [
        ["git", "add", "."],
        ["git", "commit", "-m", commit_msg],
        ["git", "push", "origin", "main"],
    ]

    for cmd in commands:
        result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(BASE_DIR))
        if result.returncode != 0:
            print(f"\n  ERROR ejecutando: {' '.join(cmd)}")
            print(result.stderr)
            sys.exit(1)
        print(f"  [OK] {' '.join(cmd)}")

# ── MAIN ───────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(
        description="Genera y publica un artículo en StackDeploy usando IA"
    )
    parser.add_argument("tema", help="Tema del artículo (ej: 'Docker Compose para desarrollo local')")
    parser.add_argument(
        "--categoria",
        choices=CATEGORIAS,
        default=None,
        help="Categoría del artículo (auto-detectada si no se especifica)"
    )
    parser.add_argument(
        "--nivel",
        choices=NIVELES,
        default="Intermediate",
        help="Nivel de dificultad (default: Intermediate)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Genera el artículo pero no hace commit/push"
    )
    args = parser.parse_args()

    print("\n" + "=" * 56)
    print("  STACKDEPLOY — Generador de Artículos con IA")
    print("=" * 56)

    categoria = args.categoria or detectar_categoria(args.tema)
    nivel = args.nivel

    # 1. Generar artículo con Claude
    articulo = generar_articulo_con_ia(args.tema, categoria, nivel)

    # 2. Mover por el pipeline
    mover_por_pipeline(articulo)

    # 3. Ejecutar build_blog.py
    ejecutar_build()

    slug = articulo["slug"]
    url  = f"https://stackdeploy.dev/articles/{slug}.html"

    if args.dry_run:
        print(f"\n  [DRY RUN] Artículo generado y HTML construido.")
        print(f"  No se hizo commit/push.")
        print(f"  Archivo listo: public/articles/{slug}.html")
    else:
        # 4. Commit y push
        git_push(articulo["titulo"])
        print(f"\n  Deployment iniciado en GitHub Actions.")
        print(f"  El artículo estará disponible en ~2-3 min:")
        print(f"  {url}")

    print("\n" + "=" * 56 + "\n")


if __name__ == "__main__":
    main()
