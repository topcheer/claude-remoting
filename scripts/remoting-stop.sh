#!/bin/bash

# remoting-stop.sh - Stop the remoting web terminal and tunnel

set -euo pipefail

PID_FILE="/tmp/remoting-pids"

if [ ! -f "$PID_FILE" ]; then
  echo "NO_SESSION"
  exit 0
fi

# Source the PID file
source "$PID_FILE"

stopped=0

if [ -n "${TTYD_PID:-}" ] && kill -0 "$TTYD_PID" 2>/dev/null; then
  kill "$TTYD_PID" 2>/dev/null || true
  stopped=1
fi

if [ -n "${CF_PID:-}" ] && kill -0 "$CF_PID" 2>/dev/null; then
  kill "$CF_PID" 2>/dev/null || true
  stopped=1
fi

if [ "$stopped" -eq 1 ]; then
  rm -f "$PID_FILE"
  echo "STOPPED"
  if [ -n "${URL:-}" ]; then
    echo "URL=$URL"
  fi
else
  echo "NOT_RUNNING"
  rm -f "$PID_FILE"
fi
