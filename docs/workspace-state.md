# Workspace state

## Startup

- **Identity:** research-led AI workspace based on sibling `AI-Research [2]`.
  SuperWorkspace is the inherited installation, not a required target design.
  Every project component, including rules and tooling, is reconsiderable.
- **Implemented:** base initialized with the generic profile, GitHub tier 0,
  solo configuration (`users: []`), and local Git on `main` with no commits.
  Agent, command, skill, lifecycle, and GitHub template files are installed.
- **Authorized task:** [workspace-design-synthesis](../.sw/comms/tasks/workspace-design-synthesis/)
  (docs-only U5 synthesis; S1-S6 recorded from the reviewed corpus Pass 8 report
  and owner-confirmed; U1 partly resolved: small roster and generator refit decided,
  harness open pending corpus Pass 9 `harnesses-09`). Approved 2026-10-02:
  [workspace-roster-refit](../.sw/comms/tasks/workspace-roster-refit/) (in progress);
  the generator refit follows the reviewed Pass 9 report.
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
  from reviewed Passes 4-8; S1-S6 are recorded as design direction, not implemented.
- **Execution boundaries:** current controls still apply until an approved change
  revises them; they are not permanent design requirements. This docs-only phase
  leaves operational files and the external corpus unchanged. No installs,
  global settings changes, commits, pushes, remotes or adapters are authorized.
  Local model tiers are not configured; runtime behavior remains unverified.

## Reading map

- `AGENTS.md`: project identity, design authority, current core/profile policies.
- `docs/workspace-outline.md`: canonical design rules/assumptions register.
- `.sw/config.json`: installed profile, GitHub tier, contributors, startup budget.
- `.sw/manifest.json`: kit-managed files and provenance.
- `.sw/workspace.md`: roles, permissions, model tiers, and verification ladder.
- `.sw/collaboration.md`: execution records and human-owned publication.
- `.sw/comms/tasks/workspace-base-setup/`: setup commands, results, and limitations.
