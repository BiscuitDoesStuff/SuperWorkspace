# p1-04-validate-doctor-comms - assignment - 2026-09-27T062717Z - leader

- **Author / audience:** leader (cloud Leader session); reader: the cloud worker session the Leader starts (role: project-developer), then the owner.
- **Approval:** the owner approved the Phase 1 plan and order, and on 2026-09-27 approved package 3 with "continue to package 4". Cloud worker flow: `docs/development.md`. This is package 4.
- **Scope / acceptance:** Phase 1 package 4. Before editing:
  - re-read 09 R2, R3 and R5 plus 09-F8, F19 and F20 (`docs/research/09-validation-evaluation.md`);
  - re-read 04 R1, R2 and R5 (`docs/research/04-context-efficiency.md`), 06 R2 (`docs/research/06-upkeep-memory.md`) and 10 R6 (`docs/research/10-collaboration-branches.md`);
  - load `minimal-change`.

  All code is in `product/lib/Sw.Project.psm1`. Each new check gets a negative fixture or test in `tests/Sw.Tests.ps1`.
  1. `Test-SwProject` (`validate`), three new errors (09 R2):
     - (a) `AGENTS.md` has a `## Project identity` heading;
     - (b) every skill `name` matches the Agent Skills spec pattern and length, and `description` is at most 1024 characters (09-F8);
     - (c) when `.claude/.sw-generated` exists, the Claude structure matches `.sw/roles.json`, independently of the generator: one agent file per non-leader, non-explore role, its `model` from the tier map, its `tools` from `claudeTools` when set, and `disallowedTools: Agent`; one command per `.opencode/commands/*.md`. Put the same asserts in the Pester `Claude adapter` test.
  2. Research lint as a **warning**, not an error (09 R3). It runs only when `docs/research/*.md` exists under the project root:
     - sections 1-6 present;
     - the header has a date;
     - each finding has one of the accepted citation forms (09-F19); a subsection heading containing "local" covers its findings.

     A warning must not change the exit code. Run it on this repository's own `docs/research/` and report what it flags. Topic 00's unnumbered findings pass. Do not edit research files to silence warnings.
  3. Pester staleness test (09 R5): no shipped `SKILL.md` under `product/` has an `Observed YYYY-MM` line outside an "Old observations" section.
  4. Budget wording (04 R1, R5):
     - the `validate` budget line reads `~N tokens (bytes/4 estimate; tokenizer varies)`;
     - the `project-leader` count also adds the agents' `description:` bytes, since it is the only role that sees the subagent catalogue. Confirm it stays under the 12100 cap on a fresh init and on this repository.
  5. `Test-SwDoctor` (04 R2, 10 R6), after the existing OpenCode Desktop reminder:
     - "Startup budget (validate) counts kit files only. Harness prompt, tool schemas, user files, hooks and plugins are not counted; check `/context` (Claude) for the real total."
     - "Branch protection on main: not checked (needs `gh api`, which agents are denied); see .sw/collaboration.md (Protect main)."

     Doctor stays read-only.
  6. `Invoke-SwComms event` (06 R2): the "changed" line drops porcelain entries under `.sw/comms/`, keeps at most 10, then appends `(+N more)`. One Pester case.
  7. `product/CHANGELOG.md` lines under 0.3.0-dev; refresh the dogfood copy with `pwsh -NoProfile -File product/sw.ps1 update .`.

  Success evidence:
  - every new check fails on its negative fixture and passes on a fresh init;
  - `validate` passes on this repository, with research-lint warnings listed;
  - CI is green on the worker branch.

  Exclusions:
  - no Claude generator changes (package 3 is done);
  - no lifecycle or manifest changes (package 5);
  - no schema validation (09 R6);
  - no edits to `docs/research/`, the roadmap or decisions;
  - no new dependencies.
- **Status:** pending
- **Branch / base:** worker branch `cloud/p1-04-validate-doctor-comms`, created from `main-ahb0v0` at the commit that holds this assignment. Published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019.
- **Checked revision / changed:** 1258e9b plus uncommitted: package 3 approval and close, and this assignment. Both go into the commit the worker starts from.
- **Owners / dependencies:** the worker owns:
  - `product/lib/Sw.Project.psm1`, `tests/Sw.Tests.ps1`, `product/CHANGELOG.md`;
  - the dogfood copies that `update` rewrites (`.sw/lib/`, `.sw/manifest.json`);
  - its own events here.

  The Leader owns everything else and does not commit to `main-ahb0v0` while the worker runs.
- **Decisions / remaining:** worker steps, in order:
  1. Install PowerShell 7: `curl -sSLO https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb && dpkg -i packages-microsoft-prod.deb && apt-get update && apt-get install -y powershell`. Launchpad PPA warnings are harmless.
  2. Read this assignment and the cited research.
  3. Implement.
  4. Validate.
  5. Commit the owned paths only (`feat(kit): ...`, body naming this task), and push to `cloud/p1-04-validate-doctor-comms` only.
  6. Read the `ci` run for the pushed commit. Fix any failure within scope and push again, until it is green or you are blocked.
  7. Write the `submission` event (`pwsh -NoProfile -File .sw/sw.ps1 comms event -Task p1-04-validate-doctor-comms -Event submission -From worker-p1-04 -Status complete`, every field filled, including the CI run ID and result), then commit and push it.

  On a scope question, or a failure you cannot fix within scope, write a `progress` event with status `blocked` and push it.
- **Validation:** the worker runs:
  - `pwsh -NoProfile -File .sw/sw.ps1 validate`;
  - a fresh `pwsh -NoProfile -File product/sw.ps1 init <scratch>/sw-check -Profile unreal -Name Check`, its `validate`, `claude enable`, then `validate` again;
  - `git diff --check`.

  Pester cannot be installed in the cloud. Lesson from package 3: run each new test's steps by hand **with the modules imported from `product/lib`** (`Import-Module ./product/lib/Sw.Project.psm1`, `./product/lib/Sw.Kit.psm1`, as `tests/Sw.Tests.ps1` does; they are checked out with CRLF), not only through an installed project's `.sw/sw.ps1`. The CI `ci` run on the pushed branch is the Pester evidence. Do not claim a result you did not observe.
- **Not validated / risks:** the new checks may flag existing installed projects. Only the research lint is lenient (a warning); the three `validate` errors apply to every project that runs `update`. Say in the CHANGELOG what a project must fix.
- **Publication:** the worker pushes `cloud/p1-04-validate-doctor-comms`; the Leader fast-forwards `main-ahb0v0` after review; `main` stays the owner's.
- **Next action:** worker; complete the steps above. Completion evidence: a filled submission event, with a green CI run, on the pushed worker branch.
