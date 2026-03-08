class ModelConfig:

    def __init__(
        self,
        vocab_size=32000,
        hidden_size=512,
        n_heads=8,
        n_layers=12,
        intermediate_size=2048,
        max_seq_len=4096,
        page_size=128,
        max_pages=64,
    ):
        self.vocab_size = vocab_size
        self.hidden_size = hidden_size
        self.n_heads = n_heads
        self.n_layers = n_layers
        self.intermediate_size = intermediate_size
        self.max_seq_len = max_seq_len
        self.page_size = page_size
        self.max_pages = max_pages