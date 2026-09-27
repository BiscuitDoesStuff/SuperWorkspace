# p0-leader - handoff - 2026-09-27T053036Z - leader

- **Author / audience:** leader (cloud Leader session, Claude Code on the web); readers: the owner and the next Leader (OpenCode on the owner's desktop, or Claude).
- **Approval:** the owner approved the cloud plan on 2026-09-27: align the cloud session, keep a rolling handoff for OpenCode, and have the Leader do Phase 0 step 6 in-session. The cloud push exception is recorded in `docs/development.md`.
- **Scope / acceptance:** Phase 0 Leader. Steps 1-5 are done (topic 10 landed in 5e74f5a). Remaining: step 6, rewrite `docs/roadmap.md` from the eleven reviewed research files as a *proposed* next phase, then owner review. Nothing in `product/` changes in step 6.
- **Status:** in_progress
- **Branch / base:** cloud branch `main-ahb0v0` (transport only, see `docs/development.md`); published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019 (origin/main, 2026-09-27); main-ahb0v0 fast-forwards from it.
- **Checked revision / changed:** 5e74f5a7b4615ebda34c683c2f0cd6b21aa6d0c5 plus uncommitted: `docs/development.md` (cloud rule), the p0-research-10 archive move, this event. They go into the next commit on main-ahb0v0.
- **Owners / dependencies:** the Leader owns `docs/roadmap.md`, `docs/decisions.md` and the task records; the owner owns `main` and publication. No worker is open.
- **Decisions / remaining:** Done in the cloud: topic 10 approved, folded and committed; `p0-research-10` closed; PowerShell 7.6.6 installed in the container (session-local); cloud rule added. Next: open `p0-roadmap-rewrite` (Leader assignment), rewrite the roadmap, add the branch-model entry to `docs/decisions.md` (topic 10 R1, F21), write a review event, and stop for the owner. A later handoff event supersedes this one.
- **Validation:** leader, 2026-09-27 ~05:30 UTC, cloud container (Ubuntu 24.04, pwsh 7.6.6): `pwsh -NoProfile -File .sw/sw.ps1 validate` PASS at 5e74f5a; `git diff --check` clean. GitHub CI on 5e74f5a: `ci` run 36296332057 success (Pester, ubuntu and windows, plus fresh-install validate); `sw-validate` run 36296332116 success. Pester cannot run in the container (PSGallery blocked).
- **Not validated / risks:** research-10's correction submission event may exist only on the desktop (see receive step 4). Desktop receive steps were rehearsed in a scratch clone rebuilt from the desktop state, not on the desktop itself.
- **Publication:** pushed to origin/main-ahb0v0 by the cloud Leader; `main` unchanged until the owner fast-forwards it.
- **Next action:** owner; to continue in OpenCode, run the receive steps below on the desktop, then start OpenCode in the repository and paste the prompt. Completion evidence: a new Leader event in `.sw/comms/tasks/p0-leader/` or `p0-roadmap-rewrite/`.

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
You are the SuperWorkspace Leader for Phase 0, taking over from a cloud Claude
Leader. Read, in order: docs/roadmap.md, the newest handoff event in
.sw/comms/tasks/p0-leader/, and any open task under .sw/comms/tasks/ (expect
p0-roadmap-rewrite). Reconcile each with `git status --short --branch` and
`git log --oneline -10` before trusting it.
Approved remaining work: Phase 0 step 6. Rewrite docs/roadmap.md from the
eleven reviewed files in docs/research/ as a PROPOSED next phase (work packages
that each cite topic recommendations like "07 R2"), and add the branch-model
entry to docs/decisions.md. No product/ changes; the next phase itself is not
approved. Stop for owner review when the draft and its review event are written.
Rules: git push is denied and git commit asks; the owner commits and publishes.
Windows PowerShell 5.1 has no && or ||. Validate with
`pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --check`.
Record progress with `pwsh .sw/sw.ps1 comms event` and keep the same field format.
```
