# Agent workspace

Installed and updated by the SuperWorkspace kit;
files listed in `.sw/manifest.json` are kit-managed (edit them upstream, or
accept that `sw update` will skip your modified copy). OpenCode is the shared
harness: new sessions default to `project-leader`. Use `/work <task>`,
`/resume <task-id>`, `/review`, `/status`, `/validate`, `/workspace-check`,
`/handoff`, and `/inbox`. In these docs `sw <command>` means
`pwsh -NoProfile -File .sw/sw.ps1 <command>` (kit-only commands such as
`update` run from the SuperWorkspace clone).

## Canonical sources

Each rule has one owning source; everything else links to it.

| Source | Owns |
| --- | --- |
| `AGENTS.md` | Project identity and invariants (project-owned), core policy and profile rules (kit-managed blocks) |
| Project state file named in `AGENTS.md` | Implemented state and what work is authorized |
| This file | Roles, approved-plan execution, permissions, tiers, verification |
| `.sw/collaboration.md` | Task records, messages, branches, publication, integration |
| `.sw/config.json` | Profile, GitHub tier, contributors, startup budget |
| `opencode.jsonc`, `.opencode/{agents,commands,plugins}`, `.agents/skills` | Actual shared configuration; inspect these and runtime discovery before asserting behavior |
| Git and `.sw/comms/tasks/` | Ancestry, publication, and approved work; not a second memory ledger |
| `.sw/onboarding.md` | New contributor setup |

Keep required startup reading small: this map is read on demand.

## Roles

| ID | Mode | Tier | Responsibility |
| --- | --- | --- | --- |
| project-leader | primary | session | Approved outcome, direct dispatch, queue, completion |
| project-developer | all | light | Single executor: implementation, tooling and coordinated validation, Markdown docs and task records, parallel work in an assigned worktree |
| project-research | all | standard | Primary-source research, cited Markdown findings |
| project-review | all | standard | Read-only correctness, scope, simplicity findings |
| explore (built-in) | subagent | light | Focused discovery |

The Leader plans inline and dispatches directly; subagents never launch teams. Built-in `build`
may dispatch the specialists plus `general` and `explore` when a user selects
it; that is not permission for recursive delegation.

## Approved-plan execution

Approval covers the agreed outcome, dispatch, routine commands, validation, and
corrections caused by the work. Continue without asking at each step. Review in
a plan runs automatically but stays advisory. Approval never grants
publication, unrelated installs, new branch types, or unapproved scope.

Stop for a material scope change or a real blocker (credentials, tools,
conflicting work, a consequential decision). After three failed attempts at one
issue, continue only with new evidence. On provider quota or rate-limit errors
(429, session or weekly limits): stop spawning or resuming workers, write the
current state to the task record, and report. Do not retry into the limit.

### Assignment and result contract

Every assignment names task ID, approval, exact branch/checkout, owners and
allowed paths/assets, dependencies, acceptance, preservation rules, the
validation owner, and the tier it runs at plus the reason (for later
calibration). A correction includes the failing command and evidence. Every
result names changed paths, checked SHA plus dirty scope, actual commands and
results, remaining criteria, and next action.

Independent reads may run concurrently. Writers in one checkout are serialized
unless ownership is explicitly disjoint. Child sessions do not isolate files. A
worktree uses an existing assigned contributor branch; Git cannot check out one
branch twice, so coordinate instead of bypassing it. Every binary asset has one
named owner. Turn off OpenCode automatic worktrees (Desktop: default environment
= Local directory); they create detached branches outside this policy. Claude:
leave the desktop worktree option off, and do not use `isolation: worktree`.

One validation owner per checkout. Reuse evidence until changes invalidate it.
Targeted checks before full suites; small corrections inline rather than a new
subagent. On Windows without `pwsh`, the OpenCode shell is Windows PowerShell
5.1, which rejects `&&`/`||`: use separate calls or `;` with
`if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }`.

## Permissions and portability

