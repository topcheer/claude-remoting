---
description: "Stop the running remoting browser mirror session"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/remoting-stop.sh:*)"]
---

# /remoting-stop

Execute the stop script:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/remoting-stop.sh"
```

Then tell the user: The remoting session runs in the foreground. Press Ctrl+C to stop it, or type /exit in Claude Code.
