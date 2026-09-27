# p0-researcher-revision - assignment - 2026-09-26T234945Z - leader

- **Author / audience:** leader (Leader session, for the repository owner); readers: the worker session assigned by the owner.
- **Approval:** owner approved the Phase 0 checkpoint plan on 2026-09-26 in the Leader session, including this work package and the topic 0 answers below.
- **Scope / acceptance:** Revise the core researcher from `docs/research/00-research-agent-design.md` section 4 (R1-R4), with the owner's answers:
  1. `product/project/base/.opencode/skills/research/SKILL.md`: apply R1 (Budget), R2 (two Sources bullets), R3 (Output item 1) as quoted in the research file. Also change "Primary sources only" to "Primary sources first; label secondary ones (benchmarks, vendor posts) as secondary."
  2. `product/project/base/.opencode/commands/research.md`: apply R4.
  3. `product/project/base/.opencode/agents/project-leader.md`, Routing list: the project-research line becomes "project-research: cited outside research, one researcher per topic. If several (at most 3, one file each) would serve a broad topic better, propose it and wait for user approval; otherwise only when the user asks."
  4. Unchanged: role edit scope stays `*.md`; `roles.json` and the role file stay as they are; no URL/date lint (deferred in `docs/roadmap.md`).
  5. `docs/research/00-research-agent-design.md`: add a status line under the title ("Status: reviewed 2026-09-26; R1-R4 adopted") and record the answers under section 5: Q1 Leader may propose fan-out (<=3) for user approval, else only on request; Q2 lint deferred; Q3 keep `*.md`; Q4 primary first, label secondary; Q5 5/10, hard cap 20.
  6. `product/CHANGELOG.md`: one line under 0.3.0-dev for the researcher revision. No VERSION change (already 0.3.0-dev).
  7. Refresh generated copies: `pwsh -NoProfile -File product/sw.ps1 update .` then `pwsh -NoProfile -File .sw/sw.ps1 claude enable`. `update` must report only the skill, command and project-leader files as updated.
  Exclusions: no other product change, no test changes unless a check fails because of this change, no roadmap/decisions/development.md edits (Leader-owned), no commits or pushes.
- **Status:** pending
- **Branch / base:** main; published main 0ee9b5e (local work uncommitted on top: Phase 0 steps 1-4 and topic 0)
- **Checked revision / changed:** 0ee9b5e plus the uncommitted Phase 0 work (see `git status`); do not touch files outside the ownership list.
- **Owners / dependencies:** worker owns the files in items 1-3, 5, 6 and the generated copies from item 7. Leader owns `docs/roadmap.md`, `docs/decisions.md`, `docs/development.md` and this record's review/approval events. No dependencies.
- **Decisions / remaining:** Keep the skill small (startup budget); follow `docs/development.md` "How development runs". Stop and message the Leader (session "SuperWorkspace Phase 0 plan"; reply to its cross-session message by copying the `from` attribute) on any scope question, failing check you cannot fix within scope, or finding that changes the plan.
- **Validation:** worker runs, from the repo root:
  `pwsh -NoProfile -c "Invoke-Pester tests -Output Detailed"`;
  `pwsh -NoProfile -File product/sw.ps1 init $env:TEMP\sw-check -Profile unreal -Name Check` (remove an old sw-check folder first);
  `pwsh -NoProfile -File $env:TEMP\sw-check\.sw\sw.ps1 validate`;
  `pwsh -NoProfile -File .sw/sw.ps1 validate`;
  `git diff --check`. Report the startup budget lines for project-leader and project-research.
- **Not validated / risks:** none yet.
- **Publication:** local-only until a human pushes
- **Next action:** worker; execute items 1-7, then write a `submission` event (`pwsh .sw/sw.ps1 comms event -Task p0-researcher-revision -Event submission -From worker-1 -Status complete`, placeholders filled: changed paths, validation evidence, findings, proposed plan changes) and message the Leader "p0-researcher-revision submitted".
