# Candle skins

Status: **idea, not scheduled.** Discussed on 16.11.2026. Nothing here is decided
until the open questions below are answered; then this becomes the design for the
issues.

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

- skin picker when lighting a candle;
- download and cache skin files; fall back to the default skin while loading or
  on error;
- map markers keep building synchronously from preloaded files (no flicker, same
  rule as #14).

**Rights and credits:**

- artists grant rights through the same CLA as code, so the CLA must cover
  graphics, not only source code;
- the author's name is shown in the catalogue and on the Contributors screen (#11).

## Open questions

1. **Format for artists.** Rive only (live animation, needs Rive skills), or also
   PNG / sprite sheets (anyone can draw, poorer animation)? Proposal: start with Rive
   and two or three skins of our own; add PNG skins later if artists without Rive
   show up.
2. **Paid skins.** Add a free/paid flag to the catalogue now (without payments), or
   keep every skin free for now?
3. **Changing the skin of a burning candle**, or only when lighting it?

## Possible issues, once decided

1. Skin specification `docs/skins.md` (non-code, label `design`).
2. Skin catalogue and `SkinId` on the backend.
3. Skin picker and loading in the app (depends on #14).
4. Two or three "Draw a candle skin" issues for artists (label `design`).
