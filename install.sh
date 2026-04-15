#!/usr/bin/env sh
# Configures Claude Code CLI to use VietAPI
set -e

# Configuration (auto-populated by server or passed via env)
ENDPOINT_URL="${VIETCODE_BASE_URL:-https://vietapi.tech}"
API_KEY="${VIETCODE_API_KEY:-}"
HAIKU_MODEL="gpt-5.2"
OPUS_MODEL="gpt-5.3-codex"
SONNET_MODEL="gpt-5.4"

# Colors
RED=$(printf '\033[0;31m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[1;33m')
BLUE=$(printf '\033[0;34m')
CYAN=$(printf '\033[0;36m')
NC=$(printf '\033[0m')

echo "${CYAN}================================${NC}"
echo "${CYAN}  VietCode Configuration${NC}"
echo "${CYAN}  Claude Code × VietAPI${NC}"
echo "${CYAN}================================${NC}"
echo ""

# Prompt for API key if not provided
if [ -z "$API_KEY" ]; then
  if [ ! -r /dev/tty ]; then
    echo "${RED}Error: cannot prompt for API key because /dev/tty is not available.${NC}"
    echo "Please rerun with VIETCODE_API_KEY set, for example:"
    echo "  ${BLUE}VIETCODE_API_KEY=your_key curl -fsSL https://raw.githubusercontent.com/blanatole/vietcode/main/install.sh | sh${NC}"
    exit 1
  fi

  printf "Enter your VietAPI key: " > /dev/tty
  stty -echo < /dev/tty
  trap 'stty echo < /dev/tty' EXIT
  read -r API_KEY < /dev/tty
  stty echo < /dev/tty
  trap - EXIT
  printf '\n' > /dev/tty
fi

if [ -z "$API_KEY" ]; then
  echo "${RED}Error: API key cannot be empty.${NC}"
  exit 1
fi

# Mask API key for display
MASKED_KEY=$(echo "$API_KEY" | cut -c 1-10)
echo "Endpoint URL: ${GREEN}$ENDPOINT_URL${NC}"
echo "API Key:      ${GREEN}${MASKED_KEY}...${NC}"
echo ""

# Function to backup file
backup_file() {
    f_path="$1"
    if [ -f "$f_path" ]; then
        cp "$f_path" "${f_path}.backup.$(date +%Y%m%d%H%M%S)"
        echo "${YELLOW}  Backed up: $f_path${NC}"
    fi
}

# Function to remove existing VietCode/Claude vars from shell rc file
remove_claude_vars() {
    f_path="$1"
    if [ -f "$f_path" ]; then
        sed '/^export ANTHROPIC_/d' "$f_path" > "${f_path}.tmp" && mv "${f_path}.tmp" "$f_path"
        sed '/^# Claude Code configuration/d' "$f_path" > "${f_path}.tmp" && mv "${f_path}.tmp" "$f_path"
        sed '/^# VietCode configuration/d' "$f_path" > "${f_path}.tmp" && mv "${f_path}.tmp" "$f_path"
        sed '/^# Claudible configuration/d' "$f_path" > "${f_path}.tmp" && mv "${f_path}.tmp" "$f_path"
        rm -f "${f_path}.tmp" 2>/dev/null || true
    fi
}

# Function to add Claude Code env vars to shell rc file
add_claude_vars() {
    f_path="$1"
    url="$2"
    key="$3"

    remove_claude_vars "$f_path"

    echo "" >> "$f_path"
    echo "# VietCode configuration" >> "$f_path"
    echo "export ANTHROPIC_BASE_URL=\"$url\"" >> "$f_path"
    echo "export ANTHROPIC_AUTH_TOKEN=\"$key\"" >> "$f_path"
}

# Update ~/.claude/settings.json using jq
update_settings_json() {
    settings_file="$HOME/.claude/settings.json"
    url="$1"
    key="$2"

    mkdir -p "$HOME/.claude"

    # Check for jq
    if ! command -v jq >/dev/null 2>&1; then
        echo ""
        echo "${RED}Error: jq is required but not installed.${NC}"
        echo ""
        echo "Please install jq first:"
        echo "  ${BLUE}macOS:${NC}        brew install jq"
        echo "  ${BLUE}Ubuntu/Debian:${NC} sudo apt-get install -y jq"
        echo "  ${BLUE}Fedora/RHEL:${NC}   sudo dnf install -y jq"
        echo "  ${BLUE}Arch Linux:${NC}    sudo pacman -S jq"
        echo ""
        echo "Then run this installer again."
        exit 1
    fi

    # If file doesn't exist, create empty object
    if [ ! -f "$settings_file" ]; then
        echo '{}' > "$settings_file"
    else
        backup_file "$settings_file"
    fi

    # Merge settings using jq
    tmp_file=$(mktemp)

    jq --arg url "$url" --arg key "$key" \
       --arg haiku "$HAIKU_MODEL" --arg opus "$OPUS_MODEL" --arg sonnet "$SONNET_MODEL" '
        .env.ANTHROPIC_BASE_URL = $url |
        .env.ANTHROPIC_API_KEY = $key |
        .env.ANTHROPIC_AUTH_TOKEN = $key |
        .modelOverrides."claude-sonnet-4-6" = $sonnet |
        .modelOverrides."claude-opus-4-6" = $opus |
        .modelOverrides."claude-haiku-4-5" = $haiku |
        .disableLoginPrompt = true
    ' "$settings_file" > "$tmp_file" && mv "$tmp_file" "$settings_file"
}

