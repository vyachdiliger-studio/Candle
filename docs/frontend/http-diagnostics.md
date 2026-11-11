# HTTP diagnostics

Flutter logs are enabled by default in debug builds. They appear in Android
Studio's Run/Logcat output or the browser console. Filter by `[HTTP`.
To enable them explicitly (including a release/web build):

```sh
flutter run --dart-define=HTTP_LOGGING=true
flutter build web --dart-define=HTTP_LOGGING=true
```

Each wire attempt has an `X-Request-ID`, including attempts retried after token
refresh. The authenticated Dio logger runs after attaching authorization and
before refresh handles a 401, so the failed attempt remains visible. The auth
Dio logs Google login, token refresh and logout too.

```text
[HTTP app-...] --> POST https://dell.tail5644bf.ts.net/candles/search
[HTTP app-...] request headers: ...
[HTTP app-...] request body: {"filter":...,"limit":30}
[HTTP app-...] <-- 200 120ms
[HTTP app-...] response body: {"items":...,"nextCursor":...}
```

A connection/TLS/timeout failure has `<!!`, a Dio error type, elapsed time, and
`status=NO_HTTP_RESPONSE`. An HTTP error includes its status and response body.
Logs indicate the client attempt, not proof that the server received it.

Backend middleware is enabled by default in Development, or explicitly with
`HttpDiagnostics__Enabled=true`. It logs incoming requests before auth, and
status, elapsed time and response body when handling completes. Exceptions log
their type; details may contain secrets and are omitted. Search for the same
request ID to correlate the two sides. Server-generated IDs are returned when
the client has not supplied a valid ID.

For the current Docker deployment:

```sh
docker compose -f compose.yaml -f compose.prod.yaml logs -f --tail=100 api
```

Only HTTP requests reaching ASP.NET Core appear here. DNS/TCP/TLS failures
before the backend do not generate an incoming request log.

Authorization, cookies and credential fields (including access, refresh,
idToken, password and API keys) are redacted in headers, query strings and JSON.
JSON content such as candle messages remains visible. Diagnostic output is
bounded at 16 KiB per body; oversized server bodies are omitted because partial
JSON cannot be reliably redacted. Non-JSON/binary content is summarized without
printing raw bytes. Response streaming is forwarded without buffering the
entire response. Client lines are split to fit Android logcat.

Tests: `flutter test test/core/network/http_diagnostics_test.dart` and
`dotnet run --project CandleBackend.Checks`.
