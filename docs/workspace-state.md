# Workspace state

## Startup

- **Publication verification (2026-10-03):** owner approved evolving the public
  SuperWorkspace repository into this Workspace project, preserving both Git
  histories, auditing public disclosure, root-layout/CI integration and a local
  integration commit. [Approval and queue](../.sw/comms/tasks/workspace-publication/2026-10-03T090514Z-leader-approval.md)
  and [audited history consent](../.sw/comms/tasks/workspace-publication/2026-10-03T091517Z-leader-progress-consent-fetch.md)
  authorize preparation only; [review and checks](../.sw/comms/tasks/workspace-publication/2026-10-03T094814Z-leader-review.md)
  and [publication handoff](../.sw/comms/tasks/workspace-publication/2026-10-03T095112Z-leader-submission.md)
  record local readiness; [human push receipt](../.sw/comms/tasks/workspace-publication/2026-10-03T095714Z-leader-receipt.md)
  confirms the prepared integration is published. [Publication closure](../.sw/comms/tasks/workspace-publication/2026-10-03T100114Z-leader-closure.md)
  verifies both hosted Windows/Ubuntu CI and workspace validation workflows passed
  on the exact published integration SHA. No new development task is authorized;
  verification records/current-state edits remain local until explicitly committed.
  Push/settings/releases remain human-owned. Current
  remote is `origin` (the approved SuperWorkspace URL); Git owns live ancestry
  and publication facts. Retained old roadmap/research/task records are historical,
  not new assignments. No additional model starts, dependencies or global repairs.

- **Current workspace-v1 outcome (2026-10-03):**
  [bounded build approval](../.sw/comms/tasks/workspace-v1/2026-10-03T063903Z-leader-approval.md)
  supersedes older launcher-not-approved notes below for this task only.
  P1/P2 source/generated launcher/adapter contracts are implemented locally;
  parser/module and 226 offline assertions pass. P2's quota-stopped work was
  reconciled without retrying that worker. [Live acceptance evidence](../.sw/comms/tasks/workspace-v1/2026-10-03T081908Z-leader-submission.md):
  independent source review, engineering artifact/checkpoint, distinct fresh
  session/hash reconciliation, six value/six Int64 tests (also rerun by Leader),
  and final read-only artifact review passed on the owner-selected free headless
  OpenCode route. All four permitted live starts used; no extra starts authorized.
  Ignored local map selects developer/reviewer only; Claude adapter absent.
  Owner accepted one unresolved conservative read-only Git denial versus an
  allowed API evaluation; do not retry/bypass it or relax permissions. Claude,
  interactive/mixed routes, compaction, other users and comprehensive security
  checks remain unverified. [Bounded v1 completed and validated](../.sw/comms/tasks/workspace-v1/2026-10-03T082329Z-leader-closure.md),
  published through the approved human integration (receipt above). Owner requested the scoped local commit
  ([commit authorization](../.sw/comms/tasks/workspace-v1/2026-10-03T083516Z-leader-approval-commit.md));
  its containing revision is recorded by Git, not a guessed future SHA.
  Preserve unrelated dirty work and historical events; no installs, global
  changes, new add-on task or publication authorized.
  Earlier startup facts below remain dated historical context, not a second
  current authorization. The native launcher neither approves work nor accepts
  artifacts from process exits; fresh kickoff/resume reconciles actual files,
  latest approval/assignment and unknown effects.

- **Identity:** research-led AI workspace based on sibling `AI-Research [2]`.
  SuperWorkspace is the inherited installation, not a required target design.
  Every project component, including rules and tooling, is reconsiderable.
- **Implemented:** base initialized with the generic profile, GitHub tier 0,
  solo configuration (`users: []`). `main` tracks `origin`; the published
  integration and later ancestry are in Git (`git log`), not restated here.
  Agent, command, skill, lifecycle, and GitHub template files are installed.
  The small roster, including `project-research`, is implemented.
- **Current authorization:** only what the publication and workspace-v1 bullets
  above state; no new development task is authorized. The 2026-10-02 items
  below are decided or implemented history, not open assignments.
- **Decided and implemented (2026-10-02):**
  [roster refit](../.sw/comms/tasks/workspace-roster-refit/) (ddd155c);
  harness U1: OpenCode after a hands-on check of OpenCode and Kilo 7.8.3
  ([decision](../.sw/comms/tasks/workspace-harness-decision/2026-10-02T181644Z-leader-decision-u1-opencode.md):
  only `-m` selects the primary model on the CLI path); generator refit with
  model-only tiers ([approval](../.sw/comms/tasks/workspace-harness-decision/2026-10-02T183500Z-leader-approval-generator-refit.md),
  [closure](../.sw/comms/tasks/workspace-harness-decision/2026-10-02T191500Z-leader-closure-generator-refit.md));
  Git-rule hardening ([closure](../.sw/comms/tasks/workspace-harness-decision/2026-10-02T200000Z-leader-closure-git-hardening.md);
  static checks only, runtime test deferred); control surface
  ([decision](../.sw/comms/tasks/workspace-harness-decision/2026-10-02T213000Z-leader-decision-control-surface.md)):
  Claude roles in Claude Code on a subscription, other roles in OpenCode,
  effort dropped. Owner accepted the launcher/scoping recommendations
  ([decision](../.sw/comms/tasks/workspace-harness-decision/2026-10-02T225000Z-leader-decision-launcher-scoping.md));
  the [launcher submission](../.sw/comms/tasks/workspace-harness-decision/2026-10-02T220000Z-leader-submission-launcher.md)
  is superseded by workspace-v1.
- **Still proposals (committed in adfd0a8, not implementation approval):**
  [S3-S6 scoping](../.sw/comms/tasks/workspace-design-scoping/);
  [research requests](../.sw/comms/tasks/workspace-research-requests/): R1-R3 answered by
  AI-Research Pass 11 (claude-11); R4-R6 unanswered; no pass for them for now (owner, 2026-10-03).
- **Completed tasks:** documentation-only clarification of research authority,
  full project changeability and one rules/assumptions register; [record](../.sw/comms/tasks/workspace-state-review/2026-10-01T223454Z-leader-submission.md).
  No runtime overhaul or adoption of proposed architecture is authorized.
  Base initialization is complete; [setup record](../.sw/comms/tasks/workspace-base-setup/).
- **Status:** `validate -CheckLinks`, `tests/workspace-v1.ps1` (226 assertions)
  and Pester (107 tests) passed on 02633c4 in a read-only audit clone
  (2026-10-03; [state-audit](../.sw/comms/tasks/state-audit/)). `doctor` was last recorded
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
