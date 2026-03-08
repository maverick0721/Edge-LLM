class Request:

    def __init__(self, tokens):
        self.tokens = tokens
        self.finished = False


class BatchingEngine:

    def __init__(self, model):

        self.model = model
        self.requests = []

    def add(self, request):

        self.requests.append(request)

    def step(self):

        batch = [r.tokens for r in self.requests]

        logits = self.model(batch)

        for i, r in enumerate(self.requests):

            token = logits[i][-1].argmax()

            r.tokens.append(int(token))