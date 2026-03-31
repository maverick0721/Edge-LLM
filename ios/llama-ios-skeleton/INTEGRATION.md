LLama.cpp integration notes
===========================

This document explains how to integrate the real `llama.cpp` sources into the `LLamaCpp` framework target and how to prepare quantized models for on-device use.

1) Fetch & build host tools (automatic)

```bash
cd ios/llama-ios-skeleton
bash scripts/fetch_build_llama.sh
```

This clones `llama.cpp` into `ios/third_party/llama.cpp`, builds the host tools (`main`, `quantize`, etc.), and stages a copy of the sources into `Framework/LLamaCpp/Source/llama_cpp`.

2) Convert & quantize your model (on macOS host)

- If you already have a GGUF quantized model, copy it to your macOS machine. Otherwise, convert HF safetensors/pytorch weights to GGUF using conversion scripts inside `third_party/llama.cpp/tools/`.

Example (host side):

```bash
# build host tools inside third_party/llama.cpp (done by fetch script)
cd ios/llama-ios-skeleton/third_party/llama.cpp
# convert (tool name/version varies)
python3 tools/convert.py --input /path/to/model.safetensors --out /tmp/model.gguf
# quantize (available after make)
./quantize /tmp/model.gguf /tmp/model-q4k.gguf q4_k_m
# test with host binary
./main -m /tmp/model-q4k.gguf -p "Hello from mac"
```

3) Add llama.cpp sources to the Xcode framework

- In Xcode, open your project and the `LLamaCpp` framework target.
- Add all source files under `Framework/LLamaCpp/Source/llama_cpp` to the framework target.
- Build settings to check:
  - C++ Language Dialect: C++17 or later
  - Other C++ Flags: add `-DGGML_USE_ACCELERATE` or Apple specific defines if you plan to use Accelerate/Metal backends
  - Enable `Objective-C++` for `.mm` files

4) Replace the stub bridge implementation

- The repo contains `LlamaBridge.h` and a stub `LlamaBridge.mm`. Replace the stub behaviour with real calls into the llama.cpp API (loading the GGUF model, running `llama_eval`/inference, and streaming tokens to the callback). See `Framework/LLamaCpp/Source/LlamaBridge_integration_example.mm` for a commented integration outline.

5) Model delivery & runtime

- Do NOT ship large model files inside the app bundle. Download them on first-run into `Application Support` and validate checksum.
- Use short contexts (e.g. 512 tokens) and conservative `n_threads` values to reduce RAM.

6) Build XCFramework

After the framework builds for device & simulator, run:

```bash
cd ios/llama-ios-skeleton
bash scripts/create_xcframework.sh
```

7) Test on device

- Run the app on a physical iPhone 14/14 Plus. Use Instruments (Allocations, VM) to watch memory usage. Tune `n_ctx` and `n_threads`.

If you want, I can also try to generate a pre-configured Xcode project that wires these files into a `LLamaCpp` framework target automatically.
