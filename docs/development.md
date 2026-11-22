# Development

## Environment

```bash
cp .env.example .env
```

The example values are for local development only. Host ports are configurable
(`HTTP_PORT`, `DEV_DB_PORT`, `DEV_STORAGE_PORT`); the port in `PUBLIC_URL` must
match `HTTP_PORT`.

## Running

```bash
make dev        # build and start everything, attached
make dev-logs
make dev-down
```

- App: http://localhost:8090
- Swagger: http://localhost:8090/api/swagger/index.html
- PostgreSQL: `localhost:5433`, database/user `candle`, password from `.env`
- S3 (SeaweedFS): `localhost:8333`

The API runs `dotnet watch` on the mounted `backend/` sources and rebuilds on save.
Migrations are applied on startup. The `web` service is a production-like build:
after Flutter changes run `docker compose -f compose.yaml -f compose.dev.yaml up -d --build web`.

### Flutter with hot reload

Flutter runs on the host (it needs a local Flutter SDK, Android/iOS tooling):

```bash
make app        # flutter run -d chrome against PUBLIC_URL from .env
cd frontend/app && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8090/api   # Android emulator
```

Generated code is not committed. After pulling or changing models:

```bash
cd frontend/app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### API from an IDE

Stop the `api` container (`docker compose -f compose.yaml -f compose.dev.yaml stop api`)
and run `backend/api` with the Development environment. `appsettings.Development.json`
points at the containers on their default ports.

## Code quality

```bash
make lint       # everything below
make format     # apply formatting (dotnet format + dart format)
```

- Backend: `dotnet build -warnaserror`, `dotnet format --verify-no-changes`
  (rules in `backend/.editorconfig`, migrations excluded).
- Frontend: `flutter analyze`, `dart format --set-exit-if-changed`, `flutter test`
  (rules in `frontend/app/analysis_options.yaml`).

Lint runs in containers: `.cache/` keeps the NuGet cache, the first frontend run
builds the Flutter SDK image (a few minutes). CI runs the same `make` targets.

## Database migrations

```bash
cd backend/api
dotnet ef migrations add <Name>
```

Never edit existing migrations. The API applies pending migrations on startup.

## Conventions

- Secrets only in `.env`; new settings get a non-secret default in `appsettings.json`
  and, if secret, a variable in `.env.example` mapped in `compose.yaml`.
- API changes stay backward-compatible with app versions already in the stores.
- User-visible app text goes through `frontend/app/lib/l10n/app_en.arb`, `app_ru.arb` and `app_uk.arb`.
- LF line endings everywhere (`.gitattributes`).
- Update `docs/` when documented behaviour changes.
