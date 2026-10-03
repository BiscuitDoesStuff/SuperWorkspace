# p1-05a-permission-correction - submission - 2026-09-27T103115Z - worker-p1-05a

- **Author / audience:** worker-p1-05a (cloud worker session, role project-developer); readers: the cloud Leader, then the owner.
- **Approval:** the owner approved package 5a's plan on 2026-09-27 (assignment `2026-09-27T100559Z-leader-assignment.md`). This submission is for review. Nothing beyond the assignment was done.
- **Scope / acceptance:** Phase 1 package 5a, items 1-5 of the assignment:
  1. One owning source, injected at render. `Get-SwSessionRules` (in `Sw.Project.psm1`, exported) returns, in order: the base list, the profile `editDeny`, `Get-SwGhRules <tier>`, then `read *.env` ask, `read *.env.*` ask, `read *.env.example` allow. `Get-SwRender` does four things with it:
     - prepends it to every rendered `.opencode/agents/*.md` `permissions:` list, through a new helper `Add-SwSessionRules` in `Sw.Kit.psm1` (not exported); an agent with no block gets one;
     - uses it as the `opencode.jsonc` `permissions` list;
     - prepends it to `agents.build.permissions`;
     - leaves the canonical agent files holding only their own rules.
  2. `validate` models what OpenCode loads:
     - each role's policy is its agent frontmatter only, and `build` is `agents.build`; the hard-coded `$base` and the `opencode.jsonc` term are gone;
     - the existing expected cases still pass;
     - new error: `Session rule drift: .opencode/agents/<role>.md does not start with the session rules for this config; run sw update`. The same check covers `agents.build`.
  3. Read-only allowlist (`project-plan`, `project-architect`, `project-review`, still identical):
     - allows `git status *`, `git diff *`, `git log *` and `git show *`;
     - then denies `git *--o*`, `git *--ext-diff*` and `git *--textconv*`;
     - then re-allows only `git log --oneline`, `git log --oneline -??` and `git ls-files --others --exclude-standard`. `?` is one character, so a re-allow cannot reach a flag;
     - removed the exact forms that the wildcards now cover.
  4. Docs in `.sw/workspace.md`:
     - the harness table heads the OpenCode column "(agent frontmatter)";
     - OpenCode `.env` reads "unverified (desktop re-test pending)"; Claude `.env` reads "guardrail (Read tool only; shell reads are not covered)";
     - the read-only shell row names the read forms and the denied flags;
     - a note that OpenCode applies only agent frontmatter, and that built-in agents other than Build carry no kit rules (Build gets them only from `opencode.jsonc` `agents.build`);
     - the "GitHub tier" line says the guardrails are in every kit agent (run `sw update` after a change).

     The push-control claim is corrected in both `.sw/workspace.md` and `.sw/collaboration.md` ("Protect main"): the solo ruleset stops force pushes and deletion, not ordinary pushes.
  5. `product/CHANGELOG.md` has an entry under 0.3.0-dev (VERSION is unchanged; it is still 0.3.0-dev). Pester tests are added, and the dogfood copy is refreshed with `update .`.

  Exclusions respected: no Claude hooks or `Bash(cat ...)` rules, no skills move, no frontmatter parser change, and no edits to `docs/research/`, the roadmap or `docs/decisions.md`. No tags, PRs or other GitHub writes.
- **Status:** complete
- **Branch / base:** `cloud/p1-05a-permission-correction`, created from `main-ahb0v0` at ace5530fe5b3d9dde21d8562c20cd0a26753207d. Published main (not observed this session; assignment value): 0ee9b5eb864b1a410e4d45da0b541f7da5c88019.
- **Checked revision / changed:** c3a53e48a562f01784d35538461d6e197a96400d (the feature commit; this event is committed on top of it).
  - Kit: `product/lib/Sw.Kit.psm1`, `product/lib/Sw.Project.psm1`, `product/project/opencode.base.json`, `product/project/base/.opencode/agents/project-{plan,architect,review}.md`, `product/project/base/.sw/{workspace,collaboration}.md`, `product/CHANGELOG.md`.
  - Tests: `tests/Sw.Tests.ps1`.
  - Dogfood copies written by `update .`: `.opencode/agents/*.md` (9), `.sw/{workspace,collaboration}.md`, `.sw/lib/Sw.Project.psm1`, `.sw/manifest.json`, `opencode.jsonc`.
