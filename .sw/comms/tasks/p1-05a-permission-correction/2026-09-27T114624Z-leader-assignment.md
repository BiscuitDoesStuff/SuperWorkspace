# p1-05a-permission-correction - assignment - 2026-09-27T114624Z - leader

- **Author / audience:** leader (cloud Leader session); reader: the cloud worker session the Leader starts (role: project-developer), then the owner.
- **Approval:** the owner chose "RTK rule twins" on 2026-09-27, after the root cause in `2026-09-27T*-leader-progress.md` (the latest progress event in this folder). This is a follow-up assignment inside package 5a; the first assignment (100559Z) and its submission are the base.
- **Scope / acceptance:** close the RTK bypass. Before editing:
  - read the latest progress event here (root cause);
  - read the first assignment and the submission (103115Z);
  - load `minimal-change`.

  **Root cause.** In OpenCode v2.0.18 the shell `create.before` hook runs before the shell tool's permission check (`packages/core/src/shell.ts:274`, then `tool/plugin/shell.ts` `prepare` → `permission.assert`). The kit's `product/project/base/.opencode/plugins/rtk.ts` rewrites commands in that hook (`git push origin main` becomes `rtk git push origin main`). So rules such as `git push *`, `git stash *`, `gh *` and `git commit *` stop matching, and `shell * allow` wins. Commands RTK does not rewrite are still checked.

  1. **Generate RTK twins from the same sources.**
     - For every `shell` rule in a rendered permission list, emit a twin with the resource prefixed by `rtk ` and the same effect, directly after the original. This keeps last-match order equivalent. Skip the twin when the resource is exactly `*`.
     - The rendered lists covered are: every `.opencode/agents/*.md` `permissions` list (the injected session rules **and** the role's own rules, such as the read-only allowlist and the worker's branch denies), `opencode.jsonc` `permissions`, and `agents.build.permissions`.
     - The twins are generated at render time only. Canonical agent files and `Get-SwSessionRules` / `Get-SwGhRules` stay the owning sources, with no hand-written `rtk ` rules. Put the transformation in one helper.
     - The output must parse with `Read-SwFrontmatter` unchanged. Do not widen the parser.
  2. **`validate`.**
     - For every existing `shell` matrix case, also expect the same decision for `rtk <command>`: push denied, commit ask or deny, `gh` tier cases, read-only allows and denies, and the worker denies.
     - The drift check compares against the twinned session list, so a hand-removed twin is drift.
     - Add a check that no rendered `shell` rule lacks its twin (it may share the drift code).
  3. **Shim comment.** Replace the incorrect order comment in `rtk.ts` with the true 2.0.18 order and a pointer to the twins. The rewrite logic stays as it is.
  4. **Docs** (`product/project/base/.sw/workspace.md`):
     - one sentence stating that the RTK plugin rewrites commands before OpenCode's permission check, so the kit renders an `rtk ` twin for every shell rule;
     - OpenCode's `.env` row may now say "enforced (ask)", because OpenCode's own default asks and the desktop showed the dialog. Keep the push row "guardrail".
  5. **Also:**
     - add a `product/CHANGELOG.md` line under 0.3.0-dev;
     - add Pester tests in `tests/Sw.Tests.ps1`: twins for the session rules and role rules, their order, no twin for `*`, the parser accepts the output, and the `rtk` matrix cases;
     - refresh the dogfood copy with `pwsh -NoProfile -File product/sw.ps1 update .`.

  Success evidence:
  - replayed by hand against `product/lib`: `Get-SwDecision` over a rendered project-leader list gives deny for `rtk git push origin main`, `rtk git stash list` and `rtk gh repo list`, and ask for `rtk git commit -m x`;
  - `project-review` allows `rtk git status`;
  - a fresh init validates;
  - CI is green on the worker branch.

  Exclusions:
  - no change to the rewrite behaviour or removal of the shim;
  - no Claude-side changes (note in the submission whether Claude's RTK path has the same ordering issue, from repository evidence only);
  - no parser changes;
  - no edits to `docs/research/`, the roadmap or `docs/decisions.md` (the Leader corrects those);
  - no tags or other GitHub writes.
- **Status:** pending
- **Branch / base:** worker branch `cloud/p1-05a-rtk-twins`, created from `main-ahb0v0` at the commit that holds this assignment. Published main 0ee9b5eb864b1a410e4d45da0b541f7da5c88019.
- **Checked revision / changed:** 92eade3 plus this assignment.
- **Owners / dependencies:** the worker owns:
  - `product/lib/Sw.Kit.psm1` and `product/lib/Sw.Project.psm1`;
  - `product/project/base/.opencode/plugins/rtk.ts` (comment only);
  - `product/project/base/.sw/workspace.md`;
  - `tests/Sw.Tests.ps1` and `product/CHANGELOG.md`;
  - the dogfood copies that `update` rewrites;
  - its own events here.

  The Leader owns everything else and does not commit to `main-ahb0v0` while the worker runs.
- **Decisions / remaining:** worker steps, in order:
  1. Install PowerShell 7: `curl -sSLO https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb && dpkg -i packages-microsoft-prod.deb && apt-get update && apt-get install -y powershell`. Delete the `.deb` afterwards.
  2. Read this assignment and the cited records.
  3. Implement.
  4. Validate.
  5. Commit the owned paths only (`fix(kit): ...`, body naming this task), and push to `cloud/p1-05a-rtk-twins` only.
  6. Read the `ci` run for the pushed commit. Fix failures within scope and push again, until green or blocked.
  7. Write a `submission` event (`pwsh -NoProfile -File .sw/sw.ps1 comms event -Task p1-05a-permission-correction -Event submission -From worker-p1-05a-rtk -Status complete`, every field filled, including CI run IDs and a sample rendered project-leader and project-review list), then commit and push it.

  On a scope question, or a failure you cannot fix within scope, write a `progress` event with status `blocked` and push it.
- **Validation:** the worker runs:
  - `pwsh -NoProfile -File .sw/sw.ps1 validate`;
  - a fresh `pwsh -NoProfile -File product/sw.ps1 init <scratch>/sw-check -Profile unreal -Name Check`, then its `validate`, `claude enable`, `validate` again, then `update` twice (the second run is a no-op);
  - a hand-removed twin in a scratch agent: `validate` fails;
  - `git diff --check`.

  Pester cannot run in the cloud container; the CI `ci` run is the Pester evidence. Never claim a result you did not see.
- **Not validated / risks:**
  - Only the desktop re-test shows OpenCode's behaviour.
  - Twins cover the `rtk ` prefix only. Another plugin that rewrites commands would bypass the rules the same way; note that in the docs sentence.
- **Publication:** the worker pushes `cloud/p1-05a-rtk-twins`; the Leader fast-forwards `main-ahb0v0` after review; `main` stays the owner's.
- **Next action:** worker; complete the steps above. Completion evidence: a filled submission event, with a green CI run, on the pushed worker branch.
