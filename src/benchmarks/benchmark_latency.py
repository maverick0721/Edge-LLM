import time
import torch

from model.model import EdgeLLM
from runtime.config import ModelConfig

model = EdgeLLM(ModelConfig())

prompt = torch.randint(0,1000,(1,50))

start = time.time()

model(prompt)

end = time.time()

print("latency:",end-start)