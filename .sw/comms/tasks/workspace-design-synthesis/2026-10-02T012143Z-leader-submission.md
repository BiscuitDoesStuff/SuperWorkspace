# workspace-design-synthesis - submission - Pass 8 intake recorded - 2026-10-02T012143Z - leader

- **Author / audience:** Project Leader (Claude Opus 5.5, Claude Code desktop); owner and future sessions.
- **Approval:** per the [assignment](2026-10-02T011732Z-leader-assignment.md).
- **Status:** Pass 8 intake complete; U5 stays in progress. U1 is partly resolved; the harness is open.
- **Changed (untracked; unborn `main`):**
  - `docs/workspace-outline.md`:
    - section 5 intro now names E8 and separates owner answers from Leader drafts
    - S1 gains an E8 evidence bullet and revised open points
    - new S2 (U1 partial resolution), plus S3-S6 marked "Decision (draft)"
    - U1 and U5 rows updated; E8 provenance row added; O3 and O7 note the S2 targets
    - "E4-E8" reference; the legend allows owner-pending S entries
    - final sha256 3900f6b9...2f15
  - `docs/workspace-state.md`: Startup task and design-register lines. Final sha256 8fbe0512...99f0.
  - New in this folder: the assignment, this submission and two pre-edit copies (`*.pre-pass8.md`).
- **Owner decisions recorded:** small roster; generator refit; harness open with the owner's
  criterion (Claude models in the same harness as everything else).
- **Leader drafts awaiting owner confirmation:** S3-S6 contents (adapted from E8 s4
  recommendations 2-8); the S2 tier-rubric row (held with the harness) and branching row
  (retained; also imposed by global rules).
- **Corpus read (read-only):** at tag `archive/2026-10-02-workspaces-08` (1fcbc0d):
  - the report's Summary and s1-s6
  - the Pass 8 review and closure records
  - claim grades taken from the reviewed report rows; the reviewer re-checked them against the register.
- **Validation:**
  - `pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks`: exit 0, PASS, after the review fixes. It reports `local links=0`.
  - Manual check: every relative link in both docs resolves. The E8 locators exist in commit 1fcbc0d (`git cat-file -e`).
  - Trailing-whitespace and conflict-marker greps on the changed files found nothing. Both docs are LF.
  - `git diff --check` was not run; untracked files make it vacuous.
- **Review:** an advisory read-only `project-review` confirmed that the cited IDs and grades match and that no harness is selected. It raised 2 must-fix items, 5 should-fix items and 7 notes. Applied:
  - Must-fix: owner answers are now separated from Leader drafts; the U1 row no longer implies that tier and branching were owner-decided.
  - Should-fix: C233 is cited as declared; the layering justification was narrowed; the Windows isolation wording is consistent; isolation is a research comparison factor, not an owner criterion; the loading-verification cross-reference was fixed.
  - Trims: duplicate routing, C233 and Windows passages removed; the intro was merged; S1 points to S4; the S3 "10-50" wording is attributed.

  Not re-reviewed after the fixes; the checks were re-run.
- **Not validated / risks:** no runtime, loading, routing or hook tests; no original-source audit; no harness research; Workspace has no Git baseline (U4).
- **Publication:** local-only, uncommitted.
- **Next action (owner's choice):**
  - confirm or revise the S3-S6 drafts and the S2 tier and branching rows
  - approve a corpus-side research question for the harness: harnesses that run Claude and non-Claude models side by side with per-agent model and effort routing, plus Windows isolation and provider terms
  - separately scope the roster reduction and the generator refit
