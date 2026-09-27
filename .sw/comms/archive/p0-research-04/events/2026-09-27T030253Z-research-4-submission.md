# p0-research-04 - submission - 2026-09-27T030253Z - research-4

- **Author / audience:** research-4; reader: the Leader.
- **Approval:** owner answers of 2026-09-27, relayed in the leader correction 2026-09-27T030221Z (Q1 R1/R2 adopted; Q2 count agent descriptions for the leader; Q3 no tokenizer, use `/context`).
- **Scope / acceptance:** correction items 1-3 applied to `docs/research/04-context-efficiency.md` only: (1) status line replaced with the given text; (2) section 5 records the answers: Q1 adopted, Q2 yes, Q3 no tokenizer and bytes/4 checked against `/context` (Q4), Q4 and Q5 runtime tests open; Q6 and Q7 unchanged; (3) the tokenizer install route replaced with "verify against `/context` (Q4); no tokenizer dependency (owner, 2026-09-27)" in both "Not covered" and R1. No other files, no new research, no commits.
- **Status:** complete
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019 (from the assignment; not re-fetched)
- **Checked revision / changed:** 1ca4e7a plus uncommitted: the p0-research-03 archive move, `.sw/comms/tasks/p0-research-04/`, `docs/research/04-context-efficiency.md`.
- **Owners / dependencies:** research-4 owned the file for this round; the Leader owns approval and the roadmap fold.
- **Decisions / remaining:** section 5 gained the line "Owner answers recorded 2026-09-27 (relayed by the Leader)", matching topic 3's format. Remaining: Leader approval, roadmap fold, owner commit.
- **Validation:** research-4; 2026-09-27 ~03:03Z; `pwsh -NoProfile -File .sw/sw.ps1 validate` → PASS; `git diff --no-index --check /dev/null docs/research/04-context-efficiency.md` → no output.
- **Not validated / risks:** none new; research calls unchanged (18).
- **Publication:** local-only until a human pushes
- **Next action:** Leader; approve or return the correction; evidence is a leader approval event.
