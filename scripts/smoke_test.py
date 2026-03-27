#!/usr/bin/env python3
import json
import os
import sys
import urllib.error
import urllib.request

PORT = os.getenv("EDGE_LLM_PORT", os.getenv("PORT", "8000"))
INFO_URL = f"http://127.0.0.1:{PORT}/api/info"
HEALTH_URL = f"http://127.0.0.1:{PORT}/health"
GENERATE_URL = f"http://127.0.0.1:{PORT}/generate"
REQUEST_TIMEOUT_SECONDS = float(os.getenv("EDGE_LLM_SMOKE_TIMEOUT_SECONDS", "60"))
GENERATE_PROMPT = os.getenv(
    "EDGE_LLM_SMOKE_PROMPT",
    "Reply with one short greeting.",
)


def load_json(url, *, data=None):
    request = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS) as response:
        return json.loads(response.read().decode("utf-8"))

try:
    info_payload = load_json(INFO_URL)
    health_payload = load_json(HEALTH_URL)
    generation_payload = load_json(
        GENERATE_URL,
        data=json.dumps({"text": GENERATE_PROMPT}).encode("utf-8"),
    )
except (urllib.error.URLError, urllib.error.HTTPError) as exc:
    print(f"smoke test failed: {exc}")
    sys.exit(1)

if info_payload.get("status") != "edge LLM server running":
    print(f"unexpected app metadata: {info_payload}")
    sys.exit(1)

if health_payload.get("status") not in {"ok", "degraded"}:
    print(f"unexpected health payload: {health_payload}")
    sys.exit(1)

if not generation_payload.get("response"):
    print(f"unexpected generation payload: {generation_payload}")
    sys.exit(1)

capabilities = info_payload.get("capabilities") or {}
required_capabilities = capabilities.get("required") or []
available_capabilities = capabilities.get("available") or {}
missing_capabilities = [
    capability
    for capability in required_capabilities
    if available_capabilities.get(capability) is not True
]
if missing_capabilities:
    print(f"missing required capabilities for profile {info_payload.get('profile')}: {missing_capabilities}")
    print(f"capability details: {capabilities}")
    sys.exit(1)

print("backend ok")
print(f"profile: {info_payload.get('profile')}")
print(f"model file: {info_payload.get('model_file')}")
print(f"ui served: {info_payload.get('ui_served')}")
print(f"llama server url: {health_payload.get('llama_server_url')}")
print(f"capabilities: {capabilities}")
print(f"sample response: {generation_payload.get('response')[:80]}")
