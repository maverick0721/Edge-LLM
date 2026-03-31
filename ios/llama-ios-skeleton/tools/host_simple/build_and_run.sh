#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$HERE/build"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake ..
cmake --build . --config Release --target local_llama_simple -j$(sysctl -n hw.ncpu)

echo "Build complete. To run:" 
echo "  ./bin/local_llama_simple -m /path/to/model.gguf \"Your prompt here\""
