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
  run env CLAUDE_SUBPROCESS=1 bash "$SCRIPT" < /dev/null
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# Test 2: Happy path emits valid JSON
# ---------------------------------------------------------------------------
@test "happy path: hook emits valid JSON" {
  run bash "$SCRIPT" < /dev/null
  [ "$status" -eq 0 ]
  [ -n "$output" ]

  # Must be valid JSON
  echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)"
}

# ---------------------------------------------------------------------------
# Test 3: Output contains required keys
# ---------------------------------------------------------------------------
@test "output contains required keys" {
  run bash "$SCRIPT" < /dev/null
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
  skip "requires faketime — tracked: https://github.com/ek33450505/cast-time/issues/1"
}

# ---------------------------------------------------------------------------
# Test 5: Weekend vs weekday detection
# ---------------------------------------------------------------------------
@test "weekend vs weekday detection" {
  skip "requires date manipulation — tracked: https://github.com/ek33450505/cast-time/issues/2"
}

# ---------------------------------------------------------------------------
# Regression: the hook must never read stdin.
# It is a SessionStart hook registered with a 3s timeout. If it blocks waiting
# for input that the harness does not send, the timeout kills it and the ENTIRE
# time context is silently dropped — the hook "fails" by producing nothing.
# A stdin read was briefly introduced here and caught by this exact scenario.
# ---------------------------------------------------------------------------
@test "does not block when stdin is an open pipe that never closes" {
  FIFO="$BATS_TEST_TMPDIR/stdin.fifo"
  OUT="$BATS_TEST_TMPDIR/out.json"
  mkfifo "$FIFO"
  # Hold the FIFO open read-write for the whole test so a reader never sees EOF.
  exec 9<> "$FIFO"

  bash "$SCRIPT" <&9 > "$OUT" 2>/dev/null &
  BGPID=$!

  FINISHED=0
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if ! kill -0 "$BGPID" 2>/dev/null; then FINISHED=1; break; fi
    sleep 0.5
  done

  if [ "$FINISHED" -eq 0 ]; then
    # SIGKILL, and deliberately no `wait`: the child is blocked on a FIFO this
    # test still holds open, so waiting on it is itself a way to hang.
    kill -9 "$BGPID" 2>/dev/null || true
  fi
  exec 9>&-

  [ "$FINISHED" -eq 1 ]
  [ -s "$OUT" ]
}
