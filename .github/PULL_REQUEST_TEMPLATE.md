## Description

<!-- What does this PR change and why? -->

## Checklist

- [ ] `bash install.sh` runs cleanly — no `[fail]` lines
- [ ] BATS tests pass: `bats tests/`
- [ ] `bash install.sh && bash uninstall.sh` cycle tested (install/uninstall both work)
- [ ] No hardcoded paths — `$HOME` or `~/` used instead of `/Users/<username>/`
- [ ] `CHANGELOG.md` updated if this is a user-visible change
