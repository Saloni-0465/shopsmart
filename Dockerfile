# syntax=docker/dockerfile:1

FROM node:20-bookworm-slim AS deps
WORKDIR /app/server
COPY server/package*.json ./
COPY server/prisma ./prisma
RUN npm ci && npm prune --omit=dev

FROM node:20-bookworm-slim AS runtime
ENV NODE_ENV=production
WORKDIR /app/server

RUN groupadd --system shopsmart && useradd --system --gid shopsmart --home /app shopsmart

COPY --from=deps --chown=shopsmart:shopsmart /app/server/node_modules ./node_modules
COPY --chown=shopsmart:shopsmart server/package*.json ./
COPY --chown=shopsmart:shopsmart server/prisma ./prisma
COPY --chown=shopsmart:shopsmart server/src ./src

USER shopsmart
EXPOSE 5001

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:' + (process.env.PORT || 5001) + '/api/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["node", "src/index.js"]
