# p1-05-lifecycle - submission - 2026-09-27T070943Z - worker-p1-05

- **Author / audience:** worker-p1-05 (cloud worker, role project-developer); reader: the Leader, then the owner.
- **Approval:** the owner approved Phase 1 and on 2026-09-27 said "continue to package 5". The brief is the assignment `2026-09-27T065338Z-leader-assignment.md`. The owner also told this session "go ahead, commit and push" after the permission classifier first blocked the commit. This submission has not been reviewed yet.
- **Scope / acceptance:** Phase 1 package 5, items 1-6 as assigned. Code changes are in `product/lib/Sw.Kit.psm1` and tests in `tests/Sw.Tests.ps1`.
  1. **kitCommit and downgrade refusal (07 R2).**
     - The manifest now has `kitCommit`. `Get-SwKitCommit` runs `git -C <kit> rev-parse HEAD` and returns `$null` outside a git clone.
     - `Compare-SwVersion` handles `X.Y.Z[-tag]`; a tagged build sorts before its release.
     - `Sync-SwProject` throws before any write when the manifest's `kitVersion` is newer than the running kit, unless `-Force` is passed.
     - `-Force` is wired through `update` and `init`. `-WhatIf` still works.
     - `Format-SwPlan` prints `kit A -> B` first, or `kit none -> B` on a fresh init.
  2. **Split `skip-modified` (07 R3).**
     - An edited file whose new rendered hash equals the manifest hash is reported `kept-local`, with no hint.
     - Otherwise it stays `skip-modified`. The new version is written to `.sw/backup/<stamp>/incoming/<path>`, and one `git diff --no-index <path> <incoming>` line is printed per file.
     - The manifest keeps the old hash in both cases.
     - Names matching `$script:SecretName` are never copied.
     - `orphan-kept` now prints its own "dropped from the kit" line.
  3. **`-Adopt` gap (07 R4).**
     - When `AGENTS.md` has no `## Project identity` heading, the template text between the title and `sw:begin core` is inserted before the core block. The plan prints "fill Project identity ...".
     - Existing text is never changed.
     - `update` gains `-Adopt`.
     - This applies with or without `-Adopt`, as 07-F20 describes the gap.
  4. **Rename map (07 R5).**
     - `$script:Moved` is an ordered table, empty, at module scope next to `Sync-SwProject`.
     - An unedited old file is removed, and the new file is added.
     - An edited old file is moved to the new path with its edit. Its manifest hash follows it, and item 2 decides between `skip-modified` and `kept-local`.
     - Pester covers both cases with a test-only entry via `InModuleScope`.
     - No uninstall command was added.
  5. **Release tags (07 R6), docs only.** The root `README.md` Quick start now covers pinning with `git -C <kit-path> checkout v<version>`, the `kitVersion`/`kitCommit` record, and the downgrade refusal. No tags were created.
  6. **Also:**
     - `product/CHANGELOG.md` has lines under 0.3.0-dev. `VERSION` stays `0.3.0-dev`.
     - The `.sw/workspace.md` "regenerate after update" line was already fixed by package 1 (line 159), so it was not touched.
     - The `product/sw.ps1` `update` help now names `-Adopt` and `-Force`.
     - The dogfood copy was refreshed with `update .`.

  Exclusions respected:
  - no three-way merge, general migrations, skills move, global overlay or Gallery;
  - no tags or GitHub writes besides the branch push;
  - no edits to `docs/research/`, the roadmap or decisions.
- **Status:** complete
- **Branch / base:** `cloud/p1-05-lifecycle`, created from `main-ahb0v0` at 3f903c97295e0fae78c56939752cbc3dbc99594c. Published main is 0ee9b5eb864b1a410e4d45da0b541f7da5c88019; that comes from the assignment and was not re-observed.
- **Checked revision / changed:** 217c42e890914f23ca62359f4169228ffa065c9e (clean). Commit 217c42e `feat(kit): add kitCommit, downgrade refusal, incoming copies, adopt sections and a rename map`. Paths changed:
  - `product/lib/Sw.Kit.psm1`, `product/sw.ps1`, `tests/Sw.Tests.ps1`;
  - `product/CHANGELOG.md`, `README.md`;
  - `.sw/manifest.json`, `.sw/sw.ps1`;
  - this event.
