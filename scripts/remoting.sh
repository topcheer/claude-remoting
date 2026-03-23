#!/bin/bash

# remoting.sh - Start a public web terminal via Cloudflare tunnel
# Usage: remoting.sh [port] [--auth user:pass]

set -euo pipefail

PORT=""
AUTH=""
SHELL_CMD="${SHELL:-zsh}"

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --auth=*)
      AUTH="${arg#*=}"
      ;;
    --shell=*)
      SHELL_CMD="${arg#*=}"
      ;;
    --help|-h)
      echo "remoting - Public Web Terminal via Cloudflare Tunnel"
      echo ""
      echo "Usage: remoting.sh [port] [--auth user:pass] [--shell /bin/bash]"
      echo ""
      echo "Options:"
      echo "  port              Local port for ttyd (default: auto-select from 7681)"
      echo "  --auth user:pass  Enable basic authentication"
      echo "  --shell PATH      Shell to use (default: current shell)"
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
PORT="${PORT:-7681}"

# Check cloudflared
if ! command -v cloudflared &>/dev/null; then
  echo "MISSING:cloudflared:brew install cloudflared"
  exit 1
fi

# Check ttyd
if ! command -v ttyd &>/dev/null; then
  echo "MISSING:ttyd:brew install tsl0922/ttyd/ttyd"
  exit 1
fi

# Check shell exists
if [ ! -x "$SHELL_CMD" ]; then
  echo "ERROR: Shell not found: $SHELL_CMD"
  exit 1
fi

# Find available port
MAX_ATTEMPTS=100
while lsof -i :"$PORT" &>/dev/null 2>&1; do
  PORT=$((PORT + 1))
  MAX_ATTEMPTS=$((MAX_ATTEMPTS - 1))
  if [ "$MAX_ATTEMPTS" -le 0 ]; then
    echo "ERROR: Could not find an available port"
    exit 1
  fi
done

# Build ttyd arguments
TTYD_ARGS=("-p" "$PORT" "-W" "--title-format" "Remoting Terminal" "--writable")

if [ -n "$AUTH" ]; then
  TTYD_ARGS+=("-c" "$AUTH")
fi

TTYD_ARGS+=("$SHELL_CMD")

# Start ttyd
ttyd "${TTYD_ARGS[@]}" &
TTYD_PID=$!

# Wait for ttyd to start
sleep 1

if ! kill -0 "$TTYD_PID" 2>/dev/null; then
  echo "ERROR: Failed to start ttyd on port $PORT"
  exit 1
fi

# Start cloudflared and capture output
TMPFILE=$(mktemp)
trap "rm -f '$TMPFILE'" EXIT

cloudflared tunnel --url "http://localhost:$PORT" > "$TMPFILE" 2>&1 &
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
    kill "$TTYD_PID" 2>/dev/null
    exit 1
  fi
  sleep 1
done

if [ -z "$URL" ]; then
  echo "ERROR: Timed out waiting for Cloudflare tunnel URL"
  kill "$TTYD_PID" "$CF_PID" 2>/dev/null
  exit 1
fi

# Save state for cleanup
cat > /tmp/remoting-pids <<EOF
TTYD_PID=$TTYD_PID
CF_PID=$CF_PID
PORT=$PORT
URL=$URL
STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

# Output results in structured format
cat <<EOF
OK
URL=$URL
PORT=$PORT
TTYD_PID=$TTYD_PID
CF_PID=$CF_PID
AUTH=${AUTH:-none}
SHELL=$SHELL_CMD
EOF
