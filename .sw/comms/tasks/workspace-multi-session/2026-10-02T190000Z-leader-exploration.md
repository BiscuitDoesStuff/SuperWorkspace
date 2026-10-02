# workspace-multi-session - exploration - separate sessions instead of, or with, in-session subagents - 2026-10-02T190000Z - Leader

- **Author / audience:** Workspace Project Leader (Claude Opus 5.5, Claude Code desktop); owner.
- **Approval:** owner in session, 2026-10-02: "look into using multi-sessions in replace of or with agentic, open-ended nothing is expected". This is an exploration only. Nothing here is approved for implementation.
- **Status:** exploration recorded. No follow-up is required.
- **Inputs:**
  - a read-only corpus scan of AI-Research [2] `docs/research-claims.md` and `docs/research/*.md`, plus Workspace `.sw/workspace.md` and `.sw/collaboration.md`;
  - the U1 hands-on records in [workspace-harness-decision](../workspace-harness-decision/);
  - two extra scratch runs on OpenCode 2.0.20 (G1, G2 below; free models, US$0).

## Terms

- **In-session subagents (current):** the Leader calls the harness `subagent` (or `task`) tool. The child runs inside the parent session's process and returns a summary.
- **Multi-session:** each role or package runs as its own harness session, either `opencode run --agent X -m M` (headless) or an interactive session that a human opens. The sessions coordinate through task records, `inbox/` messages and session exports, not through tool calls.

## What the evidence says

- **No direct evidence either way.** The corpus has no study comparing separate sessions with in-session dispatch. The nearest evidence is indirect:
  - *For fresh or bounded sessions:*
    - C250: Anthropic's guidance is an initializer session plus a progress file and git, with a fresh session per feature.
    - C251: compaction kept about 17% of constraints given only in conversation.
    - C253: durable instruction files survive `/compact`.
    - C115, C160: compliance declines as a session grows (both qualified).
    - C294: T3 Code runs one model per thread.
  - *Against assuming more agents helps:*
    - C089: the claim that multi-agent beats single-agent is contradicted.
    - C121: no general advantage at matched compute.
    - C235: single-agent frameworks repaired more issues.
    - C243: errors accumulate across delegation.
    - C242: worktrees isolate files, not compatibility; naive parallel work passed 2 of 6.
    - C090: users corrected most misalignment, which weighs on a human acting as coordinator.
  - *Costs:*
    - C199: agentic coding uses about 1000x the tokens of code chat.
    - C237: review loops cost about 4.5x the tokens.
    - The orchestrator pattern used about 15x the tokens of chat (workspaces-04).
    - Fresh-session cold-start cost has not been measured.
- **Runtime facts on OpenCode 2.0.20 (this project):**
  - Only `-m` routes a primary session's model.
  - Subagent pins hold unless the parent passes `model`, and no permission rule can stop that.
  - **G1:** a session continued with `-s` and no `-m` kept its original `-m` model (2 of 2).
  - **G2:** two `run --standalone` sessions ran in parallel with different `-m` models; each was served its own model, with no store conflict (1 pair).
  - Session export records the agent, model and every tool call. That makes it an audit trail per session.
- **Workspace already allows multi-session** (`.sw/collaboration.md`): one Leader per human, worker sessions that the human opens per package, the task record as the truth, and "go" and "done" carried by messaging or by the human.
  - It forbids automatic worktrees and branches.
  - It serializes writers unless file ownership is disjoint.
  - It stops spawning on quota limits.
  - Missing: headless launches started by the Leader, and any launcher.

## Options

1. **Status quo (subagents only).**
   - Fast and low-friction.
   - The model is not guaranteed: the parent can override it, and nothing enforces the pin.
   - The child shares the parent's process and quota.
2. **Multi-session replacing subagents.** Every delegated package runs as `opencode run --agent X -m <tier model>`, coordinated through task records.
   - The model is guaranteed by `-m`, and no parent can override it.
   - Context is clean.
   - There is a per-session audit export.
   - Parallel work fits disjoint packages.
   - Costs: a cold start per session, no live back-channel (results come only through files and JSON output), and harder coordination (C242, C243, C090).
   - The Leader would need shell permission to run `opencode run`, which is a nested harness inside its own shell rules.
   - Claude-subscription terms for scripted sessions are unresolved (C093, C283, C329).
3. **Hybrid (Leader's suggestion).**
   - Keep in-session subagents for short read-only work, such as discovery and review summaries, where any capable model will do.
   - Use separate `-m` sessions for:
     - executor packages that must run on a specific tier model;
     - long or multi-step packages, which benefit from a fresh context (C250, C251);
     - disjoint parallel packages.
   - A thin launcher would read the local tier map, start `opencode run --agent X -m M --title <task>`, and write the session ID into the task record. Proposal 1 of the U1 decision (always pass `-m`) would then be enforced by code instead of documentation.

## Gaps, if this is ever taken further

- Measured cold-start and token cost of a session versus a subagent, on the same task.
- How headless `run` handles `ask` permissions: whether it rejects, hangs or auto-approves. `--auto` approves everything that is not denied.
- Concurrent sessions in one checkout writing the same files. This is expected to conflict and would need disjoint ownership.
- Whether `--fork` keeps the model, and what the interactive TUI does.
- Provider terms for several concurrent scripted sessions.

## Next action

None required. If the owner wants to pursue it, the smallest step is a submission for the option 3 launcher (`sw session start <role> <task>`), plus a scratch test of the gaps above.
