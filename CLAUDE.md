# cast-time

## Install
```bash
bash install.sh
# or: brew install ek33450505/cast-time/cast-time
```

## Test
```bash
bats tests/cast-time-context-hook.bats
bats tests/cast-time-merge-settings.bats
```

## Non-obvious

- Hook event: **SessionStart** — registered in `~/.claude/settings.json` under `hooks.SessionStart`
- Hook script lands at `~/.claude/scripts/cast-time-context-hook.sh` (not in repo root)
- Output format: `hookSpecificOutput` JSON with `hookEventName: "SessionStart"` — non-spec output is a CI hard fail
- Always exits 0 — must never block a session; errors silently log to `~/.claude/logs/hook-errors.log`
- Guards `CLAUDE_SUBPROCESS=1` at top — skip entirely in subprocess context
- Uses `python3` for JSON serialisation (handles embedded newlines correctly); `python3` must be on PATH
- `install.sh --yes` skips interactive prompts (for CI/automated installs)
- `devto-article-draft.md` at repo root is an untracked draft — do not commit it
