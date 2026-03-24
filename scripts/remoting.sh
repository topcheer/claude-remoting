#!/bin/bash

# remoting.sh - Start Claude Code as a public web terminal via Cloudflare tunnel
# Usage: remoting.sh [port] [--auth user:pass]

set -euo pipefail

PORT=""
AUTH=""
HTTP_PORT=7681
WS_PORT=7682

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --auth=*)
      AUTH="${arg#*=}"
      ;;
    --help|-h)
      echo "remoting - Public Web Terminal via Cloudflare Tunnel"
      echo ""
      echo "Usage: remoting.sh [port] [--auth user:pass]"
      echo ""
      echo "Options:"
      echo "  port              Local port for web interface (default: 7681)"
      echo "  --auth user:pass  Enable basic authentication (not yet implemented)"
      echo "  -h, --help        Show this help"
      exit 0
      ;;
    *)
      if [[ "$arg" =~ ^[0-9]+$ ]] && [ -z "$PORT" ]; then
        PORT="$arg"
      else
        echo "Unknown argument: $arg" >&2
        exit 1
      fi
      ;;
  esac
done

# Default port
HTTP_PORT="${PORT:-7681}"
WS_PORT=$((HTTP_PORT + 1))

# Check Node.js
if ! command -v node &>/dev/null; then
  echo "MISSING:node:Visit https://nodejs.org/ to install"
  exit 1
fi

# Check npm
if ! command -v npm &>/dev/null; then
  echo "MISSING:npm:Visit https://nodejs.org/ to install"
  exit 1
fi

# Check cloudflared
if ! command -v cloudflared &>/dev/null; then
  echo "MISSING:cloudflared:brew install cloudflared"
  exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")/server"

# Check if server dependencies are installed
if [ ! -d "$SERVER_DIR/node_modules" ]; then
  echo "Installing server dependencies..."
  (cd "$SERVER_DIR" && npm install) || {
    echo "ERROR: Failed to install dependencies"
    exit 1
  }
fi

# Find available HTTP port
MAX_ATTEMPTS=100
TEST_PORT=$HTTP_PORT
while lsof -i :"$TEST_PORT" &>/dev/null 2>&1; do
  TEST_PORT=$((TEST_PORT + 1))
  MAX_ATTEMPTS=$((MAX_ATTEMPTS - 1))
  if [ "$MAX_ATTEMPTS" -le 0 ]; then
    echo "ERROR: Could not find an available port"
    exit 1
  fi
done
HTTP_PORT=$TEST_PORT
WS_PORT=$((HTTP_PORT + 1))

# Set environment variables
export PORT=$HTTP_PORT
export WS_PORT=$WS_PORT

# Start Node.js server
cd "$SERVER_DIR"
node server.js &
SERVER_PID=$!

# Wait for server to start
sleep 2

if ! kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "ERROR: Failed to start server"
  exit 1
fi

# Start cloudflared and capture output
TMPFILE=$(mktemp)
trap "rm -f '$TMPFILE'" EXIT

cloudflared tunnel --url "http://localhost:$HTTP_PORT" > "$TMPFILE" 2>&1 &
CF_PID=$!

# Wait for tunnel URL (up to 30 seconds)
URL=""
for i in $(seq 1 30); do
  URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$TMPFILE" | head -1)
  if [ -n "$URL" ]; then
    break
  fi
  # Check if cloudflared is still running
  if ! kill -0 "$CF_PID" 2>/dev/null; then
    echo "ERROR: cloudflared exited unexpectedly"
    kill "$SERVER_PID" 2>/dev/null
    exit 1
  fi
  sleep 1
done

if [ -z "$URL" ]; then
  echo "ERROR: Timed out waiting for Cloudflare tunnel URL"
  kill "$SERVER_PID" "$CF_PID" 2>/dev/null
  exit 1
fi

# Save state for cleanup
cat > /tmp/remoting-pids <<EOF
SERVER_PID=$SERVER_PID
CF_PID=$CF_PID
HTTP_PORT=$HTTP_PORT
WS_PORT=$WS_PORT
URL=$URL
STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

# Output results in structured format
cat <<EOF
OK
URL=$URL
HTTP_PORT=$HTTP_PORT
WS_PORT=$WS_PORT
SERVER_PID=$SERVER_PID
CF_PID=$CF_PID
AUTH=${AUTH:-none}
EOF
