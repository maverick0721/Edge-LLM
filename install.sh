#!/bin/bash

echo "Installing Edge LLM System..."

echo "Updating system..."
sudo apt update

echo "Installing dependencies..."
sudo apt install -y docker.io docker-compose git nodejs npm

echo "Enabling Docker..."
sudo systemctl enable docker
sudo systemctl start docker

echo "Installing Python packages..."
pip install fastapi uvicorn httpx

echo "Installing UI dependencies..."
cd ui/chat-app
npm install
cd ../../

echo "Setup complete!"

echo ""
echo "To start the system run:"
echo "docker compose up"
echo ""
echo "Then open:"
echo "http://localhost:5173"
