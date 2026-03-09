from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import httpx
import json

app = FastAPI()

LLAMA_SERVER_URL = "http://127.0.0.1:8080/completion"


@app.get("/")
async def root():
    return {"status": "edge LLM server running"}


async def stream_generation(prompt, websocket):

    async with httpx.AsyncClient(timeout=None) as client:

        async with client.stream(
            "POST",
            LLAMA_SERVER_URL,
            json={
                "prompt": prompt,
                "n_predict": 200,
                "temperature": 0.7,
                "stream": True
            },
        ) as response:

            async for line in response.aiter_lines():

                if not line:
                    continue

                if line.startswith("data:"):

                    data = line.replace("data:", "").strip()

                    if data == "[DONE]":
                        break

                    try:
                        token = json.loads(data)["content"]
                        await websocket.send_text(token)

                    except Exception:
                        pass


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