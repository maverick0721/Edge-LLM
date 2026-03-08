from tokenizers import ByteLevelBPETokenizer

def train_tokenizer(file):

    tokenizer = ByteLevelBPETokenizer()

    tokenizer.train(
        files=[file],
        vocab_size=32000,
        min_frequency=2
    )

    tokenizer.save_model("tokenizer")