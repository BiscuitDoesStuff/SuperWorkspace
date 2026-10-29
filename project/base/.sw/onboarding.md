# Onboarding

For a new contributor joining an existing SuperWorkspace project. You work in
T3 Code, which runs Claude (Claude Code) and Codex threads with their native
project configuration (see `.sw/workspace.md`).

## Prerequisites

- [Git](https://git-scm.com/downloads)
- Windows, with its built-in Windows PowerShell 5.1 (`powershell`); PowerShell 7 (`pwsh`) works too
- [T3 Code](https://t3.codes) (desktop app, or the `t3` CLI that `doctor` can detect)
- Claude Code and/or Codex, each with your own login
- Optional: `gh` (GitHub CLI), RTK >= 0.48

## Clone and check

```powershell
git clone <repo-url>
cd <checkout-directory>
powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 doctor -User <you>
```

You are joining an installed project: do not run the kit's `init` again.
Ask the owner to record your contributor name with `sw user <you>` if needed.
Solo owners run `powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 doctor` without `-User`.

`doctor` is read-only; it reports missing tools but installs nothing. In
`.sw/config.json`, `gitPolicy: host` delegates branch/worktree setup to your
project rules (doctor does not verify that workflow). `gitPolicy: workspace`,
or an absent legacy field, accepts `main` or a T3 Code `t3/<name>` thread branch.

## Models

You pick each thread's model in T3 Code; the project pins none. Optionally
keep your own tier table in the git-ignored `.sw/models.local.md` (small, mid,
top). Plan on the mid-to-top tier at moderate effort; run implementation from a
written spec and exploration on the mid tier; set model and effort explicitly
per thread; use no max effort or fast modes by default and the top tier only
after cheaper ones fail. No credentials belong in shared files or task records.

## T3 Code settings

Add the checkout as a T3 Code project and enable your providers in
**Settings > Providers**. Apply the project settings in
[workspace.md](workspace.md#project-settings-human-once): new-thread
permissions **Auto** or **Full access**, not **Supervised**, worktree
branch prefix `t3/` under workspace policy, automatic pull, and merge-based
worktree cleanup that keeps worktrees with local changes. A host-policy project
uses T3 Code worktree threads only with explicit host-owner approval. Codex
loads the project's rules only after you trust the project in Codex. `doctor`
and `validate` cannot detect these settings.

## First session

Before work, verify Project identity in `AGENTS.md` names the project's state
file, its Startup section is current, and your task has explicit approval and
an assigned checkout. A generated template or a backlog is not authorization.
Open a new T3 Code thread in the project; it coordinates your work (no
dedicated agents are defined). Then:

- `sw comms inbox` - check messages addressed to you
- `work` skill - start an approved task
- `status` skill - see open work

## Branches and publishing

Use the host workflow when `gitPolicy: host`. Under workspace policy, agents
commit as they go: small, docs-only or solo work on `main`, code changes and
public product changes in a T3 Code worktree thread (`t3/<name>`, from
published `main`) with a pull request. See
[collaboration.md](collaboration.md) for task records, messages, pull request
targets and integration, and [workspace.md](workspace.md#git-flow) for the
Git flow.

New installations default to `records: local`: task/inbox/archive files are
git-ignored and written only in your main checkout, never in a worktree. Older
installations without that field keep tracked records. Local records do not
travel with your clone; obtain approvals and handoffs from the owner. Ignoring
files does not untrack existing records or erase published history. Never
publish private evidence, secrets or personal model settings.

## Hard rules

- Agents never force-push, push to `main`, publish releases, change repository
  settings or rewrite `main` history.
- Never push to, or work on, another contributor's or thread's branch.
- Review (`review`: Codex by default) precedes every pull request merge.
