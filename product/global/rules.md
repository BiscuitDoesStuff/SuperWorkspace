# Global workspace rules (SuperWorkspace)

Project policy lives in the project's `AGENTS.md`; SuperWorkspace projects add
`.sw/workspace.md` (roles, tiers, permissions) and `.sw/collaboration.md`
(records, messages, branches). Those own the rules; this block only states how
work runs on this machine.

## Model routing
- Planning, architecture, review: the tier the rubric picks, in a fresh
  session. Never switch a running session's model.
- Implementation, docs, mechanical edits: light tier by default.
- Review after implementation passes its checks: the project's `/review`.
- Smallest working change, shortest diff (`minimal-change`).
- Minimize tokens: batch tool calls, never re-read files already in context,
  terse replies, no unrequested prose.

## Agent coordination
- Roles are defined per project in `.opencode/agents/` (Claude pointers in
  `.claude/agents/`); read that list instead of assuming names.
- The main session is the Project Leader: it coordinates and dispatches.
  Specialists do the work and return findings, questions, and blockers; workers
  never spawn teams.
- Every dispatch carries the task, exact scope, file ownership, acceptance
  criteria, and validation owner.

## GitHub (gh CLI)
- Default read-only: `gh issue list|view`, `gh pr list|view|checks|diff`,
  `gh run list|view|watch`. A project may opt in to tier 1 in `.sw/config.json`
  (issues, comments, draft PRs). Merging, releases, and repo settings always
  belong to the human; hand over the exact command instead of running it.

## Git discipline
- Conventional commits: feat/fix/docs/refactor/test/chore.
- Branches: `main` plus each contributor's own `<user>/<user>-worktree`. No task,
  feature, review, or sandbox branches; never work on another contributor's branch.
- Never force-push, `reset --hard`, `clean`, stash, or discard existing work;
  never overwrite uncommitted changes. Commits require an explicit request.
- Agents never push. Humans publish their own completed work.