Execution roles have host-user shell authority, **not a sandbox**; pattern rules
cannot recognize every shell spelling. Three words describe every rule:
*enforced* (tool lists and file-tool rules the harness applies), *guardrail*
(shell pattern rules, which stop the command as written and nothing else;
covered global-flag/wrapper spellings are still patterns; aliases and absolute paths can get past them), and
*stated* (role text the model is asked to follow). Never bypass a denied action with another
tool, shell form, or child. Read-only roles inspect only. Documentation edits
Markdown only. `*.env` read prompts cover direct reads; never grep or print
secret files to get around them.

| Rule | OpenCode (agent frontmatter) | Claude adapter |
| --- | --- | --- |
| Read-only roles: no edits | enforced | enforced (no Edit or Write tool) |
| Read-only roles: shell limited to listed git reads | enforced (read forms of `status`, `diff`, `log`, `show`; `--output`, `--ext-diff`, `--textconv` denied) | Bash unavailable (no deny-all/allow-read exception); main session supplies Git evidence |
| Documentation: edit `*.md` only | enforced | stated |
| `git push`, `reset --hard`, `clean`, `stash` denied | guardrail | guardrail |
| `.env` reads prompt | enforced (ask) | guardrail (Read tool only; shell reads are not covered) |
| Non-leader roles: no subagent launch | enforced | enforced (`disallowedTools: Agent`) |

OpenCode applies only each agent's own frontmatter rules; desktop 2.0.17 and
2.0.18 ignore the project-level list in `opencode.jsonc`. So `sw update`
writes the session rules (base denies and asks, profile edit denies, GitHub
tier, `.env` asks) at the head of every kit agent's `permissions`, and the
role's own rules follow (last match wins). OpenCode's built-in agents other
than Build carry no kit rules; Build gets them only from `opencode.jsonc`
(`agents.build`). The RTK plugin rewrites shell commands before OpenCode's
permission check, so the kit renders an `rtk ` twin after every shell rule;
another plugin that rewrites commands would bypass the rules the same way.
Claude settings patterns derive from the same Git verb/wrapper lists, but remain
guardrails, not security parity. Role tool lists remove tools; other per-role
limits (such as Markdown-only writes) are stated. The solo ruleset on `main` (`.sw/collaboration.md`)
stops force pushes and branch deletion, not ordinary pushes.

Sandboxes are documented, never configured: Claude users on macOS, Linux or
WSL2 may enable `/sandbox` locally; Codex users get one by default and on
native Windows choose its mode themselves; OpenCode has none. Sandbox settings
are machine-specific, so the kit never writes them.

GitHub access follows `githubTier` in `.sw/config.json`, as guardrails in
every kit agent (run `sw update` after a change); the Claude adapter's list
is a denylist, so unknown verbs, aliases and extensions fall to Claude's
default mode:

| Tier | Agents may |
| --- | --- |
| 0 (default) | Read only: issue/pr/run/repo/label/release list, view, status, checks, diff |
| 1 | Tier 0 plus `gh issue create/edit/comment`, `gh pr comment/edit`, and `gh pr create --draft ...` (the `--draft` flag must come first) |

At every tier agents never push, merge, publish releases, or change repo
settings. Humans push branches and merge.

No shared model/provider pins, credentials, shell paths, or absolute paths are
committed; `sw validate` enforces this. Each contributor's tier map lives in the
git-ignored `.opencode/opencode.jsonc` (`sw tiers`). Users supply provider access.
A Claude subscription is not OpenCode API access.

## Native session entry

`sw session start <role> <task-id> [-Model <id>] [-DryRun] [-Headless]`
is one manual control entry, not a cross-harness broker. Use an existing task
record with current approval/assignment. The main session must reconcile actual
artifacts and unknown effects before work or fresh-session resume; launch records
do not authorize work. No native resume, retry, rollback, teams or model switching
is automated.

- Owner-selected models live in ignored `.opencode/opencode.jsonc`, under
  `agents[role].model`. `sw tiers` maps worker tiers only. A session-tier Leader
  requires `-Model`; workers use their actual local role model. A conflicting
  override fails, never silently replaces the worker model. Built-in `explore`
  is not a standalone launch role. Unknown/missing/malformed models/configuration
  or role definitions fail before native launch.
