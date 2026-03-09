import torch
import math


def flash_attention(q, k, v):

    d = q.size(-1)

    scores = torch.matmul(q, k.transpose(-2, -1))

    scores = scores / math.sqrt(d)

    attn = torch.softmax(scores, dim=-1)

    return torch.matmul(attn, v)