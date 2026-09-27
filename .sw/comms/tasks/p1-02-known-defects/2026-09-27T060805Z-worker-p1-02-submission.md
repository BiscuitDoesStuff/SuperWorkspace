# p1-02-known-defects - submission - 2026-09-27T060805Z - worker-p1-02

- **Author / audience:** worker-p1-02 (cloud worker session, role: project-documentation); reader: the cloud Leader, then the owner.
- **Approval:** the owner approved Phase 1 package 2 per the assignment `2026-09-27T060549Z-leader-assignment.md`; this is the worker's report against it, not a new approval.
- **Scope / acceptance:** the `free-models` defect only (03 R3, 06 R5 option A). Done:
  1. `product/project/base/.opencode/skills/free-models/SKILL.md` now holds procedure and hard constraints only: find and verify (`opencode models --verbose`, strict-$0 / `:free` / Zen `*-free` check, data-use terms and consent, observed levels only, exact IDs), hard constraints (generalized: no rejected levels, no overriding locked sampling, server-locked effort, flakiness = retry once then route around), the `sw tiers` mapping with behavior-based tier fit, and `#variant`/keybind/badge notes. No model IDs, prices, endpoints or effort levels per model. The Artificial Analysis benchmark paragraph was also moved out.
  2. New `docs/research/03-free-models-observed.md` (not shipped): header naming the source skill and move date 2026-09-27; Corrections section with GLM 5.2 not free (03-F13), Muse Spark 1.3 Contributor Free contradictory and trains on prompts (03-F12), Nemotron "trial use only" (03-F12); then every removed observation with its date (options per model, sampling values, Inkling training/harness note, 2026-09-25 flakiness, Qwen agentic note, the old tier-fit list, OpenAI GPT upgrade line, benchmark note).
  3. `product/project/base/.sw/workspace.md` Model tiers: "See the `free-models` skill for dated tier fits" replaced by a pointer to the skill's procedure, stating the kit ships no model IDs or tier fits.
  4. `product/CHANGELOG.md`: the assigned line under 0.3.0-dev. `product/VERSION` is already 0.3.0-dev; not bumped.
  5. `pwsh -NoProfile -File product/sw.ps1 update .`: "43 unchanged, 2 changed" (`.opencode/skills/free-models/SKILL.md`, `.sw/workspace.md`; `.sw/manifest.json` updated).

  Exclusions kept: no `$schema` (03-F20) work, no other skills, code, tests, roadmap or decisions edits, no research fetches.
- **Status:** complete
- **Branch / base:** cloud/p1-02-known-defects from `main-ahb0v0` at d0da64db99d6e6dbcc2ce893bdcbf2d052f5c247; published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019 (per the assignment; not re-observed).
- **Checked revision / changed:** d0da64db99d6e6dbcc2ce893bdcbf2d052f5c247 plus: `product/project/base/.opencode/skills/free-models/SKILL.md`, `product/project/base/.sw/workspace.md`, `product/CHANGELOG.md`, `docs/research/03-free-models-observed.md` (new), dogfood copies `.opencode/skills/free-models/SKILL.md`, `.sw/workspace.md`, `.sw/manifest.json`, and this event. All in one commit on the worker branch.
- **Owners / dependencies:** worker owns the paths above; the Leader owns everything else. No dependencies.
- **Decisions / remaining:**
  - Hard constraints that named a model were generalized, not dropped: MiMo's locked sampling became "never override sampling values a model locks"; Inkling's training/consent rule became the data-use step in "Find and verify"; the GLM/Qwen flakiness observation became a general flakiness rule. The specifics moved to the research file.
  - "Find and verify" step 2 uses the strict-$0 filter already sourced in 03 R1 / F22 / F9 / F12; no new facts.
  - The CLI keybind note (`variant.cycle`, `ctrl+t`, fetched 2026-09-25) stays in the skill: it is client behavior, not a model ID, price, endpoint or effort level. The Leader may move it if 06 R5 is read more widely.
  - Remaining: Leader review, CI Pester result on the pushed branch, fast-forward of `main-ahb0v0`.
- **Validation:** runner: cloud worker container (Linux, PowerShell 7.6.6), 2026-09-27 UTC.
  - `grep -inE 'glm|mimo|nemotron|qwen|inkling|muse|ling 3|opencode/[a-z0-9]' product/project/base/.opencode/skills/free-models/SKILL.md`: one hit only, line 48 `.opencode/opencode.jsonc` (a path, not a model ID). No model names or IDs.
  - `pwsh -NoProfile -File .sw/sw.ps1 validate`: PASS (contracts=1826; permission cases=380; hygiene files=34).
  - `pwsh -NoProfile -File product/sw.ps1 init <scratchpad>/sw-check -Profile unreal -Name Check` then `pwsh -NoProfile -File <scratchpad>/sw-check/.sw/sw.ps1 validate`: init wrote 47 files; validate PASS (contracts=1860; permission cases=400; hygiene files=35); startup budgets 5322-5816 bytes, cap 12100.
  - `git diff --check`: clean (exit 0).
  - `grep` of `tests/` and `product/lib` for the removed headings/text: only `Sw.Project.psm1:179` lists the skill name; no test asserts removed text.
- **Not validated / risks:** Pester not run (not installable in the cloud; PSGallery blocked). GitHub CI on the pushed branch is the Pester evidence; the Leader reads it. No manual OpenCode session run.
- **Publication:** pushed to `origin/cloud/p1-02-known-defects` by the worker per the cloud worker rule; no PR, no other GitHub writes.
- **Next action:** Leader; review the diff on `cloud/p1-02-known-defects`, read its CI Pester result, then fast-forward `main-ahb0v0`. Completion evidence: CI green on the worker commit and `main-ahb0v0` at that commit.
