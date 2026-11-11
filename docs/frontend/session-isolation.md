# Account session isolation

Recent candle IDs and the selected candle persist across application restarts while
an account remains signed in. Explicit logout removes all `candles.recent.*` and
`candles.selected.*` keys, including older account/guest entries. Other application
preferences remain intact. Profile data is now memory-only; logout also removes
the legacy `persist.user` cache.

A session epoch changes on logout and when a new login starts. Gallery, candle
controllers/drafts, map state, profile and boost queue observe it. Timers are
cancelled and asynchronous completions from disposed provider builds are ignored.
The authenticated HTTP client rejects responses/retries from an older epoch.
Token reads and writes are serialized; refresh results can only be saved for the
epoch that initiated them.

Logout immediately publishes guest state and queues credential removal. A new
login waits for local cleanup and identity-provider sign-out. Server revocation
uses captured outgoing credentials (including its bearer token), runs separately,
and never clears or saves local tokens after completion. Remote revocation failure
is logged; offline logout still clears local credentials.

Regression coverage: `test/features/auth/session_isolation_test.dart`, plus the
login/logout routing checks in `test/features/candle/candle_gallery_test.dart`.
