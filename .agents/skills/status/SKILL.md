---
name: status
description: Read-only report of project state, Git, active tasks and validation, ending with a recovery card.
disable-model-invocation: true
---

# Status

Use when the owner asks where things stand, or before `resume`. Read-only:
change nothing (no `git fetch`). Scope follows the request: a named task
gets a task report; only a project-wide question gets the full sweep. Method:
topic 16 (`docs/research/16-public-capabilities.md` in the SuperWorkspace kit).

## Steps

1. Read the startup section of the project state file named in `AGENTS.md`.
2. Run `git status --short --branch`, `git log --oneline -10`,
   `git rev-parse HEAD` and `git remote`. With a remote, also run
   `git rev-parse <remote>/main` for the remote that owns `main` (usually
   `origin`; the branch upstream shows which). With none, report
   "local-only; no remote configured" and skip remote checks. A local
   remote-tracking ref is as old as the last fetch: report its value, not
   publication. Without fresh remote confirmation, publication is unknown.
3. **Named task:** read that task's record in `.sw/comms/tasks/<task-id>/`
   (main checkout) and only the branch, pull request and checks it names. Do
   not read other task records, the inbox or the open pull request list.
4. **Project-wide report** (no task named): list active tasks with their
   latest event state, unread messages in `.sw/comms/inbox/<user>/`
   (information, not approval), and open pull requests when GitHub access
   exists.
5. For a named or unique task, finish with the recovery card.

```text
Task / objective:
Applicable approval / allowed scope / source:
Owner / dependencies / conflicts:
Artifacts / checked revision / dirty scope:
Last verified checkpoint / evidence:
Process outcome: observed exit | missing/unknown
Effects: confirmed occurred | confirmed did not occur | unknown
Outstanding checks / missing evidence:
One permitted next action / responsible owner:
```

## Decisions

- Unavailable fields stay UNKNOWN. A missing exit is unknown; a nonzero exit
  does not prove no effects; a completion note does not prove the artifact.
- Several possible active tasks and none named: list them; names and
  newest-event order never select one.
- The named task has no record: say so and stop; do not substitute another
  task.
- Old or superseded approval never authorizes new work.

## Exit

A concise report: authorized work and its state, branch, HEAD, local changes
and publication, active tasks and blockers, last known validation (labeled
historical), and the next authorized step or why work is blocked.
