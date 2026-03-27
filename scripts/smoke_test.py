#!/usr/bin/env python3
import json
import sys
import urllib.error
import urllib.request

URL = "http://127.0.0.1:8000/"

try:
    with urllib.request.urlopen(URL, timeout=5) as response:
        payload = json.loads(response.read().decode("utf-8"))
except urllib.error.URLError as exc:
    print(f"smoke test failed: {exc}")
    sys.exit(1)

status = payload.get("status")
llama_server_url = payload.get("llama_server_url")

if status != "edge LLM server running":
    print(f"unexpected backend status: {payload}")
    sys.exit(1)

print("backend ok")
print(f"llama server url: {llama_server_url}")
