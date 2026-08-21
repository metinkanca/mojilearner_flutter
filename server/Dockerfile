# Small runtime image: this service is one file of routing plus an HTTP call,
# so there is nothing to build and no reason to ship a toolchain.
FROM node:22-slim

ENV NODE_ENV=production
WORKDIR /app

# Copied first so a dependency-free code change reuses the cached install.
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev || npm install --omit=dev

COPY src ./src

# Cloud Run and most PaaS hosts inject PORT; index.js reads it.
ENV PORT=8080
EXPOSE 8080

USER node
CMD ["node", "src/index.js"]
