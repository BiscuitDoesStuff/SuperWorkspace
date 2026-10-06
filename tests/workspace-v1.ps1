#requires -Version 7.2
[CmdletBinding()]
param([switch]$ParseOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$module = Join-Path $root 'lib/Sw.Project.psm1'
foreach ($file in $module, (Join-Path $root 'sw.ps1'), $PSCommandPath) {
    $tokens = $null; $errors = $null
    $null = [Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw ($errors.Message -join "`n") }
}
Import-Module $module -Force -DisableNameChecking
Write-Output 'PASS: PowerShell parser and source module import.'
if ($ParseOnly) { exit 0 }

$script:checks = 0
function Assert($Condition, [string]$Message) {
    $script:checks++
    if (-not $Condition) { throw $Message }
}
function Reject([scriptblock]$Action, [string]$Pattern) {
    $message = $null
    try { $null = & $Action } catch { $message = $_.Exception.Message }
    Assert ($message -and $message -match $Pattern) "Expected rejection matching $Pattern"
}
function ValidateFixture([int]$Expected, [string]$Pattern = '') {
    $output = @(Test-SwProject -Path $fixture -Quiet)
    Assert ($LASTEXITCODE -eq $Expected) "Fixture validate expected $Expected : $($output -join '; ')"
    if ($Pattern) { Assert (($output -join "`n") -match $Pattern) "Expected fixture error: $Pattern" }
}
function GenerateFixture {
    Invoke-SwClaude enable -Path $fixture | Out-Null
    Get-SwClaudeFiles $fixture
}

# Unique disposable fixture, inside the approved ignored subtree; no git init.
$scratch = Join-Path $root '.scratch/workspace-v1'
# Fixtures inherit the real repository, so isolate only this disposable subtree.
# Never modify repository-level ignore rules or an existing local ignore file.
if (-not (Test-Path (Join-Path $scratch '.gitignore'))) { Write-SwFile (Join-Path $scratch '.gitignore') "*`n" }
$fixture = Join-Path $scratch "$([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $fixture | Out-Null
Write-Output "Fixture evidence: $fixture"
$manifest = Read-SwJson (Join-Path $root '.sw/manifest.json')
foreach ($rel in @($manifest['files'].Keys) + 'AGENTS.md', '.sw/config.json') {
    Write-SwFile (Join-Path $fixture $rel) (Read-SwText (Join-Path $root $rel))
}
Write-SwFile (Join-Path $fixture '.sw/roles.json') (Read-SwText (Join-Path $root 'project/roles.json'))
Write-SwFile (Join-Path $fixture '.sw/workspace.md') (Read-SwText (Join-Path $root 'project/base/.sw/workspace.md'))
Write-SwFile (Join-Path $fixture '.sw/lib/Sw.Project.psm1') (Read-SwText $module)
Reject { Get-SwClaudeFiles $fixture } 'explicit local.*map'
Write-SwFile (Join-Path $fixture '.opencode/opencode.jsonc') '{"tiers":{"light":"opus"}}'
Reject { Get-SwClaudeFiles $fixture } 'agents\[role\].model'

foreach ($alias in 'opus', 'sonnet', 'haiku', 'fable', 'best', 'opus[1m]', 'sonnet[1m]') {
    Assert ((Get-SwClaudeModel $alias) -ceq $alias) "Alias $alias must remain explicit"
}
Assert ((Get-SwClaudeModel 'anthropic/claude-sonnet-4-5') -ceq 'claude-sonnet-4-5') 'Anthropic ID must retain native ID, not guess an alias'
Assert ((Get-SwClaudeModel 'claude-opus-4-6[1m]') -ceq 'claude-opus-4-6[1m]') 'Native ID must remain explicit'
Assert ($null -eq (Get-SwClaudeModel 'openai/gpt-fixture')) 'Non-Claude provider must not generate a Claude model'
foreach ($bad in '', 'default', 'inherit', 'opusplan', 'opus#high', "opus`n", 'gpt-fixture', 'anthropic/opus', 'openrouter/anthropic/claude-opus') {
    Reject { Get-SwClaudeModel $bad } 'explicit|Unsupported'
}

# Actual Set-SwTiers schema, not an invented tier dictionary.
Set-SwTiers -Path $fixture -Light 'opus' -Standard 'sonnet' -High 'haiku' -Force | Out-Null
$mapPath = Join-Path $fixture '.opencode/opencode.jsonc'
$map = Read-SwJson $mapPath
Assert ($map['agents']['project-developer']['model'] -ceq 'opus') 'Set-SwTiers must map role models'
Assert (-not $map['agents'].Contains('project-leader')) 'Session-tier Leader is unmapped without an explicit owner edit'
$files = GenerateFixture
Assert ($files['.claude/agents/project-developer.md'] -cmatch '(?m)^model: opus$') 'Light role alias from local map'
Assert ($files['.claude/agents/project-review.md'] -cmatch '(?m)^model: sonnet$') 'Standard role alias from local map'
Assert ($files['.claude/agents/project-review.md'] -cmatch '(?m)^tools: Read, Grep, Glob, Skill$') 'Reviewer must have no shell/write tools'
Assert ($files['.claude/agents/project-developer.md'] -notmatch 'already loaded') 'Worker cannot assume loaded instructions'
Assert ($files['.claude/commands/work.md'] -match 'STOP:') 'Unmapped Leader command cannot silently inherit'
$settings = $files['.claude/settings.json'] | ConvertFrom-Json -AsHashtable
Assert (-not $settings.Contains('hooks')) 'No unconditional Leader startup hook in worker/main sessions'
Assert (-not $settings.Contains('model')) 'No session model pin in settings'
Assert ('Bash(*)' -cnotin $settings['permissions']['allow']) 'No blanket Bash allow'
foreach ($rule in 'Bash(git push)', 'Bash(git -* push *)', 'Bash(* git push *)', 'Bash(* git -* push *)', 'Bash(rtk git push *)', 'Bash(git reset --hard *)', 'Bash(git clean *)', 'Bash(git stash *)') {
    Assert ($rule -cin $settings['permissions']['deny']) "Required deny presence: $rule"
}
foreach ($rule in 'Bash(git commit)', 'Bash(git -* commit *)', 'Bash(bash *-c *git*)', 'Bash(pwsh *git*)', 'Bash(pwsh *-enc*)', 'Bash(rtk powershell *git*)') {
    Assert ($rule -cin $settings['permissions']['ask']) "Required ask presence: $rule"
}
foreach ($rule in Get-SwClaudeGitRules) { Assert ($rule.Rule -cin $settings['permissions'][$rule.Effect]) 'Same-source Git rule presence (not Claude evaluation)' }

$importFile = Join-Path $fixture '.claude/CLAUDE.md'
$expectedRoot = Join-Path $fixture 'AGENTS.md'
$import = (Read-SwText $importFile).Trim().Substring(1)
$resolved = [IO.Path]::GetFullPath((Join-Path (Split-Path $importFile) $import))
Assert ($resolved -eq $expectedRoot) 'Import resolves relative to containing file to canonical root'
Assert ((Read-SwText $resolved) -ceq (Read-SwText $expectedRoot)) 'Resolved canonical rule content'
Assert (-not (Test-Path (Join-Path $fixture '.claude/AGENTS.md'))) 'No duplicate rules copy'
ValidateFixture 0

Write-SwFile $importFile "@AGENTS.md`n"
ValidateFixture 1 'Claude import must resolve'
Write-SwFile $importFile $files['.claude/CLAUDE.md']
$settings['permissions']['deny'] = @($settings['permissions']['deny'] | Where-Object { $_ -cne 'Bash(git -* push *)' })
Write-SwFile (Join-Path $fixture '.claude/settings.json') (ConvertTo-SwJson $settings)
ValidateFixture 1 'Claude Git rule missing'
Write-SwFile (Join-Path $fixture '.claude/settings.json') $files['.claude/settings.json']
$reviewPath = Join-Path $fixture '.claude/agents/project-review.md'
Write-SwFile $reviewPath ($files['.claude/agents/project-review.md'].Replace('tools: Read, Grep, Glob, Skill', 'tools: Read, Grep, Glob, Bash, Skill'))
ValidateFixture 1 'tools must be'
Write-SwFile $reviewPath $files['.claude/agents/project-review.md']
Write-SwFile $reviewPath ($files['.claude/agents/project-review.md'].Replace('model: sonnet', 'model: opus'))
ValidateFixture 1 'model must match'
Write-SwFile $reviewPath $files['.claude/agents/project-review.md']

$map['agents']['project-developer']['model'] = 'anthropic/claude-sonnet-4-5'
$map['agents']['project-review']['model'] = 'openai/gpt-fixture'
Write-SwFile $mapPath (ConvertTo-SwJson $map)
$files = GenerateFixture
Assert ($files['.claude/agents/project-developer.md'] -cmatch '(?m)^model: claude-sonnet-4-5$') 'Native Claude ID generation'
Assert (-not $files.Contains('.claude/agents/project-review.md')) 'Non-Claude role not generated'
Assert (-not (Test-Path $reviewPath)) 'Stale generated non-Claude role removed'
Assert ($files['.claude/commands/review.md'] -match 'STOP:' -and $files['.claude/commands/review.md'] -notmatch 'Agent tool') 'Non-Claude command cannot dispatch nonexistent worker'
ValidateFixture 0
$map['agents'].Remove('project-developer') | Out-Null
Write-SwFile $mapPath (ConvertTo-SwJson $map)
$files = GenerateFixture
Assert (-not $files.Contains('.claude/agents/project-developer.md')) 'Unmapped worker omitted without fallback'
Assert ($files['.claude/commands/validate.md'] -match 'STOP:') 'Unmapped inline command cannot impersonate'
ValidateFixture 0
$map['agents']['project-research']['model'] = ''
Write-SwFile $mapPath (ConvertTo-SwJson $map)
Reject { Get-SwClaudeFiles $fixture } 'explicit'
Set-SwTiers -Path $fixture -Light 'openai/gpt-fixture' -Standard 'openai/gpt-fixture' -Force | Out-Null
Reject { Get-SwClaudeFiles $fixture } 'no explicit Claude'
Reject { Set-SwTiers -Path $fixture -Light 'opus#high' -Force } 'model-only'
# P2 launch prechecks and safe arguments. Never resolve/invoke a real model CLI.
$moduleScope = Get-Module Sw.Project
$stub = Join-Path $fixture 'native-stub.ps1'
$capture = Join-Path $fixture 'native-argv.json'
Write-SwFile $stub @'
[IO.File]::WriteAllText($env:SW_TEST_ARGV, (ConvertTo-Json -InputObject @($args)))
if ($env:SW_TEST_THROW -eq '1') { throw 'fixture native failure' }
$global:LASTEXITCODE = [int]$env:SW_TEST_EXIT
'@
$env:SW_TEST_NATIVE = $stub; $env:SW_TEST_ARGV = $capture; $env:SW_TEST_EXIT = '0'
& $moduleScope {
    function script:Get-Command {
        param($Name, $CommandType, $ErrorAction)
        if ($env:SW_TEST_MISSING -eq '1') { return }
        [pscustomobject]@{ Source = $env:SW_TEST_NATIVE }
    }
}
try {
    $task = 'fixture-task'
    $taskDir = Join-Path $fixture ".sw/comms/tasks/$task"
    Write-SwFile (Join-Path $taskDir 'fixture-approval.md') '# Fixture approval only; no live authority.'
    $approvalHash = (Get-FileHash (Join-Path $taskDir 'fixture-approval.md')).Hash
    Reject { Invoke-SwSession start project-developer '../unsafe' -Path $fixture -DryRun } 'Invalid Task'
    Reject { Invoke-SwSession start project-developer '-flag' -Path $fixture -DryRun } 'flag prefix'
    Reject { Invoke-SwSession start missing $task -Path $fixture -DryRun } 'Unknown'
    Reject { Invoke-SwSession start explore $task -Path $fixture -DryRun } 'unsupported'
    Reject { Invoke-SwSession start project-developer absent -Path $fixture -DryRun } 'Existing task records'
    Reject { Invoke-SwSession start project-leader $task -Path $fixture -DryRun } 'requires explicit -Model'
    Reject { Invoke-SwSession start project-developer $task -Path $fixture -Model opus -DryRun } 'Conflicting worker'
    $mapBefore = (Get-FileHash $mapPath).Hash
    $before = @(Get-ChildItem -LiteralPath $fixture -Recurse -File | ForEach-Object { "$($_.FullName):$((Get-FileHash $_.FullName).Hash)" }) -join "`n"
    $launch = Invoke-SwSession start project-developer $task -Path $fixture -DryRun
    Assert ($launch.Tool -eq 'opencode' -and $launch.Arguments[0] -eq 'mini') 'Explicit interactive OpenCode mini route'
    Assert ($launch.RequestedModel -ceq 'openai/gpt-fixture' -and $launch.Arguments[2] -ceq $launch.RequestedModel -and $launch.Arguments[4] -eq 'project-developer') 'Worker explicit model/role argv'
    Assert ($null -eq $launch.SessionId -and $null -eq $launch.LaunchId) 'Dry-run cannot invent a native identity'
    $launch = Invoke-SwSession start project-developer $task -Path $fixture -Headless -WhatIf
    Assert ($launch.Arguments[0] -eq 'run') 'Supported OpenCode headless argv only'
    Assert (($launch.Arguments[-1] -match 'actual artifacts/current approval/assignment and unknown effects') -and ($launch.Arguments[-1] -match 'not approval')) 'Kickoff/resume reconciliation contract'
    $launch = Invoke-SwSession start project-leader $task -Path $fixture -Model 'openai/primary-fixture' -DryRun
    Assert ($launch.RequestedModel -ceq 'openai/primary-fixture' -and $launch.Arguments[4] -eq 'project-leader') 'Explicit primary model without inventing a map entry'
    $after = @(Get-ChildItem -LiteralPath $fixture -Recurse -File | ForEach-Object { "$($_.FullName):$((Get-FileHash $_.FullName).Hash)" }) -join "`n"
    Assert ($before -ceq $after -and -not (Test-Path $capture)) 'Dry-run/WhatIf no event/config/process writes'
    $env:SW_TEST_MISSING = '1'
    Reject { Invoke-SwSession start project-developer $task -Path $fixture -DryRun } 'not installed'
    $env:SW_TEST_MISSING = '0'
    Move-Item -LiteralPath $mapPath -Destination "$mapPath.saved"
    try { Reject { Invoke-SwSession start project-developer $task -Path $fixture -DryRun } 'Explicit local.*map required' }
    finally { Move-Item -LiteralPath "$mapPath.saved" -Destination $mapPath }
    Write-SwFile $mapPath '{}'
    Reject { Invoke-SwSession start project-developer $task -Path $fixture -DryRun } 'Malformed local'
    Write-SwFile $mapPath '{"agents":{"project-developer":{"model":"inherit"}}}'
    Reject { Invoke-SwSession start project-developer $task -Path $fixture -DryRun } 'explicit'
    Write-SwFile $mapPath '{"agents":{}}'
    Reject { Invoke-SwSession start project-developer $task -Path $fixture -DryRun } 'no inheritance'
    Write-SwFile $mapPath '{"agents":{"project-developer":{"model":"openai/gpt-fixture","disable":true}}}'
    Reject { Invoke-SwSession start project-developer $task -Path $fixture -DryRun } 'enabled explicit'
    $workerFile = Join-Path $fixture '.opencode/agents/project-developer.md'
    $workerText = Read-SwText $workerFile
    Write-SwFile $workerFile ($workerText.Replace('mode: all', "mode: all`nmodel: openai/stale"))
    Reject { Invoke-SwSession start project-developer $task -Path $fixture -DryRun } 'Unknown or duplicate key: model'
    Write-SwFile $workerFile $workerText
    $configPath = Join-Path $fixture '.sw/config.json'
    $configText = Read-SwText $configPath
    Write-SwFile $configPath '[]'
    Reject { Invoke-SwSession start project-developer $task -Path $fixture -DryRun } 'Malformed workspace'
    Write-SwFile $configPath $configText
    $ocPath = Join-Path $fixture 'opencode.jsonc'
    $ocText = Read-SwText $ocPath
    Write-SwFile $ocPath '[]'
    Reject { Invoke-SwSession start project-developer $task -Path $fixture -DryRun } 'Malformed shared'
    Write-SwFile $ocPath $ocText
    # Mixed map, no invented tier dictionary; Claude Leader explicitly mapped.
    $map = @{ agents = @{ 'project-leader' = @{ model = 'sonnet' }; 'project-developer' = @{ model = 'openai/gpt-fixture' }; 'project-review' = @{ model = 'anthropic/claude-sonnet-4-5' } } }
    Write-SwFile $mapPath (ConvertTo-SwJson $map)
    Reject { Invoke-SwSession start project-review $task -Path $fixture -DryRun } 'stale Claude adapter'
    $files = GenerateFixture
    Move-Item -LiteralPath $importFile -Destination "$importFile.saved"
    try { Reject { Invoke-SwSession start project-review $task -Path $fixture -DryRun } 'Missing or stale Claude adapter' }
    finally { Move-Item -LiteralPath "$importFile.saved" -Destination $importFile }
    $oc = Read-SwJson $ocPath
    $oc['agents']['project-developer'] = @{ model = 'openai/stale-fixture' }
    Write-SwFile $ocPath (ConvertTo-SwJson $oc)
    Reject { Invoke-SwSession start project-developer $task -Path $fixture -DryRun } 'Conflicting selected role configuration'
    Write-SwFile $ocPath $ocText
    $map['agents']['project-developer']['mode'] = 'subagent'
    Write-SwFile $mapPath (ConvertTo-SwJson $map)
    Reject { Invoke-SwSession start project-developer $task -Path $fixture -DryRun } 'Conflicting selected role configuration'
    $map['agents']['project-developer'].Remove('mode')
    Write-SwFile $mapPath (ConvertTo-SwJson $map)
    $launch = Invoke-SwSession start project-leader $task -Path $fixture -Model sonnet -DryRun
    Assert ($launch.Tool -eq 'claude' -and '--append-system-prompt-file' -in $launch.Arguments -and '--agent' -notin $launch.Arguments) 'Leader startup only, no nonexistent Leader agent'
    Reject { Invoke-SwSession start project-leader $task -Path $fixture -Model opus -DryRun } 'conflicts'
    $launch = Invoke-SwSession start project-review $task -Path $fixture -DryRun
    Assert ($launch.NativeModel -ceq 'claude-sonnet-4-5' -and '--agent' -in $launch.Arguments) 'Claude native model/worker argv'
    Assert ('--append-system-prompt-file' -notin $launch.Arguments -and '--tools' -in $launch.Arguments -and 'Read, Grep, Glob, Skill' -in $launch.Arguments -and 'Agent' -in $launch.Arguments) 'Read-only standalone worker tools/no delegation/no Leader hook'
    Reject { Invoke-SwSession start project-review $task -Path $fixture -Headless -DryRun } 'Headless Claude'
    Write-SwFile $reviewPath ($files['.claude/agents/project-review.md'].Replace('model: claude-sonnet-4-5', 'model: opus'))
    Reject { Invoke-SwSession start project-review $task -Path $fixture -DryRun } 'stale Claude adapter'
    Write-SwFile $reviewPath $files['.claude/agents/project-review.md']
    # Invocation success is merely exit metadata; events must remain immutable.
    $null = Invoke-SwSession start project-developer $task -Path $fixture -Headless
    Assert ($LASTEXITCODE -eq 0 -and (Test-Path $capture)) 'Native stub invoked, exit 0 propagated'
    $argv = Read-SwJson $capture
    Assert ($argv[0] -eq 'run' -and $argv[2] -ceq 'openai/gpt-fixture' -and $argv[4] -eq 'project-developer') 'Stub receives safe separated model/role argv'
    $events = @(Get-ChildItem $taskDir -Filter '*session-progress*.md')
    Assert ($events.Count -eq 2) 'Launch and exit immutable task events'
    $original = @{}; foreach ($event in $events) { $original[$event.FullName] = (Get-FileHash $event.FullName).Hash }
    $exitText = Read-SwText ($events | Where-Object { (Read-SwText $_.FullName) -match 'exited; acceptance pending' }).FullName
    Assert ($exitText -match 'Session ID:\*\* unknown' -and $exitText -match 'observed model unknown' -and $exitText -match 'not accepted' -and $exitText -notmatch [regex]::Escape($launch.Arguments[-1])) 'Unknown identity/artifact; no prompt retention'
    & $moduleScope { function script:Get-SwUtc { '2000-01-01T000000Z' } }
    $env:SW_TEST_EXIT = '7'
    $null = Invoke-SwSession start project-developer $task -Path $fixture -Headless
    Assert ($LASTEXITCODE -eq 7) 'Native nonzero exit propagated'
    $null = Invoke-SwSession start project-developer $task -Path $fixture -Headless
    $events = @(Get-ChildItem $taskDir -Filter '2000-01-01T000000Z-session-progress*.md')
    Assert ($events.Count -eq 4 -and @($events.Name | Select-Object -Unique).Count -eq 4) 'Same UTC event collisions cannot overwrite'
    Assert (@($events | Where-Object { (Read-SwText $_.FullName) -match 'exit-failure; effects unknown' }).Count -eq 2) 'Failed exit recovery events'
    $env:SW_TEST_THROW = '1'
    Reject { Invoke-SwSession start project-review $task -Path $fixture } 'effects/session identity unknown'
    Assert (@(Get-ChildItem $taskDir -Filter '*.md' | Where-Object { (Read-SwText $_.FullName) -match 'invocation-failure' }).Count -eq 1) 'Thrown invocation recorded without raw exception/transcript'
    foreach ($file in $original.Keys) { Assert ((Get-FileHash $file).Hash -ceq $original[$file]) 'Previously emitted events unchanged' }
    Assert ((Get-FileHash (Join-Path $taskDir 'fixture-approval.md')).Hash -ceq $approvalHash) 'Approval immutable; launch creates no authority'
    # The real CLI dispatcher, with only a disposable PATH shim, preserves argv/exits.
    # A fresh process cannot inherit module mocks; no installed model binary is run.
    $shimDir = Join-Path $fixture 'shim'
    Write-SwFile (Join-Path $shimDir 'opencode.ps1') (Read-SwText $stub)
    $oldPath = $env:PATH
    $env:SW_TEST_THROW = '0'; $env:SW_TEST_EXIT = '9'
    try {
        $env:PATH = "$shimDir$([IO.Path]::PathSeparator)$oldPath"
        & pwsh -NoProfile -File (Join-Path $root 'sw.ps1') session start project-developer $task -Path $fixture -Headless *> (Join-Path $fixture 'cli-stub.log')
        Assert ($LASTEXITCODE -eq 9) 'CLI dispatcher propagates nonzero stub exit'
        $argv = Read-SwJson $capture
        Assert ($argv[0] -eq 'run' -and $argv[2] -ceq 'openai/gpt-fixture') 'CLI dispatcher safe separated argv'
    } finally { $env:PATH = $oldPath }
    # P1a: a selected role's effective policy is checked, with the validator's own rules, before discovery,
    # event creation or any process. Both selected roles run on the OpenCode route so no adapter is involved.
    Invoke-SwClaude disable -Path $fixture | Out-Null
    Assert (-not (Test-Path (Join-Path $fixture '.claude/.sw-generated'))) 'Disable removed the verified adapter, with no replacement map needed'
    Write-SwFile $mapPath '{"agents":{"project-developer":{"model":"openai/gpt-fixture"},"project-review":{"model":"openai/gpt-fixture"}}}'
    $env:SW_TEST_THROW = '0'; $env:SW_TEST_EXIT = '0'
    foreach ($role in 'project-developer', 'project-review') {
        $roleFile = Join-Path $fixture ".opencode/agents/$role.md"
        $pristine = Read-SwText $roleFile
        $launch = Invoke-SwSession start $role $task -Path $fixture -DryRun
        Assert ($launch.Tool -eq 'opencode') "$role valid policy still launches (dry-run)"
        ValidateFixture 0
        $variants = [ordered]@{
            omitted = { param($t) [regex]::Replace($t, '(?s)\npermissions:\n.*?\n---\n', "`n---`n") }
            empty = { param($t) [regex]::Replace($t, '(?s)\npermissions:\n.*?\n---\n', "`npermissions:`n---`n") }
            malformed = { param($t) $t.Replace("    resource: `"*`"`n    effect: allow`n", "    resource: `"*`"`n") }
            stale = { param($t) $t.Replace("resource: `"git push *`"`n    effect: deny", "resource: `"git push *`"`n    effect: ask") }
        }
        foreach ($variant in $variants.Keys) {
            Write-SwFile $roleFile (& $variants[$variant] $pristine)
            Assert ((Read-SwText $roleFile) -cne $pristine) "$role $variant mutation applied"
            $eventsBefore = @(Get-ChildItem $taskDir -Filter '*session-progress*.md').Count
            Remove-Item -LiteralPath $capture -Force -ErrorAction SilentlyContinue
            Reject { Invoke-SwSession start $role $task -Path $fixture -Headless } 'Selected role policy rejected'
            Reject { Invoke-SwSession start $role $task -Path $fixture -DryRun } 'Selected role policy rejected'
            Assert (@(Get-ChildItem $taskDir -Filter '*session-progress*.md').Count -eq $eventsBefore -and -not (Test-Path $capture)) "$role $variant`: no event and no native invocation"
            ValidateFixture 1 'Session rule drift|needs string action|STATIC'
        }
        Write-SwFile $roleFile $pristine
        # Overlays: a later shared or local override must not undermine the policy just checked.
        $localBase = Read-SwText $mapPath
        $overlays = @(
            @{ Path = $mapPath; Edit = { param($j) $j['agents'][$role]['permissions'] = @(@{ action = 'shell'; resource = 'git push *'; effect = 'allow' }) } }
            @{ Path = $ocPath; Edit = { param($j) $j['agents'][$role] = @{ permissions = @(@{ action = 'shell'; resource = 'git push *'; effect = 'allow' }) } } }
        )
        foreach ($overlay in $overlays) {
            $before = Read-SwText $overlay.Path
            $json = Read-SwJson $overlay.Path
            & $overlay.Edit $json
            Write-SwFile $overlay.Path (ConvertTo-SwJson $json)
            $eventsBefore = @(Get-ChildItem $taskDir -Filter '*session-progress*.md').Count
            Remove-Item -LiteralPath $capture -Force -ErrorAction SilentlyContinue
            Reject { Invoke-SwSession start $role $task -Path $fixture -Headless } 'Selected role policy rejected|Conflicting'
            Assert (@(Get-ChildItem $taskDir -Filter '*session-progress*.md').Count -eq $eventsBefore -and -not (Test-Path $capture)) "$role overlay: no event and no native invocation"
            ValidateFixture 1
            Write-SwFile $overlay.Path $before
        }
        ValidateFixture 0
    }
    $null = Invoke-SwSession start project-review $task -Path $fixture -Headless
    Assert ($LASTEXITCODE -eq 0 -and (Test-Path $capture)) 'Restored valid policy launches exactly the stub again'
    # P1c: independent concurrent launches at one fixed clock keep distinct, complete launch/exit pairs per
    # LaunchId, never overwrite earlier records, and run the native stub exactly once per launch.
    $countDir = Join-Path $fixture 'race-count'
    New-Item -ItemType Directory -Path $countDir | Out-Null
    $countStub = Join-Path $fixture 'native-count-stub.ps1'
    Write-SwFile $countStub "[IO.File]::WriteAllText((Join-Path `$env:SW_TEST_COUNT_DIR ([guid]::NewGuid().ToString('N'))), 'x')`n`$global:LASTEXITCODE = 0`n"
    $env:SW_TEST_NATIVE = $countStub; $env:SW_TEST_COUNT_DIR = $countDir
    $raceTask = 'race-task'
    $raceDir = Join-Path $fixture ".sw/comms/tasks/$raceTask"
    Write-SwFile (Join-Path $raceDir 'race-approval.md') '# Fixture approval only; no live authority.'
    $priorHash = (Get-FileHash (Join-Path $raceDir 'race-approval.md')).Hash
    $writers = 4
    $barrier = [Threading.Barrier]::new($writers)
    $results = @(1..$writers | ForEach-Object -ThrottleLimit $writers -Parallel {
        Import-Module $using:module -Force -DisableNameChecking
        & (Get-Module Sw.Project) {
            function script:Get-Command { param($Name, $CommandType, $ErrorAction) [pscustomobject]@{ Source = $env:SW_TEST_NATIVE } }
            function script:Get-SwUtc { '2000-01-01T000000Z' }
        }
        ($using:barrier).SignalAndWait()
        try { $l = Invoke-SwSession start project-developer $using:raceTask -Path $using:fixture -Headless; [pscustomobject]@{ Ok = $true; LaunchId = $l.LaunchId; Exit = $l.ExitCode } }
        catch { [pscustomobject]@{ Ok = $false; Error = $_.Exception.Message } }
    })
    $failures = @($results | Where-Object { -not $_.Ok } | ForEach-Object { $_.Error })
    Assert ($failures.Count -eq 0) "Concurrent launches all recorded: $($failures -join '; ')"
    Assert (@($results.LaunchId | Select-Object -Unique).Count -eq $writers) 'Distinct launch IDs'
    Assert (@(Get-ChildItem $countDir).Count -eq $writers) 'Exactly one native stub run per launch'
    $raceEvents = @(Get-ChildItem $raceDir -Filter '*session-progress-*.md')
    Assert ($raceEvents.Count -eq 2 * $writers -and @($raceEvents.Name | Select-Object -Unique).Count -eq 2 * $writers) 'Distinct launch and exit event files, none lost'
    foreach ($id in $results.LaunchId) {
        $pair = @($raceEvents | Where-Object { (Read-SwText $_.FullName) -match "Launch ID:\*\* $id" })
        Assert ($pair.Count -eq 2) 'Each launch id has exactly its launch and exit event'
        $pairText = ($pair | ForEach-Object { Read-SwText $_.FullName }) -join "`n"
        Assert ($pairText -match 'Status:\*\* in_progress; launch' -and $pairText -match 'exited; acceptance pending' -and $pairText -match 'Exit code:\*\* 0') 'Complete launch/exit pair with the native exit'
    }
    Assert ((Get-FileHash (Join-Path $raceDir 'race-approval.md')).Hash -ceq $priorHash) 'Earlier record immutable under concurrent writers'
} finally {
    & $moduleScope { Remove-Item Function:script:Get-Command; Remove-Item Function:script:Get-SwUtc -ErrorAction SilentlyContinue }
    foreach ($name in 'SW_TEST_NATIVE', 'SW_TEST_ARGV', 'SW_TEST_EXIT', 'SW_TEST_MISSING', 'SW_TEST_THROW', 'SW_TEST_COUNT_DIR') { [Environment]::SetEnvironmentVariable($name, $null, 'Process') }
}
Write-Output "PASS: $script:checks targeted assertions; static and native-stub contracts only, no model calls or security proof."
