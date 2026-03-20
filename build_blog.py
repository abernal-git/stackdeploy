#!/usr/bin/env python3
# ============================================================
#  StackDeploy — build_blog.py
#  Convierte los .txt de 04_ready/ a HTML
#  y regenera el index.html con todos los articulos
#
#  Uso: python3 build_blog.py
#  Corre automaticamente en el pipeline de GitHub Actions
# ============================================================

import os
import json
import re
import shutil
from datetime import datetime
from pathlib import Path

# ── CONFIGURACION ──────────────────────────────────────────
BASE_DIR      = Path(__file__).parent
READY_DIR     = BASE_DIR / "stackdeploy-content" / "04_ready"
PUBLISHED_DIR = BASE_DIR / "stackdeploy-content" / "05_published"
OUTPUT_DIR    = BASE_DIR / "public"
ARTICLES_DIR  = OUTPUT_DIR / "articles"

# ── CREAR CARPETAS ─────────────────────────────────────────
OUTPUT_DIR.mkdir(exist_ok=True)
ARTICLES_DIR.mkdir(exist_ok=True)
PUBLISHED_DIR.mkdir(exist_ok=True)

# ── PARSEAR .TXT DEL PIPELINE ──────────────────────────────
def parse_article_txt(filepath):
    """Lee un .txt del pipeline y extrae metadata + cuerpo"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    meta = {}

    # Extraer campos del header
    fields = ['TITULO', 'SLUG', 'FECHA', 'CATEGORIA', 'NIVEL', 'AUTOR']
    for field in fields:
        # Handle both accented and non-accented
        patterns = [field, field.replace('I', 'Í').replace('E', 'É')]
        for pattern in patterns:
            match = re.search(rf'^{pattern}[:\s]+(.+)$', content, re.MULTILINE | re.IGNORECASE)
            if match:
                meta[field.lower().replace('í','i').replace('é','e')] = match.group(1).strip()
                break

    # Descripcion SEO
    seo_match = re.search(r'DESCRIPCI[OÓ]N SEO:\s*\n(.+?)(?=\n\n|\nKEYWORDS)', content, re.DOTALL)
    if seo_match:
        meta['excerpt'] = seo_match.group(1).strip()

    # Keywords
    kw_match = re.search(r'KEYWORDS:\s*\n(.+?)(?=\n={4,}|\nCUERPO)', content, re.DOTALL)
    if kw_match:
        meta['keywords'] = kw_match.group(1).strip()

    # Cuerpo del articulo
    body_match = re.search(r'CUERPO DEL ART[IÍ]CULO:\s*[-─]+\s*\n(.*?)(?=\n={4,}\s*NOTAS|\Z)', content, re.DOTALL)
    if body_match:
        meta['body'] = body_match.group(1).strip()
    else:
        meta['body'] = ''

    return meta

# ── MARKDOWN SIMPLE → HTML ─────────────────────────────────
def markdown_to_html(text):
    """Convierte markdown basico a HTML"""
    lines = text.split('\n')
    html_lines = []
    in_code_block = False
    in_ul = False
    code_lang = ''
    code_content = []

    for line in lines:
        # Code blocks
        if line.startswith('```'):
            if not in_code_block:
                in_code_block = True
                code_lang = line[3:].strip() or 'bash'
                code_content = []
            else:
                in_code_block = False
                escaped = '\n'.join(code_content).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
                html_lines.append(f'<div class="code-block"><div class="code-header"><span class="code-lang">{code_lang}</span><button class="copy-btn" onclick="copyCode(this)">COPY</button></div><pre><code class="{code_lang}">{escaped}</code></pre></div>')
            continue

        if in_code_block:
            code_content.append(line)
            continue

        # Headings
        if line.startswith('#### '):
            html_lines.append(f'<h4>{line[5:]}</h4>')
        elif line.startswith('### '):
            html_lines.append(f'<h3>{line[4:]}</h3>')
        elif line.startswith('## '):
            html_lines.append(f'<h2>{line[3:]}</h2>')
        elif line.startswith('# '):
            html_lines.append(f'<h1>{line[2:]}</h1>')
        # Horizontal rule
        elif line.strip() in ['---', '***', '___']:
            html_lines.append('<hr>')
        # List items
        elif line.startswith('- ') or line.startswith('* '):
            if not in_ul:
                html_lines.append('<ul>')
                in_ul = True
            item = line[2:]
            item = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', item)
            item = re.sub(r'`(.+?)`', r'<code>\1</code>', item)
            html_lines.append(f'<li>{item}</li>')
            continue
        # Empty line
        elif line.strip() == '':
            if in_ul:
                html_lines.append('</ul>')
                in_ul = False
            html_lines.append('')
        # Normal paragraph
        else:
            if in_ul:
                html_lines.append('</ul>')
                in_ul = False
            # Inline formatting
            line = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', line)
            line = re.sub(r'\*(.+?)\*', r'<em>\1</em>', line)
            line = re.sub(r'`(.+?)`', r'<code>\1</code>', line)
            line = re.sub(r'\[(.+?)\]\((.+?)\)', r'<a href="\2" target="_blank">\1</a>', line)
            html_lines.append(f'<p>{line}</p>')

    if in_ul:
        html_lines.append('</ul>')

    return '\n'.join(html_lines)

# ── GENERAR HTML DEL ARTICULO ──────────────────────────────
def generate_article_html(meta, read_time):
    body_html = markdown_to_html(meta.get('body', ''))
    title = meta.get('titulo', 'Sin titulo')
    slug = meta.get('slug', 'articulo')
    date = meta.get('fecha', '')
    category = meta.get('categoria', '')
    level = meta.get('nivel', '')
    excerpt = meta.get('excerpt', '')
    keywords = meta.get('keywords', '')
    author = meta.get('autor', 'Andres Bernal (@abernal093)')

    return f'''<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{title} | StackDeploy</title>
<meta name="description" content="{excerpt}">
<meta name="keywords" content="{keywords}">
<meta name="author" content="Andres Bernal">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{excerpt}">
<meta property="og:type" content="article">
<meta property="og:url" content="https://stackdeploy.dev/articles/{slug}">
<link rel="canonical" href="https://stackdeploy.dev/articles/{slug}">
<link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Space+Mono:wght@400;700&family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
  :root {{
    --black: #0a0a0a; --dark: #111; --card: #141414;
    --accent: #b0b0b0; --white: #f0f0f0; --gray: #888; --border: #222;
  }}
  * {{ margin:0; padding:0; box-sizing:border-box; }}
  body {{ background:var(--black); color:var(--white); font-family:'Inter',sans-serif; line-height:1.8; }}

  /* NAV */
  nav {{ position:fixed; top:0; width:100%; z-index:999; display:flex; align-items:center;
    justify-content:space-between; padding:0 40px; height:64px;
    background:rgba(10,10,10,0.95); backdrop-filter:blur(12px); border-bottom:1px solid var(--border); }}
  .nav-logo {{ font-family:'Bebas Neue',sans-serif; font-size:22px; letter-spacing:3px;
    color:var(--accent); text-decoration:none; }}
  .nav-links {{ display:flex; gap:8px; list-style:none; }}
  .nav-links a {{ font-family:'Space Mono',monospace; font-size:11px; color:var(--gray);
    text-decoration:none; padding:8px 16px; border:1px solid transparent;
    transition:all 0.2s; letter-spacing:1px; text-transform:uppercase; }}
  .nav-links a:hover {{ color:var(--accent); border-color:var(--accent); }}

  /* ARTICLE */
  .article-wrapper {{ max-width:780px; margin:0 auto; padding:100px 40px 80px; }}

  .article-meta {{ margin-bottom:40px; }}
  .meta-tags {{ display:flex; gap:8px; flex-wrap:wrap; margin-bottom:20px; }}
  .meta-tag {{ font-family:'Space Mono',monospace; font-size:9px; color:var(--white);
    background:#2a2a2a; padding:4px 10px; letter-spacing:1px; text-transform:uppercase;
    border:1px solid #3a3a3a; }}
  .meta-tag.accent {{ background:var(--accent); color:var(--black); border-color:var(--accent); }}
  .article-title {{ font-family:'Bebas Neue',sans-serif; font-size:clamp(36px,6vw,64px);
    line-height:1; letter-spacing:1px; color:var(--white); margin-bottom:16px; }}
  .article-excerpt {{ font-size:16px; color:var(--gray); line-height:1.7;
    font-weight:300; margin-bottom:24px; border-left:3px solid var(--accent); padding-left:20px; }}
  .article-info {{ display:flex; gap:24px; font-family:'Space Mono',monospace;
    font-size:11px; color:#555; flex-wrap:wrap; }}
  .article-info span {{ color:var(--accent); }}

  /* CONTENT */
  .article-content {{ border-top:1px solid var(--border); padding-top:48px; }}
  .article-content h1 {{ font-family:'Bebas Neue',sans-serif; font-size:42px; margin:48px 0 16px; color:var(--accent); }}
  .article-content h2 {{ font-family:'Bebas Neue',sans-serif; font-size:32px; margin:40px 0 16px;
    color:var(--white); border-bottom:1px solid var(--border); padding-bottom:8px; }}
  .article-content h3 {{ font-family:'Bebas Neue',sans-serif; font-size:24px; margin:32px 0 12px; color:var(--accent); }}
  .article-content h4 {{ font-size:16px; font-weight:600; margin:24px 0 8px; color:var(--white); }}
  .article-content p {{ font-size:15px; color:#ccc; margin-bottom:20px; line-height:1.8; }}
  .article-content ul {{ margin:16px 0 24px 0; padding-left:0; list-style:none; }}
  .article-content li {{ font-size:15px; color:#ccc; padding:6px 0 6px 20px;
    border-left:2px solid var(--border); margin-bottom:4px; position:relative; }}
  .article-content li::before {{ content:'→'; position:absolute; left:-20px; color:var(--accent); }}
  .article-content hr {{ border:none; border-top:1px solid var(--border); margin:40px 0; }}
  .article-content strong {{ color:var(--white); font-weight:600; }}
  .article-content em {{ color:var(--accent); font-style:italic; }}
  .article-content a {{ color:var(--accent); text-decoration:none; border-bottom:1px solid rgba(176,176,176,0.3); }}
  .article-content a:hover {{ border-bottom-color:var(--accent); }}
  .article-content code {{ font-family:'Space Mono',monospace; font-size:12px;
    background:#1a1a1a; color:var(--accent); padding:2px 6px; border:1px solid var(--border); }}

  /* CODE BLOCKS */
  .code-block {{ background:#0d0d0d; border:1px solid var(--border); margin:24px 0; overflow:hidden; }}
  .code-header {{ display:flex; align-items:center; justify-content:space-between;
    padding:8px 16px; background:#111; border-bottom:1px solid var(--border); }}
  .code-lang {{ font-family:'Space Mono',monospace; font-size:10px; color:var(--accent);
    letter-spacing:2px; text-transform:uppercase; }}
  .copy-btn {{ font-family:'Space Mono',monospace; font-size:9px; color:var(--gray);
    background:transparent; border:1px solid var(--border); padding:4px 10px;
    cursor:pointer; letter-spacing:1px; transition:all 0.2s; }}
  .copy-btn:hover {{ color:var(--accent); border-color:var(--accent); }}
  .code-block pre {{ padding:20px; overflow-x:auto; }}
  .code-block code {{ background:transparent; border:none; padding:0;
    font-size:13px; color:#e0e0e0; line-height:1.6; }}

  /* FOOTER */
  .article-footer {{ margin-top:80px; padding-top:40px; border-top:1px solid var(--border);
    display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:20px; }}
  .back-link {{ font-family:'Space Mono',monospace; font-size:11px; color:var(--gray);
    text-decoration:none; letter-spacing:1px; text-transform:uppercase;
    border:1px solid var(--border); padding:10px 20px; transition:all 0.2s; }}
  .back-link:hover {{ color:var(--accent); border-color:var(--accent); }}
  .author-block {{ font-family:'Space Mono',monospace; font-size:11px; color:#555; }}
  .author-block span {{ color:var(--accent); }}

  /* PAGE FOOTER */
  footer {{ background:#080808; border-top:1px solid var(--border); padding:30px 40px;
    display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:16px; }}
  .footer-logo {{ font-family:'Bebas Neue',sans-serif; font-size:24px; color:var(--accent); letter-spacing:3px; }}
  .footer-copy {{ font-family:'Space Mono',monospace; font-size:10px; color:#444; letter-spacing:2px; }}
  .footer-copy span {{ color:var(--accent); }}

  @media(max-width:768px) {{
    nav {{ padding:0 20px; }} .nav-links {{ display:none; }}
    .article-wrapper {{ padding:90px 20px 60px; }}
    footer {{ padding:24px 20px; flex-direction:column; text-align:center; }}
  }}
</style>
</head>
<body>

<nav>
  <a href="/" class="nav-logo">STACKDEPLOY</a>
  <ul class="nav-links">
    <li><a href="/">Home</a></li>
    <li><a href="/articles">Articles</a></li>
    <li><a href="/tutorials">Tutorials</a></li>
    <li><a href="/contact">Contact</a></li>
  </ul>
</nav>

<article class="article-wrapper">
  <div class="article-meta">
    <div class="meta-tags">
      <span class="meta-tag accent">{category}</span>
      <span class="meta-tag">{level}</span>
      <span class="meta-tag">{read_time} MIN READ</span>
    </div>
    <h1 class="article-title">{title}</h1>
    <p class="article-excerpt">{excerpt}</p>
    <div class="article-info">
      <span>BY <span>{author}</span></span>
      <span>PUBLISHED <span>{date}</span></span>
      <span>STACKDEPLOY.DEV</span>
    </div>
  </div>

  <div class="article-content">
    {body_html}
  </div>

  <div class="article-footer">
    <a href="/" class="back-link">← Back to Articles</a>
    <div class="author-block">Written by <span>Andres Bernal</span> | <span>@abernal093</span></div>
  </div>
</article>

<footer>
  <div class="footer-logo">STACKDEPLOY</div>
  <div class="footer-copy">© <span>2026</span> ANDRES BERNAL — ALL RIGHTS RESERVED</div>
</footer>

<script>
function copyCode(btn) {{
  const code = btn.closest('.code-block').querySelector('code').innerText;
  navigator.clipboard.writeText(code).then(() => {{
    btn.textContent = 'COPIED!';
    setTimeout(() => btn.textContent = 'COPY', 2000);
  }});
}}
</script>
</body>
</html>'''

# ── GENERAR INDEX.HTML ─────────────────────────────────────
def generate_index_html(articles):
    cards_html = ''
    for a in articles:
        cards_html += f'''
        <div class="article-card" onclick="window.location='/articles/{a["slug"]}.html'">
          <div class="card-tags">
            <span class="tag">{a.get("categoria","")}</span>
            <span class="tag outline">{a.get("nivel","")}</span>
          </div>
          <div class="card-title">{a.get("titulo","")}</div>
          <p class="card-excerpt">{a.get("excerpt","")}</p>
          <div class="card-meta">
            <span>{a.get("fecha","")}</span>
            <a href="/articles/{a["slug"]}.html" class="read-more">READ MORE →</a>
          </div>
        </div>'''

    # Read the existing index.html if it exists, otherwise use base template
    index_path = BASE_DIR / "index.html"
    if index_path.exists():
        with open(index_path, 'r', encoding='utf-8') as f:
            existing = f.read()
        # Inject articles into existing blog
        marker_start = '<!-- ARTICLES_START -->'
        marker_end = '<!-- ARTICLES_END -->'
        if marker_start in existing and marker_end in existing:
            new_content = re.sub(
                f'{re.escape(marker_start)}.*?{re.escape(marker_end)}',
                f'{marker_start}\n{cards_html}\n{marker_end}',
                existing, flags=re.DOTALL
            )
            return new_content

    # Fallback: generate simple index
    return f'''<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>StackDeploy — Know Your Infra. Build Your Dream.</title>
<link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Space+Mono:wght@400;700&family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
  :root {{ --black:#0a0a0a; --accent:#b0b0b0; --white:#f0f0f0; --gray:#888; --border:#222; --card:#141414; }}
  * {{ margin:0; padding:0; box-sizing:border-box; }}
  body {{ background:var(--black); color:var(--white); font-family:'Inter',sans-serif; }}
  nav {{ position:fixed; top:0; width:100%; z-index:999; display:flex; align-items:center;
    justify-content:space-between; padding:0 40px; height:64px;
    background:rgba(10,10,10,0.95); backdrop-filter:blur(12px); border-bottom:1px solid var(--border); }}
  .nav-logo {{ font-family:'Bebas Neue',sans-serif; font-size:22px; letter-spacing:3px; color:var(--accent); text-decoration:none; }}
  .hero {{ min-height:80vh; display:flex; align-items:center; padding:80px 40px; background:radial-gradient(ellipse 60% 50% at 70% 50%, rgba(176,176,176,0.04) 0%, transparent 70%); }}
  .hero h1 {{ font-family:'Bebas Neue',sans-serif; font-size:clamp(56px,10vw,120px); line-height:0.9; }}
  .hero-accent {{ color:var(--accent); display:block; }}
  .hero-tagline {{ font-family:'Bebas Neue',sans-serif; font-size:clamp(24px,4vw,48px); color:var(--accent); letter-spacing:6px; margin-top:8px; opacity:0.8; }}
  .hero-sub {{ font-size:16px; color:var(--gray); max-width:500px; margin:24px 0 0; line-height:1.7; }}
  .articles {{ padding:80px 40px; }}
  .section-header {{ display:flex; align-items:baseline; justify-content:space-between; margin-bottom:48px; border-bottom:1px solid var(--border); padding-bottom:20px; }}
  .section-title {{ font-family:'Bebas Neue',sans-serif; font-size:48px; letter-spacing:2px; }}
  .articles-grid {{ display:grid; grid-template-columns:repeat(auto-fill,minmax(340px,1fr)); gap:2px; }}
  .article-card {{ background:var(--card); border:1px solid var(--border); padding:32px; cursor:pointer; transition:all 0.3s; position:relative; overflow:hidden; }}
  .article-card::before {{ content:''; position:absolute; top:0; left:0; width:3px; height:0; background:var(--accent); transition:height 0.3s; }}
  .article-card:hover {{ background:#181818; transform:translateY(-2px); }}
  .article-card:hover::before {{ height:100%; }}
  .card-tags {{ display:flex; gap:8px; flex-wrap:wrap; margin-bottom:16px; }}
  .tag {{ font-family:'Space Mono',monospace; font-size:9px; color:var(--white); background:#2a2a2a; padding:3px 8px; letter-spacing:1px; text-transform:uppercase; border:1px solid #3a3a3a; }}
  .tag.outline {{ background:transparent; color:var(--gray); border:1px solid var(--border); }}
  .card-title {{ font-family:'Bebas Neue',sans-serif; font-size:26px; letter-spacing:1px; line-height:1.1; margin-bottom:12px; transition:color 0.2s; }}
  .article-card:hover .card-title {{ color:var(--accent); }}
  .card-excerpt {{ font-size:13px; color:var(--gray); line-height:1.7; margin-bottom:24px; }}
  .card-meta {{ display:flex; align-items:center; justify-content:space-between; font-family:'Space Mono',monospace; font-size:10px; color:#555; border-top:1px solid var(--border); padding-top:16px; }}
  .read-more {{ color:var(--accent); text-decoration:none; font-size:10px; letter-spacing:1px; }}
  footer {{ background:#080808; border-top:1px solid var(--border); padding:30px 40px; display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:16px; }}
  .footer-logo {{ font-family:'Bebas Neue',sans-serif; font-size:24px; color:var(--accent); letter-spacing:3px; }}
  .footer-copy {{ font-family:'Space Mono',monospace; font-size:10px; color:#444; letter-spacing:2px; }}
  .footer-copy span {{ color:var(--accent); }}
</style>
</head>
<body>
<nav>
  <a href="/" class="nav-logo">STACKDEPLOY</a>
</nav>
<section class="hero">
  <div>
    <h1>KNOW YOUR <span class="hero-accent">INFRA</span></h1>
    <p class="hero-tagline">BUILD YOUR DREAM</p>
    <p class="hero-sub">Real technical tutorials, RHEL cluster configurations, and DevOps guides written from the lab.</p>
  </div>
</section>
<section class="articles">
  <div class="section-header">
    <span class="section-title">ARTICLES</span>
    <span style="font-family:'Space Mono',monospace;font-size:11px;color:var(--accent)">// {len(articles)} POSTS</span>
  </div>
  <div class="articles-grid">
    <!-- ARTICLES_START -->
    {cards_html}
    <!-- ARTICLES_END -->
  </div>
</section>
<footer>
  <div class="footer-logo">STACKDEPLOY</div>
  <div class="footer-copy">© <span>2026</span> ANDRES BERNAL — ALL RIGHTS RESERVED</div>
</footer>
</body>
</html>'''

# ── MAIN ───────────────────────────────────────────────────
def main():
    print("\n  STACKDEPLOY — Blog Builder")
    print("  ─────────────────────────────────")

    # Buscar todos los .txt en 04_ready
    txt_files = sorted(READY_DIR.glob("*.txt")) if READY_DIR.exists() else []
    json_files = sorted(READY_DIR.glob("*_meta.json")) if READY_DIR.exists() else []

    if not txt_files:
        print(f"\n  No hay articulos en {READY_DIR}")
        print("  Corre primero el pipeline de contenido.\n")
        return

    print(f"\n  Encontrados: {len(txt_files)} articulos\n")

    articles = []
    for txt_file in txt_files:
        print(f"  Procesando: {txt_file.name}")
        meta = parse_article_txt(txt_file)

        if not meta.get('slug'):
            # Extraer slug del nombre del archivo
            name = txt_file.stem
            # Remove date prefix if present (2026-03-20_slug)
            name = re.sub(r'^\d{4}-\d{2}-\d{2}_', '', name)
            meta['slug'] = name

        if not meta.get('titulo'):
            meta['titulo'] = meta['slug'].replace('-', ' ').title()

        # Calcular tiempo de lectura
        word_count = len(meta.get('body', '').split())
        read_time = max(1, round(word_count / 200))

        # Generar HTML del articulo
        article_html = generate_article_html(meta, read_time)
        output_path = ARTICLES_DIR / f"{meta['slug']}.html"
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(article_html)

        print(f"  [OK] -> public/articles/{meta['slug']}.html ({read_time} min read)")

        # Mover .txt a 05_published/ y copiar .html ahi tambien
        published_txt  = PUBLISHED_DIR / txt_file.name
        published_html = PUBLISHED_DIR / f"{meta['slug']}.html"

        shutil.move(str(txt_file), str(published_txt))
        shutil.copy(str(output_path), str(published_html))
        print(f"  [OK] -> stackdeploy-content/05_published/{txt_file.name}")
        print(f"  [OK] -> stackdeploy-content/05_published/{meta['slug']}.html")

        articles.append(meta)

        # Mover el _meta.json si existe
        meta_json = READY_DIR / f"{meta['slug']}_meta.json"
        if meta_json.exists():
            shutil.move(str(meta_json), str(PUBLISHED_DIR / meta_json.name))
            print(f"  [OK] -> stackdeploy-content/05_published/{meta_json.name}")

    # Ordenar por fecha descendente
    articles.sort(key=lambda x: x.get('fecha', ''), reverse=True)

    # Generar/actualizar index.html
    index_html = generate_index_html(articles)
    index_path = OUTPUT_DIR / "index.html"
    with open(index_path, 'w', encoding='utf-8') as f:
        f.write(index_html)

    print(f"\n  [OK] index.html actualizado con {len(articles)} articulo(s)")
    print(f"  [OK] Archivos generados en: public/")
    print(f"\n  Listo para hacer push a GitHub!\n")

if __name__ == '__main__':
    main()
