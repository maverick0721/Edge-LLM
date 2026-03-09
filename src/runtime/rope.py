import torch

def precompute_rope(head_dim, seq_len):

    theta = 10000

    freqs = 1.0 / (
        theta ** (torch.arange(0, head_dim, 2).float() / head_dim)
    )

    t = torch.arange(seq_len)

    freqs = torch.outer(t, freqs)

    return torch.cos(freqs), torch.sin(freqs)


def apply_rope(x, cos, sin):

    x1 = x[..., ::2]
    x2 = x[..., 1::2]

    out = torch.stack(
        [
            x1 * cos - x2 * sin,
            x1 * sin + x2 * cos,
        ],
        dim=-1,
    )

    return out.flatten(-2)