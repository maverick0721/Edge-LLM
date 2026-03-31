try:
    import faiss
    import numpy as np
except ImportError as exc:
    raise RuntimeError(
        "RAG support requires optional dependencies. "
        "Install with `pip install -r requirements.txt`."
    ) from exc


class VectorStore:
    def __init__(self, dim):
        self.index = faiss.IndexFlatL2(dim)
        self.texts = []

    def add(self, embeddings, texts):
        self.index.add(np.asarray(embeddings, dtype="float32"))
        self.texts.extend(texts)

    def search(self, query_embedding, k=3):
        if self.index.ntotal == 0:
            return []

        _, indices = self.index.search(np.asarray(query_embedding, dtype="float32"), k)
        return [self.texts[i] for i in indices[0] if 0 <= i < len(self.texts)]
