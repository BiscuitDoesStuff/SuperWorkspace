# Agent workspace

Installed and updated by the SuperWorkspace kit;
files listed in `.sw/manifest.json` are kit-managed (edit them upstream, or
accept that `sw update` will skip your modified copy). T3 Code is the app: its
threads run Claude (Claude Code) or Codex with their native project
configuration. This file holds only what scripts cannot check; whatever
`sw validate` checks lives in the scripts, not here. In these docs
`sw <command>` means
`powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 <command>`
(Windows PowerShell 5.1; `pwsh` works the same way; kit-only commands such as
`update` run from the SuperWorkspace clone).

## Canonical sources

Each rule has one owning source; everything else links to it.

| Source | Owns |
| --- | --- |
| `AGENTS.md` | Project identity, invariants and the core rules every agent loads (authority, Git hard limits, safety, records, validation, code review rules) |
| Project state file named in `AGENTS.md` | Implemented state and what work is authorized |
| `.agents/skills/` (generated into `.claude/skills/`) | Workflow procedures: `work`, `resume`, `handoff`, `review`, `validate`, `status`, `research` and the method skills; the workflow ones are explicit-only (`disable-model-invocation` for Claude, `agents/openai.yaml` for Codex) |
| This file | T3 Code threads, the Git flow, records in the main checkout, opt-ins, verification |
| `.sw/collaboration.md` | Task records, messages, branches, pull request targets, integration |
| `.sw/config.json` | Profile, GitHub tier, contributors, startup budget, Git policy and record privacy |
| `.claude/settings.json`, `.codex/rules/workspace.rules` | The Git and GitHub hard limits, per provider |
| Git and `.sw/comms/tasks/` | Ancestry, publication, and approved work; not a second memory ledger |
| `.sw/onboarding.md` | New contributor setup |

No dedicated agents are defined: the main T3 thread coordinates, skills hold
the procedures, and deterministic checks are scripts (`sw validate`, `sw comms`,
`sw context`, `sw doctor`).

## T3 Code threads

T3 Code is the required app for working in a project. It runs Claude and Codex
on the host machine with their own logins and native project configuration:
Claude loads `.claude/CLAUDE.md` (which imports `AGENTS.md`), `.claude/skills`
and `.claude/settings.json`; Codex loads `AGENTS.md`, `.agents/skills` and,
once the owner trusts the project in Codex, `.codex/rules`. T3 Code is
early-stage software: record unexpected behavior in the task record; never
work around a rule.

- One thread is one session. Start or resume with the `work` or `resume`
  skill against an existing task record; a thread, its title or
  a schedule never authorizes work. Reconcile actual artifacts and unknown
  effects before work and after reopening a thread.
- **The main thread coordinates.** It plans, records, dispatches and
  integrates. It does small work inline and splits work only for isolation or
  independence: read-heavy exploration goes to native subagents, independent
  or long implementation packages go to T3 worktree threads (own checkout and
  branch, visible and stoppable).
- **Briefs.** Every worktree thread or delegated task gets the task ID,
  approval, exact scope and owned files, dependencies, acceptance, checks,
  whether it may commit, and the report it returns. A report names its branch
  and commit SHAs, changed paths, exact commands and results, and open issues.
  Writers in one checkout are serialized unless their file ownership is
  explicitly disjoint.
- **Delegation.** `delegate_task` creates child threads; children and
  worktree threads do not delegate further, except a review routed to Codex
  under the `review` skill.
- **Models** are chosen per thread in T3; no model is pinned in tracked files.
  An optional, git-ignored `.sw/models.local.md` may hold your own tier table
  (a mid model for normal work, the top model for architecture and hard
  debugging, a small model for exploration). Switching provider or model
  inside a thread is a handoff: treat it as a new session and reconcile the
  task record.
- **Quota.** On provider quota or rate-limit errors (429, session or weekly
  limits), stop starting or resuming threads, write the current state to the
  task record and report. Do not retry into the limit.

### Records in the main checkout

Task records live in the main checkout only. `.sw/comms/` (with
`records: local`) and other ignored files such as `.sw/models.local.md` and
`.env` are absent in worktree threads, and T3 Code's worktree cleanup can
delete ignored files. A worktree thread therefore writes no records: it reports
in its final message, and the main thread writes the task events.

