import { spawn } from 'node-pty';
import { WebSocketServer } from 'ws';
import express from 'express';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { createServer } from 'http';
import { randomUUID } from 'crypto';
import { execFile } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const PORT = process.env.PORT || 7681;
const SESSION_ID = randomUUID();
const clients = new Set();

// ============================================================
// HTTP + WebSocket Server
// ============================================================
const app = express();
app.use(express.static(join(__dirname, 'public')));
const server = createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

// ============================================================
// WebSocket: Auth + Input forwarding
// ============================================================
wss.on('connection', (ws) => {
  let authenticated = false;
  const authTimeout = setTimeout(() => {
    if (!authenticated) {
      ws.close(4001, 'Auth timeout');
    }
  }, 5000);

  ws.on('message', (message) => {
    try {
      const msg = JSON.parse(message);

      // First message must be auth
      if (!authenticated) {
        if (msg.type === 'auth' && msg.sessionId === SESSION_ID) {
          authenticated = true;
          clearTimeout(authTimeout);
          clients.add(ws);
          ws.send(JSON.stringify({ type: 'auth_ok' }));
        } else {
          ws.close(4003, 'Invalid session');
        }
        return;
      }

      // After auth: forward input to PTY
      if (msg.type === 'input') {
        ptyProcess.write(msg.data);
      }

      // Handle resize from browser → update PTY size
      if (msg.type === 'resize') {
        ptyCols = msg.cols || 120;
        ptyRows = msg.rows || 36;
        try { ptyProcess.resize(ptyCols, ptyRows); } catch (_) {}
      }
    } catch (_) {
      // Ignore malformed messages
    }
  });

  ws.on('close', () => {
    clients.delete(ws);
    clearTimeout(authTimeout);
  });

  ws.on('error', () => {
    clients.delete(ws);
    clearTimeout(authTimeout);
  });
});

// ============================================================
// Singleton PTY: wraps claude
// ============================================================
// Track the largest viewport so PTY matches browser
let ptyCols = 120;
let ptyRows = 36;

const ptyProcess = spawn('claude', [], {
  name: 'xterm-256color',
  cols: ptyCols,
  rows: ptyRows,
  cwd: process.env.CLAUDE_CWD || process.cwd(),
  env: { ...process.env },
});

// PTY output → local terminal + all WebSocket clients
ptyProcess.onData((data) => {
  // Local terminal
  process.stdout.write(data);

  // Broadcast to all authenticated browser clients
  const msg = JSON.stringify({ type: 'data', data });
  for (const client of clients) {
    if (client.readyState === 1) { // WebSocket.OPEN
      client.send(msg);
    }
  }
});

// PTY exit → cleanup and exit
ptyProcess.onExit(({ exitCode }) => {
  for (const client of clients) {
    if (client.readyState === 1) {
      client.send(JSON.stringify({ type: 'exit', code: exitCode }));
      client.close();
    }
  }
  cleanup();
  process.exit(exitCode || 0);
});

// ============================================================
// Local terminal: stdin raw mode → PTY
// ============================================================
if (process.stdin.isTTY) {
  process.stdin.setRawMode(true);
  process.stdin.resume();
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', (data) => {
    ptyProcess.write(data);
  });
}

// Note: PTY resize is controlled by browser viewport, not local terminal

// ============================================================
// Orphan detection: if parent dies, we should exit too
// ============================================================
setInterval(() => {
  try {
    process.kill(process.ppid, 0);
  } catch {
    // Parent process is dead — we're an orphan
    ptyProcess.kill();
    cleanup();
    process.exit(0);
  }
}, 2000);

// ============================================================
// Signal handlers
// ============================================================
process.on('SIGINT', () => {
  ptyProcess.kill('SIGINT');
});

process.on('SIGTERM', () => {
  ptyProcess.kill();
  cleanup();
  process.exit(0);
});

// ============================================================
// Cleanup
// ============================================================
function cleanup() {
  try { process.stdin.setRawMode(false); } catch (_) {}
  process.stdin.pause();
  for (const client of clients) {
    client.close();
  }
  server.close();
}

// ============================================================
// Start server + auto-open browser
// ============================================================
server.listen(PORT, () => {
  const url = `http://localhost:${PORT}?session=${SESSION_ID}`;

  // Show URL in terminal (clickable in most modern terminals)
  process.stderr.write(`\n[remoting] ${url}\n\n`);

  // Auto-open browser
  const cmd = process.platform === 'darwin' ? 'open' : 'xdg-open';
  execFile(cmd, [url], (err) => {
    if (err) {
      process.stderr.write(`[remoting] Could not auto-open browser. Open manually: ${url}\n`);
    }
  });
});
