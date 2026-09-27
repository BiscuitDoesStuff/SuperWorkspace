# p1-05a-permission-correction - submission - 2026-09-27T120333Z - worker-p1-05a-rtk

- **Author / audience:** worker-p1-05a-rtk (cloud worker session, role project-developer); readers: the cloud Leader, then the owner.
- **Approval:** the owner chose "RTK rule twins" on 2026-09-27 (assignment `2026-09-27T114624Z-leader-assignment.md`). This submission is for review. Nothing beyond the assignment was done.
- **Scope / acceptance:** close the RTK bypass, assignment items 1-5.
  1. **Twins from the same sources.** One helper, `Add-SwRtkTwins` in `Sw.Project.psm1` (exported, because `validate` needs it in installed projects). For each rule it emits the rule, then, when `action` is `shell` and `resource` is not exactly `*`, a twin `shell "rtk <resource>"` with the same effect. Render uses it in three places:
     - every `.opencode/agents/*.md` list. `Add-SwSessionRules` (`Sw.Kit.psm1`) now reads the agent's own rules from the canonical text and re-emits the whole list as twins(session rules + role rules). A role list that is not in the kit's three-line form throws; nothing else changed;
     - `opencode.jsonc` `permissions`;
     - `agents.build.permissions` (the twinned session list, then the subagent rules).

     Canonical agent files, `Get-SwSessionRules` and `Get-SwGhRules` hold no `rtk ` rules. The output parses with `Read-SwFrontmatter` unchanged. With the twin lines stripped, a fresh `unreal` init's 9 agents are byte-identical to the a1b3933 render, and `opencode.jsonc` is equal.
  2. **`validate`:**
     - every `shell` matrix case also expects the same decision for `rtk <command>`. The change is in `Expect`, so push, reset, clean and stash denies, commit ask/deny, the `gh` tier cases, read-only allows and denies, and the worker denies are all covered. A fresh init goes from 469 to 743 permission cases;
     - the drift check compares against `Add-SwRtkTwins (Get-SwSessionRules ...)`;
     - new error: `RTK twin missing: <list> shell [<resource>] needs its [rtk ...] twin, same effect, directly after it; run sw update`. It runs for each role's agent file, `opencode.jsonc permissions` and `opencode.jsonc agents.build`. Rules already starting with `rtk ` are skipped, so one removed twin gives one message.
  3. **Shim comment.** `rtk.ts` now states the 2.0.18 order: `packages/core/src/shell.ts:274` fires `create.before` first, and the shell tool's `prepare` (`tool/plugin/shell.ts` ~116-136, called ~210) then runs `permission.assert`, so the check sees the rewritten command. It points to `Add-SwRtkTwins`. The rewrite logic is unchanged.
  4. **Docs** (`.sw/workspace.md`):
     - one sentence says the RTK plugin rewrites shell commands before OpenCode's permission check, so the kit renders an `rtk ` twin after every shell rule. It adds that another plugin that rewrites commands would bypass the rules the same way;
     - OpenCode `.env` row: "enforced (ask)";
     - the push row stays "guardrail".
  5. `product/CHANGELOG.md` has a "Fixed (... RTK bypass)" line under 0.3.0-dev. VERSION stays 0.3.0-dev. Pester tests were added, and the dogfood copy was refreshed with `update .`.

  Success evidence, replayed by hand against `product/lib` on a rendered project-leader list: deny for `rtk git push origin main`, `rtk git stash list` and `rtk gh repo list`; ask for `rtk git commit -m x`. `project-review` allows `rtk git status`. A fresh init validates, and CI is green (see Validation).

  Exclusions respected:
  - no change to the rewrite behaviour, and the shim is kept;
  - no Claude-side changes and no parser changes;
  - no edits to `docs/research/`, the roadmap or `docs/decisions.md`;
  - no tags, PRs or other GitHub writes.
- **Status:** complete
- **Branch / base:** `cloud/p1-05a-rtk-twins`, created from `main-ahb0v0` at a1b393394d05e586853dbba01d602e76f12ff386. Published main was not observed this session; the assignment gives 0ee9b5eb864b1a410e4d45da0b541f7da5c88019.
- **Checked revision / changed:** 7988266753934d8b9ad37e8e9295d398fc71291f. This event is committed on top of it. There are two commits:
  - 3ddfefb, the feature;
  - 7988266, the `-WhatIf` fix below.

  Changed paths:
  - kit: `product/lib/Sw.Kit.psm1`, `product/lib/Sw.Project.psm1`, `product/project/base/.opencode/plugins/rtk.ts`, `product/project/base/.sw/workspace.md`, `product/CHANGELOG.md`;
  - tests: `tests/Sw.Tests.ps1`;
  - dogfood copies written by `update .`: `.opencode/agents/*.md` (9), `.opencode/plugins/rtk.ts`, `.sw/lib/Sw.Project.psm1`, `.sw/workspace.md`, `.sw/manifest.json`, `opencode.jsonc`.
