FROM python:3.10

WORKDIR /app

COPY . /app

RUN pip install fastapi uvicorn httpx

CMD ["python", "-m", "cli.cli"]