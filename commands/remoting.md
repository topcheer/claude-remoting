---
description: "Start a public web terminal via Cloudflare tunnel"
argument-hint: "[port] [--auth user:pass]"
---

# /remoting - Public Web Terminal

Start Claude Code as a web terminal accessible from the internet using Cloudflare's temporary tunnel. The web terminal will show the full Claude Code interface and allow you to continue your conversation.

## How it works:

This script:
1. Starts a Node.js server that launches Claude Code in a pseudo-terminal
2. Creates a WebSocket connection for real-time bidirectional communication
3. Uses xterm.js in the browser to render the terminal
4. Exposes it via Cloudflare tunnel for public access

## Steps:

1. Run the remoting script with optional arguments:

$ "${CLAUDE_PLUGIN_ROOT}/scripts/remoting.sh" $ARGUMENTS

2. If the script outputs MISSING:<tool>:<install-command>, install the missing dependency and re-run.

3. If the script outputs OK, display the tunnel URL prominently:

```
╔═══════════════════════════════════════════════════╗
║  Web Terminal is live!                           ║
║                                                   ║
║  URL: <URL from output>                          ║
║  Port: <HTTP_PORT from output>                   ║
║                                                   ║
║  Stop: /remoting-stop                             ║
╚═══════════════════════════════════════════════════╝
```

4. If the script outputs ERROR:, inform the user about the error and suggest troubleshooting steps.

## Important Notes:
- The tunnel URL is temporary and changes each time you start
- Anyone with the URL can access the terminal
- This starts a NEW Claude Code session - your current conversation history will be loaded automatically by Claude Code
- The services run as background processes on this machine
- To stop, use /remoting-stop

## Requirements:
- Node.js (for the WebSocket server)
- npm (comes with Node.js)
- cloudflared (for the tunnel)