# Configure shell rc files
configure_file() {
    rc_file="$1"
    echo "  Processing $rc_file"
    backup_file "$rc_file"
    add_claude_vars "$rc_file" "$ENDPOINT_URL" "$API_KEY"
    echo "  ${GREEN}✓ Updated $rc_file${NC}"
}

echo "${BLUE}Configuring shell environment...${NC}"

SHELL_FOUND=0
if [ -f "$HOME/.bashrc" ]; then
    configure_file "$HOME/.bashrc"
    SHELL_FOUND=1
fi
if [ -f "$HOME/.zshrc" ]; then
    configure_file "$HOME/.zshrc"
    SHELL_FOUND=1
fi

if [ "$SHELL_FOUND" -eq 0 ]; then
    echo "${YELLOW}  No .bashrc or .zshrc found, creating .zshrc${NC}"
    touch "$HOME/.zshrc"
    configure_file "$HOME/.zshrc"
fi

echo ""
echo "${BLUE}Configuring Claude Code settings...${NC}"
update_settings_json "$ENDPOINT_URL" "$API_KEY"
echo "  ${GREEN}✓ Updated ~/.claude/settings.json${NC}"

# Also save VietCode's own config
VIETCODE_CONFIG_DIR="$HOME/.vietcode"
mkdir -p "$VIETCODE_CONFIG_DIR"

cat > "$VIETCODE_CONFIG_DIR/config.json" << EOF
{
  "api_key": "$API_KEY",
  "base_url": "$ENDPOINT_URL",
  "model": "gpt-5.4",
  "identity": "You are an expert AI coding assistant. You are helpful, precise, and have full access to tools to improve the codebase.",
  "model_mapping": {
    "claude-sonnet-4-6": "gpt-5.4",
    "claude-opus-4-6": "gpt-5.3-codex",
    "claude-haiku-4-5": "gpt-5.2",
    "sonnet 4.6": "gpt-5.4",
    "opus 4.6": "gpt-5.3-codex",
    "haiku 4.5": "gpt-5.2",
    "gpt-5.4": "gpt-5.4",
    "gpt-5.3-codex": "gpt-5.3-codex",
    "gpt-5.2": "gpt-5.2"
  }
}
EOF
echo "  ${GREEN}✓ Updated ~/.vietcode/config.json${NC}"

# Optionally install VietCode CLI tooling
INSTALL_DIR="${VIETCODE_INSTALL_DIR:-$HOME/.vietcode-cli}"
REPO_URL="${VIETCODE_REPO_URL:-https://github.com/blanatole/vietcode.git}"

if command -v git >/dev/null 2>&1 && command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    echo ""
    echo "${BLUE}Installing VietCode CLI...${NC}"

    if [ -d "$INSTALL_DIR" ]; then
        echo "  ${YELLOW}Updating existing installation at $INSTALL_DIR${NC}"
        cd "$INSTALL_DIR" && git pull --ff-only 2>/dev/null || true
    else
        git clone "$REPO_URL" "$INSTALL_DIR" 2>/dev/null || true
    fi

    if [ -d "$INSTALL_DIR" ]; then
        cd "$INSTALL_DIR"
        npm install --omit=dev 2>/dev/null
        npm link 2>/dev/null || true
        echo "  ${GREEN}✓ VietCode CLI installed${NC}"
    fi
else
    echo ""
    echo "${YELLOW}Skipping VietCode CLI install (git/node/npm not all available).${NC}"
    echo "${YELLOW}You can still use Claude Code directly with the configured settings.${NC}"
fi

# Check for Claude Code CLI
if ! command -v claude >/dev/null 2>&1; then
    echo ""
    echo "${YELLOW}Claude Code CLI not found in PATH.${NC}"
    echo "To install it, run:"
    echo "  ${BLUE}npm install -g @anthropic-ai/claude-code${NC}"
fi

echo ""
echo "${GREEN}================================${NC}"
echo "${GREEN}  Configuration Complete!${NC}"
echo "${GREEN}================================${NC}"
echo ""
echo "Claude Code is now configured to use VietAPI:"
echo "  Endpoint:  ${BLUE}$ENDPOINT_URL${NC}"
echo "  API Key:   ${BLUE}${MASKED_KEY}...${NC}"
echo "  Models:"
echo "    Sonnet → ${CYAN}$SONNET_MODEL${NC}"
echo "    Opus   → ${CYAN}$OPUS_MODEL${NC}"
echo "    Haiku  → ${CYAN}$HAIKU_MODEL${NC}"
echo ""
echo "${YELLOW}Next steps:${NC}"
echo "  1. Restart your terminal or run: ${BLUE}source ~/.zshrc${NC}"
echo "  2. Run: ${BLUE}claude${NC}"
echo "     Or:  ${BLUE}vietcode${NC}"
echo ""
