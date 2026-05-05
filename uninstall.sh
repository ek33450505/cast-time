#!/bin/bash
# uninstall.sh — cast-time uninstaller
# Removes the cast-time-context hook script and settings entry.
set -euo pipefail

# Colors
if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
  C_BOLD='\033[1m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_RESET='\033[0m'
else
  C_BOLD='' C_GREEN='' C_YELLOW='' C_RESET=''
fi

_ok()   { printf "${C_GREEN}  [ok]${C_RESET} %s\n" "$*"; }
_warn() { printf "${C_YELLOW}  [warn]${C_RESET} %s\n" "$*" >&2; }
_step() { printf "\n${C_BOLD}%s${C_RESET}\n" "$*"; }

printf "\n${C_BOLD}cast-time uninstaller${C_RESET}\n"
printf "══════════════════════════════════════\n\n"

CLAUDE_DIR="${HOME}/.claude"

# Remove hook script
_step "Removing hook script..."
if rm -f "${CLAUDE_DIR}/scripts/cast-time-context-hook.sh"; then
  _ok "removed cast-time-context-hook.sh"
fi

# Remove hook from settings.json
_step "Removing cast-time-context entry from settings.json..."
SETTINGS="${CLAUDE_DIR}/settings.json"
if [ ! -f "$SETTINGS" ]; then
  _warn "settings.json not found — nothing to update"
elif ! command -v python3 &>/dev/null; then
  _warn "python3 not available — remove cast-time-context entry manually from ~/.claude/settings.json"
else
  # Backup first
  cp "$SETTINGS" "${SETTINGS}.bak"
  _ok "Backup saved to ${SETTINGS}.bak"

  SETTINGS="$SETTINGS" python3 -c '
import json, os, sys, tempfile

settings_path = os.environ["SETTINGS"]
with open(settings_path) as f:
    s = json.load(f)
hooks = s.get("hooks", {})
for event in list(hooks.keys()):
    hooks[event] = [h for h in hooks[event] if h.get("id") != "cast-time-context"]
    if not hooks[event]:
        del hooks[event]
if hooks:
    s["hooks"] = hooks
elif "hooks" in s:
    del s["hooks"]
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(settings_path))
try:
    with os.fdopen(fd, "w") as f:
        json.dump(s, f, indent=2)
        f.write("\n")
    os.replace(tmp, settings_path)
except Exception:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    raise
print("  [ok] cast-time-context entry removed from settings.json")
'
  PYTHON_EXIT=$?
  if [ "$PYTHON_EXIT" -ne 0 ]; then
    cp "${SETTINGS}.bak" "$SETTINGS"
    _warn "settings.json update failed — settings restored from backup"
  fi
fi

printf "\n${C_GREEN}cast-time uninstalled.${C_RESET}\n\n"
exit 0
