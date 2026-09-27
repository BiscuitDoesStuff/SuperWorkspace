# p1-03-claude-adapter - assignment - 2026-09-27T061248Z - leader

- **Author / audience:** leader (cloud Leader session); reader: the cloud worker session the Leader starts (role: project-developer), then the owner.
- **Approval:** the owner approved the Phase 1 plan and order, and on 2026-09-27 the Phase 1 overview ("assign package 3 and start its worker"). Cloud worker flow: `docs/development.md`. This is package 3, the first code package.
- **Scope / acceptance:** Phase 1 package 3. Before editing, re-read 05 R1, 05 R7, 08 R2, 08 R8 and 09 R4 in `docs/research/`; for 08 R2 read `docs/research/08-permissions-safety.md` F27 too. Load the `minimal-change` skill.
  1. `Get-SwClaudeFiles` (`product/lib/Sw.Project.psm1`, around line 428):
     - emit `disallowedTools: Agent` in every generated agent's frontmatter (05 R1, 08 R2);
     - add `ask` rules `Read(**/.env)` and `Read(**/.env.*)`;
     - add a `deny` rule `Bash(gh alias:*)` (08 R2).

     Do not enumerate more `gh` verbs.
  2. `product/project/opencode.base.json`: the `external_directory` rule changes from `allow` to `ask` (08 R8). Update the validator's permission matrix expectations only where they assert the old value.
  3. The subagent flag (05 R7):
     - delete the hard-coded `$child` list and its `subagent` check in the validator (`$script:Routes` loop, around lines 306-310). Keep the routing check and `$script:Routes` itself;
     - build the leader pointer's dispatch sentence (the `/review`, `/status` and `/research` lines in `.claude/project-leader.md`) from the commands whose `subagent` is `true`, using the command loop that already reads them.
  4. Pester (`tests/Sw.Tests.ps1`, `Describe 'Claude adapter'`):
     - assert `disallowedTools: Agent` in a generated agent;
     - assert the `.env` asks and the `gh alias` deny in `settings.json`;
     - add the 09 R4 test: flipping `subagent:` in `.opencode/commands/review.md` changes the generated leader dispatch sentence.

     Change any test that asserted the removed check.
  5. `product/project/base/.sw/workspace.md` harness table:
     - the Claude `.env` row becomes "enforced (ask)";
     - add a row "Non-leader roles: no subagent launch" with OpenCode "enforced" and Claude "enforced (`disallowedTools: Agent`)";
     - the sentence after `githubTier` already calls the Claude list a denylist, so keep it.
  6. `product/CHANGELOG.md`: lines under 0.3.0-dev for the changed Claude output, OpenCode's `external_directory` default (a behaviour change for installed projects: outside-folder access now prompts), and the validator change.
  7. Refresh the dogfood copy: `pwsh -NoProfile -File product/sw.ps1 update .`.

  Success evidence: a fresh init with `sw claude enable` generates the new frontmatter and rules (inspect the files); `validate` passes; the new Pester tests are present; CI is green on the worker branch.

  Exclusions:
  - no other `validate`, `doctor` or `comms` changes (package 4);
  - no lifecycle changes (package 5);
  - no `roles.json` field;
  - no hooks (08 R5 deferred);
  - no `.claude/` templates (the adapter is generated).
- **Status:** pending
- **Branch / base:** worker branch `cloud/p1-03-claude-adapter`, created from `main-ahb0v0` at the commit that holds this assignment. Published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019.
- **Checked revision / changed:** 3df122f plus uncommitted: package 2 approval and close, and this assignment. Both go into the commit the worker starts from.
- **Owners / dependencies:** the worker owns:
  - `product/lib/Sw.Project.psm1`, `product/project/opencode.base.json`, `tests/Sw.Tests.ps1`;
  - `product/project/base/.sw/workspace.md`, `product/CHANGELOG.md`;
  - the dogfood copies that `update` rewrites (`opencode.jsonc`, `.sw/`, `.opencode/`);
  - its own events here.

  The Leader owns everything else and does not commit to `main-ahb0v0` while the worker runs.
- **Decisions / remaining:** worker steps, in order:
  1. Install PowerShell 7: `curl -sSLO https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb && dpkg -i packages-microsoft-prod.deb && apt-get update && apt-get install -y powershell`. Launchpad PPA warnings are harmless.
  2. Read this assignment and the cited research.
  3. Implement.
  4. Validate.
  5. Write the `submission` event: `pwsh -NoProfile -File .sw/sw.ps1 comms event -Task p1-03-claude-adapter -Event submission -From worker-p1-03 -Status complete`, then fill every field, including the diff summary and any test you could not run.
  6. Commit the owned paths only (`feat(kit): ...`, body naming this task).
  7. Push to `cloud/p1-03-claude-adapter` only.

  On a scope question, or a failing check you cannot fix within scope, write a `progress` event with status `blocked` and push it.
- **Validation:** the worker runs:
  - `pwsh -NoProfile -File .sw/sw.ps1 validate`;
  - a fresh `pwsh -NoProfile -File product/sw.ps1 init <scratch>/sw-check -Profile unreal -Name Check`, its `validate`, and its `sw claude enable` (inspect `.claude/agents/*.md`, `.claude/settings.json`, `.claude/project-leader.md`);
  - `git diff --check`.

  Pester cannot run in the cloud (PSGallery blocked), so GitHub CI on the pushed worker branch is the Pester evidence. The worker must not claim Pester results it did not see. After the fast-forward, the Leader runs `project-review` over the diff before owner approval.
- **Not validated / risks:** runtime behaviour in Claude and OpenCode is not tested here. That is the desktop checkpoint (smoke checklist, runtime test 2).
- **Publication:** the worker pushes `cloud/p1-03-claude-adapter`; the Leader fast-forwards `main-ahb0v0` after review; `main` stays the owner's.
- **Next action:** worker; complete the steps above. Completion evidence: a filled submission event on the pushed worker branch.
