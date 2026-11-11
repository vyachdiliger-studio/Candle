# Image resources and candle backgrounds

The API uses the standard AWS S3 SDK against SeaweedFS. PostgreSQL stores resource
metadata and object keys, never provider URLs. SeaweedFS stores bytes in the
`media_data` Docker volume.

## Run locally

`make dev` starts storage, the API and the proxy (see `docs/development.md`).

EF migrations run on API startup. The migration history was consolidated into
InitialMigration; this baseline requires an empty database.
The S3 bucket is initialized by SeaweedFS `mini` from `S3_BUCKET`.

`Storage:Endpoint` is the server-side endpoint (`http://storage:8333` in Compose).
`Storage:PublicEndpoint` is used to sign URLs that the client can reach. Compose sets it to `PUBLIC_URL`: the edge proxy forwards `/candle-media/*` to
SeaweedFS, so uploads use the same origin as the app (HTTPS in production).
The reverse proxy must preserve the signed Host, path and query string.
Changing the hostname of an already signed URL invalidates its signature.

## Upload protocol

1. Authenticated `POST /api/resources` with no body returns `{ id, uploadUrl, expiresAt }`.
2. `PUT` the raw file bytes to `uploadUrl`, without a Candle Authorization header
   and without multipart encoding. The URL expires after ten minutes.
3. Authenticated `POST /api/resources/{id}/complete` verifies and processes the actual
   object, then returns `{ id, url, thumbnailUrl, contentType, size, width, height }`.
   This operation is idempotent. A lost completion response can be retried.
4. Pass `backgroundResourceId` in `POST /api/candles` or `PATCH /api/candles/{id}`.

`url` and `thumbnailUrl` are relative to the **API origin**, not the Flutter origin.
The API serves immutable image bytes from the private bucket with long cache
headers. Clients do not need expiring signed download URLs. A CDN can cache these
public resource endpoints later. Completed resources are public, matching public
candle backgrounds; they are not intended for private user documents.

Omitting `backgroundResourceId` in PATCH preserves the background; explicit null
removes it. Only the candle author may change the candle. Only a resource owned by
the acting user and successfully completed can be attached. Candle responses,
including search, return `background` (null or the resource response).

Accepted inputs: JPEG, PNG and WebP, up to 20 MiB and 40 million pixels.
These are image processing bounds, not user quotas. The initial processor uses
Magick.NET, fixes orientation, strips metadata, emits a WebP background at most
2560 pixels per side and a thumbnail at most 320 pixels per side. It never upscales.
Only the first frame is used. HEIC, SVG, GIF and videos are not accepted.
Further image transforms belong in `ResourceImageProcessor`, not S3 storage.

## Resource lifecycle

A signed PUT URL is reusable until expiry. Uploads therefore go to `uploads/{id}`;
completion publishes separately to `resources/{id}/image.webp` and `thumbnail.webp`.
Reusing the upload URL cannot overwrite an already published background.

Every ten minutes the cleanup worker handles up to 100 old resources:
- uncompleted resources older than 24 hours are removed;
- completed but unreferenced resources are eligible 24 hours after completion;
- referenced resources stay; their staging uploads are removed after that window.

An old background detached from its last candle may be collected on the next sweep
if its completion was already more than 24 hours ago. Cleanup and attachment lock
the same resource row, and a restricting foreign key prevents dangling references.
Before deleting published files, cleanup commits ReadyAt = null so the resource
cannot be attached or served after a partial deletion. Deletion failures leave
the DB record for a later retry. Uploads/processing that
fail before completion also retain a record for cleanup.

No user quotas, request throttling or DoS protection are added. Expiry and cleanup
do not prevent someone from creating many resources within the retention window.
A signed PUT does not enforce the API's image-size bound at storage ingress; it is
checked when completing the resource. Later, signed POST policies, ingress limits
and user quotas can bound uploads earlier. Bucket lifecycle rules can additionally
expire abandoned staging objects (including late-finishing uploads), but cannot
determine whether PostgreSQL still references a resource.

## Moving to AWS S3

Copy objects retaining their keys, then change `Storage` endpoint(s), region,
credentials, bucket and `ForcePathStyle` (normally false on AWS). Leave endpoints
empty to use the AWS regional endpoint. Leave credentials empty to use the AWS SDK
credential chain, e.g. an IAM role. Provision the destination bucket and browser
CORS for PUT separately; SeaweedFS initializes these locally, AWS does not.
The application does not use SeaweedFS-specific object APIs.