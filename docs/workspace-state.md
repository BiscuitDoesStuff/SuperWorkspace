# Workspace state

## Startup

Observed 2026-10-25 UTC. Read this section for current state and authorization;
use the linked evidence only when the task needs it.

- **Identity and authority:** this is the development checkout of the public
  SuperWorkspace product; the owner's private instance is a separate remote.
  Design is research-led and every component is revisable on evidence.
  [Design register](workspace-outline.md) owns requirements and assumptions;
  `AGENTS.md` and `.sw/workspace.md` own operational rules. Git owns branch,
  ancestry and publication facts. Historical plans are not an execution queue.
- **Implemented:** kit 0.4.0-dev, research profile, Windows PowerShell 5.1 and
  PowerShell 7; Claude Code and Codex through T3 Code. The role roster,
  OpenCode launcher/adapter and parent manager are retired. Sources are
  `project/`, `lib/`, `global/` and `sw.ps1`; `.sw/manifest.json` identifies
  generated definitions. This checkout uses GitHub tier 2 and local records.
  Docs-only work may commit on main; code uses a T3 worktree and PR. A human
  publishes main. Product work is public-first: a `t3/` pull request to
  `origin`, then a merge of `origin/main` into private `main` (outline O13).
  Latest public publications are origin PR #2 (47a98b4, public-first
  publication flow) and PR #3 (eca549e, central rules delivery E5 and revised
  skill drafts E2); `origin/main` was merged into private `main` after each.
- **Accepted baseline:** the rebuild, A7 global preservation, Windows/both-shell
  runtime, native UTF-8 fix, CI local fallback, explicit owner commands, all
  six audit fixes, central delivery E3, E2 (catalogue drafts and fixtures) and
  E5 (central rules blocks written with per-artifact receipts, tested in
  temporary homes) are integrated. Central skill links and project migration
  are not implemented. Global rules were installed in the owner's existing
  harness homes on 2026-10-18; that observation does not authorize further
  deployment.
- **Product audit closed (2026-10-22 UTC):** private-instance PRs merged P1,
  P2, P3a/P3b, P4 and the D1b/D1c prompt-time freshness repair; D1d documented
  the recovery and stale outcome in [setup](setup.md). Hosted Actions are
  disabled on the private repository, so the local gate in `AGENTS.md` Git
  applies and the owner merges. Remaining audit items moved: D2a (native
  checks) to G4, D2b (trials) waits for a selected trial budget, D2c waits for
  both, and E2-E9 stay with the central delivery plan. A local task record
  holds the evidence.
- **Selected direction and gates (owner):** D10/D11 select central product plus
  personal sources with preservation; D13 makes the public repository the
  template. G1 is drafting and test fixtures only, with no paid trials. G3:
  research is built in (changed from opt-in, 2026-10-24); external plugin/MCP
  defaults stay empty; RTK stays an opt-in pilot needing source review, an
  adoption record, a budget and install approval. G4 native acceptance is
  decided after E6 and absorbs template Q8; G5 adoption/publication is decided
  once E8 exists. Template Q2-Q9 were decided 2026-10-24 and the P0 product
  contract approved 2026-10-25, keeping structured-debugging and
  agent-documentation as defaults (outline D13). Each template package P1-P6
  needs its own scope approval. [Roadmap](central-delivery-roadmap.html) is
  the visual view.
- **Next:** E4 (individual central skill links: apply/check/remove) is in
  progress in a public-first worktree thread. E6 (project migration, including
  the D1c move/stale-replacement cases) follows once E4 is published, then the
  G4 decision, then E7-E9.
- **Evidence limits:** E3 and the audit prove no real delivery, migration,
  recovery effects or native loading (G4). E5 rules effects are proven only in
  temporary test homes: no real-home delivery followed the 2026-10-18 install
  observation, and nothing proves native loading. Earlier bounded scratch
  checks do not prove every real checkout, fresh-user behavior, compaction,
  security or harness version. Group Policy blocking Bypass, a real no-console
  parent, the file-symlink test skip and native memory loading remain
  unverified. No probes, installations, sibling redeploys, global settings,
  corpus edits or public publication are authorized by research or proposals.
- **Records:** task records are ignored/local under `.sw/comms/tasks/` and
  `.sw/comms/archive/`; dated evidence below preserves earlier checkpoints.

## History (dated checkpoints)

### Superseded Startup (preserved 2026-10-25 UTC)

