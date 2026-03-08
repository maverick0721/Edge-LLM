import torch
import torch.nn as nn

from runtime.config import ModelConfig
from model.transformer import TransformerBlock

class EdgeLLM(nn.Module):

    def __init__(self, config: ModelConfig):

        super().__init__()

        self.config = config

        self.embed = nn.Embedding(
            config.vocab_size,
            config.hidden_size,
        )

        self.layers = nn.ModuleList(
            [TransformerBlock(config) for _ in range(config.n_layers)]
        )

        self.ln_f = nn.LayerNorm(config.hidden_size)

        self.head = nn.Linear(
            config.hidden_size,
            config.vocab_size,
        )

    def forward(self, input_ids):

        x = self.embed(input_ids)

        for layer in self.layers:
            x = layer(x)

        x = self.ln_f(x)

        logits = self.head(x)

        return logits