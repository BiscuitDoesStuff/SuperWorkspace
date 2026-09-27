# p0-research-01 - correction - 2026-09-27T013434Z - leader

- **Author / audience:** leader; reader: research-1.
- **Approval:** owner answered the topic 1 questions in the Leader session on 2026-09-27: R1 and R2 as corrected adopted; seed an empty stub; R3 accepted; Cowork not used.
- **Scope / acceptance:** Edit only `docs/research/01-structure-and-extension.md`:
  1. Status line: "Status: complete; reviewed by the owner 2026-09-27, R1-R4 adopted (R2 corrected)."
  2. Section 4, R2: replace it with the correction from the review event (`2026-09-27T012806Z-leader-review.md`). `product/global/rules.md` is already tier-neutral, so there is no product rules change. The personal lines (model names, Ponytail, `code-review`, free-first) are owner edits inside the managed block in `~/.claude/CLAUDE.md`, and they move to `rules.local.md`. Keep "remove, do not override" (F2).
  3. Section 4, R1, last bullet: the kit creates `rules.local.md` only if it is missing, as an empty stub holding a short comment header and no opinions, and never rewrites it.
  4. Section 5: record the answers under the questions. Q1: adopted as corrected. Q2: empty stub. Q3: still open, a runtime test before implementation. Q4: Cowork is not used; a default Cowork project points at this folder, so the import would be skipped there if it is ever used (accepted risk). Q5: noted, and the Leader proposes the cap count research calls only.
  Exclusions: no other files, no new research, no commits.
- **Status:** pending
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** 65d6b7092c3224928a445aa2f464ffbef39f93fe plus uncommitted: M docs/roadmap.md; ?? .sw/comms/tasks/p0-leader/; ?? .sw/comms/tasks/p0-research-01/; ?? docs/research/01-structure-and-extension.md
- **Owners / dependencies:** research-1 owns the file for this round; the Leader owns approval and the roadmap fold.
- **Decisions / remaining:** after this round: Leader approval, roadmap fold, and a topic 2 assignment.
- **Validation:** research-1 runs `pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --no-index --check /dev/null docs/research/01-structure-and-extension.md`.
- **Not validated / risks:** none new.
- **Publication:** local-only until a human pushes
- **Next action:** research-1; apply items 1-4, write a `submission` event, and message the Leader "p0-research-01 corrected".
