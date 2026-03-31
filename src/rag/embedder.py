try:
    from sentence_transformers import SentenceTransformer
except ImportError as exc:
    raise RuntimeError(
        "RAG support requires optional dependencies. "
        "Install with `pip install -r requirements.txt`."
    ) from exc


class Embedder:
    def __init__(self):
        self.model = SentenceTransformer("all-MiniLM-L6-v2")

    def embed(self, texts):
        return self.model.encode(texts)
