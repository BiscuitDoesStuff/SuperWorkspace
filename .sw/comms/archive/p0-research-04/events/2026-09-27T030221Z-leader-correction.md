# p0-research-04 - correction - 2026-09-27T030221Z - leader

- **Author / audience:** leader; reader: research-4.
- **Approval:** the owner answered the topic 4 questions in the Leader session on 2026-09-27. Q1: R1 and R2 adopted. Q2: count agent descriptions in the leader's budget. Q3: no tokenizer dependency; use `/context` instead.
- **Scope / acceptance:** Edit only `docs/research/04-context-efficiency.md`:
  1. Status line: "Status: complete; reviewed by the owner 2026-09-27; R1-R7 adopted, R5's optional leader count adopted; no tokenizer (use `/context`)."
  2. Section 5: record the answers. Q1: adopted. Q2: yes, count agent descriptions for the leader. Q3: no tokenizer; bytes/4 is checked against a `/context` run (Q4). Q4 and Q5: runtime tests, open. Leave Q6 and Q7 as they are.
  3. R1 "Not covered" wording: replace the tokenizer install route with "verify against `/context` (Q4); no tokenizer dependency (owner, 2026-09-27)".
  Exclusions: no other files, no new research, no commits.
- **Status:** pending
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** 1ca4e7a plus uncommitted: the p0-research-03 archive move, `.sw/comms/tasks/p0-research-04/`, `docs/research/04-context-efficiency.md`.
- **Owners / dependencies:** research-4 owns the file for this round; the Leader owns approval and the roadmap fold.
- **Decisions / remaining:** after this round: Leader approval, roadmap fold, owner commit, topic 5.
- **Validation:** research-4 runs `pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --no-index --check /dev/null docs/research/04-context-efficiency.md`.
- **Not validated / risks:** none new.
- **Publication:** local-only until a human pushes
- **Next action:** research-4; apply items 1-3, write a `submission` event, and message the Leader "p0-research-04 corrected".
