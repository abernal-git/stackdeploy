# ============================================================
#  StackDeploy Blog -- Dockerfile
#  Multi-stage build: build -> production (nginx)
# ============================================================

# -- STAGE unico: Production (nginx) ------------------------
FROM nginx:1.25-alpine AS production

ARG ENVIRONMENT=production
ARG APP_VERSION=latest
ENV ENVIRONMENT=${ENVIRONMENT}
ENV APP_VERSION=${APP_VERSION}

# Copiar config nginx
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Copiar la carpeta public/ ya generada localmente por build_blog.py
COPY public/ /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/health || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