- **Owners / dependencies:** the worker owned the paths above. The Leader owns the rest and reviews. There are no open dependencies.
- **Decisions / remaining:**
  - **CI fix, 7988266.** The first CI run (3ddfefb) failed 2 Pester tests on both OSes: `Session rules ... -WhatIf writes nothing` and `Sync and init lifecycle.-WhatIf writes nothing`. Cause: `ForEach-Object Length` (the member form) goes through ShouldProcess, so under `-WhatIf` it returned nothing, and the new form check in `Add-SwSessionRules` threw. I reproduced it locally with `Update-SwProject -WhatIf` on the 3ddfefb kit, then replaced it with a plain loop. The same command now passes.
  - **Scope of the twin check.** It checks the kit roles only (`.sw/roles.json`), `opencode.jsonc` `permissions` and `agents.build`, matching the drift check. A project's own extra agents are not checked, and they get no twins, so RTK-rewritten commands bypass their shell rules. The Leader may want this noted.
  - **Twin form.** A twin is `rtk ` plus the same pattern, so `rtk git *--o*` and `rtk git log --oneline -??` keep the one-character re-allow narrow. Trailing-` *` bare matching applies to twins as it does to the originals (`rtk git status` matches `rtk git status *`).
  - **Claude's RTK path (repository evidence only).**
    - The kit ships no Claude hook that rewrites commands. RTK reaches Claude only through the user-level `~/.claude/RTK.md` include (`Install-SwGlobal`, `Sw.Kit.psm1`), which tells the model to type `rtk ...` itself.
    - The generated `.claude/settings.json` denies `Bash(<verb>:*)` prefixes (`Get-SwClaudeGhDeny`, plus the session denies). Whether Claude's prefix matching strips a leading `rtk` is not recorded in this repository. If it does not, a model-typed `rtk git push` would not match `Bash(git push:*)`, a similar gap by a different route.
    - Research F20 (`docs/research/08-permissions-safety.md`) records that a PreToolUse hook's decision cannot loosen a deny. It does not say whether rules see a hook-rewritten command. RTK's own user-level Claude hook, if a user installs one, is outside the kit.
    - Unverified; needs a Claude runtime check.
  - Sample rendered lists, fresh `unreal` init at tier 0, one rule per `|`:
    - `project-leader`: `shell "*" allow | external_directory "*" ask | skill "*" allow | subagent "*" deny | shell "git commit *" ask | shell "rtk git commit *" ask | shell "git push *" deny | shell "rtk git push *" deny | shell "git reset --hard *" deny | shell "rtk git reset --hard *" deny | shell "git clean *" deny | shell "rtk git clean *" deny | shell "git stash *" deny | shell "rtk git stash *" deny | shell "gh *" deny | shell "rtk gh *" deny | edit "*.uasset" deny | edit "*.umap" deny | shell "gh issue list *" allow | shell "rtk gh issue list *" allow | ... (each of the 18 gh read verbs, then its rtk twin) ... | shell "gh browse --no-browser *" allow | shell "rtk gh browse --no-browser *" allow | read "*.env" ask | read "*.env.*" ask | read "*.env.example" allow | subagent "*" allow`
    - `project-review`: the same session block, then `* "*" deny | read "*" allow | read "*.env" ask | read "*.env.*" ask | read "*.env.example" allow | glob "*" allow | grep "*" allow | skill "*" allow | question "*" allow | external_directory "*" allow | shell "git status *" allow | shell "rtk git status *" allow | shell "git diff *" allow | shell "rtk git diff *" allow | shell "git log *" allow | shell "rtk git log *" allow | shell "git show *" allow | shell "rtk git show *" allow | shell "git rev-parse HEAD" allow | shell "rtk git rev-parse HEAD" allow | shell "git rev-parse origin/main" allow | shell "rtk git rev-parse origin/main" allow | shell "git ls-files --others --exclude-standard" allow | shell "rtk git ls-files --others --exclude-standard" allow | shell "git *--o*" deny | shell "rtk git *--o*" deny | shell "git *--ext-diff*" deny | shell "rtk git *--ext-diff*" deny | shell "git *--textconv*" deny | shell "rtk git *--textconv*" deny | shell "git log --oneline" allow | shell "rtk git log --oneline" allow | shell "git log --oneline -??" allow | shell "rtk git log --oneline -??" allow | shell "git ls-files --others --exclude-standard" allow | shell "rtk git ls-files --others --exclude-standard" allow`
  - Remaining: the owner's desktop re-test in OpenCode 2.0.18 with RTK installed (push, stash, `gh`, commit as project-leader; `git status` in a read-only child).
