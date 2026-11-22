# Notes for AI coding agents

## What this is

Monorepo of Candle: virtual candles of remembrance, placed on a map, kept burning
by other users' taps. `backend/api` is the ASP.NET Core (.NET 10) API, `backend/bot`
the Telegram bot library, `frontend/app` the Flutter app (Android, iOS, web).
Architecture: `docs/architecture.md`. Workflow: `docs/development.md`.

## Commands

- Run everything: `cp .env.example .env && make dev` (http://localhost:8090)
- Verify before finishing: `make lint` must pass (backend build with warnings as
  errors + `dotnet test` + `dotnet format`; `flutter analyze` + `dart format` + `flutter test`).
- Apply formatting: `make format`.

## Backend (`backend/api`, `backend/bot`)

- `Controllers/`: thin HTTP layer, validates input, returns error codes such as
  `BadRequest("invalid_cursor")`. `Services/`: auth, sessions, JWT, Telegram checks,
  image processing. `Mappers/` + AutoMapper: DTO mapping.
- `Data/AppDbContext.cs`: EF Core + NetTopologySuite. Schema change = new migration
  in `Migrations/`; never edit old ones.
- `Storage/`: S3 abstraction. Store object keys in the DB, never URLs.
- All routes live under `/api` except public pages at `/candles/{id}`.

## Frontend (`frontend/app`)

- Feature-first: `lib/features/<feature>/{domain,data,application,presentation}`.
  `domain` has no Flutter/dio; `data` implements repositories with dio;
  `application` holds Riverpod notifiers; `presentation` uses hooks.
- Shared infrastructure in `lib/core`, helpers in `lib/common`, routing in `lib/app/router.dart`.
- Generated files (`*.g.dart`, `*.freezed.dart`, `lib/l10n/generated/`) are not committed.
- Every user-visible string goes into `lib/l10n/app_en.arb`, `app_ru.arb`, `app_uk.arb` and
  `app_th.arb` (a test fails if the Ukrainian or Thai file misses a key).
- Double quotes; URLs and IDs only in `lib/core/config/app_config.dart`.

## Rules

- No secrets in code, `appsettings*.json` or compose files: only `.env`
  (document new variables in `.env.example` and map them in `compose.yaml`).
- API changes must stay backward-compatible with app versions already in the stores.
- Read the relevant file in `docs/backend` or `docs/frontend` before changing that
  behaviour, and update it afterwards.
- No sweeping refactors or reformatting of unrelated code.
