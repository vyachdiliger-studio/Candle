#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Keep version metadata inside the executable, in sync with Flutter's manifest.
# Set BUILD_NAME/BUILD_NUMBER to override pubspec without editing source files.
package_version=$(awk '$1 == "version:" {gsub(/[\047\042]/, "", $2); print $2; exit}' pubspec.yaml)
version=${BUILD_NAME:-${package_version%%+*}}
number=${BUILD_NUMBER:-${package_version#*+}}
if [[ "$number" == "$package_version" ]]; then number=1; fi
if [[ -z "$version" || ! "$number" =~ ^[0-9]+$ ]]; then
  echo "A version and a numeric BUILD_NUMBER are required." >&2
  exit 1
fi

# Version overrides belong in the environment so metadata cannot disagree.
for arg in "$@"; do
  case "$arg" in
    --build-name*|--build-number*|--dart-define*|--config-only)
      echo "Use BUILD_NAME, BUILD_NUMBER and BUILD_COMMIT; pass URL overrides through API_BASE_URL/SHARE_BASE_URL." >&2
      exit 1 ;;
  esac
done

defines=(
  "--dart-define=APP_VERSION=$version"
  "--dart-define=APP_BUILD_NUMBER=$number"
  "--dart-define=BUILD_COMMIT=${BUILD_COMMIT:-}"
)
if [[ -n "${API_BASE_URL:-}" ]]; then defines+=("--dart-define=API_BASE_URL=$API_BASE_URL"); fi
if [[ -n "${SHARE_BASE_URL:-}" ]]; then defines+=("--dart-define=SHARE_BASE_URL=$SHARE_BASE_URL"); fi

flutter build web --release "--build-name=$version" "--build-number=$number" "${defines[@]}" "$@"
