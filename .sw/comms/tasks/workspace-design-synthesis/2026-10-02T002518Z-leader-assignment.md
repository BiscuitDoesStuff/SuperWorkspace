# workspace-design-synthesis - assignment - U5 synthesis, first decision - 2026-10-02T002518Z - leader

- **Author / audience:** Project Leader (Claude Opus 5.5, Claude Code desktop); owner and future sessions.
- **Approval:** owner in session on 2026-10-01 (local): "Start the U5 design synthesis in
  docs/workspace-outline.md from the reviewed AI-Research [2] corpus (Passes 4-7, current
  claims register). First decision: shared core plus per-project-type profiles. Leave U1
  harness choice open pending the reviewed workspaces-08 report. Plan first; no runtime
  changes." Plan approved in the same session. The owner chose to cite their earlier
  statement ("an all-purpose workspace, that can be heavily adapted to fit the specific
  project type", recorded in corpus `.sw/comms/tasks/workspaces-08/2026-10-02T000100Z-leader-submission.md`)
  as the source for the decision, not as a new D requirement.
- **Scope / acceptance:**
  - Add a design-synthesis section to `docs/workspace-outline.md` with entry S1 (shared core
    plus per-project-type profiles): decision, core/profile split, layering rule, evidence
    with claim IDs, limits and open sub-points.
  - Keep the layering mechanism and profile budgets provisional pending Pass 8 H1/H3.
    U1 stays open and links to workspaces-08.
  - Add E4 (Pass 4) provenance. Mark U5 in progress. Update the Startup task line in
    `docs/workspace-state.md`.
- **Status:** in_progress.
- **Branch / base:** unborn local `main`, no commits; all files untracked. Pre-edit outline
  copy: `workspace-outline.pre-synthesis.md` in this folder (sha256 e743d434...93bc).
  `docs/workspace-state.md` sha256 930fa02c...55ed before edits.
- **Corpus read base:** `AI-Research [2]` `main` at 57805673300dc71dc14a27727ec735c227cd4a5f,
  with uncommitted Pass 8 setup files (not read as evidence). Read-only.
- **Owners / dependencies:** Leader is sole writer and validation owner. Allowed writes:
  `docs/workspace-outline.md`, `docs/workspace-state.md`, new files in this folder. A
  read-only `project-review` agent owns no files. No runtime, config, managed-block, kit-source,
  v0.2 or corpus changes; no commits.
- **Validation plan:** `pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks`; explicit
  whitespace/conflict-marker check on changed files (an untracked `git diff --check` is vacuous).
- **Next action:** bounded corpus read, outline edit, checks, review, submission.
