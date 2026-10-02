# workspace-harness-decision - handoff - U1 still open; control-surface idea raised - 2026-10-02T203000Z - Leader

- **Author / audience:** Workspace Project Leader (Claude Opus 5.5, Claude Code desktop); the next Leader session and the owner.
- **Approval:** none new. The owner, 2026-10-02: "hand off to a new session, no decisions have been made yet".
- **Status:**
  - Task B (git hardening) is done, uncommitted, with static checks only ([closure](2026-10-02T200000Z-leader-closure-git-hardening.md)).
  - Task A (finalize U1) is **not decided**. U1 stays as recorded in the [decision](2026-10-02T181644Z-leader-decision-u1-opencode.md) (OpenCode), not marked final.
  - The new control-surface question below is **not approved**.
- **Branch / base:** `main` at `ddd155c`. Everything since is uncommitted:
  - the generator refit files listed in the [previous handoff](2026-10-02T192004Z-leader-handoff-finalize-harness.md);
  - plus the git hardening: `lib/Sw.Project.psm1`, `project/base/.opencode/agents/project-review.md`, regenerated `opencode.jsonc`, `.opencode/agents/*.md`, `.sw/lib/`, `.sw/manifest.json`;
  - plus `CHANGELOG.md`, `docs/workspace-outline.md` (S4) and `docs/workspace-state.md`.

  No commit or push unless the owner asks.

## Read first

1. `docs/workspace-state.md`, Startup only.
2. This file.
3. For harness questions, the reading list in the [previous handoff](2026-10-02T192004Z-leader-handoff-finalize-harness.md) still applies.

## What happened in the session (2026-10-02)

- **Task B, done.** Patterns were designed by the Leader, approved by the owner ("go"), implemented by a general-purpose Sonnet subagent acting as `project-developer`, and recorded.
  - Workspace has no `.claude/agents/`, so the project role types are not available to a Claude session here.
  - Optional runtime check: not approved, not run.
- **Task A, Leader recommendation only (not accepted or declined).** Confirm OpenCode as final, because:
  - the `-m` rule now in `.sw/workspace.md` works around Kilo's one advantage;
  - enforcement is the same in both;
  - Kilo silently drops Workspace's config and would need a port.

  Conditions: re-check routing on each OpenCode upgrade, keep Kilo as the fallback, and keep the TUI path and Claude-terms question (C283, C329) open.
- **The owner liked the hybrid launcher idea** (option 3 of the [multi-session exploration](../workspace-multi-session/2026-10-02T190000Z-leader-exploration.md)): a per-session `-m` launch that guarantees the model and records the session in the task record.
- **The owner proposed a new direction:** build that idea on a modifiable open-source control surface such as **T3 Code**, and find a way to change **effort**.

## Leader's analysis of the owner's proposal (from the AI-Research [2] corpus; nothing verified at runtime)

- **Fit:**
  - T3 Code drives installed harnesses through adapters, including Claude via the Claude Agent SDK, and OpenCode (adapter list secondary only).
  - It picks provider and model per thread, outside the agent tree (C294), which is the launcher pattern.
  - It is MIT (C292).
  - It has no roles (C294), so a fork would add roles, the tier map and task-record links.
- **Risks:**
  - alpha v0.0.44 with daily nightlies (C293);
  - five unreproduced Windows issues (C298);
  - permissions enforced by the provider, Full access by default, no sandbox (C296);
  - AGENTS.md and hooks undocumented (C295);
  - Claude terms through it unresolved (C299 vs C269).
- **Effort:** tiers became model-only because no shortlisted harness has a usable per-agent effort setting (C316, C303). A launcher needs effort only **per session**. Candidate routes, none checked:
  - an OpenCode variant chosen at launch (`run`, or the server or SDK);
  - Claude Agent SDK effort;
  - Codex `model_reasoning_effort` (C227);
  - T3 per-thread effort (secondary, C294).
- **Leader's proposed next step (not approved):** keep U1 separate from this. Open one bounded question, "control surface for per-session model and effort routing", comparing:
  - (a) a T3 Code fork;
  - (b) a thin launcher on OpenCode's server or SDK (Kilo is built on it, C303);
  - (c) a plain `sw session start` script.

  Criteria: how effort is set, Windows stability, fork maintenance cost, permission defaults. Desk research first, either in AI-Research [2] as a Pass 11 question or as a Workspace task. A hands-on only with approval. No installs or forks without approval.

## Open owner decisions

1. U1: confirm OpenCode as final, change it, or defer until the control-surface question is answered.
2. Whether to open the control-surface and effort question, and where: AI-Research pass or Workspace task.
3. Optional runtime check of the git hardening (free Zen model, about US$2 cap).
4. Commit of the uncommitted work.

If U1 is confirmed: a `confirmation` event in this folder, the outline harness row and U1 set to final, and the state Startup updated. If it changes: follow the previous handoff's Task A instructions.

## Prompt for the next session

```text
Resume Workspace per the handoff:
.sw/comms/tasks/workspace-harness-decision/2026-10-02T203000Z-leader-handoff-control-surface.md

1. Read the Workspace state Startup and the handoff. Confirm base ddd155c plus the listed uncommitted changes.
2. No decisions were made last session. I will decide on U1 and on the proposed control-surface/effort question; answer from the recorded evidence first.
3. Run no runtime tests, installs or forks without my approval. Do not commit.
```
