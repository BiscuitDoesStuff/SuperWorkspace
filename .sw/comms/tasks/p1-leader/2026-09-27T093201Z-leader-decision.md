# p1-leader - decision - 2026-09-27T093201Z - leader

- **Author / audience:** leader (cloud Leader session); readers: the owner and later Leaders.
- **Approval:** correction passed on by the previous Leader through the owner; the owner confirmed the ruleset is set and approved this plan (2026-09-27, in the Leader session).
- **Scope / acceptance:** correct the push-control wording in `docs/roadmap.md`; no kit files change.
- **Status:** complete
- **Branch / base:** main-ahb0v0; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** e727052f1df07f0a68022a6248665cbb80bc112c plus `docs/roadmap.md` and this event.
- **Owners / dependencies:** the Leader owns the roadmap; 5a waits on the owner's approval of its assignment.
- **Decisions / remaining:**
  - The solo ruleset on `main` is set (owner, 2026-09-27). It blocks force pushes and deletion, not ordinary pushes, so it does not stop an OpenCode session from pushing; only 5a does.
  - This supersedes the risk line in `2026-09-27T092912Z-leader-decision.md` ("until 5a lands or `main` is protected").
  - 5a gains a bullet: correct the shipped claim that branch protection is the real push control (`.sw/workspace.md`, `.sw/collaboration.md` "Protect main").
- **Validation:** cloud container, 2026-09-27 ~09:33 UTC: `pwsh -NoProfile -File .sw/sw.ps1 validate` PASS (2 known research-lint warnings); `git diff --check` clean.
- **Not validated / risks:** OpenCode sessions can still push until 5a lands and is re-tested on the desktop.
- **Publication:** pushed to origin/main-ahb0v0 by the cloud Leader.
- **Next action:** owner; approve the 5a assignment draft.
