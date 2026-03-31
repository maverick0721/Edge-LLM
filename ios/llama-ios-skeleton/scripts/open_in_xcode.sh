#!/usr/bin/env bash
set -euo pipefail

# Opens the Swift package in Xcode. Run from ios/llama-ios-skeleton
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

cd "$HERE"
echo "Preparing SPM sources (may create symlink)..."
bash scripts/prepare_spm_sources.sh || true

echo "Opening package in Xcode..."
if command -v xed >/dev/null 2>&1; then
  xed .
else
  open Package.swift
fi
