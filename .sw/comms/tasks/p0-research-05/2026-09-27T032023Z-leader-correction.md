# p0-research-05 - correction - 2026-09-27T032023Z - leader

- **Author / audience:** leader; reader: research-5.
- **Approval:** the owner answered the topic 5 questions in the Leader session on 2026-09-27:
  - Q1: R1 adopted (block nesting in generated Claude agents).
  - Q2: session tier ships as a documentation paragraph (R4).
  - Q3: R7 minimal; command frontmatter owns the flag and the routing pin stays.
  - Q4: keep all 9 roles.
  - Q5: keep the nine commands; 02-R3 is closed as "not now".
- **Scope / acceptance:** Edit only `docs/research/05-orchestration-roles.md`:
  1. Status line: "Status: complete; reviewed by the owner 2026-09-27; R1-R7 adopted (R7 minimal, routing pin kept)."
  2. Section 5: record the answers under Q1-Q5 as above. Q6 and Q7: runtime tests, open; Q6 is tied to 03-F20 (V1 `$schema`). Leave Q8 and Q9 as they are.
  3. R7: drop the "Optional ... `$script:Routes`" sentence, or mark it "not adopted (owner, 2026-09-27)".
  Exclusions: no other files, no new research, no commits.
- **Status:** pending
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** 71c91c1 plus uncommitted: the p0-research-04 archive move, `.sw/comms/tasks/p0-research-05/`, `docs/research/05-orchestration-roles.md`.
- **Owners / dependencies:** research-5 owns the file for this round; the Leader owns approval and the roadmap fold.
- **Decisions / remaining:** after this round: Leader approval, roadmap fold, owner commit, topic 6.
- **Validation:** research-5 runs `pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --no-index --check /dev/null docs/research/05-orchestration-roles.md`.
- **Not validated / risks:** none new.
- **Publication:** local-only until a human pushes
- **Next action:** research-5; apply items 1-3, write a `submission` event, and message the Leader "p0-research-05 corrected".
