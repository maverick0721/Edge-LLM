import uvicorn

def run_server():

    uvicorn.run(
        "server.websocket_server:app",
        host="0.0.0.0",
        port=8000,
    )


if __name__ == "__main__":
    run_server()