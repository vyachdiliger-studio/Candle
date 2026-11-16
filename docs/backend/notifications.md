# Notifications and honorees

Status: **design, not implemented.** Agreed on 16.11.2026. This document is the
reference for the issues that implement it; change it in the same PR when the
design changes.

## What we are building

Two product features share one notification pipeline:

1. **Candle lifetime.** A candle burns 30 days; each supporter tap adds a second.
   - *Expiring soon*: 3 days before `ExtinguishedAt`, tell the author (and the
     candle's honorees, see below) and invite them to ask friends for support.
   - *Extinguished*: when the candle goes out, tell the author and offer
     "Light again". Lighting again creates a **new** candle with the same message
     and background; the old candle keeps its history, taps and supporters.
2. **Candles lit in someone's honour.** The author can mark a candle as lit for a
   person: an existing Candle user, or anyone identified by a Telegram username,
   phone number or email, registered or not. The candle **stays the author's**:
   only the author edits or deletes it. The honoree is told about it, sees it in
   "In my honour", can remove themselves from it and can block the author.

Planned next: a daily digest "N people supported your candle yesterday".

Rules for every notification:

- No messages at night (v1: local time estimated from the candle's longitude).
- Every kind can be turned off separately; every external message has an opt-out.
- At most one notification of a kind per candle per recipient.

## Pipeline

```text
 domain events                      producers                     outbox                 dispatcher           channels
 ─────────────                      ─────────                     ──────                 ──────────           ────────
 time passes ───────────────> CandleExpiryWorker ──┐
 honoree added / matched ───> HonoreeService ──────┼──> Notifications ──> NotificationDispatcher ──> InApp
 day ends ──────────────────> SupportDigestWorker ─┘    (+ Deliveries)    (every minute)           ├─> Telegram
                                                                                                    ├─> Email
                                                                                                    ├─> WhatsApp
                                                                                                    └─> Sms
```

- **Producers** only decide *what* to tell *whom* and insert rows. They never
  call a provider.
- **The outbox** (`Notifications`, `NotificationDeliveries`) makes delivery survive
  restarts and makes duplicates impossible (unique keys, `ON CONFLICT DO NOTHING`).
- **The dispatcher** picks channels, checks preferences, quiet hours and limits at
  send time, renders the text and calls the channel. Retries with backoff.
- **Channels** are plug-ins behind one interface. A channel without a configured
  provider is registered as disabled; nothing else in the pipeline changes when a
  provider is added later.

All workers are `BackgroundService`s in `backend/api`, modelled on
`BackgroundJobs/ResourceCleanupWorker.cs`: a loop with a fixed interval, one
scoped `AppDbContext` per iteration, cancellation-aware.

## Data model

```text
CandleHonorees                      one row per person a candle is lit for
  Id, CandleId
  Kind               User | Email | Phone | TelegramUsername | InviteLink
  DisplayName        what the author typed ("Mom", "Andrii"), optional, max 100
  IdentifierHash     HMAC-SHA256(normalised contact, Notifications:ContactHashKey); null for User/InviteLink
  EncryptedAddress   contact in clear, encrypted with Data Protection; erased after delivery or TTL
  InviteTokenHash    for InviteLink (and every external message link)
  HonoreeUserId      set when matched to a Candle account
  CreatedAt, ClaimedAt, RemovedAt
  UNIQUE (CandleId, Kind, IdentifierHash)

Notifications                       what to tell whom, once
  Id, Kind           CandleExpiringSoon | CandleExtinguished | LitForYou | SupportDigest
  CandleId
  RecipientUserId    registered recipient …
  HonoreeId          … or an unregistered honoree (exactly one of the two is set)
  DedupKey           e.g. "expiring:{candleId}", "digest:{yyyy-MM-dd}"
  Payload            jsonb: values for the template (author name, counts)
  CreatedAt, ReadAt  ReadAt drives the in-app badge
  UNIQUE (Kind, RecipientUserId, HonoreeId, DedupKey)

NotificationDeliveries              one row per channel attempt
  Id, NotificationId, Channel       InApp | Telegram | Email | WhatsApp | Sms
  Status             Pending | Sent | Failed | Skipped | Expired
  Attempts, NextAttemptAt, SentAt, ProviderMessageId, LastError

NotificationPreferences             absent row = enabled
  UserId, Kind, Enabled

ContactSuppressions                 "never contact me", applies to every author
  IdentifierHash, CreatedAt

UserLogins (Telegram)               + TelegramWritable bool
Candles                             + index on ExtinguishedAt
```

Notes:

- The model allows several honorees per candle; the UI limit is a setting
  (`Notifications:MaxHonoreesPerCandle`).
- `DisplayName` is the only honoree field the API ever returns, and only to the
  author. Contacts are never returned, not even to the author.
- `ContactHashKey` is a secret in `.env`. Without it the hashes cannot be matched;
  rotating it orphans unmatched honorees, so do not rotate it casually.

## Normalising and matching contacts

| Kind | Normalised form | Verified source for matching |
| --- | --- | --- |
| Email | trimmed, lower-case | Google login (`email_verified`) |
| Phone | E.164 (`libphonenumber-csharp`) | Telegram contact shared in the Mini App or bot; later SMS code |
| TelegramUsername | without `@`, lower-case | Telegram login or bot `/start` (`from.username`) |

`HonoreeMatcher.Match(userId, identifiers)` runs after login, registration, bot
`/start` and a shared contact. It hashes the user's identifiers, sets
`HonoreeUserId` on unclaimed rows and enqueues `LitForYou` for each new match.

- Email and phone matches are claimed automatically (both are verified).
- Telegram usernames can change hands, so a username match is shown as
  "Maybe this is for you" until the user confirms.
- An invite link is claimed by whoever logs in through it.

## Channels

```csharp
public interface INotificationChannel
{
    NotificationChannel Channel { get; }
    bool IsEnabled { get; }   // provider configured
    Task<DeliveryResult> Send(DeliveryRequest request, CancellationToken cancellationToken);
}
```

`DeliveryResult` is `Sent(providerMessageId)`, `RetryLater(reason)` or
`Rejected(reason, disableAddress)`. `disableAddress` covers "bot blocked by user"
(Telegram 403 sets `TelegramWritable = false`) and hard email bounces (adds the hash
to `ContactSuppressions`).

Which channels the dispatcher uses:

| Recipient | Channels, in order |
| --- | --- |
| Registered user | **InApp** always; **Telegram** if `TelegramWritable` |
| Honoree by email, not registered | **Email** |
| Honoree by phone, not registered | **WhatsApp**, falling back to **Sms** if WhatsApp is disabled or rejects |
| Honoree by Telegram username, not registered | none: we cannot write first; delivered on their `/start` or login |
| Invite link | none: the author shares the link |

`TelegramWritable` becomes true on bot `/start` or when the Mini App's
`requestWriteAccess` is granted.

Providers that exist today: InApp, Telegram (`backend/bot`). Email, WhatsApp and
SMS are registered disabled. A delivery to a disabled channel stays `Pending` for
`Notifications:PendingTtl` (7 days), then becomes `Expired` and the honoree's
`EncryptedAddress` is erased. So a provider added within a week still delivers the
backlog, and contacts are not kept forever.

## Producers

- **CandleExpiryWorker** (every 5 min): candles with `ExtinguishedAt` in
  `(now + 72h - 10 min, now + 72h]` → `CandleExpiringSoon` for the author and
  claimed honorees; candles extinguished in the last 10 minutes →
  `CandleExtinguished` for the author. The overlap with the interval is harmless
  thanks to the unique key.
- **HonoreeService**: on candle create/edit with honorees → `LitForYou` per honoree
  (registered or not); on match → `LitForYou` for the newly matched user.
- **SupportDigestWorker** (hourly): for users whose local morning has started and
  who got new supports yesterday → `SupportDigest`.

## Dispatcher checks at send time

1. The candle still exists, and for `CandleExpiringSoon` it is still within 3 days
   of going out (taps may have moved `ExtinguishedAt`).
2. The kind is enabled in `NotificationPreferences`.
3. The honoree has not removed themselves; the recipient has not blocked the author.
4. The contact hash is not in `ContactSuppressions`.
5. Quiet hours (22:00–09:00 local): postpone `NextAttemptAt`, do not drop.
6. Rate limits (below).

Retries: exponential backoff from 1 minute, at most 5 attempts, then `Failed`.

## Abuse and privacy limits

- An author can add at most `MaxExternalHonoreesPerDay` (default 10) contacts per day.
- One external message per contact per author per 7 days, however many candles.
- Every external message names the author, links the candle and has two links:
  "Not for me" (removes the honoree) and "Never contact me" (suppression list).
  Links carry a random token; only its hash is stored.
- Blocking the author hides their candles from "In my honour" and stops all
  notifications from them.
- Hashes, not contacts, are what we keep; the clear address lives only until
  delivered or expired. Review this section with someone who knows GDPR before
  enabling Email, WhatsApp or SMS.

## Texts

Templates live with the bot texts (`backend/bot/Localization`, `.resx`), one per
kind and channel family (short for Telegram/SMS/WhatsApp, rich for email and
in-app). Language: the recipient's `PreferredLanguage`; for unregistered honorees,
the author's.

## Configuration

```text
Notifications__ContactHashKey       secret, required once honorees ship
Notifications__PendingTtl           default 7.00:00:00
Notifications__MaxHonoreesPerCandle default 1
Notifications__MaxExternalHonoreesPerDay default 10
Email__*, WhatsApp__*, Sms__*       added with each provider
```

## Rollout

Each step is one small PR.

1. Outbox tables, preferences, `TelegramWritable`, `ExtinguishedAt` index.
2. Dispatcher with InApp and Telegram channels, retries, quiet hours.
3. `CandleExpiryWorker` and the expiry texts; "Light again" in the app.
4. In-app notification list, badge, notification settings screen.
5. Mini App `requestWriteAccess`; bot `/start` sets `TelegramWritable`.
6. Honorees v1 (variant A): `DisplayName` and invite link; "In my honour" screen.
7. Bot inline mode (variant B): send your candle to any Telegram chat.
8. Honorees by contact: hashing, matching, `LitForYou`, "Not for me", suppressions.
9. Channel providers, one PR each: Email, WhatsApp, SMS.
10. `SupportDigestWorker`.
11. Later: push (FCM/APNs) as another channel; user time zones.
