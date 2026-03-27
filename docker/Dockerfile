FROM python:3.10

WORKDIR /app

ENV PYTHONPATH=/app/src

COPY pyproject.toml README.md /app/
COPY src /app/src

RUN pip install --no-cache-dir fastapi uvicorn httpx

CMD ["python", "-m", "cli.cli"]
