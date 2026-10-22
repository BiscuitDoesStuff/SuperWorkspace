# Changelog

## 0.4.0-dev - follow-ups (2026-10-16, unreleased)

- **Windows PowerShell 5.1 and PowerShell 7 (breaking).** The kit runs on the
  Windows PowerShell 5.1 built into Windows, with nothing else to install, and
  still on PowerShell 7; CI runs the suite under both. Every command the kit
  writes or prints is `powershell -NoProfile -ExecutionPolicy Bypass -File
  .sw/sw.ps1 <command>` (`t3.json`, skills, `AGENTS.md`, onboarding, the pull
  request template, `sw-validate`); `validate` accepts `t3.json` scripts for
  either shell. The kit writes JSON with its own serializer in PowerShell 7's
  layout, so generated files and every hash, including the shipped global
  rules hashes, are byte-identical on both shells. Reading JSON is now the
  same on both shells, which changes what is accepted: keys that differ only
  in letter case are refused with a message naming the file (a project
  `.claude/settings.json` with both `HTTP_PROXY` and `http_proxy` under `env`
  no longer validates), and empty `""` keys are refused. Two differences
  remain for values the kit never writes: an integer beyond Int64 becomes a
  double on 5.1 and throws on write under PowerShell 7, and a date-time
  string stays a string on 5.1 but becomes a DateTime under PowerShell 7,
  where writing it back throws "unsupported value type System.DateTime".
  The `~/.sw/global.json` record is checked as strict RFC 8259 JSON before
  it is read, so single-quoted or unquoted keys, comments and trailing commas
  can no longer hide a duplicate entry.
- **Windows-only (breaking).** The kit supports Windows only. The Linux and
  macOS code paths, the case-sensitive home comparison, their tests and the
  ubuntu CI jobs are removed; `sw-validate` runs on `windows-latest`.
- **Global setup per provider home.** `global install|check|backup` take
  `-ClaudeConfigDir` and `-CodexHome` (several directories each), falling back
  to `CLAUDE_CONFIG_DIR` / `CODEX_HOME`, then `~/.claude` / `~/.codex`, so
  T3 Code provider instances with their own homes get the global rules.
  Homes must be absolute; only a single string is read as a path list, and an
  ambiguous one is refused. A named home must exist, or `install` and `backup`
  write nothing; backups cover every targeted home; `check` and `backup`
  report each home. `doctor -CodexHome` checks Codex trust there.
- **Global rules baselines (breaking).** `global install` records each
  delivered block's hash in `~/.sw/global.json` and never overwrites a block
  that was edited locally or cannot be shown unedited (no baseline and no
  match with a shipped version); there is no override. Kept blocks are
  reported with resolution steps and an incoming copy, other homes proceed,
  and the run exits 1 (`PARTIAL`). Broken markers, a directory at the block
  file or an invalid record stop the run before any write. `-ReplaceUnmanaged`
  is removed. `install` no longer rewrites Claude `settings.json` (gh allow
  narrowing) or `~/AGENTS.md` (`@RTK.md` include); `check` reports both with
  the suggested change, and reports each block as OK, missing, outdated,
  edited or unverified. This closes the edited-block gap of the previous entry.
  Each block is compared and written through one exclusive handle.
- **RTK install is opt-in.** `global install` installs RTK only with
  `-InstallRtk`; by default it prints how to install it.
- **Single-provider review.** Codex review stays the default. A project whose
  owner uses one provider states so in `AGENTS.md` and reviews with a
  fresh-context reviewer on that provider, labelled "single-provider review".
  A Codex quota, rate-limit or permission failure still stops for the owner.
- **Status without a remote.** The `status` skill checks `git remote` before
  reading a remote `main` and reports a remote-free project as local-only.
- **Installed templates hold rules only.** Development-checkout names and
  live-check provenance moved out of `.sw/workspace.md` and
  `.sw/collaboration.md`; the evidence stays in the design register.
- **Host publication guidance preserved (pull request #1).** Under host Git
  policy, the generated `.sw/collaboration.md` keeps host-owned commit and
  publication guidance instead of the workspace flow.
- **Docs.** OpenCode setup removed from the setup and development guides;
  `t3.json` scripts are documented as imported project actions, checked
  against T3 Code's published schema; research topic 14 (sharing skills, MCP
  and plugins across Claude Code and Codex) added as a recommendation, not
  approved work.

