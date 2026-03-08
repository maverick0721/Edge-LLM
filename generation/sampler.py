import torch

def sample_next_token(logits, temperature=1.0, top_k=50):

    logits = logits / temperature

    values, indices = torch.topk(logits, top_k)

    probs = torch.softmax(values, dim=-1)

    next_token = torch.multinomial(probs, 1)

    return indices[next_token]