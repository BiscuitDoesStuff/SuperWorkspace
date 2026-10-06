---
description: Read-only status of branches, project state, tasks, and validation
agent: project-review
subagent: true
---

Produce a concise project status report without modifying files: $ARGUMENTS

1. Read the startup section of the project state file named in `AGENTS.md`.
2. Use `git status --short --branch`, `git log --oneline -10`,
   `git rev-parse HEAD`, and `git rev-parse origin/main` to separate local
   commits, uncommitted work, and the last-fetched `main`. Without independent
   remote confirmation, publication status is unknown.
3. List active tasks under `.sw/comms/tasks/` with their latest event state.
   `sw context [-Task <id>] -StateFile <state file from AGENTS.md>` output, when
   the main session supplies it, gives sizes and event references only; it is
   not approval, and names or newest-event order never select an active task.

Report: current authorized work and its state, branch/HEAD/local changes and
publication status, active tasks and blockers, last known validation (labeled
historical), and the next authorized step or why work is blocked. For a named
or unique task, end with this recovery card, quoting or linking the sources:

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

Unavailable fields stay UNKNOWN. A missing exit is unknown, not success or
failure; a nonzero exit does not prove no effects; a completion note, hash or
launch receipt does not prove the artifact is correct. Old or superseded
approval never authorizes new work. Never invent dates, tests, or features;
call out ambiguity instead of guessing.
