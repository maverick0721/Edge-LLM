#!/usr/bin/env python3
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODELS_DIR = ROOT / "models"
DEFAULT_MODEL = MODELS_DIR / "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
COMPOSE_FILE = ROOT / "docker-compose.yml"
UI_DIR = ROOT / "ui" / "chat-app"

checks = []


def add_check(name, ok, detail):
    checks.append((name, ok, detail))


add_check("docker", shutil.which("docker") is not None, "docker CLI available")
add_check("node", shutil.which("node") is not None, "node runtime available")
add_check("npm", shutil.which("npm") is not None, "npm CLI available")
add_check("compose", COMPOSE_FILE.exists(), f"compose file at {COMPOSE_FILE}")
add_check("ui", UI_DIR.exists(), f"ui directory at {UI_DIR}")
add_check("models_dir", MODELS_DIR.exists(), f"models directory at {MODELS_DIR}")
add_check("default_model", DEFAULT_MODEL.exists(), f"default GGUF model at {DEFAULT_MODEL}")

failed = False

for name, ok, detail in checks:
    status = "ok" if ok else "missing"
    print(f"{name}: {status} - {detail}")
    if ok is False:
        failed = True

if failed:
    print("preflight failed")
    sys.exit(1)

print("preflight passed")
