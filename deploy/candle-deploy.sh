#!/usr/bin/env bash
# Forced command for the CI deploy key (see docs/deployment.md, "Automatic deploys").
# Installed on the server as /usr/local/bin/candle-deploy. The key can run nothing
# else: SSH passes the requested commit as SSH_ORIGINAL_COMMAND.
set -euo pipefail

REPO=/srv/candle/Candle
SHA="${SSH_ORIGINAL_COMMAND:-${1:-}}"

if [[ ! "$SHA" =~ ^[0-9a-f]{40}$ ]]; then
  echo "usage: candle-deploy <full commit sha>" >&2
  exit 2
fi

exec 9>/var/lock/candle-deploy.lock
flock 9

cd "$REPO"
git fetch --quiet origin master
if ! git merge-base --is-ancestor "$SHA" origin/master; then
  echo "refusing: $SHA is not on origin/master" >&2
  exit 3
fi
# Deploy only forward: an older commit arriving late must not roll the server back.
if ! git merge-base --is-ancestor HEAD "$SHA"; then
  echo "skipping: the server already runs a newer commit ($(git rev-parse --short HEAD))"
  exit 0
fi
git merge --quiet --ff-only "$SHA"

# The shell environment takes precedence over .env, so this pins both images to the commit.
export IMAGE_TAG="$SHA"
PROD=(docker compose -f compose.yaml -f compose.prod.yaml)
"${PROD[@]}" pull --quiet
"${PROD[@]}" up -d --no-build --remove-orphans

port=$(grep -E '^HTTP_PORT=' .env | cut -d= -f2)
for _ in $(seq 1 30); do
  if curl -fsS -o /dev/null "http://127.0.0.1:${port:-8090}/api/candles/search" \
      -H 'Content-Type: application/json' -d '{"limit":1}' \
    && curl -fsS -o /dev/null "http://127.0.0.1:${port:-8090}/"; then
    docker image prune -f >/dev/null
    echo "deployed $SHA"
    exit 0
  fi
  sleep 4
done
echo "deployed $SHA, but the smoke check failed" >&2
"${PROD[@]}" ps >&2
exit 1
