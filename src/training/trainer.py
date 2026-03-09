import os
import torch
from torch.utils.data import DataLoader
from torch.optim import AdamW

from model.model import EdgeLLM
from runtime.config import ModelConfig
from training.dataset import TextDataset
from tokenizers import ByteLevelBPETokenizer
from runtime.device import get_device


def train():
    if os.path.exists("tokenizer/vocab.json") and os.path.exists("tokenizer/merges.txt"):
        tokenizer = ByteLevelBPETokenizer(
            "tokenizer/vocab.json",
            "tokenizer/merges.txt"
        )
        print("Loaded existing tokenizer.")
    else:
        dataset_file = "dataset.txt"
        if not os.path.exists(dataset_file):
            raise FileNotFoundError(f"{dataset_file} not found. Please create a dataset first.")
        tokenizer = ByteLevelBPETokenizer()
        tokenizer.train(
            files=[dataset_file],
            vocab_size=32000,
            min_frequency=2
        )
        os.makedirs("tokenizer", exist_ok=True)
        tokenizer.save_model("tokenizer")
        print("Tokenizer trained and saved.")

    config = ModelConfig(vocab_size=tokenizer.get_vocab_size())
    device = get_device()

    model = EdgeLLM(config).to(device)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model.to(device)
    print(f"Using device: {device}")

    dataset_file = "dataset.txt"
    if not os.path.exists(dataset_file):
        raise FileNotFoundError(f"{dataset_file} not found. Please create a dataset first.")

    dataset = TextDataset(dataset_file, tokenizer=tokenizer)
    loader = DataLoader(dataset, batch_size=8, shuffle=True)

    optimizer = AdamW(model.parameters(), lr=3e-4)

    for epoch in range(3):
        for batch in loader:
            batch = batch.to(device)

            logits = model(batch)

            loss = torch.nn.functional.cross_entropy(
                logits.view(-1, logits.size(-1)),
                batch.view(-1)
            )

            loss.backward()
            optimizer.step()
            optimizer.zero_grad()

            print("loss:", loss.item())

    torch.save(model.state_dict(), "edge_model.pt")
    print("Model saved as edge_model.pt")


if __name__ == "__main__":
    train()