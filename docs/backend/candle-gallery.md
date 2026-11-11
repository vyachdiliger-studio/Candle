# Candle gallery and API

The gallery is a session's open candles, not the user's archive. At startup it
loads every page of the user's burning candles, then resolves up to 30 locally
remembered recent IDs. An extinguished candle stays open for this session. A new
session filters it out unless explicitly opened again. Background/resume does
not reset the session. Recent IDs and last selection are stored per account;
they are not synchronized between devices.

The first gallery page is a local draft. Swipe or tap `+` to open it. Lighting
creates a candle, selects it in Mine, and clears the draft only after success.
Author ID determines Mine vs Recent and edit permission. Opening a map preview
or a shared link adds/selects the full candle; selecting a map marker alone does
not add history. Repeat visits do not reorder the currently open strip.

## Backend contract

`POST /candles/search` is public and does not mutate data:

```json
{
  "filter": { "authorId": 42, "status": "burning", "ids": [137610, 137611] },
  "sort": "createdAtDesc",
  "limit": 30,
  "cursor": null
}
```

All filter fields are optional and combined with AND. Omit `status` for all
states; supported values are `burning` and `extinguished`. Omit `authorId` for all
authors. The client supplies its numeric session user ID for Mine. Empty `ids`
means no matches; omitted `ids` means no ID restriction. Maximum 100 IDs and
`limit` from 1 to 100; default 30.

```json
{ "items": [], "nextCursor": null }
```

Sort order is `createdAt DESC, id DESC`. Pass the opaque `nextCursor` with the
same filters and sort to continue; null means finished. Changing page size is
allowed. Invalid, altered, or mismatched tokens return `400 invalid_cursor`.
Start from the beginning if the cursor is rejected. This is a live collection,
not a frozen snapshot: candles can stop matching `burning` between requests.
Data Protection keys must persist across backend instances/restarts if cursors
are expected to survive them; without retained keys clients restart pagination.

`GET /candles/{id}` and map tiles are public. All Candle responses include
`author: { id, username }`; the client tolerates missing authors for compatibility.
They also include `supportersCount` and `commentsCount` (live comments, replies
included; see `candle-comments.md`).
`POST /candles` requires login, supports multiple burning candles, and returns
201 with Location pointing to the new candle. PATCH remains owner-only.
`POST /candles/{id}/boost` requires login, permits any supporter, and atomically
adds taps; extinguished candles return 409 `candle_extinguished`.
`GET /candles/active` is retained only for older clients.

New users receive a neutral generated username. A migration fills missing
usernames and makes the database column required; existing names are preserved.
Profile changes reject blank names, require 3–48 ASCII letters/digits/underscores,
and return 409 `username_taken` for uniqueness conflicts.

## Navigation

New shared URLs: `/candles/{id}`. `/` restores gallery selection or opens the
empty draft. Old `/map?candleId={id}` and `/map/candle/{id}` URLs redirect to the
gallery. Internal map positioning uses `/map?focus={id}` to avoid that redirect.
The login/splash flow preserves the destination. Browsing a shared candle does
not require login; supporting or creating one does.

The future archive in the drawer can use the same cursor API without a status
filter and open a selection through `/candles/{id}`. It is not included here.

## Validation

Run `flutter test` and `flutter analyze` in the frontend. Generate sources with
`dart run build_runner build` when model/provider definitions change.

Review/apply the CandleGallery migration in the backend deployment before running this client against it.
