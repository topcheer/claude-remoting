---
description: "Start a public web terminal via Cloudflare tunnel"
argument-hint: "[port] [--auth user:pass] [--shell /bin/bash]"
---

# /remoting - Public Web Terminal

Start a web terminal accessible from the internet using Cloudflare's temporary tunnel. Anyone with the URL can interact with your terminal through a browser.

## Steps:

1. Run the remoting script:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/remoting.sh" $ARGUMENTS
```

2. If the script outputs `MISSING:<tool>:<install-command>`, install the missing dependency by running the install command in a separate Bash call, then re-run the script.

3. If the script outputs `OK`, display the tunnel URL prominently to the user in this format:

```
╔═══════════════════════════════════════════════════╗
║  Web Terminal is live!                           ║
║                                                   ║
║  URL: <URL from output>                          ║
║  Port: <PORT from output>                        ║
║                                                   ║
║  Stop: /remoting-stop                             ║
╚═══════════════════════════════════════════════════╝
```

4. If the script outputs `ERROR:`, inform the user about the error and suggest troubleshooting steps.

## Important Notes:
- The tunnel URL is temporary and changes each time you start
- Anyone with the URL can access the terminal - use --auth for security
- The services run as background processes on this machine
- To stop, use /remoting-stop
