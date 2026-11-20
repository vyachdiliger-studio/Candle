# Flutter SDK pinned to the version the app is developed with.
FROM debian:bookworm-slim AS sdk

ARG FLUTTER_VERSION=3.47.2

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git /opt/flutter \
    && git config --system --add safe.directory /opt/flutter

ENV PATH="/opt/flutter/bin/cache/dart-sdk/bin:/opt/flutter/bin:${PATH}"
ENV FLUTTER_SUPPRESS_ANALYTICS=true

RUN flutter config --no-analytics --no-cli-animations --enable-web \
    && flutter precache --web \
    && flutter --version


FROM sdk AS base

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter gen-l10n \
    && dart run build_runner build --delete-conflicting-outputs


FROM base AS lint

CMD ["sh", "-c", "flutter analyze && dart format --output=none --set-exit-if-changed $(find lib test -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' ! -path 'lib/l10n/generated/*') && flutter test"]


FROM base AS build

# Empty values keep the production defaults from lib/core/config/app_config.dart.
ARG API_BASE_URL=""
ARG SHARE_BASE_URL=""
ARG BUILD_COMMIT=""
ARG BUILD_NUMBER=""

RUN BUILD_COMMIT="${BUILD_COMMIT}" BUILD_NUMBER="${BUILD_NUMBER}" \
    API_BASE_URL="${API_BASE_URL}" SHARE_BASE_URL="${SHARE_BASE_URL}" \
    bash scripts/build_web.sh --base-href /


# Static file server for the web build; the edge proxy (deploy/Caddyfile) sits in front.
FROM caddy:2.11-alpine AS prod

COPY docker/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/build/web /srv

EXPOSE 80
