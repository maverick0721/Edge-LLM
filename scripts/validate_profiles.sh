#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SMOKE_SCRIPT="$ROOT_DIR/scripts/smoke_test.py"
SMOKE_RETRIES=${EDGE_LLM_SMOKE_RETRIES:-6}
SMOKE_RETRY_DELAY_SECONDS=${EDGE_LLM_SMOKE_RETRY_DELAY_SECONDS:-10}

if [ "$#" -gt 0 ]; then
  PROFILES="$*"
else
  PROFILES="lite standard high-quality"
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker CLI not found"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "docker daemon is not reachable"
  exit 1
fi

status=0
active_env_file=""

cleanup() {
  if [ -n "$active_env_file" ]; then
    docker compose --env-file "$active_env_file" down >/dev/null 2>&1 || true
    active_env_file=""
  fi
}

run_smoke_with_retries() {
  profile_name="$1"
  attempt=1

  while [ "$attempt" -le "$SMOKE_RETRIES" ]; do
    echo "[$profile_name] smoke attempt $attempt/$SMOKE_RETRIES"

    if python3 "$SMOKE_SCRIPT"; then
      return 0
    fi

    if [ "$attempt" -lt "$SMOKE_RETRIES" ]; then
      echo "[$profile_name] smoke not ready yet, waiting ${SMOKE_RETRY_DELAY_SECONDS}s before retry"
      sleep "$SMOKE_RETRY_DELAY_SECONDS"
    fi

    attempt=$((attempt + 1))
  done

  return 1
}

trap cleanup EXIT INT TERM

for profile in $PROFILES; do
  env_file="$ROOT_DIR/profiles/$profile.env"

  if [ ! -f "$env_file" ]; then
    echo "[$profile] missing env file: $env_file"
    status=1
    continue
  fi

  echo "[$profile] starting stack"
  active_env_file="$env_file"

  if ! docker compose --env-file "$env_file" up --build -d; then
    echo "[$profile] failed to start stack"
    status=1
    cleanup
    continue
  fi

  echo "[$profile] running smoke test"
  if ! run_smoke_with_retries "$profile"; then
    echo "[$profile] smoke test failed"
    status=1
  else
    echo "[$profile] smoke test passed"
  fi

  cleanup
done

if [ "$status" -eq 0 ]; then
  echo "all requested profile checks passed"
else
  echo "one or more profile checks failed"
fi

exit "$status"