## 0.4.0-dev - T3-native rebuild (2026-10-15, unreleased)

Development version, not a release. Implements owner decisions D7-D9 in
[the design register](docs/workspace-outline.md). Acceptance M7 passed: live
checks inside T3 Code with Claude Code and Codex in a scratch project, a
read-only multi-agent workflow, seven review rounds (six Codex, one Claude by
owner choice) and hosted CI on
both operating systems ([state](docs/workspace-state.md)).

- **Claude and Codex through T3 Code; OpenCode dropped (D7).** The OpenCode
  surface (`opencode.jsonc`, `.opencode/`, the RTK plugin twins) and the
  four agent roles are removed. The main T3 thread coordinates; core rules
  live in `AGENTS.md` and procedures in workflow skills (`work`, `resume`,
  `handoff`, `review`, `validate`, `status`, `research` plus method skills).
  `project-planning`, `focused-review`, `task-handoff` and `free-models` are
  merged or removed. The multi-project manager leaves the product.
- **Claude and Codex files are tracked generated files.** `.claude/CLAUDE.md`,
  `.claude/settings.json` and `.claude/skills/` replace the opt-in
  `sw claude enable` adapter; Codex gets `.codex/rules/workspace.rules`.
  Commands `tiers`, `claude`, `session` and `manager` are removed. Models are
  chosen per thread in T3; an optional git-ignored `.sw/models.local.md` holds
  a personal tier table.
- **Hands-off Git through T3 Code (D9).** Shell-pattern Git deny lists are
  replaced by hard limits only: no force-push, no push to `main`, no
  `gh release` writes, no repository-setting changes, no rewriting `main`
  history. Agents commit as they go; small, docs-only or solo work commits on
  `main`, code and public product changes go through a `t3/<name>` worktree
  thread and a pull request, Codex review precedes auto-merge. GitHub tier 2
  adds pushing the thread's own `t3/*` branch and `gh pr merge --auto`.
