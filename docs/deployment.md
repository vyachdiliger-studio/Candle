# Deployment

## How a release works

1. Push to `main`. GitHub Actions (`.github/workflows/ci.yml`) runs `make lint`,
   then builds the production images and pushes them to GHCR:
   `ghcr.io/<owner>/candle-api` and `candle-web`, tags `latest` and the commit SHA.
2. Wait for the green check on GitHub (about 10 minutes).
3. On the server:

   ```bash
   cd /srv/candle/Candle && make deploy
   ```

   `make deploy` = `git pull --ff-only` (compose files, Candle's Caddyfile) +
   `docker compose pull` + `up -d` (recreates only what changed) + `docker image prune`.
   The server never builds anything.

**Rollback**: set `IMAGE_TAG=<previous commit SHA>` in `.env`, run `make prod`;
set it back to `latest` afterwards. Database migrations are not rolled back automatically.

## Server layout

```text
Internet ──HTTPS──> Caddy (systemd, /etc/caddy/Caddyfile) ──> 127.0.0.1:8090 Candle (Docker)
                                                          └─> /var/www/vyachdiliger (static site)
```

The server's Caddy owns ports 80/443 and the certificates. The Candle block is:

```caddy
candle.vyachdiliger.com {
	reverse_proxy 127.0.0.1:8090
}
```

Routing inside Candle (`/api`, `/candles`, `/candle-media`, web) lives in this
repository (`deploy/Caddyfile`), so it changes with the code.

## Production `.env`

| Variable | Value |
| --- | --- |
| `PUBLIC_URL` | `https://candle.vyachdiliger.com` |
| `HTTP_PORT` | `8090` (must match the server Caddyfile) |
| `POSTGRES_PASSWORD` | `openssl rand -hex 24` |
| `STORAGE_ACCESS_KEY`, `STORAGE_SECRET_KEY` | `openssl rand -hex 16` each |
| `JWT_KEY` | `openssl rand -base64 48` |
| `TELEGRAM_BOT_ENABLED` | `true` |
| `TELEGRAM_BOT_TOKEN` | Bot token from @BotFather |
| `TELEGRAM_WEBHOOK_SECRET` | `openssl rand -hex 32` |
| `IMAGE_REGISTRY` | `ghcr.io/<owner, lowercase>` |
| `IMAGE_TAG` | `latest` |

`DEV_*` variables are ignored. Keep `chmod 600 .env`.

## One-time server setup

1. **Read access to GHCR.** On GitHub: Settings → Developer settings → Personal access
   tokens → Tokens (classic) → scope `read:packages` only. On the server:

   ```bash
   docker login ghcr.io -u <github-user>     # paste the token as the password
   ```

2. **Clone and configure**:

   ```bash
   git clone git@github.com:<owner>/Candle.git /srv/candle/Candle && cd /srv/candle/Candle
   cp .env.example .env && chmod 600 .env && nano .env
   ```

   The server needs read access to the repository (deploy key or an SSH key of the account).

## Moving from the old layout (one time)

Old layout: `/srv/candle/CandleBackend` (compose project `candlebackend`, API on
`127.0.0.1:8082`, storage on `127.0.0.1:8333`), Flutter files in `/var/www/candle`
served by the server's Caddy. The new stack starts with **empty volumes** and the
data is restored from a fresh backup. Old volumes stay untouched for rollback.

1. Make sure the images exist in GHCR (first green CI run on `main`) and do the
   one-time setup above. `POSTGRES_PASSWORD` can be new: the new volume is created
   with it. Use **new** storage keys, JWT key, Telegram token (revoke the old one in
   @BotFather) and webhook secret.

2. **Pull images while the old site still runs**:

   ```bash
   cd /srv/candle/Candle
   docker compose -f compose.yaml -f compose.prod.yaml pull
   ```

3. **Stop the old stack** (volumes are kept) and take the final backup:

   ```bash
   cd /srv/candle/CandleBackend
   docker compose stop api
   docker compose exec -T db pg_dump -U candle -d candle -Fc > /root/backups/final.dump
   docker run --rm -v candlebackend_candle_media_data:/data:ro alpine tar czf - -C /data . > /root/backups/final-media.tgz
   docker compose down
   ```

4. **Start the new database and storage, restore the data**:

   ```bash
   cd /srv/candle/Candle
   P="docker compose -f compose.yaml -f compose.prod.yaml"
   $P up -d db
   $P exec -T db pg_restore -U candle -d candle --clean --if-exists < /root/backups/final.dump
   docker run --rm -v candle_media_data:/data -v /root/backups:/b:ro alpine sh -c 'tar xzf /b/final-media.tgz -C /data'
   ```

   `pg_restore` may print notices about PostGIS objects that already exist; the
   table counts in step 7 are what matters.

5. **Start everything**: `make prod`. Migrations already applied in the dump are skipped.

6. **Switch the server Caddy**: in `/etc/caddy/Caddyfile` replace the whole
   `candle.vyachdiliger.com { ... }` block with the one above, then:

   ```bash
   caddy validate --config /etc/caddy/Caddyfile && systemctl reload caddy
   ```

7. **Verify**:

   ```bash
   docker compose -f compose.yaml -f compose.prod.yaml exec -T db psql -U candle -d candle -Atc \
     'select count(*) from "Users"; select count(*) from "Candles"; select count(*) from "MediaResources";'
   curl -I https://candle.vyachdiliger.com/
   curl -s https://candle.vyachdiliger.com/candles/<existing id> | grep og:title
   ```

   Open the app: log in, open an existing candle with a background, upload a new
   background, tap a candle, open the bot and the Mini App.

**Rollback**: restore the old Caddy block (`reverse_proxy 127.0.0.1:8082` etc.,
`/var/www/candle`), `systemctl reload caddy`, `make prod-down`,
`cd /srv/candle/CandleBackend && docker compose up -d`.
Remove the old volumes, `/var/www/candle` and `/srv/candle/CandleBackend` only after
the new deployment has run for a while.

A new `JWT_KEY` does not sign users out: refresh tokens are random values stored in the
database (restored with the dump). Old access tokens get 401, and the app refreshes them.

## Backups

```bash
docker compose -f compose.yaml -f compose.prod.yaml exec -T db pg_dump -U candle -d candle -Fc > candle-$(date +%F).dump
docker run --rm -v candle_media_data:/data:ro -v "$PWD":/out alpine tar czf /out/media-$(date +%F).tgz -C /data .
```

## Mobile releases

The server and CI build only the web app. Android/iOS releases are built locally from
`frontend/app`. The Android upload keystore and `android/key.properties` are never
committed (`frontend/app/android/.gitignore`): keep them in a password manager or
another backup outside the repository.
