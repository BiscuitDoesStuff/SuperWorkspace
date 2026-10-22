---
name: status
description: Read-only report of project state, Git, active tasks and validation, ending with a recovery card.
disable-model-invocation: true
---

# Status

Use when the owner asks where things stand, or before `resume`. Read-only:
change nothing.

## Steps

1. Read the startup section of the project state file named in `AGENTS.md`.
2. Run `git status --short --branch`, `git log --oneline -10`,
   `git rev-parse HEAD` and `git remote`. With a remote, also run
   `git rev-parse <remote>/main` for the remote that owns `main` (usually
   `origin`; the branch upstream shows which). With none, report
   "local-only; no remote configured" and skip remote checks. List open pull
   requests when GitHub access exists. Without fresh remote confirmation,
   publication is unknown.
3. List active tasks under `.sw/comms/tasks/` (main checkout) with their
   latest event state, and unread messages in `.sw/comms/inbox/<user>/`
   (information, not approval).
4. For a named or unique task, finish with the recovery card.

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
- Several possible active tasks: list them; names and newest-event order never
  select one.
- Old or superseded approval never authorizes new work.

## Exit

A concise report: authorized work and its state, branch, HEAD, local changes
and publication, active tasks and blockers, last known validation (labeled
historical), and the next authorized step or why work is blocked.
