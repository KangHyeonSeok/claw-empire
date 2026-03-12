# Claw-Empire Docker Multi-Company Guide

This setup uses one shared application image and many company-specific runtime volumes.

## Architecture

- Shared base: one Docker image contains the Claw-Empire code and frontend build.
- Company isolation: each company gets its own SQLite database volume and logs volume.
- Easy updates: rebuild or pull one image tag, then recreate all company containers.

The production server already serves the built React app from the same process, so each company only needs one container and one exposed port.

## Files

- `Dockerfile`: builds the shared runtime image.
- `deploy/docker/fleet.config.json`: fleet template source of truth.
- `deploy/docker/company.env.template`: default env template for new companies.
- `deploy/docker/compose.multi-company.yml`: generated fleet compose file.
- `deploy/docker/runtime/*.env`: generated per-company runtime env files.

## Template workflow

Edit `deploy/docker/fleet.config.json` and regenerate the compose stack:

```bash
pnpm run docker:fleet:generate
```

When a new company is added, the generator creates `deploy/docker/runtime/<slug>.env` only if it does not already exist. That lets you keep secrets and company-specific overrides intact across regenerations.

## First start

From the repository root:

```bash
pnpm run docker:fleet:generate
docker compose -f deploy/docker/compose.multi-company.yml build
docker compose -f deploy/docker/compose.multi-company.yml up -d
```

Example URLs:

- Company Alpha: `http://127.0.0.1:8791`
- Company Beta: `http://127.0.0.1:8792`

Health checks:

```bash
curl http://127.0.0.1:8791/healthz
curl http://127.0.0.1:8792/healthz
```

## Why this matches your requirement

- The company foundation is shared because every company runs the same image.
- Company information stays isolated because each service writes to its own `DB_PATH` and `LOGS_DIR` volumes.
- Feature updates apply to all companies at once because they all restart from the same updated image.

## Updating all companies together

If you build locally from this repository:

```bash
docker compose -f deploy/docker/compose.multi-company.yml build --pull
docker compose -f deploy/docker/compose.multi-company.yml up -d
```

If you publish a registry image and want all companies to track that tag:

```bash
CLAW_EMPIRE_IMAGE=ghcr.io/your-org/claw-empire:2.0.3 docker compose -f deploy/docker/compose.multi-company.yml pull
CLAW_EMPIRE_IMAGE=ghcr.io/your-org/claw-empire:2.0.3 docker compose -f deploy/docker/compose.multi-company.yml up -d
```

Use a stable tag like `:prod` or `:latest-approved` if you want one-command fleet updates.

## Adding another company

1. Add a new item to `deploy/docker/fleet.config.json` with a unique `slug` and `hostPort`.
2. Run `pnpm run docker:fleet:generate`.
3. Edit the generated `deploy/docker/runtime/<slug>.env` and replace all `CHANGE_ME_*` values.

## Operational notes

- Replace all `CHANGE_ME_*` placeholders before exposing the service outside localhost.
- Keep one reverse proxy in front if you want friendly domains instead of separate host ports.
- If you want OpenClaw per company, mount a company-specific config file and set `OPENCLAW_CONFIG` in that company's env file.
- Named volumes keep each company's data when containers are recreated during updates.
- `deploy/docker/runtime/` is gitignored on purpose so company secrets stay local.
