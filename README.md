# Edge-LLM

### Local AI Chat Stack for Edge-Class Hardware

Edge-LLM is a local chat system built around two runtime services:
- `llama.cpp` serving a local GGUF model
- one FastAPI app that serves both the API/WebSocket backend and the built React UI

That deployment shape is intentionally simpler than the old dev-only layout. On an edge device, you no longer need a separate always-on Vite dev server.

The repo includes an iOS local GGUF runtime sample:
- `ios/llama-ios-skeleton/` for iPhone/iPad using `llama.cpp` + GGUF via an XCFramework bridge

## Project Layout

```text
Edge-LLM/
├── docker-compose.yml
├── docker/
├── models/
├── profiles/
├── scripts/
├── src/
└── ui/chat-app/
```

## Runtime Tiers

The repo now ships with three edge-oriented tiers:

- `lite`: smallest Python/runtime footprint, best for CPU-only and lower-memory devices
- `standard`: adds local RAG and heavier ML dependencies
- `high-quality`: adds voice I/O on top of the standard tier

Python install files:

```bash
pip install -r requirements.txt
```

Docker launch profiles:

- `profiles/lite.env`
- `profiles/standard.env`
- `profiles/high-quality.env`

The shipped example model is still:

- `models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf`

For better quality on stronger hardware, replace the model path in the chosen profile with a larger GGUF.

## Quick Start

1. Place a GGUF model in `models/`
2. Run the preflight check
3. Start the profile that matches the target device

```bash
python3 scripts/preflight.py
docker compose --env-file profiles/lite.env up --build
```

Then open:

```text
http://localhost:8000
```

That single URL now serves the built UI and talks to the backend on the same origin.

## One-Command Demo Run

For a complete start flow (preflight + compose up + smoke test), run:

```bash
./scripts/run_demo.sh
```

Optional examples:

```bash
./scripts/run_demo.sh --profile standard
./scripts/run_demo.sh --profile high-quality --follow
./scripts/run_demo.sh --down --profile lite
```

## One-Command iOS Run

Run the iOS simulator demo in one command:

```bash
./scripts/run_ios_demo.sh
```

Optional examples:

```bash
./scripts/run_ios_demo.sh --sim-name "iPhone 17 Pro"
./scripts/run_ios_demo.sh --sim-id 0DAAA551-21D2-4901-B9BC-C962A8338369
```

## Preflight

Run this before startup:

```bash
python3 scripts/preflight.py
```

Required checks:

- Docker
- profile directory
- models directory
- selected GGUF model

Helpful optional checks:
- Node and npm for local UI rebuilds
- built UI assets in `ui/chat-app/dist`
 
If any required check is missing, fix that before starting the stack.

## Smoke Check

After the app starts, run:

```bash
python3 scripts/smoke_test.py
```

Expected output includes:
- `backend ok`
- selected profile
- selected model file
- whether the UI is being served by the app
- required profile capabilities when applicable
- a non-empty sample generation

## Services

- `llama`: serves the local GGUF model on port `8080`
- `app`: serves the built React UI, `/generate`, `/health`, `/api/info`, and WebSocket `/chat` on port `8000`

## Production-Oriented Docker Flow

Start the default low-footprint tier:

```bash
docker compose --env-file profiles/lite.env up --build
```

Start the balanced tier:

```bash
docker compose --env-file profiles/standard.env up --build
```

Start the higher-quality tier:

```bash
docker compose --env-file profiles/high-quality.env up --build
```

You can also use the helper script:

```bash
./scripts/start_profile.sh standard
```

## Install Script

The old Ubuntu-specific installer was replaced with a project-local setup flow:

```bash
./install.sh lite
./install.sh standard
./install.sh high-quality
```

That script:
- creates `.venv` if needed
- installs the selected Python tier
- builds the production UI
- prepares `models/`

## Manual Start

Start the model server:

```bash
docker compose --env-file profiles/lite.env up llama
```

Start the backend manually against an already-running llama server:

```bash
EDGE_LLM_PROFILE=lite \
EDGE_LLM_MODEL_FILE=tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
EDGE_LLM_UI_DIST=ui/chat-app/dist \
LLAMA_SERVER_URL=http://127.0.0.1:8080/completion \
PYTHONPATH=src python3 -m cli.cli
```

Build the UI manually if needed:

```bash
cd ui/chat-app
npm install
npm run build
```

For frontend-only development, you can still use:

```bash
cd ui/chat-app
VITE_EDGE_LLM_PORT=8000 npm run dev -- --host
```

## API Endpoints

- `/`: built UI if available, otherwise runtime metadata JSON
- `/api/info`: runtime metadata including profile and selected model file
- `/health`: backend plus llama reachability status
- `/generate`: HTTP generation endpoint
- `/chat`: WebSocket streaming chat endpoint

## Notes

- `requirements.txt` is now a unified dependency file that includes core + optional packages.
- Runtime tiers still differ by profile settings and required capabilities, not by separate requirements files.
- The container build installs `requirements.txt` and applies profile-specific runtime flags/capability checks.
- The main app now serves the production UI directly, so runtime deployment no longer depends on a separate Vite dev server.
- The compose profiles let you tune context size, threads, generation length, and model file per device class.
- Better answer quality comes mostly from the GGUF model choice, not from the Python tier alone.
- iPhone/iPad local mode is available in `ios/llama-ios-skeleton` and is separate from the Docker stack.

## Validation Script

Run all profile smoke checks in sequence:

```bash
./scripts/validate_profiles.sh
```

Run a subset:

```bash
./scripts/validate_profiles.sh lite standard
```
