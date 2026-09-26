# Changelog

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
