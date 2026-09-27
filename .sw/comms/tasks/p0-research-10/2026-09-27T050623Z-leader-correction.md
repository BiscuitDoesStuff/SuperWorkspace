# p0-research-10 - correction - 2026-09-27T050623Z - leader

- **Author / audience:** leader; reader: research-10.
- **Approval:** the owner answered the topic 10 questions in the Leader session on 2026-09-27:
  - R1 adopted (solo mode derived from `users: []`; not configurable yet), after the Leader explained it.
  - Q1: the owner made the repository **public** on 2026-09-27, so protection is available on Free. The owner will set the minimal solo ruleset from the Leader's steps.
  - Q3: no hosted agent planned.
  - R3-R5 adopted as text only, with no `sw comms event` collision check.
  - Protection state: the owner checked on 2026-09-27 that `main` is not protected (before the ruleset).
- **Scope / acceptance:** Edit only `docs/research/10-collaboration-branches.md`:
  1. Status line: "Status: complete; reviewed by the owner 2026-09-27; R1-R6 adopted (R3 text only)."
  2. F16: add "Update 2026-09-27: the owner made the repository public; protection is now available on Free." Keep the original probe result as dated evidence.
  3. Section 1 "not covered" line on the protection state: record the owner's check (`main` not protected, 2026-09-27).
  4. Section 5: record the answers. Q1: public now; the solo ruleset is a human action. Q2: open; the rationale is recorded when `decisions.md` gets the branch entry. Q3: no. Q4: text only. Q5: yes, per R1.
  Exclusions: no other files, no new research, no `gh` calls, no commits.
- **Status:** pending
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** fe10015 plus uncommitted: the p0-research-09 archive move, `.sw/comms/tasks/p0-research-10/`, `docs/research/10-collaboration-branches.md`.
- **Owners / dependencies:** research-10 owns the file for this round; the Leader owns approval and the roadmap fold.
- **Decisions / remaining:** after this round: Leader approval, roadmap fold, owner commit, then Phase 0 step 6.
- **Validation:** research-10 runs `pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --no-index --check /dev/null docs/research/10-collaboration-branches.md`.
- **Not validated / risks:** none new.
- **Publication:** local-only until a human pushes
- **Next action:** research-10; apply items 1-4, write a `submission` event, and message the Leader "p0-research-10 corrected".
