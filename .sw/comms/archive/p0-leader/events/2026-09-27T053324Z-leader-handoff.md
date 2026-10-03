# p0-leader - handoff - 2026-09-27T053324Z - leader

- **Author / audience:** leader (cloud Leader session, Claude Code on the web); readers: the owner and the next Leader (OpenCode on the owner's desktop, or Claude). Supersedes 2026-09-27T053036Z.
- **Approval:** the owner approved the cloud plan on 2026-09-27 (align, rolling handoff, Leader does Phase 0 step 6). The Phase 1 proposal in `docs/roadmap.md` is **not approved**.
- **Scope / acceptance:** Phase 0 Leader. Steps 1-5 are done. Step 6 draft is written and self-reviewed (`p0-roadmap-rewrite`); it waits on the owner.
- **Status:** in_progress (blocked on owner review of the step 6 draft)
- **Branch / base:** cloud branch `main-ahb0v0` (transport only, `docs/development.md`); published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019 (origin/main, 2026-09-27).
- **Checked revision / changed:** 55ea92d plus uncommitted: `docs/roadmap.md`, `docs/decisions.md`, `.sw/comms/tasks/p0-roadmap-rewrite/`, this event. They go into the next commit on main-ahb0v0. The pushed tip holds everything.
- **Owners / dependencies:** the Leader owns `docs/roadmap.md`, `docs/decisions.md` and the records; the owner owns review, `main` and publication. No worker is open.
- **Decisions / remaining:**
  1. Owner reviews the draft: `docs/roadmap.md` Phase 1 and the top entry of `docs/decisions.md`. The open choices are listed in `p0-roadmap-rewrite/*-leader-review.md`.
  2. On acceptance, the Leader:
     - ticks step 6;
     - closes `p0-roadmap-rewrite` and `p0-leader` (`sw comms close`);
     - writes the Phase 1 plan as a new task record;
     - writes the first assignment (package 1, shipped text), and asks the owner to approve Phase 1 before any `product/` edit.
  3. On corrections, the Leader edits the draft and writes a new review event.
- **Validation:** leader, 2026-09-27 ~05:33 UTC, cloud container (pwsh 7.6.6): `pwsh -NoProfile -File .sw/sw.ps1 validate` PASS; `git diff --check` clean. CI on 5e74f5a green (`ci` 36296332057, `sw-validate` 36296332116); later commits are docs and records only, so check CI on the new tip.
- **Not validated / risks:** research-10's correction submission event may exist only on the desktop (receive step 4). Desktop receive was rehearsed in a scratch clone, not on the desktop.
- **Publication:** pushed to origin/main-ahb0v0 by the cloud Leader; `main` unchanged until the owner fast-forwards it.
- **Next action:** owner; review the step 6 draft. To continue in OpenCode instead of this cloud session: run the receive steps below, then paste the prompt.

## Desktop receive (owner, PowerShell, once)

The desktop still has topic 10 as uncommitted changes on `main`. That content is committed on `main-ahb0v0`. Keep a copy, then fast-forward:

1. `git fetch origin`
2. `git stash push -u -m "desktop WIP before cloud receive"` (the owner may stash; agents may not)
3. `git merge --ff-only origin/main-ahb0v0`
4. Check for desktop-only files. `tasks/p0-research-10/*` moved to `archive/p0-research-10/events/`, so only files missing from that folder matter (for example a research-10 correction submission event):
   `git ls-tree -r --name-only 'stash@{0}^3' | ForEach-Object { git cat-file -e "HEAD:$_" 2>$null; if ($LASTEXITCODE) { $_ } }`
   Restore one with `git checkout 'stash@{0}^3' -- <path>` if needed. Drop the stash (`git stash drop`) only after this check.
5. Optional, to publish: `git push origin main` (fast-forward; `main` then equals main-ahb0v0).

## OpenCode prompt (paste into a new session; default agent `project-leader`)

```text
/resume p0-leader
You are the SuperWorkspace Leader, taking over Phase 0 from a cloud Claude
Leader. Read, in order: docs/roadmap.md, the newest handoff event in
.sw/comms/tasks/p0-leader/, and the newest review event in
.sw/comms/tasks/p0-roadmap-rewrite/. Reconcile them with
`git status --short --branch` and `git log --oneline -10` before trusting them.
State: Phase 0 step 6 (the roadmap rewrite) is drafted and waits for my review.
Phase 1 in docs/roadmap.md is a proposal, not approved.
First ask me: accept the draft, or give corrections. If I accept: tick step 6,
close p0-roadmap-rewrite and p0-leader (`pwsh .sw/sw.ps1 comms close`), then
draft the Phase 1 plan as a new task record and the first assignment (package 1,
shipped text). Stop for my approval before any product/ edit. If I correct:
edit the draft and write a new review event.
Rules: git push is denied and git commit asks; I commit and publish. Windows
PowerShell 5.1 has no && or ||. Validate with
`pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --check`. Record
events with `pwsh .sw/sw.ps1 comms event` and keep the field format.
```
