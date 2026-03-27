import json
import os

import httpx
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

app = FastAPI()

LLAMA_SERVER_URL = os.getenv("LLAMA_SERVER_URL", "http://127.0.0.1:8080/completion")


@app.get("/")
async def root():
    return {
        "status": "edge LLM server running",
        "llama_server_url": LLAMA_SERVER_URL,
    }


@app.get("/health")
async def health():
    payload = {
        "status": "ok",
        "llama_server_url": LLAMA_SERVER_URL,
        "llama_reachable": False,
    }

    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            response = await client.get(LLAMA_SERVER_URL.replace("/completion", "/health"))
            payload["llama_reachable"] = response.is_success
            payload["llama_status_code"] = response.status_code
    except httpx.HTTPError as exc:
        payload["status"] = "degraded"
        payload["error"] = exc.__class__.__name__
        return payload

    if payload["llama_reachable"] is False:
        payload["status"] = "degraded"

    return payload


async def stream_generation(prompt, websocket):

    async with httpx.AsyncClient(timeout=None) as client:
        try:
            async with client.stream(
                "POST",
                LLAMA_SERVER_URL,
                json={
                    "prompt": prompt,
                    "n_predict": 200,
                    "temperature": 0.7,
                    "stream": True,
                },
            ) as response:
                response.raise_for_status()

                async for line in response.aiter_lines():

                    if not line:
                        continue

                    if line.startswith("data:"):

                        data = line.replace("data:", "").strip()

                        if data == "[DONE]":
                            break

                        try:
                            payload = json.loads(data)
                            token = payload.get("content")

                            if token:
                                await websocket.send_text(token)
                        except json.JSONDecodeError:
                            continue
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

            prompt = f"""
<|system|>
You are a helpful AI assistant.
<|user|>
{user_message}
<|assistant|>
"""

            await stream_generation(prompt, ws)

    except WebSocketDisconnect:

        print("Client disconnected")
