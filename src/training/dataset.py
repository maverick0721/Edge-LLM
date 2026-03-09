import torch
from torch.utils.data import Dataset

class TextDataset(Dataset):
    def __init__(self, file_path, tokenizer=None, seq_len=128):
        """
        Args:
            file_path (str): Path to text dataset.
            tokenizer: a ByteLevelBPETokenizer or similar object with encode() method.
            seq_len (int): sequence length for training.
        """
        if tokenizer is None:
            raise ValueError("Tokenizer must be provided.")

        self.tokenizer = tokenizer
        self.seq_len = seq_len

        with open(file_path, "r", encoding="utf8") as f:
            text = f.read()

        tokens = self.tokenizer.encode(text).ids

        self.samples = []
        for i in range(0, len(tokens) - seq_len + 1, seq_len):
            self.samples.append(tokens[i:i+seq_len])

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        return torch.tensor(self.samples[idx], dtype=torch.long)