#!/usr/bin/env bash
set -e

REPO_URL="${VIETCODE_REPO_URL:-https://github.com/blanatole/vietcode.git}"
INSTALL_DIR="${VIETCODE_INSTALL_DIR:-$HOME/.vietcode-cli}"

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

printf '\nEnter your VietCode API key: '
stty -echo
read -r API_KEY
stty echo
printf '\n'

if [ -z "$API_KEY" ]; then
  printf 'Error: API key cannot be empty.\n' >&2
  exit 1
fi

vietcode config --key "$API_KEY"
vietcode model gpt-5.4

printf '\nInstalled successfully.\n'
printf 'Install directory: %s\n' "$INSTALL_DIR"
printf 'Default model: gpt-5.4\n'
printf 'Available models: gpt-5.4, gpt-5.3-codex, gpt-5.2\n'
printf 'Run: vietcode\n'
