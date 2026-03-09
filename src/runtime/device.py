import torch

def get_device():

    if torch.cuda.is_available():
        print("Using CUDA GPU")
        return torch.device("cuda")

    if torch.backends.mps.is_available():
        print("Using Apple MPS")
        return torch.device("mps")

    print("Using CPU")
    return torch.device("cpu")