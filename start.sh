#!/usr/bin/env bash
set -e

# Start the FastAPI backend in the background, internal-only on 8000
cd /app
uvicorn Backend.main:app --host 127.0.0.1 --port 8000 &
BACKEND_PID=$!

# Start the Next.js frontend in the foreground, on the port HF Spaces expects
cd /app/Frontend
PORT="${PORT:-7860}" npm run start -- -p "${PORT:-7860}" &
FRONTEND_PID=$!

# If either process dies, stop the container so HF Spaces reports the failure
wait -n "$BACKEND_PID" "$FRONTEND_PID"
