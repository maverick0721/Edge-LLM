# Edge-LLM iOS (llama.cpp) Integration

This module provides an iOS SwiftUI app + C bridge around `llama.cpp` for on-device GGUF inference.

## Included

- SwiftUI app: `App/SwiftUIApp/*`
- C bridge: `Sources/LlamaBridgeShim/*`
- Binary package dependency: `LLamaCppBinaryPackage/`
- XCFramework build + sync scripts: `scripts/*`

## Requirements

- macOS + Xcode (latest recommended)
- iOS Simulator or physical iPhone
- A **valid generative GGUF model** (not vocab-only)

## Quick Start

### 1) Open in Xcode

From project root:

```bash
cd ios/llama-ios-skeleton
bash scripts/open_in_xcode.sh
```

Or open `Package.swift` directly in Xcode.

### 2) Build and run

- Select scheme: `LLamaDemo`
- Select simulator/device
- Run (`Cmd + R`)

### 3) Load model

In app UI:

1. Tap `Pick Model` and select your `.gguf`
2. Tap `Load`
3. Enter prompt and tap `Generate`

## Model Rules (Important)

To avoid garbage output (`<unk>`, symbols, random tokens):

- Use a chat/instruct GGUF (example: `tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf`)
- Do **not** use vocab-only GGUF files (`ggml-vocab-*`)
- Prefer model files larger than ~100MB

The app/bridge now validates model load and rejects invalid/non-generative files.

## Recommended Test Prompt

After load succeeds:

```text
What is RAG? Explain in 2 simple sentences.
```

## Scripts

### Build XCFramework

```bash
bash scripts/create_xcframework.sh
```

Output:
- `build_xcframework/LLamaCpp.xcframework`

### Copy XCFramework into local binary package

```bash
bash scripts/copy_xcframework_to_package.sh
```

### Run on simulator (CLI helper)

```bash
bash scripts/run_ios_sim.sh
```

## Known Troubleshooting

### App runs but output is unreadable

Check in order:

1. Wrong GGUF selected (most common)
2. Vocab-only model instead of generative model
3. Stale build cache

Fix:

- `Product -> Clean Build Folder`
- Re-run app
- Re-load correct chat GGUF

### File picker shows empty list

- Simulator has no local files by default
- Use `Pick Model` and import model into app sandbox
- Or copy model into simulator app Documents folder first, then use `Use Documents`

### Build errors around `llama.h` / `ggml.h`

- Ensure package/header settings are synced
- Rebuild after `create_xcframework.sh` and `copy_xcframework_to_package.sh`

## Project Layout

- `App/SwiftUIApp/ContentView.swift` — UI + load/generate flow
- `App/SwiftUIApp/LlamaClient.swift` — Swift -> C bridge calls
- `Sources/LlamaBridgeShim/llama_bridge_shim.c` — model load + token generation loop
- `Package.swift` — targets, dependencies, C header include settings

## Notes

- Generation runs on-device (no server dependency)
- Performance and output quality depend on model size/quantization and device RAM
- For production, add structured model metadata checks and telemetry for load/generation failures
