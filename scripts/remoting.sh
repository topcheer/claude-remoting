#!/bin/bash

# remoting.sh - Start Claude Code as a public web terminal via Cloudflare tunnel
# Usage: remoting.sh [port]

set -euo pipefail

PORT="${1:-7681}"

# Check Node.js
if ! command -v node &>/dev/null; then
  echo "MISSING:node:Visit https://nodejs.org/ to install"
  exit 1
fi

# Check cloudflared
if ! command -v cloudflared &>/dev/null; then
  echo "MISSING:cloudflared:brew install cloudflared"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")/server"

# Install dependencies if needed
if [ ! -d "$SERVER_DIR/node_modules" ]; then
  echo "Installing dependencies..."
  (cd "$SERVER_DIR" && npm install)
fi

# Start server
cd "$SERVER_DIR"
PORT=$PORT WS_PORT=$((PORT + 1)) node server.js &
SERVER_PID=$!

sleep 2

if ! kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "ERROR: Failed to start server"
  exit 1
fi

# Start cloudflared (nohup to keep it running)
echo "Starting tunnel..."
nohup cloudflared tunnel --url "http://localhost:$PORT" > /tmp/cf.log 2>&1 &
CF_PID=$!

# Wait for URL with timeout
URL=""
for i in $(seq 1 20); do
  sleep 1
  URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cf.log 2>/dev/null | head -1)
  if [ -n "$URL" ]; then
    break
  fi
done

if [ -z "$URL" ]; then
  echo "ERROR: Failed to get tunnel URL"
  cat /tmp/cf.log
  kill "$SERVER_PID" 2>/dev/null
  exit 1
fi

# Save state
cat > /tmp/remoting-pids <<EOF
SERVER_PID=$SERVER_PID
CF_PID=$CF_PID
PORT=$PORT
URL=$URL
STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

# Output
cat <<EOF
OK
URL=$URL
PORT=$PORT
EOF
