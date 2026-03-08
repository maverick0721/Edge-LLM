import torch
from torch.utils.data import DataLoader
from torch.optim import AdamW

from model.model import EdgeLLM
from runtime.config import ModelConfig
from training.dataset import TextDataset


def train():

    config = ModelConfig()

    model = EdgeLLM(config)

    dataset = TextDataset("dataset.txt")

    loader = DataLoader(dataset, batch_size=8, shuffle=True)

    optimizer = AdamW(model.parameters(), lr=3e-4)

    for epoch in range(3):

        for batch in loader:

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


if __name__ == "__main__":
    train()