# p0-research-06 - correction - 2026-09-27T033803Z - leader

- **Author / audience:** leader; reader: research-6.
- **Approval:** the owner answered the topic 6 questions in the Leader session on 2026-09-27:
  - Q1: R1 adopted.
  - Q2: option c (exclude `.sw/comms/`, cap 10).
  - Q3: option A for `free-models` (procedure only; volatile facts go to dated research).
  - Q4: the Leader trimmed the owner's memory entry to a pointer at `docs/roadmap.md` and the p0-leader record. Done 2026-09-27.
- **Scope / acceptance:** Edit only `docs/research/06-upkeep-memory.md`:
  1. Status line: "Status: complete; reviewed by the owner 2026-09-27; R1-R6 adopted (R2 option c, R5 option A)."
  2. Section 5: record the answers under Q1-Q4 as above. Q5: open. Leave Q6 and Q7 as they are.
  3. R5: state option A as adopted for `free-models`; keep option B only as the rule for any future skill that must hold a snapshot.
  4. F19: add one sentence saying the entry was trimmed to a pointer on 2026-09-27 (owner decision). Quote no content.
  Exclusions: no other files, no new research, no commits.
- **Status:** pending
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** 85db278 plus uncommitted: the p0-research-05 archive move, `.sw/comms/tasks/p0-research-06/`, `docs/research/06-upkeep-memory.md`.
- **Owners / dependencies:** research-6 owns the file for this round; the Leader owns approval and the roadmap fold.
- **Decisions / remaining:** after this round: Leader approval, roadmap fold, owner commit, topic 7.
- **Validation:** research-6 runs `pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --no-index --check /dev/null docs/research/06-upkeep-memory.md`.
- **Not validated / risks:** none new.
- **Publication:** local-only until a human pushes
- **Next action:** research-6; apply items 1-4, write a `submission` event, and message the Leader "p0-research-06 corrected".
