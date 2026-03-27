# Edge-LLM Android Local Mode

This folder now contains a real Android app project for fully local chat on supported Android devices.

## What It Uses

- Google's ML Kit Prompt API
- Android AICore for on-device Gemini Nano execution
- a local Android UI
- no Python backend
- no Docker dependency for inference

## What This Means

This Android path is fully local on supported devices, but it is not the same GGUF + `llama.cpp` runtime as the desktop edge stack.

For Android-first local deployment, this is the practical official path today because Google exposes on-device generation through AICore-backed ML Kit APIs.

## Requirements

- Android API level 26 or later
- a device that supports AICore / Gemini Nano for ML Kit Prompt API
- the AICore-managed local model prepared on device

Official references:

- https://developers.google.com/ml-kit/genai/prompt/android/get-started
- https://developer.android.com/ai/aicore

## Project Layout

- `app/` contains the Android application
- `app/src/main/java/com/edge/llm/OnDevicePromptEngine.java` handles local inference and download status
- `app/src/main/java/com/edge/llm/MainActivity.java` provides the Android chat UI

## How To Use

1. Open `mobile/android` in Android Studio.
2. Let Android Studio install any missing Android SDK components.
3. Run the `app` target on a supported Android device.
4. Use `Prepare Model` if AICore reports the local model as downloadable.

## Current Limits

- This Android-local mode depends on Google AICore availability on the device.
- The ML Kit Prompt API is currently documented as an alpha API.
- This repo does not yet include a unified Android GGUF + `llama.cpp` mobile runtime.
- I could not terminal-build this project on the current Mac because it does not have a Java runtime, Gradle, or Android SDK installed.
