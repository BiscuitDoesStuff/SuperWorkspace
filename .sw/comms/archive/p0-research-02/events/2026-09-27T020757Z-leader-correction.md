# p0-research-02 - correction - 2026-09-27T020757Z - leader

- **Author / audience:** leader; reader: research-2.
- **Approval:** the owner answered the topic 2 questions in the Leader session on 2026-09-27. Q1: nobody uses Codex, Gemini, Cursor or Copilot today, but the project is meant to be universal across tools (already a roadmap standing rule). Q2: deferred to the roadmap rewrite. Q5: deferred to the roadmap rewrite.
- **Scope / acceptance:** Edit only `docs/research/02-multi-harness.md`:
  1. Status line: "Status: complete; reviewed by the owner 2026-09-27; R1-R4 and R6 adopted, R5 revised, option b and R3 deferred to the roadmap rewrite."
  2. R5: replace "only when someone uses it" with the owner's direction. Universality is a project goal (`docs/roadmap.md` standing rule "the goal is every major AI app"), so new adapters are planned scope for the roadmap rewrite, not speculative. Codex is first because it needs the fewest files. Keep the reasoning on file counts.
  3. F17: change "Weak" on the negative to "Leader re-verified 2026-09-27: the page lists only `.claude/skills` shapes and plugin `skills/`, and does not mention `.agents/skills`". Mark F3 and F11 "Leader re-verified 2026-09-27" (see `2026-09-27T015024Z-leader-review.md`).
  4. Section 5: record the answers under the questions. Q1: none today; universality is the goal (R5 as revised). Q2: deferred to the roadmap rewrite, to decide together with topic 7 and after the Q3 runtime test. Q3 and Q4: runtime tests, deferred to implementation. Q5: deferred to the roadmap rewrite (touches topic 5). Q6: adopted as a research-skill input for the roadmap.
  Exclusions: no other files, no new research, no commits.
- **Status:** pending
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** 85336e0 plus uncommitted: the p0-research-01 archive move, `.sw/comms/tasks/p0-research-02/`, `docs/research/02-multi-harness.md`.
- **Owners / dependencies:** research-2 owns the file for this round; the Leader owns approval and the roadmap fold.
- **Decisions / remaining:** after this round: Leader approval, roadmap fold, owner commit, topic 3.
- **Validation:** research-2 runs `pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --no-index --check /dev/null docs/research/02-multi-harness.md`.
- **Not validated / risks:** none new.
- **Publication:** local-only until a human pushes
- **Next action:** research-2; apply items 1-4, write a `submission` event, and message the Leader "p0-research-02 corrected".
