# Edge-LLM iPhone/iPad Local Mode

This folder now targets a true local iPhone/iPad chat path instead of calling the desktop backend.

## What It Uses

- Apple's `FoundationModels` framework for on-device generation
- a local SwiftUI chat UI
- no Docker
- no FastAPI backend
- no network dependency for inference

## What This Means

This is fully local on supported iPhone and iPad hardware, but it is not the same runtime as the repo's GGUF + `llama.cpp` edge stack.

For iPhone/iPad first, this is the most realistic local deployment path because Apple already ships the on-device model runtime on supported devices.

## Supported Devices

This path requires:

- iOS or iPadOS 26 or later
- an Apple Intelligence-capable iPhone or iPad
- Apple Intelligence enabled on the device

Representative supported hardware includes:

- iPhone 15 Pro and iPhone 15 Pro Max
- iPhone 16 family
- iPad mini with A17 Pro
- iPad models with M1 or later

Check the current official Apple support page before shipping broadly:

- https://support.apple.com/121115

## How To Use In Xcode

1. Open `mobile/ios/EdgeLLMiOS.xcodeproj`.
2. Select the `EdgeLLMiOS` scheme.
3. Build and run on a supported iPhone or iPad.
4. If you want to customize branding later, add `Assets.xcassets` into the target from Xcode.

## Current Limits

- This iOS-local mode does not yet load a shipped GGUF model.
- It depends on Apple Intelligence availability on the device.
- The generated project keeps branding assets optional so it can compile even on a Mac without installed iOS simulator runtimes.
- The repo still needs a separate `llama.cpp`-based iOS path if you want the same quantized GGUF runtime family everywhere.

## Next Step

If you want broader iPhone/iPad coverage beyond Apple Intelligence devices, the next iteration should add a `llama.cpp` iOS integration path using an iOS-friendly local GGUF runtime.
