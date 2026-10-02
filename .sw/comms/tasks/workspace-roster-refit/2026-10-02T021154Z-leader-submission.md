# workspace-roster-refit - submission - small roster implemented - 2026-10-02T021154Z - leader

- **Author / audience:** Project Leader (Claude Opus 5.5, Claude Code desktop); owner and future sessions.
- **Approval:** per the [assignment](2026-10-02T020107Z-leader-assignment.md).
- **Status:** implemented and validated; uncommitted on top of the baseline commit `05df1c0` (owner-approved; staged by path, secret-screened).
- **Executor:** `project-developer`, dispatched from the AI-Research session; its configured model is unverified.
- **Changed:**
  - Kit sources: `project/roles.json`; `project/base/.opencode/agents/` (removed `project-plan`, `project-architect`, `project-build`, `project-documentation` and `project-worker`; developer and leader updated); `project/base/.opencode/commands/validate.md`; `project/base/.sw/workspace.md`; `lib/Sw.Project.psm1`.
  - Generated through `pwsh -NoProfile -File sw.ps1 update .` (dry run first; no hand edits): `.opencode/agents/*`, `.opencode/commands/validate.md`, `.sw/workspace.md`, `.sw/roles.json`, `.sw/lib/Sw.Project.psm1`, `opencode.jsonc`, `.sw/manifest.json`.
  - `CHANGELOG.md` entry. The register (O7, O8, the S2 roster row and Open) and the state Startup are updated by the Leader.
  - O9 is unchanged and still accurate: the lanes and the rubric don't name the removed roles.
- **Review:** an advisory read-only `project-review` found 1 must-fix item and 5 should-fix items. All are applied:
  - **Must-fix:** removing `project-worker` had dropped its enforced Git denies. They are restored as `ask` rules on `project-developer` (switch, checkout, merge, rebase, cherry-pick, branch, worktree) with a contract `Expect` case in `lib/Sw.Project.psm1`. They are `ask` rather than `deny` so that the solo executor's normal use still works with human approval.
  - **Should-fix:**
    - S2 row implementation status
    - state wording (the research profile role is still pending)
    - "the planner" changed to "the Leader" or "the plan's tier" in `workspace.md`
    - the leader's duplicate "parallel"
    - this O9 note

  The fixes were not re-reviewed.
- **Validation:**
  - `pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks`: PASS (contracts=4568, permission cases=314, local links=0).
  - `pwsh -NoProfile -File sw.ps1 update . -WhatIf`: 40 unchanged, 0 changed (no drift).
  - `git diff --check` against `05df1c0`: exit 0 (CRLF warnings only, from `core.autocrlf`).
  - A grep found no removed role names outside `CHANGELOG.md` history, `.sw/comms/` and `docs/`.
- **Not validated / risks:**
  - No runtime check that OpenCode loads the new agents or applies the `ask` rules (U3).
  - `project-research` is not yet a profile role; that waits for the generator refit.
  - No `.claude/` adapter exists, so the Claude pointers were not checked at runtime.
- **Publication:** local-only, uncommitted. A commit needs an owner request.
- **Next action:** owner chooses whether to commit. The generator refit follows the reviewed corpus Pass 9 report.
