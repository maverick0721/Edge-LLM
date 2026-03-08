import torch

def speculative_decode(
    draft_model,
    target_model,
    tokens,
    steps=4
):

    draft_logits = draft_model(tokens)

    draft_tokens = torch.argmax(
        draft_logits[:, -steps:], dim=-1
    )

    target_logits = target_model(tokens)

    target_tokens = torch.argmax(
        target_logits[:, -steps:], dim=-1
    )

    accepted = []

    for d, t in zip(draft_tokens[0], target_tokens[0]):

        if d == t:
            accepted.append(int(d))
        else:
            break

    return accepted