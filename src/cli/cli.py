import os

import uvicorn

def run_server():
    host = os.getenv("EDGE_LLM_HOST", "0.0.0.0")
    port = int(os.getenv("EDGE_LLM_PORT", os.getenv("PORT", "8000")))

    uvicorn.run(
        "server.websocket_server:app",
        host=host,
        port=port,
    )

if __name__ == "__main__":

    run_server()
