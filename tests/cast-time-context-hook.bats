#!/usr/bin/env bats

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/scripts/cast-time-context-hook.sh"

setup() {
  TMPDIR_TEST="$(mktemp -d -p "${TMPDIR:-/tmp}")" || TMPDIR_TEST="$(mktemp -d)"
  export HOME="$TMPDIR_TEST"
  mkdir -p "$HOME/.claude/logs"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# ---------------------------------------------------------------------------
# Test 1: CLAUDE_SUBPROCESS=1 exits 0 silently
# ---------------------------------------------------------------------------
@test "subprocess guard: CLAUDE_SUBPROCESS=1 exits 0 silently" {
  run env CLAUDE_SUBPROCESS=1 bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# Test 2: Happy path emits valid JSON
# ---------------------------------------------------------------------------
@test "happy path: hook emits valid JSON" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -n "$output" ]

  # Must be valid JSON
  echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)"
}

# ---------------------------------------------------------------------------
# Test 3: Output contains required keys
# ---------------------------------------------------------------------------
@test "output contains required keys" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  # Parse JSON and extract additionalContext
  CONTEXT=$(echo "$output" | python3 -c '
import json, sys
d = json.load(sys.stdin)
ctx = d["hookSpecificOutput"]["additionalContext"]
print(ctx)
')

  # Verify all required keys are present
  [[ "$CONTEXT" == *"Date:"* ]]
  [[ "$CONTEXT" == *"Time:"* ]]
  [[ "$CONTEXT" == *"Timezone:"* ]]
  [[ "$CONTEXT" == *"Day type:"* ]]
  [[ "$CONTEXT" == *"Time of day:"* ]]
  [[ "$CONTEXT" == *"Session started:"* ]]
}

# ---------------------------------------------------------------------------
# Test 4: Semantic bucket edge cases
# ---------------------------------------------------------------------------
@test "semantic bucket edge cases" {
  skip "requires faketime — TODO: extract bucket logic into helper for direct testing"
}

# ---------------------------------------------------------------------------
# Test 5: Weekend vs weekday detection
# ---------------------------------------------------------------------------
@test "weekend vs weekday detection" {
  skip "requires date manipulation — TODO: extract day-type logic into helper for direct testing"
}
