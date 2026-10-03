# workspace-design-scoping - submission (draft) - S4 enforcement parity on Claude Code - 2026-10-02T214500Z - Leader

- **Author / audience:** drafted by the `project-developer` subagent for the Workspace Project Leader; owner, for approval.
- **Approval:** none. Proposal, not approved.
- **Status:** proposed.
- **Branch / base:** `main` at `0701522`; this draft is uncommitted. No commit or push unless the owner asks.

## Current state (read 2026-10-02)

- OpenCode: git-rule hardening is implemented and committed (`5c08816`). `$script:SessionWrappers`, `$script:SessionGitVerbs`, `Get-SwSessionRules`, `Add-SwRtkTwins`; static matrix only (618 cases). Runtime test deferred to workspace completion (owner, 2026-10-02).
- Claude adapter: `Get-SwClaudeFiles` (`lib/Sw.Project.psm1`, about line 586) writes `.claude/settings.json` with `deny` = only the plain forms `Bash(git push:*)`, `reset --hard`, `clean`, `stash`, plus `Get-SwClaudeGhDeny`, plus `Edit(**/<editDeny>)`; `ask` = `git commit`, `Read(**/.env*)`; `allow` = `Skill`; one SessionStart hook (`cat .claude/project-leader.md`). None of the global-flag, compound, rtk-runner or wrapper forms (`git -C . push`, `x && git push`, `bash -c '...git...'`) is covered.
- Per-role limits on Claude are "stated" (`.sw/workspace.md` permissions table). `roles.json` gives `project-review` `claudeTools` = `Read, Grep, Glob, Bash, Skill`, so Bash is unrestricted there (OpenCode: enforced git-read allowlist). `project-research` gets `Edit, Write` without the markdown-only limit.
- Claude agents are all pinned `model: opus` and `disallowedTools: Agent`; `Test-SwProject` checks the generated agents and drift only when `.claude/.sw-generated` exists. `.claude/` is not enabled in this checkout, so none of this path has run.
- Static checks use `Get-SwDecision`, an OpenCode-semantics evaluator; there is no offline evaluator for Claude permission syntax.

## Goal

The generated Claude settings carry the same hard git and gh rules as OpenCode, from one source list, with a static check that the rules are present. Gaps that Claude settings cannot express are recorded as stated, not implied enforced.

## Scope (smallest independently testable change)

1. **Single source:** derive Claude git deny/ask entries from `$script:SessionGitVerbs` and `$script:SessionWrappers` in `Get-SwClaudeFiles` instead of the hard-coded four verbs. Pattern syntax for global-flag and compound forms (for example `Bash(git * push:*)`) is unverified: needs R3 first.
2. **Drift check:** `Test-SwProject` asserts every OpenCode deny verb has a Claude counterpart in the generated `settings.json` (rule presence, not evaluation), using the existing generated-file comparison.
3. **Role limits:** document, per owner choice (question 1), whether `project-review` keeps Bash (stated limit), loses Bash (no git reads), or gets an agent-level hook (R3). Update `project/base/.sw/workspace.md` table (regenerated to `.sw/workspace.md`).
4. **Contracts:** assert no `Bash(*)` allow rule and no `model`/effort fields in settings; `CHANGELOG.md` entry; outline S4 and state rows by the Leader.

## Out of scope

Running Claude or any hook; Windows hook acceptance test (deferred item below); sandbox settings (documented, never configured); OpenCode rule changes; `.claude/settings.local.json`; enabling the adapter in Workspace (belongs to the launcher submission).

## Acceptance

- Static: `pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks` passes; a negative fixture (settings missing the `git -C` form) fails validate; `pwsh -NoProfile -File sw.ps1 update . -WhatIf` no drift; `git diff --check` clean. `sw claude enable -WhatIf` lists the written files without writing (generation dry run).
- **Deferred runtime item (needs separate owner approval; owner deferred the runtime git test to workspace completion):** on native Windows, in a scratch project with a harmless probe, show that (a) a `deny` rule blocks the matched Bash call, (b) a PreToolUse hook exiting 2 blocks the call and a subagent write (the C258 report, one report, not vendor-confirmed), (c) the effect cannot be reached by Write/Edit or a wrapper. Subscription limits apply (C324). No destructive command is run to prove a denial.

## Dependencies

- **R3** (Claude Code permission and hook enforcement on native Windows): required before step 1 patterns and the hook acceptance test. S4 text: sandbox needs WSL2 (C231), plugin subagents ignore hooks (C224; project `.claude/agents/` are not plugin-carried), denylists are bypassable (C257).
- **R2** (Claude Code model routing per launch path): not needed for rules; needed before runtime claims about which model ran.
- **R1** (scripted Claude on subscription): decides whether a scripted acceptance run is allowed at all (C093, C283).
- The launcher submission (`workspace-harness-decision/2026-10-02T220000Z-leader-submission-launcher.md`, draft) lists this item as a precondition for Claude roles doing write work.

## Owner questions

1. `project-review` on Claude: keep Bash (stated limit), drop Bash, or require a hook? `project-research`: accept unrestricted Edit/Write?
2. Add `Edit(.claude/**)` and `.git/**` deny rules so a Claude session cannot rewrite its own settings (a new deny surface; `sw` writes them outside Claude)?
3. Accept rule-presence checks as the static bar, given no offline Claude evaluator exists?
