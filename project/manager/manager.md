# WS manager

This is a local coordination instance, not an umbrella Git repository. The
Workspace checkout owns product sources; this installation has its own manifest.
Project configuration, approvals, execution records and private evidence remain
project-owned. Manager shell rules are guardrails, not an OS sandbox.

## Commands

Run `pwsh -NoProfile -File .sw/sw.ps1 manager <action> ...` from the root.

- `projects`, `status`: offline registry, bounded startup context and task records.
- `request -Project <id> -Task <id> -Body <question> [-DependsOn <task-ids>]`:
  write an immutable planning request; no model/service call. Returns a request ID.
- **Human only:** `approve -Project <id> -Task <id> -Model <provider/model>
  -MaxMessages <count> -Owner <name> -Approval <source>` records a scoped planning
  approval. The source must identify the actual owner decision. This approval is
  separate from installing the product and never grants project execution.
- `start -Task <id>`: create one read-only OpenCode session at the approved project
  directory. No parentID: native child sessions inherit their parent's directory.
- **Human only:** `attach -Task <id> -SessionID <id> -Owner <name>
  -Approval <opt-in-source>`: attach only an idle, already restricted ws-planner
  session with matching project/model/permissions. Never change an existing role.
- `send -Task <id> -Request <request-id>`: reserve one approved message, then queue
  the request without steering/interrupting. Sending may resume an idle session
  and spend the approved model budget. Never run it merely to inspect a draft.
- `collect -Task <id>`: inspect native identity/inbox/messages, reconcile unknown
  creation/delivery, and show correlated completed response text. Saves references
  and state, not native transcripts. Paginated messages are read only for this task.
- `accept -Task <id> -Request <request-id> -Summary <reviewed-outcome>`:
  record reviewed acceptance only after a collected answer. Not implementation
  approval or project completion. Other tasks can depend on this acceptance.
- `handoff -Task <id> -Body <scoped-summary> -To <project-or-Claude-session>`:
  record a manual handoff; no claim of native delivery or acknowledgment.
- `validate`: check installation hashes, namespaced config and registered paths;
  warn when managed files are stale vs the Workspace kit sources.

Root task records live in `.sw/comms/tasks/<task-id>/`: human approvals, requests,
native intent/identity, delivery observations and reviewed outcomes. There is no
second plan/memory ledger. A task belongs to one project; cross-project tasks link
with `-DependsOn`. Requests contain scoped planning text, never bulk evidence.
Project plans and execution records stay authoritative inside each project.

## Recovery and limits

Mutating operations serialize per task. Creation and send intent are persisted
before native calls; unknown results consume their reservation and block retries.
Use `collect` to reconcile by the exact native IDs. Do not delete intent records
to bypass an uncertainty or budget. A new task/approval is not an automatic retry.
The budget counts logical input reservations, not tokens, dollars or every native
agent/compaction request. Keep free-first routing; metered access needs owner opt-in.
Queued, delivered, answered and accepted are distinct; an errored or truncated
response is not an answer. Revise scope with the owner when evidence is missing.

The installer does not create Git, install packages/plugins/MCPs, select models,
change global settings, modify children, import sessions or activate Claude.
The root config defines only `ws-manager` and `ws-planner`, not ancestor-wide
default agents, models, providers, permissions or compaction settings. Select
`ws-manager` explicitly in a fresh root session. Live API/routing/permission
acceptance requires its own owner-selected model and bounded test approval.
