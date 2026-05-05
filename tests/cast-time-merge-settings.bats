#!/usr/bin/env bats

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/scripts/cast-time-merge-settings.sh"

setup() {
  TMPDIR_TEST="$(mktemp -d -p "${TMPDIR:-/tmp}")" || TMPDIR_TEST="$(mktemp -d)"
  export HOME="$TMPDIR_TEST"
  mkdir -p "$HOME/.claude"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# ---------------------------------------------------------------------------
# Test 1: Merge adds hook entry to empty settings
# ---------------------------------------------------------------------------
@test "merge adds hook entry to empty settings" {
  # Start with empty settings
  echo '{}' > "$HOME/.claude/settings.json"

  run bash "$SCRIPT" --yes
  [ "$status" -eq 0 ]

  # Parse the resulting settings.json and verify hook entry exists
  HOOK_ID=$(cat "$HOME/.claude/settings.json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
entries = d.get('hooks', {}).get('SessionStart', [])
ids = [e.get('id') for e in entries if isinstance(e, dict)]
print(ids[0] if ids else '')
")

  [ "$HOOK_ID" = "cast-time-context" ]
}

# ---------------------------------------------------------------------------
# Test 2: Merge is idempotent
# ---------------------------------------------------------------------------
@test "merge is idempotent" {
  # Start with empty settings
  echo '{}' > "$HOME/.claude/settings.json"

  # Run merge twice
  run bash "$SCRIPT" --yes
  [ "$status" -eq 0 ]

  run bash "$SCRIPT" --yes
  [ "$status" -eq 0 ]

  # Count entries with id 'cast-time-context'
  COUNT=$(cat "$HOME/.claude/settings.json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
entries = d.get('hooks', {}).get('SessionStart', [])
count = sum(1 for e in entries if isinstance(e, dict) and e.get('id') == 'cast-time-context')
print(count)
")

  [ "$COUNT" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Test 3: Merge backs up settings file
# ---------------------------------------------------------------------------
@test "merge backs up settings file" {
  # Start with empty settings
  echo '{}' > "$HOME/.claude/settings.json"

  run bash "$SCRIPT" --yes
  [ "$status" -eq 0 ]

  # Verify backup exists
  [ -f "$HOME/.claude/settings.json.bak" ]
}
