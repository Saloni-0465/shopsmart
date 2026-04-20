# Shopsmart

**Shopsmart** is an **e-commerce platform** for selling **products** online (electronics, home, sports, groceries, and more)—not a bookstore or content site.

Stack: **React (Vite)** + **Express** + **Prisma** + **MySQL**.

## Features

#checking code quality raising pr to main repo

- Product catalog (retail goods)
- Register / login (JWT)
- Shopping cart & checkout (demo—no real payment processor)
- Order history

## Prerequisites

- Node 18+
- MySQL 8+ with a database:

  ```sql
  CREATE DATABASE shopmart CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  ```

## Backend (`server/`)

1. Copy `server/.env.example` → `server/.env` and set `DATABASE_URL` and `JWT_SECRET`.
2. Run:

   ```bash
   cd server
   npm install
   npx prisma migrate deploy
   npm run db:seed
   npm run dev
   ```

   **Refreshing the product catalog:** run `npm run db:seed` again after pulling changes. The seed removes old demo product names and inserts/updates the current retail list so the storefront shows new items.

   API: **http://localhost:5001**

## Frontend (`client/`)

```bash
cd client
npm install
npm run dev
```

App: **http://localhost:5173** — Vite proxies `/api` to port 5001.

For production, set `VITE_API_URL` to your API origin.

## API overview

| Area | Routes |
|------|--------|
| Health | `GET /api/health` |
| Products | `GET /api/products`, CRUD as implemented |
| Auth | `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/me` |
| Cart | `GET/POST/PATCH/DELETE /api/cart/...` (auth) |
| Orders | `POST /api/orders/checkout`, `GET /api/orders` (auth) |

## Integration tests

These hit **real HTTP** and (on the server) **real MySQL** — not mocked.

### API + database (`server/`)

Uses **Supertest** + **Prisma** against `DATABASE_URL` from `server/.env`.

```bash
cd server
npx prisma migrate deploy   # if needed
SHOPSMART_INTEGRATION=1 npm run test:integration
```

Set `SHOPSMART_INTEGRATION=1` so tests are not mistaken for unit tests against production. The suite creates rows, runs checkout, then **deletes** test users/products/orders.

### Frontend ↔ backend (`client/`)

Uses **Node `fetch`** to the API (same URLs as the browser with the Vite `/api` proxy). **Start the server first** (`npm run dev` in `server/` on port 5001).

```bash
cd client
SHOPSMART_INTEGRATION=1 npm run test:integration
```

Override base URL: `SHOPSMART_API_URL=http://127.0.0.1:5001`.

Unit tests (`npm test` in each package) **exclude** `client/src/integration/` and `server/tests/integration/`.

## End-to-end tests (Playwright, bonus)

From the **repo root** (needs `server/.env` with MySQL + `npm run db:seed` in `server/` so products exist):

```bash
npm install                 # root — installs Playwright, concurrently, wait-on
npx playwright install chromium
npm run e2e                 # starts API + Vite, runs tests (or reuse already-running servers)
```

- Specs live in **`e2e/`** (e.g. **login → add to cart → cart shows a line**).
- Override API URL for `beforeAll` register: `PLAYWRIGHT_API_URL=http://127.0.0.1:5001`.

## Lint & formatting

Shared **Prettier** config: **`.prettierrc`** (repo root).

| Package | ESLint | Prettier check |
|---------|--------|----------------|
| `client/` | `npm run lint` | `npm run format:check` |
| `server/` | `npm run lint` | `npm run format:check` |

From repo root:

```bash
npm run lint
npm run format:check
```

(`format:check` runs Prettier in `--check` mode — CI uses the same commands.)

## GitHub Actions (CI)

On **push / PR** to `main` or `master`:

1. **`lint`** — ESLint + Prettier check on **client** and **server** (fails the PR if either fails).
2. **`e2e`** — MySQL service, Prisma migrate + seed, API + Vite, **Playwright** Chromium.

Workflow file: **`.github/workflows/ci.yml`**.

## EC2 deployment (CD)

Workflow file: **`.github/workflows/deploy-ec2.yml`**.

- Triggered after **CI succeeds on `main`** (`workflow_run`) or manually (`workflow_dispatch`).
- Uses SSH to connect to EC2, pull latest code, install dependencies, run Prisma migrations, and restart API with PM2.
- Uses idempotent operations (`mkdir -p`, `git fetch/reset`, `npm ci`) so reruns are safe.

### Required GitHub Secrets

| Secret | Purpose |
|--------|---------|
| `EC2_HOST` | Public EC2 hostname or IP |
| `EC2_USER` | SSH user (e.g. `ubuntu`) |
| `EC2_SSH_KEY` | Private key (PEM content) |
| `EC2_PORT` | SSH port (usually `22`) |
| `EC2_APP_DIR` | App path on EC2 (e.g. `/home/ubuntu/shopsmart`) |
| `EC2_BRANCH` | Branch to deploy (usually `main`) |
| `EC2_PM2_APP_NAME` | PM2 process name (e.g. `shopsmart-api`) |

### One-time EC2 setup

```bash
sudo npm i -g pm2
```

Ensure `server/.env` is present on EC2 with production values (especially `DATABASE_URL` and `JWT_SECRET`).

## Dependabot

**`.github/dependabot.yml`** opens weekly PRs to update **npm** dependencies in the repo root, **`client/`**, and **`server/`**, and to bump **GitHub Actions** versions. Enable it by merging that file into the default branch (Settings → Code security → Dependabot version updates must be allowed for the repo).

## Security (production)

- Strong `JWT_SECRET`, HTTPS, rate limits on auth.
- Integrate a real payment provider (Stripe, etc.) before taking real money.
