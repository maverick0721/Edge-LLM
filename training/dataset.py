import torch
from torch.utils.data import Dataset
from transformers import AutoTokenizer


class TextDataset(Dataset):

    def __init__(self, file_path, tokenizer_name="gpt2", seq_len=128):

        self.tokenizer = AutoTokenizer.from_pretrained(tokenizer_name)
        self.seq_len = seq_len

        with open(file_path, "r", encoding="utf8") as f:
            text = f.read()

        tokens = self.tokenizer.encode(text)

        self.samples = []

        for i in range(0, len(tokens) - seq_len):
            self.samples.append(tokens[i:i+seq_len])

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        x = torch.tensor(self.samples[idx])
        return x