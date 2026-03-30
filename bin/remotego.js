#!/usr/bin/env node

// remotego - Expose any CLI tool as a public web terminal
// Usage: remotego <command> [args...] [--port <port>] [--cwd <dir>]

import { spawn } from 'child_process';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Parse arguments: everything before flags is the command + its args
function parseArgs(argv) {
  const cmd = [];
  const flags = {};
  let i = 0;

  // Collect command and args until we hit a --flag
  while (i < argv.length && !argv[i].startsWith('--')) {
    cmd.push(argv[i]);
    i++;
  }

  // Parse flags
  while (i < argv.length) {
    const arg = argv[i];
    if (arg === '--port' && argv[i + 1]) {
      flags.port = argv[++i];
    } else if (arg === '--cwd' && argv[i + 1]) {
      flags.cwd = argv[++i];
    } else if (arg === '--domain' && argv[i + 1]) {
      flags.domain = argv[++i];
    } else if (arg === '--help' || arg === '-h') {
      printHelp();
      process.exit(0);
    } else if (arg === '--') {
      // Everything after -- is command args
      i++;
      while (i < argv.length) {
        cmd.push(argv[i]);
        i++;
      }
    } else {
      console.error(`Unknown option: ${arg}`);
      printHelp();
      process.exit(1);
    }
    i++;
  }

  return { cmd, flags };
}

function printHelp() {
  console.log(`
remotego - Expose any CLI tool as a public web terminal

Usage:
  remotego <command> [command-args...] [options]
  remotego --port 9000 --cwd ~/project vim
  remotego bash
  remotego python3 -i
  remotego claude

Options:
  --port <port>       Port to listen on (default: 7681)
  --cwd <dir>         Working directory for the command (default: current dir)
  --domain <domain>   Custom domain for localhost.run tunnel (default: random)
  --help, -h          Show this help message

Examples:
  remotego claude                        # Mirror Claude Code
  remotego vim                           # Mirror vim editor
  remotego bash                          # Mirror a bash shell
  remotego python3 -i                    # Mirror Python REPL
  remotego --port 9000 node              # Mirror Node.js REPL on port 9000
  remotego --domain myterm.localhost.run bash  # Custom tunnel domain
  remotego -- --flagged-arg              # Use -- to separate flags from command args
`);
}

const { cmd, flags } = parseArgs(process.argv.slice(2));

if (cmd.length === 0) {
  console.error('Error: No command specified.\n');
  printHelp();
  process.exit(1);
}

const serverDir = resolve(__dirname, '..', 'server');

// Build environment for server.js
const env = {
  ...process.env,
  REMOTE_CMD: cmd[0],
  REMOTE_ARGS: JSON.stringify(cmd.slice(1)),
  REMOTE_CWD: flags.cwd ? resolve(flags.cwd) : process.cwd(),
};

if (flags.port) {
  env.PORT = flags.port;
}

if (flags.domain) {
  env.TUNNEL_DOMAIN = flags.domain;
}

// Install server dependencies if needed
import { existsSync } from 'fs';
if (!existsSync(resolve(serverDir, 'node_modules'))) {
  console.log('Installing dependencies...');
  const install = spawn('npm', ['install'], { cwd: serverDir, stdio: 'inherit' });
  install.on('exit', (code) => {
    if (code !== 0) {
      console.error('Failed to install dependencies');
      process.exit(1);
    }
    startServer();
  });
} else {
  startServer();
}

function startServer() {
  const server = spawn('node', [resolve(serverDir, 'server.js')], {
    cwd: serverDir,
    env,
    stdio: 'inherit',
  });

  server.on('exit', (code) => {
    process.exit(code || 0);
  });

  process.on('SIGINT', () => {
    server.kill('SIGINT');
  });

  process.on('SIGTERM', () => {
    server.kill('SIGTERM');
  });
}
