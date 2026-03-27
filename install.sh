#!/bin/bash

set -e

echo "Installing Edge LLM System..."

echo "Updating system..."
sudo apt update

echo "Installing dependencies..."
sudo apt install -y docker.io docker-compose git nodejs npm python3-pip

echo "Enabling Docker..."
sudo systemctl enable docker
sudo systemctl start docker

echo "Installing Python packages..."
python3 -m pip install --upgrade pip
python3 -m pip install fastapi uvicorn httpx

echo "Installing UI dependencies..."
cd ui/chat-app
npm install
cd ../../

mkdir -p models

echo "Setup complete!"
echo ""
echo "Place your GGUF model in: ./models"
echo "Expected filename: tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
echo ""
echo "To start the system run:"
echo "docker compose up"
echo ""
echo "Then open:"
echo "http://localhost:5173"
