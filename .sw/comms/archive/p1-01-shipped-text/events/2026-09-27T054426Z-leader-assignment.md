# p1-01-shipped-text - assignment - 2026-09-27T054426Z - leader

- **Author / audience:** leader (cloud Leader session; the Leader implements this package itself, docs only); reader: the owner.
- **Approval:** the owner approved the Phase 1 plan and its order on 2026-09-27 (`docs/roadmap.md` Phase 1; archive `p0-roadmap-rewrite`). This is package 1.
- **Scope / acceptance:** shipped text only, in `product/`, then refresh the dogfood copy (`pwsh product/sw.ps1 update .`):
  - `product/project/base/.sw/collaboration.md`:
    - solo mode (10 R1); agent-made branches off (10 R2, 05 R5);
    - claims, `<user>-` task IDs, close after the last event is on `main`, `sw user add` on `main`, `git lfs lock` (10 R3);
    - who runs `update` (10 R4);
    - a multi-session paragraph (05 R4, 10 R5);
    - "Protect main (human, once)" (10 R6);
    - harness memory (06 R1); the Closing `-Outcome` rule (06 R3).
  - `product/project/base/.sw/workspace.md`:
    - enforced/guardrail/stated with a harness table (08 R1); sandboxes (08 R4); trusted MCP servers (08 R6);
    - the Claude worktree sentence (05 R5);
    - the "Regenerate after `sw update`" fix (07-F21); caching (04 R6).
  - `product/project/base/AGENTS.md` Git rule: "(solo projects: `main` only)" (10 R1).
  - `project-leader.md` routing default (05 R3).
  - Skills: `task-handoff` and `agent-documentation` lines (06 R4); `research` raw-text and call-count rules (topic 0 follow-up); `free-models` `#variant` with `sw tiers` (03 R2).
  - `product/CHANGELOG.md` entry under 0.3.0-dev (unreleased, so no new version number).
  - Dev-workspace only: the `docs/decisions.md` "Known gap" line gains the 08-F26 list (08 R1).

  Exclusions: no code or test changes, no new commands, no GitHub actions.
- **Status:** in_progress
- **Branch / base:** cloud branch `main-ahb0v0`; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019
- **Checked revision / changed:** 3be5aa4 plus uncommitted Phase 0 close-out (roadmap tick, `p0-roadmap-rewrite` and `p0-leader` archived) at assignment.
- **Owners / dependencies:** the Leader owns the listed files for this package; no other writer. Depends on nothing.
- **Decisions / remaining:** the Claude rows of the harness table describe today's generator. Package 3 updates them when it closes the `.env` and `Agent` gaps.
- **Validation:** leader; `pwsh -NoProfile -File .sw/sw.ps1 validate` (startup budget stays under the cap), a fresh `init` plus `validate` in a temp folder, `git diff --check`; Pester through GitHub CI on the pushed tip (PSGallery is blocked in the container).
- **Not validated / risks:** runtime behaviour is unchanged (text only).
- **Publication:** pushed to `main-ahb0v0`; `main` is the owner's.
- **Next action:** leader; make the edits, validate, write a submission event, then stop for owner review.
