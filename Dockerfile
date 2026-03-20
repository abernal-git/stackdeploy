# ============================================================
#  StackDeploy Blog -- Dockerfile
#  Multi-stage build: build -> production (nginx)
# ============================================================

# -- STAGE 1: Build ------------------------------------------
FROM python:3.11-alpine AS builder

WORKDIR /app

# Copiar todo el proyecto
COPY . .

# Correr el build del blog (convierte .txt -> HTML)
RUN python3 build_blog.py

# -- STAGE 2: Production (nginx) -----------------------------
FROM nginx:1.25-alpine AS production

ARG ENVIRONMENT=production
ARG APP_VERSION=latest
ENV ENVIRONMENT=${ENVIRONMENT}
ENV APP_VERSION=${APP_VERSION}

# Copiar config nginx
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Copiar solo la carpeta public/ generada por build_blog.py
COPY --from=builder /app/public /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/health || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
