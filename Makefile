-include .env

DEV = docker compose -f compose.yaml -f compose.dev.yaml
PROD = docker compose -f compose.yaml -f compose.prod.yaml

# Tooling runs in containers, so only Docker is needed on the machine.
DOTNET_SDK = mcr.microsoft.com/dotnet/sdk:10.0.402
DOTNET = docker run --rm -u "$$(id -u):$$(id -g)" -e HOME=/tmp -e DOTNET_CLI_TELEMETRY_OPTOUT=1 \
	-e DOTNET_NOLOGO=1 -e NUGET_PACKAGES=/repo/.cache/nuget -v "$(CURDIR)":/repo -w /repo $(DOTNET_SDK)
FLUTTER_SDK = candle-flutter-sdk
DART = docker run --rm -u "$$(id -u):$$(id -g)" -e HOME=/tmp -v "$(CURDIR)/frontend/app":/app -w /app $(FLUTTER_SDK) dart
DART_SOURCES = $$(cd frontend/app && find lib test -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' ! -path 'lib/l10n/generated/*')

.PHONY: dev dev-down dev-logs prod prod-build prod-down prod-logs deploy lint lint-backend lint-frontend format \
	format-backend format-frontend flutter-sdk app

dev:
	$(DEV) up --build

dev-down:
	$(DEV) down

dev-logs:
	$(DEV) logs -f

# Run the images built by CI (pulls the current IMAGE_TAG).
prod:
	$(PROD) pull --quiet
	$(PROD) up -d --no-build --remove-orphans

# Fallback: build the production images on this machine instead of pulling them.
prod-build:
	$(PROD) up -d --build --remove-orphans

prod-down:
	$(PROD) down

prod-logs:
	$(PROD) logs -f

# On the server: latest compose/Caddy config from git + latest images from GHCR.
deploy:
	git pull --ff-only
	$(MAKE) prod
	docker image prune -f

lint: lint-backend lint-frontend

lint-backend:
	mkdir -p .cache/nuget
	$(DOTNET) sh -c "dotnet build Candle.slnx -warnaserror && dotnet test Candle.slnx --no-build && dotnet format Candle.slnx --verify-no-changes"

# Analyzer + formatting + tests, on a clean copy of the sources inside the image.
lint-frontend:
	docker build -q --target lint -t candle-app-lint frontend/app
	docker run --rm candle-app-lint

format: format-backend format-frontend

format-backend:
	mkdir -p .cache/nuget
	$(DOTNET) dotnet format Candle.slnx

format-frontend: flutter-sdk
	$(DART) format $(DART_SOURCES)

flutter-sdk:
	docker build -q --target sdk -t $(FLUTTER_SDK) frontend/app

# Flutter with hot reload runs on the host (needs a local Flutter SDK) against `make dev`.
app:
	cd frontend/app && flutter run -d chrome --dart-define=API_BASE_URL=$(PUBLIC_URL)/api \
		--dart-define=SHARE_BASE_URL=$(PUBLIC_URL)