The 2026-10-22 Startup (Q2-Q9 and P0 open, E2/E5 next, latest publication
origin PR #1) is superseded by the Startup above.

### Superseded Startup (preserved 2026-10-22 UTC)

The 2026-10-20 Startup (product-audit execution selected, code worktrees
awaiting publication) is superseded by the Startup above.

### Superseded Startup (preserved 2026-10-20 UTC)

The following is the verbatim pre-cleanup Startup. Its task locators and next
actions describe that revision; current authorization is above. Completed
records subsequently moved to the archive with their full trees preserved.

## Startup

- **Identity / sources (owner, 2026-10-05):** development checkout of the public
  SuperWorkspace product, research-led; every
  component is reconsiderable on evidence. The owner's private instance is a
  separate remote, configured locally; its adaptations may be upstreamed here.
  Decision (local task record `workspace-repo-split/2026-10-05T181851Z-owner-decision.md`). Design rules/assumptions:
  [outline](workspace-outline.md). Operational rules: `AGENTS.md`,
  `.sw/workspace.md`, `.sw/collaboration.md`. Git owns ancestry/publication facts.
- **Implemented (2026-10-16):** kit 0.4.0-dev, research profile, Claude Code
  and Codex through T3 Code. The four-role roster, OpenCode launcher/adapter
  and product root manager are retired. Sources and generated definitions
  follow `AGENTS.md`; current Git, review and permission rules are in
  `AGENTS.md` and `.sw/workspace.md`. This checkout is GitHub tier 2 with
  workspace Git policy and local records. Local `main` tracks the private
  instance's `main`; Git owns branch, ancestry and publication facts.
  Publication to the private instance does not publish to the public `origin`;
  `origin` receives one squashed commit per approved publication (latest:
  2026-10-18, merged in origin PR #2 after hosted CI passed on both
  Windows shells; `main` merged it back).
- **Rebuild checkpoint (closed 2026-10-16, published 5465219): `t3-native-rebuild`.**
  Kit 0.4.0-dev (breaking) is on the private instance's `main`: Claude Code and Codex
  through T3 Code, D9 Git flow (tier 2 here), generated Claude denies and
  Codex forbidden rules for the hard limits. Acceptance M7 (closing summary:
  local `archive/t3-native-rebuild/SUMMARY.md`), with each kind of evidence
  kept separate:
  - Offline: full Pester 371/0/1 (symlink-privilege skip); `sw validate`
    PASS with 972 static hard-limit checks.
  - Review: Codex review rounds 1-7 (round 4 on Claude, the owner's choice
    during a provider quota stop); round 7 found nothing.
  - L6: a read-only two-agent Workflow through a provider routing proxy passed.
  - L5: Claude Code and Codex through a provider routing proxy in a scratch
    project, Supervised, Auto and
    Full access. Every rule decision matched the static model. Model-based
    Auto refusals were inconsistent and are not counted as enforcement.
    Codex ran its gap spellings silently in Full access.
  - CI: run 38869117248 at 5465219 passed on both OSes, Pester 372/0/0. It
    had been failing on the private instance's `main` before this task's fixes.

  Owner decisions:
  - M7 decisions 1-18: local task record; outline O2, O12 and O13.
  - Decision 15: the gap and over-block tables are accepted as the baseline.
    Supervised is not used; threads run Auto or Full access, and the gaps rely
    on agent restraint.

  Open: sibling redeploys (each needs approval); the scratch project
  `t3-live-check` and its bare origin stay in the system temp directory until
  the owner removes them. The tab-before-flag Claude patterns are verified
  statically only.
  Background: owner decisions D6-D9 in the [outline](workspace-outline.md);
  research topics [11](research/11-t3-agent-architecture.md),
  [12](research/12-workflow-methods.md) and [13](research/13-agentic-leverage.md).
- **Current scope:** the rebuild is closed. Task `product-direction` (owner,
  2026-10-16) set D10/D11 and research topic 15. Its one implementation
  package, the A7 baseline for `sw global`, merged in PR #3 (CI Pester
  432/0/1 on Windows and Ubuntu). The D10 runtime package also merged:
  Windows-only in PR #4, then Windows PowerShell 5.1 plus PowerShell 7 in
  PR #5 (local Pester 445/0/1 and CI green on both shells; Claude-only
  review, approved by the owner). A small approved fix merged in PR #6:
  `Invoke-SwNative` now reads native stdout as UTF-8 for each process,
  so repository paths with non-ASCII characters work on both shells (local
  Pester 452/0/1 and CI green on both shells; two Codex review rounds,
  approved by the owner). Follow-up checks (2026-10-18): `t3.json` scripts
  run from T3 Code passed (owner; Context report run from a terminal);
  Group Policy overriding `-ExecutionPolicy Bypass` is documented in
  `docs/setup.md`, not live-tested; a real parent process with no console
  attached remains NOT VERIFIED. PR #7 removed private details before
  publication (Codex audit rounds 1-3, local Pester 452/0/1 on both shells;
  merged without hosted CI under a one-time owner exception). Task `ci-minutes` (owner, 2026-10-18) merged
  in PR #8 (8445bfe): CI runs once per pull request revision and skips
  drafts, `ci.yml` skips `docs/**`, and a standing local-gate fallback
  applies when hosted CI cannot run for a quota or billing reason, or
  (2026-10-22) because Actions is disabled; the owner merges where
  auto-merge is not allowed (local
  Pester 454/0/1 on both shells, Codex rounds 1-2; hosted CI skipped under
  the local-gate fallback). Task `owner-commands` (owner, 2026-10-18) merged in PR #9
  (e23b700): an `AGENTS.md` Authority rule that any action handed to the
  owner comes as exact copy-paste commands that run from any directory
  (local Pester 455/0/1 on both shells, Codex review clean; hosted CI
  skipped). Task `global-owner-commands` (owner, 2026-10-18) merged in PR
  #10 (64e28a0): the same rule in the kit's `global/rules.md`, shipped hash
  recorded (local Pester 455/0/1 on both shells, Codex review clean; hosted
  CI skipped); the owner installed it with `sw.ps1 global install`. Task
  `publish-origin-2` (owner, 2026-10-18) published private-instance PRs to `origin`
  as one squash in origin PR #2 (Codex audit rounds 1-2, billing
  details removed first; local Pester 455/0/1 on both shells in a
  simulated public clone; hosted CI green on both shells). Additional
  authorized slices are recorded below. The main
  thread coordinates, with code fixes in T3 worktree threads and pull
  requests; docs-only work may commit on `main`. A human publishes `main`;
  tier-2 thread publication follows `AGENTS.md`.
