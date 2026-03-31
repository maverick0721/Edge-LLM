#!/usr/bin/env bash
set -euo pipefail

# Ensure this script is run from the package root (ios/llama-ios-skeleton)
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

SRC="$HERE/third_party/llama.cpp"
DEST="$HERE/Framework/LLamaCpp/Source/llama_cpp"

if [ ! -d "$SRC" ]; then
  echo "Error: staged llama.cpp not found at $SRC"
  echo "Run: bash scripts/fetch_build_llama.sh"
  exit 1
fi

if [ -L "$DEST" ] || [ -d "$DEST" ]; then
  echo "Destination $DEST already exists; skipping copy."
  exit 0
fi

echo "Creating symlink from $DEST -> $SRC"
mkdir -p "$(dirname "$DEST")"
ln -s "$SRC" "$DEST"
echo "Symlink created. Open the package in Xcode (see scripts/open_in_xcode.sh)."