- **Owners / dependencies:** the worker owned the paths above. The Leader owns the rest and reviews. There are no open dependencies.
- **Decisions / remaining:**
  - **Base list moved (for the Leader to confirm).** The base session list moved from `opencode.base.json` into `$script:SessionBase` in `Sw.Project.psm1`, and `opencode.base.json` now has no `permissions` key. Reason: `validate` runs in installed projects, which ship `.sw/lib/Sw.Project.psm1` but not `opencode.base.json`. Without the move, the drift check could not compute `Get-SwSessionRules` for the project's config. The assignment listed that file as "only if needed". Outcomes:
    - `opencode.jsonc` now carries the `.env` asks as well, and its `permissions` key comes after `compaction`;
    - `README.md:99` still lists `opencode.base.json`, which is still true;
    - AGENTS.md "One owning source per rule" could add "Session rules live only in `Get-SwSessionRules`". That file is the Leader's.
  - **Drift check scope.** It covers the roles in `.sw/roles.json` only. A project's own extra agents are not checked, so they are not forced to carry the rules.
  - **Tier changes.** No command other than `init` and `update` writes `githubTier`. `sw tiers` writes only the per-user model map. Both paths go through `Get-SwRender`, so agents re-render with `opencode.jsonc`. A `githubTier` edit without `update` now also fails with the drift error, alongside the existing "do not match githubTier" error.
  - **Abbreviated flags.** git 2.43 rejects abbreviated diff options (`--ext`, `--textc`, `--outp=`, all "invalid option"), so the substring denies are not bypassed by abbreviation.
  - **Plain reads run filters.** Plain `git diff`, `git log -p` and `git show` still run textconv and diff drivers as git configures them by default. That was already true of the old exact `git diff` allow. The role bodies still recommend the `--no-ext-diff --no-textconv` forms.
  - Sample rendered frontmatter, `project-review` in a fresh `unreal` init at tier 0 (condensed to one rule per line; the file uses the three-line action/resource/effect form):
    ```
    permissions:
      shell * allow | external_directory * ask | skill * allow | subagent * deny
      shell "git commit *" ask | shell "git push *" deny | shell "git reset --hard *" deny
      shell "git clean *" deny | shell "git stash *" deny | shell "gh *" deny
      edit "*.uasset" deny | edit "*.umap" deny
      shell "gh issue list *" allow ... shell "gh browse --no-browser *" allow   (18 read verbs)
      read "*.env" ask | read "*.env.*" ask | read "*.env.example" allow
      --- role rules ---
      "*" * deny | read * allow | read "*.env" ask | read "*.env.*" ask | read "*.env.example" allow
      glob * allow | grep * allow | skill * allow | question * allow | external_directory * allow
      shell "git status *" allow | shell "git diff *" allow | shell "git log *" allow | shell "git show *" allow
      shell "git rev-parse HEAD" allow | shell "git rev-parse origin/main" allow
      shell "git ls-files --others --exclude-standard" allow
      shell "git *--o*" deny | shell "git *--ext-diff*" deny | shell "git *--textconv*" deny
      shell "git log --oneline" allow | shell "git log --oneline -??" allow
      shell "git ls-files --others --exclude-standard" allow
    ```
  - Remaining (roadmap 5a): the owner's desktop re-test of the smoke checklist.
- **Validation:** runner: this cloud container (Linux, PowerShell 7.6.6, git 2.43.0), 2026-09-27 ~10:05-10:35 UTC. Pester could not be installed here (`Install-Module Pester` found no match).
  - Hand run of the Pester file through a local keyword shim (scratch only, not committed) against `product/lib`:
    - `Session rules`, `Validator negative fixtures`, `Permission model`, `Validator positive fixture`: 36 passed, 0 failed;
    - whole file: 88 passed. The 10 failures were all in `Backup secret filter`, where the shim lacks `InModuleScope -Parameters`; that suite has no change here.
  - `pwsh -NoProfile -File product/sw.ps1 init <scratch>/sw-check -Profile unreal -Name Check`, then its `validate`: PASS (469 permission cases). Every rendered agent carries the session rules first.
  - The same project, `claude enable`, then `validate`: PASS. Then `update` twice: both "47 unchanged, 0 changed".
  - Tier change on the scratch project (`githubTier` set to 1 in `.sw/config.json`):
    - `validate` before `update`: FAILED with the drift error for the agents;
    - `update`: 9 agents and `opencode.jsonc` updated;
    - `validate` after: PASS, and every agent carries `gh issue create *` and `gh pr create --draft *` allow.
  - A hand-edited leading rule in `project-developer.md`: `validate` FAILED with `Session rule drift: .opencode/agents/project-developer.md ...; run sw update`, plus the matrix errors it causes.
  - `Initialize-SwProject ... -WhatIf` on an empty directory: 0 files written.
  - Init from a CRLF copy of `product/`, then `validate`: PASS; the rendered agents have LF endings.
  - Repository checks:
    - `pwsh -NoProfile -File product/sw.ps1 update .`: 13 changed;
    - `pwsh -NoProfile -File .sw/sw.ps1 validate`: PASS, with the 2 existing research-lint warnings;
    - a second `update .`: "45 unchanged, 0 changed";
    - `git diff --check`: clean.
  - CI on c3a53e4:
    - `sw-validate` run 36312789702: success;
    - `ci` run 36312789708, `test (ubuntu-latest)` job 108601799784: success (Pester and fresh install validates);
    - `ci` run 36312789708, `test (windows-latest)` job 108601799898: success (Pester and fresh install validates). Run 36312789708 concluded success on both OSes.
- **Not validated / risks:**
  - No OpenCode runtime check was possible here. Whether OpenCode 2.0.17/2.0.18 enforces the injected rules, `agents.build` from `opencode.jsonc`, and the `.env` rule form needs the owner's desktop re-test. The `.env` rows stay "unverified".
  - Pester was not run locally. The CI jobs above are the Pester evidence.
  - `update` rewrites every agent file in user projects. Locally edited agents become `skip-modified`, get an `incoming/` copy, and then fail the drift check until the user merges them.
  - Pattern rules are guardrails: shell spellings such as `git -C . push` still get past them.
- **Publication:** pushed to `cloud/p1-05a-permission-correction` only. The Leader fast-forwards `main-ahb0v0` after review; `main` stays the owner's.
- **Next action:** Leader: review c3a53e4 plus this event; decide on the base-list move and the AGENTS.md line; fast-forward `main-ahb0v0`. Owner: run the desktop re-test of the smoke checklist (roadmap 5a). Completion evidence: a Leader `review`/`approval` event and the re-test results.
