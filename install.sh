#!/usr/bin/env bash
set -e

REPO_URL="${VIETCODE_REPO_URL:-https://github.com/blanatole/vietcode.git}"
INSTALL_DIR="${VIETCODE_INSTALL_DIR:-$HOME/.vietcode-cli}"
API_KEY="${VIETCODE_API_KEY:-}"

if ! command -v git >/dev/null 2>&1; then
  printf 'Error: git is required. Please install git first.\n' >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  printf 'Error: Node.js is required. Please install Node.js 18+ first.\n' >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  printf 'Error: npm is required. Please install npm first.\n' >&2
  exit 1
fi

printf 'Installing VietCode from %s\n' "$REPO_URL"

rm -rf "$INSTALL_DIR"
git clone "$REPO_URL" "$INSTALL_DIR"

cd "$INSTALL_DIR"
npm install --omit=dev
npm link

if ! command -v claude >/dev/null 2>&1; then
  printf '\nClaude Code CLI not found. Installing @anthropic-ai/claude-code...\n'
  npm install -g @anthropic-ai/claude-code
fi

if [ -z "$API_KEY" ]; then
  if [ ! -r /dev/tty ]; then
    printf '\nError: cannot prompt for API key because /dev/tty is not available.\n' >&2
    printf 'Please rerun with VIETCODE_API_KEY set, for example:\n' >&2
    printf 'VIETCODE_API_KEY=your_key curl -fsSL https://raw.githubusercontent.com/blanatole/vietcode/main/install.sh | bash\n' >&2
    exit 1
  fi

  printf '\nEnter your VietCode API key: ' > /dev/tty
  stty -echo < /dev/tty
  trap 'stty echo < /dev/tty' EXIT
  read -r API_KEY < /dev/tty
  stty echo < /dev/tty
  trap - EXIT
  printf '\n' > /dev/tty
fi

if [ -z "$API_KEY" ]; then
  printf 'Error: API key cannot be empty.\n' >&2
  exit 1
fi

vietcode config --key "$API_KEY"
vietcode model gpt-5.4

printf '\nInstalled successfully.\n'
printf 'Install directory: %s\n' "$INSTALL_DIR"
printf 'Claude binary: %s\n' "$(command -v claude || printf 'not found')"
printf 'Default model: gpt-5.4\n'
printf 'Available models: gpt-5.4, gpt-5.3-codex, gpt-5.2\n'
printf 'Run: vietcode\n'
