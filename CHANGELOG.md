# Changelog

## 0.2.0 - 2026-09-26

- **Fix:** handle dotfiles on Linux and macOS (`-Force` on file operations). CI no longer stops at the first failing OS.
- **Fix (security and data loss):**
  - comms names reject path traversal;
  - `comms close` archives the whole task folder;
  - `claude enable` and `claude disable` keep your own `.claude/` files;
  - both broad `gh` allows are removed, and more `gh` write verbs are denied;
  - global backups skip `opencode.json`.
- **Fix:** `remote` works on Linux and macOS, and `global` returns its exit code.
- **New:** `sw doctor [-User]`, a read-only setup check that prints the fix for each problem, and `.sw/onboarding.md` for new contributors.

## 0.1.0 - 2026-09-26

First version. It replaces the ai-environment-foundation repo and the MyMMO
workspace layer, which were harvested once and then retired.

- **CLI:** `sw.ps1` on PowerShell 7, with project and kit modules.
- **Project layer:**
  - 8 roles: MyMMO's roles, made generic.
  - 8 commands, including the new `/handoff` and `/inbox`.
  - 7 base skills, plus `unreal-validation` in the Unreal profile.
  - A generated `opencode.jsonc` covering the profile's binary-edit denies, the GitHub tier and the build delegation allowlist.
  - Install and update driven by a manifest, with `-Adopt` for existing repos.
- **Validator:** ported from MyMMO's `Validate-AgentWorkspace.ps1`. It is now driven by the profile and roles, and adds GitHub tier checks and Claude drift detection.
- **Claude adapter:** generated instead of kept in sync by hand. Skills are copied, not linked through absolute junctions.
- **Comms:** task events, inboxes, and a close/archive step with `SUMMARY.md`.
- **GitHub:** issue forms, a PR template, labels, and a validate workflow. Tier 0 and tier 1 rules are enforced in OpenCode and in Claude.
- **Global:** managed rule blocks for OpenCode and Claude, read-only `gh` allows, and backups that never copy credential files.
- **Remote:** `tailscale serve` setup and check, with a `-KeepLan` option.
- **Usage:** a report combining RTK gain, OpenCode stats and the startup budget.