- **Audit (closed 2026-10-18):** an owner-approved audit reviewed
  code/tests, docs/instructions and research/direction: six confirmed findings
  (three P2, three P3; no P0/P1 identified), with final report review complete.
  Both Windows shells passed Pester 455/0/1; workspace/link validation and
  disposable regeneration passed. One file-symlink case was skipped; no new
  manual UI, live permission, fresh-user, no-console or hosted CI checks were
  performed. Report and proposed fix packages are kept in a
  local task record. No fixes were made during the audit;
  the separately approved implementation is recorded below.
- **Audit fixes (closed 2026-10-18):** an owner-approved fix task
  resolved all six confirmed findings in a private-instance PR.
  Archive/close operations validate participating paths before effects (F1);
  closing authors resolve as From, User, then configured fallback (F2);
  init/update CLI processes propagate partial failure status (F3); requested
  native RTK installation failures survive diagnostics (F4). The design
  register records completed parent-manager removal (F5) and qualified
  plugin-subagent field/tool restrictions (F6). Generated definitions were
  refreshed through the existing generator.
  Both Windows shells passed full Pester 478/0/1 at the reviewed candidate;
  all 23 new regressions and disposable fresh-install checks passed on each.
  Static/link validation and regeneration passed; independent Codex review
  found no actionable defects. Hosted jobs never started, so integration used
  the standing local gate with exact evidence in the PR and local task record.
  Main received the merge by fast-forward; its tree matched the tested
  candidate. The existing file-symlink privilege case remained skipped;
  all new junction cases ran. No new manual UI, live permission, no-console
  or real RTK installation check was performed. Public `origin` is unchanged;
  optional clarifications and unverified audit hot spots remain outside scope.
- **Evidence limits:** the accepted checks do not establish comprehensive
  security, compaction, other-user/fresh-user behavior or every harness/tool
  version. The earlier audit's OpenCode N3 criterion was owner-deferred, not
  completed; its historical record is preserved below. Live checks in a
  scratch project do not prove native loading in every real checkout.
- **Next planning view (2026-10-19 UTC):** the owner requested a durable
  [visual roadmap](central-delivery-roadmap.html) for central skills/rules
  delivery and unresolved implementation choices, extended with public
  skill/plugin/MCP selection in [topic 16](research/16-public-capabilities.md).
  The owner selected a general foundation with research and software development
  equally included by default as the target audience. The owner then requested
  individual skill reassessment before catalogue selection. Topic 16 and P1 now
  propose four kept common contracts, five revisions before common selection,
  optional agent-documentation/Unreal and three priority outcome comparisons
  (synthesis, local analysis, frontend design). The provisional nine supersedes
  the unselected ten-default proposal; shipped defaults remain unchanged.
  Research and roadmap documentation are authorized. The prior
  audit-fix closure commit is published (Git owns publication facts).
