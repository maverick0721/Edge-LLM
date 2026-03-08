from fastapi import FastAPI
from pydantic import BaseModel

from runtime.tokenizer import Tokenizer
from model.model import EdgeLLM
from runtime.config import ModelConfig

app = FastAPI()

tokenizer = Tokenizer()

model = EdgeLLM(ModelConfig())


class Prompt(BaseModel):

    text: str


@app.post("/generate")
def generate(prompt: Prompt):

    tokens = tokenizer.encode(prompt.text)

    import torch

    input_ids = torch.tensor([tokens])

    logits = model(input_ids)

    next_token = logits[0][-1].argmax()

    return {
        "token": tokenizer.decode([int(next_token)])
    }