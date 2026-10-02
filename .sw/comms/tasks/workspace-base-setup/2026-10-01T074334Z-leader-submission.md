# workspace-base-setup - submission - 2026-10-01T074334Z - leader

- **Author / audience:** Project Leader (GPT-6.1 Sol); owner and future sessions.
- **Approval:** actual base setup requested by the owner; scope in the assignment.
- **Scope / acceptance:** supplied initializer run; installed definitions, project
  identity, startup state, navigation, and static checks complete. Existing kit
  sources and external research untouched. No outline extensions implemented.
- **Status:** complete for base initialization and documentation. Optional runtime
  verification and global launcher repair are not claimed complete.
- **Branch / base:** unborn local `main`; no commit SHA, remote, or published base.
- **Checked revision / changed:** installed `.agents/`, `.opencode/`, `.sw/`,
  `.github/`, `opencode.jsonc`, `.gitignore`, and project-owned `AGENTS.md`,
  `README.md`, `docs/workspace-state.md`, and this task directory. All uncommitted;
  pre-existing source files also remain untracked, not part of a task commit.
- **Owners / dependencies:** Leader owns implementation, static validation, and
  focused read-only review. No other writers, new dependencies, or binary assets.
- **Decisions / remaining:** generic profile, GitHub tier 0, solo mode. Default
  primary agent is `project-leader`. Local model mapping and Claude adapter are
  not configured. The approved v0.2 outline remains provisional and separate.
- **Validation:** Leader, 2026-10-01 UTC:
  - `pwsh -NoProfile -File .\sw.ps1 init . -Profile generic -Name Workspace
    -WhatIf`: PASS, no conflicts; then the same command without `-WhatIf`: PASS.
  - `pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks`: PASS; 8,555 contract
    checks, 723 static permission cases; Leader startup 8,148 bytes under 12,100.
  - Final `pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks` rerun after
    updating startup status and adding this submission: PASS.
  - `git diff --check`: PASS, but no tracked changes exist yet. Separate
    `Select-String -LiteralPath $paths -Pattern '[\t ]+$'`: PASS on five Markdown
    files. `$paths` is `@('AGENTS.md', 'README.md', 'docs/workspace-state.md')`
    plus every `*.md` file in `.sw/comms/tasks/workspace-base-setup/`.
  - Supplementary read-only PowerShell check below: PASS at 07:43:34 UTC;
    43 managed hashes, both managed AGENTS blocks, and six documentation links.
- **Review:** Leader checked project-owned versus generated boundaries, startup
  authorization, navigation, and limits. No outstanding in-scope findings.
  This was a focused local review, not an independent security audit.
- **Not validated / risks:** `doctor` failed on the existing npm OpenCode launcher
  (`StandardOutputEncoding is only supported when standard output is redirected`).
  No runtime discovery, permission-denial execution, UI test, model routing test,
  or global repair. Supplementary check attempts first hit Windows argument
  quoting, then a non-exported helper; corrected with encoded script invocation
  and the kit helper's module scope, without changing kit code or permissions.
- **Publication:** local-only; no staging, commits, remote, or pushes.
- **Next action:** owner opens a fresh session here. Any model mapping, launcher
  repair, runtime tests, or outline implementation needs its own scoped request.

## Supplementary check

Executed as `$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($check))`
and `pwsh -NoProfile -OutputFormat Text -EncodedCommand $encoded`, with `$check`:

```powershell
$ErrorActionPreference = 'Stop'
Import-Module .\lib\Sw.Project.psm1 -Force -DisableNameChecking
Import-Module .\lib\Sw.Kit.psm1 -Force -DisableNameChecking
$manifest = Read-SwJson '.sw/manifest.json'
foreach ($entry in $manifest['files'].GetEnumerator()) {
    if ((Get-SwHash (Read-SwText $entry.Key)) -cne $entry.Value) { throw "Managed file differs from installed manifest: $($entry.Key)" }
}
$agents = Read-SwText 'AGENTS.md'
$template = Read-SwText 'project/base/AGENTS.md'
$coreMatches = & (Get-Module Sw.Kit) { param($a, $t) (Get-SwBlockBody $a 'core') -ceq (Get-SwBlockBody $t 'core') } $agents $template
if (-not $coreMatches) { throw 'Managed AGENTS core block changed' }
$profile = Read-SwText 'project/profiles/generic/AGENTS.section.md'
$profileMatches = & (Get-Module Sw.Kit) { param($a, $p) (Get-SwBlockBody $a 'profile') -ceq $p.Trim("`n") } $agents $profile
if (-not $profileMatches) { throw 'Managed AGENTS profile block changed' }
$links = 0
foreach ($file in @('README.md', 'docs/workspace-state.md')) {
    foreach ($match in [regex]::Matches((Read-SwText $file), '\]\(([^\s)]+)\)')) {
        $target = [Uri]::UnescapeDataString(($match.Groups[1].Value -split '#', 2)[0])
        $parent = Split-Path $file -Parent
        if (-not $parent) { $parent = '.' }
        if (-not (Test-Path -LiteralPath (Join-Path $parent $target))) { throw "Missing link in ${file}: $target" }
        $links++
    }
}
Write-Output "PASS: $($manifest['files'].Count) managed hashes, both managed AGENTS blocks, and $links project documentation links."
Write-Output ([DateTime]::UtcNow.ToString('yyyy-MM-ddTHHmmssZ'))
```