- **Execution planning (owner, 2026-10-19 UTC):** a detailed plan is
  prepared in a local task record, with E0-E9
  packages, file ownership, source/catalogue and delivery-contract gates,
  preservation/recovery cases, both-shell checks, native acceptance and scoped
  adoption/publication. The roadmap maps those packages to P1-P3/C1-C5/M1-M6.
  The owner approved E0/E1 evidence and contract preparation. E0 inspected pinned
  frontend/data instructions and scoped licenses, plus a concrete synthesis
  method; [topic 16](research/16-public-capabilities.md#f8-exact-candidate-sources-narrow-the-proposals)
  records findings and limits. E1 prepared commands, strict A7 record extension,
  state/action outcomes and explicit project-copy coexistence/migration.
  The local task now contains source receipts, 14 comparison case pairs and a
  concrete G1/G2 brief. No candidate trial, source/default revision, link/rule
  installation, project migration or native acceptance ran in this slice.
  The owner then directed G1 to review individual public common skills from
  ECC, Hermes and source documentation before selecting revisions/prototypes
  or model comparisons. G2 accepted the reviewed direct-source/A7 contract
  and authorized E3: strict schema handling, pure state/action planning and
  read-only CLI preview in synthetic homes, in one T3 worktree. E3 creates no
  links, replaces no rules and performs no project migration, real-home
  discovery or deployment. The E3 checkpoint below records implementation
  evidence.
- **G1 individual-source review (2026-10-19 UTC):** [topic 16](research/16-public-capabilities.md#individual-public-source-review)
  now records 15 ECC and 16 Hermes skills against actual pinned instructions,
  selected helpers/licenses and primary documentation. Four new external
  requests saved source bodies; no imported skills, installs or candidate
  trials. Most development techniques fit existing procedures. General
  writing and cited document reasoning join synthesis, local analysis and
  frontend design in the next comparison proposal; format production and
  other specialists remain optional candidates. Bundling/source advice is
  not measured public use or benefit. The earlier 28-run proposal was not
  selected; source findings change the next G1 proposal, not shipped defaults.
- **E3 read-only preflight (completed 2026-10-19 UTC):** a private-instance PR
  adds strict schema1/schema2 reading, in-memory legacy normalization and
  opt-in `central-v1` planning/check/WhatIf previews through the existing global
  CLI. Shared ownership remains independent of desired selections. Preflight
  protects current and recorded sources, including unselected canonical skill
  containers; valid sibling paths remain allowed. Central mutation is refused
  before effects. Both Windows shells passed full Pester 556/0/1, with all
  78 E3 cases passing per shell; the existing file-symlink privilege case was
  skipped. Fresh generic/research/Unreal, regeneration parity, workspace/link
  validation and independent review passed. Hosted jobs never started, so
  integration used the documented local gate; main received a fast-forward
  whose tree matched the tested candidate. Native loading, real delivery,
  migration, races and recovery effects remain unverified. No central links,
  rule writes, installs or public-origin publication occurred.
- **Next action:** review the requested structure/memory audit in a local task
  record and select any bounded simplification
  scope, alongside revised G1 drafting/fixture selection in
  the central delivery plan. The initial audit records stale memory,
  context growth and current/history ambiguity; no restructuring or memory
  repair is selected. Skill revisions and model comparisons still need scope.
  G1 trial scope/budget, G3 catalogue/defaults, G4 native acceptance and G5
  adoption/publication remain unselected; E4-E6 effects await their selected
  scope and dependencies. The audit-fix and E3 PRs exercised ready-for-review triggers
  without hosted execution at their checked revisions. The global rules are
  installed in the
  Claude `.claude` and Codex homes (2026-10-18, verified). Further implementation,
  sibling redeploys, root-manager changes, new live probes, installs, global
  settings or public publication need their own approved scope. Existing
  historical tasks and proposals are not a queue to resume automatically.
- **Task records:** `.sw/comms/` is local-only in this checkout (gitignored since
  2026-10-05). The owner replaced public `origin` history on 2026-10-22 with
  one commit of the then-public tree, so it holds no earlier records; `main`
  shares no ancestry with `origin/main`.
- **History:** [dated checkpoints](#history-dated-checkpoints) below and task
  records under `.sw/comms/tasks/` hold evidence and qualifications; they are
  not current authorization.



Dated context moved from Startup unchanged; Startup above supersedes it. Approvals
here are task-specific and cannot authorize new work.

### Superseded Startup context (moved 2026-10-16)

The following paragraphs are preserved verbatim from Startup at `5aeafac`.
Their ownership, limits, version and next-action statements describe earlier
tasks; they are historical evidence, not current instructions or approval.
The current Startup and `AGENTS.md` govern execution.

- **Implemented baseline (reconciled 2026-10-11):** research + provider-setup,
  GitHub tier 0, solo `main`, four-role roster, profile selection, context recovery,
  launcher/adapter and manager source are committed in the audited `bd5dc48`
  baseline. Live public `main` was verified at that SHA during the adoption audit;
  prior local/unpublished Startup labels are superseded, not missing work to redo.
  Local `main` tracks the private instance's `main`; Git owns subsequent branch/publication facts.
  This checkout keeps legacy workspace Git policy and its existing local records.
- **Unverified:** only the headless OpenCode route passed live acceptance
  (workspace-v1). Claude/interactive/mixed routes, compaction, other users,
  comprehensive security, live manager planning/routing, native loading in this
  real checkout and runtime permission enforcement are untested; static/offline checks do not prove
  them. Since 2026-10-16, M7 live checks L5 (hard-limit rules under Claude Code
  and Codex through a provider routing proxy, scratch project) and L6 (Workflow) passed, as recorded in
  the last-task bullet; they cover only those probes and one version of each
  tool. Do not retry, bypass or relax the one accepted read-only Git denial.
  Configured-machine `doctor` passed at audit time; this is not fresh-user proof.
  Hosted automated acceptance at published ddd2c65 passed on 2026-10-12: both
  OSes Pester 334/0/0, fresh installation, session 307 and manager 89 assertions;
  separate sw-validate passed. These are static/stub checks, not live assurance.
- **Accepted adoption delivery:** owner approved public-adoption-audit P0-P4 fix plan and MIT,
  preserve-host integration, local new records and human-enabled GitHub private
  reporting choices (2026-10-11). Development-only implementation acceptance is
  complete at published ddd2c65; human push and hosted results verified 2026-10-12.
  Git owns subsequent commit/publication state. Implemented scope:
  baseline/preflight repairs, policy/privacy compatibility, public setup/support
  docs and offline acceptance. Sources/copies are consistent; follow-up full
  CI-mode Pester 5.6.1 passed 333/0 failed/1 file-symlink privilege skip, with
  offline/static checks recorded locally. Owner explicitly waived independent
  review (not performed) and chose development-only delivery on 2026-10-12.
  GitHub recognizes MIT; the private-reporting entry and requested About/setup
  homepage/topics are verified. No stable release or broader runtime readiness.
  Owner requested continuation of delivery steps 2-5, including a local commit;
  pushes/settings/metadata/releases remain human-owned. Native/platform/account/
  root/other-project work is not authorized. Old S3-S6/R4-R6 remain proposals.
- **Last task (closed 2026-10-15, committed b252c19): `t3code-adoption`.** Owner
  decision D6 ([outline](workspace-outline.md)): T3 Code is the required app
  (personal and public); `sw session start` launcher retired; workspace Git
  policy uses `main` plus T3 Code `t3/<name>` thread branches. Kit redeployed
  to sibling projects; static checks only. Open owner decisions: live T3 Code
  acceptance (separate approval), redefining or closing the audit's N3 headless
  route (it used the retired launcher), and a kit `t3.json`. Local archive
  `t3code-adoption/SUMMARY.md` owns evidence.
- **Previous task (committed 2158213):** owner accepted `workspace-comprehensive-audit`
  local R1-R4 repairs with their recorded static/stub limits and non-independent
  review. Full plan v14 and the latest N2 result own stable E01-E17 endpoints,
  review/change control
  and first R5 implementation/offline-validation approval. Selected scope: core
  lifecycle, one headless OpenCode route and explicit Context7 opt-in; native
  acceptance target 2.0.29; temporary artifact and authenticated foreground
  API version/PID verified. Owner accepted the two final no-model cells:
  expected kit
  definitions loaded after bounded warm-up, default MCP empty, explicit
  opt-in Context7 connected. All owned test processes stopped. Earlier401
  and premature built-in-only snapshots retained as failed test prerequisites,
  not kit defects. No product compatibility rewrite needed for these cases.
  This installation's
  Context7 choice is explicitly enabled; fresh installs omit it without opt-in.
  First R5 opt-in implementation/regeneration/offline checks and non-independent
  review are owner-accepted with their limits. The bounded native procedure is
  approved within its prerequisites. Owner chose one temporary official Windows
  artifact download; PE-x64 identity and `--version`2.0.29 passed without an
  install/PATH/shared-service change. Approved metadata preflight verified5
  synthetic roots; after inherited participants were found, owner approved an
  outside-home synthetic fixture and no-model cells. Legitimate generated
  test credential was handled in memory only by the runner; no private
  credential read. Owner deferred N3; headless model/provider/access/cost choices
  remain unset and its selected criterion remains incomplete, not removed.
  Native loading/connection observations do not prove headless work, actual
  permission enforcement, compaction or documentation-query functionality.
  Exact current evidence:
  full Pester392/0/1 known privilege skip before two added review controls;
  latest affected103/0/0 skipped/292 not run, 395 discovered. Launcher307 and
  manager103 static/stub assertions pass; native/service/model effects remain
  gated. This installation's opencode.jsonc bytes were preserved; only the
  ordinary workspace choice was recorded. Disclosure remains inventory-only.
  Owner separately requested a local checkpoint commit on 2026-10-15 UTC;
  Git and the latest task receipt own its outcome. No optional investigation,
  install, extra agent or publication included. Private task events own full
  plan, endpoint ledger and exact results; old
  adoption-small-fixes and its commit permission are completed history, not a queue.
- **Owners / protected work:** current Leader is sole writer/validator with
  non-independent focused review. Owner requested a fresh-Leader handoff;
  transfer is reconciled with Git. N2 is accepted within its limits and N3 is
  owner-deferred; no worker launch/retry or paid fallback is authorized.
  Preserve existing audit evidence, historical records, model map, adapter,
  fixtures, Git objects and unrelated projects. Leader owns only the explicitly
  approved temporary ZIP/executable/metadata, not tracked binary assets.
  Desktop reopening/Claude trust confirmation remains owner-owned.
- **Limits:** no implicit native/model starts, live manager calls, installs, new
  dependencies, global settings, adapter enablement, trust/private-memory
  migration, commits, pushes or publication without explicit approval. Push,
  settings and releases are human-owned. The ignored local map selects
  developer/reviewer models only; the Leader model is chosen per launch; the
  Claude adapter is absent.
- **Next action:** no further native execution is queued. Current private plan
  `workspace-comprehensive-audit/2026-10-15T010522Z-leader-approval-plan-v14.md`
  under `.sw/comms/tasks/` records N2 acceptance and N3 deferral; the preceding
  handoff retains exact inventory/assets/evidence. Preserve accepted local repairs and the submitted
  R5 offline batch, verified temporary2.0.29 artifact and stopped N2 evidence.
  Preserve completed N2 default/opt-in results and earlier failed attempts;
  do not replay them. Only if the owner reopens N3, resolve explicit
  model/provider/access/cost choices and obtain approval of its exact effect
  proposal before the remaining single harmless headless request. Deferral
  does not complete the selected support contract or whole-plan acceptance.
  Offline success will not close native/headless/MCP acceptance endpoints.
  Completed checks are not an automatic re-execution queue. The local checkpoint
  commit does not authorize push, further implementation or
  Pester-major/action/runner migration. Keep VERSION 0.3.0-dev.
  Native/platform/disclosure gaps do not authorize further investigation, and
  publication remains human-owned. `sw context -Task <id> -StateFile
  docs/workspace-state.md` lists references, not approval or continuous control.

### Earlier checkpoints

- **Profile-selection-v1, context-recovery-v1, validation/adoption P1/P2 (moved from Startup 2026-10-05):**
  profile-selection-v1 complete locally (local task record `profile-selection-v1/2026-10-05T042035Z-leader-closure.md`),
  owner-approved 2026-10-04, closed 2026-10-05 UTC after corrections, legacy
  self-regeneration and C3 review. C2 evidence (local task record `profile-selection-v1/2026-10-05T034902Z-executor-receipt-c2.md`):
  76 selection cases passed; full suite 303 passed / one prior file-symlink skip.
  No real selection migration, Claude adapter enablement or root redeployment.
  Context-recovery-v1 is complete locally (local task record `context-recovery-v1/2026-10-04T213644Z-leader-closure.md`),
  with remaining validation limits (local task record `context-recovery-v1/2026-10-04T220118Z-leader-remaining-validation-note.md`),
  not a reopened execution queue. Validation/adoption plan (local task record `workspace-validation-adoption-v1/plan.md`)
  has P1/P2 complete locally (local task record `workspace-validation-adoption-v1/2026-10-05T054409Z-leader-closure-p2.md`)
  on 2026-10-05 UTC: Workspace migrated to research + provider-setup, same roles/eight
  skills; parity/protection and full suite 303 pass / one existing skip verified.
  No native/platform/other-project/root/Claude/publication work approved or performed.
  WS manager, relocation (step 4 validation deferred),
  workspace-v1, review-repair and publication approvals are task-specific
  history. S3-S6 scoping and R4-R6 requests remain proposals.
- **context-recovery-v1 (owner-approved; 2026-10-04 UTC, local draft):** context
  report/recovery feature implemented in sources, regenerated and validated
  offline. C2 and its root-anchor correction (local task record `context-recovery-v1/2026-10-04T204636Z-leader-correction-c2.md`)
  were accepted for scoped offline functionality in the
  C3 clearance (local task record `context-recovery-v1/2026-10-04T210718Z-leader-clearance-c3.md`): full Pester 227
  passed / 0 failed / 1 skipped (file-symlink case, no privilege), launcher 307
  and manager 87 assertions (executor evidence (local task record `context-recovery-v1/2026-10-04T210242Z-claude-progress-c2-correction.md`)).
  Native loading, other PowerShell versions/Linux/CI, runtime savings and fresh
  independent review remain unverified. No commit or publication.
- **WS manager (owner-approved; implementation 2026-10-04 UTC, local draft):**
  install a tailored manager at the parent WS directory, keeping all three
  repositories independent. Scope/assignment (local task record `ws-manager/2026-10-04T051621Z-leader-assignment.md`).
  Manager source, templates, offline regression and generic CLI integration are
  implemented and deployed at WS with all three projects registered; 87 manager
  assertions and 307 existing launcher/native-stub assertions pass. All 210 Pester
  tests passed; localized follow-up corrections passed manager/generated-copy
  checks. Workspace and root static validation pass; two historical research
  citation/section warnings remain. Exact checks, advisory review and limits (local task record `ws-manager/2026-10-04T055955Z-leader-submission.md`).
  This approval covers product implementation/offline checks/deployment,
  not live planning/model calls. No new dependencies, global changes, child
  execution, research passes, commits or publication. Preserve concurrent
  relocation updates and other projects' existing work. Earlier no-development notes below remain historical/task-specific.
- **WS relocation follow-up (owner-approved 2026-10-03; recorded 2026-10-04 UTC):**
  current checkout is `Workspace/` under the shared WS directory. Root README/AGENTS guidance, active
  location/current-state corrections and project configuration discovery are
  approved; pipeline, suite and integrity validation (step 4) is deferred.
  Execution outcome (local task record `ws-relocation/2026-10-04T041949Z-leader-submission.md`):
  directory guidance/current summaries updated; the running OpenCode service
  resolves all three new canonical locations and their project agents. Workspace's
  ignored worker map is effective. Desktop reopening/Claude trust confirmation
  still requires the owner; no fresh model session was launched.
  Preserve historical events, existing dirty work and separate project policies.
  No model starts, trust/memory migration, installs, commits or publication.
- **Repository arrangement (observed 2026-10-04 UTC; superseded 2026-10-05 by the
  owner decision (local task record `workspace-repo-split/2026-10-05T181851Z-owner-decision.md`)):**
  `origin` was the owner's private instance (now a separate remote, configured locally)
  (relayed 2026-10-04 record (local task record `workspace-repo-split/2026-10-04T013549Z-owner-approval.md`)).
  Git was clean at `50957e6`, with the locally recorded origin/main matching HEAD;
  live publication was not rechecked. Older publication descriptions below refer
  to the earlier integration, not today's remote or new authorization.

- **workspace-v1 review repairs (2026-10-03, local, unpublished):** the owner approved
  the Workspace lane of workspace-v1-review-fixes (local task record `workspace-v1-review-fixes/2026-10-03T222314Z-leader-submission-claude-workspace.md`)
  (repair in place; refuse unsafe Unreal-to-generic transitions; verified Claude
  ownership; unique recovery snapshots; one exclusive-create helper), P0-P3 and
  Workspace P6 only. A Claude executor session made the repairs to the kit
  sources, tests and generated copies. The Leader's independent reviews accepted
  the repairs and follow-up A1 (`claude` exit-code forwarding); the owner then
  approved local commits only. Acceptance evidence is in that task directory
  (checkpoints, submissions, reviews), not restated here. Hosted CI has not run on
  these local commits, and no push or other publication is authorized. Other
  projects' lanes are separate.

- **Publication verification (2026-10-03):** owner approved evolving the public
  SuperWorkspace repository into this Workspace project, preserving both Git
  histories, auditing public disclosure, root-layout/CI integration and a local
  integration commit. Approval and queue (local task record `workspace-publication/2026-10-03T090514Z-leader-approval.md`)
  and audited history consent (local task record `workspace-publication/2026-10-03T091517Z-leader-progress-consent-fetch.md`)
  authorize preparation only; review and checks (local task record `workspace-publication/2026-10-03T094814Z-leader-review.md`)
  and publication handoff (local task record `workspace-publication/2026-10-03T095112Z-leader-submission.md`)
  record local readiness; human push receipt (local task record `workspace-publication/2026-10-03T095714Z-leader-receipt.md`)
  confirms the prepared integration is published. Publication closure (local task record `workspace-publication/2026-10-03T100114Z-leader-closure.md`)
  verifies both hosted Windows/Ubuntu CI and workspace validation workflows passed
  on the exact published integration SHA. No new development task is authorized;
  verification records/current-state edits remain local until explicitly committed.
  Push/settings/releases remain human-owned. At that checkpoint the remote was
  `origin` (the approved SuperWorkspace URL); the current origin is the separate
  private instance described above. Git owns live ancestry
  and publication facts. Retained old roadmap/research/task records are historical,
  not new assignments. No additional model starts, dependencies or global repairs.

- **Current workspace-v1 outcome (2026-10-03):**
  bounded build approval (local task record `workspace-v1/2026-10-03T063903Z-leader-approval.md`)
  supersedes older launcher-not-approved notes below for this task only.
  P1/P2 source/generated launcher/adapter contracts are implemented locally;
  parser/module and 226 offline assertions pass. P2's quota-stopped work was
  reconciled without retrying that worker. Live acceptance evidence (local task record `workspace-v1/2026-10-03T081908Z-leader-submission.md`):
  independent source review, engineering artifact/checkpoint, distinct fresh
  session/hash reconciliation, six value/six Int64 tests (also rerun by Leader),
  and final read-only artifact review passed on the owner-selected free headless
  OpenCode route. All four permitted live starts used; no extra starts authorized.
  Ignored local map selects developer/reviewer only; Claude adapter absent.
  Owner accepted one unresolved conservative read-only Git denial versus an
  allowed API evaluation; do not retry/bypass it or relax permissions. Claude,
  interactive/mixed routes, compaction, other users and comprehensive security
  checks remain unverified. Bounded v1 completed and validated (local task record `workspace-v1/2026-10-03T082329Z-leader-closure.md`),
  published through the approved human integration (receipt above). Owner requested the scoped local commit
  (commit authorization (local task record `workspace-v1/2026-10-03T083516Z-leader-approval-commit.md`));
  its containing revision is recorded by Git, not a guessed future SHA.
  Preserve unrelated dirty work and historical events; no installs, global
  changes, new add-on task or publication authorized.
  Earlier startup facts below remain dated historical context, not a second
  current authorization. The native launcher neither approves work nor accepts
  artifacts from process exits; fresh kickoff/resume reconciles actual files,
  latest approval/assignment and unknown effects.

- **Identity:** research-led AI workspace.
  SuperWorkspace is the inherited installation, not a required target design.
  Every project component, including rules and tooling, is reconsiderable.
- **Implemented:** base initialized with the generic profile, GitHub tier 0,
  solo configuration (`users: []`). `main` then tracked `origin` (it now
  tracks the private remote); the published
  integration and later ancestry are in Git (`git log`), not restated here.
  Agent, command, skill, lifecycle, and GitHub template files are installed.
  The small roster, including `project-research`, is implemented.
- **Current authorization:** the WS manager offline/deployment task is complete;
  no native live acceptance or implicit follow-up is approved. The relocation follow-up and previous
  publication, workspace-v1 and review-repair approvals remain task-specific.
  No unrelated product development or live manager acceptance is authorized. The 2026-10-02 items
  below are decided or implemented history, not open assignments.
- **Decided and implemented (2026-10-02):**
  roster refit (local task record `workspace-roster-refit/`) (ddd155c);
  harness U1: OpenCode after a hands-on check of OpenCode and Kilo 7.8.3
  (decision (local task record `workspace-harness-decision/2026-10-02T181644Z-leader-decision-u1-opencode.md`):
  only `-m` selects the primary model on the CLI path); generator refit with
  model-only tiers (approval (local task record `workspace-harness-decision/2026-10-02T183500Z-leader-approval-generator-refit.md`),
  closure (local task record `workspace-harness-decision/2026-10-02T191500Z-leader-closure-generator-refit.md`));
  Git-rule hardening (closure (local task record `workspace-harness-decision/2026-10-02T200000Z-leader-closure-git-hardening.md`);
  static checks only, runtime test deferred); control surface
  (decision (local task record `workspace-harness-decision/2026-10-02T213000Z-leader-decision-control-surface.md`)):
  Claude roles in Claude Code on a subscription, other roles in OpenCode,
  effort dropped. Owner accepted the launcher/scoping recommendations
  (decision (local task record `workspace-harness-decision/2026-10-02T225000Z-leader-decision-launcher-scoping.md`));
  the launcher submission (local task record `workspace-harness-decision/2026-10-02T220000Z-leader-submission-launcher.md`)
  is superseded by workspace-v1.
- **Still proposals (committed in adfd0a8, not implementation approval):**
  S3-S6 scoping (local task record `workspace-design-scoping/`);
  research requests (local task record `workspace-research-requests/`): R1-R3 answered by
  research Pass 11 (claude-11); R4-R6 unanswered; no pass for them for now (owner, 2026-10-03).
- **Completed tasks:** documentation-only clarification of research authority,
  full project changeability and one rules/assumptions register; record (local task record `workspace-state-review/2026-10-01T223454Z-leader-submission.md`).
  No runtime overhaul or adoption of proposed architecture is authorized.
  Base initialization is complete; setup record (local task record `workspace-base-setup/`).
- **Status:** `validate -CheckLinks`, `tests/workspace-v1.ps1` (226 assertions)
  and Pester (107 tests) passed on 02633c4 in a read-only audit clone
  (2026-10-03; `state-audit/`). `doctor` was last recorded
  blocked by an OpenCode npm launcher error (2026-10-01) and is not rechecked;
  no global repair is authorized. Static results do not prove runtime enforcement.
- **Design register:** [rules, assumptions and outline](workspace-outline.md) is
  the single project design-review document. It distinguishes approved owner
  requirements, current operational constraints, proposals and unknowns.
  [v0.2](workspace-outline-v0.2.md) remains a dated reference; its preliminary
  Pass 7 cutoff is stale. The design synthesis (U5) has no closure; S1-S6 are
  recorded and S2's roster is implemented.
- **Execution boundaries:** current controls still apply until an approved change
  revises them; they are not permanent design requirements. No installs, global
  settings changes, commits, pushes or adapters beyond an explicit approval.
  Kilo's user-scope state (`~/.config|.local/share|.cache|.local/state/kilo`)
  was moved to the Recycle Bin at the owner's request, 2026-10-02. An ignored
  local map selects developer and reviewer models only; the Leader model is
  chosen per launch and the Claude adapter is absent. Only the headless
  OpenCode route has passed live acceptance (workspace-v1).

## Reading map

- `AGENTS.md`: project identity, design authority, current core/profile policies.
- `docs/workspace-outline.md`: canonical design rules/assumptions register.
- `.sw/config.json`: installed profile, GitHub tier, contributors, startup budget.
- `.sw/manifest.json`: kit-managed files and provenance.
- `.sw/workspace.md`: Git tiers, opt-ins, preservation and runtime checks.
- `.sw/collaboration.md`: task events, archive format and publication handoff.
- `.sw/comms/tasks/workspace-base-setup/`: setup commands, results, and limitations.
