import torch

class BatchingEngine:

    def __init__(self, model):

        self.model = model
        self.requests = []

    def add(self, request):

        self.requests.append(request)

    def step(self):

        if not self.requests:
            return []

        max_len = max(len(r.tokens) for r in self.requests)

        batch = []

        for r in self.requests:

            padded = r.tokens + [0]*(max_len-len(r.tokens))

            batch.append(padded)

        input_ids = torch.tensor(batch)

        logits = self.model(input_ids)

        outputs = []

        for i, r in enumerate(self.requests):

            next_token = logits[i][-1].argmax()

            r.tokens.append(int(next_token))

            outputs.append(int(next_token))

        return outputs