#!/bin/bash

# remoting.sh - Mirror a CLI tool in a browser (Claude plugin default: claude)
# Usage: remoting.sh [port] [--domain <domain>]

set -euo pipefail

PORT="7681"
DOMAIN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain)
      DOMAIN="$2"; shift 2 ;;
    *)
      PORT="$1"; shift ;;
  esac
done

# Check Node.js
if ! command -v node &>/dev/null; then
  echo "MISSING:node:Visit https://nodejs.org/ to install"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")/server"

# Install dependencies if needed
if [ ! -d "$SERVER_DIR/node_modules" ]; then
  echo "Installing dependencies..."
  (cd "$SERVER_DIR" && npm install)
fi

# Start server in foreground -- replaces this shell process
# Default command is 'claude' for the Claude plugin
# Save caller's cwd so the command starts in the right directory
REMOTE_CWD="$(pwd)"
cd "$SERVER_DIR"

# Build tunnel domain env var if specified
TUNNEL_ENV=""
if [ -n "$DOMAIN" ]; then
  TUNNEL_ENV="TUNNEL_DOMAIN=$DOMAIN"
fi

exec env PORT="$PORT" REMOTE_CMD="claude" REMOTE_ARGS="[]" REMOTE_CWD="$REMOTE_CWD" $TUNNEL_ENV node server.js
