# p0-research-08 - submission - 2026-09-27T042154Z - research-8

- **Author / audience:** research-8
- **Approval:** owner answered topic 8 questions 2026-09-27 (leader correction 2026-09-27T042122Z): R1-R4, R6-R8 adopted; R5 not now.
- **Scope / acceptance:** Correction items 1-3 applied to `docs/research/08-permissions-safety.md` only: status line; section 5 answers for Q1-Q6 (Q5 records the denied read-only `gh api` query as live evidence that the Claude denylist applies to the main session; Q6 open; Q7-Q8 unchanged); section 6 adds the unverified note that agents read skills, so Codex's `.agents` read-only protection is expected to be harmless. No other files, no new research, no gh commands, no commits.
- **Status:** complete
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019 (per assignment; not re-fetched)
- **Checked revision / changed:** 0d593d03c265eb174ef0aa2204bd3a7c7696f944 plus uncommitted:  D .sw/comms/tasks/p0-research-07/2026-09-27T034623Z-leader-assignment.md;  D .sw/comms/tasks/p0-research-07/2026-09-27T035212Z-research-7-submission.md;  D .sw/comms/tasks/p0-research-07/2026-09-27T035254Z-leader-review.md;  D .sw/comms/tasks/p0-research-07/2026-09-27T035544Z-leader-correction.md;  D .sw/comms/tasks/p0-research-07/2026-09-27T035612Z-research-7-submission.md;  D .sw/comms/tasks/p0-research-07/2026-09-27T035630Z-leader-approval.md; ?? .sw/comms/archive/p0-research-07/; ?? .sw/comms/tasks/p0-research-08/; ?? docs/research/08-permissions-safety.md
- **Owners / dependencies:** research-8 owns the research file for this round; Leader owns approval and the roadmap fold.
- **Decisions / remaining:** Wording note: Q5 says the `Bash(gh api:*)` deny is present at every tier (it is in the always-denied list in `Get-SwClaudeGhDeny`), not tier 0 only. Next: Leader approval, roadmap fold, owner commit, topic 9.
- **Validation:** research-8, 2026-09-27 ~04:22Z: `pwsh -NoProfile -File .sw/sw.ps1 validate` -> PASS; `git diff --no-index --check /dev/null docs/research/08-permissions-safety.md` -> no whitespace errors (exit 1 = file differs, expected).
- **Not validated / risks:** none new; Q6 runtime tests remain open by design.
- **Publication:** local-only until a human pushes
- **Next action:** Leader: approve topic 8 and fold it into the roadmap.
