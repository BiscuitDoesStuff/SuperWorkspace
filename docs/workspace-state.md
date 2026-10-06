# Workspace state

## Startup

- **Identity / sources (owner, 2026-10-05):** development checkout of the public
  SuperWorkspace product, research-led; every
  component is reconsiderable on evidence. The owner's private instance is the
  `personal` remote; its adaptations may be upstreamed here.
  Decision (local task record `workspace-repo-split/2026-10-05T181851Z-owner-decision.md`). Design rules/assumptions:
  [outline](workspace-outline.md). Operational rules: `AGENTS.md`,
  `.sw/workspace.md`, `.sw/collaboration.md`. Git owns ancestry/publication facts.
- **Implemented (local):** v1 research profile + provider-setup, GitHub tier 0, solo `main`, four-role
  roster, workspace-v1 launcher/adapter contracts and review repairs, and the
  context-recovery-v1 context report/recovery feature (uncommitted draft).
  Profile-selection-v1 and this Workspace's P2 opt-in are complete locally. The WS
  manager is deployed offline at the parent WS with three projects registered
  (uncommitted draft). `origin` is public `BiscuitDoesStuff/SuperWorkspace`;
  `personal` is the owner's private instance (`personal` remote) (local `main` still
  tracks `personal/main`, 6 ahead/0 behind `origin/main` on 2026-10-05).
- **Unverified:** only the headless OpenCode route passed live acceptance
  (workspace-v1). Claude/interactive/mixed routes, compaction, other users,
  comprehensive security, live manager planning/routing, native loading and
  runtime permission enforcement are untested; static/offline checks do not prove
  them. Do not retry, bypass or relax the one accepted read-only Git denial.
  `doctor` was last recorded blocked (2026-10-01). Live publication not rechecked.
- **Current task:** none active. Profile-selection-v1, context-recovery-v1 and
  validation/adoption P1/P2 are complete locally; closure detail is in
  [History](#history-dated-checkpoints). No native/platform/other-project/root/Claude/publication
  work approved or performed. WS manager, relocation (step 4 validation deferred),
  workspace-v1, review-repair and publication approvals are task-specific
  history. S3-S6 scoping and R4-R6 requests remain proposals.
- **Owners / protected work:** developer stopped; Leader recorded local completion.
  No active writer/build job or successor package. Preserve uncommitted
  context/recovery, WS manager and relocation drafts (their tracked hunks,
  `lib/Sw.Manager.psm1`, `.sw/lib/Sw.Manager.psm1`, `project/manager/`,
  `tests/manager.ps1`, task records) and all other projects. Desktop
  reopening/Claude trust confirmation after relocation remains owner-owned.
- **Limits:** no implicit native/model starts, live manager calls, installs, new
  dependencies, global settings, adapter enablement, trust/private-memory
  migration, commits, pushes or publication without explicit approval. Push,
  settings and releases are human-owned. The ignored local map selects
  developer/reviewer models only; the Leader model is chosen per launch; the
  Claude adapter is absent.
- **Next action:** none authorized. Owner may choose a separately bounded remaining
  package; prior platform/native gaps are not an automatic execution queue.
  Leader does not automate or claim continuous control of that native session.
  Publication remains human-owned and unrequested. Read that task, then needed
  workspace/collaboration rules. `sw context -Task <id> -StateFile
  docs/workspace-state.md` lists sizes and event references, not approval.
- **Task records:** `.sw/comms/` is local-only in this checkout (gitignored since
  2026-10-05); previously published records remain in public history.
- **History:** [dated checkpoints](#history-dated-checkpoints) below and task
  records under `.sw/comms/tasks/` hold evidence and qualifications; they are
  not current authorization.

## History (dated checkpoints)

Dated context moved from Startup unchanged; Startup above supersedes it. Approvals
here are task-specific and cannot authorize new work.

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
  `origin` was the owner's private instance (now the `personal` remote)
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
  personal instance named above. Git owns live ancestry
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
  solo configuration (`users: []`). `main` tracks `origin`; the published
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
- `.sw/workspace.md`: roles, permissions, model tiers, and verification ladder.
- `.sw/collaboration.md`: execution records and human-owned publication.
- `.sw/comms/tasks/workspace-base-setup/`: setup commands, results, and limitations.
