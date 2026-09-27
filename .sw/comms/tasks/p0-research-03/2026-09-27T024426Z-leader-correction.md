# p0-research-03 - correction - 2026-09-27T024426Z - leader

- **Author / audience:** leader; reader: research-3.
- **Approval:** the owner answered the topic 3 questions in the Leader session on 2026-09-27:
  - Q1: R1 adopted (a skill, no command).
  - Q2: public keyless calls are fine. Use the owner's local project `C:\DevProjects\ModelAnalysis` ("AIProj") as the precedent. The product skill stays neutral, and the owner's `rules.local.md` may point the advisor at their latest report.
  - Q3: deferred to the roadmap rewrite.
  - Defects (F13 stale GLM entry, F20 V1 `$schema`): recorded, fixed after the rewrite; the kit freeze holds.
- **Scope / acceptance:** Edit only `docs/research/03-model-advisor.md`:
  1. Status line: "Status: complete; reviewed by the owner 2026-09-27; R1, R2, R4, R6, R7 adopted; R3 and the F20 fix recorded for after the rewrite; R5 `effort` deferred."
  2. Add one local-evidence finding F22 (label it local context, as `01` did). Read `C:\DevProjects\ModelAnalysis\README.md` only (read-only; do not run it, do not open any key or `.env` file). Record what it shows about keyless retrieval (which sources need no key) and its strict-$0 free filter definition. Cite the path and the file's date. No new web research calls.
  3. R1 step 3: reference F22's filter as the tested method, and add that a user's `rules.local.md` (topic 1 R1) may point the advisor at a local snapshot report. The product skill names no personal tool.
  4. Section 5: record the answers. Q1: adopted. Q2: yes, public keyless calls; F22 precedent; personal report via the overlay. Q3: deferred to the rewrite. Q4: open. Q5 and Q6: runtime tests; `opencode` is not on the owner's Bash PATH, so they are deferred to implementation. R3 and F20: recorded as known defects, fixed after the rewrite.
  5. Supersedes: leave as is; mark the F6 note on 02-R4/R5 for the Leader's roadmap fold.
  Exclusions: no other files, no new research calls, no commits.
- **Status:** pending
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** 7ba9a09 plus uncommitted: the p0-research-02 archive move, `.sw/comms/tasks/p0-research-03/`, `docs/research/03-model-advisor.md`.
- **Owners / dependencies:** research-3 owns the file for this round (and reads the one ModelAnalysis README); the Leader owns approval and the roadmap fold.
- **Decisions / remaining:** after this round: Leader approval, roadmap fold, owner commit, topic 4.
- **Validation:** research-3 runs `pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --no-index --check /dev/null docs/research/03-model-advisor.md`.
- **Not validated / risks:** none new.
- **Publication:** local-only until a human pushes
- **Next action:** research-3; apply items 1-5, write a `submission` event, and message the Leader "p0-research-03 corrected".
