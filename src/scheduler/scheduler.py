import asyncio

class Scheduler:

    def __init__(self, engine):

        self.engine = engine

    async def run(self):

        while True:

            outputs = self.engine.step()

            await asyncio.sleep(0)