- **Validation:** runner: this cloud container (Linux, PowerShell 7.6.6, git 2.43.0), 2026-09-27 ~11:45-12:05 UTC. Pester could not be installed here (PSGallery "No match"; the direct download was refused by the proxy with 403).
  - Hand replay, a scratch script (not committed) with the modules imported from `product/lib`. It covers:
    - the new and changed Session-rules tests: twin unit, leads every agent with the twinned list, twin order for leader, review and worker, no twin for `*`, the canonical files carry no `rtk `;
    - the `rtk` decisions above;
    - the negative fixtures: session twin missing, role twin missing, `opencode.jsonc` twin missing, drift, `--output` re-open, tier mismatch;
    - a positive fixture.

    Result: 135 ok, 0 failed (after 7988266).
  - A fresh `pwsh -NoProfile -File product/sw.ps1 init <scratch>/sw-check -Profile unreal -Name Check`, then:
    - `validate`: PASS (743 permission cases);
    - `claude enable`, then `validate`: PASS;
    - `pwsh -NoProfile -File product/sw.ps1 update <scratch>/sw-check` twice: "47 unchanged, 0 changed" both times.
  - A hand-removed `rtk git push *` twin in the scratch `project-developer.md` made `validate` FAIL with:
    - `Session rule drift: ...project-developer.md ...`;
    - `RTK twin missing: .opencode/agents/project-developer.md shell [git push *] ...`;
    - `STATIC project-developer shell [rtk git push]` and `[rtk git push origin main]`: expected deny, got allow.
  - `Update-SwProject -WhatIf` on a scratch project writes nothing and does not throw (after 7988266).
  - Repository:
    - `pwsh -NoProfile -File product/sw.ps1 update .`: 13 changed on the first run; after the fix, 45 unchanged (only `kitCommit` in `.sw/manifest.json`);
    - `pwsh -NoProfile -File .sw/sw.ps1 validate`: PASS, with the 2 existing research-lint warnings;
    - `git diff --check`: clean.
  - CI on 3ddfefb: `ci` run 36317223719 FAILED on both OSes (Pester 101 passed, 2 failed, the `-WhatIf` cause above). `sw-validate` run 36317223712 succeeded.
  - CI on 7988266:
    - `ci` run 36317525369: success. `test (ubuntu-latest)` job 108614949093 had Pester 103 passed, 0 failed, and "Fresh install validates" PASS (743 cases). `test (windows-latest)` job 108614948997 had Pester 103 passed, 0 failed, and "Fresh install validates" PASS.
    - `sw-validate` run 36317525406: success.
- **Not validated / risks:**
  - No OpenCode runtime check was possible here. Only the owner's desktop re-test shows that the twins stop `rtk git push` and friends in 2.0.18.
  - The twins cover the `rtk ` prefix only. `rtk rewrite` outputs other than `rtk <original>`, if RTK ever emits them, and any other rewriting plugin bypass the rules; the docs say so.
  - Projects' own extra agents get no twins (see Decisions).
  - The Claude-side question is unverified (see Decisions).
  - Pester was not run locally. The CI jobs above are the Pester evidence.
- **Publication:** pushed to `cloud/p1-05a-rtk-twins` only. The Leader fast-forwards `main-ahb0v0` after review; `main` stays the owner's.
- **Next action:**
  - Leader: review 3ddfefb, 7988266 and this event, then fast-forward `main-ahb0v0`, and correct the decision entry, roadmap and harness notes it owns.
  - Owner: run the desktop re-test with RTK installed (push, stash, `gh repo list` and commit as project-leader; `git status` in a `/review` child).
  - Completion evidence: a Leader `review` or `approval` event and the re-test results.
