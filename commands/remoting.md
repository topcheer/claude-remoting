---
description: "Mirror your Claude Code terminal in a browser for remote viewing and interaction"
argument-hint: "[port]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/remoting.sh:*)"]
---

# /remoting - Browser Terminal Mirror

Execute the remoting script to launch a browser mirror of this terminal:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/remoting.sh" $ARGUMENTS
```

If the output contains `MISSING:`, tell the user which dependency is missing and how to install it, then stop.
If the output contains `ERROR:`, show the error to the user and suggest troubleshooting steps.
Otherwise, the script will print local and public URLs — share these with anyone who needs to view the terminal.

To stop the session: press Ctrl+C in the terminal, or type /exit in Claude Code.
