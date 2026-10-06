---
description: Reconcile a task record with Git and resume its approved remaining steps
agent: project-leader
subagent: false
---

Resume task: $ARGUMENTS

Load `task-handoff`. Locate the task under `.sw/comms/tasks/` (or its
`SUMMARY.md` under `.sw/comms/archive/`). `sw context -Task <id> -StateFile
<state file from AGENTS.md>` lists sizes and event references; it is a pointer
list, not an approval verdict. Verify approved scope, checkout, ownership, Git
diff, dependencies, and preserved validation evidence against the actual files.
Before acting, state the recovery card from `/status` (task, approval/scope/
source, owners/conflicts, artifacts/revision/dirty scope, last verified
checkpoint, process outcome, effects, outstanding checks, one next action);
unavailable fields stay UNKNOWN. Resume unambiguous approved steps without
asking to continue. If no task is named, find the unique active approved task;
ask only when records are ambiguous. A historical recommendation, draft plan,
newest event or superseded approval is never approval. Missing authority or
ownership, or unknown effects, block mutating steps until reconciled: never
retry an operation with unknown effects or auto-resume a native conversation.
