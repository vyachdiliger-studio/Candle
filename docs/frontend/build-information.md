# Build information and release notes

Settings → About Candle shows the installed version and build number from
`package_info_plus` on native platforms, or compile-time metadata on web, plus
the source revision when the artifact supplies one.
It is available without signing in, through the existing Settings entry on the
login screen. Copy build information includes the full revision for bug reports;
the dialog displays its first seven characters. Without revision metadata, it
explicitly says the source revision was not supplied. No latest-release lookup
or network request is made.

When Settings is opened directly by URL, its back button goes to the application
root (login for guests). When pushed from another screen, it returns to that
screen. The shared page shell honors the active nested route's pop/exit guards.

The changelog is a curated list of changes and manual test scenarios bundled with
the application. Update the `release*Title` / `release*Body` entries in both
`frontend/app/lib/l10n/app_en.arb` and `app_ru.arb` when preparing a release. Add or
remove corresponding entries in `app_info_tile.dart`. These notes describe the
frontend artifact, not the current backend deployment. Do not fetch notes from
`master`: an older installed client must keep its own notes.

## Build metadata

The web image accepts optional `BUILD_COMMIT` and `BUILD_NUMBER` build arguments.
GitHub Actions supplies the checked-out commit SHA and workflow run number. The
SHA distinguishes rebuilds/source versions even when `pubspec.yaml` still has
the same marketing version. An ordinary local build uses package metadata and
does not invent a source revision.

For a manually built web or Android release:

```bash
cd frontend/app
BUILD_NUMBER=42 BUILD_COMMIT="$(git rev-parse HEAD)" bash scripts/build_web.sh
# Use the next unused Play versionCode, not the example web number:
flutter build appbundle --release --build-number=5 \
  --dart-define=BUILD_COMMIT="$(git rev-parse HEAD)"
```

Use the actual checked-out commit; do not label dirty sources as a clean release.
Android's version/build come from the signed artifact, including any
`--build-name` / `--build-number` overrides. The web wrapper reads the version from
`pubspec.yaml` (or `BUILD_NAME` / `BUILD_NUMBER` overrides) and supplies the same
values to Flutter and to `APP_VERSION` / `APP_BUILD_NUMBER` compile-time defines.
An old JavaScript bundle therefore keeps its own version, even after a newer
`version.json` is deployed. Direct `flutter build web` without these defines
reports unavailable version/build fields instead of guessing from the server.
URL overrides can be supplied through `API_BASE_URL` and `SHARE_BASE_URL`.
Keep the web entrypoint and JavaScript in one release when deploying, and reload
an old browser tab before comparing builds.

Regression tests: `frontend/app/test/features/settings/app_info_test.dart` covers
runtime metadata, copying the full commit, missing metadata and retry, offline
notes, and narrow Russian layouts with enlarged text.
