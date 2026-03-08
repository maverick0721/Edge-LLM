from fastapi import FastAPI
from pydantic import BaseModel

from runtime.tokenizer import Tokenizer
from model.model import EdgeLLM
from runtime.config import ModelConfig
from rag.rag_pipeline import RAGPipeline

app = FastAPI()

tokenizer = Tokenizer()

model = EdgeLLM(ModelConfig())

rag = RAGPipeline()

class Prompt(BaseModel):

    text: str

@app.post("/generate")
def generate(prompt: Prompt):

    prompt_text = rag.build_prompt(prompt.text)

    tokens = tokenizer.encode(prompt_text)

    import torch

    input_ids = torch.tensor([tokens])

    logits = model(input_ids)

    token = logits[0][-1].argmax()

    return {
        "response": tokenizer.decode([int(token)])
    }