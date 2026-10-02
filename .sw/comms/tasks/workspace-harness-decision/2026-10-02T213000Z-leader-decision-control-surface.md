# workspace-harness-decision - decision - one control surface; Claude on subscription via Claude Code - 2026-10-02T213000Z - Leader

- **Author / audience:** Workspace Project Leader (Claude Opus 5.5, Claude Code desktop); owner and the next Leader session.
- **Approval:** owner in session, 2026-10-02, answering the [handoff](2026-10-02T203000Z-leader-handoff-control-surface.md) open decisions:
  - "lets drop the effort change requirement" (effort is not a control-surface requirement);
  - "I want to sign in through a subscription, that is requirement" (Claude access);
  - "Yes one control surface" (replaces the one-harness criterion).
- **Status:** decided. Nothing implemented. The launcher is a proposal and needs its own submission and approval.
- **Branch / base:** `main` at `ddd155c`, plus the uncommitted work listed in the handoff. No commit or push unless the owner asks.

## Decisions

1. **Effort:** dropped as a requirement for the control surface. Tiers stay model-only. Re-add only when a session is observed to overspend or underperform at its default effort.
2. **Claude access:** subscription login is an owner requirement. Per the corpus, a subscription may be used in the unmodified Claude Code program (C093 notes; C324), not through third-party clients (C093) or automated access without an API key (C283). So Claude runs in **Claude Code**, not OpenCode.
3. **Criterion change:** "Claude models in the same harness as every other model and role" is replaced by **one control surface and one set of task records**: Claude roles run in Claude Code on the subscription; other roles run in OpenCode. Claude Code cannot host non-Claude models (C269).
4. **U1 harness (revised):** OpenCode for non-Claude roles; Claude Code for Claude roles. Kilo stays the fallback for OpenCode. Re-check routing after each OpenCode upgrade.

## Leader evaluation (recorded evidence only; nothing verified at runtime)

- Dropping effort does not change the OpenCode/Kilo choice: tiers were already model-only, and the free/open-source constraint had already excluded the only harnesses with per-agent effort (Cursor, Factory).
- Control-surface options: a plain `sw session start <role> <task>` script is preferred. It enforces `-m` (OpenCode) and `--model` (Claude Code) in code and adds no dependency. T3 Code is set aside (alpha, Full-access default, unreproduced Windows issues, no roles; C293, C296, C298, C294); revisit only if a GUI is wanted. It also drives Claude Code with a subscription login (C299).
- Accepted costs: Claude and non-Claude roles cannot call each other as subagents across harnesses; they coordinate through task records (hybrid option 3 of the [multi-session exploration](../workspace-multi-session/2026-10-02T190000Z-leader-exploration.md)). Enforcement must cover Claude Code permissions and hooks as well as OpenCode; the git hardening covers OpenCode only. Claude usage draws from subscription limits (C324), so scripted Claude sessions stay few and bounded.

## Open

- Launcher submission (not approved): routes each role by its tier to `claude` / `claude -p --model <m>` or `opencode run --agent X -m <m>`, records the session ID in the task record, and enables the generated `.claude/agents/` adapter in Workspace. Includes a scratch test of headless `ask` handling, cold-start cost and `--fork` model retention, with free models for OpenCode.
- Optional runtime check of the git hardening; commit of the uncommitted work.
