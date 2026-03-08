import torch

class KVCacheManager:

    def __init__(self, allocator):

        self.allocator = allocator
        self.requests = {}

    def append(self, request_id, k, v):

        page = self.allocator.allocate((k, v))

        if request_id not in self.requests:
            self.requests[request_id] = []

        self.requests[request_id].append(page)

    def get(self, request_id):

        pages = self.requests[request_id]

        k_list = []
        v_list = []

        for p in pages:

            k, v = self.allocator.pages[p]

            k_list.append(k)
            v_list.append(v)

        return (
            torch.cat(k_list, dim=2),
            torch.cat(v_list, dim=2),
        )