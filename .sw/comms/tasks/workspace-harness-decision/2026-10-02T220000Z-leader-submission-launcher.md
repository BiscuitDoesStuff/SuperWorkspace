# workspace-harness-decision - submission (draft) - session launcher: one control surface - 2026-10-02T220000Z - Leader

- **Author / audience:** Workspace Project Leader (Claude Opus 5.5, Claude Code desktop); owner, for approval.
- **Approval:** none. Draft for owner approval. Requested by the owner in session, 2026-10-02 ("Draft the launcher submission"), after the [control-surface decision](2026-10-02T213000Z-leader-decision-control-surface.md).
- **Status:** proposed.
- **Branch / base:** `main` at `0701522`. No commit or push unless the owner asks.

## Current state (read 2026-10-02)

- `project/roles.json` gives each role a tier: `project-leader` session, `project-developer` light, `project-research` standard, `project-review` standard, `explore` light.
- `sw tiers -Light <id> -Standard <id> -High <id>` (`Set-SwTiers`, `lib/Sw.Project.psm1`) writes the local, git-ignored OpenCode tier map. Shared files pin no model.
- `sw claude enable` (`Invoke-SwClaude`, `Get-SwClaudeFiles`) generates the git-ignored `.claude/` adapter. The contract pins every Claude agent to `model: opus` (`Test-SwProject`, about line 530). Workspace has not enabled it.
- `sw comms event` (`Invoke-SwComms`) writes task events.
- No script launches sessions. The `-m` rule in `.sw/workspace.md` is documentation only.

## Goal

`sw session start <role> <task-id> [-Headless]` starts the role in the tool its tier model belongs to, always passes the model explicitly, and records the session in the task folder. This enforces the `-m` rule in code and gives both tools one entry point.

## Scope

1. **Tier map routes by model ID:** a tier model whose ID starts with `anthropic/` (OpenCode's form) or is a Claude alias (`opus`, `sonnet`, `haiku`) routes to Claude Code. Every other ID routes to OpenCode. There is no new config file; `Set-SwTiers` keeps its inputs.
2. **New command `session`** in `sw.ps1` and an `Invoke-SwSession` function in `lib/Sw.Project.psm1`. It reuses `Get-SwConfig`, `Get-SwUtc`, `Assert-SwSafeName`, `Read-SwJson` and `Invoke-SwComms`.
   - It resolves the role's tier from `project/roles.json`, then the model from the local tier map. It fails if either is missing and never falls back to a default model. The `session` tier (Leader) requires an explicit `-Model`.
   - **OpenCode:** `opencode run --agent <role> -m <model> --title <task-id>` (interactive: `opencode --agent <role> -m <model>`). It captures the session ID from `--format json`.
   - **Claude Code:** interactive `claude --agent <role> --model <alias>` on the user's subscription login. `-Headless` uses `claude -p` only if research request R1 allows scripted subscription use; until then it refuses with a message.
   - Before a Claude launch, it requires the `.claude/` adapter to be enabled and current, and tells the user to run `sw claude enable` otherwise. It does not enable the adapter itself.
3. **Records:** writes a `progress` event in `.sw/comms/tasks/<task-id>/` with the role, tool, model, launch command and session ID (or "interactive; ID not captured"). It never writes outside the task folder.
4. **Contracts:** `validate` asserts the documented launch commands always carry `-m`/`--model`, that `session` has no default model, and that no effort or variant field appears (existing `NoEffort`).
5. **Docs:** the `.sw/workspace.md` launch rule (through `project/base/.sw/workspace.md`) names `sw session start` as the way to start role sessions. Also a `CHANGELOG.md` entry and the outline and state rows.

## Owner input (2026-10-02, in session)

- **Requirement:** every user who installs Workspace must be able to configure it fully for themselves. Tools, models and accounts are per-user, local choices; shared files carry none of them (extends O10).
- **Owner's own setup:** Claude, OpenAI and likely other providers; for Claude, only Opus.

Resolutions in this draft:
1. **Routing is per user:** each user's local tier map decides the model per tier, and the model decides the tool. No role is fixed to Claude in shared files.
2. **Claude model comes from the local map:** `Get-SwClaudeFiles` writes the user's Claude model (default `opus`) instead of a hard-coded one; the contract changes from "`model: opus`" to "a Claude model alias from the local map, never in shared files". The owner's map uses `opus` for every Claude tier.
3. **Open:** how OpenAI models are reached (API key in OpenCode, or a ChatGPT-plan sign-in; C131 says ChatGPT sign-in for third-party apps exists as a preview). Research request R6.
4. **Open:** interactive Claude session ID: record "not captured" (Leader default) unless the owner says otherwise.

## Out of scope

T3 Code; effort; installs; global settings; changes to OpenCode or Claude Code configuration beyond the existing generators; the git-hardening runtime test (deferred to workspace completion by the owner); parallel or automatic sessions; worktrees.

## Acceptance

- **Static (part of this change):**
  - `sw validate` PASS with the new contracts;
  - Pester-free self-check: a dry-run switch (`-WhatIf`) prints the resolved tool, model and command for each role against a test tier map, with no process started; Claude roles route to `claude`, others to `opencode`, and a missing tier fails;
  - `git diff --check` clean.
- **Runtime (separate owner approval; free OpenCode models, US$0; no Claude launches without approval):**
  - one OpenCode launch per tier, with the served model confirmed from `opencode session export`;
  - headless `ask` permission handling (rejects, hangs or approves);
  - start-up cost per session compared with a subagent;
  - whether `--fork` keeps the model.

## Dependencies

- **R1** (research request): whether scripted or headless Claude use on a subscription is allowed. This gates `-Headless` for Claude.
- **R2** (research request): whether Claude Code honours `--model` and agent `model:` per launch path. Until it's answered, a Claude launch is verified from the session's own model report.
- **R6** (research request): OpenAI access route per user (API key or ChatGPT-plan sign-in) and its terms.
- **R5** (research request): OpenCode headless `ask` handling (documentation side of the runtime check).
- **S4 scoping:** Claude Code enforcement parity before Claude roles do write work.
