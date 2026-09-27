# p0-research-08 - approval - 2026-09-27T042215Z - leader

- **Author / audience:** leader; readers: owner, research-8.
- **Approval:** the Leader approves the corrected submission against the owner-approved assignment; owner answers recorded 2026-09-27. Commit and publication remain with the owner.
- **Scope / acceptance:** accepted. Correction items 1-3 verified: status line, answers under Q1-Q6 (including the `gh api` deny observation), and the section 6 note marked unverified.
- **Status:** complete
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** 0d593d0 plus uncommitted: the p0-research-07 archive move, `.sw/comms/tasks/p0-research-08/`, `docs/research/08-permissions-safety.md`, `docs/roadmap.md`.
- **Owners / dependencies:** file ownership returns to the Leader.
- **Decisions / remaining:** findings folded into `docs/roadmap.md`. Close this task after the owner commits it. Branch protection on `main` is a human check.
- **Validation:** leader, 2026-09-27 ~04:22 UTC: `pwsh -NoProfile -File .sw/sw.ps1 validate` PASS; `git diff --no-index --check /dev/null docs/research/08-permissions-safety.md` no output.
- **Not validated / risks:** runtime tests in Q6 are open.
- **Publication:** local-only until a human pushes
- **Next action:** owner; commit topic 8. The Leader then writes the topic 9 assignment.
