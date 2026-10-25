#requires -Version 5.1
<#
.SYNOPSIS
  SuperWorkspace CLI. In the kit: every command. Inside a project (.sw/sw.ps1):
  the project commands only (validate, doctor, context, comms, user, gh, usage).
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File sw.ps1 init <project-path> -Profile unreal -Name MyGame
  powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 validate
#>
# No param block on purpose: plain $args keeps "-Name value" tokens bindable when
# splatted into the target function (a typed array would turn them positional).
$Command, $Arguments = $args
if (-not $Command) { $Command = 'help' }
$Arguments = @($Arguments | Where-Object { $null -ne $_ })
$ErrorActionPreference = 'Stop'
# A project copy (<root>/.sw/sw.ps1) defaults to its own project, wherever it is run from.
$env:SW_ROOT = if ((Split-Path $PSScriptRoot -Leaf) -eq '.sw') { Split-Path $PSScriptRoot -Parent } else { '' }
Import-Module (Join-Path $PSScriptRoot 'lib/Sw.Project.psm1') -Force -DisableNameChecking
$kit = Join-Path $PSScriptRoot 'lib/Sw.Kit.psm1'
if (Test-Path -LiteralPath $kit) { Import-Module $kit -Force -DisableNameChecking }

$commands = [ordered]@{
    init     = @('Initialize-SwProject', 'kit', 'Install into a repository root: init <path> -Profile generic|research|unreal [-Name] [-NoGitHub] [-GitPolicy host|workspace] [-Records local|tracked] [-GitHubTier 0|1|2] [-Adopt (backup and replace conflicts)] [-SelectionV1] [-Force (kit downgrade)] [-Capabilities research]')
    update   = @('Update-SwProject', 'kit', 'Re-apply to an installed project: update [<path>] [-Adopt] [-Force (kit downgrade)] [-SelectionV1] [-Capabilities <list>] [-GitPolicy host|workspace] [-Records local|tracked]')
    global   = @('Invoke-SwGlobal', 'kit', 'User-level rules: global install|check|backup [-ClaudeConfigDir <dirs>] [-CodexHome <dirs>] (absolute paths; quoted ; list or PowerShell array; env homes, else ~/.claude / ~/.codex) [-InstallRtk (legacy install only)]. Central delivery: global check|install|remove|backup -Delivery central-v1 -Harness codex|claude|both [-Component all|rules|skills] [-Skills <product-ids>] [-PersonalSkills <ids>] [-PersonalRules <shared,claude,codex>] (comma lists or arrays). install/remove write a marked block per rules file (with backups) and one junction per selected skill, each with a record receipt; existing folders, files and unowned or changed links are kept and reported, never replaced. backup requires -WhatIf. Initial skills install requires -Skills. Codex skills share ~/.agents/skills regardless of -CodexHome. Project migration is not implemented; legacy schema1 writes refuse schema2 records.')
    validate = @('Test-SwProject', 'project', 'Static workspace contract check: validate [-Path] [-CheckLinks (local Markdown links, docs/ included)]')
    doctor   = @('Test-SwDoctor', 'project', 'Read-only setup check for a contributor: doctor [-User <name>] [-CodexHome <dir>]')
    context  = @('Get-SwContext', 'project', 'Read-only context/evidence report, not an approval: context [-Task <id>] [-StateFile <rel.md>] [-StateSection <heading>]')
    comms    = @('Invoke-SwComms', 'project', 'Messages and task records: comms send|inbox|event|close|archive ...')
    user     = @('Add-SwUser', 'project', 'Record a contributor and create their inbox: user <name>')
    gh       = @('Invoke-SwGitHub', 'project', 'GitHub helpers: gh status (read-only) | gh labels (human-run write)')
    usage    = @('Get-SwUsage', 'project', 'Workspace estimates: RTK output savings and the static startup budget; not provider request telemetry')
}

if ($Command -in 'help', '-h', '--help', '/?' -or -not $commands.Contains($Command)) {
    if ($Command -notin 'help', '-h', '--help', '/?') { Write-Output "Unknown command: $Command`n" }
    $version = Join-Path $PSScriptRoot 'VERSION'
    Write-Output "SuperWorkspace $(if (Test-Path -LiteralPath $version) { (Get-Content -LiteralPath $version).Trim() } else { '(project copy)' })"
    foreach ($c in $commands.GetEnumerator()) {
        if ($c.Value[1] -eq 'kit' -and -not (Test-Path -LiteralPath $kit)) { continue }
        Write-Output ('  {0,-9} {1}' -f $c.Key, $c.Value[2])
    }
    Write-Output '  Every writing command accepts -WhatIf.'
    exit $(if ($Command -in 'help', '-h', '--help', '/?') { 0 } else { 2 })
}

$fn = $commands[$Command][0]
if (-not (Get-Command $fn -ErrorAction SilentlyContinue)) { Write-Output "'$Command' is a kit command; run it from your SuperWorkspace clone."; exit 2 }
try { & $fn @Arguments }
catch [System.Management.Automation.ParameterBindingException] {
    if ($Command -ne 'global') { throw }
    Write-Output "Usage: $($_.Exception.Message)"; exit 2
}
if ($Command -in 'init', 'update', 'validate', 'doctor', 'context', 'global') { exit $LASTEXITCODE }