### Project settings (human, once)

- New-thread permissions **Auto** or **Full access** (T3 Code's initial
  default), not **Supervised**. The kit's hard-limit rules
  apply in both. The known gaps listed under [Git flow](#git-flow) are
  accepted and rely on the agent following the rules. In Auto, Claude's
  classifier and Codex's auto-review add model refusals that vary between
  runs and are not enforcement; Full access has no such layer.
- Worktree branch naming: static prefix `t3/`. Automatic pull on. Worktree
  cleanup merge-based, keeping worktrees with local changes.
- **Auto-resume limited threads** off (quota stops are not retried).
  **Continue threads after restarts** resumes interrupted turns automatically;
  reconcile unknown effects afterwards.
- Codex: the owner trusts the project so project rules load. Until then,
  Codex relies on its sandbox and the hard limits are not loaded.

## Git flow

Under workspace Git policy (`gitPolicy: workspace`), agents work hands-off
through T3 Code: T3's Restore checkpoints, per-turn diffs and worktree threads
are the safety net, and the hard limits are the only blocks. Under host policy
the host project's workflow replaces the routing below; the hard limits still
apply.

1. **Commit as you go** in small Conventional Commits, staging selected
   paths only.
2. **Route by change.** Small, docs-only or solo work commits directly on
   `main`. Code changes, and anything published to the public product remote,
   go through a `t3/<name>` worktree thread and a pull request
   (targets in `.sw/collaboration.md`).
3. **Push and pull request.** Either the owner uses the thread's Git actions,
   or, at GitHub tier 2, the agent pushes its own `t3/` branch and opens a
   draft pull request.
4. **Watch.** Whenever a pull request exists, the thread links it
   (`link_pull_request`) and watches it (`watch_pull_request`), then fixes CI
   failures and conflicts on its own branch. Unwatch when handing the work
   back to the owner.
5. **Review, ready, CI, then merge.** Draft pull requests run no CI. Codex
   review (the `review` skill; a single-provider review where the owner uses
   one provider) comes first; then the agent marks the pull request ready
   (`gh pr ready`), which starts CI. Once the relevant
   CI checks on the current pull request revision have passed, the agent may
   enable auto-merge (`gh pr merge --auto`, tier 2). Auto-merge waits only for checks the target
   branch requires, so it is no CI gate while CI is not required: before
   pushing again to a pull request with auto-merge on, disable it
   (`gh pr merge --disable-auto`) and re-enable it only after the gate passes
   on the new revision. **Fallback:** if hosted CI cannot run for a quota or
   billing reason (its jobs never start), the gate is the repository's full
   local test suite on every shell its CI covers, at the current pull request
   revision, plus `sw validate` and review, with the exact commands and
   results recorded in the pull request body and task record; then auto-merge
   may be enabled. The hosted jobs are not rerun or worked around: a quota
   stop is still a stop (`AGENTS.md` Safety).

**Hard limits** (every mode, every tier): no force-push (`--force`, `-f`,
`--force-with-lease`, `+refspec`), no push to `main`, no `gh release` writes,
no repository-setting changes (`gh repo edit|delete|rename|archive`,
`gh ruleset`, `gh secret`, `gh variable`), no rewriting `main` history, and
on every branch no `git commit --amend`, `git rebase`, `git pull --rebase`
or `git reset` that moves the branch (`--hard`, `--soft`, `--mixed`,
`--merge` or `--keep` with a commit, or `git reset <commit>`). Prefix rules
cannot see the current branch: make a new commit, merge `main` into a thread
branch instead of rebasing, and unstage with `git restore --staged`,
`git reset HEAD <path>`, `git reset -- <path>` or plain `git reset`. Claude
enforces them through `permissions.deny` in `.claude/settings.json`, Codex
through `forbidden` rules in `.codex/rules/workspace.rules`. Both match command
text: they stop the command as written, not every spelling. They are
guardrails, **not a sandbox**; never bypass a denied action with another
tool, shell form or child.

Known gaps and over-blocks come from static rule evaluation,
`codex execpolicy check` and source reading; the kit repository's design
register (`docs/workspace-outline.md`, O12) holds the live-check evidence.
Rule decisions are the same in every mode. In Full access, nothing asks
before a gap spelling runs. In Auto, Claude's classifier and Codex's
auto-review may refuse some gap spellings and some ordinary commands,
differently from run to run; they are not enforcement and nothing here relies
on them. On Windows, where Codex runs each command through PowerShell, its
rules do not check even a plain-word `bash -lc` script. Claude's patterns are
text globs, so they cannot see a `--` separator, and the Bash rules are
case-sensitive while the PowerShell rules are not; Codex's rules compare whole
leading words. Quoted and doubled-space spellings stay gaps because no pattern
targets them: a pattern with a doubled space after `git` can also deny
unrelated commands such as `git diff --stat`, and how Claude Code reads a
quote in a pattern is undocumented.

Every command in an Example column below is a static case in the kit
(`$script:HardLimitCases` in `Sw.Project.psm1`). `sw validate` re-checks its
decision against both rule sets, and the kit's test suite checks that its
decision matches the row's Harness column. Examples after *not a rule case*
cannot be expressed as a rule decision, and nothing checks them.

Gaps, forms that should be blocked but are not:

| Gap | Harness | Example |
| --- | --- | --- |
| Git aliases and configuration | Both | an alias (`git undo`); *not a rule case*: `pull.rebase=true` before a plain pull, a `+` refspec in `remote.origin.push` |
| Scripts, other programs and APIs | Both | `gh api -X PATCH repos/o/r -f visibility=public`; `gh repo sync --force`; *not a rule case*: `./publish.sh`, `curl` to the GitHub API |
| Commands built at run time | Both | `$g push --force`; *not a rule case*: `eval "$cmd"`, `Invoke-Expression $cmd` |
| Escapes or quotes inside a word | Both | `git pu""sh --force`; `git p\ush --force` (static model; whether Codex's shell parsing joins the word is not verified) |
| Line continuation | Both | `git push \` with `--force` on the next line (static model: each line is matched alone) |
| Abbreviated long options (Git accepts a unique prefix) | Both | `git reset --har`; `git commit --amen`; `git pull --reb`; `git push origin --mirr` |
| A reset target no rule names | Both | another branch or tag (`git reset v1.0`, `git reset topic`); a remote name (`git reset origin` resolves to `origin/HEAD`); a commit message search (`git reset ":/text"`); a commit after an unlisted option (`git reset --no-refresh origin/main`); Claude still catches `HEAD~`, `HEAD^`, `@~`, `@^` and `@{` anywhere, and both catch a listed commit after `-q`, `-N` or `--end-of-options` |
| A reset to a SHA or unlisted name | Codex | `git reset 1a2b3c4`; `git reset t3/other`; `git reset HEAD~7` |
| An uppercase reset target or program | Claude Bash, Codex | `git reset ABCD123`; `git reset BISECT_HEAD`; `Git push --force`; `GIT.EXE reset --hard` (the PowerShell rules ignore case and match; Windows resolves a cased program) |
| A flag cluster outside the lists | Both | `git push -uvf origin t3/x`; `git push -4f origin t3/x`; `git pull -vqr`; `git pull -4r` (both catch the listed clusters such as `-uf` and `-vr`; Claude also catches any push cluster starting with `f` and any pull cluster starting with `r`) |
| A redirection touching the last word | Both | `git push origin main>push.log` |
| An option between `gh <group>` and the verb | Both | `gh release -R o/r create v1` |
| A push to `main` that does not name it | Both | `git push origin :` (all matching branches); `git push origin 'refs/heads/*'` (a Claude pattern cannot match a literal `*`); *not a rule case* (the rules cannot see the branch): a bare `git push`, or `git push origin HEAD`, while `main` is checked out (`git push origin HEAD` stays open for thread branches) |
| Rewriting `main` through an unlisted spelling | Both | `git branch -f -q main HEAD~1` and `git branch --force --no-track main x` (an option between the flag and `main`); `git checkout -qfB main HEAD~1`, `git checkout -qfBmain HEAD~1`, `git checkout -qBmain HEAD~1` and `git switch -qCmain HEAD~1` (unlisted clusters); `git branch -M t3/x main` (renaming another branch over `main`); `git fetch . +HEAD~1:main` (both catch checkout `-B`, `-fB`, `-Bmain` and `-fBmain`, switch `-C`, `-Cmain` and `--force-create[=]main`, and branch `-f` or `--force` just before or after `main`, also after `-q`; Claude matches each flag only where it starts a word, after a space or a tab) |
| Commands the limits do not name | Both | moving another branch (`git branch -f t3/x HEAD~1`, `git update-ref refs/heads/t3/x HEAD~1`, `git checkout -B t3/x HEAD~1`); repository writes outside the named commands (`gh repo unarchive`, `gh repo deploy-key add key.pub`, `gh repo autolink create`, `gh workflow disable ci.yml`, `gh label delete bug`; adding a category is an owner decision); merging a pull request now (`gh pr merge 12`) and discarding work (`git checkout -- .`, `git restore .`, `git clean -fd`, `git stash`) are stated rules, not hard limits |
| A quoted or doubled-space verb or argument | Claude | `git "rebase" main`; `git.exe "reset" origin/main`; `git reset "origin/main"`; `git  reset origin/main`; `git reset  origin/main` (Codex sees the words and matches; Claude still catches flags such as `--hard`, `--amend`, `--rebase` and `--force` anywhere) |
| A quoted or doubled-space reset to a SHA | Both | `git reset "1a2b3c4"`; `git reset '1a2b3c4'`; `git  reset 1a2b3c4`; `git "reset" 1a2b3c4`; `git -C . "reset" 1a2b3c4` |
| A tab between words, or a quoted program | Claude | `git<TAB>reset origin/main`; `"git" reset origin/main` (Codex sees the words and matches) |
| A path-qualified program | Codex | `/usr/bin/git reset --hard`; `C:/Git/cmd/git.exe push --force` |
| Options or runners before Git | Codex | `git -C . reset --hard`; `git -c x=y push origin main`; `git -C . checkout -B main HEAD~1`; `rtk git push --force`; `env A=1 git push --force`; `cmd /c git push --force` |
| An argument before the flag | Codex | `git commit -m x --amend`; `git push origin t3/x --force`; `git pull origin t3/x --rebase` (the rules list a few such orders: `-a` before `--amend`, a remote and `main` before `--rebase`, a listed commit before `--hard`) |
| Flag and refspec spellings outside the lists | Codex | `git push origin --force-with-lease=refs/heads/t3/x:abcd123`; `git push origin t3/x:main` and `git push origin @:main` (only `HEAD:main` and `:main` are listed); `git push origin +t3/x` (only `+HEAD` and `+main`); `git push -fuv origin t3/x`; `git push --no-verify origin main`; `git push https://example.com/o/r.git main` (a URL or another remote name); `git pull --rebase=TRUE` |
| Shell-wrapped commands | Codex | `bash -c "git reset --hard HEAD~1"`: checked only when Codex parses the script as plain words, so an unquoted `~ ^ { } * ? [ ] $` or backtick leaves it unchecked (openai/codex source; the static model and `codex execpolicy check` never unwrap a shell) |
| An untrusted project | Codex | *not a rule case*: the rules load only when Codex trusts the project |

Over-blocks, allowed work that is refused (use the alternative):

| Over-block | Harness | Example | Instead |
| --- | --- | --- | --- |
| A mention of denied text | Claude | `git commit -m "note: git rebase is a hard limit"`; `gh pr create --body "never git push origin main"`; `git log --grep "reset --hard"`; `git -C . log --grep rebase`; a later word containing the verb (`git checkout -b t3/push-x -f`; `git log --branches -M main`) | `git commit -F <file>`; `gh pr create --body-file <file>`; reword the search |
| A path read as a commit-like first argument | Claude | `git reset docs/a.md` and `git reset build.ps1` (a lowercase hexadecimal first letter, `0-9` or `a-f`); `git reset maintenance.md` (`main`); `git reset refs/x.md` | `git reset -- <path>`; `git restore --staged <path>` |
| The same with an uppercase letter, a new branch named `main` or `main-...` with or without a space after `-b` or `-c`, or a word ending in `reset` before `-n` (the PowerShell rules ignore case) | Claude PowerShell | `git reset AGENTS.md`; `git reset CHANGELOG.md`; `git reset Docs/a.md`; `git checkout -b main-x`; `git switch -c main-x`; `git checkout -bmain-x`; `git switch -cmain-x`; `git log t3/fix-reset -n 5` | `git reset -- <path>`; a `t3/` name; options before the name (`git log -n 5 t3/fix-reset`) |
| A reset with `-q`, `-N` or `--end-of-options` and an argument | Claude | `git reset -q -- notes.md`; `git reset --quiet HEAD a.md`; `git reset --quiet -- a.md`; `git reset -N -- a.md` | drop the option |
| A reset operator inside a path | Claude | `git reset -- notes@{1}.md` (also `HEAD~`, `HEAD^`, `@~`, `@^`) | `git restore --staged <path>` |
| A commit-like first argument with paths (index only) | Both | `git reset origin/main -- a.md`; `git reset HEAD~1 -- a.md` | `git restore --staged --source=<commit> <path>` |
| `--rebase=false` | Claude | `git pull --rebase=false` | `git pull --no-rebase` |
| A name starting with `main`, or `main` anywhere in `git update-ref` | Claude | `git branch -D main-old`; `git push origin refs/heads/main-docs`; `git update-ref refs/heads/t3/x main` | another name; `git branch <name> main` |
| A bare `--mixed`, `--merge` or `--keep` reset | Codex | `git reset --mixed`; `git reset --merge`; `git reset --keep` | `git reset` |
| Read-only `gh ruleset`, `gh secret` and `gh variable` commands (the whole groups are limited, deliberately) | Both | `gh ruleset list`; `gh ruleset view 1`; `gh secret list`; `gh variable list` | the repository settings page, or ask the owner |
| `--help` on a blocked verb | Both | `gh release create --help`; `git rebase --help` | `gh help release create`; `git help rebase` |
| Recovering from a rebase the owner started | Both | `git rebase --continue`; `git rebase --abort`; `git rebase --show-current-patch` | hand the owner the command |

GitHub access follows `githubTier` in `.sw/config.json`. Tiers are stated
rules; only the hard limits are enforced:

| Tier | Agents may |
| --- | --- |
| 0 (default) | Read only: issue/pr/run/repo/label/release list, view, status, checks, diff |
| 1 | Tier 0 plus `gh issue create/edit/comment`, `gh pr comment/edit`, and draft `gh pr create --draft` |
| 2 | Tier 1 plus `git push` of the thread's own `t3/*` branch, `gh pr ready` after review, and `gh pr merge --auto` after review (`review`) and passing CI on the current revision (or the quota fallback gate, [Git flow](#git-flow) step 5) |

Sandboxes are documented, never configured: Claude users under WSL2 may
enable `/sandbox` locally; Codex has one by default and on native
Windows its users choose the mode. Sandbox settings are machine-specific, so
the kit never writes them. No model pins, credentials, shell paths or absolute
paths are committed; `sw validate` checks the portability part statically and
does not scan for credentials, which need a separate disclosure review.

## Opt-ins

| Automation | Default | Notes |
| --- | --- | --- |
| Pull request watching | On whenever a pull request exists | Link and watch as in the Git flow; unwatch on handback |
| Scheduled read-only Codex audit | Off | Owner enables it as a T3 scheduled task; it writes a report and changes nothing |
| Codex cloud automatic PR review | Off | External service; owner choice |
| Other scheduled tasks and webhook automations | Off | They start agent turns with no human present; each needs owner approval |
| MCP servers (for example Context7) | None configured by the kit | Each user adds them in Claude Code or Codex; queries and session metadata leave the machine; send no secrets or private source |

## Verification ladder

Record each level separately; a lower level never proves a higher one.

1. Static contract: `sw validate` and `git diff --check`.
2. Load check: a fresh T3 thread per provider discovers the project rules and
   skills.
3. Guardrail evaluation: expected hard-limit decisions, not executed denials.
4. Controlled workflow: a harmless approved task, skill load and fresh-thread
   resume, only when available and in scope.
5. Independent read-only review (`review`: Codex, or single-provider).

Missing runtime, second-user or interactive evidence is reported as not run.
Never execute destructive commands to prove a denial.
