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

Date anchors (use these directly; do not compute offsets):
- Yesterday: 2026-05-04 (Monday)
- Tomorrow: 2026-05-06 (Wednesday)
- This week: 2026-05-04 (Mon) to 2026-05-10 (Sun), ISO 2026-W19
- Last week: 2026-04-27 to 2026-05-03
- This month: May 2026 ends 2026-05-31 (26 days remaining)
- This quarter: Q2 2026 (2026-04-01 to 2026-06-30), 56 days remaining
```

The anchors are absolute dates so relative references never have to be computed
in-head — the arithmetic is done once, correctly, instead of being re-derived
per question.

## Staying correct in long sessions

The block above is injected once, at session start. A session that opens at
18:08 and is still running past midnight would otherwise carry
"Wednesday / evening" for hours after both stopped being true — and anything
that derives a date from it (a dated note, a journal filename) records the
wrong day without ever looking wrong.

A second hook, `cast-time-drift-hook.sh`, runs on `UserPromptSubmit` and stays
silent on virtually every prompt. It re-injects only when:

- the local **date has rolled over** — and says so explicitly, so earlier dated
  output in the same session can be recognised as wrong; or
- **`CAST_TIME_DRIFT_SECONDS`** (default `10800`, 3h) has elapsed since the last
  injection, so the time-of-day bucket cannot silently go stale.

It also reports **session elapsed**, measured from the real session start.

| Variable | Default | Effect |
|---|---|---|
| `CAST_TIME_DRIFT_SECONDS` | `10800` | Seconds before a same-day re-injection |
| `CAST_TIME_STATE_DIR` | `~/.claude/.cast-time` | Where per-session state is kept |

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

A SessionStart hook runs `cast-time-context-hook.sh` at session open. The script uses `date` and `python3 json.dumps` — no network, no external deps, no telemetry. It emits a `hookSpecificOutput.additionalContext` block consumed by the Claude Code harness and injected into the model's context.

A UserPromptSubmit hook runs `cast-time-drift-hook.sh` on each prompt. It reads a
small per-session state file (`START_EPOCH|LAST_EPOCH|LAST_DATE`) and exits 0
silently unless the date rolled over or the drift window elapsed. Date
arithmetic is done in Python from the epoch rather than with `date -v` / `date -d`,
which diverge between BSD and GNU.

The hook ids `cast-time-context` and `cast-time-drift` are registered in
`~/.claude/settings.json` under `hooks.SessionStart` and `hooks.UserPromptSubmit`.
The installer backs up your settings.json before merging.

## Why

Out of the box, the system prompt injects today's date once at session start and that's all the temporal context Claude has. Mid-session it's effectively flying blind on time-of-day, weekend awareness, and timezone. cast-time fixes that with about 90 lines of Bash.

## CAST Ecosystem

> Auto-synced from [claude-agent-team/docs/ecosystem.md](https://github.com/ek33450505/claude-agent-team/blob/main/docs/ecosystem.md). Run `~/Projects/personal/claude-agent-team/scripts/sync-ecosystem-readme.sh` to refresh.

<!-- ECOSYSTEM_START -->
**Core Framework**

| Repo | Description | Latest | Install |
|---|---|---|---|
| [claude-agent-team](https://github.com/ek33450505/claude-agent-team) | Local-first multi-agent control plane — specialist agents, quality gates, hook enforcement, and the tamper-evident cast.db execution record. | ![](https://img.shields.io/github/v/release/ek33450505/claude-agent-team?style=flat-square) | `brew tap ek33450505/cast && brew install cast` |

**Observability**

| Repo | Description | Latest | Install |
|---|---|---|---|
| [claude-code-dashboard](https://github.com/ek33450505/claude-code-dashboard) | React observability UI — sessions, agent analytics, hook health, memory browser, SQLite explorer. | ![](https://img.shields.io/github/v/release/ek33450505/claude-code-dashboard?style=flat-square) | Clone from GitHub |
| [cast-desktop](https://github.com/ek33450505/cast-desktop) | Tauri 2 native app — embedded PTY terminal, command palette, 11 dashboard views. | ![](https://img.shields.io/github/v/release/ek33450505/cast-desktop?style=flat-square) | `brew tap ek33450505/homebrew-cast-desktop && brew install cast-desktop` |

**Standalone Packages**

| Repo | Description | Latest | Install |
|---|---|---|---|
| [cast-mcp](https://github.com/ek33450505/cast-mcp) | Read-only MCP server over the Claude Code execution record (cast.db) — dispatch decisions, incidents, cost, sessions, and full-text search as 5 MCP tools + 5 resources. stdlib-only, strictly read-only. | ![](https://img.shields.io/github/v/release/ek33450505/cast-mcp?style=flat-square) | `brew tap ek33450505/cast-mcp && brew install cast-mcp` |
| [cast-ledger](https://github.com/ek33450505/cast-ledger) | Signed, hash-chained, tamper-evident session receipts for Claude Code — SHA-256-stamped audit receipts from cast.db with `--verify`, plus an optional provenance hash-chain across sessions. | ![](https://img.shields.io/github/v/release/ek33450505/cast-ledger?style=flat-square) | `brew tap ek33450505/cast-ledger && brew install cast-ledger` |
| [cast-predict](https://github.com/ek33450505/cast-predict) | Telemetry-driven dispatch prediction for Claude Code — reads cast.db to predict a task's likely cost, suggest agents, and surface related past incidents before you run it. | ![](https://img.shields.io/github/v/release/ek33450505/cast-predict?style=flat-square) | `brew tap ek33450505/cast-predict && brew install cast-predict` |
| [cast-memory](https://github.com/ek33450505/cast-memory) | Persistent agent memory for Claude Code — FTS5 full-text search, weighted relevance, temporal validity, Ollama embeddings, and weekly consolidation over cast.db. | ![](https://img.shields.io/github/v/release/ek33450505/cast-memory?style=flat-square) | `brew tap ek33450505/cast-memory && brew install cast-memory` |
| [cast-doctor](https://github.com/ek33450505/cast-doctor) | Standalone read-only health check for any Claude Code install — validates hooks, MCP config, agent frontmatter, cast.db core schema, and stale memories without the full CAST framework. | ![](https://img.shields.io/github/v/release/ek33450505/cast-doctor?style=flat-square) | `brew tap ek33450505/cast-doctor && brew install cast-doctor` |
| [cast-time](https://github.com/ek33450505/cast-time) | Gives Claude Code a clock — injects local time, timezone, and a semantic time-of-day bucket at every SessionStart. | ![](https://img.shields.io/github/v/release/ek33450505/cast-time?style=flat-square) | `brew tap ek33450505/cast-time && brew install cast-time` |
| [cast-claudes_journal](https://github.com/ek33450505/cast-claudes_journal) | Three-hook journaling for Claude Code (Stop/SessionStart/UserPromptSubmit) — maintains Claude's perspective and working memory across sessions as Obsidian-compatible markdown in ~/Documents/Claude/. | ![](https://img.shields.io/github/v/release/ek33450505/cast-claudes_journal?style=flat-square) | `brew tap ek33450505/homebrew-claudes-journal && brew install claudes-journal` |
<!-- ECOSYSTEM_END -->

## License

MIT.
