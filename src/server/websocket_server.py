import functools
import importlib
import json
import os
from pathlib import Path

import httpx
from fastapi import FastAPI, HTTPException, Request, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse
from pydantic import BaseModel

app = FastAPI()

DEFAULT_MODEL_FILE = "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
DEFAULT_UI_DIST = Path(__file__).resolve().parents[2] / "ui" / "chat-app" / "dist"

LLAMA_SERVER_URL = os.getenv("LLAMA_SERVER_URL", "http://127.0.0.1:8080/completion")
LLAMA_HEALTH_TIMEOUT_SECONDS = float(os.getenv("LLAMA_HEALTH_TIMEOUT_SECONDS", "3"))
LLAMA_REQUEST_TIMEOUT_SECONDS = float(os.getenv("LLAMA_REQUEST_TIMEOUT_SECONDS", "15"))
LLAMA_STREAM_TIMEOUT_SECONDS = float(os.getenv("LLAMA_STREAM_TIMEOUT_SECONDS", "60"))
EDGE_LLM_PROFILE = os.getenv("EDGE_LLM_PROFILE", "lite")
EDGE_LLM_MODEL_FILE = os.getenv("EDGE_LLM_MODEL_FILE", DEFAULT_MODEL_FILE)
EDGE_LLM_N_PREDICT = int(os.getenv("EDGE_LLM_N_PREDICT", "200"))
EDGE_LLM_TEMPERATURE = float(os.getenv("EDGE_LLM_TEMPERATURE", "0.7"))
PROFILE_CAPABILITIES = {
    "lite": (),
    "standard": ("rag",),
    "high-quality": ("rag", "voice"),
}
CAPABILITY_MODULES = {
    "rag": ("rag.embedder", "rag.vector_store", "rag.rag_pipeline"),
    "voice": ("voice.stt", "voice.tts"),
}


class Prompt(BaseModel):
    text: str


def get_ui_dist_dir():
    return Path(os.getenv("EDGE_LLM_UI_DIST", str(DEFAULT_UI_DIST)))


@functools.lru_cache(maxsize=1)
def get_capability_status():
    available = {}
    errors = {}

    for capability, modules in CAPABILITY_MODULES.items():
        try:
            for module_name in modules:
                importlib.import_module(module_name)
            available[capability] = True
        except Exception as exc:  # pragma: no cover - best-effort runtime probe
            available[capability] = False
            errors[capability] = f"{exc.__class__.__name__}: {exc}"

    required = list(PROFILE_CAPABILITIES.get(EDGE_LLM_PROFILE, ()))
    missing = [capability for capability in required if available.get(capability) is False]
    return {
        "available": available,
        "required": required,
        "missing": missing,
        "errors": errors,
    }


def get_runtime_metadata():
    return {
        "status": "edge LLM server running",
        "llama_server_url": LLAMA_SERVER_URL,
        "profile": EDGE_LLM_PROFILE,
        "model_file": EDGE_LLM_MODEL_FILE,
        "ui_served": (get_ui_dist_dir() / "index.html").exists(),
        "n_predict": EDGE_LLM_N_PREDICT,
        "temperature": EDGE_LLM_TEMPERATURE,
        "capabilities": get_capability_status(),
    }


def get_llama_health_url():
    if LLAMA_SERVER_URL.endswith("/completion"):
        return LLAMA_SERVER_URL[: -len("/completion")] + "/health"
    return LLAMA_SERVER_URL.rsplit("/", 1)[0] + "/health"


def build_prompt(user_message):
    return f"""
<|system|>
You are a helpful AI assistant.
<|user|>
{user_message}
<|assistant|>
"""


def build_generation_payload(prompt, stream):
    return {
        "prompt": prompt,
        "n_predict": EDGE_LLM_N_PREDICT,
        "temperature": EDGE_LLM_TEMPERATURE,
        "stream": stream,
    }


def get_timeout(*, stream):
    read_timeout = LLAMA_STREAM_TIMEOUT_SECONDS if stream else LLAMA_REQUEST_TIMEOUT_SECONDS
    return httpx.Timeout(connect=3.0, read=read_timeout, write=10.0, pool=5.0)


