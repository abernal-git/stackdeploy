# ============================================================
#  StackDeploy Blog -- Dockerfile
#  Multi-stage build: build -> production (nginx)
# ============================================================

# -- STAGE 1: Build ------------------------------------------
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar dependencias primero (cache layer)
COPY package*.json ./
RUN npm ci --only=production 2>/dev/null || echo "No package.json, skipping"

# Copiar el resto del codigo
COPY . .

# -- STAGE 2: Production (nginx) -----------------------------
FROM nginx:1.25-alpine AS production

ARG ENVIRONMENT=production
ARG APP_VERSION=latest
ENV ENVIRONMENT=${ENVIRONMENT}
ENV APP_VERSION=${APP_VERSION}

# Copiar config nginx
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Copiar el blog (HTML estatico)
COPY --from=builder /app /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/health || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
