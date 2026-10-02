# workspace-design-synthesis - assignment - Pass 8 intake: U1, S1 open points, U5 - 2026-10-02T011732Z - leader

- **Author / audience:** Project Leader (Claude Opus 5.5, Claude Code desktop); owner and future sessions.
- **Approval:** owner in session (2026-10-01 local): "Take in the reviewed workspaces-08 report
  (corpus tag `archive/2026-10-02-workspaces-08`, s4): resolve U1, revise S1's open points, and
  continue U5." Owner answers in the same session:
  - Harness: "I would rather do more search for better options, my ideal is having claude code
    models in the same harness as everything else." The harness stays open; no harness is selected.
  - Role roster: small roster (Leader inline; optional read-only explorer, repository-exploring
    reviewer, one executor).
  - Generator and layout: refit the generator around S1's layers.
  - New S entries: review and acceptance tests; enforcement and isolation; continuity and
    compaction; skills curation.
- **Scope / acceptance:**
  - `docs/workspace-outline.md`: revise S1's open points with Pass 8; add S2 (U1 partial
    resolution) and S3-S6; update U1 and U5; add E8 provenance; note the S2 target on O3 and O7.
  - `docs/workspace-state.md`: Startup task and design-register lines.
  - Decisions set design direction only; no roster removal, generator refit or harness change.
- **Branch / base:** unborn local `main`, no commits; all files untracked. Pre-edit copies in this
  folder: `workspace-outline.pre-pass8.md` (sha256 961ad403...69f2) and
  `workspace-state.pre-pass8.md` (sha256 ee7436aa...6505).
- **Corpus read base:** `AI-Research [2]` tag `archive/2026-10-02-workspaces-08` = `main` at
  1fcbc0de1e029af43bebf3e57fb24ceba097f778 (clean). Read: report Summary, s1-s6; Pass 8 review and
  closure records. Read-only.
- **Owners / dependencies:** Leader is sole writer and validation owner. Allowed writes: the two
  docs above and new files in this folder. A read-only `project-review` agent owns no files. No
  runtime, config, managed-block, kit-source, v0.2 or corpus changes; no commits.
- **Validation plan:** `pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks`; manual link and
  locator check; whitespace and conflict-marker greps on changed files (untracked `git diff --check`
  is vacuous).
- **Next action:** outline edit, checks, review, submission.
