# remotego

Expose any CLI tool as a public web terminal via tunnel.

## Install

```bash
npm install -g @zhanju/remotego
```

## Usage

```bash
remotego <command> [command-args...] [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--port <port>` | Port to listen on | `7681` |
| `--cwd <dir>` | Working directory for the command | Current directory |
| `--help, -h` | Show help | |

### Examples

```bash
# Mirror Claude Code
remotego claude

# Mirror a bash shell
remotego bash

# Mirror Python REPL
remotego python3 -i

# Mirror vim editor
remotego vim

# Custom port
remotego --port 9000 node

# Pass flags to the command (use -- to separate)
remotego -- git log --oneline
```

## How It Works

1. Spawns the given command in a PTY (pseudo-terminal)
2. Starts a local HTTP server with a browser-based terminal (xterm.js)
3. Creates a public tunnel via localhost.run for remote access
4. Opens the browser automatically

### Security

- A random session UUID is generated on each start
- The session ID is embedded in the URL — only holders of the URL can connect
- Clients must authenticate within 5 seconds of connecting

## Claude Code Plugin

This project also works as a Claude Code plugin. Install it and use the `/remoting` slash command to mirror your Claude Code session in a browser.

## License

MIT
