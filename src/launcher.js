import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawn, spawnSync } from 'node:child_process';
import { startProxy } from './proxy.js';
import { getEffectiveConfig } from './config.js';
import chalk from 'chalk';

function getExtensionBinaryCandidates() {
  const home = os.homedir();
  const platform = process.platform;
  const extensionRoots = [
    path.join(home, '.vscode', 'extensions'),
    path.join(home, '.vscode-insiders', 'extensions'),
    path.join(home, '.cursor', 'extensions')
  ];

  const candidates = [];

  for (const root of extensionRoots) {
    if (!fs.existsSync(root)) continue;

    const entries = fs.readdirSync(root, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isDirectory() || !entry.name.startsWith('anthropic.claude-code-')) continue;

      const base = path.join(root, entry.name, 'resources', 'native-binary');
      candidates.push(path.join(base, 'claude'));
      if (platform === 'win32') {
        candidates.push(path.join(base, 'claude.exe'));
      }
    }
  }

  return candidates.filter((candidate) => fs.existsSync(candidate)).sort().reverse();
}

function getClaudeInPath() {
  const command = process.platform === 'win32' ? 'where' : 'which';
  const result = spawnSync(command, ['claude'], { encoding: 'utf8' });

  if (result.status === 0) {
    const firstLine = result.stdout.split(/\r?\n/).map((line) => line.trim()).find(Boolean);
    if (firstLine) {
      return firstLine;
    }
  }

  return null;
}

export function inspectClaudeBinary() {
  if (process.env.CLAUDE_CODE_BIN) {
    return {
      source: 'CLAUDE_CODE_BIN',
      path: process.env.CLAUDE_CODE_BIN,
      exists: fs.existsSync(process.env.CLAUDE_CODE_BIN)
    };
  }

  const pathBinary = getClaudeInPath();
  if (pathBinary) {
    return {
      source: 'PATH',
      path: pathBinary,
      exists: true
    };
  }

  const extensionCandidates = getExtensionBinaryCandidates();
  if (extensionCandidates.length > 0) {
    return {
      source: 'extension',
      path: extensionCandidates[0],
      exists: true,
      candidates: extensionCandidates
    };
  }

  return {
    source: 'unresolved',
    path: 'claude',
    exists: false,
    candidates: []
  };
}

function resolveClaudeBinary() {
  const inspection = inspectClaudeBinary();
  return inspection.path;
}

export async function run() {
  const config = getEffectiveConfig();

  if (!config.api_key) {
    console.log(chalk.red('Error: API key is not set.'));
    console.log(chalk.yellow('Run "vietcode config --key YOUR_API_KEY" to set your credentials.'));
    process.exit(1);
  }

  const PROXY_PORT = 7888;
  const proxy = startProxy(PROXY_PORT);

  console.log(chalk.cyan('Starting Claude Code via VietCode...'));

  const claudeExe = resolveClaudeBinary();
  const env = {
    ...process.env,
    ANTHROPIC_BASE_URL: `http://localhost:${PROXY_PORT}/v1`,
    ANTHROPIC_API_KEY: config.api_key,
    VIETCODE_PROXY_PORT: PROXY_PORT.toString()
  };

  delete env.ANTHROPIC_AUTH_TOKEN;
  delete env.CLAUDE_CODE_OAUTH_TOKEN;

  const args = ['--bare', ...process.argv.slice(2)];

  const child = spawn(claudeExe, args, {
    stdio: 'inherit',
    env
  });

  child.on('error', (err) => {
    proxy.close();
    console.error(chalk.red('Failed to start Claude Code binary.'));
    console.error(chalk.yellow('Set CLAUDE_CODE_BIN if Claude is not in PATH or not installed via a supported editor extension.'));
    console.error(err.message);
    process.exit(1);
  });

  child.on('close', (code) => {
    proxy.close();
    process.exit(code ?? 0);
  });

  process.on('SIGINT', () => {
    child.kill('SIGINT');
  });
}
