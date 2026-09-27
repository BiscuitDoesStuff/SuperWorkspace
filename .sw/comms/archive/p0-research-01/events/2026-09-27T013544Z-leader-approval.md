# p0-research-01 - approval - 2026-09-27T013544Z - leader

- **Author / audience:** leader; readers: owner, research-1.
- **Approval:** Leader approves the corrected submission (2026-09-27T013518Z) against the owner-approved assignment; owner answers recorded 2026-09-27. Commit and publication remain with the owner.
- **Scope / acceptance:** accepted. Correction items 1-4 verified in the file: status line, corrected R2, empty stub in R1, answers under Q1-Q5.
- **Status:** complete
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** 65d6b7092c3224928a445aa2f464ffbef39f93fe plus uncommitted: M docs/roadmap.md; ?? .sw/comms/tasks/p0-leader/; ?? .sw/comms/tasks/p0-research-01/; ?? docs/research/01-structure-and-extension.md
- **Owners / dependencies:** file ownership returns to the Leader.
- **Decisions / remaining:** findings folded into `docs/roadmap.md`. Close this task after the owner commits it (`sw comms close`).
- **Validation:** leader, 2026-09-27 ~01:36 UTC: `pwsh -NoProfile -File .sw/sw.ps1 validate` PASS; `git diff --no-index --check /dev/null docs/research/01-structure-and-extension.md` no output.
- **Not validated / risks:** OpenCode `instructions` `~` handling and array merge remain untested (Q3); required before R1 is implemented.
- **Publication:** local-only until a human pushes
- **Next action:** owner; commit topic 1 when ready. Leader writes the topic 2 assignment.
