# p1-02-known-defects - assignment - 2026-09-27T060549Z - leader

- **Author / audience:** leader (cloud Leader session); reader: the cloud worker session the Leader starts (role: project-documentation), then the owner.
- **Approval:** the owner approved the Phase 1 plan and order on 2026-09-27 (`docs/roadmap.md` Phase 1) and approved package 1 the same day. On 2026-09-27 the owner also chose Leader-spawned cloud workers that install PowerShell themselves (`docs/development.md`). This is package 2.
- **Scope / acceptance:** Phase 1 package 2, the `free-models` defect only (03 R3, 06 R5 option A). Re-read both recommendations and 03-F12 and 03-F13 in `docs/research/` first.
  1. `product/project/base/.opencode/skills/free-models/SKILL.md` keeps the procedure and hard constraints only: how to find and verify models, the `sw tiers` mapping, `#variant`, and flakiness handling. Remove model IDs, prices, endpoints and effort levels.
  2. Move the removed per-model observations, with their dates, to a new dev-workspace file, `docs/research/03-free-models-observed.md`:
     - a header naming the source skill and the date moved;
     - GLM 5.2 marked **not free** (03-F13);
     - Muse Spark 1.3 Contributor Free marked contradictory, and it trains on prompts (03-F12);
     - the Nemotron "trial use only" terms (03-F12).

     The file is dated evidence, not a research topic, so it needs no six sections. It is not shipped.
  3. `product/project/base/.sw/workspace.md` "Model tiers": replace "See the `free-models` skill for dated tier fits" with a pointer to the skill's procedure; the shipped kit no longer holds dated tier fits.
  4. `product/CHANGELOG.md`: one line under 0.3.0-dev ("Fixed: `free-models` no longer lists models or prices; GLM 5.2 was listed as free and is not.").
  5. Refresh the dogfood copy: `pwsh -NoProfile -File product/sw.ps1 update .`.

  Success evidence: the skill has no model IDs (the worker greps for `glm`, `mimo`, `nemotron`, `qwen`, `inkling`, `muse`, and `opencode/` IDs); the new file holds every removed observation; the checks below pass.

  Exclusions:
  - the `$schema` defect (03-F20) waits on runtime test 3 and is not part of this task;
  - no other skills, no code, no tests, no roadmap or decisions edits;
  - no new research calls. This is a move plus the three corrections already sourced in topic 3.
- **Status:** pending
- **Branch / base:** worker branch `cloud/p1-02-known-defects`, created from `main-ahb0v0` at the commit that holds this assignment. Published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019.
- **Checked revision / changed:** 62e52b1 plus uncommitted: `docs/development.md` (cloud worker rule) and this assignment. Both go into the commit the worker starts from.
- **Owners / dependencies:** the worker owns the five paths above, the dogfood copies that `update` rewrites, and its own events here. The Leader owns everything else and does not commit to `main-ahb0v0` while the worker runs. No dependencies.
- **Decisions / remaining:** worker setup, in order:
  1. Install PowerShell 7: `curl -sSLO https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb && dpkg -i packages-microsoft-prod.deb && apt-get update && apt-get install -y powershell`. Launchpad PPA warnings from `apt-get update` are harmless.
  2. Read this assignment and the cited research text.
  3. Do the work.
  4. Validate.
  5. Write the `submission` event: `pwsh -NoProfile -File .sw/sw.ps1 comms event -Task p1-02-known-defects -Event submission -From worker-p1-02 -Status complete`, then fill every field.
  6. Commit the owned paths only (`fix(kit): ...`, body naming this task).
  7. Push to `cloud/p1-02-known-defects` only.

  Stop and write a `progress` event with status `blocked` on any scope question.
- **Validation:** the worker runs:
  - `pwsh -NoProfile -File .sw/sw.ps1 validate`;
  - a fresh `pwsh -NoProfile -File product/sw.ps1 init <scratch>/sw-check -Profile unreal -Name Check` and its `validate`;
  - `git diff --check`.

  Pester is not installable in the cloud (PSGallery blocked), so GitHub CI on the pushed worker branch is the Pester evidence. The Leader reads it.
- **Not validated / risks:** none yet.
- **Publication:** the worker pushes `cloud/p1-02-known-defects`; the Leader fast-forwards `main-ahb0v0` after review; `main` stays the owner's.
- **Next action:** worker; complete the steps above. Completion evidence: a filled submission event on the pushed worker branch.
