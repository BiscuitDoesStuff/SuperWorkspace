# p1-08-model-routing - submission - 2026-09-28T011341Z - leader

- **Author / audience:** leader
- **Approval:** owner, 2026-09-27 (see the assignment event)
- **Scope / acceptance:** as in the assignment event; all acceptance items met
- **Status:** complete
- **Branch / base:** biscuit/biscuit-worktree; published main not observed
- **Checked revision / changed:** 41bdd5ca69d5f49c60c76a6ac78e3960012002da plus uncommitted:  M .agents/skills/free-models/SKILL.md;  M .sw/lib/Sw.Project.psm1;  M .sw/manifest.json;  M .sw/onboarding.md;  M .sw/roles.json;  M .sw/sw.ps1;  M .sw/workspace.md;  M docs/decisions.md;  M docs/roadmap.md;  M product/CHANGELOG.md (+8 more)
- **Owners / dependencies:** project-developer (product/, tests/, dogfood); Leader (docs, record); no dependencies
- **Decisions / remaining:** project-developer implemented the full scope (product/, tests/, dogfood update, .claude regenerated); Leader added the decisions.md entry and roadmap 8a. Leader re-check: diff, generated agents (model opus + effort), no old tier names left. No role defaults to high, so -High maps no OpenCode role; high work runs in a session at that tier, as workspace.md states.
- **Validation:** project-developer, local Windows 2026-09-28 UTC: Invoke-Pester tests 106 passed 0 failed; fresh unreal init + validate PASS (largest role budget: leader 8164 B of 12100); dogfood validate PASS with the 2 known research warnings. Leader re-ran dogfood validate (PASS, same warnings) and git diff --check (clean).
- **Not validated / risks:** no runtime check that Claude honours effort in subagents; the current Claude session applies the regenerated agents only after /clear or a restart
- **Publication:** local-only until a human pushes
- **Next action:** owner: review the diff, then ask for a commit; re-run sw tiers -Light/-Standard/-High locally
