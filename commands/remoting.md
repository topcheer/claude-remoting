---
description: "Mirror your Claude Code terminal in a browser for remote viewing and interaction"
argument-hint: "[port]"
---

# /remoting - Browser Terminal Mirror

Start a browser-accessible mirror of your Claude Code terminal. Your terminal continues to work normally while a browser tab shows the same content and can also interact.

## How it works:

1. Wraps Claude Code in a pseudo-terminal (PTY)
2. Starts a local HTTP/WebSocket server
3. Opens your browser with an authenticated session URL
4. Everything you see and type is mirrored to the browser in real-time

## Steps:

1. Run the remoting script with optional port argument:

$ "${CLAUDE_PLUGIN_ROOT}/scripts/remoting.sh" $ARGUMENTS

2. If the script outputs MISSING:<tool>:<install-command>, install the missing dependency and re-run.

3. If the script starts successfully, your browser will open automatically with the mirrored terminal.

4. If the script outputs ERROR:, inform the user about the error and suggest troubleshooting steps.

## Important Notes:

- Your terminal works exactly as before -- this is a non-destructive mirror
- The browser URL contains a unique session ID (UUID); only browsers with this URL can connect
- Local-only: accessible only from this machine (localhost)
- The session runs in foreground: exit Claude Code or press Ctrl+C to stop
- Multiple browser tabs can connect simultaneously

## Requirements:

- Node.js (for the WebSocket server)
- npm (comes with Node.js)
