import torch

def quantize_int4(weight):

    scale = weight.abs().max() / 7

    q = torch.clamp((weight / scale).round(), -8, 7)

    q = q.to(torch.int8)

    return q, scale


def dequantize_int4(q, scale):

    return q.float() * scale