#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
PROFILE=${1:-lite}
ENV_FILE="$ROOT_DIR/profiles/$PROFILE.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Unknown profile: $PROFILE"
  echo "Expected env file at: $ENV_FILE"
  exit 1
fi

shift || true

exec docker compose --env-file "$ENV_FILE" up --build "$@"
