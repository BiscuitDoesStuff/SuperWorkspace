---
name: resume
description: Reconcile a task record or ExecPlan with Git and the files, then continue its approved remaining steps.
disable-model-invocation: true
---

# Resume

Use when work restarts after a break, a compaction, a new thread or a handoff.
The request names the task, or there is one unique active approved task.

## Steps

1. Locate the task in `.sw/comms/tasks/<task-id>/` (main checkout), or its
   `SUMMARY.md` under `.sw/comms/archive/`. In a worktree thread the records
   are absent: use the dispatch brief in the prompt instead.
   `sw context -Task <id> -StateFile <state file>` lists sizes and event
   references; it is a pointer list, not approval.
2. Read the ExecPlan or latest plan and approval, then check Git and the
   actual files: branch, HEAD, dirty paths, commits since the last event,
   pull request state.
3. State the recovery card from `status` before acting.
4. Continue the unambiguous approved steps with `work` from the first open
   `Progress` item, without asking to continue.

## Decisions

- No task named and several candidates: ask which one.
- Records and Git disagree: Git owns commits and publication; stop and report
  the mismatch instead of guessing.
- Missing authority or ownership, or an operation with unknown effects: block
  mutating steps until reconciled; never retry it blindly or auto-resume a
  native conversation.
- A historical recommendation, draft plan, newest event or superseded approval
  is never approval.

## Exit

Either work continues from a stated recovery card, or a report names the
blocker, the missing evidence and one next action with its owner.
