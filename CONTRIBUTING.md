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

<!-- TODO (maintainers): choose a license and set up the CLA bot before publishing. -->
By submitting a pull request you agree to the Contributor License Agreement.
