# p1-checkpoint-runtime - summary

- **Outcome:** Desktop checkpoint (owner, 2026-09-27; Claude desktop app, OpenCode desktop 2.0.17/2.0.18). Claude: git push denied; read-only role has no Edit/Write (Bash by instruction only); .env read via Bash cat with no prompt; /context 44.8k total, kit share about 2.3k, bytes/4 estimate fine. OpenCode: the project-level permissions list (V2, and V1 in an experiment) is ignored, so git push ran, commits and .env reads gave no prompt; agent-frontmatter rules work (project-review shell denied, no edit tool); children load AGENTS.md, cannot nest; the subagent flag is honoured both ways; no cross-session messaging; built-in Build and Plan agents carry no kit rules. No $schema warning, so no action on that item. 'opencode models --verbose' no longer exists (affects package 8). Follow-up for the owner's decision: a permission correction package (repeat the session-wide rules in agent frontmatter, correct the harness table, widen the read-only allowlist) or package 6.
- **Closed:** 2026-09-27 09:17:15Z by claude at aba4551468078b9acae7f44f75cf8cf0737e4256
- **Events:** 12, kept in `events/` for evidence; read this summary instead.

- 2026-09-27T073149Z-leader-assignment.md
- 2026-09-27T080255Z-leader-progress.md
- 2026-09-27T081333Z-leader-progress.md
- 2026-09-27T082348Z-leader-progress.md
- 2026-09-27T082835Z-leader-progress.md
- 2026-09-27T083103Z-leader-progress.md
- 2026-09-27T083807Z-leader-progress.md
- 2026-09-27T084341Z-leader-progress.md
- 2026-09-27T085042Z-leader-progress.md
- 2026-09-27T090041Z-leader-progress.md
- 2026-09-27T090707Z-leader-progress.md
- 2026-09-27T091702Z-leader-approval.md
