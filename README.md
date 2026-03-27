# Edge-LLM

### Local AI Chat System for Edge Devices

Edge-LLM is a local chat stack built around three pieces:
- a React chat UI
- a FastAPI WebSocket backend
- a `llama.cpp` server serving a local GGUF model

## Project Layout

```text
Edge-LLM/
├── docker-compose.yml
├── docker/
├── models/
├── scripts/
├── src/
└── ui/chat-app/
```

## Requirements

Before starting the full system, place a GGUF model in [`models/README.md`](/home/ubuntu/Edge-LLM/models/README.md).

Default expected file:
- `models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf`

For local Python setup, use the cleaned dependency file:

```bash
pip install -r requirements.txt
```

## Quick Start

```bash
chmod +x install.sh
./install.sh
python3 scripts/preflight.py
docker compose up
```

Then open:

```text
http://localhost:5173
```

## Preflight

Run this before startup to catch missing local requirements:

```bash
python3 scripts/preflight.py
```

It checks for:
- Docker
- Node and npm
- the root compose file
- the UI directory
- the models directory
- the default GGUF model file

## Smoke Check

After the backend starts, run:

```bash
python3 scripts/smoke_test.py
```

Expected output includes:
- `backend ok`
- the resolved `llama_server_url`

## Health Endpoint

After the backend starts, you can also check:

```text
http://localhost:8000/health
```

That endpoint reports backend status plus whether the backend can currently reach the llama server.

## Docker Healthchecks

The compose files now include healthchecks for:
- `backend`: queries `http://127.0.0.1:8000/health`
- `ui`: fetches `http://127.0.0.1:5173`

The dependency chain is now:
- `backend` waits for `llama` to start
- `ui` waits for `backend` to become healthy

After startup, you can inspect them with:

```bash
docker compose ps
```

## Services

- `llama`: serves the local GGUF model on port `8080`
- `backend`: exposes the WebSocket chat API on port `8000`
- `ui`: runs the Vite chat app on port `5173`

## Manual Start

Start the model server with Docker:

```bash
docker compose up llama
```

Start the backend manually:

```bash
PYTHONPATH=src python3 -m cli.cli
```

Start the UI manually:

```bash
cd ui/chat-app
npm install
npm run dev -- --host
```

## Notes

- `requirements.txt` was reduced to the actual project dependencies so plain `pip install -r requirements.txt` works on a normal environment.
- In Docker, the backend now talks to `http://llama:8080/completion` instead of trying to call itself on `127.0.0.1`.
- The UI connects to the current host by default instead of hardcoding `127.0.0.1`.
- If the model server is unavailable, the chat view now shows an explicit error instead of silently failing.
- The frontend chat list and current conversation are now wired together, so saved chats and sidebar selection work consistently.
