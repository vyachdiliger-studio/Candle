# Candle link previews

Caddy forwards `/candles/{id}` to the backend unchanged. The backend returns the
current Flutter entry point with candle metadata already in its HTML. Browsers
and crawlers receive the same response; no User-Agent detection or redirects.
Flutter assets continue to be served by Caddy from the same web build.

## Deployment

The `web` service serves the Flutter build; the API fetches its `index.html`
from `WebApp:EntryPointUrl` (`http://web/index.html` inside Compose) and caches it
for one minute. The edge proxy (`deploy/Caddyfile`) sends `/candles/*` to the API
with `handle`, not `handle_path`: the URL must not be stripped.
`WebApp:PublicUrl` comes from `PUBLIC_URL`. A normal `make prod` / `make deploy`
rebuilds both images; no separate frontend upload step exists.

## Response behavior

- Existing candle: 200, canonical URL, Open Graph and Twitter metadata. The
  description uses its message and the title identifies its author.
- Background present: a JPEG rendition served at `/api/resources/{id}/preview.jpg`.
  Published resources are immutable, so the image URL can be cached long-term.
- No background: the current application's `/icons/Icon-512.png`.
- Missing candle or deleted author: 404 with the Flutter entry point and noindex.
- Web service unreachable or incompatible build: 503; the server log identifies the problem.
- HTML uses `no-store`; changes appear on the next origin request. Telegram and
  other platforms maintain their own preview caches and may keep an older card.

User text is HTML-encoded. Public URLs come from configuration, not the Host
header. Preview data is public and independent of the viewer's login or blocks.
The frontend still fetches its ordinary authenticated API data after starting.

## Verify after deployment

```sh
curl -i https://candle.vyachdiliger.com/candles/9
curl -I https://candle.vyachdiliger.com/flutter_bootstrap.js
curl -I https://candle.vyachdiliger.com/api/swagger/index.html
```

The first response should be HTML containing the candle's `og:*` tags and the
normal Flutter loader, without a redirect. Open the same URL in a browser to
check that Flutter starts on the candle page. Share a new candle URL in Telegram
to avoid confusing a cached preview with the latest origin response.