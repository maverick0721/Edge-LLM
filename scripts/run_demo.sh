#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SMOKE_SCRIPT="$ROOT_DIR/scripts/smoke_test.py"
PREFLIGHT_SCRIPT="$ROOT_DIR/scripts/preflight.py"

PROFILE=${EDGE_LLM_PROFILE:-lite}
MODE="up"
RUN_PREFLIGHT=1
RUN_SMOKE=1
FOLLOW_LOGS=0
SMOKE_RETRIES=${EDGE_LLM_SMOKE_RETRIES:-6}
SMOKE_RETRY_DELAY_SECONDS=${EDGE_LLM_SMOKE_RETRY_DELAY_SECONDS:-10}

usage() {
  cat <<EOF
Usage:
  ./scripts/run_demo.sh [--profile <lite|standard|high-quality>] [--follow] [--no-preflight] [--no-smoke]
  ./scripts/run_demo.sh --down [--profile <lite|standard|high-quality>]

Examples:
  ./scripts/run_demo.sh
  ./scripts/run_demo.sh --profile standard
  ./scripts/run_demo.sh --profile high-quality --follow
  ./scripts/run_demo.sh --down
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile)
      if [ "$#" -lt 2 ]; then
        echo "--profile requires a value"
        exit 1
      fi
      PROFILE="$2"
      shift 2
      ;;
    --down)
      MODE="down"
      shift
      ;;
    --follow)
      FOLLOW_LOGS=1
      shift
      ;;
    --no-preflight)
      RUN_PREFLIGHT=0
      shift
      ;;
    --no-smoke)
      RUN_SMOKE=0
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

ENV_FILE="$ROOT_DIR/profiles/$PROFILE.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Unknown profile: $PROFILE"
  echo "Expected env file at: $ENV_FILE"
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker CLI not found"
  exit 1
fi

if [ "$MODE" = "down" ]; then
  echo "Stopping profile: $PROFILE"
  exec docker compose --env-file "$ENV_FILE" down
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "docker daemon is not reachable"
  exit 1
fi

if [ "$RUN_PREFLIGHT" -eq 1 ]; then
  echo "Running preflight checks..."
  python3 "$PREFLIGHT_SCRIPT"
fi

echo "Starting Edge-LLM with profile: $PROFILE"
docker compose --env-file "$ENV_FILE" up --build -d

if [ "$RUN_SMOKE" -eq 1 ]; then
  echo "Running smoke test..."
  attempt=1
  smoke_ok=0

  while [ "$attempt" -le "$SMOKE_RETRIES" ]; do
    echo "smoke attempt $attempt/$SMOKE_RETRIES"
    if python3 "$SMOKE_SCRIPT"; then
      smoke_ok=1
      break
    fi

    if [ "$attempt" -lt "$SMOKE_RETRIES" ]; then
      echo "stack not ready yet, waiting ${SMOKE_RETRY_DELAY_SECONDS}s..."
      sleep "$SMOKE_RETRY_DELAY_SECONDS"
    fi
    attempt=$((attempt + 1))
  done

  if [ "$smoke_ok" -ne 1 ]; then
    echo "Smoke test failed after $SMOKE_RETRIES attempts."
    echo "Inspect logs with:"
    echo "  docker compose --env-file \"$ENV_FILE\" logs --tail=200 app llama"
    exit 1
  fi
fi

echo ""
echo "Edge-LLM is up."
echo "Open: http://localhost:8000"
echo "Active profile: $PROFILE"
echo ""
echo "Useful commands:"
echo "  docker compose --env-file \"$ENV_FILE\" logs -f app llama"
echo "  ./scripts/run_demo.sh --down --profile $PROFILE"

if [ "$FOLLOW_LOGS" -eq 1 ]; then
  exec docker compose --env-file "$ENV_FILE" logs -f app llama
fi