- Claude spellings use the classifier below and route to native Claude Code;
  other provider/model IDs route to OpenCode. No provider/access fallback is
  supplied. Classification does not check model inventory or subscription access.
  OpenCode interactive launches use `mini --model <id> --agent <role>`: installed
  V2's default full-screen entry lacks these flags. `-Headless` uses supported
  `run --model <id> --agent <role>`; Claude headless is refused.
- Claude requires an already generated, current local adapter. For a Claude
  Leader, add a matching explicit `agents.project-leader.model` entry before
  `sw claude enable`; no entry is invented by the launcher. Mixed maps are valid:
  Claude commands STOP for non-Claude/unmapped workers; start those roles through
  this manual entry instead of dispatching them inside Claude. Leader startup
  appends its generated material only; worker main sessions select `--agent`,
  disable `Agent`, and apply the local tool list. There is no unconditional
  Leader hook. Adapter drift or stale workers stop launch.
- `-DryRun` (and `-WhatIf`) prechecks and returns separated argv without native
  launch, config writes or task-event writes. Native discovery uses PATH, not
  shared machine pins. Precheck failures produce no launch event or model request.
- Actual launches append immutable collision-safe task progress events before
  and after invocation. They name requested role/tool/model, local launch ID,
  unknown native session/observed model, exit/failure and unknown artifact/effects.
  No prompt, secret or raw native output is retained by the launcher. Exit 0 is
  **not** acceptance. Native output remains in the interactive terminal; shared
  records contain metadata only. Numeric exits propagate; invocation failures
  stop without retry and require inspection. A missing exit event after interruption
  also means unknown effects, not success. Verify runtime identity/loading/access
  and permission behavior separately; local config comparisons do not inspect
  global/account settings or establish merged runtime identity.

## Model tiers

Single source for role-to-tier membership is the Roles table above (light,
standard, high); the Leader inherits the session model.

### Routing

Two lanes: Planning (research, review, the Leader's own
planning) and Execution (developer). Execution
follows a strict written plan; no plan, Planning first. Execution defaults to
light; escalate to standard only after one failed light attempt, or when the
plan flags a step needing judgment (concurrency, shared state). Not high:
oversized work goes back to the Leader to be chunked, unless the Leader
suggests high and the user approves, or the user runs it themselves. Executor tier stays
at or below the plan's tier, usually one lower (high -> standard, standard ->
light, light -> light). On failure: Planning escalates one tier; Execution
escalates once, then returns to the Leader; the three-failed-attempts rule
still applies. Rubric (the agent classifies the task; the local tier map
picks the model): light = verify, reconcile records with Git, record
decisions, hand over commands, review one change; standard = a multi-step
plan or procedure against a clear spec (even across systems), full-context
continuation briefs; high = architecture trade-offs, unclear requirements,
large multi-system review. A costly-mistake risk (security, data loss,
publishing) makes it high only when the agent itself performs the
irreversible step, not when it hands commands to a human. Applying a tier:
tiers are model-only (no effort, `reasoningEffort` or `#variant`; `sw
validate` rejects them). Role defaults come from the local tier map
(OpenCode); Claude agents use explicit local `agents[role].model` values. Work above a role's default runs in
a session at that tier (the Leader inline, or a fresh session the human
opens). Never switch a running session's model.

Claude generation requires a local `.opencode/opencode.jsonc` map from `sw tiers`
or an owner edit. Supported Claude spellings are explicit `opus`, `sonnet`,
`haiku`, `fable`, `best`, `opus[1m]`, `sonnet[1m]`, full `claude-*` IDs, or
`anthropic/claude-*` IDs (the provider prefix is stripped, never converted to a
guessed alias). Other provider/model IDs are non-Claude; ambiguous spellings,
`default`, `inherit` and `opusplan` are rejected. Missing maps or maps with no
Claude roles fail generation; unmapped/non-Claude workers are omitted and their
commands stop rather than dispatch or impersonate them. No shared user model
pin or implicit launcher fallback is supplied. Alias/model availability and the
actual runtime model still need live verification. Keep the map available for
adapter disable/drift checks, which compare current generated content.

