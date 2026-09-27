# p1-03-claude-adapter - submission - 2026-09-27T061533Z - worker-p1-03

- **Author / audience:** worker-p1-03 (cloud worker session, role: project-developer); reader: the cloud Leader, then the owner.
- **Approval:** the owner approved Phase 1 package 3 per the assignment `2026-09-27T061248Z-leader-assignment.md`; this is the worker's report against it, not a new approval.
- **Scope / acceptance:** Phase 1 package 3 (05 R1, 05 R7, 08 R2, 08 R8, 09 R4). Done:
  1. `Get-SwClaudeFiles` (`product/lib/Sw.Project.psm1`): every generated `.claude/agents/<role>.md` has `disallowedTools: Agent` in its frontmatter; `settings.json` `ask` gains `Read(**/.env)` and `Read(**/.env.*)`; `deny` gains `Bash(gh alias:*)`. No other `gh` verbs were added.
  2. `product/project/opencode.base.json`: `external_directory * allow` became `ask`. The validator's permission matrix has no `Expect` on `external_directory` (its `$base` list already models OpenCode's default `ask`), so no expectation changed.
  3. Subagent flag: the hard-coded `$child` list and its `subagent` `Require` are gone from the `$script:Routes` loop; the routing `Require` and `$script:Routes` stay. The leader pointer's dispatch sentence is built in the existing command loop from commands with `subagent: true`, grouped by agent. Default output: "`/research` dispatches `project-research`; `/review` and `/status` dispatch `project-review`."
  4. Pester (`tests/Sw.Tests.ps1`, `Describe 'Claude adapter'`): the enable test now asserts `disallowedTools: Agent` in `project-worker.md`, the two `.env` asks and the `gh alias` deny; a new test flips `subagent:` in `.opencode/commands/review.md` and asserts the dispatch sentence changes (`/review` gone, "`/status` dispatches `project-review`") and that `validate` still passes. No existing test asserted the removed check, so none changed.
  5. `product/project/base/.sw/workspace.md` harness table: `.env` row Claude column "enforced (ask)"; new row "Non-leader roles: no subagent launch" (OpenCode enforced; Claude enforced (`disallowedTools: Agent`)). The denylist sentence after `githubTier` is unchanged.
  6. `product/CHANGELOG.md`: three lines under 0.3.0-dev (Claude output, the `external_directory` behaviour change, the validator change). `product/VERSION` is already 0.3.0-dev; not bumped.
  7. `pwsh -NoProfile -File product/sw.ps1 update .`: "42 unchanged, 3 changed" (`.sw/workspace.md`, `.sw/lib/Sw.Project.psm1`, `opencode.jsonc`; `.sw/manifest.json` updated).

  Exclusions kept: no other `validate`, `doctor` or `comms` changes, no lifecycle changes, no `roles.json` field, no hooks, no `.claude/` templates.
- **Status:** complete
- **Branch / base:** cloud/p1-03-claude-adapter from `main-ahb0v0` at 082a6805a593baaf5defaeb9cf5e1d528a40063d; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019 (per the assignment; not re-observed).
- **Checked revision / changed:** 082a6805a593baaf5defaeb9cf5e1d528a40063d plus: `product/lib/Sw.Project.psm1`, `product/project/opencode.base.json`, `tests/Sw.Tests.ps1`, `product/project/base/.sw/workspace.md`, `product/CHANGELOG.md`, dogfood copies `.sw/lib/Sw.Project.psm1`, `.sw/workspace.md`, `.sw/manifest.json`, `opencode.jsonc`, and this event. All in one commit on the worker branch.
- **Owners / dependencies:** worker owns the paths above; the Leader owns everything else. No dependencies.
- **Decisions / remaining:**
  - `gh alias` was added to the `$always` list in `Get-SwClaudeGhDeny`, not inline in `Get-SwClaudeFiles`: AGENTS.md says GitHub rules live only in `Get-SwGhRules` and `Get-SwClaudeGhDeny`. The generated `settings.json` is the same either way (`Bash(gh alias:*)` in `deny`, at every tier).
  - The dispatch sentence uses "dispatches" for one command and "dispatch" for several; with no subagent commands it reads "No command dispatches a subagent."
  - Claude cannot re-allow `.env.example` under an ask, so it prompts too (08 R2; noted in the CHANGELOG).
  - Remaining: Leader review (`project-review` over the diff), CI Pester result on the pushed branch, fast-forward of `main-ahb0v0`.
- **Validation:** runner: cloud worker container (Linux, PowerShell 7.6.6), 2026-09-27 UTC.
  - `pwsh -NoProfile -File .sw/sw.ps1 validate` (dogfood, after `update .`): PASS (contracts=1817; permission cases=380; hygiene files=34).
  - `pwsh -NoProfile -File product/sw.ps1 init <scratchpad>/sw-check -Profile unreal -Name Check`: 47 files; its `validate`: PASS (contracts=1851; permission cases=400; hygiene files=35), budgets under the 12100 cap. Then `sw claude enable`: 29 files; inspected `.claude/agents/project-worker.md` and `project-review.md` (both carry `disallowedTools: Agent`), `.claude/settings.json` (`ask`: `Bash(git commit:*)`, `Read(**/.env)`, `Read(**/.env.*)`; `deny` includes `Bash(gh alias:*)`), `.claude/project-leader.md` (dispatch sentence as in item 3). `validate` after enable: PASS (contracts=1880, drift check included). Generated `opencode.jsonc` has `external_directory` `ask`.
  - The new Pester test's steps, run by hand in pwsh without Pester on a generic tier-0 init: all four matches true, `Test-SwProject` exit 0 after the flip.
  - `git diff --check`: clean.
- **Not validated / risks:** Pester not run (not installable in the cloud; PSGallery blocked); GitHub CI on the pushed branch is the Pester evidence. Runtime behaviour in Claude and OpenCode (whether `disallowedTools: Agent`, the `.env` asks and the outside-folder prompt actually fire) is not tested here; that is the desktop checkpoint.
- **Publication:** pushed to `origin/cloud/p1-03-claude-adapter` by the worker per the cloud worker rule; no PR, no other GitHub writes.
- **Next action:** Leader; review the diff on `cloud/p1-03-claude-adapter`, read its CI Pester result, then fast-forward `main-ahb0v0`. Completion evidence: CI green on the worker commit and `main-ahb0v0` at that commit.
