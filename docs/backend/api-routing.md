# API routing

The backend owns the `/api` prefix. The edge proxy (`deploy/Caddyfile`) forwards
`/api/...` to the `api` service without stripping or adding a prefix. Public HTML pages at `/candles/{id}` are also
served by the backend; other paths return 404.
Swagger is at `/api/swagger/index.html`; the bot webhook is
`/api/telegram/webhook`. Media URLs returned by the API include `/api`.

Update `deploy/Caddyfile` together with the backend. Remove any rule that rewrites
`/api/foo` to `/foo`. Frontend API base URL remains `https://your-host/api`.

S3 uploads are separate: the proxy forwards `PUT` and `OPTIONS` on
`/candle-media/uploads/*` to SeaweedFS, preserving the signed Host, path and query.
Every other `/candle-media` request (reads, listing, deletes, writes outside
`uploads/`) gets 404, so storage stays closed from outside even if its keys leak. Do not route S3 uploads through `/api` or rewrite
the generated signed URLs. `Storage:PublicEndpoint` specifies the public S3 origin.