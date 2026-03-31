#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SRC="$HERE/build_xcframework/LLamaCpp.xcframework"
DEST="$HERE/LLamaCppBinaryPackage/LLamaCpp.xcframework"

if [ ! -d "$SRC" ]; then
  echo "Error: $SRC not found. Build the XCFramework first with: bash scripts/create_xcframework.sh"
  exit 1
fi

echo "Copying $SRC -> $DEST"
rm -rf "$DEST"
cp -a "$SRC" "$DEST"
echo "Done. Now add the local package: File -> Add Packages... -> Add Local... -> $HERE/LLamaCppBinaryPackage"
