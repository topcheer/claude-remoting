#!/bin/bash

# remoting.sh - Mirror Claude Code terminal in a browser
# Usage: remoting.sh [port]

set -euo pipefail

PORT="${1:-7681}"

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
# server.js wraps claude in a PTY and mirrors to browser
# Save caller's cwd so claude starts in the right directory
CLAUDE_CWD="$(pwd)"
cd "$SERVER_DIR"
exec env PORT="$PORT" CLAUDE_CWD="$CLAUDE_CWD" node server.js
