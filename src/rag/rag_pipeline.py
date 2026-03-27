from rag.embedder import Embedder
from rag.ingest import DocumentIngestor

class RAGPipeline:

    def __init__(self):

        self.embedder = Embedder()

        self.ingestor = DocumentIngestor()

    def add_documents(self, docs):

        self.ingestor.ingest(docs)

    def retrieve(self, query):

        store = self.ingestor.get_store()

        q = self.embedder.embed([query])

        return store.search(q)

    def build_prompt(self, query):

        docs = self.retrieve(query)
        if not docs:
            return query

        context = "\n".join(docs)

        return f"""
Use the following context to answer.

Context:
{context}

Question:
{query}
"""
