class PagedAllocator:

    def __init__(self, page_size, max_pages):

        self.page_size = page_size
        self.max_pages = max_pages

        self.pages = []
        self.free_pages = list(range(max_pages))

        for _ in range(max_pages):
            self.pages.append(None)

    def allocate(self, tensor):

        if not self.free_pages:
            raise RuntimeError("KV cache full")

        page = self.free_pages.pop()

        self.pages[page] = tensor

        return page

    def free(self, page):

        self.pages[page] = None
        self.free_pages.append(page)