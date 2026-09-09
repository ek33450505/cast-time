# Changelog

## [0.2.0] — 2026-09-09

### Added
- **Drift correction for long sessions** (`cast-time-drift-hook.sh`, UserPromptSubmit).
  The session-start block is injected once; a session running past midnight kept
  reporting the previous day indefinitely, and anything deriving a date from it
  recorded the wrong day without looking wrong. The new hook stays silent on
  virtually every prompt and re-injects only on a date rollover (saying so
  explicitly) or after `CAST_TIME_DRIFT_SECONDS` (default 3h).
- **Relative date anchors** in the session-start block — yesterday, tomorrow,
  week span + ISO week, month end, quarter span and days remaining. Emitted as
  absolute dates so offsets are never computed in-head.
- **Elapsed time** reported alongside each re-injection, measured from the
  session's first prompt. (The SessionStart hook deliberately does not read
  stdin — a SessionStart hook that blocks on input is killed by its 3s
  timeout, which would drop the entire time context.)
- `CAST_TIME_DRIFT_SECONDS` and `CAST_TIME_STATE_DIR` environment variables.
- **CI** — this repo previously had no workflows at all. Adds shellcheck,
  `bash -n`, BATS on ubuntu + macOS, an install/uninstall round-trip that
  asserts hook-id registration *and* deregistration, and a `python-compat` job
  that compiles the embedded Python under a real 3.9 interpreter.

### Fixed
- Removed unused `DAY_OF_WEEK` / `LOCAL_DATE` assignments (dead since the file
  was written; never caught because the repo had no CI).

### Notes
- Date arithmetic is computed in Python from the epoch, never via `date -v`
  (BSD) or `date -d` (GNU), whose divergence has broken CI on this project before.
- The embedded Python avoids nested quotes inside f-strings: that syntax needs
  3.12+ (PEP 701) and fails on a stock macOS python3 (3.9), where the hook's
  `|| _log_error` would swallow it into a silent no-op. The `python-compat` job
  exists specifically to catch that class; `ast.parse(feature_version=(3,9))`
  does **not** detect it.

## [0.1.2] — 2026-07-01

- chore: v9 ecosystem sync — version bump for the CAST v9 ecosystem consolidation (repo is already v9-clean; no behavior change).

## [0.1.1] — 2026-06-05

- docs: refresh CAST ecosystem stats to 23 agents / 1171 tests / 38 tables (devto-article-draft.md)
- docs: remove fictional "Constellation 3D graph" claim from README ecosystem table
- docs: fix SECURITY.md personal absolute path — now uses generic `cat VERSION`
- fix: correct "Stop event" comment to "SessionStart event" in cast-time-merge-settings.sh
- test: replace inline TODO stubs with issue tracker references in skipped tests
- chore: gitignore devto-article-draft.md (unpublished draft, not a release artifact)

## [0.1.0] — 2026-05-05

- Initial release: SessionStart hook injecting local time, timezone, day type, semantic time-of-day bucket
