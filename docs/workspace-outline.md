# Workspace design rules, assumptions and outline

**Canonical project design register.** Owner requirements below are approved;
architecture recommendations are provisional. Updated 2026-10-20 (UTC).

## 1. Approved direction

The owner clarified these requirements directly in the current session;
execution record (local task record `workspace-state-review/2026-10-01T222130Z-leader-assignment.md`).

| ID | Requirement | Authority and revision |
| --- | --- | --- |
| D1 | **Workspace must be research-based.** Use the owner's research findings, current claims register, qualifications and corrections to inform design; do not retrofit findings around an assumed kit architecture. | Owner requirement. New evidence can revise recommendations; changing this requirement is an owner decision. |
| D2 | **Everything in this project can be modified, overhauled or replaced based on new research/data.** This includes instructions, rules, assumptions, kit sources, generated files, roles, harness choices, architecture, layouts and tooling. Nothing is privileged merely because it already exists or is kit-managed. | Owner requirement. An approved change can retain, revise or replace any project component. This is changeability, not authorization to make every change now. |
| D3 | **Document every identified rule or assumption that materially shapes Workspace, preferably here in one document.** Identify its source, status, limits and revision trigger; do not silently treat an inherited preference or uncertain inference as a requirement. | Owner requirement. Add newly identified shaping constraints here; the owner can revise the register or its organization. |
| D4 | **Retired (owner, 2026-10-16): the parent WS manager.** The earlier requirement installed a tailored manager for cross-project planning/communication while keeping projects independent. The manager is now removed; each project's own tooling and records remain. | Original approval: local task record `ws-manager/2026-10-04T051621Z-leader-assignment.md`. Superseded by the owner's standalone relocation and parent-manager removal decision, verified in local task record `standalone-relocation-2026-10-16/2026-10-17T012204Z-codex-integration.md`. |

**D5 - Public adoption contract (owner, 2026-10-11):** MIT with preserved
third-party notices; preserve host configuration and Git workflow, compatible
additions and explicit conflict decisions, no automatic deep merge; local-only
records for new installs while keeping existing choices; GitHub private
vulnerability reporting, human-enabled and unverified until confirmed. Owner
approved the bounded adoption fix plan, not publication/settings or unrelated
global/native/platform changes. Existing config variants may be explicitly
refused; neither backup replacement nor static success means seamless runtime
compatibility. Implementation/check state belongs in the state/task record,
not this design requirement. Revised integration, privacy or license defaults
require a new owner decision; evidence can revise implementation boundaries.

**D6/D9 reading note (2026-10-20):** these dated decisions retain their original
reasoning. D7 supersedes D6's OpenCode provider choice; D9 supersedes D6's
commit/push restrictions. The later rebuild reinstated generated hard-limit
rules for Claude Code and Codex, superseding D9's proposal to drop shell deny
lists. Current controls are O7/O13 and `AGENTS.md`; neither historical paragraph
below authorizes a return to retired providers or removal of hard limits.

**D6 - T3 Code is the required app (owner, 2026-10-15 UTC):** T3 Code
(`pingdotgg/t3code`, MIT; its README says "very very early... expect bugs") is
the required app for the personal instance and the public product. It runs
OpenCode and Claude Code threads with their native project configuration and
replaces the `sw session start` launcher, which is retired. Workspace Git policy
conforms to T3 Code: `main` plus one worktree-thread branch per thread
(`t3/<name>`), replacing owner-designated `<user>/<user>-worktree` branches.
T3 Code's commit, push, pull request and Restore actions are human actions;
agents still never create branches, commit unasked or push. Host Git policy is
unchanged. The owner approved rules, launcher removal and docs; live acceptance
inside T3 Code needs its own approval. Source: T3 Code repository and its
`docs/user/` provider, permission-mode, source-control and project-settings
pages (accessed 2026-10-15). Revisit if T3 Code's behavior or license changes or
live acceptance fails. Supersedes the launcher parts of S2 and O13's branch model.
**D7 - Claude and Codex through T3 Code; OpenCode dropped (owner, 2026-10-15
UTC):** OpenCode is removed from the personal and public product; T3 Code runs
Claude (Claude Code via the Agent SDK) and ChatGPT (Codex). Architecture
answers to [topic 11](research/11-t3-agent-architecture.md): no Leader role (the
main T3 thread coordinates; core rules in `AGENTS.md`, procedures as workflow
skills); parallel implementation through T3 worktree threads with task records
kept in the main checkout; the owner will trust the project in Codex so project
rules load; the governance docs (including `.sw/workspace.md`) are to be
rewritten. Review routing (owner, 2026-10-15): Codex is the default reviewer
for every review, audit and bug hunt, whoever authored the work; any other
cross-provider review runs only when explicitly requested in the prompt.
Workflow method: the topic 12 composite (R1) is adopted, without a trial (R3
declined). Later the same day: lessons are a dated line in the task's closing
summary, promoted into a rule, check or skill after review when they recur or
cause a failure, never auto-loaded (topic 12 Q3); the [topic 13](research/13-agentic-leverage.md)
R1 review stack is approved; Codex cloud PR review is not automatic; the
scheduled read-only Codex audit is opt-in. Moving to T3 Auto waits on a
planned guardrail rule set. No implementation is approved by this record.

**D8 - Better options replace the current system (owner, 2026-10-15 UTC):**
when a better-evidenced option exists, it replaces the current Workspace
design rather than the current design being kept by default. Decisions must
compare the current system as one candidate among the alternatives.
Third-party options, including installs, are eligible and are chosen when they
are the best or most maintainable option; avoiding a dependency is not a goal
in itself (owner, 2026-10-15). Installing still needs the usual explicit
approval.

**D9 - Hands-off Git through T3 Code procedures (owner, 2026-10-15 UTC):** the
shell-pattern Git deny lists (generated Claude and OpenCode rules, planned
`.codex/rules` Git blocks) are dropped; T3 Code's Restore checkpoints, per-turn
diffs and worktree threads are the safety net. Agents commit as they go in
small conventional commits. Small, docs-only or solo work commits directly on
`main`; code changes and anything published to `origin` go through a `t3/<name>`
worktree thread and a pull request. Push and pull request: either the owner uses
the thread's Git actions, or the agent pushes its `t3/` branch and opens a draft
pull request itself (GitHub tier 2; this record said tier 1 until owner M7
decision 8 corrected it, 2026-10-15), then links and watches it
(`link_pull_request`, `watch_pull_request`) and fixes CI and conflicts.
Codex review precedes merge; merging uses auto-merge once required checks
pass. Hard limits remain: no force-push, no push to the public `origin` outside
the pull request route, no releases or repository-setting changes, no rewriting
`main` history. T3 settings: automatic pull, merge-based worktree cleanup that
keeps worktrees with local changes, `t3/` branch prefix. Supersedes D6's
"agents never commit unasked or push", O13's commit/push rules and topic 11
R5's Git deny rules once implemented; until then current rules govern. Source:
T3 Code `docs/user/source-control.md` and `project-settings.md` at `ec1313c8`
(accessed 2026-10-15). Open for the plan: how a local Codex review becomes a
gate auto-merge respects (required check or the agent enabling auto-merge only
after review), and branch protection on `main`. No implementation is approved
by this record. Owner M7 decision 2 (2026-10-15) settles both: `main` is
protected against force-push and deletion, CI is not yet a required check, and
the agent enables auto-merge only after Codex review and after the relevant CI
checks pass on the current pull request revision. Task `ci-minutes` (owner,
2026-10-18) orders it draft, review, ready, CI, auto-merge (drafts run no CI)
and adds a local fallback gate when hosted CI cannot run for a quota or
billing reason (O13).

