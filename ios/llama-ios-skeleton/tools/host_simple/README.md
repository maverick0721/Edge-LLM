# Host-side quick test for staged llama.cpp

This folder contains a small CLI harness (`local_llama_simple`) and a `CMakeLists.txt` to build it against the staged `llama.cpp` in `../../third_party/llama.cpp`.

Prerequisites (on macOS):

- Xcode command line tools
- Homebrew `cmake` (install with `brew install cmake`)

Build & run (from this folder):

```bash
cd ios/llama-ios-skeleton/tools/host_simple
mkdir -p build && cd build
cmake ..
cmake --build . --config Release --target local_llama_simple -j$(sysctl -n hw.ncpu)

# run the binary (replace /path/to/model.gguf with your model)
./bin/local_llama_simple -m /path/to/model.gguf "Hello from host"
```

Notes:
- If you cloned the repo elsewhere or your `llama.cpp` is in a different path, edit the `CMakeLists.txt` to point `LLAMA_CPP_DIR` at the correct location.
- If you haven't fetched `llama.cpp` into `ios/third_party/llama.cpp`, run the helper script: `bash ../../scripts/fetch_build_llama.sh` from `ios/llama-ios-skeleton`.
