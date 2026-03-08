import torch
import torch.nn as nn

from kernels.flash_attention import flash_attention

class MultiHeadAttention(nn.Module):

    def __init__(self, config):

        super().__init__()

        self.n_heads = config.n_heads
        self.head_dim = config.hidden_size // config.n_heads

        self.qkv = nn.Linear(
            config.hidden_size,
            3 * config.hidden_size,
        )

        self.proj = nn.Linear(
            config.hidden_size,
            config.hidden_size,
        )

    def forward(self, x):

        B, T, C = x.shape

        qkv = self.qkv(x)

        q, k, v = qkv.chunk(3, dim=-1)

        q = q.view(B, T, self.n_heads, self.head_dim).transpose(1, 2)
        k = k.view(B, T, self.n_heads, self.head_dim).transpose(1, 2)
        v = v.view(B, T, self.n_heads, self.head_dim).transpose(1, 2)

        out = flash_attention(q, k, v)

        out = out.transpose(1, 2).contiguous()

        out = out.view(B, T, C)

        return self.proj(out)


class TransformerBlock(nn.Module):

    def __init__(self, config):

        super().__init__()

        self.ln1 = nn.LayerNorm(config.hidden_size)

        self.attn = MultiHeadAttention(config)

        self.ln2 = nn.LayerNorm(config.hidden_size)

        self.mlp = nn.Sequential(
            nn.Linear(config.hidden_size, config.intermediate_size),
            nn.GELU(),
            nn.Linear(config.intermediate_size, config.hidden_size),
        )

    def forward(self, x):

        x = x + self.attn(self.ln1(x))

        x = x + self.mlp(self.ln2(x))

        return x