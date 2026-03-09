from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import asyncio
import torch
import json

from model.model import EdgeLLM
from runtime.config import ModelConfig
from runtime.tokenizer import Tokenizer
from scheduler.request import Request
from scheduler.batching_engine import BatchingEngine
from runtime.device import get_device
from transformers import AutoModelForCausalLM, AutoTokenizer, TextIteratorStreamer, BitsAndBytesConfig
from threading import Thread

app = FastAPI()

model_name = "TinyLlama/TinyLlama-1.1B-Chat-v1.0"

tokenizer = AutoTokenizer.from_pretrained(model_name)

# enable 8-bit quantization for edge devices
bnb_config = BitsAndBytesConfig(
    load_in_8bit=True
)

model = AutoModelForCausalLM.from_pretrained(
    model_name,
    quantization_config=bnb_config,
    device_map="auto"
)

model.eval()

engine = BatchingEngine(model)

# store conversations per chat
chat_sessions = {}

@app.get("/")
async def root():
    return {"message": "WebSocket server is running"}

@app.websocket("/chat")
async def chat(ws: WebSocket):
    await ws.accept()

    # memory per client
    conversation = []

    try:  # <-- wrap the loop in try
        while True:
            user_message = await ws.receive_text()

            conversation.append({"role": "user", "content": user_message})

            # build prompt using chat template
            prompt = tokenizer.apply_chat_template(
                conversation,
                tokenize=False,
                add_generation_prompt=True
            )

            inputs = tokenizer(prompt, return_tensors="pt").to(model.device)

            streamer = TextIteratorStreamer(
                tokenizer,
                skip_prompt=True,
                skip_special_tokens=True
            )

            generation_kwargs = dict(
                **inputs,
                streamer=streamer,
                max_new_tokens=200,
                do_sample=True,
                temperature=0.7,
                top_p=0.9
            )

            thread = Thread(target=model.generate, kwargs=generation_kwargs)
            thread.start()

            assistant_message = ""

            for new_text in streamer:
                assistant_message += new_text
                await ws.send_text(new_text)

            conversation.append({"role": "assistant", "content": assistant_message})

    except WebSocketDisconnect:
        print("Client disconnected")