#!/bin/bash
# install.sh — cast-time installer
# Injects local time context into Claude Code at every session start.
# Only requirement: Claude Code CLI installed.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CT_VERSION="$(cat "${REPO_DIR}/VERSION" 2>/dev/null || echo "unknown")"

# Colors
if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
  C_BOLD='\033[1m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'
  C_RED='\033[0;31m'; C_RESET='\033[0m'
else
  C_BOLD='' C_GREEN='' C_YELLOW='' C_RED='' C_RESET=''
fi

_ok()   { printf "${C_GREEN}  [ok]${C_RESET} %s\n" "$*"; }
_warn() { printf "${C_YELLOW}  [warn]${C_RESET} %s\n" "$*" >&2; }
_fail() { printf "${C_RED}  [fail]${C_RESET} %s\n" "$*" >&2; exit 1; }
_step() { printf "\n${C_BOLD}%s${C_RESET}\n" "$*"; }

printf "\n${C_BOLD}cast-time v${CT_VERSION} installer${C_RESET}\n"
printf "══════════════════════════════════════\n"
printf "  Give Claude a clock.\n\n"

# Step 1: Prerequisites
_step "Checking prerequisites..."
if command -v claude &>/dev/null; then
  _ok "Claude Code CLI found"
else
  _warn "claude CLI not found — install from https://install.anthropic.com"
fi

CLAUDE_DIR="${HOME}/.claude"
mkdir -p "${CLAUDE_DIR}"
_ok "~/.claude/ ready"

# Step 2: Copy hook script
_step "Installing cast-time-context hook..."
SCRIPTS_DIR="${CLAUDE_DIR}/scripts"
mkdir -p "${SCRIPTS_DIR}"
if cp "${REPO_DIR}/scripts/cast-time-context-hook.sh" "${SCRIPTS_DIR}/cast-time-context-hook.sh"; then
  chmod 750 "${SCRIPTS_DIR}/cast-time-context-hook.sh"
  _ok "cast-time-context-hook.sh → ~/.claude/scripts/"
else
  _fail "Could not copy hook script"
fi

# Step 3: Merge hook settings
_step "Registering SessionStart hook..."
MERGE_SCRIPT="${REPO_DIR}/scripts/cast-time-merge-settings.sh"
if [ -f "$MERGE_SCRIPT" ]; then
  if [ "${1:-}" = "--yes" ] || [ "${CI:-}" = "true" ]; then
    bash "$MERGE_SCRIPT" --yes
  else
    bash "$MERGE_SCRIPT"
  fi
else
  _warn "Settings merge script not found — register hook manually in ~/.claude/settings.json"
fi

# Summary
printf "\n${C_BOLD}══════════════════════════════════════${C_RESET}\n"
printf "${C_GREEN}cast-time v${CT_VERSION} installed.${C_RESET}\n\n"
printf "  Hook:    ~/.claude/scripts/cast-time-context-hook.sh\n"
printf "  Config:  registered in ~/.claude/settings.json\n"
printf "\n${C_BOLD}Test it:${C_RESET}\n"
printf "  Open a new Claude Code session and look for ## Session Time Context\n\n"
