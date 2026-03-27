FROM node:20-bookworm-slim AS ui-builder

WORKDIR /ui

COPY ui/chat-app/package.json ui/chat-app/package-lock.json ./
RUN npm ci

COPY ui/chat-app /ui
RUN npm run build


FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app/src
ENV EDGE_LLM_UI_DIST=/app/ui-dist

ARG EDGE_LLM_PROFILE=lite
ARG EDGE_LLM_REQUIREMENTS=requirements.txt

COPY requirements.txt requirements-standard.txt requirements-high-quality.txt /app/
RUN apt-get update \
    && if [ "$EDGE_LLM_PROFILE" = "high-quality" ]; then \
        apt-get install -y --no-install-recommends espeak-ng libportaudio2; \
    fi \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r "/app/${EDGE_LLM_REQUIREMENTS}"

COPY pyproject.toml README.md /app/
COPY src /app/src
COPY --from=ui-builder /ui/dist /app/ui-dist

EXPOSE 8000

CMD ["python", "-m", "cli.cli"]