Static source/doc review of T3 Code `ec1313c8` (2026-10-15, not live-tested):
OpenCode 2 threads run as built-in `build`/`plan`, not the default agent; T3
session permission rules follow agent rules and win (Full access allows all,
Supervised asks for every shell/edit, Auto-accept edits allows every edit), so
only Supervised keeps a human gate over kit denies; Claude threads use the Agent
SDK with modes `default`/`acceptEdits`/`auto`/`bypassPermissions`; worktree
threads lack ignored local files. `t3.json` can set `defaultThreadEnvMode` and
shared scripts, not permissions or branch prefix (a kit `t3.json` is unproposed).

**D10 - Product scope: T3 Code with CLIProxyAPI (owner, 2026-10-16):**
SuperWorkspace targets T3 Code with CLIProxyAPI; supported harnesses are Claude
Code and Codex, others added after verification. Windows only for now.
CLIProxyAPI does routing only: no rule injection and no management page for now.
The documentation names a tested CLIProxyAPI version and re-pins it often.
Shared settings, skills and rules come from one central source in two tiers: a
product tier in this repository, and a personal tier kept locally at `~/.sw/`
without Git. Each harness is wired natively:
- skills are linked one by one into `~/.agents/skills` (Codex) and into each
  Claude config directory's `skills`;
- rules reach Claude by `@import` and Codex through a managed block;
- MCP and hooks entries are generated only when needed.

Every harness gets the same central rules, plus optional per-harness additions
from the personal tier. This refines topic 14's S3 skill-links
recommendation. It replaces two earlier local plans: one managed provider home
per harness, and the skill-links execution plan. Evidence: research topic 15.

