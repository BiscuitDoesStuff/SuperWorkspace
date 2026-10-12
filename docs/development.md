# Developing Workspace

The public SuperWorkspace repository now carries the research-led Workspace
project. The active kit is at the root; the old `product/` layout remains in
Git history, not as a second active generator.

| Path | Responsibility |
| --- | --- |
| `sw.ps1`, `lib/`, `project/`, `global/`, `VERSION`, `LICENSE`, `THIRD_PARTY_NOTICES.md` | Current kit sources and distributed license notices |
| `.sw/`, `.opencode/`, `.agents/` | Generated installation used by this project |
| `tests/Sw.Tests.ps1` | Inherited lifecycle, validator, permission and adapter Pester coverage, adapted to current contracts |
| `tests/workspace-v1.ps1` | Dependency-free offline launcher/adapter regression, native CLIs stubbed |
| `lib/Sw.Manager.psm1`, `project/manager/`, `tests/manager.ps1` | Separate non-Git manager installation and bounded project planning coordination; native V2 API transport stubbed offline |
| `docs/workspace-state.md` | Current implemented state and authorization |
| `docs/workspace-outline.md` | Current design rules, assumptions and proposals |
| `docs/roadmap.md`, `docs/decisions.md`, `docs/research/`, `docs/case-studies/` | Retained pre-Workspace history/evidence, not current implementation authority |

## Workflow

Follow [AGENTS.md](../AGENTS.md), [workspace ownership](../.sw/workspace.md) and
[collaboration rules](../.sw/collaboration.md). The Leader owns the approved task
queue; specialists never spawn teams. Serialize writers and use one validation
owner per checkout. Commits require explicit owner approval; agents never push.
Solo work uses `main`; contributor branches require owner designation. Imported
cloud/task-branch procedures are historical, not an exception to current policy.

Edit the source rather than competing generated copies. Preview regeneration:

```powershell
pwsh -NoProfile -File sw.ps1 update . -WhatIf
```

Apply an approved update with `sw.ps1 update .`, then validate. Do not enable a
local Claude adapter or configure models/accounts merely to run checks; those
are separate owner opt-ins. Older nine-role, effort and implicit-model test
assumptions have been replaced by the implemented four-role/model-only contracts.

Adopter instructions live in [setup.md](setup.md); generated join instructions
come from `project/base/.sw/onboarding.md`. This checkout retains its existing
workspace Git policy and local-record choice; self-regeneration does not adopt
new-install defaults. Edit Git-policy snippets in `project/git-*.md`; rendering
selects one from `gitPolicy`, absent means legacy workspace policy. Licenses are
copied under `.sw/` without changing the host license.

## Validation

PowerShell 7.2+ is required. Local validation and isolated Windows/Linux CI use
Pester **5.6.1** explicitly; local dependency installation needs separate approval.
Do not silently select a newer major: Pester 6 changes filtered-mock fallthrough.
Updating the test dependency requires its own compatibility validation.

```powershell
pwsh -NoProfile -File tests/workspace-v1.ps1 -ParseOnly
pwsh -NoProfile -File tests/workspace-v1.ps1
pwsh -NoProfile -File tests/manager.ps1
pwsh -NoProfile -Command 'Import-Module Pester -RequiredVersion 5.6.1 -Force -ErrorAction Stop; Invoke-Pester -Path tests -CI'
pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks
pwsh -NoProfile -File sw.ps1 update . -WhatIf
git diff --check
```

Context-report and recovery-card regressions are the Pester block
`Context and recovery reporting` (`Invoke-Pester -Path tests -FullNameFilter
'Context and recovery reporting*'`). `sw context` and `sw validate` share
`Get-SwStartupBudget`; changing it changes both.

Offline fixtures must also run from a fresh checkout without ignored local
records/settings. The session suite reads generated comms docs from their
tracked `project/base/` sources, never from private task records.

Research lint normally expects the six-section topic format. A dated evidence
snapshot may put `<!-- sw:research-format: snapshot -->` in its header (before
the first `##` heading) to exempt only the topic-section check. Date and numbered
finding checks remain active; explicit `Source F1` / `Sources F1, F2` citations
are recognized. This is lightweight citation lint, not source verification.

Profile selection v1 (`project/selection.json`, profile `composition`, the
`research` preset and `project/capabilities/`) is the Pester block `Profile
selection v1` (`-FullNameFilter 'Profile selection v1*'`). Fresh `init` defaults
to v1; an existing project without `selection` stays
legacy (all base components) on `update` unless `-SelectionV1` is passed. Its
fixtures use disposable projects and isolated kit copies; a real selection
migration needs separate approval. Selection controls installed files, not
runtime loading, global skills or measured savings.
This Workspace's research + provider-setup opt-in (local task record `workspace-validation-adoption-v1/2026-10-05T054409Z-leader-closure-p2.md`)
is complete locally; other projects' migrations and native acceptance remain separate gates.

Use disposable fixture directories for fresh `init`/`update` checks. Pester and
offline regression do not exercise real model access or runtime permissions;
keep those results separate from the bounded v1 live evidence. After human
publication, verify the exact remote SHA and both GitHub workflows; local Windows
success is not proof of hosted Linux CI. No release/tag or account setup is
implied by a normal main-branch push.

Public-adoption regression is `Public adoption*` in `tests/Sw.Tests.ps1`:
new generic/research/Unreal, existing Git/non-Git, host files/application and
Git-state preservation, alternate/JSONC/MCP conflicts, preview/refusal complete
trees, policy/privacy compatibility and explicit backup-replacement. Synthetic
application tests are not acceptance against every adopter's real application.

### Human publication gates

1. Inspect selected diffs and new files for private data; never publish the
   local comparison audit or raw comms/backup/model files. No full history or
   credential audit is implied by static checks.
2. Commit only the reviewed paths when requested; humans push their branch.
   Current `main` is development; choose any tag/release version deliberately,
   not from `VERSION` alone. Do not overwrite historical tags.
3. Verify remote SHA and both `ci` OS jobs, fresh-install/offline steps and
   `sw-validate` at that SHA before calling the published candidate ready.
   Local green results do not repair an old hosted run.
4. Human repository settings: enable private vulnerability reporting and
   confirm **Report a vulnerability** is available. Suggested About:
   "Project-local OpenCode agents, skills and task handoffs for new or existing
   repositories." Suggested topics: `opencode`, `ai-agents`, `powershell`,
   `developer-tools`; setup URL is the published `docs/setup.md`. Metadata is
   not changed by this task.

Do not describe the Leader's own checks as an independent review; record any
unavailable planned review in the task/state record. No platform/native/account
gap is silently waived.

## Manager deployment

`sw.ps1 manager install -Path <root>` deploys a manager-specific subset, not
`sw init`. It rejects unmanaged/modified target conflicts before writing and
backs up owned updates. `.sw/manager-manifest.json` owns generated manager files;
`.sw/manager/projects.json` is the local project registry. No Git, generic
defaults, plugins, MCPs, model mapping or Claude adapter is installed at the root.
Develop changes in these product sources and redeploy; do not hand-edit managed
copies. Root instructions/startup state are root-owned, not generator-owned.

Manager records are local structured events in its `.sw/comms/tasks/`, not Git
transport or project execution approvals. One session/task owner, explicit
operator approvals, bounded messages, immutable intent and native IDs protect
against accidental duplicate dispatch. Shell pattern rules are guardrails; a
separately approved live test must verify native routing and effective policy.
