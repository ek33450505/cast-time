# cast-time

Claude Code only knows today's date — it has no clock. Ask Claude what time it is and it guesses, often wrong ("good morning" at 4pm, "tonight" at noon).

cast-time is a SessionStart hook that injects local time, timezone, and a semantic bucket (morning / afternoon / evening / night) at the start of every session, so Claude always knows when it is.

## Install (Homebrew)

```bash
brew tap ek33450505/cast-time
brew install cast-time
bash $(brew --prefix cast-time)/install.sh
```

## What gets injected

At every session start, Claude receives:

```
## Session Time Context

Date: Tuesday, 2026-05-05
Time: 13:49 EDT
Timezone: EDT (UTC-4)
Day type: weekday
Time of day: afternoon
Session started: 2026-05-05T17:49:00Z (epoch: 1746467340)
```

That's it — no rules to learn, no slash commands, no behavior changes. Claude just knows the time.

## Manual install (without Homebrew)

```bash
git clone https://github.com/ek33450505/cast-time.git
cd cast-time
bash install.sh
```

## Uninstall

```bash
bash $(brew --prefix cast-time)/uninstall.sh
# or, from a clone:
bash uninstall.sh
```

## Requirements

- Claude Code CLI
- Bash + python3 (already required by Claude Code)
- macOS or Linux (uses GNU/BSD `date`)

## How it works

A SessionStart hook runs `cast-time-context-hook.sh` at session open. The script uses `date` and `python3 json.dumps` — no network, no external deps, no telemetry. It emits a `hookSpecificOutput.additionalContext` block consumed by the Claude Code harness and injected into the model's context exactly once per session.

The hook id `cast-time-context` is registered in `~/.claude/settings.json` under `hooks.SessionStart`. The installer backs up your settings.json before merging.

## Why

Out of the box, the system prompt injects today's date once at session start and that's all the temporal context Claude has. Mid-session it's effectively flying blind on time-of-day, weekend awareness, and timezone. cast-time fixes that with about 90 lines of Bash.

## License

MIT.
