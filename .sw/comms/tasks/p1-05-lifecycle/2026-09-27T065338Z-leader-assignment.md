# p1-05-lifecycle - assignment - 2026-09-27T065338Z - leader

- **Author / audience:** leader (cloud Leader session); reader: the cloud worker session the Leader starts (role: project-developer), then the owner.
- **Approval:** the owner approved the Phase 1 plan and order, and on 2026-09-27 approved package 4 with "continue to package 5". Cloud worker flow: `docs/development.md`. This is package 5, the last before the desktop checkpoint.
- **Scope / acceptance:** Phase 1 package 5. Before editing:
  - re-read 07 R1-R6 and 07-F13 to F22 in `docs/research/07-lifecycle.md`, and 10 R4;
  - load `minimal-change`.

  Code is in `product/lib/Sw.Kit.psm1` (`Sync-SwProject` about line 83, `Format-SwPlan` about line 159, the update and init entry points). Every behaviour change gets Pester coverage in `tests/Sw.Tests.ps1`.
  1. **kitCommit and downgrade refusal (07 R2).**
     - The manifest gains `kitCommit`: `git -C <kit> rev-parse HEAD`, or `null` outside a git clone.
     - `Sync-SwProject` stops when the manifest's `kitVersion` is newer than the running kit, unless `-Force`. Wire `-Force` through the update entry point if needed; it must keep `-WhatIf` support.
     - `Format-SwPlan` prints `kit A -> B`.
     - Compare versions correctly for `X.Y.Z` and `X.Y.Z-dev`: a `-dev` build is older than the same release.
  2. **Split `skip-modified` (07 R3).**
     - When the kit did not change the file (the new rendered hash equals the manifest hash), report `kept-local` with no merge hint.
     - When it did, write the new rendered file to `.sw/backup/<stamp>/incoming/<path>` and print one `git diff --no-index <path> <incoming>` line.
     - The manifest keeps the old hash, so the edit stays detected.
     - Backups never copy credential files (`$script:SecretName`).
  3. **`-Adopt` gap (07 R4).** When an existing `AGENTS.md` has no `## Project identity` heading, insert the template's project sections (the text between the title and `sw:begin core`) before the core block, and print "fill Project identity". Never touch existing text. This makes package 4's new `validate` error fixable by `update -Adopt` / `init -Adopt`.
  4. **Rename map (07 R5).**
     - A kit-side `moved` table (`old -> new`), empty today, in `Sync-SwProject`.
     - An unedited old file moves (remove, then add).
     - An edited old file moves with its edit and is marked `skip-modified`, so item 2 applies.
     - Pester covers both cases with a test-only map entry.
     - No uninstall command.
  5. **Release tags (07 R6), docs only.** In the root `README.md` kit-clone section, document pinning with `git checkout v<version>` in the kit clone, and that the manifest's `kitCommit` records what was used. Do not create tags; tagging is the owner's action.
  6. **Also:**
     - `product/CHANGELOG.md` lines under 0.3.0-dev: new messages, `-Force` on downgrade, the `incoming/` backups;
     - fix the `.sw/workspace.md` line about regenerating after `update` only if package 1 missed it;
     - refresh the dogfood copy with `pwsh -NoProfile -File product/sw.ps1 update .`. Note what the refresh itself prints: the first real run of the new plan output.

  Success evidence:
  - each behaviour has a test that fails before and passes after (show this by hand against `product/lib`);
  - `update .` on this repository works and records `kitCommit`;
  - CI is green on the worker branch.

  Exclusions:
  - no three-way merge (07 R3 option c);
  - no general migrations;
  - no skills move (package 6);
  - no global overlay (package 7);
  - no PowerShell Gallery;
  - no tags or other GitHub writes;
  - no edits to `docs/research/`, the roadmap or decisions.
- **Status:** pending
- **Branch / base:** worker branch `cloud/p1-05-lifecycle`, created from `main-ahb0v0` at the commit that holds this assignment. Published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019.
- **Checked revision / changed:** 75645c4 plus uncommitted: package 4 approval and close, and this assignment. Both go into the commit the worker starts from.
- **Owners / dependencies:** the worker owns:
  - `product/lib/Sw.Kit.psm1` (and `product/lib/Sw.Project.psm1` only if a shared helper must change);
  - `product/sw.ps1` if an entry point needs `-Force`;
  - `tests/Sw.Tests.ps1`, `product/CHANGELOG.md`, root `README.md`;
  - the dogfood copies that `update` rewrites (`.sw/`, `.opencode/`, `opencode.jsonc`, the `AGENTS.md` block);
  - its own events here.

  The Leader owns everything else and does not commit to `main-ahb0v0` while the worker runs.
- **Decisions / remaining:** worker steps, in order:
  1. Install PowerShell 7: `curl -sSLO https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb && dpkg -i packages-microsoft-prod.deb && apt-get update && apt-get install -y powershell`. Launchpad PPA warnings are harmless.
  2. Read this assignment and the cited research.
  3. Implement.
  4. Validate.
  5. Commit the owned paths only (`feat(kit): ...`, body naming this task), and push to `cloud/p1-05-lifecycle` only.
  6. Read the `ci` run for the pushed commit. Fix failures within scope and push again, until green or blocked.
  7. Write the `submission` event (`pwsh -NoProfile -File .sw/sw.ps1 comms event -Task p1-05-lifecycle -Event submission -From worker-p1-05 -Status complete`, every field filled, including CI run IDs and results), then commit and push it.

  On a scope question, or a failure you cannot fix within scope, write a `progress` event with status `blocked` and push it.
- **Validation:** the worker runs:
  - `pwsh -NoProfile -File .sw/sw.ps1 validate`;
  - a fresh `pwsh -NoProfile -File product/sw.ps1 init <scratch>/sw-check -Profile unreal -Name Check`, its `validate`, then `update` on it twice (the second run is a no-op);
  - a downgrade attempt (refused; allowed with `-Force`);
  - an edited-file update (`kept-local` or `incoming/` as appropriate);
  - an `-Adopt` run on a hand-written `AGENTS.md` with no Project identity;
  - `git diff --check`.

  Run each new test's steps by hand with the modules imported from `product/lib` (CRLF checkout, as `tests/Sw.Tests.ps1` does). The CI `ci` run on the pushed branch is the Pester evidence; never claim a result you did not see.
- **Not validated / risks:** `update` touches user projects. Every write keeps `-WhatIf` support and backs up first (AGENTS.md "Rules for changing the kit"), and `-Force` on a downgrade is the only new way past a refusal.
- **Publication:** the worker pushes `cloud/p1-05-lifecycle`; the Leader fast-forwards `main-ahb0v0` after review; `main` stays the owner's.
- **Next action:** worker; complete the steps above. Completion evidence: a filled submission event, with a green CI run, on the pushed worker branch.
