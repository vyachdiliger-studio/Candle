# Architecture

## Services

All services run in one Docker Compose project named `candle`.

| Service   | Image / build                     | Role |
| --------- | --------------------------------- | ---- |
| `proxy`   | `caddy:2.11-alpine`               | Candle's entry point and router (plain HTTP), the only service with a host port (`127.0.0.1:HTTP_PORT`) |
| `web`     | `frontend/app/Dockerfile`         | Flutter web build served by Caddy as static files |
| `api`     | `backend/api/Dockerfile`          | ASP.NET Core API, Telegram bot webhook, public candle pages |
| `storage` | `chrislusf/seaweedfs` (`mini`)    | S3-compatible media storage, bucket `candle-media` |
| `db`      | `postgis/postgis:16-3.4`          | PostgreSQL + PostGIS |

Volumes: `pg_data` (database), `media_data` (media files).

```text
Internet ──HTTPS──> server Caddy (systemd) ──HTTP──> 127.0.0.1:8090 proxy ──> api / web / storage
```

TLS is terminated by the server's own Caddy, which also serves other sites on the
same server. In development nothing sits in front of `proxy`.

## Routing

`deploy/Caddyfile` (inside the Candle project):

| Path              | Target          | Notes |
| ----------------- | --------------- | ----- |
| `/api`, `/api/*`  | `api:8080`      | Prefix is not stripped |
| `/candles/*`      | `api:8080`      | Server-rendered entry point with link-preview metadata |
| `/candle-media/uploads/*` | `storage:8333` | Only `PUT` and `OPTIONS`: presigned uploads; Host and query must stay intact. Any other `/candle-media` request gets 404 |
| everything else   | `web:80`        | Flutter web, SPA fallback to `index.html` |

The API fetches the Flutter `index.html` from `http://web/index.html` to render
`/candles/{id}` pages (see `docs/backend/link-previews.md`).

## Configuration

- Secrets live only in `.env` (git-ignored); `.env.example` documents every variable.
- `compose.yaml` maps `.env` to ASP.NET Core settings (`Section__Key`) and refuses to
  start when a required secret is missing.
- `appsettings.json` holds non-secret defaults; `appsettings.Development.json` holds
  values for running the API from an IDE against `make dev`.
- The Flutter app takes `API_BASE_URL` / `SHARE_BASE_URL` via `--dart-define`
  (defaults: production). The `web` image is built with both derived from `PUBLIC_URL`.
- Outside Development the API refuses to start with an empty or placeholder JWT key.

## Images

Dockerfiles use stages like Aura: `base` (restore + sources), `dev`, `publish`/`build`, `prod`.
`compose.dev.yaml` builds locally and runs the API with `dotnet watch` on the mounted
sources. In production the `prod` stages are built by GitHub Actions on every push to
`master` and pushed to GHCR as `candle-api` / `candle-web` with tags `latest` and the commit
SHA; `compose.prod.yaml` pulls them (`IMAGE_REGISTRY`, `IMAGE_TAG`). The server never
builds; `make prod-build` exists as a fallback. The Flutter SDK version is pinned in
`frontend/app/Dockerfile` (`FLUTTER_VERSION`).

## Several projects on one server

Only one process can own ports 80/443: the server's Caddy. Each project publishes one
port on `127.0.0.1` and gets a site block in `/etc/caddy/Caddyfile`. If the server
configuration should move into git later, the same Caddy can run as a separate
`edge` Compose project on a shared Docker network; projects stay unchanged apart
from the network.
