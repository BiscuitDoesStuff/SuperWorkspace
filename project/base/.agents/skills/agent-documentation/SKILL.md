---
name: agent-documentation
description: Maintain concise agent instructions and documentation while preserving canonical sources and historical evidence.
---

# Agent documentation

Use for an approved documentation, rule or skill change.
All paths below are repository-root relative. `AGENTS.md` is canonical
project policy; `.sw/workspace.md` and `.sw/collaboration.md` own workspace
and record guidance.

## Steps

1. Inspect the requested document, its callers or links, and relevant current
   evidence.
2. Choose the owning source: the project state file named in `AGENTS.md` for
   implemented state and authorization; Git for branch, commit, publication
   and worktree facts; the changelog and dated task records for history;
   `.sw/collaboration.md` for record format. When a generator owns the file,
   edit its source, not the generated copy.
3. Write for the next task (rules below).
4. Check links, paths, frontmatter when present, and consistency with
   canonical policy; run `git diff --check` and trailing-whitespace checks on
   new files.

## Write for the next task

- Put each rule in its owning source and link to it from skills.
- Prefer short actionable instructions and concrete paths over repeated
  background. Keep always-loaded text small; move procedures into skills.
- Distinguish implemented, authorized, proposed, blocked, and unverified work.
- Preserve dated evidence; add a correction event rather than rewriting
  another author.
- Update current state only after the corresponding implementation and checks
  exist.
- Avoid hand-maintained live SHA inventories and duplicate memory or status
  ledgers.
- Date every volatile fact (`Observed YYYY-MM-DD`) and keep it out of
  instructions when a procedure can replace it.
- Use original project wording; do not import external instructions or
  dependencies.
- Describe tool limitations accurately and keep harness details out of
  product policy.

## Decisions

- Sources contradict: resolve explicitly; never silently promote history to
  current policy.
- A new instruction could be read as authorizing future work: reword it.
- A lesson becomes a rule, check or skill only after review, when it recurs or
  caused a failure.

## Exit

Report the changed files, exact checks and any unresolved cross-document
dependency. Keep documentation checks distinct from build or interactive
evidence.
