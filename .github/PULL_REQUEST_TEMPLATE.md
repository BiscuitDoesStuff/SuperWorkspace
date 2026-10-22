## Task

Task ID / issue: <id>. Record: `.sw/comms/tasks/<task-id>/`

## Change

<what changed and why, in two or three lines>

## Evidence

- [ ] `powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 validate` passes
- [ ] Build and tests per the AGENTS.md profile (exact commands and results below)
- [ ] Manual/interactive checks: <done by whom, or "not run">
- [ ] `git diff --check` clean

<commands and results>

Below GitHub tier 2 a human merges. At tier 2 the agent may enable auto-merge only
after review and after the relevant CI checks pass on the current revision.
Agents never push to `main`.
