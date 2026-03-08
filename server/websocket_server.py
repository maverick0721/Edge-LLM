from fastapi import FastAPI, WebSocket
import asyncio

from model.model import EdgeLLM
from runtime.config import ModelConfig
from runtime.tokenizer import Tokenizer
from scheduler.request import Request
from scheduler.batching_engine import BatchingEngine

app = FastAPI()

config = ModelConfig()

model = EdgeLLM(config)

tokenizer = Tokenizer()

engine = BatchingEngine(model)


@app.websocket("/chat")
async def chat(ws: WebSocket):

    await ws.accept()

    while True:

        message = await ws.receive_text()

        tokens = tokenizer.encode(message)

        request = Request(tokens)

        engine.add(request)

        while not request.finished:

            outputs = engine.step()

            if outputs:

                token = outputs[-1]

                text = tokenizer.decode([token])

                await ws.send_text(text)

            await asyncio.sleep(0)