- **Governance docs rewritten.** `.sw/workspace.md` keeps only what scripts
  cannot check: T3 threads, the Git flow, records in the main checkout,
  opt-ins (pull request watching on when a pull request exists; scheduled
  read-only Codex audit, Codex cloud PR review and other automations off).
  `.sw/collaboration.md` describes the D9 routing, pull request targets
  (the owner's private instance, a separate remote configured locally, or `origin` for product changes) and
  branch-protection trade-offs; onboarding, README, contributing and security
  docs follow.
- **M7 fix package (owner decisions, 2026-10-15).** Agents enable auto-merge
  only after Codex review and passing CI on the current pull request
  revision, since CI is not a required check. Hard limits add
  `git pull --rebase` and any `git reset` that moves the branch (unstaging
  stays open) and a push to `main` inside `$(...)`, backticks or quotes;
  `validate` checks per-harness static decision cases (denied, allowed and
  documented gaps), and `.sw/workspace.md` lists the known gaps. Workflow
  skills carry Codex `agents/openai.yaml` (explicit-only). Core and global
  rules cap ordinary repair at three attempts and stop at once on quota,
  rate-limit or permission failures. `usage` says it reports Workspace
  estimates, not provider telemetry. `validate -CheckLinks` also checks local
  links in `docs/`. Fresh installs stay at GitHub tier 0.
- **M7 review round 3 fixes.** Claude reads a commit-like reset name only as
  the first argument, so a path after `--` stays open for unstaging; a quiet
  reset with an argument is refused. Both harnesses cover `git.exe` and
  `gh.exe` and the common push flag clusters (`-uf`, `-vf`, ...).
  `.sw/workspace.md` lists the known gaps and over-blocks with their harness
  and examples, and a new `Gap` case kind lets `validate` re-check the gap
  cases (not yet one for every row). `-CheckLinks`
  reads link titles, angle-bracket destinations and reference definitions,
  skips code, and refuses drive-letter and other rooted targets.
- **M7 review round 4 fixes.** Every command in the gap and over-block
  tables is now a static case, which `validate` re-checks; the kit's tests
  tie each to its row's Harness column, and examples that cannot be a rule
  decision are marked *not a rule case*. A `PowerShellOnly` case kind covers
  forms only the case-insensitive PowerShell rules deny. Both harnesses also
  block the common `checkout -B`, `switch -C` and `branch -f` spellings that
  rewrite `main`, the `pull -vr`/`-qr` clusters and a reset with `-N` or
  `--end-of-options` before a commit. The tables add the remaining spellings,
  matching and glob refspecs, unnamed reset targets and repository writes,
  and the over-blocks of read-only `gh ruleset`/`secret`/`variable`, `--help`
  on a blocked verb, rebase recovery and PowerShell case folding. No Claude
  pattern may hold a doubled space (a live test showed one also denied
  `git diff --stat`). `-CheckLinks` refuses a colon in a local target and a
  letter-case mismatch with the disk, and ends a link after an escaped
  backslash.
- **M7 review round 5 fixes.** Claude's `main`-rewrite patterns match each
  flag only where it starts a word, so a thread branch such as `t3/webmain`,
  `t3/Bmain` or `t3/plan-b` is no longer refused. `-CheckLinks` checks the
  letter case of a link that names the project root.
- **M7 review round 6 fixes.** Claude's `main`-rewrite flags also match after
  a tab (`git branch -q<TAB>-f main`), which round 5 had left open, and Codex
  forbids `-Bmain`, `-Cmain` and `--force-create=main` after `-f`, `-q` or
  `--discard-changes`. `checkout -qBmain` and `switch -qCmain` are listed
  gaps. The kit tests pass in a fresh checkout: the generated-copies test
  skips a git-ignored rendered file that is absent (`.sw/comms/README.md`)
  but still checks its manifest hash, and the LFS validation test removes
  `.gitattributes` with `-Force`, which Linux PowerShell needs for a
  dotfile.
- **No Supervised mode (owner decision 15, 2026-10-16).** The owner accepted
  the documented gaps and over-blocks as the 0.4.0-dev baseline. The kit
  recommends new-thread permissions Auto or Full access, not Supervised, in
  `.sw/workspace.md`, onboarding, setup, the README and the `doctor`
  reminder; the hard-limit rules apply in both, and Auto's model refusals
  are not counted as enforcement.
- `VERSION` is `0.4.0-dev`.

## 0.3.0-dev - T3 Code adoption (2026-10-15, superseded by 0.4.0-dev)

- T3 Code is the required app (owner decision D6). The `sw session start`
  launcher (`Invoke-SwSession`) and its session-event writer are removed; use
  T3 Code threads running OpenCode or Claude Code (OpenCode was dropped in
  0.4.0-dev).
- Workspace Git policy now allows `main` plus T3 Code worktree-thread branches
  (`t3/<name>`) instead of `<user>/<user>-worktree`; `doctor` accepts either,
  checks for the `t3` CLI (warning only) and the local Claude adapter, and
  reminds about T3 Code permission/branch-prefix settings. Host policy unchanged.
- Rules, onboarding and setup document T3 Code project settings; offline
  launcher tests are replaced by validate-based role-policy checks.

## 0.3.0-dev - public adoption candidate (2026-10-11, superseded)

- Follow-up: correct task-closure examples to use explicit `-Task` / `-Outcome`;
  recognize explicit research snapshots and `Sources F<n>` citations without
  suppressing genuine date/section/uncited-finding warnings. Add lint and
  installed-CLI regressions; VERSION remains 0.3.0-dev, not a release.
- MIT license and preserved third-party notices, distributed with installed kits.
- Public README, new/existing/join setup routes, bootstrap/update/recovery guide,
  contribution/security guidance and sanitized bug diagnostics.
- New installs default to host-owned Git policy and local-only records. Explicit
  `-GitPolicy host|workspace` and `-Records local|tracked` choices; updates and
  re-init keep existing choices, absent legacy fields retain the old behavior.
  No automatic config merge, Git untracking or history migration.
- Installer preflight now checks conflicts/downgrades before directory/Git
  effects; initial adoption refuses unsupported config variants and nested
  repository targets. `-Adopt` remains explicit backup-and-replace.
- Exclusive event allocation distinguishes file collisions from directory/I/O
  failures; context reporting distinguishes unsafe linked role definitions
  from missing files. Portable regression fixtures correct newline, hidden-file,
  denial scope, executable-hook and Unix directory-link assumptions.
- Offline whole-tree/preservation fixtures added. This is an unreleased
  candidate, published at `525b5bb` with MIT detected and the private-reporting
  entry verified (2026-10-12). Hosted CI at that SHA failed one context fixture
  on each OS and skipped fresh-install/offline steps. Publication is not release
  or runtime assurance.
- CI follow-up pins/imports the locally tested Pester 5.6.1 instead of allowing
  an unvalidated newer major, and logs the selected version. Hosted success
  requires a new human publication and verification of both OS jobs/all steps.
- At published `2d49b10`, both OSes pass Pester (334/0/0) and fresh installation;
  the offline session fixture fails because it expects a local-only generated
  comms doc. Follow-up reads that doc from its tracked kit source, without
  copying private records or weakening assertions. Hosted rerun remains required.
- Owner explicitly waived independent review (not performed) and chose to keep
  this development-only on 2026-10-12; no version change, tag or release.
- **Verified development delivery (2026-10-12):** published `ddd2c65` passes both
  hosted OS jobs: Pester 334/0/0, fresh-install validation, offline session 307
  assertions and manager 89 assertions, plus `sw-validate`. The dated failures
  above are superseded for that implementation SHA, not erased or retroactively
  made green. Broader live/platform/security assurance remains unverified.

## 0.3.0-dev

**Publication correction (observed 2026-10-11):** the local/unpublished labels
below record earlier checkpoints, not current publication. The audited public
`main` at `bd5dc48` includes these features; that exact hosted CI run failed
Pester on Windows/Linux and skipped the later fresh-install/offline steps.
It is not a release tag or a green adoption baseline. The former `product/`
layout and superseded roster/permission descriptions below are historical.

- **Unreleased (2026-10-03..05, local, uncommitted, unpublished):**
  - Identity: this checkout is the development checkout of the public SuperWorkspace product (`origin`); the owner's private
    instance is a separate remote, configured locally.
  - WS manager (`lib/Sw.Manager.psm1`, `project/manager/`, `sw manager ...`): offline project registry, status, requests and
    manual handoffs for a parent directory of independent projects; live planning calls stay unverified and need separate approval.
    In a manager instance `validate` runs `Test-SwManager`, which checks installed files against the manifest and, offline, against kit sources
    (drift check; skipped with a warning when kit sources are absent).
  - `opencode.jsonc` `watcher.ignore` merges the profile's `watcherIgnore` with an optional project `.sw/config.json` `watcherIgnore`;
    every profile now ignores `.scratch/**`.
  - Profile selection v1 (`project/selection.json`, `project/capabilities/`): roles and skills are selected per project; the `research`
    profile and `provider-setup` capability were added, and this Workspace migrated to research + provider-setup.
  - Task records: `.sw/comms/` is gitignored and local-only in this checkout; previously published records remain in public history.
  - `.sw/config.json` `"records": "local"` (opt-in; default `tracked`) adds `.sw/comms/` to the managed `.gitignore` block and
    renders `.sw/collaboration.md` with local-only wording; other values are rejected.

- **Fixed (workspace-v1 review repairs, local, unpublished):**
  - A selected role's effective permission list (its file plus shared and local overlays) is checked by the same narrow check `validate` runs, before any
    discovery, event or process; an omitted, empty, malformed, stale or overridden policy is rejected.
  - `claude enable` records a versioned per-file byte-hash inventory in `.claude/.sw-generated`; `claude disable` removes only verified-owned files
    without needing the replacement map, keeps edited files and reports PARTIAL; legacy marker-only installs are removed only where exactly reproducible;
    enable backs up any differing unverified target before replacing it. Marker text alone never authorizes deletion.
  - Session events and `comms send`/`event` use one exclusive-create allocator; a recording failure after the native exit reports the observed exit
    instead of losing it, and the native process is never retried.
  - `init`/`update` validate every managed block (and refuse to drop managed LFS rules on an Unreal-to-generic change) before writing anything.
    Recovery snapshots (global, adoption, incoming copies, adapter) are unique per operation and never overwrite; an explicit existing backup
    destination is rejected; a failed copy stops the replacement it protects. Every broad `gh` Claude allow is narrowed.
  - `doctor` no longer reports a tool that cannot report a version as present (no fabricated 0.0.0): a required OpenCode failure is `FAILED`, optional
    gh/rtk problems warn, and `main` is accepted only in a solo project (with contributors, the recorded user's own worktree branch is required).
    Diagnostics reach installed tools through two replaceable functions so tests never run real tools, auth or installers.
  - Guidance: onboarding enters the checkout after cloning; static checks are described as portability checks, not credential proof; ownership,
    backup and profile-transition notes added; outline publication facts updated; Claude Leader summary follows each command's availability.
  - `ForEach-Object Rule` in adapter generation returned nothing under `-WhatIf`; replaced with a script-block form.

- **Changed (publication integration):** preserve published SuperWorkspace and
  local Workspace histories while making the root kit the only active source.
  Retire duplicate `product/` and obsolete role definitions; retain historical
  docs/task archives without granting their proposals implementation authority.
  CI and inherited Pester fixtures now use root paths and current contracts;
  kit provenance recognizes a root clone and remains null for nested copies.
  Publication, hosted CI and broader runtime assurance remain separate checks.

- **Added (workspace-v1):** `sw session start <role> <task-id>` routes
  explicit local role models to native Claude Code or OpenCode. Leader sessions
  require `-Model`; conflicting worker overrides, absent config/roles and stale
  Claude adapters fail closed. OpenCode uses `mini` (interactive) or `run`
  (`-Headless`); no headless Claude. Dry-run writes nothing. Immutable task events
  record requested models and unknown native identity/effects, not artifact
  acceptance. Offline native-stub tests added; independent review ran on an
  owner-selected free route, with a conservative runtime read-denial discrepancy
  recorded and owner-accepted. Bounded headless OpenCode engineering artifact,
  checkpoint/fresh-session tests and read-only acceptance passed under workspace-v1;
  Claude/interactive/mixed routes and broader enforcement remain unverified.
  No shared config/account activation implied.
- **Fixed (Claude adapter, workspace-v1 P1):** worker models come from actual
  local `agents[role].model`, not a hardcoded model. Mixed/unmapped workers get
  STOP commands; reviewer has no Bash/write/Agent tools. Git guardrails share
  canonical verb/wrapper lists; canonical import is `@../AGENTS.md`, relative to
  `.claude/CLAUDE.md`. The older `@AGENTS.md` draft and model-hardpin descriptions
  below remain historical, not current behavior. Leader startup is role-scoped,
  without an unconditional worker-session hook. Live enforcement remains unproven.

- **Changed (permissions):** git and `gh` shell rules are hardened against prefix bypasses.
  - Each git deny or ask verb (push, reset --hard, clean, stash; commit) also matches:
    - the global-flag form `git -* V *`;
    - compound and runner forms `* git V *` and `* git -* V *` (`x && git push`, `rtk proxy git push`).
  - `* gh *` deny, plus `gh *&*`, `gh *;*` and `gh *|*` denies after the gh read allows.
  - Wrapper asks: `bash|sh *-c *git*`, `pwsh|powershell *git*`, `cmd */c *git*`, `*rtk run *git*`, and the pwsh/powershell encoded-command flags.
  - `project-review` denies the compound and redirect operators (`& ; | > < $( `` ` ``) after its read allowlist.
  - Rules starting with `*` or `rtk ` get no `rtk ` twin.
  - New static matrix cases cover each form.
  - Known false positives: text containing ` git push ` (for example a commit message) is denied, any `pwsh` call that mentions git asks, and `project-review` cannot pipe.
  - Limits: wrappers behind a compound, `$(...)` and backticks in writer roles, and scripts written to a file are not caught; a shell rule stops the call, not its effect. Re-run `sw update`.
- **Changed (model routing, breaking):** tiers are model-only. The Claude adapter no longer emits `effort:` (agents keep `model: opus`) and `validate` no longer checks it; `validate` now rejects `effort`, `reasoningEffort`, `reasoning_effort`, `variant` and `#variant` in agent and command files, `opencode.jsonc` and the local tier map `.opencode/opencode.jsonc`. `.sw/workspace.md` Model tiers gains three rules: pass `-m <tier model>` on `opencode run --agent` (OpenCode 2.0.20 `run` ignores agent models), parents do not pass `model` to the `subagent` tool, and a shell deny needs matching `write`/`edit` rules for file effects. `sw tiers` rejects a `#variant` suffix and the `free-models` skill no longer maps effort levels to tiers. Re-run `sw update`; `sw claude enable` regenerates the Claude agents.
- **Changed (roster, breaking):** reduced to `project-leader`, `explore`, `project-review`, `project-research` and `project-developer` as the single executor.
  Removed `project-plan`, `project-architect`, `project-build`, `project-documentation` and `project-worker`; the Leader plans inline with `project-planning`, and `project-developer` also covers coordinated validation, Markdown docs and task records, and parallel work in an assigned worktree. `/validate` routes to `project-developer`. The removed worker's Git denies are kept as `ask` rules on `project-developer` (switch, checkout, merge, rebase, cherry-pick, branch, worktree), with a matching contract check.
- **Fixed (docs):** `.sw/collaboration.md` said `sw user add <name>`; the command is `sw user <name>`.
- **Changed (routing):** executors do not run at high unless the Leader suggests it and the user approves, or the user runs the work themselves.
- **Changed (model routing, Phase 1 package 8, breaking):** tiers renamed
  `reasoning/standard/fast` -> `high/standard/light` everywhere, no aliases
  or old names. Default role tiers: `project-plan`, `project-architect`,
  `project-research`, `project-review` = standard; `project-developer`,
  `project-worker`, `project-build`, `project-documentation`, `explore` =
  light; `project-leader` stays session. `sw tiers` flags are renamed to
  `-Light -Standard -High`; re-run it with the new flags (an existing
  `.opencode/opencode.jsonc` tier map keeps working, since it maps roles to
  models directly). The Claude adapter now gives every generated agent
  `model: opus` plus `effort: low|medium|xhigh` (light/standard/high)
  instead of picking a model per tier; `validate` checks both lines.
  `.sw/workspace.md` gains a Planning/Execution routing section and rubric
  (no model IDs); `free-models`' tier-mapping names are renamed to match.
- **Changed (skills, Phase 1 package 6):** canonical skills moved from `.opencode/skills` to `.agents/skills` (base and the `unreal` profile), because OpenCode, Codex, Gemini, Cursor and Copilot all read `.agents/skills`, while `.opencode/skills` is OpenCode-only.
  - The rename map (`$script:Moved`, `Sw.Kit.psm1`) gained prefix support: one `.opencode/skills/` -> `.agents/skills/` rule, expanded per file against the project's manifest. `update` moves an edited kit skill to `.agents/skills/<name>` with its edit, the same as any other renamed file.
  - A user's own skill under `.opencode/skills/<name>` (not a kit skill name) is left alone; OpenCode still reads it there, but `claude enable` and `validate` now read only `.agents/skills`. Move your own skills to `.agents/skills/<name>` and delete their stale `.claude/skills/<name>` copies.
  - `validate` now reads skills from `.agents/skills`, and reports a new error when a kit skill name still exists under `.opencode/skills/<name>`, since it shadows the kit's `.agents/skills` copy in OpenCode.
  - The generated `.claude/skills` copy is now built from `.agents/skills`. Claude users: re-run `sw claude enable` if `update` does not regenerate your `.claude/` (no `.claude/.sw-generated` marker).
- **Changed (OpenCode permissions, Phase 1 package 5a):** OpenCode desktop 2.0.17/2.0.18 ignores the project-level `permissions` list in `opencode.jsonc` and applies only agent frontmatter.
  - `update` writes the session rules (shell allow, `external_directory` ask, skill allow, subagent deny, commit ask, push/reset/clean/stash/`gh` deny, the profile's edit denies, the GitHub tier allows, then the `.env` read asks) at the head of every `.opencode/agents/*.md` `permissions` list, and of `agents.build`. The role's own rules follow and still win. `opencode.jsonc` keeps the same list. The rules now live in `Get-SwSessionRules`; `opencode.base.json` no longer holds a `permissions` list.
  - A `githubTier` change needs `update`, which now rewrites the agents too. A locally edited agent follows the usual `skip-modified` / `incoming/` path.
  - `validate` models each role from its agent file only (`build` from `agents.build`), and reports `Session rule drift: .opencode/agents/<role>.md ...; run sw update` when an agent's leading rules differ from the session rules for the project's config.
  - Read-only roles (`project-plan`, `project-architect`, `project-review`) may run `git status *`, `git diff *`, `git log *` and `git show *`, plus `git log --oneline` and `git log --oneline -??`. `--output`, `--ext-diff` and `--textconv` stay denied; `validate` checks both.
  - `.sw/workspace.md`: the harness table states OpenCode enforcement through agent frontmatter, OpenCode `.env` prompts as unverified, and Claude `.env` prompts as a guardrail (Read tool only). Built-in OpenCode agents other than Build carry no kit rules. `.sw/workspace.md` and `.sw/collaboration.md` no longer call branch protection the real push control: the solo ruleset stops force pushes and deletion, not ordinary pushes.
- **Fixed (OpenCode permissions, Phase 1 package 5a): RTK bypass.** OpenCode 2.0.18 runs plugin shell hooks before its permission check, so the RTK plugin's rewrite (`git push ...` to `rtk git push ...`) slipped past the push, commit, stash and `gh` rules. `update` now renders an `rtk ` twin, with the same effect, directly after every shell rule except `*`: in every `.opencode/agents/*.md` list (session and role rules), `opencode.jsonc` `permissions` and `agents.build`. `validate` checks every shell case for its `rtk` form too, compares agents against the twinned session rules, and reports `RTK twin missing: ...; run sw update` for a shell rule without its twin. `.sw/workspace.md` records the rewrite order, and OpenCode `.env` prompts read "enforced (ask)".
- **Changed (update, Phase 1 package 5): lifecycle.**
  - `.sw/manifest.json` gains `kitCommit`, the kit clone's `git rev-parse HEAD` (`null` outside a git clone, or when the kit was copied into another repository).
  - `update` and `init` refuse to run when the manifest's `kitVersion` is newer than the running kit (a `-dev` build is older than its release), and write nothing. Update the kit clone, or pass `-Force` to downgrade on purpose. `update` also accepts `-Adopt`.
  - The plan starts with `kit A -> B`.
  - A locally edited file the kit did not change is reported `kept-local`, with no merge hint.
  - A locally edited file the kit did change stays `skip-modified`. The kit's new version is written to `.sw/backup/<stamp>/incoming/<path>` (git-ignored; credential-like names are never copied), and one `git diff --no-index <path> <incoming>` line is printed per file.
  - `orphan-kept` files are listed as dropped from the kit and left in place.
  - An `AGENTS.md` without a `## Project identity` heading gets the template's project sections inserted above the kit blocks, and the plan says "fill Project identity". Existing text is untouched. This fixes package 4's new `validate` error.
  - A kit-side rename map (empty today) moves files the kit renames. An edited old file moves with its edit and is reported like any edited file.
- **Changed (validate, Phase 1 package 4): three new errors.** Fix these before or right after `update`:
  - `AGENTS.md` must keep a `## Project identity` heading. A project that adopted an existing `AGENTS.md` may lack it; add the heading above the kit blocks.
  - Every skill `name` must be 1-64 lowercase letters, digits and single inner hyphens, and its `description` at most 1024 characters (Agent Skills spec). Rename or shorten your own skills that break this.
  - When `.claude/.sw-generated` exists, `.claude/` must match `.sw/roles.json`: one agent per role except `project-leader` and `explore`, with the tier's `model`, the role's `claudeTools` as `tools`, and `disallowedTools: Agent`, plus one command per `.opencode/commands/*.md`. Run `claude enable` to fix.
- **New (validate):** a research lint for `docs/research/*.md` (sections 1-6, a dated header, a citation per `F<n>.` finding). It prints `WARNING:` lines and never changes the exit code.
- **Changed (validate):** the budget line reads `~N tokens (bytes/4 estimate; tokenizer varies)`, and `project-leader`'s count adds the other agents' `description` bytes (the subagent catalogue it sees). `.sw/workspace.md` describes the same.
- **Changed (doctor):** two notes: the startup budget counts kit files only (check `/context` in Claude for the real total), and branch protection on `main` is not checked (see `.sw/collaboration.md`, Protect main).
- **Changed (comms):** an event's "changed" line drops `.sw/comms/` entries and lists at most 10 paths, then `(+N more)`.
- **Changed (Claude adapter, Phase 1 package 3):** generated `.claude/agents/*.md` set `disallowedTools: Agent`, so only the main session spawns agents. `.claude/settings.json` asks before `Read(**/.env)` and `Read(**/.env.*)` (`.env.example` prompts too) and denies `gh alias`. The `.claude/project-leader.md` dispatch sentence is built from the commands marked `subagent: true`. Run `update` (or `claude enable`) to regenerate.
- **Changed (behaviour):** OpenCode `external_directory` now defaults to `ask` instead of `allow`, so access outside the project folder prompts. `update` rewrites the base rule in `opencode.jsonc`.
- **Changed:** `validate` no longer pins each command's `subagent` value; command frontmatter owns the flag. The routing check stays.
- **Fixed:** `.claude/project-leader.md` is generated with LF line endings, so `validate` no longer reports false Claude drift when the kit module is checked out with CRLF.
- Fixed: `free-models` no longer lists models or prices; GLM 5.2 was listed as free and is not.
- **Docs (research topics 5-10, Phase 1 package 1):**
  - `.sw/collaboration.md`:
    - a solo mode: with `users` empty, the owner works on `main`;
    - agent-made branches stay off;
    - claims, `<user>-` task IDs, and closing only after the last event is on `main`;
    - an optional multi-session paragraph;
    - "Protect main (human, once)" steps;
    - who runs `update`;
    - harness memory is not a record.
  - `.sw/workspace.md`:
    - rules are labelled enforced, guardrail or stated, with a per-harness table (the Claude adapter was overstated);
    - sandboxes are documented;
    - trusted MCP servers;
    - the Claude worktree note;
    - `update` already regenerates `.claude/`, and Claude reloads only after `/clear`, `/compact` or a restart.
  - Also: the `AGENTS.md` Git rule names solo projects, `project-leader` defaults to working in-session, and there are small additions to the `task-handoff`, `agent-documentation`, `research` (raw page text, research-call budget) and `free-models` (`#variant`) skills.
- **New:** core `project-research` role (reasoning tier, Markdown-only), the `research` skill and the `/research` command. It records cited primary-source findings in `docs/research/NN-topic.md`. Adapted from mattpocock/skills `research` and the Anthropic claude-cookbooks research subagent prompt (both MIT).
- **Changed:** the `research` skill writes its plan into the file first, caps tool calls at 20, labels secondary sources, treats fetched pages as data and rechecks each finding against its source; `/research` confirms scope and budget first. The Leader may propose up to 3 researchers for a broad topic, with user approval.
- **Moved:** the kit now lives in `product/` inside the SuperWorkspace repository. Run `product/sw.ps1` instead of `sw.ps1` from a kit checkout. Installed projects are unaffected.
- **Changed:** the global rules block is tier-neutral; it names no models or third-party tools. `global install` rewrites that block, so keep personal routing lines outside it.

## 0.2.0 - 2026-09-26

- **Fix:** handle dotfiles on Linux and macOS (`-Force` on file operations). CI no longer stops at the first failing OS.
- **Fix (security and data loss):**
  - comms names reject path traversal;
  - `comms close` archives the whole task folder;
  - `claude enable` and `claude disable` keep your own `.claude/` files;
  - both broad `gh` allows are removed, and more `gh` write verbs are denied;
  - global backups skip `opencode.json`.
- **Fix:** `remote` works on Linux and macOS, and `global` returns its exit code.
- **New:** `sw doctor [-User]`, a read-only setup check that prints the fix for each problem, and `.sw/onboarding.md` for new contributors.

## 0.1.0 - 2026-09-26

First version. It replaces an earlier foundation repository and a predecessor game
project's workspace layer, which were harvested once and then retired.

- **CLI:** `sw.ps1` on PowerShell 7, with project and kit modules.
- **Project layer:**
  - 8 roles: the game workspace's roles, made generic.
  - 8 commands, including the new `/handoff` and `/inbox`.
  - 7 base skills, plus `unreal-validation` in the Unreal profile.
  - A generated `opencode.jsonc` covering the profile's binary-edit denies, the GitHub tier and the build delegation allowlist.
  - Install and update driven by a manifest, with `-Adopt` for existing repos.
- **Validator:** ported from the game workspace's `Validate-AgentWorkspace.ps1`. It is now driven by the profile and roles, and adds GitHub tier checks and Claude drift detection.
- **Claude adapter:** generated instead of kept in sync by hand. Skills are copied, not linked through absolute junctions.
- **Comms:** task events, inboxes, and a close/archive step with `SUMMARY.md`.
- **GitHub:** issue forms, a PR template, labels, and a validate workflow. Tier 0 and tier 1 rules are enforced in OpenCode and in Claude.
- **Global:** managed rule blocks for OpenCode and Claude, read-only `gh` allows, and backups that never copy credential files.
- **Remote:** `tailscale serve` setup and check, with a `-KeepLan` option.
- **Usage:** a report combining RTK gain, OpenCode stats and the startup budget.
