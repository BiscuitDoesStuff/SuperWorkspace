# workspace-harness-decision - handoff - launcher, S3-S6 scoping and research requests - 2026-10-02T224500Z - Leader

- **Author / audience:** Workspace Project Leader (Claude Opus 5.5, Claude Code desktop); the next Leader session and the owner.
- **Approval:** owner in session, 2026-10-02: "I accept all of these, create handoff first". This accepts the Leader recommendations listed under Decisions. It approves no implementation, runtime test, install or commit.
- **Status:** drafts written; owner decisions recorded in the [decision record](2026-10-02T225000Z-leader-decision-launcher-scoping.md); nothing implemented.
- **Branch / base:** `main` at `0701522` (commits `5c08816` and `0701522` made this session at the owner's request). Uncommitted:
  - `docs/workspace-outline.md` (S2 "Decided" fix; O10 per-user requirement);
  - `docs/workspace-state.md` (Startup links to the drafts);
  - [launcher submission](2026-10-02T220000Z-leader-submission-launcher.md), this handoff and the decision record;
  - `.sw/comms/tasks/workspace-design-scoping/` (S3-S6 drafts, written by a `project-developer` subagent, spot-checked by the Leader);
  - `.sw/comms/tasks/workspace-research-requests/` (R1-R6 and the prompt for AI-Research [2]).

  No commit or push unless the owner asks.

## Read first

1. `docs/workspace-state.md`, Startup only.
2. This file and the [decision record](2026-10-02T225000Z-leader-decision-launcher-scoping.md).
3. On demand: the launcher submission and the four scoping drafts.

## What happened (2026-10-02)

- Owner decisions: effort dropped; Claude by subscription login only; one control surface (Claude roles in Claude Code, others in OpenCode) ([decision](2026-10-02T213000Z-leader-decision-control-surface.md)).
- Owner requirement: every installing user configures tools, models and accounts locally (outline O10).
- Owner's own setup: Claude (Opus only), OpenAI and likely others.
- Git-hardening runtime test deferred to workspace completion.
- Drafted: launcher submission, S3-S6 scoping, research requests R1-R6.
- Owner accepted the Leader recommendations on the open points (see the decision record).

## Next actions

1. **Leader:** fold the accepted decisions into the launcher draft and the S4, S5 and S6 drafts (they are unsubmitted, so editable), then present them to the owner for approval one at a time. Suggested order: S4 Claude git parity (gates Claude write work), launcher, S5, S6, S3.
2. **Owner:** paste the prompt in the research requests file into an AI-Research [2] session when ready. R1 gates headless Claude; R6 gates OpenAI routing.
3. **Owner, optional:** approve running `claude --help` (prints options only) to confirm `--session-id` for the launcher.
4. Commit of the uncommitted drafts when the owner asks.

## Prompt for the next session

```text
Resume Workspace per the handoff:
.sw/comms/tasks/workspace-harness-decision/2026-10-02T224500Z-leader-handoff-launcher-scoping.md

1. Read the Workspace state Startup, the handoff and its decision record. Confirm base 0701522 plus the listed uncommitted changes.
2. Fold the accepted decisions into the launcher and S4-S6 drafts, then present them for approval one at a time.
3. Run no runtime tests, installs or forks without my approval. Do not commit unless I ask.
```
