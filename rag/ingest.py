from rag.embedder import Embedder
from rag.vector_store import VectorStore

class DocumentIngestor:

    def __init__(self):

        self.embedder = Embedder()

        self.store = VectorStore(384)

    def ingest(self, documents):

        embeddings = self.embedder.embed(documents)

        self.store.add(embeddings, documents)

    def get_store(self):

        return self.store