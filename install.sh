#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
PROFILE=${1:-${EDGE_LLM_INSTALL_PROFILE:-lite}}

# Use unified requirements.txt for all profiles (consolidated dependencies)
REQUIREMENTS_FILE="requirements.txt"

PYTHON_BIN=${PYTHON_BIN:-python3}
VENV_DIR="$ROOT_DIR/.venv"
VENV_PYTHON="$VENV_DIR/bin/python"

echo "Setting up Edge-LLM ($PROFILE profile)..."

if [ ! -d "$VENV_DIR" ]; then
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

"$VENV_PYTHON" -m pip install --upgrade pip
"$VENV_PYTHON" -m pip install -r "$ROOT_DIR/$REQUIREMENTS_FILE"

mkdir -p "$ROOT_DIR/models"

(
  cd "$ROOT_DIR/ui/chat-app"
  npm install
  npm run build
)

echo ""
echo "Setup complete."
echo "Installed Python tier: $PROFILE"
echo "Built production UI into: ui/chat-app/dist"
echo "Place your GGUF model in: ./models"
echo ""
echo "Recommended start command:"
echo "docker compose --env-file profiles/$PROFILE.env up --build"
