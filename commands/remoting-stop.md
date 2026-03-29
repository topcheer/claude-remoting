---
description: "Remoting runs in foreground - use Ctrl+C to stop"
---

# /remoting-stop - Stop Browser Mirror

The remoting session runs in the foreground in your terminal.

## To stop:

- Press **Ctrl+C** in the terminal where `/remoting` is running
- Or exit Claude Code by typing `/exit` in the session

There is no background process to kill.

## Steps:

1. Run the stop script for confirmation:

$ "${CLAUDE_PLUGIN_ROOT}/scripts/remoting-stop.sh"

2. Inform the user: The remoting session runs in the foreground. Press Ctrl+C to stop it, or exit Claude Code normally.
