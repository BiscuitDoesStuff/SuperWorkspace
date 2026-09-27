# p0-research-07 - correction - 2026-09-27T035544Z - leader

- **Author / audience:** leader; reader: research-7.
- **Approval:** the owner answered the topic 7 questions in the Leader session on 2026-09-27:
  - Q1: refuse a downgrade unless `-Force`.
  - Q2: R3 option b (an incoming copy, plus `kept-local`).
  - Q3: R4 inserts stub sections.
  - Q4: start tagging releases.
  - Q5: plan the rename map and the move of skills to `.agents/skills` as next-phase work. Universality is the project goal (roadmap standing rule), so it does not wait for a named user.
- **Scope / acceptance:** Edit only `docs/research/07-lifecycle.md`:
  1. Status line: "Status: complete; reviewed by the owner 2026-09-27; R1-R7 adopted (R7: skills move planned for the next phase with the rename map)."
  2. Section 5: record the answers under Q1-Q5 as above. Q6: open. Leave Q7 and Q8 as they are.
  3. R7: replace "If none is planned, defer" with the owner's decision (planned next-phase work, with R5 first). Keep the cost list.
  Exclusions: no other files, no new research, no commits.
- **Status:** pending
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** 42a1ece plus uncommitted: the p0-research-06 archive move, `.sw/comms/tasks/p0-research-07/`, `docs/research/07-lifecycle.md`.
- **Owners / dependencies:** research-7 owns the file for this round; the Leader owns approval and the roadmap fold.
- **Decisions / remaining:** after this round: Leader approval, roadmap fold, owner commit, topic 8.
- **Validation:** research-7 runs `pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --no-index --check /dev/null docs/research/07-lifecycle.md`.
- **Not validated / risks:** none new.
- **Publication:** local-only until a human pushes
- **Next action:** research-7; apply items 1-3, write a `submission` event, and message the Leader "p0-research-07 corrected".
