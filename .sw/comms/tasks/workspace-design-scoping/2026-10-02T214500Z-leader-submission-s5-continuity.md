# workspace-design-scoping - submission (draft) - S5 continuity and compaction - 2026-10-02T214500Z - Leader

- **Author / audience:** drafted by the `project-developer` subagent for the Workspace Project Leader; owner, for approval.
- **Approval:** none. Proposal, not approved.
- **Status:** proposed.
- **Branch / base:** `main` at `0701522`; this draft is uncommitted. No commit or push unless the owner asks.

## Current state (read 2026-10-02)

- Re-injected instruction file: `AGENTS.md` (project-owned identity plus kit blocks). Its Startup says the harness auto-loads it. `.sw/workspace.md`, `.sw/collaboration.md` and skills load on demand (`.sw/workspace.md` "Keep required startup reading small").
- **No root `CLAUDE.md` exists** (repo root: `AGENTS.md`, `README.md`, `opencode.jsonc`, no `CLAUDE.md`; `lib/Sw.Project.psm1` never emits one). The outline cites Claude Code re-reading project-root `CLAUDE.md` after compaction (C253); nothing in the corpus claims it reads `AGENTS.md`. The generated `.claude/project-leader.md` says project rules are in `AGENTS.md`, "already loaded", which is unverified for Claude Code.
- Claude path: a SessionStart hook cats `.claude/project-leader.md` (`Get-SwClaudeFiles`). Whether SessionStart runs again after `/compact` is not in the corpus.
- OpenCode: `opencode.jsonc` compaction `auto: true`, `preserve_recent_tokens: 50000`, `reserved: 32000`; `.sw/workspace.md` says small-context local models override it. What OpenCode re-injects after compaction is not documented in the repo (S5 Limits: Codex and OpenCode compaction docs not inspected).
- Rules that live only in `.sw/workspace.md` (on demand, not re-injected): pass `-m` on `opencode run --agent`; stop on quota or rate-limit errors; three-failed-attempts rule; never switch a running session's model. Rules in `AGENTS.md`: approval and scope, no push, commit only on request, no destructive Git, no installs without approval.
- Task records carry approvals and decisions (`.sw/collaboration.md`); owner deferrals (for example the runtime git test) live in the state Startup and records.

## Goal

Every must-survive constraint is either in a file the harness re-injects or in a task record the Leader re-reads at resume, and a check proves it. Where a harness's re-injection is unknown, that is recorded as a gap, not assumed.

## Scope (smallest independently testable change)

1. **Constraint list** (about 10 items, in `docs/workspace-outline.md` under S5 or a project doc): constraint, owner file, re-injected (yes / no / unknown per harness). Seeds from the on-demand list above plus the `AGENTS.md` Git and scope rules.
2. **Static check** in `Test-SwProject` (`lib/Sw.Project.psm1`, reusing `Read-SwText`, `Require`): each required phrase appears in `AGENTS.md` (and `CLAUDE.md` when present). Constraints found only in `.sw/workspace.md` are either moved into the kit `AGENTS.md` block (`project/base/AGENTS.md`; startup budget 12,100 bytes applies) or listed as accepted on-demand with a reason.
3. **Claude side (owner decision first):** emit a root `CLAUDE.md` pointing at `AGENTS.md` from the kit (`project/base/`), or state that Claude Code gets rules only via the hook. Whether an import line is honoured must be checked in Claude Code documentation first.
4. **Resume rule check:** `/resume` and `task-handoff` already reconcile records with Git; add one static check that the state Startup commit hashes exist (shared with S3 A9).
5. `CHANGELOG.md` entry; Leader updates S5 Limits and state.

## Out of scope

Any memory service (P5 stands); changing compaction settings; running a compaction; measuring interaction cost (C252) until a runtime item is approved; Codex; hook changes (S4).

## Acceptance

- Static: validate passes with the new check; negative fixture (remove a listed phrase) fails; `update -WhatIf` no drift; `git diff --check` clean.
- Reported separately as not run: that Claude Code re-reads the file after `/compact`; what OpenCode keeps after compaction (R4).
- Runtime (separate owner approval, free OpenCode models; Claude launches need approval and draw subscription limits, C324): scratch project, sentinel constraint stated only in conversation vs only in `AGENTS.md`, force compaction, then probe. At least 3 isolated trials per cell (C167); record interaction cost as well as completion (C252).

## Dependencies

- **R4** (OpenCode compaction and re-injection): needed before any OpenCode continuity claim.
- **R2** (Claude Code per-launch behaviour) and **R1** (scripted Claude on subscription, C093, C283): needed only for scripted Claude trials.
- S3 case register (A9 shared check). Launcher records session IDs; this item does not depend on it.

## Owner questions

1. Add a root `CLAUDE.md` (kit-managed) so the re-injection claim holds on Claude, or rely on the SessionStart hook?
2. Which on-demand rules (for example `-m`, quota stop) move into `AGENTS.md`, given its startup byte budget?
3. Is R4 to be requested now, or does OpenCode stay "unknown" until a runtime session is approved?
