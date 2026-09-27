# p0-research-09 - correction - 2026-09-27T043635Z - leader

- **Author / audience:** leader; reader: research-9.
- **Approval:** the owner answered the topic 9 questions in the Leader session on 2026-09-27:
  - Q1: the research lint is a warning, not an error.
  - Q2: it ships to installed projects and runs only where `docs/research/*.md` exists.
  - Q3: the smoke checklist runs after the rewrite, when the adapter fixes land; OpenCode must be installed first.
  - Q4: evaluations are a practice only; no `claude plugin eval`.
- **Scope / acceptance:** Edit only `docs/research/09-validation-evaluation.md`:
  1. Status line: "Status: complete; reviewed by the owner 2026-09-27; R1-R8 adopted (R3 as a warning, shipped; R7 after the rewrite; R8 practice only)."
  2. Section 5: record the answers under Q1-Q4 as above. Leave Q5 and Q6.
  3. R3: state "warning, shipped to installed projects". Because it is a warning, the 07 and 08 edits are optional; say so.
  Exclusions: no other files, no new research, no commits.
- **Status:** pending
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** 2676728 plus uncommitted: the p0-research-08 archive move, `.sw/comms/tasks/p0-research-09/`, `docs/research/09-validation-evaluation.md`.
- **Owners / dependencies:** research-9 owns the file for this round; the Leader owns approval and the roadmap fold.
- **Decisions / remaining:** after this round: Leader approval, roadmap fold, owner commit, topic 10.
- **Validation:** research-9 runs `pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --no-index --check /dev/null docs/research/09-validation-evaluation.md`.
- **Not validated / risks:** none new.
- **Publication:** local-only until a human pushes
- **Next action:** research-9; apply items 1-3, write a `submission` event, and message the Leader "p0-research-09 corrected".
