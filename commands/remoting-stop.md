---
description: "Stop the running web terminal and Cloudflare tunnel"
---

# /remoting-stop - Stop Web Terminal

Stop the remoting web terminal and Cloudflare tunnel that were started with /remoting.

## Steps:

1. Run the stop script:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/remoting-stop.sh"
```

2. Display the result:
- If `STOPPED`: Inform the user the web terminal has been stopped and the tunnel is closed. If a URL was shown, mention it.
- If `NO_SESSION`: Inform the user there is no active remoting session.
- If `NOT_RUNNING`: Inform the user the processes were not found (may have been stopped already).
