# p1-08-model-routing - progress - 2026-09-28T031351Z - leader

- **Author / audience:** leader
- **Approval:** owner, 2026-09-28, in chat (rule correction and step 6 help)
- **Scope / acceptance:** executor high-tier rule corrected; OpenCode tier map verified end to end
- **Status:** blocked
- **Branch / base:** biscuit/biscuit-worktree; published main not observed
- **Checked revision / changed:** a016301571bdc19d0cfc49360820af90e26ec873 plus uncommitted:  M .sw/manifest.json;  M .sw/workspace.md;  M product/project/base/.sw/workspace.md
- **Owners / dependencies:** Leader; depends on the OpenAI usage limit resetting
- **Decisions / remaining:** Owner correction applied (uncommitted): executors are not high unless the Leader suggests it and the user approves, or the user runs it (product workspace.md + dogfood update; validate PASS, diff --check clean). Tier map written: openai/gpt-6-astra #low (5 light roles) / #high (4 standard roles); /api/agent confirms all 8 kit agents resolve to it. Smoke runs: without -m, the auto compaction step used a default OpenRouter model (no top-level model in any config layer) and failed on that key's limit; with -m openai/gpt-6-astra#low the request reached OpenAI and failed provider.quota (usage limit reached). Stopped per the quota rule. Remaining: a default model so compaction does not fall back to OpenRouter; re-run the smoke check after the OpenAI limit resets.
- **Validation:** Leader, local Windows 2026-09-28 UTC: .sw/sw.ps1 validate PASS (2 known warnings); git diff --check clean; opencode-cli 2.0.18 api GET /api/agent shows the tier map; opencode-cli run results as above
- **Not validated / risks:** no successful model reply yet (quota); default-model fix not yet chosen
- **Publication:** local-only until a human pushes
- **Next action:** owner: choose the default-model fix and approve committing the rule correction; Leader re-runs the smoke check after the limit resets
