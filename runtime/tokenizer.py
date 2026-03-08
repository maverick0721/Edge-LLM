from transformers import AutoTokenizer


class Tokenizer:

    def __init__(self, model_name="gpt2"):

        self.tokenizer = AutoTokenizer.from_pretrained(model_name)

    def encode(self, text):

        return self.tokenizer.encode(text)

    def decode(self, tokens):

        return self.tokenizer.decode(tokens)