- **Owners / dependencies:** the worker owned only the paths above; `Sw.Project.psm1` was not changed. Nothing blocks this work.
- **Decisions / remaining:**
  - `Format-SwPlan` gets the old version from its callers through `Get-SwManifestKit`. The plan stays one row per file, so the existing "everything same" test still holds.
  - Plan rows gained a `Note` property, used for the incoming diff line, the moved-from line and the AGENTS.md hint. `Format-SwPlan`, `Get-SwKitCommit` and `Compare-SwVersion` are now exported for tests.
  - The existing test "user-modified managed file becomes skip-modified" now expects `kept-local`, because the kit does not change that file (07-F19). A new test covers the `skip-modified` + `incoming/` case.
  - An unparseable `kitVersion` in a manifest makes `update` throw "Not a kit version".
  - First real run of the new plan output (`pwsh -NoProfile -File product/sw.ps1 update .` on this repository, before the commit) printed:
    `kit 0.3.0-dev -> 0.3.0-dev` / `update .sw/sw.ps1` / `44 unchanged, 1 changed.`
    The one update is the new `sw.ps1` help text. It recorded `kitCommit` 3f903c97295e0fae78c56939752cbc3dbc99594c: the base commit, because the kit changes were still uncommitted. The next `update .` after this lands will record the new commit.
  - Proposed follow-up for the Leader, not done here: a `validate` or `doctor` note when `.sw/manifest.json`'s `kitVersion` is newer than the kit that `doctor` runs from. 10 R4 mentions `validate` reporting drift; out of scope here.
- **Validation:** cloud worker container, Ubuntu, PowerShell 7.6.6, 2026-09-27 ~06:55-07:10Z.
  - Pester is not installable here. The whole `tests/Sw.Tests.ps1` ran through a hand-written Pester-compatible shim (scratchpad, not committed), with modules imported from `product/lib` by the file's own BeforeAll, on a CRLF working copy: 88 passed, 0 failed.
  - The same shim against HEAD~ (3f903c9) `product/` failed 14 of the 21 "Sync and init lifecycle" cases: every new test plus the changed kept-local one. Caveat: the unedited-rename case fails before only because `$script:Moved` did not exist. Its remove + add behaviour already worked.
  - `pwsh -NoProfile -File .sw/sw.ps1 validate` (this repository): PASS, exit 0. One research WARNING, 03-model-advisor F15, as reported in package 4.
  - Fresh `pwsh -NoProfile -File product/sw.ps1 init <scratch>/sw-check -Profile unreal -Name Check`, then its `validate`: PASS, exit 0.
  - `update` on that project, twice: both printed `kit 0.3.0-dev -> 0.3.0-dev`, `47 unchanged, 0 changed.`, and the manifest has `kitCommit`.
  - Downgrade: with manifest `kitVersion` 0.3.0 (and later 0.4.0), `update` refused with "newer than this kit (0.3.0-dev); nothing was written" and exit 1. `-Force -WhatIf` wrote nothing. `-Force` succeeded, and the manifest went back to 0.3.0-dev.
  - Edited files:
    - one appended line in `.sw/workspace.md` gave `kept-local` and no `.sw/backup`;
    - `.sw/onboarding.md` edited, with its manifest hash changed to simulate a kit change, gave `skip-modified`, an `incoming/` copy, and one `git diff --no-index` line that ran from the project root.
  - `-Adopt`:
    - `init -Adopt` over a hand-written `AGENTS.md` ("# Hand written / Our own rules.") kept the text, inserted Project identity and Architecture invariants above the core block, printed the hint, and `validate` passed;
    - removing that section made `validate` fail with the package 4 error, and `update -Adopt` fixed it back to PASS.
  - `git diff --check`: clean.
  - GitHub Actions `ci` run 36302128939 on 217c42e: success.
    - Job `test (ubuntu-latest)` 108571603312: "Tests Passed: 88, Failed: 0", and fresh install validates PASS.
    - Job `test (windows-latest)` 108571603213: "Tests Passed: 88, Failed: 0", and fresh install validates PASS.
  - `sw-validate` run 36302128956 on 217c42e: success.
- **Not validated / risks:**
  - Real Pester was not run locally; CI is the Pester evidence.
  - `update` on a project with an enabled Claude adapter was not run here (no `.claude/` in the container).
  - The rename map has no real entry yet, so it has only been exercised through the test-only entry.
  - Projects whose manifest was written by a newer kit now fail `update` until the kit clone is updated or `-Force` is given; this is intended (owner answer 07 Q1).
  - CI for the commit carrying this event is not observed in this event.
- **Publication:** pushed to `origin/cloud/p1-05-lifecycle` by the cloud worker (session rule). No PR, no tags and no other GitHub writes.
- **Next action:** Leader: rerun the checks, then review (with `project-review`) and write `review` then `approval` or `correction`. On approval, fast-forward `main-ahb0v0` to this branch tip. Tagging a release (07 R6) stays the owner's action.
