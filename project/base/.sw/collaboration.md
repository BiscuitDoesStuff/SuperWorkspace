# Collaboration

Owns task records, messages, branches, pull request targets, publication and
integration under `AGENTS.md`. Git is the transport: everything below is plain files in
`.sw/comms/`, published when a human pushes their branch. `main` is the
integration baseline. Agents commit and push only as the Git flow in
`.sw/workspace.md` allows.

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
correction event instead. Your own unsubmitted event may be revised. Records
are written only in the project's own checkout, never in a worktree thread;
worktree threads report in their final message instead (`.sw/workspace.md`).

## Task events

Events: `assignment`, `progress`, `submission`, `correction`, `review`,
`approval`, `integration`, `receipt`, `closure`. One task directory per task; no
second plan, memory, or TODO hierarchy. A plan file for large or multi-session
work lives in the task directory (the `work` skill). Harness memory (Claude
auto memory, Codex memories) is machine-local recall; anything the team or a
later session needs goes in a task record or a committed file. Fields:

```markdown
# <task-id> - <event> - <UTC> - <author>

- **Author / audience:** <human owner; agent/model if relevant; readers>
- **Approval:** <who approved what, when, source; or "proposal, not approved">
- **Scope / acceptance:** <outcome, success evidence, exclusions>
- **Status:** <pending | in_progress | complete | blocked; why>
- **Branch / base:** <main or t3/<name>>; published main <full SHA, when observed>
- **Checked revision / changed:** <full SHA plus dirty paths, or "uncommitted draft over <SHA>">
- **Owners / dependencies:** <file, binary-asset, validation owners; dependencies and their state>
- **Decisions / remaining:** <choices made, work done, next items>
- **Validation:** <runner; time/zone; exact command; result; evidence location>
- **Not validated / risks:** <missing or failed checks; reported vs observed>
- **Publication:** <local-only, or observed published ref + full SHA; pull request URL>
- **Next action:** <owner; executable step; completion evidence>
```

`blocked` names the unmet dependency and what unblocks it; `complete` needs
acceptance evidence and is not publication. On resume, reconcile the latest
events with Git and the actual files, not just the status field. Context
summaries and model switches do not carry uncommitted work. Never guess the SHA
of the commit that will contain a record.

**Claims.** A task is claimed when its `assignment` event is on `main`; if two
people assign the same task, the first fast-forward push wins and the other
reconciles. At GitHub tier 1 an assignment may name an issue and its assignee,
but the record stays the truth. With recorded contributors, task IDs start with
the owner's user name (`<user>-<slug>`) so two people never create the same
folder.

**Closing.** When a task is integrated,
`sw comms close -Task <task-id> -Outcome "<summary>"` writes
`archive/<task-id>/SUMMARY.md` (outcome, final SHA, decisions, open follow-ups)
and moves the events beside it. Agents read the summary, not the old events, so
closed work stops costing context. `-Outcome` is the whole summary: give the
outcome, the decisions, the open follow-ups and a dated lessons line when the
task taught one (promoted into a rule, check or skill only after review). Close a task only after its last
event is on `main`.

## Parallel threads

Each human runs one coordinating thread that dispatches their tasks and writes
their records; worktree threads, opened from it or by that human, each own one
package. The task record is the truth. Briefs and reports travel through T3
Code (thread messages, final reports); the human relays them where T3 cannot.
A coordinating thread is never shared between humans and dispatches only tasks its
human owns. Across humans, coordination travels as files (a message in
`inbox/<user>/` or a task event, published by push and received by fetch) or,
at GitHub tier 1, as an issue comment.

## Messages

A message is for coordination between people or models: questions, requests,
FYIs. It carries no authority: approval happens in a task `approval` event or
directly from the human owner. Fields: `from`, `to`, `task` (optional),
`subject`, body, and the action requested. Read with `sw comms inbox`; archive
once handled.

## Branches

Work happens in T3 Code threads. Only `main` and T3 Code worktree-thread
branches (`t3/<name>`) exist.

- **Route by change.** Small, docs-only or solo work is committed directly on
  `main` in the main checkout. Code changes, and anything published to the
  public product remote, go through a worktree thread and a pull request.
- **Contributors.** With no recorded contributors (`users` is empty in
  `.sw/config.json`) the owner works as above. Once anyone is recorded
  (`sw user <name>`, run by the owner on `main`), everyone, the owner included,
  works in worktree threads and nothing is committed to `main` directly.

