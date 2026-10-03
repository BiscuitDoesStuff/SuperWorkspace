# p1-leader - decision - 2026-09-27T092912Z - leader

- **Author / audience:** leader (cloud Leader session that took over from session_01Md93Aa7xjxkWfWqxHChXXM); readers: the owner and later Leaders.
- **Approval:** the owner approved the roadmap reconciliation and chose "correction first" (2026-09-27, in the Leader session).
- **Scope / acceptance:** realignment of `docs/roadmap.md` with the checkpoint results; no package started.
- **Status:** complete
- **Branch / base:** main-ahb0v0; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** 26704a8b5cc49d6ee47ec7d0c34ecdaf872838c0 plus `docs/roadmap.md` and this event.
- **Owners / dependencies:** the Leader owns the roadmap; the owner approves the 5a assignment before a worker starts.
- **Decisions / remaining:**
  - Roadmap: packages 1-5 and 10 marked done; runtime tests 1-3 marked done with results; package 2's `$schema` item is "no action"; package 8 uses the picker or plain `opencode models` (`--verbose` is gone); the solo ruleset is marked urgent.
  - New package **5a, permission correction**, runs before package 6. Numbered 5a so packages 6-10 and existing records keep their numbers.
  - Next: the Leader drafts the `p1-05a-permission-correction` assignment for the owner's approval.
- **Validation:** cloud container, 2026-09-27 ~09:30 UTC: `pwsh -NoProfile -File .sw/sw.ps1 validate` PASS (2 known research-lint warnings); `git diff --check` clean.
- **Not validated / risks:** the cause of the ignored OpenCode project list is still unknown; OpenCode sessions are not blocked from pushing until 5a lands or `main` is protected.
- **Publication:** pushed to origin/main-ahb0v0 by the cloud Leader.
- **Next action:** owner; approve the 5a assignment draft.
