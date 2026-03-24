#!/bin/bash

# remoting.sh - Start Claude Code as a public web terminal via localhost.run
# Usage: remoting.sh [port]

set -euo pipefail

PORT="${1:-7681}"

# Check Node.js
if ! command -v node &>/dev/null; then
  echo "MISSING:node:Visit https://nodejs.org/ to install"
  exit 1
fi

# Check ssh
if ! command -v ssh &>/dev/null; then
  echo "MISSING:ssh:Install openssh"
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
PORT=$PORT node server.js &
SERVER_PID=$!

sleep 2

if ! kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "ERROR: Failed to start server"
  exit 1
fi

# Start tunnel using localhost.run
echo "Starting tunnel..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -T -R 80:localhost:$PORT localhost.run 2>&1 | tee /tmp/ssh-tunnel.log &
SSH_PID=$!

# Wait for URL with timeout
URL=""
for i in $(seq 1 30); do
  sleep 1
  URL=$(grep -oE 'https://[a-z0-9.-]+\.lhr\.life' /tmp/ssh-tunnel.log 2>/dev/null | head -1)
  if [ -n "$URL" ]; then
    break
  fi
done

if [ -z "$URL" ]; then
  echo "ERROR: Failed to get tunnel URL"
  cat /tmp/ssh-tunnel.log
  kill "$SERVER_PID" 2>/dev/null
  kill "$SSH_PID" 2>/dev/null
  exit 1
fi

# Save state
cat > /tmp/remoting-pids <<EOF
SERVER_PID=$SERVER_PID
SSH_PID=$SSH_PID
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
