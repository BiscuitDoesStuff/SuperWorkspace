# p1-leader - handoff - 2026-09-27T054603Z - leader

- **Author / audience:** leader (cloud Leader session, Claude Code on the web); readers: the owner and the next Leader (OpenCode on the owner's desktop, or Claude).
- **Approval:** the owner approved the Phase 1 plan and order on 2026-09-27 (`docs/roadmap.md`). Rule: one package at a time, owner review after each.
- **Scope / acceptance:** Phase 1 Leader: run packages 1-10 of `docs/roadmap.md` in order.
- **Status:** in_progress (package 1 submitted, waiting on owner review)
- **Branch / base:** cloud branch `main-ahb0v0` (transport only, `docs/development.md`); published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019 (origin/main, 2026-09-27).
- **Checked revision / changed:** 845131b plus the package 1 changes (see `p1-01-shipped-text` submission). All of it is in the commit that follows this event.
- **Owners / dependencies:** the Leader owns the Phase 1 records and implements docs packages in-session; the owner reviews, owns `main` and publishes.
- **Decisions / remaining:**
  - Package 1 (`p1-01-shipped-text`): submitted.
  - Next: package 2 (known defects). Package 3 (Claude adapter) is the first code package: Pester tests need CI or a local Pester.
  - Phase 0 records are archived (`archive/p0-leader/`, which also holds the desktop receive steps).
- **Validation:** see the package 1 submission. `validate` PASS; fresh init PASS; `git diff --check` clean.
- **Not validated / risks:** Pester is not installable in the cloud container; CI is the evidence.
- **Publication:** pushed to origin/main-ahb0v0 by the cloud Leader.
- **Next action:** owner; review package 1. To continue in OpenCode instead: first do the desktop receive steps in `.sw/comms/archive/p0-leader/events/2026-09-27T053324Z-leader-handoff.md`, then paste the prompt below.

## OpenCode prompt (paste into a new session; default agent `project-leader`)

```text
/resume p1-leader
You are the SuperWorkspace Leader for Phase 1, taking over from a cloud Claude
Leader. Read, in order: docs/roadmap.md (Phase 1), the newest event in
.sw/comms/tasks/p1-leader/, and every open task under .sw/comms/tasks/.
Reconcile them with `git status --short --branch` and `git log --oneline -10`
before trusting them.
Phase 1 is approved: run the packages in order, one at a time, and stop for my
review after each. First ask me to approve or correct the open package (see its
submission event). After approval: write an approval event, close the task
(`pwsh .sw/sw.ps1 comms close`), then assign and do the next package. Re-read the
cited research recommendation text before each package. For code packages
dispatch project-developer and run project-review. Run
`Invoke-Pester tests -Output Detailed` locally.
Rules: git push is denied and git commit asks; I commit and publish. Windows
PowerShell 5.1 has no && or ||. Checks: the ones in AGENTS.md "Checks before
handing work back". Refresh the dogfood copy with `pwsh product/sw.ps1 update .`.
```
