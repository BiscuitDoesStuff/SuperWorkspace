# p0-roadmap-rewrite - assignment - 2026-09-27T053139Z - leader

- **Author / audience:** leader (cloud Leader session); readers: the owner, and any later Leader that resumes this task.
- **Approval:** Phase 0 step 6 is on the owner-approved Phase 0 checklist (`docs/roadmap.md`). The owner approved on 2026-09-27 that the Leader does it in-session.
- **Scope / acceptance:** Rewrite `docs/roadmap.md` from the eleven reviewed files in `docs/research/`. Phase 0 is summarized as done. The next phase is written as a **proposal**: ordered work packages, each citing topic recommendations (`NN Rk`), plus one list of runtime tests, and the standing rules and hypotheses updated. Every "decided in topic N" input from the old roadmap appears in the new one. Also add the branch-model entry to `docs/decisions.md` (topic 10 R1; no rationale existed, 10-F21). Exclusions: no `product/`, test or `.opencode/` changes; the next phase is not approved by this task.
- **Status:** in_progress
- **Branch / base:** cloud branch `main-ahb0v0`; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** 55ea92d (clean) at assignment.
- **Owners / dependencies:** the Leader owns `docs/roadmap.md`, `docs/decisions.md` and this record. Depends on topics 0-10 (all reviewed and closed).
- **Decisions / remaining:** draft, then self-review against the research files, then owner review. After the owner approves the proposal, the next phase gets its own plan and first assignment.
- **Validation:** leader runs `pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --check`, and checks the citations and coverage by hand.
- **Not validated / risks:** none yet.
- **Publication:** pushed to `main-ahb0v0` with the next milestone commit; `main` is the owner's.
- **Next action:** leader; write the draft and a `review` event, then stop for the owner.
