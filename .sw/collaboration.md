# Collaboration

Owns task records, messages, branches, publication, and integration under
`AGENTS.md`. Git is the transport: everything below is plain files in
`.sw/comms/`, published when a human pushes their branch. `main` is the
integration baseline. Only humans publish; agents never push.

## Layout

```
.sw/comms/
  tasks/<task-id>/<UTC>-<user>-<event>.md   immutable task events
  inbox/<user>/<UTC>-<from>-<slug>.md       messages to one person or model
  archive/<task-id>/SUMMARY.md              closed tasks, one page each
  archive/inbox/<user>/                     read messages
```

`sw comms` writes these for you (`send`, `inbox`, `event`, `close`, `archive`).
UTC stamps use `yyyy-MM-ddTHHmmssZ`. Never edit another author's file; add a
correction event instead. Your own unsubmitted event may be revised.

## Task events

Events: `assignment`, `progress`, `submission`, `correction`, `review`,
`approval`, `integration`, `receipt`, `closure`. One task directory per task; no
second plan, memory, or TODO hierarchy. Fields:

```markdown
# <task-id> - <event> - <UTC> - <author>

- **Author / audience:** <human owner; agent/model if relevant; readers>
- **Approval:** <who approved what, when, source; or "proposal, not approved">
- **Scope / acceptance:** <outcome, success evidence, exclusions>
- **Status:** <pending | in_progress | complete | blocked; why>
- **Branch / base:** <user/user-worktree>; published main <full SHA, when observed>
- **Checked revision / changed:** <full SHA plus dirty paths, or "uncommitted draft over <SHA>">
- **Owners / dependencies:** <file, binary-asset, validation owners; dependencies and their state>
- **Decisions / remaining:** <choices made, work done, next items>
- **Validation:** <runner; time/zone; exact command; result; evidence location>
- **Not validated / risks:** <missing or failed checks; reported vs observed>
- **Publication:** <local-only, or observed published ref + full SHA>
- **Next action:** <owner; executable step; completion evidence>
```

`blocked` names the unmet dependency and what unblocks it; `complete` needs
acceptance evidence and is not publication. On resume, reconcile the latest
events with Git and the actual files, not just the status field. Context
summaries and model switches do not carry uncommitted work. Never guess the SHA
of the commit that will contain a record.

**Closing.** When a task is integrated, `sw comms close <task-id>` writes
`archive/<task-id>/SUMMARY.md` (outcome, final SHA, decisions, open follow-ups)
and moves the events beside it. Agents read the summary, not the old events, so
closed work stops costing context.

## Messages

A message is for coordination between people or models: questions, requests,
FYIs. It carries no authority: approval happens in a task `approval` event or
directly from the human owner. Fields: `from`, `to`, `task` (optional),
`subject`, body, and the action requested. Read with `/inbox` or
`sw comms inbox`; archive once handled.

## Branches

Only `main` and owner-designated `<user>/<user>-worktree` branches exist
(`sw user add <name>` records a contributor). Each contributor works, commits,
and publishes only on their own branch. The owner supplies the contributor name;
never infer it from a path or old commit. A worktree uses an existing assigned
branch that is not checked out elsewhere. A dirty tree means stop and
coordinate, never reset or stash.

## Finish and publish (human)

Stage selected task paths only; inspect `git diff --cached` for unrelated work
and secrets; commit with a Conventional Commit message (`feat:`, `fix:`,
`docs:`, `refactor:`, `test:`, `chore:`). A local commit is local until the
human pushes their branch and confirms the remote tip. Announce:

```text
Task: <task-id>; author: <user>
Published ref: refs/heads/<user>/<user>-worktree @ <full SHA observed after push>
Base: <full main SHA>; record: .sw/comms/tasks/<task-id>/<event>.md
Validation: <summary>; blockers/next: <owner and action>
```

## Integrate (human)

After `/validate` passes on the published task SHA:

```powershell
git fetch origin
git merge-base --is-ancestor origin/main <task-sha>   # exit 0 required
git switch main
git merge --ff-only origin/main
git merge --ff-only <task-sha>
git push origin main
```

If the ancestry check fails, merge `origin/main` into **your** contributor
branch, resolve conflicts by intent, revalidate, publish, and retry. Never
force-push, rebase a published branch, or reset. With GitHub tier 1 the same
rule holds: a PR is a review surface, and a human merges it.

## Receive

Fetch, check `git status` is clean, and fast-forward only when your HEAD is an
ancestor of `origin/main`; divergent unintegrated commits need deliberate
reconciliation on your branch. For LFS projects run `git lfs pull` before
building. Publication, receipt, build, automated checks, and manual checks are
separate facts.
