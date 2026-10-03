# workspace-harness-decision - decision - launcher and S4-S6 open points - 2026-10-02T225000Z - Leader

- **Author / audience:** Workspace Project Leader (Claude Opus 5.5, Claude Code desktop); owner and the next Leader session.
- **Approval:** owner in session, 2026-10-02: "I accept all of these". These are design decisions for the drafts; each change still needs its own submission approval before implementation.
- **Status:** decided; not implemented.
- **Branch / base:** `main` at `0701522`. Uncommitted.

## Decisions

1. **Per-user configuration (owner requirement):** every installing user configures tools, models and accounts locally; shared files carry none of them (outline O10).
2. **Launcher routing:** each user's local tier map sets the model per tier; the model decides the tool (Claude model → Claude Code, other → OpenCode). No role is fixed to Claude in shared files. The Claude agent model comes from the local map (default `opus`); the `model: opus` contract becomes "a Claude alias from the local map, never in shared files". The owner uses `opus` for every Claude tier.
3. **Interactive Claude session ID:** the launcher generates the ID and passes `--session-id` if Claude Code supports it (to be confirmed with `claude --help`, which needs owner approval to run); otherwise it records "not captured".
4. **S4, Claude Code enforcement:** generate Claude git deny and ask rules from the same rule lists as OpenCode (`$script:SessionGitVerbs`, `$script:SessionWrappers`) before any Claude role does write work. On Claude, `project-review` gets no Bash if a read-only git allowlist can't be expressed (Claude cannot deny all then allow). `project-research`'s Markdown-only limit stays a stated rule (profile role, not enabled).
5. **S5, `AGENTS.md` on Claude:** `sw claude enable` writes a one-line `.claude/CLAUDE.md` containing `@AGENTS.md`, inside the per-user, git-ignored adapter; no shared root `CLAUDE.md`. That Claude Code reads `.claude/CLAUDE.md` is unconfirmed: add to R2 or verify in the approved launcher runtime check.
6. **S6, skills:** core skills are `task-handoff`, `minimal-change` and `focused-review`. `research` moves to the research profile. `free-models` becomes an optional local skill. The other three stay but become optional rather than mandatory; removal only after paired with/without trials show no benefit (C247, C248).

## Open

- R1 (headless Claude on a subscription) and R6 (OpenAI per-user route and terms) remain open research requests.
- S3 scope is unchanged by these decisions.
