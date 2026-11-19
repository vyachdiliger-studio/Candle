# Candle skins

Status: **decided, not scheduled.** Discussed and decided on 16.11.2026 (see
[Decisions](#decisions)). This is the design for the issues below.

## Why

- **Work for artists.** A clear, visible contribution: your skin burns on the map
  for real people. Opens the project to non-developers.
- **Monetisation.** "Prettier candles" is already on the list of paid ideas: some
  skins free, some paid or seasonal (Christmas, Easter, memorial days).
- **Hard to clone.** Code can be copied; a community-made skin collection cannot.

## How it fits the current app

The candle icon is a Rive animation, `frontend/app/assets/animations/candle.riv`,
driven by two values: `progress` (how much burning time is left) and `isBurning`.

A **skin is a Rive file with the same contract**. The artist draws the candle any
way they like, but must expose those two values, so the app drives every skin the
same way.

That makes **#14 (move the candle icon to Rive Data Binding)** the foundation: the
contract (a View Model with `progress: number`, `isBurning: boolean`) has to be
fixed before artists start drawing.

## What is needed

**Skin specification for artists** (`docs/skins.md`, no code):

- canvas size and the anchor point on the map;
- required states: burning, about to go out, extinguished;
- the View Model contract and how `progress` should look from 1 to 0;
- file size budget; works on low-end phones and in the web build;
- what to submit: `.riv`, the `.rev` source, a static PNG, a name and credits.

**A static PNG per skin.** The server renders link previews
(`CandlePreviewRenderer`) and cannot play Rive. The PNG is also used in the skin
catalogue and as a fallback on weak devices.

**Backend:**

- `Candle.SkinId` (nullable; null = default skin);
- skin catalogue: id, name, author, free/paid, season or availability window,
  file versions;
- skin files served from our storage, not bundled in the app, so a new skin ships
  without a store release.

**App:**

- skin picker when lighting a candle (the skin cannot be changed later);
- "Light again" (#23) copies the skin together with the text, background and place;
- download and cache skin files; fall back to the default skin while loading or
  on error;
- map markers keep building synchronously from preloaded files (no flicker, same
  rule as #14).

**Rights and credits:**

- artists grant rights through the same CLA as code, so the CLA must cover
  graphics, not only source code;
- the author's name is shown in the catalogue and on the Contributors screen (#11).

## Decisions

Decided on 16.11.2026.

1. **Format: Rive first.** We start with two or three skins of our own in Rive,
   using the contract from #14. PNG / sprite-sheet skins are added later, only if
   artists without Rive skills show up.
2. **Paid skins: flag now, payments later.** The catalogue gets a free/paid flag
   and an availability window (seasonal skins) from the start, but every skin is
   free until payments exist. No purchase flow in this work.
3. **Skin is chosen only when lighting.** A burning candle keeps its skin: it
   looks the same to everyone who supported it, and link previews never go stale.
   To use another skin, light the candle again (#23).

## Issues to create

1. Skin specification `docs/skins.md` (non-code, label `design`).
2. Skin catalogue and `SkinId` on the backend.
3. Skin picker and loading in the app (depends on #14).
4. Two or three "Draw a candle skin" issues for artists (label `design`).
