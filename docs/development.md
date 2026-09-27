# Developing SuperWorkspace

The repository has two halves:

- `product/` is what ships: the CLI, its modules, the project templates, the
  global rules and the user guides. `init`, `update` and `global` read only
  from here.
- The root is the dev workspace for the kit itself: `AGENTS.md` (the rules for
  changing the kit), `tests/`, `.github/`, and `docs/`.

```
product/                 what ships (see README.md for its layout)
tests/                   Pester suite for product/lib
docs/decisions.md        why things are the way they are
docs/roadmap.md          the living plan
docs/research/           sourced research, one file per topic (NN-topic.md)
docs/case-studies/       projects the kit was harvested from; examples, not targets
```

Run the checks in `AGENTS.md` before handing work back.

## How development runs

A **Leader** session owns the whole plan (`docs/roadmap.md`), writes work
packages, and reviews them. **Worker** sessions are opened by the human in this
folder on `main`; each runs one work package and reports back.

- A new Desktop session is not reachable by peer messaging until its first
  turn runs, so the Leader sends the first brief through the app's session
  message; later signals can use peer messages.
- A work package is an `assignment` event in `.sw/comms/tasks/<task-id>/`
  (`pwsh .sw/sw.ps1 comms event -Task <id> -Event assignment -From leader`),
  carrying scope, exclusions, file ownership, acceptance criteria, validation
  commands and stop conditions. Task records are the durable truth;
  cross-session messages are only the "go" and "done" signals.
- Workers post `progress` events, stop and message the Leader on any scope
  change or plan-level finding, and finish with a `submission` event holding
  changed paths, validation evidence and proposed plan changes. Workers may
  use subagents but never start sessions.
- The Leader reruns the checks, reviews (with `project-review` for code), writes
  `review` then `approval` or `correction`, and folds findings into the roadmap.
- One writing worker at a time; research workers that each own one new
  `docs/research/` file may run alongside. Nobody commits or pushes without the
  human; a worker never does what the Leader was denied.
- Edit `product/`, never the generated copies (`.opencode/`, `.sw/`,
  `.claude/`); refresh them with `pwsh product/sw.ps1 update .` and
  `pwsh .sw/sw.ps1 claude enable`.
- When context runs long, the Leader writes a `handoff` event and a fresh Leader
  session resumes from the roadmap and open task records.
- A cloud Leader session (Claude Code on the web) works on the branch the
  harness assigns it, because its container is temporary. It may commit and
  push to that branch only; the branch carries work between machines, is not a
  contributor branch, and never becomes a base for other work. Only the owner
  updates `main`, by fast-forward after review. The cloud Leader keeps a
  `handoff` event current after each milestone so a local session (OpenCode or
  Claude) can take over at any point.
- Cloud workers: the cloud Leader starts each worker as a separate cloud
  session from the tip of its own branch, with the assignment as the first
  message. The worker installs PowerShell 7 itself (Microsoft apt repository),
  works only in its owned paths, writes its `submission` event, commits, and
  pushes only to the branch named in the assignment (`cloud/<task-id>`). It
  cannot message the Leader, so the owner says when it is done. The Leader does
  not commit to its own branch while a writing worker runs. After review it
  fast-forwards its branch to the worker's tip. The owner deletes the worker
  branch after integration.

## Commits

`<type>(<area>): <imperative summary>`. Types: feat, fix, docs, refactor,
test, chore. Areas: `kit` (product/), `dogfood` (generated install at the
root), `docs`, `research`, `tests`. The body lists one bullet per change and
names the task record; a `BREAKING CHANGE:` footer marks anything a kit user
must act on. Only the human commits and pushes, except a cloud Leader on its
assigned branch (see above).
