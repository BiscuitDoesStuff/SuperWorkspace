# p0-research-10 - approval - 2026-09-27T051500Z - leader

- **Author / audience:** leader; readers: owner, research-10.
- **Approval:** the Leader approves the corrected file against the owner-approved assignment; owner answers recorded 2026-09-27 (correction 2026-09-27T050623Z). Commit and publication remain with the owner.
- **Scope / acceptance:** accepted. Correction items 1-4 verified in `docs/research/10-collaboration-branches.md`: status line; F16 update (repository public, protection on Free) with the original probe kept; the section 1 "not covered" line records the owner's check (`main` not protected); section 5 records Q1-Q5.
- **Status:** complete
- **Branch / base:** main; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019. The session moved to a cloud checkout on branch `main-ahb0v0` (HEAD 4687178, a desktop WIP snapshot on top of fe10015).
- **Checked revision / changed:** fe10015 plus the WIP snapshot: the p0-research-09 archive move, `.sw/comms/tasks/p0-research-10/`, `docs/research/10-collaboration-branches.md`; plus `docs/roadmap.md` (topic 10 fold).
- **Owners / dependencies:** file ownership returns to the Leader.
- **Decisions / remaining:** findings folded into `docs/roadmap.md`: a topic 10 input, the session-tier line, the hypothesis answered "not yet", and Phase 0 step 5 ticked. The Leader also removed a duplicated 08/09 entry from the roadmap's work-package list. R6 still says "This repository is private"; section 5 and the F16 update supersede that line, so it was left as dated text. Close this task after the owner commits it. Next: Phase 0 step 6, the roadmap rewrite.
- **Validation:** leader, 2026-09-27 ~05:15 UTC, cloud container: `git diff --check` clean. Not run: `pwsh -NoProfile -File .sw/sw.ps1 validate` (no `pwsh` in this container).
- **Not validated / risks:** research-10's correction `submission` event is missing from this checkout. The file edits arrived with the desktop snapshot, but the event did not. If it exists on the desktop, it is not in this record set. Run validate on a machine with `pwsh` before or after committing.
- **Publication:** local-only until a human pushes
- **Next action:** owner; commit topic 10. The Leader then plans Phase 0 step 6.
