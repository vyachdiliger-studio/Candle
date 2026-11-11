# Telegram Mini App sign-in

The Mini App login screen offers Continue with Telegram when the Telegram SDK
provides nonempty initData. The SDK loads before Flutter routing so launch data
survives path URL updates. Outside Telegram the existing Google/password flows remain.
This implements Mini App authentication, not Telegram Login/OIDC for ordinary websites.

The frontend posts raw initData to POST /auth/telegram. The backend verifies the
HMAC with the bot token, rejects duplicate fields and launch data older than ten
minutes (30 seconds of future clock skew allowed), and resolves UserLogin by
Telegram's numeric user ID. It issues the existing access/refresh session.
No Telegram credentials or bot tokens should be logged.

Configure Telegram__BotToken in the backend's runtime environment (or the equivalent
Telegram:BotToken secret configuration). Never put it in Flutter or commit it.
If running through Compose, explicitly pass that environment variable to the backend
service; a host variable alone does not automatically enter the container.
Deploy the backend endpoint and frontend together. No database migration is required.
Configure the bot's Main Mini App or menu button in BotFather with the HTTPS frontend
URL. Keyboard-button launches may not supply usable user initData.

Login requires a tap; an existing Candle session is restored as before. Logout does
not silently log back in through Telegram. Reopen the Mini App for fresh launch data
if an initial login expires. Manual reload may retain the same expired launch data.

Google, Telegram, and password registrations are separate accounts unless credentials
were explicitly added to an existing user. Existing profile password setup works for
Telegram users too. Provider linking and merging already-created accounts are deferred:
never merge based on matching usernames, names, or unverified email. A future link flow
must require the existing session plus verified new-provider credentials and reject
identities already owned by another user. Merging their data needs separate rules.

Verification: test an initial Telegram login, repeat login (same Candle user), logout,
password setup on that user, invalid/expired launch data, and normal browser login.
Source: https://core.telegram.org/bots/webapps#validating-data-received-via-the-mini-app

## Native Android/iOS login

Android/iOS also show Continue with Telegram outside the Mini App. The published
`telegram_login` package opens native authentication and returns an ID token.
The frontend sends `{ "idToken": "..." }` to the existing `/auth/telegram` endpoint.
The backend must have `Telegram__ClientId` set to the same public BotFather Client ID.
Mini App initData login is unchanged; ordinary browser Telegram login is not added.
No automatic login or configuration requests run at app startup.

Register the native app in BotFather → Login Widget:
- Android: package `com.vyachdiliger.candle` and signing certificate SHA-256.
- iOS: bundle `com.example.candleFrontend` and Apple Team ID.

The public Client ID and Android App URL are set directly in
`lib/core/config/app_config.dart`. The Android callback host is set directly in
`android/app/src/main/AndroidManifest.xml` to `app2935833290-login.tg.dev`.
No Telegram Dart defines or environment variables are required for the frontend:

```sh
flutter run -d DEVICE_ID
```

If changing the Android App URL, update both AppConfig and the manifest host.
The SDK downloads from Maven Central; no GitHub credentials are needed.
For iOS set `telegramIosAppUrl` in AppConfig and the Xcode build setting
`TELEGRAM_LOGIN_HOST` (all configurations) to that URL's host. Associated Domains
are wired through Runner.entitlements. Register the fallback scheme
`com.example.candleFrontend://` with BotFather for older iOS auth sessions.
The package requires iOS 15+ and Android API 23+.

Without public BotFather values the button reports that login is not configured.
No bot token or client secret belongs in the frontend configuration. Test success,
cancellation/retry and return with and without Telegram installed on a real device.
Source: https://pub.dev/packages/telegram_login

## Web login

Ordinary browsers use the official Telegram Login JavaScript SDK loaded by
`web/index.html`. The Flutter button calls `Telegram.Login.auth` synchronously
from the click, requests `profile`, and sends the returned `id_token` to the
existing `/auth/telegram` endpoint. Mini Apps continue to use `initData`.

In BotFather → Login Widget → Allowed URLs, register each website origin,
including the origin used for development (scheme, hostname and port). Use a
fixed port with `flutter run -d chrome --web-port=8080` if testing localhost.
Do not serve `Cross-Origin-Opener-Policy: same-origin`; use
`same-origin-allow-popups` if a COOP header is needed.

Closing the popup cancels login. A missing SDK or a callback timeout restores
the button and displays an error. No backend redirect endpoint is needed.
