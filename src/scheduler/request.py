class Request:

    def __init__(self, tokens):

        self.tokens = tokens
        self.finished = False
        self.generated_tokens = []