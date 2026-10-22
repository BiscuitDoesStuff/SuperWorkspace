# Developing Workspace

The public SuperWorkspace repository now carries the research-led Workspace
project. The active kit is at the root; the old `product/` layout remains in
Git history, not as a second active generator.

| Path | Responsibility |
| --- | --- |
| `sw.ps1`, `lib/`, `project/`, `global/`, `VERSION`, `LICENSE`, `THIRD_PARTY_NOTICES.md` | Current kit sources and distributed license notices |
| `project/base/` (`AGENTS.md`, `t3.json`, `.sw/`, `.agents/skills/`), `project/profiles/`, `project/capabilities/`, `project/selection.json` | Installed file sources, profiles and selection catalogue |
| `lib/Sw.Kit.psm1` | Rendering and lifecycle; generates `.claude/CLAUDE.md`, `.claude/settings.json`, `.claude/skills/` and `.codex/rules/workspace.rules`, which have no separate source files |
| `.sw/`, `.agents/`, `.claude/`, `.codex/`, `t3.json` | Generated installation used by this project (tracked; listed in `.sw/manifest.json`) |
| `tests/Sw.Tests.ps1` | Lifecycle, retired-surface migration, validator, hard-limit, doctor, global and context Pester coverage |
| `docs/workspace-state.md` | Current implemented state and authorization |
| `docs/workspace-outline.md` | Current design rules, assumptions and proposals |
| `docs/roadmap.md`, `docs/decisions.md`, `docs/research/`, `docs/remote-access.md` | Retained history/evidence, not current implementation authority |

## Workflow

Follow [AGENTS.md](../AGENTS.md), [workspace ownership](../.sw/workspace.md) and
[collaboration rules](../.sw/collaboration.md). The coordinating main thread
owns the approved task queue and dispatches independent packages to T3
worktree threads, which do not delegate further. Serialize writers and use one
validation owner per checkout. Commits and pull requests follow the
[Git flow](../.sw/workspace.md#git-flow) and its hard limits. Imported
cloud/task-branch procedures are historical, not an exception to current policy.

Edit the source rather than competing generated copies. Preview regeneration:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 update . -WhatIf
```

Apply an approved update with `sw.ps1 update .`, then validate. Do not
configure models or accounts merely to run checks; those are separate owner
opt-ins. Claude and Codex files are generated from `lib/` and `project/`: edit
those sources, never the generated `.claude/` or `.codex/` copies.

Adopter instructions live in [setup.md](setup.md); generated join instructions
come from `project/base/.sw/onboarding.md`. This checkout retains its existing
workspace Git policy and local-record choice; self-regeneration does not adopt
new-install defaults. Edit Git-policy snippets in `project/git-*.md`; rendering
selects one from `gitPolicy`, absent means legacy workspace policy. Licenses are
copied under `.sw/` without changing the host license.

## Validation

The kit supports Windows PowerShell 5.1 and PowerShell 7, and CI runs the suite
under both (`shell: powershell` and `shell: pwsh`). Local validation and CI use
Pester **5.6.1** explicitly; local dependency installation needs separate approval.
Do not silently select a newer major: Pester 6 changes filtered-mock fallthrough.
Updating the test dependency requires its own compatibility validation.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command 'Import-Module Pester -RequiredVersion 5.6.1 -Force -ErrorAction Stop; Invoke-Pester -Path tests -CI'
pwsh -NoProfile -Command 'Import-Module Pester -RequiredVersion 5.6.1 -Force -ErrorAction Stop; Invoke-Pester -Path tests -CI'
powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 validate -CheckLinks
powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 update . -WhatIf
git diff --check
```

Context-report and recovery-card regressions are the Pester block
`Context and recovery reporting` (`Invoke-Pester -Path tests -FullNameFilter
'Context and recovery reporting*'`). `sw context` and `sw validate` share
`Get-SwStartupBudget`; changing it changes both.

Offline fixtures must also run from a fresh checkout without ignored local
records/settings. Fixtures read generated comms docs from their tracked
`project/base/` sources, never from private task records. Upgrades from 0.3
(retired outputs, retired config choices, the old local Claude adapter) are the
Pester block `Retired surface migration`.

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
This Workspace's research opt-in (local task record `workspace-validation-adoption-v1/2026-10-05T054409Z-leader-closure-p2.md`,
which also opted into the since-retired `provider-setup` capability) is complete
locally; other projects' migrations and native acceptance remain separate gates.

Use disposable fixture directories for fresh `init`/`update` checks. Pester and
offline regression do not exercise real model access or runtime permissions;
keep those results separate from the historical bounded v1 live evidence. After human
publication, verify the exact remote SHA and both GitHub workflows; local Windows
success is not proof of hosted CI. No release/tag or account setup is
implied by a normal main-branch push.

Public-adoption regression is `Public adoption*` in `tests/Sw.Tests.ps1`:
new generic/research/Unreal, existing Git/non-Git, host files/application and
Git-state preservation, host Claude/Codex/T3 conflicts, host-owned legacy
configuration, preview/refusal complete trees, policy/privacy compatibility and
explicit backup-replacement. Synthetic application tests are not acceptance
against every adopter's real application.

### Human publication gates

1. Inspect selected diffs and new files for private data; never publish the
   local comparison audit or raw comms/backup/model files. No full history or
   credential audit is implied by static checks.
2. Commit only reviewed paths, routed by the [Git flow](../.sw/workspace.md#git-flow);
   `main` changes only by a human push or a merged pull request. Current
   `main` is development; choose any tag/release version deliberately,
   not from `VERSION` alone. Do not overwrite historical tags.
3. Verify remote SHA and both `ci` Windows shell jobs (Windows PowerShell 5.1
   and PowerShell 7), each with its fresh-install step, and `sw-validate` at that SHA
   before calling the published candidate ready.
   Local green results do not repair an old hosted run.
4. Human repository settings: enable private vulnerability reporting and
   confirm **Report a vulnerability** is available. Suggested About:
   "Project-local rules, workflow skills and task records for Claude Code and
   Codex through T3 Code, in new or existing repositories." Suggested topics:
   `t3code`, `claude-code`, `codex`, `ai-agents`, `powershell`,
   `developer-tools`; setup URL is the published `docs/setup.md`. Metadata is
   not changed by this task.

Do not describe the coordinating main thread's own checks as an independent
review (Codex review is the `review` skill); record any unavailable planned
review in the task/state record. No platform/native/account gap is silently
waived.
