# Candle

Virtual candles of remembrance, hope and support: light a candle with a message,
place it on a map, share a link; other people's taps keep it burning longer.
Production: https://candle.vyachdiliger.com (web, Android, iOS, Telegram Mini App).

## Stack

- ASP.NET Core (.NET 10), EF Core, PostgreSQL + PostGIS
- SeaweedFS (S3-compatible media storage)
- Telegram bot (`backend/bot`, optional)
- Flutter (Android, iOS, web), Riverpod, go_router
- Docker Compose, Caddy, GitHub Actions + GHCR (production images)

## Structure

```text
Candle/
├── backend/
│   ├── api/          ASP.NET Core API (CandleBackend.csproj)
│   └── bot/          Telegram bot library (CandleBot.csproj)
├── frontend/
│   └── app/          Flutter app
├── deploy/
│   └── Caddyfile     router: /api, /candles, /candle-media, web
├── docs/
├── Candle.slnx
├── compose.yaml
├── compose.dev.yaml
├── compose.prod.yaml
└── Makefile
```

## Development

Only Docker and `make` are required.

```bash
cp .env.example .env
make dev        # http://localhost:8090
make lint       # backend + frontend checks
make dev-down
```

Flutter with hot reload runs on the host against `make dev`: `make app`.
Details: [`docs/development.md`](docs/development.md).

## Deployment

Push to `master` → GitHub Actions checks the code and publishes images to GHCR. Then on the server:

```bash
make deploy     # git pull + pull images + restart what changed
```

First-time server setup and the move from the old layout:
[`docs/deployment.md`](docs/deployment.md).

## Documentation

- [`architecture.md`](docs/architecture.md): services, routing, configuration
- [`development.md`](docs/development.md): workflow, commands, conventions
- [`deployment.md`](docs/deployment.md): server setup, deploys, backups
- [`backend/`](docs/backend): API behaviour (auth, gallery, comments, previews, media, bot, notifications)
- [`frontend/`](docs/frontend): app behaviour (auth, sessions, diagnostics)

Contributing: [`CONTRIBUTING.md`](CONTRIBUTING.md). AI coding agents: [`AGENTS.md`](AGENTS.md).
