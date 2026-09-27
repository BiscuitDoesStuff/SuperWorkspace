# p1-05a-permission-correction - assignment - 2026-09-27T100559Z - leader

- **Author / audience:** leader (cloud Leader session); reader: the cloud worker session the Leader starts (role: project-developer), then the owner.
- **Approval:** the owner chose "correction first" in the realignment (2026-09-27) and approved this package's plan on 2026-09-27. Roadmap: Phase 1 package 5a. Cloud worker flow: `docs/development.md`.
- **Scope / acceptance:** Phase 1 package 5a. Before editing:
  - read the roadmap's 5a entry, `.sw/comms/archive/p1-checkpoint-runtime/SUMMARY.md` and its events `081333Z`, `083103Z`, `085042Z`, `090707Z`;
  - load `minimal-change`.

  **Background.** OpenCode desktop 2.0.17/2.0.18 ignores the project-level `permissions` list in `opencode.jsonc`; agent-frontmatter rules work. So in OpenCode no kit agent has the push/reset/clean/stash/`gh` deny, the commit ask or the `external_directory` ask. Today:
  - the session list is `product/project/opencode.base.json:8-19`; `Get-SwRender` (`product/lib/Sw.Kit.psm1` ~81-93) adds `editDeny` and `Get-SwGhRules`, plus `agents.build.permissions`, and writes `opencode.jsonc`;
  - agent files (`product/project/base/.opencode/agents/*.md`) are copied verbatim (`$add`, ~64-73; only `{{PROJECT}}` is replaced);
  - `validate` (`Test-SwProject`, `product/lib/Sw.Project.psm1` ~382-420) models each role as a hard-coded `$base` (with `.env` asks) + `opencode.jsonc` + the agent's rules, which is not what OpenCode loads.

  1. **One owning source, injected at render.**
     - Add `Get-SwSessionRules` in `Sw.Project.psm1`. In order, it returns: the `opencode.base.json` permissions, the profile `editDeny`, `Get-SwGhRules <tier>`, then `read` `*.env` ask, `*.env.*` ask, `*.env.example` allow (the forms the read-only agents use today).
     - `Get-SwRender` uses it for `opencode.jsonc` (keep the project list; a future OpenCode may honour it) and prepends it to `agents.build.permissions`.
     - `Get-SwRender` prepends it to the `permissions:` list of every rendered agent file under `.opencode/agents/`, so session rules come first and the agent's own rules still win (last match wins). An agent with no `permissions:` block gets one. The canonical agent files keep only their own rules.
     - The output must parse with `Read-SwFrontmatter` unchanged. Do not widen the parser; quote values as the existing files do.
     - Read-only roles keep their leading `"*"` deny and their `external_directory` allow; no behaviour change there.
     - `GhTier` changes (`sw tiers`, config edits) must re-render the agents the same way `opencode.jsonc` is re-rendered today; check the paths that regenerate `opencode.jsonc` and cover them.
  2. **`validate` models what OpenCode loads.**
     - Each role's policy is that agent file's frontmatter only; drop the hard-coded `$base` and the `opencode.jsonc` term. `build` stays `agents.build` from the JSON.
     - The existing expected cases must still pass.
     - Add a drift error: an installed agent whose leading rules differ from `Get-SwSessionRules` for the project's config (message names the file and says to run `update`).
  3. **Widen the read-only shell allowlist** in `project-plan.md`, `project-architect.md` and `project-review.md`.
     - Allow common read forms of `git status`, `git diff`, `git log` and `git show` (for example with `*` arguments).
     - `--output`, `--ext-diff` and `--textconv` must stay unreachable: keep the ordered deny-then-reallow pattern (AGENTS.md "Permission rules are ordered"), and make any re-allow narrow enough that it cannot re-open those flags.
     - Keep the three lists identical. Add matrix cases in `validate` for the new forms and for each blocked flag.
  4. **Docs** (`product/project/base/.sw/workspace.md` and `.sw/collaboration.md`):
     - Rule table: OpenCode rows state enforcement through agent frontmatter. OpenCode `.env` becomes "unverified (desktop re-test pending)". Claude `.env` becomes "guardrail (Read tool only; shell reads are not covered)".
     - A note: OpenCode's built-in agents other than Build carry no kit rules; Build gets them only from `opencode.jsonc`.
     - Correct the claim that branch protection is the real push control (`workspace.md` ~105, `collaboration.md` "Protect main" ~135): the solo ruleset stops force pushes and deletion, not ordinary pushes.
  5. **Also:**
     - add a `product/CHANGELOG.md` entry under 0.3.0-dev;
     - add Pester tests in `tests/Sw.Tests.ps1` for injection (every agent, order, the parser accepts the output), the drift error, the new matrix cases, and `-WhatIf` writing nothing;
     - refresh the dogfood copy with `pwsh -NoProfile -File product/sw.ps1 update .`.

  Success evidence:
  - each behaviour has a test, run by hand against `product/lib`;
  - a fresh init validates, and every rendered agent carries the session rules first;
  - `update .` on this repository works;
  - CI is green on the worker branch.

  Exclusions:
  - no Claude hooks or `Bash(cat ...)` rules;
  - no skills move (package 6);
  - no frontmatter parser changes;
  - no edits to `docs/research/`, the roadmap or `docs/decisions.md` (the Leader records those);
  - no tags or other GitHub writes.
