# p0-research-08 - correction - 2026-09-27T042122Z - leader

- **Author / audience:** leader; reader: research-8.
- **Approval:** the owner answered the topic 8 questions in the Leader session on 2026-09-27:
  - Q1 and Q2: R1 and R2 adopted.
  - Q3: R8 adopted; `external_directory` becomes `ask`.
  - Q4: R5 not now.
  - Q5: the owner asked the Leader to check read-only. The Leader's `gh api repos/.../branches/main` call was denied by this session's permission rules, which are the kit's tier-0 `gh api` deny. The Leader did not route around it. Branch protection stays a human check.
- **Scope / acceptance:** Edit only `docs/research/08-permissions-safety.md`:
  1. Status line: "Status: complete; reviewed by the owner 2026-09-27; R1-R4 and R6-R8 adopted; R5 not now."
  2. Section 5: record the answers under Q1-Q5 as above. For Q5, add the observation that the kit's Claude `gh api` deny blocked a read-only Leader query on 2026-09-27: live evidence that the tier-0 denylist applies to the main session. Q6: open. Leave Q7 and Q8.
  3. Section 6: keep the 07 R7 note. Add that agents read skills and do not edit them, so the `.agents` read-only protection in Codex is expected to be harmless. Mark it unverified.
  Exclusions: no other files, no new research, no commits.
- **Status:** pending
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** 0d593d0 plus uncommitted: the p0-research-07 archive move, `.sw/comms/tasks/p0-research-08/`, `docs/research/08-permissions-safety.md`.
- **Owners / dependencies:** research-8 owns the file for this round; the Leader owns approval and the roadmap fold.
- **Decisions / remaining:** after this round: Leader approval, roadmap fold, owner commit, topic 9.
- **Validation:** research-8 runs `pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --no-index --check /dev/null docs/research/08-permissions-safety.md`.
- **Not validated / risks:** none new.
- **Publication:** local-only until a human pushes
- **Next action:** research-8; apply items 1-3, write a `submission` event, and message the Leader "p0-research-08 corrected".
