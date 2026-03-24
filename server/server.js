import { spawn } from 'node-pty';
import { WebSocketServer } from 'ws';
import express from 'express';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { createServer } from 'http';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const PORT = process.env.PORT || 7681;

// Express app for static files
const app = express();
app.use(express.static(join(__dirname, 'public')));

// Create HTTP server with Express
const server = createServer(app);

// WebSocket server attached to HTTP server
const wss = new WebSocketServer({ server, path: '/ws' });

server.listen(PORT, () => {
  console.log(`HTTP server listening on port ${PORT}`);
  console.log(`WebSocket server available at ws://localhost:${PORT}/ws`);
});

wss.on('connection', (ws) => {
  console.log('Client connected');

  // Start Claude Code in a pseudo-terminal
  const ptyProcess = spawn('claude', [], {
    name: 'xterm-256color',
    cols: 80,
    rows: 24,
    cwd: process.cwd(),
    env: { ...process.env },
  });

  // Send pty output to WebSocket
  ptyProcess.on('data', (data) => {
    if (ws.readyState === ws.OPEN) {
      ws.send(JSON.stringify({ type: 'data', data: data.toString() }));
    }
  });

  // Handle pty exit
  ptyProcess.on('exit', (exitCode) => {
    console.log(`Claude Code exited with code ${exitCode}`);
    ws.send(JSON.stringify({ type: 'exit', code: exitCode }));
    ws.close();
  });

  // Handle WebSocket messages (user input)
  ws.on('message', (message) => {
    try {
      const msg = JSON.parse(message);
      if (msg.type === 'input') {
        ptyProcess.write(msg.data);
      } else if (msg.type === 'resize') {
        ptyProcess.resize(msg.cols, msg.rows);
      }
    } catch (err) {
      console.error('Failed to parse message:', err);
    }
  });

  ws.on('close', () => {
    console.log('Client disconnected');
    ptyProcess.kill();
  });

  ws.on('error', (err) => {
    console.error('WebSocket error:', err);
    ptyProcess.kill();
  });
});