The ignored adapter writes `.claude/CLAUDE.md` with `@../AGENTS.md`, relative to
that file, importing canonical root rules without a duplicate. Official Claude
documentation supports this location/import syntax; static path checks do not
prove live loading or compaction. Worker definitions load their own role body;
`.claude/project-leader.md` is only for an explicitly selected Leader main
session, not a session-wide startup hook. Actual adapter/map enablement is
opt-in; generation does not configure accounts or verify tool/model access.

- Launch: on OpenCode 2.0.20 the `run` path ignores agent models
  (frontmatter and the local `agents` map; only `-m` selects the primary
  model; top-level `model` does not fix it), so any CLI launch
  `opencode run --agent X` passes `-m <X's tier model>`. The tier map still
  routes subagents launched through the `subagent` tool. Re-verify after
  OpenCode upgrades. Evidence: Workspace hands-on check, 2026-10-02 (U1
  harness decision). A session continued with `-s` keeps its `-m` model.
- Parents do not pass `model` to the `subagent` tool: it overrides the pin
  and no permission rule can block it. Advisory; spot-check session exports.
- A shell deny stops the shell call, not the effect. A hard rule against a
  file effect also needs matching `write`/`edit` rules at project level;
  plugins that rewrite commands (`rtk.ts`) are part of the enforcement
  boundary.

Default cost policy is free-first: free OpenCode/OpenRouter models and local
LM Studio, no metered API spend unless a contributor opts in locally. To pick
free models per tier, follow the `free-models` skill's procedure; the kit
ships no model IDs or tier fits. Local models with small context windows must
override `compaction` locally.

## Usage optimization

- Startup budget: `AGENTS.md` + role body + skill names/descriptions (the Leader
  also counts the other agents' descriptions), capped per role by `sw validate`
  (`startupBudgetBytes` in `.sw/config.json`); tokens are a bytes/4 estimate.
- Skills and docs load on demand; do not re-read `AGENTS.md`.
- RTK rewrites shell output through `.opencode/plugins/rtk.ts` (fails open).
- context7 MCP for library docs instead of web search; it receives your queries,
  so send no secrets or private source. It is the one third-party remote MCP
  server the kit ships; add only MCP servers you trust.
- Resume from task records, not chat summaries; batch independent calls.
- Subagents pay a cold start; the Leader does small work inline.

## Claude adapter (opt-in, local)

`sw claude enable` generates a git-ignored `.claude/` from these sources:
pointer agents and commands, copied skills, permission rules for the GitHub
tier, and role-scoped startup material. No unconditional SessionStart hook
makes worker main sessions the Leader; native entry selects the main role.
`sw update` regenerates it when `.claude/.sw-generated` exists; otherwise run
`sw claude enable`. `sw validate` reports drift. Never hand-edit generated
files; edit the `.opencode/` or `.agents/skills` source instead. Claude applies instruction edits
and `update` output only after `/clear`, `/compact` or a restart. Keep one
model per session in every harness: switching mid-session breaks the prompt
cache.

## Verification ladder

Record each level separately; a lower level never proves a higher one.

1. Static contract: `sw validate` and `git diff --check`.
2. Runtime discovery: the OpenCode CLI `api` against `/api/agent`,
   `/api/command`, `/api/skill` with an explicit
   `?location%5Bdirectory%5D=<encoded-repo-path>` (omitting it reads home config).
   The first request for a new directory can return an empty command list
   while discovery warms up; repeat it before reporting a failure.
3. Permission API evaluation: expected decisions, not executed denials.
4. Controlled workflow: a harmless approved dispatch, skill load, and
   fresh-session resume, only when available and in scope.
5. Independent read-only review.

Missing runtime, second-user, or interactive evidence is reported as not run.
Never execute destructive commands to prove a denial.