T3 Code creates each worktree thread's branch from published `main` with the
static prefix `t3/` (**Settings > Source Control > Worktree branch naming**,
human, once per project). A thread owns its branch: never work on another
thread's branch. Agents never create, switch or delete branches themselves. A
dirty tree means stop and coordinate, never reset or stash. T3 Code's
merge-based worktree cleanup removes merged worktrees and keeps those with
local changes; an unexpected branch is reported, never deleted.

Other tools' automatic branches stay off: Claude's desktop worktree option and
`--worktree`, Codex cloud tasks and the Copilot cloud agent each create
branches outside this model. For binary assets in LFS projects, `git lfs lock`
optionally enforces the one-owner rule.

**Pull request targets.** A pull request targets `main` on the remote that owns
the change. Most projects have one remote, `origin`. A product developed
alongside a private instance keeps two: the private instance's remote takes
the instance's own adaptations, and the public product remote (`origin`) takes product
changes. Private evidence, personal paths and nonredistributable material never
go to the public remote.

## Finish and publish

Stage selected task paths only; inspect `git diff --cached` for unrelated work
and secrets; commit with a Conventional Commit message (`feat:`, `fix:`,
`docs:`, `refactor:`, `test:`, `chore:`). Agents commit as they go. A thread
branch is published either by the owner through the thread's T3 Git actions
(check a generated commit message before accepting it) or, at GitHub tier 2,
by the agent pushing its own `t3/` branch and opening a draft pull request.
Whoever opens the pull request links and watches it (`.sw/workspace.md`). A
local commit is local until the remote tip is confirmed. Announce:

```text
Task: <task-id>; author: <user>
Published ref: refs/heads/t3/<name> @ <full SHA observed after push>
Base: <full main SHA>; record: .sw/comms/tasks/<task-id>/<event>.md
Pull request: <URL or none>; validation: <summary>; blockers/next: <owner and action>
```

## Integrate (human)

**Thread pull requests.** Review (the `review` skill: Codex, or a recorded
single-provider review) precedes merge. Drafts run no CI; after review the
pull request is marked ready (`gh pr ready`), which starts CI.
Once the relevant CI checks on the current pull request revision
have passed (or the quota fallback gate in `.sw/workspace.md` Git flow step 5
has), the agent (tier 2) or the human enables auto-merge; GitHub then
merges when the checks the target branch requires, if any, pass. Auto-merge
waits only for required checks, so while CI is not required it does not wait
for CI: disable auto-merge before pushing to its pull request again
(`gh pr merge --disable-auto`) and re-enable it after the gate passes on the
new revision. The thread fixes CI failures and conflicts on its own branch by
merging the target branch in; agents never rebase any branch (a hard limit).

**Direct commits on `main`.** A human publishes them, fast-forward only:

```powershell
git fetch <remote>
git merge-base --is-ancestor <remote>/main main   # exit 0 required
git push <remote> main
```

If the ancestry check fails, merge `<remote>/main` locally, resolve conflicts
by intent, revalidate and retry. Never force-push, rebase any branch, or
reset.

**Protect main (human, once).** A ruleset stops force pushes and deletion of
`main`. The kit prints these steps and never applies them. In the repository
settings, add a branch ruleset for the default branch:

- Always: block force pushes, restrict deletions, and allow no bypass (admins
  included).
- Pull request route: require the status check `validate` (from
  `sw-validate.yml`) so auto-merge waits for it. A required check or required
  pull request also blocks direct pushes to `main`, so a project that keeps
  direct commits needs the publisher allowed to bypass, or routes every change
  through pull requests.
- Private repositories need GitHub Pro or an organization plan for this;
  public ones get it on Free.

## Receive

Fetch, check `git status` is clean, and fast-forward only when your HEAD is an
ancestor of `origin/main`; divergent unintegrated commits need deliberate
reconciliation on their thread branch. T3 Code's automatic pull keeps the
main checkout current. For LFS projects run `git lfs pull` before building.
Publication, receipt, build, automated checks, and manual checks are separate
facts.

**Kit updates.** `sw update` changes shared files for everyone, so the owner
(or a named contributor) runs it from the kit clone as a task, validates, and
integrates it like any change. Others receive it, including the generated
`.claude/` files; `sw validate` reports drift in generated copies.
