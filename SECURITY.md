# Security Policy

## Supported Versions

| Version | Support Status |
|---|---|
| 0.1.x | Full support — security fixes backported |
| < 0.1 | No longer supported |

## Reporting a Vulnerability

**Do NOT open a public GitHub issue for security vulnerabilities.**

Report privately using [GitHub Security Advisories](https://github.com/ek33450505/cast-time/security/advisories/new).

### What to Include

- **Version** — output of `cat ~/Projects/personal/cast-time/VERSION`
- **Operating system** — macOS version (e.g., `sw_vers`)
- **Which file** — e.g., `install.sh`, `scripts/cast-time-context-hook.sh`
- **Steps to reproduce** — minimal, clear reproduction steps
- **Impact** — what an attacker could do

### Response Timeline

| Severity | Acknowledgment | Fix Target |
|---|---|---|
| Critical | 48 hours | 14 days |
| High | 48 hours | 30 days |
| Medium / Low | 5 business days | Next release |

## Security Design Notes

cast-time installs a hook script that runs at the start of every Claude Code session. Key design decisions:

- **No credentials** — cast-time does not store or handle API keys, tokens, or secrets
- **No network calls** — `install.sh`, `uninstall.sh`, and the hook script make no external network requests
- **Local only** — all reads and writes target `~/.claude/` under your user context; nothing is world-readable
- **install.sh is idempotent** — safe to re-run; copies files, does not execute hook logic or modify system config
- **Hook is read-only** — the SessionStart hook only reads system time and emits JSON to stdout; it does not write files or read sensitive content
- **Settings merge is non-destructive** — backs up `~/.claude/settings.json` before modifying; preserves all existing hook entries

## Out of Scope

- Vulnerabilities in the Claude API or Anthropic services — report to [Anthropic](https://www.anthropic.com/security)
- Vulnerabilities in third-party tools (bash, Python, Homebrew)
- Agent behavior or output quality — these are configuration concerns, not security boundaries
