# Contributing to cast-time

## Prerequisites

- **Claude Code CLI** — `claude` must be on your PATH.
- **Bash** and **python3** — both are already required by Claude Code.
- No external dependencies beyond the above.

## Quick Start

```bash
git clone https://github.com/ek33450505/cast-time
cd cast-time
bash install.sh
```

`install.sh` is idempotent — safe to re-run after pulling changes.

## How to Modify

**Hook script** (`scripts/cast-time-context-hook.sh`): The SessionStart context injection logic. Must output valid JSON with a `hookSpecificOutput` key to stdout. Test with:
```bash
bash scripts/cast-time-context-hook.sh | python3 -c "import sys,json; json.load(sys.stdin)"
```

**Config** (`config/settings.json`): The hook entry registered in `~/.claude/settings.json`. Edit here if the hook id or timeout needs changing.

**Settings merge** (`scripts/cast-time-merge-settings.sh`): Modifies `~/.claude/settings.json`. Test in a safe environment before submitting changes.

## PR Checklist

- [ ] `bash install.sh` runs cleanly (no `[fail]` lines)
- [ ] `bash -n scripts/cast-time-context-hook.sh` passes
- [ ] Hook script outputs valid JSON: `bash scripts/cast-time-context-hook.sh | python3 -m json.tool`
- [ ] BATS tests pass: `bats tests/`
- [ ] No hardcoded paths — use `$HOME` or `~/` instead of `/Users/<username>/`
- [ ] `CHANGELOG.md` updated for any user-visible changes
