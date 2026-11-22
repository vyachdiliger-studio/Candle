# Candle Telegram bot

## Projects and responsibilities

`CandleBot` is a .NET class library in the backend solution. It owns Telegram
commands, keyboards, localized resources, profile setup and the `IBotPreferences`
contract. It has no EF dependency and does not reference `CandleBackend`.

`CandleBackend` hosts `/telegram/webhook`, verifies its secret header, and implements
`IBotPreferences` with the existing PostgreSQL database. No separate process,
container or bot database is required. The frontend is unchanged.

## Enable a new bot

1. Create a dedicated bot with @BotFather. Choose its public username.
2. In `.env` set `TELEGRAM_BOT_ENABLED=true`, `TELEGRAM_BOT_TOKEN` and
   `TELEGRAM_WEBHOOK_SECRET`. Compose derives `WebhookUrl` and `MiniAppUrl`
   from `PUBLIC_URL`. Never commit the token.
3. Expose the API webhook URL over HTTPS. The proxy must forward POST bodies and
   `X-Telegram-Bot-Api-Secret-Token` without redirecting to another host.
4. Start the backend. It applies the language migration and configures the new
   bot's name, descriptions and commands in every bot language (English as the default), launch menu and webhook.
   Failed setup retries after a minute without stopping the API.
5. In @BotFather configure the Main Mini App to use `MiniAppUrl`, upload
   `backend/bot/Assets/avatar.png`, and add real screenshots of the app to its profile.
6. Open the bot, send `/start`, choose each language, open the Mini App and check login.

While enabled, Mini App initData is checked with `TelegramBot:Token`, so launching
through the old bot is no longer supported. While disabled, authentication keeps
using the existing `Telegram:BotToken`. Native/browser Telegram OIDC still uses
`Telegram:ClientId`; moving that login to the new bot requires configuring its
client ID, origins and native callback URLs together. Do not blindly copy the bot ID
into existing OAuth settings.

No Telegram calls are made while Enabled is false. Starting an enabled bot configures
its public text and webhook. Profile photos and Main Mini App previews are managed
in BotFather; the SVG is an editable source for the provided PNG avatar.

## Conversations

- `/start`: welcome screen and launch button.
- `/help`: short instructions and a reminder that candles/messages are public.
- `/language` or `/settings`: English, Українська, Русский, ไทย, with the selected option marked.
- Other input: a short explanation and navigation buttons.

Callbacks edit the current message. Missing/non-editable messages fall back to a
new message. Commands and the launch menu are localized per private chat. Groups
and messages from bots are ignored. The webhook accepts only messages and callbacks;
Telegram delivery is serialized with maxConnections=1 for the initial deployment.
Language writes are idempotent. Telegram may redeliver an update after a failed
response, so a welcome message can occasionally repeat; this is not exactly-once delivery.

## Language and account integration

Explicit selection wins over Telegram's optional `language_code`. The bot speaks
English, Ukrainian, Russian and Thai (`BotLanguage.Supported`); a Telegram language
among them is used, all other/missing languages fall back to English. Text resources
live in `backend/bot/Localization/Messages.resx` (English) and `Messages.<lang>.resx`;
`BotLocalizationTests` checks that every language has every text and that profile
texts fit Telegram's limits (description 512, short description 120 characters).

`TelegramUserSettings` records explicit selection before the user has a Candle
account. It uses the numeric Telegram user ID, not username or chat title.
Changing the language also updates the linked, active Candle user, if one exists.
Telegram sign-in initializes `User.PreferredLanguage` only when it is still null.
For a linked user the account preference takes priority over the pre-login setting.
Deleted accounts are not updated. No accounts are linked automatically.

`GET /users/me` returns `preferredLanguage` for future frontend localization.
Launch links additionally include `lang=ru` or `lang=en` as an initial UI hint.
This parameter is not authentication and must not overwrite account preferences.
Old message links can contain an older hint; the profile remains authoritative.
The current Flutter app does not consume the preference yet and will not translate.

Telegram itself selects localized bot profile descriptions according to client
language; manual selection controls bot messages and per-chat commands/menu.

## Extending

Add translations to the resources, build keyboards in `BotKeyboards`, and route new
commands in `BotUpdateHandler`. Split larger features into separate handlers as
workflows grow. Keep persistence behind `IBotPreferences`; do not add DbContext to
CandleBot or make HTTP requests from the backend to itself.