def extract_text(payload):
    if isinstance(payload, dict):
        for key in ("content", "response", "text", "completion"):
            value = payload.get(key)
            if isinstance(value, str):
                return value

        choices = payload.get("choices")
        if isinstance(choices, list) and choices:
            choice = choices[0]
            if isinstance(choice, dict):
                text = choice.get("text")
                if isinstance(text, str):
                    return text

                delta = choice.get("delta")
                if isinstance(delta, dict):
                    content = delta.get("content")
                    if isinstance(content, str):
                        return content

    return ""


def get_static_file(full_path):
    dist_dir = get_ui_dist_dir().resolve()
    candidate = (dist_dir / full_path).resolve()

    if candidate.is_relative_to(dist_dir) and candidate.is_file():
        return candidate

    return None


def should_skip_spa_fallback(path):
    return path.startswith("/api") or path in {"/health", "/generate"}


async def iter_generation_tokens(prompt):
    async with httpx.AsyncClient(timeout=get_timeout(stream=True)) as client:
        async with client.stream(
            "POST",
            LLAMA_SERVER_URL,
            json=build_generation_payload(prompt, stream=True),
        ) as response:
            response.raise_for_status()

            async for line in response.aiter_lines():
                if not line:
                    continue

                if line.startswith("data:"):
                    data = line.replace("data:", "").strip()
                else:
                    data = line.strip()

                if data == "[DONE]":
                    break

                try:
                    payload = json.loads(data)
                except json.JSONDecodeError:
                    if data:
                        yield data
                    continue

                token = extract_text(payload)
                if token:
                    yield token


@app.get("/api/info")
async def info():
    return get_runtime_metadata()


@app.get("/")
async def root():
    index_file = get_ui_dist_dir() / "index.html"
    if index_file.exists():
        return FileResponse(index_file)

    return get_runtime_metadata()


@app.get("/health")
async def health():
    payload = {
        **get_runtime_metadata(),
        "status": "ok",
        "llama_reachable": False,
    }

    try:
        async with httpx.AsyncClient(timeout=LLAMA_HEALTH_TIMEOUT_SECONDS) as client:
            response = await client.get(get_llama_health_url())
            payload["llama_reachable"] = response.is_success
            payload["llama_status_code"] = response.status_code
    except httpx.HTTPError as exc:
        payload["status"] = "degraded"
        payload["error"] = exc.__class__.__name__
        return payload

    if payload["llama_reachable"] is False:
        payload["status"] = "degraded"

    if payload["capabilities"]["missing"]:
        payload["status"] = "degraded"

    return payload


@app.post("/generate")
async def generate(prompt: Prompt):
    try:
        tokens = []
        async for token in iter_generation_tokens(build_prompt(prompt.text)):
            tokens.append(token)
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=503,
            detail=f"Model server unavailable: {exc.__class__.__name__}",
        ) from exc

    text = "".join(tokens).strip()
    if not text:
        raise HTTPException(
            status_code=502,
            detail="Model server returned an empty response",
        )

    return {
        "response": text,
        "llama_server_url": LLAMA_SERVER_URL,
        "profile": EDGE_LLM_PROFILE,
        "model_file": EDGE_LLM_MODEL_FILE,
    }


async def stream_generation(prompt, websocket):
    try:
        async for token in iter_generation_tokens(prompt):
            await websocket.send_text(token)
    except httpx.HTTPError as exc:
        await websocket.send_text(
            f"[error] Model server unavailable: {exc.__class__.__name__}"
        )


@app.websocket("/chat")
async def chat(ws: WebSocket):
    await ws.accept()

    try:
        while True:
            data = await ws.receive_json()
            user_message = data["message"]
            await stream_generation(build_prompt(user_message), ws)
    except WebSocketDisconnect:
        print("Client disconnected")


@app.middleware("http")
async def spa_fallback(request: Request, call_next):
    response = await call_next(request)

    if request.method != "GET" or response.status_code != 404:
        return response

    if should_skip_spa_fallback(request.url.path):
        return response

    static_file = get_static_file(request.url.path.lstrip("/"))
    if static_file is not None:
        return FileResponse(static_file)

    index_file = get_ui_dist_dir() / "index.html"
    if index_file.exists():
        return FileResponse(index_file)

    return response
