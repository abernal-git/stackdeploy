# ============================================================
#  StackDeploy Blog — Dockerfile
#  Multi-stage build: build → production (nginx)
# ============================================================
 
# ── STAGE 1: Build ──────────────────────────────────────────
FROM node:20-alpine AS builder
 
LABEL maintainer="Andres Bernal <abernal093>"
LABEL app="stackdeploy-blog"
 
WORKDIR /app
 
# Copiar dependencias primero (cache layer)
COPY package*.json ./
RUN npm ci --only=production 2>/dev/null || echo "No package.json, skipping npm install"
 
# Copiar el resto del código
COPY . .
 
# Si usas un build step (ej: Astro, Next, Hugo) descomenta:
# RUN npm run build
 
# ── STAGE 2: Production (nginx) ─────────────────────────────
FROM nginx:1.25-alpine AS production
 
# Copiar config personalizada de nginx
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
 
# Copiar el blog (HTML estático o build output)
COPY --from=builder /app /usr/share/nginx/html
 
# Variables de entorno para el ambiente
ARG ENVIRONMENT=production
ARG APP_VERSION=latest
ENV ENVIRONMENT=${ENVIRONMENT}
ENV APP_VERSION=${APP_VERSION}
 
# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/health || exit 1
 
# Exponer puerto
EXPOSE 80
 
# Script de arranque
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
 
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
 # ============================================================
#  StackDeploy Blog — Dockerfile
#  Multi-stage build: build → production (nginx)
# ============================================================
 
# ── STAGE 1: Build ──────────────────────────────────────────
FROM node:20-alpine AS builder
 
LABEL maintainer="Andres Bernal <abernal093>"
LABEL app="stackdeploy-blog"
 
WORKDIR /app
 
# Copiar dependencias primero (cache layer)
COPY package*.json ./
RUN npm ci --only=production 2>/dev/null || echo "No package.json, skipping npm install"
 
# Copiar el resto del código
COPY . .
 
# Si usas un build step (ej: Astro, Next, Hugo) descomenta:
# RUN npm run build
 
# ── STAGE 2: Production (nginx) ─────────────────────────────
FROM nginx:1.25-alpine AS production
 
# Copiar config personalizada de nginx
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
 
# Copiar el blog (HTML estático o build output)
COPY --from=builder /app /usr/share/nginx/html
 
# Variables de entorno para el ambiente
ARG ENVIRONMENT=production
ARG APP_VERSION=latest
ENV ENVIRONMENT=${ENVIRONMENT}
ENV APP_VERSION=${APP_VERSION}
 
# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/health || exit 1
 
# Exponer puerto
EXPOSE 80
 
# Script de arranque
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
 
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
 
