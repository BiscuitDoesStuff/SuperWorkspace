# Onboarding

For a new contributor joining an existing SuperWorkspace project, on OpenCode
only (Claude Code is an opt-in local adapter; see `.sw/workspace.md`).

## Prerequisites

- [Git](https://git-scm.com/downloads)
- [PowerShell 7.2+](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell) (`pwsh`, not Windows PowerShell 5.1)
- [OpenCode](https://opencode.ai/v2/docs/) (Desktop or CLI), with your own provider/model access
- Optional: `gh` (GitHub CLI), RTK >= 0.48

## Clone and check

```powershell
git clone <repo-url>
cd <checkout-directory>
pwsh .sw/sw.ps1 doctor -User <you>
```

You are joining an installed project: do not run the kit's `init` again.
Ask the owner to record your contributor name with `sw user <you>` if needed.
Solo owners run `pwsh .sw/sw.ps1 doctor` without `-User`.

`doctor` is read-only; it reports missing tools but installs nothing. In
`.sw/config.json`, `gitPolicy: host` delegates branch/worktree setup to your
project rules (doctor does not verify that workflow). `gitPolicy: workspace`,
or an absent legacy field, requires your own `<you>/<you>-worktree` with recorded
contributors; `main` is accepted only in a solo workspace-policy project.

## Model tiers

```powershell
pwsh .sw/sw.ps1 tiers -Light <id> -Standard <id> -High <id>
```

Default cost policy is free-first: free OpenCode/OpenRouter models and local
LM Studio, no metered API spend unless you opt in locally. See the
`free-models` skill for dated tier fits if the owner selected `provider-setup`
(or this is a legacy installation). The command writes only the ignored local
`.opencode/opencode.jsonc`; it does not configure accounts or authenticate.
Use actual available IDs, not the placeholders above; an existing map is not
replaced without `-Force`. No credentials belong in shared files or task records.

## OpenCode Desktop setting

Set the default environment to "Local directory". OpenCode Desktop's
automatic-worktree environment may conflict with the project's branch policy;
do not use it without owner approval. `doctor` and `validate` cannot detect it.

## First session

Before work, verify Project identity in `AGENTS.md` names the project's state
file, its Startup section is current, and your task has explicit approval and
an assigned checkout. A generated template or a backlog is not authorization.
Open a fresh project session in OpenCode; select `project-leader`. Then:

- `/inbox` - check messages addressed to you
- `/work <task>` - start an approved task
- `/status` - see open work

## Branches and publishing

Use the host workflow when `gitPolicy: host`. Under workspace policy, work on
`<you>/<you>-worktree`, created by the owner from published `main`, or on `main`
when solo. Agents never push; humans publish and merge their own work. See
[collaboration.md](collaboration.md) for task records, messages, and
integration rules.

New installations default to `records: local`: task/inbox/archive files are
git-ignored. Older installations without that field keep tracked records.
Local records do not travel with your clone; obtain approvals and handoffs from
the owner. Ignoring files does not untrack existing records or erase published
history. Never publish private evidence, secrets or personal model settings.

## Hard rules

- Agents never push.
- Never push to, or work on, another contributor's branch.
- Humans publish and merge; agents only propose.
