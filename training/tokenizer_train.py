import os
from tokenizers import ByteLevelBPETokenizer

def train_tokenizer(file_path):
    """
    Train a ByteLevel BPE tokenizer if not already trained,
    otherwise load existing tokenizer files.
    """

    if not os.path.exists(file_path):
        print(f"Error: Dataset file '{file_path}' not found.")
        return None

    os.makedirs("tokenizer", exist_ok=True)

    vocab_file = "tokenizer/vocab.json"
    merges_file = "tokenizer/merges.txt"

    if os.path.exists(vocab_file) and os.path.exists(merges_file):
        tokenizer = ByteLevelBPETokenizer(vocab_file, merges_file)
        print("Loaded existing tokenizer.")
    else:
      
        print(f"Training tokenizer on '{file_path}'...")
        tokenizer = ByteLevelBPETokenizer()
        tokenizer.train(
            files=[file_path],
            vocab_size=32000,
            min_frequency=2,
            special_tokens=["<s>", "<pad>", "</s>", "<unk>", "<mask>"]
        )
        tokenizer.save_model("tokenizer")
        print("Tokenizer trained and saved in 'tokenizer/' folder.")

    return tokenizer

if __name__ == "__main__":
    dataset_file = "dataset.txt"
    train_tokenizer(dataset_file)