# p1-04-validate-doctor-comms - submission - 2026-09-27T064338Z - worker-p1-04

- **Author / audience:** worker-p1-04
- **Approval:** the owner approved Phase 1 and on 2026-09-27 said "continue to package 4"; the assignment `2026-09-27T062717Z-leader-assignment.md` is the brief. This submission is not yet reviewed.
- **Scope / acceptance:** Phase 1 package 4, steps 1-7 as assigned. All code is in `product/lib/Sw.Project.psm1`; tests are in `tests/Sw.Tests.ps1`.
  1. `validate` has three new errors:
     - (a) `AGENTS.md` lacks a `## Project identity` heading;
     - (b) a skill `name` fails `^[a-z0-9]+(-[a-z0-9]+)*$` or is over 64 characters, or a `description` is over 1024 characters;
     - (c) when `.claude/.sw-generated` exists: a missing `.claude/agents/<role>.md` for a non-leader, non-explore role; a wrong `model` for the tier; `tools` not equal to `claudeTools` (or a `tools` line when `claudeTools` is empty); no `disallowedTools: Agent`; a missing `.claude/commands/<name>.md` for an `.opencode/commands/*.md`.
  2. Research lint (`Get-SwResearchWarnings`, private) checks sections 1-6, a `YYYY-MM-DD` date in the header, and a citation per `F<n>.` block under `## 2.`. Accepted citations: a URL; `Same ... as F<n>`, which may span lines; `Local`; `(F<n>`; or `NN-F<n>`. A `###` heading containing "local" covers its findings. Output is `WARNING:` lines before the ERROR/PASS lines; the exit code is unchanged.
  3. Pester `Shipped skill staleness` test.
  4. Budget line: `Startup budget: <role> = N bytes, ~M tokens (bytes/4 estimate; tokenizer varies); cap C`. `project-leader` also adds the description bytes of every other `.opencode/agents/*.md`.
  5. Doctor prints the two notes after the OpenCode Desktop reminder.
  6. The comms event "changed" line drops porcelain entries under `.sw/comms/`, keeps 10, then adds `(+N more)`.
  7. CHANGELOG lines under 0.3.0-dev say what a project must fix. `VERSION` stays `0.3.0-dev`. The dogfood copy was refreshed with `update .`.

  Exclusions respected: no generator behaviour change, no lifecycle or manifest-format change, no schema validation, no edits to `docs/research/`, roadmap or decisions, no new dependencies.
- **Status:** complete
- **Branch / base:** cloud/p1-04-validate-doctor-comms, from `main-ahb0v0` at 0a2be43471b5abb156a278990e6a94d21a88ff08; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019 (from the assignment; not re-observed).
- **Checked revision / changed:** f098f62c05c297a9ea1ec2ed6912fc1c1b8fef5c (clean). Commits: bb70991 `feat(kit): add validate, doctor and comms checks from Phase 1 package 4`, and f098f62 `fix(kit): restore a dropped space in the mojibake pattern line` (undoes whitespace churn in bb70991). Paths: `product/lib/Sw.Project.psm1`, `tests/Sw.Tests.ps1`, `product/CHANGELOG.md`, `.sw/lib/Sw.Project.psm1`, `.sw/manifest.json`, plus this event.
- **Owners / dependencies:** the worker owned only the paths above. Nothing blocks this work.
- **Decisions / remaining:**
  - The tier-to-model map moved to `$script:ClaudeModels`. The generator and the new check share this one constant; everything else in check (c) reads `.sw/roles.json` and the files on disk, not generator output.
  - Check (c) also flags a `tools:` line when `claudeTools` is empty, which is how the generator behaves.
  - The research lint reads every `docs/research/*.md`, including the non-topic `03-free-models-observed.md`.
  - Research-lint warnings on this repository (validate still passes):
    - `03-free-models-observed.md`: sections 1-6 missing (it is dated evidence, not a topic file);
    - `03-model-advisor.md`: F15 has no citation. It cites "Sources F9, F14." and "in F9)", which none of the accepted forms match.

    07-F17 to F22 pass through their "local" subsection heading. 08-F4 passes because `Same ... as` may span lines. Topic 00 passes vacuously. No research file was edited.
  - Leader budget (cap 12100): this repository 9614 bytes (~2404 tokens), fresh unreal init 8164 bytes locally (8168 on CI ubuntu).
  - Proposed follow-ups for the Leader, not done here because the paths are not owned:
    - `product/project/base/.sw/workspace.md` line 143 still describes the budget as AGENTS.md + role body + skills, without the leader's catalogue;
    - 04 R2 put the doctor budget note under "Startup budget per role", which is in `Get-SwUsage` (`usage`), not doctor; the assignment's placement in `Test-SwDoctor` was followed;
    - consider accepting "Sources F<n>" as a cross-reference form, or leave 03-F15 as a warning.
- **Validation:** cloud worker container, Ubuntu, PowerShell 7.6.6, 2026-09-27 ~06:30-06:45Z.
  - `pwsh -NoProfile -File .sw/sw.ps1 validate`: PASS, exit 0, 2 research WARNING lines (above).
  - Fresh `pwsh -NoProfile -File product/sw.ps1 init <scratch>/sw-check -Profile unreal -Name Check`, then its `validate`: PASS, exit 0. Then `claude enable` (29 files) and `validate` again: PASS, exit 0.
  - Its `doctor` printed both new notes. Its exit code was 1 only because OpenCode is MISSING in the container.
  - `git diff --check`: clean.
  - Pester is not installable here. The whole `tests/Sw.Tests.ps1` ran through a hand-written Pester-compatible shim (scratchpad, not committed), with modules imported from `product/lib` by the file's own BeforeAll: 75 passed, 0 failed.
  - The same shim against the HEAD~ (0a2be43) `Sw.Project.psm1`, with an `Observed 2026-09` line planted in a copied `free-models/SKILL.md`, gave 13 failures. They are exactly the new or changed tests: 3 validate fixtures, 5 Claude structure fixtures, research lint warnings, budget output, comms cap, doctor notes and staleness. So each new check fails on its negative fixture and passes on a fresh init.
  - GitHub Actions `ci` run 36300844313 on bb70991: success. Windows and ubuntu jobs green; ubuntu Pester reported "Tests Passed: 75, Failed: 0".
  - `ci` run 36300869831 on f098f62: success, both jobs green.
  - `sw-validate` runs 36300844288 (bb70991) and 36300869842 (f098f62): success.
- **Not validated / risks:**
  - Real Pester was not run locally; CI is the Pester evidence.
  - The Windows Pester count was not read from the log; only the job and step conclusions were.
  - `claude enable` + `validate` was not run on this repository, which has no `.claude/` in the container.
  - Installed projects that run `update` can newly fail `validate` in three cases (see CHANGELOG): an adopted `AGENTS.md` without `## Project identity`, a user skill with a non-spec name or a long description, or a stale `.claude/`.
  - CI for the commit carrying this event is not observed in this event.
- **Publication:** pushed to `origin/cloud/p1-04-validate-doctor-comms` by the cloud worker (session rule). No PR and no other GitHub writes.
- **Next action:** Leader: rerun the checks, then review (with `project-review`) and write `review` then `approval` or `correction`. On approval, fast-forward `main-ahb0v0` to this branch tip.
