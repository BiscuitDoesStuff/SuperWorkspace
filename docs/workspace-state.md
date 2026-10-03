# Workspace state

## Startup

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
  local-only, not published. Owner requested the scoped local commit
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
  solo configuration (`users: []`), and local Git on `main` (baseline commit 05df1c0, 2026-10-02).
  Agent, command, skill, lifecycle, and GitHub template files are installed.
- **Authorized task:** [workspace-design-synthesis](../.sw/comms/tasks/workspace-design-synthesis/)
  (docs-only U5 synthesis; S1-S6 recorded from the reviewed corpus Pass 8 report
  and owner-confirmed; U1 partly resolved: small roster and generator refit decided,
  harness chosen: OpenCode after a hands-on check of OpenCode and Kilo;
  tier rubric model-only). Approved 2026-10-02:
  [workspace-roster-refit](../.sw/comms/tasks/workspace-roster-refit/) (implemented, committed ddd155c).
  [workspace-harness-decision](../.sw/comms/tasks/workspace-harness-decision/):
  hands-on check approved and run for OpenCode and Kilo 7.8.3 (scratch-local
  npm install; both results records hold the comparison) plus OpenCode follow-ups;
  U1 harness decided: OpenCode (owner, 2026-10-02; [decision](../.sw/comms/tasks/workspace-harness-decision/2026-10-02T181644Z-leader-decision-u1-opencode.md):
  only `-m` selects the primary model on the CLI path). Generator refit
  approved and implemented 2026-10-02 (model-only tiers; committed;
  [approval](../.sw/comms/tasks/workspace-harness-decision/2026-10-02T183500Z-leader-approval-generator-refit.md));
  reviewed (no `rtk.ts` rewrite escapes a rule; review fixes applied); owner items in its
  [closure](../.sw/comms/tasks/workspace-harness-decision/2026-10-02T191500Z-leader-closure-generator-refit.md).
  Next: [handoff](../.sw/comms/tasks/workspace-harness-decision/2026-10-02T203000Z-leader-handoff-control-surface.md):
  then [decision](../.sw/comms/tasks/workspace-harness-decision/2026-10-02T213000Z-leader-decision-control-surface.md)
  (owner, 2026-10-02): one control surface; Claude roles in Claude Code on a
  subscription, other roles in OpenCode; effort dropped; launcher not approved. Git-rule hardening approved and implemented
  2026-10-02 (committed; static checks only; runtime test deferred to
  workspace completion, owner 2026-10-02;
  [closure](../.sw/comms/tasks/workspace-harness-decision/2026-10-02T200000Z-leader-closure-git-hardening.md)).
- **Completed tasks:** documentation-only clarification of research authority,
  full project changeability and one rules/assumptions register; [record](../.sw/comms/tasks/workspace-state-review/2026-10-01T223454Z-leader-submission.md).
  No runtime overhaul or adoption of proposed architecture is authorized.
  Base initialization is complete; [setup record](../.sw/comms/tasks/workspace-base-setup/).
- **Status:** initialization, startup documentation, static contracts, managed-file
  integrity, and local documentation links checked successfully. `doctor` remains
  blocked by an existing OpenCode npm launcher error; no global repair is
  authorized by setup. Static results do not prove runtime enforcement.
- **Design register:** [rules, assumptions and outline](workspace-outline.md) is
  the single project design-review document. It distinguishes approved owner
  requirements, current operational constraints, proposals and unknowns.
  [v0.2](workspace-outline-v0.2.md) remains a dated reference; its preliminary
  Pass 7 cutoff is stale. The updated design synthesis (U5) is in progress
  from reviewed Passes 4-8; S1-S6 are recorded; S2's roster is implemented except the research profile role.
- **Execution boundaries:** current controls still apply until an approved change
  revises them; they are not permanent design requirements. The roster refit
  changed kit sources and generated files only; the external corpus is unchanged.
  Commits are the owner-approved baseline, roster refit, and (2026-10-02, owner)
  the generator refit, git hardening and harness decision records. No installs (beyond the
  approved scratch-local Kilo test install), global settings changes, further
  commits, pushes, remotes or adapters are authorized. Kilo's user-scope state
  (`~/.config|.local/share|.cache|.local/state/kilo`) was moved to the Recycle Bin
  at the owner's request, 2026-10-02. Local model tiers are not configured; runtime routing and
  enforcement were checked only in scratch test projects, not in Workspace itself.

## Reading map

- `AGENTS.md`: project identity, design authority, current core/profile policies.
- `docs/workspace-outline.md`: canonical design rules/assumptions register.
- `.sw/config.json`: installed profile, GitHub tier, contributors, startup budget.
- `.sw/manifest.json`: kit-managed files and provenance.
- `.sw/workspace.md`: roles, permissions, model tiers, and verification ladder.
- `.sw/collaboration.md`: execution records and human-owned publication.
- `.sw/comms/tasks/workspace-base-setup/`: setup commands, results, and limitations.