- **Status:** pending
- **Branch / base:** worker branch `cloud/p1-05a-permission-correction`, created from `main-ahb0v0` at the commit that holds this assignment. Published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019.
- **Checked revision / changed:** 2e5654875ccb5417685b3eec8edc4b385bd79964 plus this assignment.
- **Owners / dependencies:** the worker owns:
  - `product/lib/Sw.Kit.psm1` and `product/lib/Sw.Project.psm1`;
  - `product/project/opencode.base.json` (only if needed);
  - the three read-only agent files;
  - `product/project/base/.sw/workspace.md` and `.sw/collaboration.md`;
  - `tests/Sw.Tests.ps1` and `product/CHANGELOG.md`;
  - the dogfood copies that `update` rewrites (`.sw/`, `.opencode/`, `opencode.jsonc`, the `AGENTS.md` block);
  - its own events here.

  The Leader owns everything else and does not commit to `main-ahb0v0` while the worker runs.
- **Decisions / remaining:** worker steps, in order:
  1. Install PowerShell 7: `curl -sSLO https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb && dpkg -i packages-microsoft-prod.deb && apt-get update && apt-get install -y powershell`. Launchpad PPA warnings are harmless. Delete the `.deb` afterwards.
  2. Read this assignment and the cited records.
  3. Implement.
  4. Validate.
  5. Commit the owned paths only (`feat(kit): ...`, body naming this task), and push to `cloud/p1-05a-permission-correction` only.
  6. Read the `ci` run for the pushed commit. Fix failures within scope and push again, until green or blocked.
  7. Write the `submission` event (`pwsh -NoProfile -File .sw/sw.ps1 comms event -Task p1-05a-permission-correction -Event submission -From worker-p1-05a -Status complete`, every field filled, including CI run IDs and results, and a sample rendered agent frontmatter), then commit and push it.

  On a scope question, or a failure you cannot fix within scope, write a `progress` event with status `blocked` and push it.
- **Validation:** the worker runs:
  - `pwsh -NoProfile -File .sw/sw.ps1 validate`;
  - a fresh `pwsh -NoProfile -File product/sw.ps1 init <scratch>/sw-check -Profile unreal -Name Check`, then its `validate`, `claude enable`, `validate` again, then `update` twice (the second run is a no-op);
  - a tier change on the scratch project (`sw tiers` or `githubTier` 1), then `validate`: the agents carry the tier-1 `gh` allows;
  - a hand-edited agent whose leading rules differ: `validate` fails with the drift error;
  - `git diff --check`.

  Run each new test's steps by hand with the modules imported from `product/lib` (CRLF checkout, as `tests/Sw.Tests.ps1` does). Pester cannot run in the cloud container, so the CI `ci` run on the pushed branch is the Pester evidence; never claim a result you did not see.
- **Not validated / risks:**
  - Only the desktop re-test shows what OpenCode enforces. The review agent already carried a `.env` ask and a `/review` child still read `.env` with no prompt (`085042Z`), so the `.env` rule form may be wrong. Do not claim OpenCode `.env` enforcement.
  - `update` rewrites agent files in user projects. Locally edited agents follow the existing `skip-modified` / `incoming/` path.
- **Publication:** the worker pushes `cloud/p1-05a-permission-correction`; the Leader fast-forwards `main-ahb0v0` after review; `main` stays the owner's.
- **Next action:** worker; complete the steps above. Completion evidence: a filled submission event, with a green CI run, on the pushed worker branch.
