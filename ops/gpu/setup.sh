#!/bin/bash
# One-shot setup on an NVIDIA 8GB host with Docker + Ollama already installed.
set -e
cd "$(dirname "$0")/../.."
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo cp ops/gpu/ollama-override.conf /etc/systemd/system/ollama.service.d/override.conf
sudo systemctl daemon-reload && sudo systemctl enable --now ollama && sudo systemctl restart ollama
ollama pull qwen2.5:7b
cp -n ops/gpu/docker-compose.override.gpu.yml docker-compose.override.yml
[ -f .env ] || cp ops/gpu/env.gpu-8gb.example .env
docker compose up -d --build
docker exec openshorts-backend nvidia-smi -L
docker exec openshorts-backend curl -sf http://host.docker.internal:11434/api/tags >/dev/null && echo "OK: backend -> Ollama"
# Clean renders older than 7 days
( crontab -l 2>/dev/null | grep -v openshorts-clean; echo "0 4 * * * find $(pwd)/output -type f -mtime +7 -delete # openshorts-clean" ) | crontab -
echo "Ready: http://<host>:5175 (put Nginx/Caddy + HTTPS in front)"
