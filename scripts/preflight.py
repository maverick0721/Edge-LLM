#!/usr/bin/env python3
import os
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODELS_DIR = ROOT / "models"
DEFAULT_MODEL_NAME = "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
MODEL_NAME = os.getenv("EDGE_LLM_MODEL_FILE", DEFAULT_MODEL_NAME)
MODEL_PATH = MODELS_DIR / MODEL_NAME
COMPOSE_FILE = ROOT / "docker-compose.yml"
PROFILE_DIR = ROOT / "profiles"
UI_DIR = ROOT / "ui" / "chat-app"
UI_DIST_DIR = UI_DIR / "dist"
PROFILE = os.getenv("EDGE_LLM_PROFILE", "lite")

checks = []


def add_check(name, ok, detail):
    checks.append((name, ok, detail))


add_check("docker", shutil.which("docker") is not None, "docker CLI available")
add_check("compose", COMPOSE_FILE.exists(), f"compose file at {COMPOSE_FILE}")
add_check("profiles", PROFILE_DIR.exists(), f"profile directory at {PROFILE_DIR}")
add_check("ui", UI_DIR.exists(), f"ui directory at {UI_DIR}")
add_check("models_dir", MODELS_DIR.exists(), f"models directory at {MODELS_DIR}")
add_check("selected_model", MODEL_PATH.exists(), f"selected GGUF model at {MODEL_PATH}")

# Helpful but optional checks.
add_check("node", shutil.which("node") is not None, "node runtime available for local UI rebuilds")
add_check("npm", shutil.which("npm") is not None, "npm CLI available for local UI rebuilds")
add_check("ui_dist", UI_DIST_DIR.exists(), f"built UI directory at {UI_DIST_DIR}")

failed = False

print(f"profile: {PROFILE}")

for name, ok, detail in checks:
    optional = name in {"node", "npm", "ui_dist"}
    status = "ok" if ok else ("optional-missing" if optional else "missing")
    print(f"{name}: {status} - {detail}")
    if ok is False and optional is False:
        failed = True

if failed:
    print("preflight failed")
    sys.exit(1)

print("preflight passed")