Planning view: [central skills/rules delivery roadmap](central-delivery-roadmap.html)
maps proposed milestones and open choices to this direction. The register owns
decisions; state and task records own implementation, authorization and evidence.
Detailed execution planning (2026-10-19 UTC) is recorded in a local task
record: E0-E9 map evidence/contract decisions through
implementation, migration, native acceptance and adoption. The owner approved
E0/E1 evidence/contract preparation. Exact candidate source/license inspection
is complete. The owner accepted G2's direct-source/A7 contract and E3's strict
schema/pure planning/read-only synthetic preview, now verified in a private-instance PR
as recorded in [state](workspace-state.md#startup). G1's individual review covers
31 ECC/Hermes skills and primary documentation; drafting, comparisons and the
catalogue still need their selected scope. Task attachments own commands/schema,
case definitions and decision history. Contract acceptance authorizes no real
links, rule replacement, project migration, installation or deployment in E3.

Audience refinement (owner, 2026-10-19 UTC): a general foundation with research
and software development equally included by default. Specialist selection is
outside this audience decision. Public skill/plugin/MCP choices are being
evaluated in [topic 16](research/16-public-capabilities.md). This sets the target
audience, not the catalogue or an installation/implementation approval.

Live checks (2026-10-17, one T3 Code version):
- a Claude instance with a custom config directory loads that directory's
  `CLAUDE.md`;
- a skill linked into both locations appears once in Claude and once in Codex;
- Claude does not read `~/.agents/skills`.

Runtime (owner, 2026-10-16): the kit runs on the PowerShell built into Windows
(5.1) with nothing else to install, and also on PowerShell 7. Product commands
use `powershell -NoProfile -ExecutionPolicy Bypass -File`. Pester 5 stays a
development and CI dependency. The Linux/macOS code paths and the Linux CI job
are removed. Both are implemented: Windows-only in PR #4 and PowerShell 5.1
plus 7 in PR #5 (merged 2026-10-17). JSON keys that differ only in letter case
are now refused on both shells. Later evidence (owner, 2026-10-18): `t3.json`
scripts run from T3 Code passed; Context was run from a terminal only. Group
Policy blocking Bypass and a real no-console parent remain unverified. Current
evidence and authorization belong in [state](workspace-state.md#startup);
each implementation package needs its own approval.

**D11 - Never overwrite local edits (A7; owner, 2026-10-16):** no update,
removal, conversion or restore may overwrite or delete an installed copy that
was edited locally or cannot be shown unedited. There is no `--force` bypass.
A restore proceeds only after the replaced content has been saved recoverably.
Editing happens at the central source. D11 applies to every sync mechanism.

The first package (approved 2026-10-16) is implemented for `sw global`; PR #3
merged on 2026-10-17:
- a baseline record at `~/.sw/global.json`;
- `-ReplaceUnmanaged` retired;
- install no longer rewrites Claude `settings.json` or `~/AGENTS.md`, and
  `check` reports them instead;
- an edited block becomes a `check` warning (exit 0).

Evidence: Codex review rounds 1-5, all findings fixed, and CI Pester
432/0/1 on Windows and Ubuntu. The Linux/macOS advisory-lock limit recorded
then no longer applies: the kit is Windows-only since PR #4. The project
generator's managed
blocks and `-Adopt` still have the gap; fixing them is not yet scheduled.

Project-generator follow-ups (owner, 2026-10-22 UTC): a private-instance PR added prompt-time
freshness refusal (C1/C2). The remaining semantics stay as implemented and are
documented here. C3: a block that changed before inspection keeps the current
behavior; revisit at E5. C4: explicit `-Adopt` over unowned conflicting content
counts as consent and keeps backup-then-replace. C5: a run that skips edited
items still exits 0 and reports the skips; revisit at E4/E6.

**D12 - Current truth before deeper restructuring (owner, 2026-10-20 UTC):**
simplify the path to current behavior, authority and next decisions first;
then use four representative read-only task traces to judge deeper structural
changes. Execute the bounded documentation cleanup, repair scoped existing
native memories in place with dated pointers and recoverable backups, and
archive verified completed records using the existing mechanism. Keep central
delivery open. Preserve useful lessons and dated evidence. Source-reading
burden is not measured runtime tokens or task efficacy. Trace findings become
concrete proposals, not automatic code/skill changes or model comparisons.
A local task record owns execution and acceptance;
the register records this sequencing decision for later work. Revisit when
representative tasks or new evidence identify a concrete benefit and the owner
selects its scope. No new memory service, catalogue, installation, native probe
or publication is selected.

**D13 - The public repository is the template (owner, 2026-10-22 UTC):**
the public SuperWorkspace repository itself is what new users copy or install
from (option A), rather than a separately generated template repository. This
answers the public-template handoff's first question. The remaining questions
were decided 2026-10-24 UTC:

- Q2: sources and tests live in the public repository; development evidence
  (`.sw/comms`) stays local and private.
- Q3: public instructions are the README plus the generated `AGENTS.md`; each
  project's identity and current state live in its own state file; no new
  setup helper (`sw.ps1 init`).
- Q4: default skills are work, resume, handoff, review, validate, status,
  minimal-change, research, structured-debugging and agent-documentation.
  Research is built in, not opt-in; no external plugin/MCP defaults.
- Q5: a new project gets `main` only at the lowest tier; for an existing
  project, init/update only detect and never change remotes, branches or Git
  config.
- Q6: upgrades use a documented manual `sw.ps1 update`, supported from the
  previous release only; update-PR automation is deferred.
- Q7: keep the existing public repository, with no history rewrite.
- Q8: folded into G4.
- Q9: deferred until there is a team user.

P0 (owner, 2026-10-25 UTC) approves the product contract's ownership classes:
template-owned (core skills and native copies, `.codex/` rules, `.sw/` runtime
and guidance, the `sw:core` block, licensing; replaced by `sw.ps1 update` via
the manifest), project-owned (identity and boundaries outside the core block,
the state file, design docs, approvals, app files, Git workflow; never
replaced), personal/local (credentials, model preferences, `.sw/comms/`
records, backups, local leak patterns, user settings; never published) and
mixed (`AGENTS.md`, `.gitignore`/`.gitattributes`, `.sw/config.json`,
`t3.json`: only marked or manifest-recorded parts are updated; other conflicts
are reported, or backed up with `-Adopt`). A new project supplies its
name/profile, identity, a state file with a Startup section, its Git choice
and a first approved task. No public publication or history rewrite beyond the
approved public-first flow is authorized; packages P1-P6 each need their own
approval.

These supersede the earlier outline's preserve-base design premise. Preservation
within a bounded task protects unrelated work; it does not make any component
permanent. The external research corpus is a source, not part of this project's
changeable assets, and this task does not authorize editing or redistributing it.

## 2. How to use this register

- **Approved requirement (D):** directly specified by the owner above.
- **Current control (O):** an operative project/harness rule or installed choice,
  not necessarily a research-supported target design. Follow it until changed.
- **Provisional proposal (P):** an evidence-informed interpretation, not adoption.
- **Unresolved assumption (U):** missing evidence or a decision still required.
- **Synthesis decision (S):** an owner-directed or owner-confirmed design decision from the U5
  synthesis, with its evidence and open sub-points. It sets design direction;
  it does not by itself authorize implementation.

This is the single design-review view, not a second implementation of permission
patterns or a task/status ledger. [AGENTS](../AGENTS.md) applies project policy;
[state](workspace-state.md) owns implementation and authorization;
[workspace guidance](../.sw/workspace.md), [collaboration](../.sw/collaboration.md)
and the configuration linked below contain current operational detail.
For each change, revise the relevant register entry and its actual controlling
source together. No proposal, research update or recorded gap starts work by itself.

Project-owned controls can be replaced through an approved scope. Global/session
instructions and tool restrictions can also shape execution, but are outside this
repository: changing a project document cannot override or bypass them. Where a
control is enforced, a guardrail or merely stated, retain that distinction; static
documentation does not prove runtime behavior.

## 3. Current controls and inherited choices

The inventory below covers the identified material shaping constraints. Exact
permission cases and role procedures remain in the linked implementation; their
presence is not evidence that this design is optimal.

| ID / area | Current rule or assumption | Provenance, applicability and limits | Revision trigger / authority |
| --- | --- | --- | --- |
| O1 Purpose | Reusable, generic AI workspace for bounded project work. The owner selected a general foundation with research and software development equally default (D10); particular application workloads remain unselected. | Existing project brief and generic profile; a working scope, not a research-proven taxonomy or architecture. | Owner clarifies intended workloads; compare design against those needs. |
| O2 Installed base | SuperWorkspace 0.4.0-dev (2026-10-15, `t3-native-rebuild`); v1 research profile with the research capability, solo `users: []`, GitHub tier 2 in this checkout (owner M7 decision 1, 2026-10-15; set in the project-owned `.sw/config.json`; the tier is a stated rule and changes no generated file). T3 Code threads run Claude Code or Codex; no default agent or roles. | [Config](../.sw/config.json), [manifest](../.sw/manifest.json), [T3 scripts](../t3.json). The `provider-setup` capability and OpenCode configuration were retired by the 0.4.0-dev update. These describe installation, not target requirements. | Any separately approved refit can change or replace the base/profile/harness. |
| O3 Generation | Kit sources currently live in `project/`, `lib/`, `global/` and `sw.ps1`; installed definitions are manifest-managed. Avoid silent competing copies while this generator is used. | [AGENTS](../AGENTS.md), manifest, workspace guidance. Source-generation consistency is conditional on retaining that mechanism. | Change upstream sources or explicitly migrate/replace the generator; no permanent kit-preservation rule. S2 is a dated synthesis; D7/D10 and the selected delivery contract refine the target. Any further refit needs scoped approval. |
| O4 Context ownership | Read Startup, inspect Git and relevant files, reconcile authorization before meaningful work; load detail/skills on demand. State and task records have distinct owners. | AGENTS (Claude loads it through `.claude/CLAUDE.md`); [skills](../.agents/skills/) mirrored to `.claude/skills/`. No demonstrated universal task-success gain from this file scheme. | Approved context/continuity changes, measured loading failures or representative-task evidence. |
| O5 Scope and effects | Only approved work executes; a plan covers routine execution/checks/corrections, not new scope. No automatic installs, dependencies, external access or global configuration changes. Owner requests carry exact copy-paste commands that run from any directory (explicit repository targets, absolute paths; owner, task `owner-commands`). | AGENTS and workspace guidance; state records the currently selected execution scope. Research is advice, not permission. | Owner approves a bounded change and any consequential effects; global/session limits still apply. |
| O6 Change method | Preserve unrelated/uncommitted work and working behavior; reuse first, smallest independently testable change; avoid speculative refactors. | AGENTS and `minimal-change` skill; an execution method, not a veto on an approved overhaul. | An approved replacement/refit defines broader scope, preservation/migration and acceptance. |
| O7 Roles/access | No roles (D7, topic 11): the main T3 thread coordinates and plans; skills hold procedures (`work`, `review`, `resume`, `handoff`, `status`, `validate`, `research`, `minimal-change`, `structured-debugging`, `agent-documentation`); side-effect skills are user-invoked only. Child work runs as T3 delegated tasks or worktree threads with a brief and a final report. | [AGENTS](../AGENTS.md), [skills](../.agents/skills/), workspace guidance. The four-role roster and `roles.json` were removed in 0.4.0-dev. Claude workflow skills set `disable-model-invocation: true`; their Codex copies ship `agents/openai.yaml` with `policy.allow_implicit_invocation: false`. Method skills (`minimal-change`, `structured-debugging`, `agent-documentation`) have neither and may load implicitly. Runtime enforcement of both settings is not separately verified. | Owner-approved orchestration/access redesign; measured coordination failures. |
| O8 Coordination | Explicit task/checkout/path ownership, dependencies and acceptance; independent reads may overlap; writers serialize unless disjoint; parallel implementation uses separate T3 worktree threads or delegated tasks with disjoint file ownership; the main thread integrates. One validation owner per checkout; records are written in the main checkout only. | Workspace guidance and collaboration. Child sessions in a shared checkout do not isolate files. No fixed delegation requirement for every task. | Measured coordination need or failure; approved change must address shared-state/ownership risks. |
| O9 Tiers/budgets | No model pins in shared files; an optional ignored `.sw/models.local.md` holds a personal tier table. Quota stop (no retry into a limit); switching provider/model mid-thread is a handoff. Startup budget is 12,100 bytes. | Workspace guidance, config and global/session instructions. This is not a tier-fit benchmark. Global harness guidance may add routing constraints. The stop rule covers quota and rate errors that reach the agent; agents never change routing, retries or credentials. | Approved routing/budget change after task-level evidence; session-imposed limits require changes outside this repo. |
| O10 Cost/data setup | Free-first; no metered spend without opt-in. Model mappings and credentials stay local; shared files avoid machine paths/provider pins. Owner requirement (2026-10-02): every installing user configures their own tools, models and accounts locally. | Workspace guidance, validation contracts and global/session rules. These are current policy/portability choices, not evidence that cheapest-token models are best. | Owner-approved cost/data/portability policy; check actual terms and task-level effort first. |
| O11 Runtime configuration | The kit configures no MCP servers, plugins or compaction settings; Context7 and RTK plugin configuration left with OpenCode (0.4.0-dev). MCP servers are configured per user in Claude Code or Codex. T3 project settings (automatic pull, worktree cleanup, `t3/` prefix) are human-set. | [Workspace guidance](../.sw/workspace.md), [T3 scripts](../t3.json). Settings presence does not establish effective loading or trust. | Evidence of task/context/tool failure or an approved harness/tool change. |
| O12 Safety | No credential probing or denied-action bypass. Git/GitHub hard limits (force-push, push to `main`, releases, repository settings, rewriting `main`; since M7 round 1 also `reset --hard`, `commit --amend` and rebase on every branch, because prefix rules cannot see the branch; since M7 decisions 5-6 also `pull --rebase` and any reset that moves the branch, keeping unstaging open) are tracked `.claude/settings.json` denies and `.codex/rules/workspace.rules` forbidden prefixes; `.env` reads are asked. Threads have host-user shell authority; T3 Restore and worktrees are the recovery net (D9). | Generated settings/rules, workspace guidance and global/session controls. Prefix matching stops the command as written, not every spelling; not a sandbox. Not covered in either harness: aliases and Git configuration, scripts and APIs (`gh api`), run-time-built commands, escapes inside a word, line continuation, abbreviated long options, unnamed reset targets, a push to `main` that does not name it (a `:` or glob refspec), some `main`-rewrite spellings and flag clusters, and commands the limits do not name (including repository writes such as `gh repo unarchive`; adding a category is an owner decision). Claude also misses quoted or doubled-space verbs and arguments, a tab, a quoted program and (Bash) an uppercase target or program; Codex misses options or runners before Git, arguments before a flag, path-qualified or differently cased programs, unlisted flag or refspec spellings and (per its source) shell scripts that are not plain words. `git reset <sha>` vs `<path>` is approximated, with documented over-blocks; since M7 review round 3 a commit-like name after `--` is never read as a commit, and `.exe` and push flag-cluster spellings are blocked; since round 4 so are the common `checkout -B`, `switch -C` and `branch -f` spellings that rewrite `main`, `pull -vr`/`-qr` and a reset with `-N` or `--end-of-options` before a commit. No Claude pattern holds a doubled space: in a live test with one Claude Code version, a doubled-space pattern alone also denied `git diff --stat`, while quote-ending patterns alone did not; quote-ending patterns stay out too, since quote handling in patterns is undocumented. Every command in the gap and over-block tables in `.sw/workspace.md` (Git flow) is a `sw validate` static case, tied by the kit's tests to its row's Harness column; examples marked *not a rule case* are checked by nothing. The owner accepted the tables as the 0.4.0-dev baseline (decision 15, 2026-10-16). Supervised is not used; threads run Auto or Full access, so the accepted gaps rely on agent restraint. Live check L5 passed for Claude and Codex in a scratch project: Supervised and Auto on the round-3 rules, Auto and Full access on the final round-5 rules. Every rule decision matched the static model, and no rule denied a control. In Supervised, Codex prompted before its gap spellings; in Full access it ran them silently. In Auto, Claude's classifier and Codex's auto-review refused some gap spellings and some ordinary commands, inconsistently, so they are not counted as enforcement. On Windows, Codex rules did not check a plain-word `bash -lc` script. | Approved threat-model/access/isolation change; project edits cannot disable external tool restrictions. |
| O13 Git/publication | D9 implemented in 0.4.0-dev: commit as you go in small conventional commits; small, docs-only or solo work on `main`; code changes and `origin` work through a `t3/<name>` thread and a pull request (the owner's private instance, a separate remote configured locally, or `origin` for product changes). At GitHub tier 2 the agent pushes its `t3/` branch, opens a draft PR (drafts run no CI), watches it, marks it ready after Codex review, and enables auto-merge once the relevant CI checks pass on the current PR revision; if hosted CI cannot run for a quota or billing reason or because Actions is disabled (jobs not started), the gate is the full local test suite on every CI shell at that revision plus `sw validate` and review, recorded in the PR body and task record (task `ci-minutes`, owner 2026-10-18; Actions-disabled case and owner merge where auto-merge is not allowed, owner 2026-10-22); otherwise the owner publishes. Hard limits per O12. No other branches, hard reset, clean, stash or discarding work. Public publication (public-first, owner 2026-10-23; replaces the 2026-10-22 snapshot method now that private `main` merged the `origin` history, merge-base 683e9a4): product work starts in a thread launched after `git fetch origin` with `baseRef: origin/main`, `startFromOrigin: false`, whose first step checks `git rev-parse HEAD` equals `origin/main`. The agent may push its own `t3/<name>` branch to `origin` and open the public PR; before each push `tools/publish-scan.ps1 -Base origin/main -Source HEAD` must exit 0 (it prints `path:line: rule` per hit without the matched text and exits 1 on any hit; `-Tree` scans the whole source tree). Public PRs gate on hosted CI (`origin` has Actions enabled; the local-gate fallback applies only when hosted CI cannot run), are squash-merged, and the owner merges once the gate passes (`origin` has auto-merge off). After each public merge the private instance syncs by a PR that merges `origin/main` into private `main` (a merge, never a rebase). Pushing to `main` on any remote, force-push and the other hard limits stay unchanged. | AGENTS, collaboration, workspace guidance, global rules. D9's tier text was corrected to tier 2 (M7 decision 8). `main` is protected against force-push and deletion (a human repository setting); CI is not yet a required check, so auto-merge alone does not wait for it (a required check would also block direct `main` pushes). Private `main` contains the public squash commits only through explicit sync merges of `origin/main`; `t3/` branch commits are ancestors of neither `main`, so an ancestry check for a branch commit can fail even when its change is integrated; the leak scan screens the diff only, so review still checks for private material. | Owner-approved workflow revision, while session publication/data-loss constraints still apply; a sync merge that conflicts or diverges from `origin/main`, a leak-scan miss, or a change to `origin` CI, auto-merge or protection settings reopens it. |
| O14 Records/review | Task events carry approval, progress, ownership and exact evidence; append-only/author rules protect history. Resume reconciles records with Git. Codex reviews before merge through a T3 delegated task (read-only by instruction) or `codex exec -s read-only` when enforcement is needed; review stays advisory. Closing summaries carry a dated lessons line, promoted after review. | Collaboration, `review`/`resume`/`handoff` skills. Complete, committed and published are separate states. | Approved record/review migration can revise this mechanism; no silent history rewrite or duplicate memory ledger in the meantime. |
| O15 Checks | Docs: `sw validate` and `git diff --check`; code: discover build/type check, targeted tests then suite, actual manual checks only when available. Static/discovery/permission evaluation/workflow/review evidence stays separate. | Current AGENTS research profile/capability and workspace verification ladder. Untracked Git diffs and known ordinary-project-doc coverage gaps need explicit checks. | Approved validation change or demonstrated coverage gap; report unavailable checks rather than claim them. |
| O16 Optional capabilities | Other profiles, persistent memory, network exposure/connectors, PR auto-review, scheduled Codex audit and remote setup are not enabled or authorized by their availability. PR watching is on whenever a PR exists. | State and workspace guidance. The [remote-access procedure](remote-access.md) is retired OpenCode history. | Concrete owner-selected need, permitted data and separately approved acceptance/security scope. |
| O17 Root manager | Removed from the product in 0.4.0-dev (plan O3). The owner also removed the former parent WS directory; migration is complete (D4). Retired sources remain in Git history before `eecacbd`. This manager is distinct from the separate private Workspace remote. | D4 relocation closure; plan O3 (local task record `t3-native-rebuild/`). | Owner revises D4. |

## 4. Evidence-informed proposals, not a selected architecture

References E4-E8 name local corpus reports below; claim IDs resolve in its current
`docs/research-claims.md`, including later corrections. These are bounded design
interpretations. Neither research nor kit packaging selects an optimal Workspace.

| ID / area | Provisional direction | Evidence and limitation | Reconsider when |
| --- | --- | --- | --- |
| P1 Context/prompting | Keep necessary authority/constraints discoverable; test task/model-specific guidance rather than presume longer files, personas or prompt rituals improve outcomes. | E5 C112-C115: Python-task context-file success nulls, conflicting cost effects, model-specific tuning. E6 C152/C160-C161 are qualified. E7 C186-C193 do not establish prompting effects on models released in 2026; C111 remains a gap. | Representative-task or newer controlled evidence changes the trade-off. |
| P2 Orchestration | Choose inline/single-agent work or bounded delegation according to task decomposition and observed effort, not an obligatory roster or team framework. | E5 C089/C121: no general matched-compute multi-agent gain; task-dependent benefits remain. Spec-detail/workflow results C091/C153 are qualified, not a universal spec-first requirement. | A demonstrated coordination/decomposition need or matched-condition comparison. |
| P3 Models/cost | Compare model, harness, effort and tools as a configuration; measure successful-task cost and human correction effort, not token price alone. | E7 C164/C167-C168: leakage, run variance and harness effects; C197-C198: effort/token use affect cost per task. C202: measured agent total cost beyond tokens remains a gap. Benchmark cost is not the owner's workload cost. | Actual workload, versions, pricing/terms or accepted budget changes. No provider/model chosen here. |
| P4 Verification | Prefer executable outcome/constraint checks; record configuration and uncertainty. Validate any model judge against task-specific human labels and allow unknown results. | E7 C173-C185: criterion/dataset dependence and judge-specific biases; workspace/coding-trajectory judge efficacy C108 remains a gap. Small score gaps are not reliable single-run proof. | A chosen acceptance case or demonstrated need for a calibrated judge. No evaluation platform is adopted. |
| P5 Memory | Keep authoritative state distinguishable from retrieval; compare simple files/retrieval/full context before adding a memory service. Define provenance, write authority and correction/expiry for any persistence. | E5/E6 C076-C079/C117-C119: poisoning, staleness, mixed superiority and write-cost trade-offs; coding-file-memory efficacy remains a gap. Some adaptive defences retain bypass; no general safety guarantee. | Demonstrated retrieval/update failure and a bounded comparison with simpler baselines. |
| P6 Extensions/safety | Treat skills/plugins/MCP and supplied instructions as trust surfaces. Evaluate provenance, privileges, destinations, cost and recovery; don't mistake prompt rules for isolation. | E5/E6 C082/C088/C101-C102/C141-C156: differing risk measures and attacker positions; no approval-enabled skill exploit study or certified repository/tool-injection defence. Protocol portability is not compatibility certification. | Concrete missing capability or threat model, with approved harmless tests and controls. |
| P7 Value | Evaluate accepted outcomes, quality, rework and sustained utility—not agent count, survey popularity or generated output alone. | E7 C205-C212: self-selected/vendor-recruited survey trends, not population estimates. C213-C221: short-run field output gains, unresolved persistence and mixed controlled findings; no universal productivity promise. | Owner selects intended outcomes and appropriate observation horizon. |
| P8 Lifecycle/portability | Compare keeping, refitting and replacing components on evidence. Make preservation/recovery/loading tests proportionate to the chosen change. | E5/E6: differing harness loading/truncation semantics; C104 Windows reproducibility/removal remains a gap. Workspace manifest integrity does not establish whole-project recovery. | Approved lifecycle/harness change; source/adapter preservation is not an automatic preference. |
| P9 Public capabilities | Owner requested individual ECC/Hermes/common-source review before selecting revisions/trials. Nine workflow contracts remain an interim evaluation baseline. General writing and cited document reasoning join synthesis, local analysis and frontend design as proposed outcomes; format production and specialists stay optional. G3 selected empty external plugin/MCP defaults (owner, 2026-10-22); RTK is the first named pilot candidate, not installed. | Owner's D10 audience refinement; [topic 16](research/16-public-capabilities.md#individual-public-source-review) records 31 actual source assessments, scoped licenses/helpers and primary documentation. Bundling, repetition and source recommendations do not establish use, benefit, T3 loading or preservation. | G1 is selected as drafting and test fixtures only, no paid trials (owner, 2026-10-22); E2 follows. A pilot needs source review, an adoption record, a budget and install approval. G2 accepted the direct-source/A7 contract and E3 read-only synthetic preview only. Distribution, installation and enablement remain distinct; no new dependency/install is approved. |

## 5. Design synthesis (U5, in progress)

Started 2026-10-02 (UTC) from the reviewed corpus: Passes 4-7 (E4-E7) and the
current claims register, read at corpus commit `5780567`. The reviewed Pass 8
report (E8; corpus tag `archive/2026-10-02-workspaces-08`, commit `1fcbc0d`) was
taken in later the same day: it revises S1's open points and informs S2-S6.
Its s4 maps findings to this register as recommendations. S1 and S2's harness,
roster and generator rows record owner answers; S2's tier and branching rows and
the S3-S6 contents were drafted by the Leader from E8 s4 and confirmed by the
owner on 2026-10-02. Grades are as in the corpus register at that tag. Each entry is
design direction; changing current controls (section 3) needs its own approved
scope; task record (local task record `workspace-design-synthesis/`).

### S1 Shared core plus per-project-type profiles

**Decision.** Workspace is one shared core plus a profile per project type
(coding and research are examples, not a fixed set). Source: the owner's stated
use, "an all-purpose workspace, that can be heavily adapted to fit the specific
project type" (corpus `.sw/comms/tasks/workspaces-08/2026-10-02T000100Z-leader-submission.md`),
and the owner's direction to start U5 with this decision. This is a design
direction, not research-proven superiority over alternatives.

**Layering rule.** A profile adds or narrows; it never loosens core controls.
Where layers conflict, the stricter rule applies to safety, approval, Git and
publication, and to data handling.

| Layer | Contents | Register links |
| --- | --- | --- |
| Core | Authority and approval; change method; Git and publication; task records and handoff; the shape of the validation contract (report exact checks, keep result kinds separate); safety and trust boundaries; cost/data portability policy. | O4-O6, O10, O12-O15; P6 |
| Profile | Validation commands and acceptance outcomes; which skills, context and instructions load; which roles are used; data sensitivity; project-type checks and evaluation cases. | O1, O7, O15; P1, P4, P7; U2 |
| Harness adapter (separate axis) | Per-harness loading files and settings. Not a profile: it varies by harness, not project type. | U1, O16, P8 |

**Evidence and how it shapes S1** (grades as in the current register):

- *Keep the core small; add profile guidance only for observed need.* Ordinary
  context files gave no task-success gain on Python tasks (C112, replicated
  direction, no non-Python study) and grow over a repository's life (C116,
  qualified). Tuned guidance helped one model and hurt another (C114, qualified),
  so profile guidance is per task and model and should be tested, not assumed.
- *Expect compliance to fall over a session.* C115 and C160 (both qualified)
  report declining instruction compliance as sessions lengthen. Hard core rules
  should be enforced by hooks, permissions or validation where available, not
  prose alone (E4 recommendation 3; the vendor advice in E4 s2.2 that
  instruction files are context, not enforcement, is declared only; see S4).
- *Layering semantics differ by harness.* Loading order, concatenation and
  instruction and settings precedence vary (C068, C146, C150, all declared).
  Truncation and silent drops exist (C147, C151, qualified), so each layer needs
  a size budget and loading must be verified from logs, not model answers (C069
  observed; C070 shows loading only; E4 recommendation 2). Cross-harness reading beyond AGENTS.md is declared, not
  demonstrated (C067).
- *Profiles do not imply more agents.* Role choice per profile follows P2: no
  general matched-compute multi-agent gain (C121, replicated direction; C089
  contradicted).
- *Non-code profiles lack outcome evidence.* Skills and shared spaces are
  spreading beyond code (E4 s2.7, declared), but whether knowledge workspaces
  improve non-code outcomes is a gap.
- *The workspace must supply the layering (E8).* No inspected harness documents
  a project-template feature (C233, declared; no template feature found); only Codex has named profiles, as file
  overlays; OpenCode and Claude Code layer by scope only (C233, declared). No
  empirical study of layering was found.

**Open points (revised 2026-10-02 with E8):**

- *Layering mechanism: decided.* A refitted generator produces the layers (S2).
  Inspected harnesses offer no templates, and only Codex has named profiles
  (C233), so the workspace supplies the layering (E8 s4 rec. 7); plain files
  would need hand-syncing per harness. Each layer's
  output must still be mapped to each harness's precedence (C068, C146, C150).
- *Size budgets and loading checks: partly settled.* Profile skills: one to
  three short ones (S6). Core constraints that must survive compaction live in
  files the harness re-injects (S5; C253). Numeric byte budgets per layer and
  harness remain open until the harness is chosen (U1); loading is verified from
  runtime logs, not model answers (S1 evidence above; C069), as a runtime check under U3.
- *Which profiles first, and their acceptance outcomes:* still open (U2). Each
  profile's acceptance cases follow S3.
- *Generic profile and `.sw/profile.json`:* their mapping to S1 is part of the
  S2 generator refit; that migration needs its own approved scope.

### S2 U1 partial resolution: roster, generator, harness criterion

**Historical synthesis (2026-10-02/03), superseded in part by D7/D9/D10.**
The implementation updates, role roster, provider choices and model tiers below
are dated evidence, not current controls. Current U1-U5 are in section 6;
current implementation/authorization is in Startup. Only later approved
decisions retain or replace these individual design points.

**Current implementation update (2026-10-03, workspace-v1):** the
bounded owner approval (local task record `workspace-v1/2026-10-03T063903Z-leader-approval.md`)
now authorizes the launcher, superseding the older "not yet approved" table
wording below without erasing its history or the older uncommitted proposals.
P1 maps actual local worker models, imports canonical root rules with
`@../AGENTS.md` relative to `.claude/CLAUDE.md` (the historical `@AGENTS.md`
draft is not the implemented import), shares Git guardrails, and removes Bash
from the Claude reviewer. P2 provides one manual `sw session start` control
entry: explicit primary model, actual worker map, safe argv, OpenCode `mini`/`run`
or interactive Claude, current-adapter prechecks and immutable metadata events.
Mixed maps do not create cross-harness dispatch; non-Claude Claude commands STOP.
Parser/module and 226 offline assertions pass; native stubs are not runtime
loading, served-model, access, isolation or permission proof. P2 stopped at its
worker usage limit; the Leader reconciled and reran its offline checks. The owner
then selected an existing free OpenCode route and a temporary ignored two-role
map. P3 independent review ran; its variable-assignment finding was rebutted.
Owner accepted the conservative read-only shell-denial/API discrepancy as a known
limitation; no bypass or permission relaxation. P4 engineering artifact/checkpoint,
distinct fresh-session/hash reconciliation, six value/six Int64 tests and final
read-only artifact review passed on the selected headless OpenCode route. Claude
adapter absent; all four live starts used. This does not validate other routes,
interactive use, compaction, security isolation or empirical benefits. Exact evidence
belongs to workspace-v1 records (local task record `workspace-v1/`), not this
design register. The bounded v1 was published through the approved human
integration (push receipt (local task record `workspace-publication/2026-10-03T095714Z-leader-receipt.md`),
hosted-CI closure (local task record `workspace-publication/2026-10-03T100114Z-leader-closure.md`));
that was a dated publication checkpoint, not a current claim about later work.
Git and [state](workspace-state.md) own subsequent publication/implementation.
No broader research-led overhaul is authorized by that implementation.

**Superseded in part (2026-10-15, D6):** T3 Code is now the required app and
the `sw session start` launcher is retired; the launcher statements below are
history.

**Freshness clarification (2026-10-14):** the implementation/status statements
in the following S2 table and decision paragraph are 2026-10-02 checkpoints.
Research + provider-setup selection was implemented later; current scope,
acceptance and publication live in [state](workspace-state.md), not those old
not-yet-scoped labels. They do not authorize redoing accepted work.

| Component | Decision | Evidence and limits |
| --- | --- | --- |
| Harness | **Superseded by D7 (2026-10-15): Claude Code and Codex through T3 Code; OpenCode and the launcher are retired. Kept as 2026-10-02 history.** **Revised (owner, 2026-10-02; decision (local task record `workspace-harness-decision/2026-10-02T213000Z-leader-decision-control-surface.md`)): one control surface and one set of task records replace the one-harness criterion. Claude roles run in Claude Code on a subscription login (owner requirement; third-party subscription use barred, C093, C283); other roles run in OpenCode. Effort is not a requirement. The launcher is implemented and accepted on one route (workspace-v1, above).** Earlier: chosen: OpenCode (owner, 2026-10-02, after the U3 hands-on check; decision (local task record `workspace-harness-decision/2026-10-02T181644Z-leader-decision-u1-opencode.md`)).** On the CLI path, only `-m` selects the primary model; the launcher must pass it. Kilo honours agent models but drops Workspace's V2 config without warning. Earlier: shortlisted (owner, 2026-10-02; E9, E10). Option 2: shortlist **OpenCode** and **Kilo**, then a hands-on check (U3) before choosing. Constraint: the harness must be free / open source, so Cursor, Factory Droid and GitHub Copilot CLI are out; Goose is excluded (models per recipe only, C270; thin evidence). OpenCode: per-agent Claude and non-Claude models (C225, C316); caveats: subagent model-override reports (C226, C319), plugins can defeat rules (C317), no OS isolation on Windows (C256). Kilo: sticky model per agent (C303); caveat: a parent can override the subagent model, fix closed not_planned (C304); Windows not inspected. Licences are not in the corpus: confirm from each repo's LICENSE. Claude still needs a subscription or API key; third-party subscription OAuth is unresolved (C283, C329), recheck at decision time. Owner criterion unchanged: Claude models usable in the same harness as every other model and role. | E8 selects no harness. Claude Code and Codex declare per-agent model and effort (C222, C227); OpenCode passes effort to the provider (C225); Copilot has no effort field (C229). Each of Claude Code, OpenCode and Codex has a report of per-agent routing being ignored (C223, C226, C228). Native Windows isolation: see S4. E8 did not examine which harnesses run Claude models alongside other providers, or the provider terms for doing so. |
| Role roster | **Small.** The Leader works inline by default; core optional roles are a read-only explorer, an independent repository-exploring reviewer (S3) and one executor (merging developer, build, documentation and worker). Research is a profile role, enabled by a research profile (S1). Planning and architecture fold into the Leader. Implemented 2026-10-02 except the research profile role (generator refit). Delegate for context isolation or separable work, not by default. Worktrees are file isolation only: serialize writers or check intended changes before parallel writes. | C234 (declared); C235, C236, C243 (qualified, task-dependent, not compute-matched); C121 (replicated direction); C241, C242 (qualified; C242 a feasibility check). No roster-size study exists. |
| Generator and layout | **Refit.** Model-field part implemented and committed 2026-10-02 (approval (local task record `workspace-harness-decision/2026-10-02T183500Z-leader-approval-generator-refit.md`)): no effort output, `validate` rejects effort and `#variant`, launch rules in `.sw/workspace.md`. One source generates the core, profile and per-harness adapter files (S1 layers). The current SuperWorkspace layout gets no preference. | See S1 open points (C233). Skill and instruction locations differ per harness (E8 note on C067; C068, C146, C150). |
| Tier rubric | **Model-only (owner, 2026-10-02; E9 Rec 2).** Tiers name a model, not a per-agent effort setting; Implemented by the generator refit (2026-10-02; committed). On OpenCode `run` only `-m` routes the primary model, so launches pass it. Whatever routing is configured, verify the model per launch path from runtime logs (S4, U3). | C222 alias caveat (E8 review): a family alias can resolve to the main model. Effort is dropped because neither shortlisted harness declares a usable per-agent effort field (OpenCode `#variant` mapping unstated, C316; Kilo not stated). |
| Branching | Retained (O13). No inspected evidence bears on it, and global/session rules also impose it. | None in E4-E8. |

**Decided:** the harness (U1) is OpenCode for non-Claude roles and Claude Code for Claude roles under one control surface (revised 2026-10-02); OpenCode was chosen after the hands-on check under U3
(task (local task record `workspace-harness-decision/`)). Corpus
Passes 9 and 10 (E9, E10) closed the research; no harness was run hands-on. The
roster reduction was approved and implemented the same day
(task (local task record `workspace-roster-refit/`)); `project-research`
becomes a profile role in the generator refit, which emits model fields per
harness and no effort fields (model-field part implemented and committed
2026-10-02); the research profile role is not yet scoped.

### S3 Review and acceptance tests

**Decision.** Use an independent review step for weaker executors and hard,
non-local tasks, with a reviewer that explores the repository rather than
reading only the diff. Budget its token cost and judge it by accepted outcomes,
not review activity (P7). Test configuration changes (instructions, skills,
roles, routing) like small evals: 10-50 cases from real failures (report s4 wording); deterministic
outcome or trace checks first and LLM rubrics only for qualitative checks, with
the judge calibrated (P4); negative controls for skill triggering; several
isolated trials; graduated cases kept as a regression suite.

**Evidence.** Review loops raised SWE-bench Verified resolve rates over
no-review baselines, with gains shrinking as the generator strengthens and a
reviewer stronger than every generator; about 4.5x zero-shot tokens in one
study (C237, qualified, one benchmark lineage). Repository-exploring review beat
diff-only review (C238, qualified). Agent PRs reviewed only by review agents
merged less often than human-reviewed ones (C240, qualified, observational).
The eval practice is vendor and practitioner guidance (C259-C262, declared);
run variance is measured (C167).

**Limits.** No equal-compute baseline for review loops. Whether such suites
catch configuration regressions is unmeasured (C108 gap). This revises O14's
"planned review runs automatically" only once an approved change says so.

### S4 Enforcement and isolation

**Decision.** Hard core rules go in enforced controls (settings, deny rules,
permissions, sandboxes) where the harness has them, not in prose. On Windows,
a hook is not a path boundary until a local acceptance test shows a denied write
is blocked. Shell-pattern denylists are guardrails, not isolation. Claude Code
plugin subagents have documented tool restrictions, with field exclusions
detailed below; tool restrictions do not establish OS isolation. Native Windows
OS isolation is a comparison factor for the harness research question (S2 Open),
not an owner criterion.

**Evidence.** Vendors declare instruction files advisory and settings, deny
rules, hooks or sandboxes enforced (C230, declared). One Windows desktop report
measured a PreToolUse hook exiting 2 while a subagent write still happened
(C258, qualified, one report, not vendor-confirmed). Denylists were bypassable
in 69.0-98.6% of cases by bypass class (C257, qualified, secondary relay).
Claude Code's [subagent documentation](https://code.claude.com/docs/en/sub-agents)
says plugin subagents ignore `hooks`, `mcpServers` and `permissionMode` (C224,
declared), while `disallowedTools` removes tools. Its
[changelog](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)
records `disallowedTools` support for plugin-shipped agents. These are
source/version-specific vendor declarations, not universal runtime proof.
OpenCode ships no OS isolation and allows all in-project actions by
default (C256, qualified); Claude Code's sandbox needs WSL2 (C231). Of Claude
Code, OpenCode and Codex, only Codex declares a native Windows sandbox (C231,
C254); its unelevated fallback limits network only advisorily (C255). A source
survey of 11 harnesses also finds Gemini CLI (C256, qualified).

**Implemented (2026-10-02, committed; owner-approved "harden git rules"; runtime test deferred to workspace completion).**
The generated shell rules now also catch the git/gh prefix bypasses found in the
generator refit review: global flags (`git -C`), compounds, rtk runners, wrappers
(as asks), and `project-review` operator chaining. Checked statically only (618
matrix cases), not at runtime; see the closure (local task record `workspace-harness-decision/2026-10-02T200000Z-leader-closure-git-hardening.md`).
The guardrail limit stands: `$(...)`, wrappers behind a compound and scripts
written to a file still get through.

**Limits.** No shared-attacker comparison of isolation and access control (C102
gap). The hook test and the routing checks (S2 tier row) are runtime work under U3, each needing
its own approval.

### S5 Continuity and compaction

**Decision.** Constraints that must survive compaction live in files the
harness re-injects (its root instruction file) or in task records, not only in
conversation. Keep the task-record, progress and Git pattern. Measure
continuity changes by interaction cost as well as completion. No memory service
is added (P5 stands).

**Evidence.** Compactors kept 17% of conversation-only constraints on average
(C251, qualified; not a shipped harness). Claude Code re-reads project-root
CLAUDE.md after compaction while conversation-only instructions can be lost
(C253, declared). Anthropic's long-running pattern of progress file, JSON
feature list and Git matches the existing records (C250, declared, one demo).
Compression raised interaction cost while completion stayed unchanged (C252,
qualified). No memory substrate dominates (C078 stays contradicted).

**Limits.** No controlled evidence that task records or handoffs improve
continuity (C079 gap). Re-injection is documented here for Claude Code only;
Codex and OpenCode compaction docs were not inspected, and retention in a
shipped harness is untested.

### S6 Skills curation

**Current qualification (2026-10-20):** this earlier short-profile proposal
does not settle the tension with the shipped workflow set or topic 16's
provisional catalogue. G1 is selected as drafting and fixtures only and G3 as
empty external defaults (owner, 2026-10-22); E2 drafts the catalogue. No skill
count or catalogue change is inferred from S6.

**Decision.** Each profile gets one to three short, human-curated skills. No
auto-generated skills and no exhaustive procedure. Each skill is tested with
paired with/without runs on the profile's acceptance cases, including negative
trigger controls (S3). The generator emits skills to each harness's location
(S2).

**Evidence.** Curated skills raised mean pass rates across 18 model-harness
configurations (C244, qualified). One to three compact skills did better than
four or more or comprehensive docs; self-generated skills fell below the
no-skills baseline (C247, qualified). Excess procedure caused most efficiency
regressions (C248, qualified). Some skills lower success (C246, replicated
direction); the software-engineering gain is contested in magnitude (C245,
contradicted); token overhead ranged up to +451% (C249, qualified). Skill
directories differ per harness (E8 note on C067).

**Limits.** Mostly one benchmark family; the contrary SWE result used one small
model. No study of non-code profile skills.

Qualification (2026-10-19 research, not a revised owner decision): the bundle
ablations above do not establish a maximum installed/distributed library size.
Newer saved practice guidance describes selective use of a much larger library,
without controlled product-efficacy evidence. [Topic 16](research/16-public-capabilities.md#f3-useful-skills-are-task-specific-a-numerical-library-cap-is-unproven)
proposes a shared default and task/trigger checks; catalogue selection must
explicitly reconcile this guidance with O7's existing common procedures.

## 6. Assumptions and decisions still open

| ID | Unresolved assumption / decision | Source / limit | Resolution trigger |
| --- | --- | --- | --- |
| U1 | Which deeper structural changes improve representative tasks? | D7/D9 retired the role roster, OpenCode and launcher; D10 selects Windows/T3/central tiers. E3 is read-only only. File size and generated copies alone do not establish over-engineering. | D12 selects four read-only traces and concrete alternatives first; code/layout or catalogue changes need their own selected scope. |
| U2 | Which individual skills, plugins and MCPs should ship publicly? | D10 selects a general foundation with research and development equally default. Topic 16 reviewed 31 ECC/Hermes skills; recommendations are not measured use or outcome gains. | G1 drafting/fixtures (no trials) and G3 empty external defaults were selected 2026-10-22; catalogue contents come from E2. No comparison or trial budget is selected. |
| U3 | Which native loading, routing, enforcement, resume and runtime claims remain unverified? | Bounded rebuild scratch checks and the owner's T3 script checks have explicit limits in Startup. E3 synthetic tests establish no real delivery/native loading; memory loading, compaction, fresh-user and no-console behavior remain unverified. | Separately selected G4/native scope with named targets and evidence; do not resume retired OpenCode diagnosis from historical rows. |
| U4 | What recovery, migration and removal behavior is demonstrated? | D11/A7 preserves installed global edits; E3 adds strict reading and pure preflight only. Project managed blocks/Adopt retain the recorded gap. Independent recovery and central effects are not demonstrated by Git history or memory backups. | E4-E6 scoped implementation, G4 acceptance and G5 named adoption/publication. D12's local archival/memory backups are bounded evidence preservation only. |
| U5 | Which research/design assumptions need renewed synthesis? | D1/D2 keep all components reconsiderable. S1-S6 are dated synthesis, partly superseded by D7/D10 and topic 16; they do not constitute a complete updated comparison of all alternatives. | D12 task traces first; scope any deeper synthesis around concrete outcomes and current evidence rather than replaying retired architecture. |

### Historical U1-U5 rows (pre-cleanup 2026-10-20)

Retained verbatim as dated design history; the current rows above supersede
their present-tense status and next actions.

| ID | Historical question | Historical evidence | Historical next action |
| --- | --- | --- | --- |
| U1 | Whether to retain, refit or replace SuperWorkspace, OpenCode, the role roster, file layout, tier rubric or branching model. | Existing implementation plus D1/D2; no inspected comparative evidence establishes these as the best architecture. | Evidence-led design proposal and owner decision, not inheritance. **Partly resolved 2026-10-02 from E8 (S2):** small roster and generator refit decided (owner); tier rubric held with the harness and branching retained (owner-confirmed). **Further resolved 2026-10-02 from E9 and E10 (S2):** option 2 chosen (owner): shortlist OpenCode and Kilo under a free / open-source constraint, then a hands-on check; tier rubric is model-only, no effort. **Harness resolved 2026-10-02:** OpenCode (owner), after the U3 hands-on check of OpenCode and Kilo (decision (local task record `workspace-harness-decision/2026-10-02T181644Z-leader-decision-u1-opencode.md`)). |
| U2 | Intended workloads, data sensitivity, acceptance outcomes, cost/effort limits and target harnesses. | O1 is broad; no application workload was selected by this task. | Owner clarification when it materially affects a design choice; not a prerequisite to documenting research. |
| U3 | Actual runtime loading, routing, enforcement and resume behavior. | Workspace setup was statically checked; doctor has a recorded launcher failure (2026-10-01, not rechecked); an ignored local map selects developer/reviewer only. The headless OpenCode route passed bounded live acceptance in Workspace on 2026-10-03 (`workspace-v1/`); Claude, interactive and mixed routes and compaction remain unchecked. Routing and enforcement of OpenCode 2.0.20 and Kilo 7.8.3 were checked in scratch projects on 2026-10-02 (task (local task record `workspace-harness-decision/`)); a bounded fresh-session resume reconciliation passed on the headless OpenCode route only (workspace-v1); instruction loading beyond that, resume on other routes and compaction remain unchecked. | Separately approved diagnosis/runtime checks. CLI repair is not a mandatory precursor to design work. |
| U4 | Independent recovery baseline and migration/removal requirements. | Workspace history is committed and published to `origin` (2026-10-03, publication (local task record `workspace-publication/`)); corpus same-disk backup is not independent recovery. Full lifecycle preservation has not been demonstrated. | Owner chooses recovery/migration scope; no automatic commit, backup, cleanup or removal. |
| U5 | Complete updated design synthesis across the research corpus. | Earlier outline used an incomplete Pass 7 snapshot. This phase inventories rules and selected implications; it does not compare every design alternative or audit all originals. | A separately scoped synthesis/design task using current report/register/review evidence. In progress since 2026-10-02: S1-S6 recorded and owner-confirmed in section 5 (S2-S6 and the revised S1 open points from E8). |

## 7. Research provenance and freshness

**Operational checkpoint clarification (2026-10-14):** U3's 2026-10-01 doctor
failure is historical; later configured-machine acceptance recorded a pass,
not fresh-user/platform assurance. U4's 2026-10-03 publication checkpoint is
also dated. [State](workspace-state.md) and Git own current facts; the U rows
retain their research/verification limits, not an automatic execution queue.

**Source:** private research corpus (not redistributed), read-only in
this task. Locators are not Workspace paths or redistributed evidence.

| Ref | Source in the private research corpus (not redistributed) |
| --- | --- |
| E4 | Pass 4 workspaces report, sections 2.1-2.11 and 4 (analyst recommendations, not rules); reviewed and closed. |
| E5 | Pass 5 workspaces report, especially sections 2.1-2.7; use current claims-register notes rather than frozen grades alone. |
| E6 | Pass 6 workspaces report, sections 2.1-2.6; later corrections are in the claims register and the Pass 7 review. |
| E7 | Pass 7 frontier-breadth report, sections 2.1-2.6; reviewed and closed. |
| E8 | Pass 8 workspaces report (archived), sections 2.1-2.5 and 4 (analyst recommendations, not rules); reviewed and closed. |
| E9 | Pass 9 harnesses report (archived), section 3 options table and section 4 Recs 1-8; claims C263-C291. |
| E10 | Pass 10 harnesses report (archived), section 3 options table and section 4 Recs 1-9; claims C292-C330. Summarized for the owner in a local handoff record. |
| Register | Claims register; reviewed Pass 7 adds C163-C221, reviewed Pass 8 adds C222-C262, and Passes 9-10 add C263-C330, each with dated notes on earlier claims. |
| Broader context | Initial-pass overview, cross-dossier synthesis, AI-research foundation, frontier-depth-03 and the cumulative AI-engineering landscape; earlier outline source map is historical navigation, not a refreshed synthesis of these files. |

The [v0.2 reference](workspace-outline-v0.2.md) remains the historical outline
authored from the 08:50:45 UTC snapshot and 09:03 UTC recheck on 2026-10-01.
Its preliminary Pass 7 status and preserve-base premise are not current design
authority. The corpus now records reviewed closure at **19:15 UTC**, including
corrections narrowing C173 and qualifying C190. The frozen report's pending-review
header is stale; the review/closure and current register govern that status.

This documentation phase read local reports and review/closure records, not all
original studies or private data inputs. It ran no new research, source
audit, corpus integrity checks or Workspace runtime tests. Corpus reported checks
are not checks performed here. Independent review did not read every source;
prices C194-C195 remain unchecked by that review, and several dates/published
versions and manifest locators remain unresolved. Older archive/review limits
are retained in the historical reference and current corpus records, not certified
away by this document. Evidence remains local-only/no-redistribution.

## 8. Next action and change discipline

The three owner requirements are now the design direction. Current controls are
visible and revisable; provisional implications and unresolved choices are not
implementation approval. No compulsory keep-kit/readiness/expansion sequence is
adopted. Any next task needs its own outcome, scope, ownership and acceptance.

When evidence or owner direction changes a shaping rule/assumption, update its
entry, explain what it supersedes, and align the actual controlling files within
the approved scope. Keep historical evidence distinguishable from current policy.
For the design synthesis (section 5), assess retain/refit/replace on equal footing rather
than requiring changes to preserve the inherited kit.
