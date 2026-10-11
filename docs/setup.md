# Setup and adoption

SuperWorkspace is installed **from a kit clone into a project root**. Keep the
clone separate so you can update the kit without mixing it with your application.
In this guide `sw` means `pwsh -NoProfile -File .sw/sw.ps1` inside an installed
project; `init` and `update` run from the kit's root `sw.ps1` instead.

## Prerequisites

Install these yourself; the kit does not install tools or authenticate accounts:

- [Git](https://git-scm.com/downloads), on PATH. Configure your identity before
  committing (prefer project-local `git config user.name` / `user.email`).
- [PowerShell 7.2+](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell)
  on Windows, Linux or macOS; check `pwsh --version`. Windows PowerShell 5.1 is
  not supported. Follow Microsoft's per-platform installation instructions.
- For sessions: [OpenCode Desktop or CLI](https://opencode.ai/v2/docs/), provider
  access and owner-selected available models. A Claude subscription is not
  OpenCode API access. Do not put credentials in shared project files.
- Optional: GitHub CLI (`gh`) for GitHub helpers, RTK >= 0.48 for output
  reduction, Git LFS for an Unreal project's actual LFS workflow, Claude Code
  for the explicit local adapter. Pester is only a kit-development requirement.

```powershell
git clone https://github.com/BiscuitDoesStuff/SuperWorkspace.git
cd SuperWorkspace
git status --short --branch
git rev-parse HEAD
pwsh -NoProfile -File sw.ps1 help
```

Select a reviewed revision; `main` is moving development, not a stable release
channel. Check its hosted CI at that exact SHA. `VERSION` alone cannot reproduce
an install; `.sw/manifest.json` records kit version and commit, but a dirty clone
can contain code not represented by that commit. Use a clean clone for adoption.

## Choose a profile

| Option | Intended use |
| --- | --- |
| `-Profile generic` | Application/code projects, project-discovered build/test commands |
| `-Profile research` | Research/evidence projects, cited findings and evidence checks |
| `-Profile unreal` | Unreal projects, engine/build constraints and managed LFS patterns; does not install the engine or initialize LFS |
| `-Capabilities research` | Add outside-research role/skill to another preset |
| `-Capabilities provider-setup` | Add the `free-models` procedure; no models/accounts are configured |
| `-NoGitHub` | Omit kit GitHub workflows/templates; existing project-owned GitHub files are not deleted |
| `-GitPolicy host` | Default for new installs; host owns branches, worktrees and integration |
| `-GitPolicy workspace` | Explicit kit workflow: solo `main`, or owner-designated contributor branches |
| `-Records local` / `tracked` | Default new records local; tracking is an explicit opt-in |

Fresh installs use selection v1. Older configs without `selection` stay legacy
(all base components) until explicit `update -SelectionV1`; capabilities are
additive to the preset. Never migrate a real project merely to test an option.

## New project

From the kit clone, use a target outside that clone. These relative examples
work in PowerShell on each supported platform; quote paths containing spaces.

```powershell
pwsh -NoProfile -File sw.ps1 init ../MyProject -Profile generic -Name MyProject -WhatIf
pwsh -NoProfile -File sw.ps1 init ../MyProject -Profile generic -Name MyProject
```

Preview first; `-WhatIf` creates no target, Git repository, config or records.
Apply creates the directory and, if absent, a Git repository starting at `main`.
The new `gitPolicy: host` does not require staying on that branch: document your
chosen workflow. No commit, remote, push, model map, global configuration or
Claude adapter is created. Continue with [bootstrap](#bootstrap-and-first-session).

## Existing project

First installation is **init**, even if the repository already exists. Ask its
owner to approve adoption; start from a known, coordinated checkout and run
the application's existing tests before and after. Existing changes are not
stashed or discarded. Use the repository root (including a worktree's root),
not a package underneath another repository.

```powershell
# From the kit clone; replace the example with the actual project root.
pwsh -NoProfile -File sw.ps1 init ../ExistingProject -Profile generic -WhatIf
# Apply only after reviewing the preview and any conflicts.
pwsh -NoProfile -File sw.ps1 init ../ExistingProject -Profile generic
```

Existing Git branches/remotes/configuration are left alone. A non-Git folder
is supported too: after successful preflight the kit runs `git init -b main`.
Unknown whole-file conflicts and kit downgrades refuse before Git initialization
or file writes. Permissions/I/O failures during an applied operation can still
leave partial effects; this is not an atomic transaction.

### Ownership and conflicts

| Surface | Behavior |
| --- | --- |
| `AGENTS.md` | Project identity/invariants and text outside `sw` blocks remain project-owned. Core/profile blocks are refreshed, not deep-merged. Review contradictory existing instructions before agent work. |
| `.gitignore`, `.gitattributes` | Kit only inserts/refreshes its named blocks; existing text remains. Managed LFS removal is refused even with `-Force`/`-Adopt`. |
| Files listed in `.sw/manifest.json` | Whole-file managed copies; updates refresh unedited files, keep local edits and supply incoming comparisons when the kit also changed. |
| `opencode.jsonc` | Kit-generated strict JSON, despite its extension. An existing differing file is a conflict, including JSONC with comments/trailing commas. |
| Host agents, skills, plugins and GitHub files | Noncolliding extras remain project-owned; matching kit paths conflict. Runtime compatibility is not inferred from file preservation. |
| `.opencode/opencode.jsonc`, `.claude/`, `.sw/backup/` | Local model map, opt-in adapter and recovery data are ignored. Never publish their private settings or backup contents. |

There is **no transparent merge** of OpenCode configuration/MCPs, plugins,
GitHub workflows or policy. Resolve conflicts with the owner. You can integrate
settings manually in a separately reviewed change or decline adoption.
Do not simply rename a conflicting config to a higher-precedence OpenCode
location: that can override the kit's effective policy.

Only when the owner explicitly chooses to replace the conflicting whole files:

```powershell
pwsh -NoProfile -File sw.ps1 init ../ExistingProject -Profile generic -Adopt -WhatIf
pwsh -NoProfile -File sw.ps1 init ../ExistingProject -Profile generic -Adopt
```

`-Adopt` backs those files up under `.sw/backup/<UTC>-<id>/` and replaces them;
it does **not** preserve their active settings. Backup failure stops its
replacement. Credential-like filenames are excluded by name, not by content;
settings/backup files can still contain secrets. Review them privately. Never
make `-Adopt` an unconditional onboarding command.

## Supported boundaries

- Project/repository-root setup and non-Git folders; not monorepo subpackages,
  auto-created nested repositories or manager roots. Submodules/nested setups
  need a separate owner decision. Linked/special filesystem layouts have no
  general installation safety guarantee; use an ordinary root and review paths.
- Fresh `opencode.jsonc` generation or explicit conflict refusal/replacement.
  Initial adoption refuses root `opencode.json`, preexisting `.opencode`
  JSON/JSONC config variants and legacy singular/skills directories before
  changes, even with `-Adopt`. Migrate them separately; the kit does not do it.
  These are **kit limitations**, not OpenCode limitations: OpenCode itself
  [supports JSON/JSONC and merged discovery](https://opencode.ai/v2/docs/config).
- Existing extra files remain, but must satisfy the validator's metadata,
  portability and permission rules. Host policy does not disable safety checks.
  Global instructions, providers and plugins may change actual runtime behavior;
  installation does not edit them or prove their compatibility.
- Windows/Linux CI is defined. Local Windows/offline checks are not hosted
  Linux or fresh-user proof. macOS, provider access, interactive/Claude/mixed
  sessions, second-user handoffs and runtime permissions need separate checks.

## Bootstrap and first session

From the target project:

1. Replace `AGENTS.md`'s project-owned placeholders. State what the application
   is, its boundaries and existing build/tests. Name the current state file and
   document the host Git workflow, or explicitly choose workspace policy.
2. Reuse the project's state source if present; otherwise create, for example,
   `docs/project-state.md` with a `## Startup` section: implemented baseline,
   current authorized task, assigned owner/checkout, protected work and next
   check. State "no work approved" until the owner approves a bounded task.
3. Record the first approved task under `.sw/comms/tasks/<task-id>/` (approval,
   scope, acceptance, ownership and checks). A roadmap, template, model map or
   launcher event is not approval. Local records require explicit handoff to
   other users rather than assuming Git transports them.
4. Validate the installation and your tools:

```powershell
pwsh -NoProfile -File .sw/sw.ps1 validate
pwsh -NoProfile -File .sw/sw.ps1 doctor
```

Solo owners omit `-User`. For contributors the owner runs `sw user <you>`;
follow the host's branch setup before `doctor -User <you>`. Under workspace
policy the owner supplies `<you>/<you>-worktree` from published `main`;
doctor checks that branch. Under host policy it reports the branch and that
the project workflow is **not checked**. Warnings are not proof of readiness;
required-tool failures are errors. `doctor` never installs or authenticates.

Choose your provider and model IDs locally using OpenCode's own setup. Optional
worker mapping (replace placeholders with IDs actually available to you):

```powershell
pwsh -NoProfile -File .sw/sw.ps1 tiers -Light '<provider/model>' -Standard '<provider/model>' -High '<provider/model>'
pwsh -NoProfile -File .sw/sw.ps1 validate
```

This writes the ignored local tier map; it does not select a Leader model or
authorize spending. An existing map stops without `-Force` (which overwrites
it). Free-first is the default cost policy, not a guarantee of free model
availability. `provider-setup` adds the dated verification procedure; never
send credentials/private code to documentation queries.

Open a **fresh session in the target**, select `project-leader` and an approved
model, use Local directory rather than automatic worktrees, then `/work
<approved-task>`. Check loaded roles/instructions and effective permissions
before consequential work; static validation is not runtime verification.
For CLI users, the optional explicit entry can be previewed after creating
approved records:

```powershell
pwsh -NoProfile -File .sw/sw.ps1 session start project-leader first-task -Model '<provider/model>' -DryRun
```

Remove `-DryRun` only with launch/access approval. See
[native-entry contracts](../.sw/workspace.md#native-session-entry); no implicit
model fallback, adapter activation or retry. Exit 0 does not accept an artifact.

## Updates and recovery

Updating the **kit clone** and updating an **installed project** are different:

1. Human receives/selects a reviewed kit revision with a clean clone and checks
   its hosted CI. There is no auto-update service or guaranteed stable channel.
2. From that clone, preview then apply an approved project update:

```powershell
pwsh -NoProfile -File sw.ps1 update ../ExistingProject -WhatIf
pwsh -NoProfile -File sw.ps1 update ../ExistingProject
```

3. Read the report. `kept-local` means your edit stays and the kit version did
   not change; `skip-modified` also supplies an ignored incoming version under
   `.sw/backup/<UTC>-<id>/incoming/`. Compare with the printed
   `git diff --no-index` command (exit 1 normally means differences), then
   resolve by intent. No automatic merge. Modified removed files remain as
   `orphan-kept`; unchanged owned files removed from the kit can be removed.
4. Revalidate the installation **and application**. Publish selected shared
   changes only after private-data review. Other contributors receive them
   through the host workflow, then regenerate an already opted-in local Claude
   adapter if needed. Do not enable one just to validate an OpenCode project.

Updates preserve existing Git/privacy/selection choices. Explicit
`update -GitPolicy host` or `-Records local|tracked` changes those choices;
review previews first. Choosing local does not untrack existing records or
remove past disclosures; the human decides any Git/history migration. Choosing
tracked can expose accumulated local records: review before staging/publishing.

Kit downgrades stop unless you consciously pass `-Force`. Do not use that flag
to fix an unknown mismatch; first select the intended kit revision.
Managed-block errors and unsafe selection/LFS changes also stop; fix only with
separate approval. Before retrying any partial failure, inspect actual files,
Git state, manifest and recovery copies. There is no automatic rollback or
uninstall: restore/merge only the specific affected files you verified, keeping
unrelated work and the operation's backup. Never reset/clean/stash to recover.

## Troubleshooting and support

- **Wrong PowerShell:** use `pwsh`, not `powershell`; compare `pwsh --version`.
- **Kit command unavailable:** run root `sw.ps1` from the kit clone, not the
  target's `.sw/sw.ps1` (which contains project commands only).
- **Conflict / alternate configuration / nested target:** refusal is expected;
  nothing is silently merged. Check [boundaries](#supported-boundaries), then
  make an owner-approved migration decision, not a blind retry with `-Adopt`.
- **Missing state/task/model map:** complete bootstrap and explicit local
  selections; do not invent authority or model IDs.
- **Doctor warnings:** optional tools and host Git workflow can warn; distinguish
  those from required tools reporting MISSING/FAILED. Runtime access is untested.
- **Edited managed file / adapter drift:** inspect incoming copies or regenerate
  the already enabled adapter from its actual sources. Keep local edits.

[Support/diagnostics](../CONTRIBUTING.md#support) ·
[Private security reporting](../SECURITY.md). Do not post credentials, raw
private task records, local model maps or backup contents in public issues.
