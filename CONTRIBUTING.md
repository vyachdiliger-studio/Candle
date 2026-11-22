# Contributing to Candle

Candle is a live app: merged work reaches real users.

## How it works

1. **Pick an issue.** Comment "I'll take this"; a maintainer assigns it.
2. **Deadline: 7 days.** No PR or update within 7 days: the issue goes back to the pool.
3. **One issue, one PR.** Small, focused changes, no unrelated refactoring.
4. **CI must be green** (`make lint`) before review.
5. **Review.** Two maintainers review every PR.

New ideas: open an issue first. The roadmap is owned by the maintainers.

## Rules

- Found a vulnerability? Do not open a public issue: report it privately as
  described in [`SECURITY.md`](SECURITY.md).
- Never commit secrets, keystores or service account files. Configuration goes
  through `.env` (documented in `.env.example`).
- Database changes: add an EF migration with the model change; never edit existing migrations.
- Keep API changes backward-compatible: store apps cannot update instantly.
- User-visible text in English and Russian (`frontend/app/lib/l10n/*.arb`).
- Add or update tests for logic you change.
- Update `docs/` when you change documented behaviour.
- AI-assisted code is welcome; you are responsible for running and testing it.

## Commit messages

Conventional style with a scope: `feat(candles): add supporter count`,
`fix(auth): reject expired refresh tokens`, `chore(deploy): …`.

## Licensing

- Code is licensed under [AGPL-3.0](LICENSE). Your contributions are published
  under the same licence.
- Before your first pull request is merged, sign the
  [Contributor License Agreement](CLA.md): the CLA bot posts instructions on the
  pull request, you sign once by replying with a comment. You keep the copyright
  in your work; the CLA lets the maintainer relicense it, for example to ship it
  in the store apps. It covers code and content alike: graphics, animations,
  translations, audio.
- Images, animations, icons and store graphics are not under AGPL:
  see [`LICENSE-ASSETS.md`](LICENSE-ASSETS.md). The name and logo:
  [`TRADEMARKS.md`](TRADEMARKS.md).
- Third-party code or assets: name the source and its licence in the pull request.
