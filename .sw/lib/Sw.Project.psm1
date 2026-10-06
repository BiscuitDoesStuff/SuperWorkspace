# SuperWorkspace project module: everything that runs inside an installed project.
# Copied into each project as .sw/lib/Sw.Project.psm1 so collaborators without the
# kit can still validate, generate the Claude adapter, and use comms. PowerShell 7.2+.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Utf8 = [Text.UTF8Encoding]::new($false)

# --- shared helpers -------------------------------------------------------------

function Resolve-SwRoot([string]$Path) {
    if (-not $Path -and $env:SW_ROOT) { $Path = $env:SW_ROOT }
    if (-not $Path) {
        $top = & git rev-parse --show-toplevel 2>$null
        $Path = if ($LASTEXITCODE -eq 0 -and $top) { $top } else { (Get-Location).Path }
    }
    (Resolve-Path -LiteralPath $Path).Path
}

function Write-SwFile([string]$Path, [string]$Content) {
    $dir = Split-Path $Path -Parent
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [IO.File]::WriteAllText($Path, $Content.Replace("`r`n", "`n"), $script:Utf8)
}

function Get-SwTextBytes([string]$Content) { $script:Utf8.GetBytes($Content.Replace("`r`n", "`n")) }

function Get-SwByteHash([byte[]]$Bytes) { [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant() }

function Get-SwOperationId { "$(Get-SwUtc)-$([guid]::NewGuid().ToString('N').Substring(0, 8))" }

function Test-SwContained([string]$Base, [string]$Path) {
    # True when $Path resolves inside $Base (never equal to it); catches '..' escapes.
    $b = [IO.Path]::GetFullPath($Base).TrimEnd([char[]]@([char]92, [char]47)) + [IO.Path]::DirectorySeparatorChar
    $cmp = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    [IO.Path]::GetFullPath($Path).StartsWith($b, $cmp)
}

function Write-SwBytesNew([string]$Path, [byte[]]$Bytes) {
    # CreateNew: IOException if the path exists; a failed write removes the file this call created.
    $stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($Bytes, 0, $Bytes.Length) }
    catch { $stream.Dispose(); $stream = $null; Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue; throw }
    finally { if ($stream) { $stream.Dispose() } }
}

function Write-SwNewFile([string]$Path, [string]$Content) {
    # Exact path, never replaces: recovery copies must not clobber an earlier generation.
    [IO.Directory]::CreateDirectory((Split-Path $Path -Parent)) | Out-Null
    Write-SwBytesNew $Path (Get-SwTextBytes $Content)
}

function Copy-SwNew([string]$Source, [string]$Destination) {
    [IO.Directory]::CreateDirectory((Split-Path $Destination -Parent)) | Out-Null
    [IO.File]::Copy($Source, $Destination, $false)
}

function New-SwSnapshotDir([string]$Path) {
    # Reserve a recovery directory; fails if anything already exists there.
    [IO.Directory]::CreateDirectory((Split-Path $Path -Parent)) | Out-Null
    New-Item -ItemType Directory -Path $Path | Out-Null
    $Path
}

function New-SwExclusiveFile([string]$Dir, [string]$BaseName, [string]$Extension, [string]$Content, [int]$MaxAttempts = 100) {
    # The one allocator for immutable records: CreateNew wins the name or fails. Retry only on a real name
    # collision (-2, -3, ...); any other I/O failure surfaces at once.
    [IO.Directory]::CreateDirectory($Dir) | Out-Null
    $bytes = Get-SwTextBytes $Content
    for ($n = 1; $n -le $MaxAttempts; $n++) {
        $path = Join-Path $Dir $(if ($n -eq 1) { "$BaseName$Extension" } else { "$BaseName-$n$Extension" })
        try { Write-SwBytesNew $path $bytes; return $path }
        catch {
            $e = $_.Exception
            while ($e.InnerException -and $e -isnot [IO.IOException]) { $e = $e.InnerException }
            if ($e -is [IO.IOException] -and (Test-Path -LiteralPath $path)) { continue }
            throw
        }
    }
    throw "No free name for $BaseName$Extension in $Dir after $MaxAttempts attempts"
}

function Read-SwText([string]$Path) { [IO.File]::ReadAllText($Path).Replace("`r`n", "`n") }

function Read-SwJson([string]$Path) { Read-SwText $Path | ConvertFrom-Json -AsHashtable }

function ConvertTo-SwJson($Value) { ($Value | ConvertTo-Json -Depth 20).Replace("`r`n", "`n") + "`n" }

function Get-SwHash([string]$Content) {
    $bytes = $script:Utf8.GetBytes($Content.Replace("`r`n", "`n"))
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
}

function Get-SwConfig([string]$Root) {
    $path = Join-Path $Root '.sw/config.json'
    if (-not (Test-Path -LiteralPath $path)) { throw "Not a SuperWorkspace project (missing .sw/config.json): $Root" }
    Read-SwJson $path
}

function Get-SwUtc { [DateTime]::UtcNow.ToString('yyyy-MM-ddTHHmmssZ') }

# Diagnostics touch installed tools only through these two functions, so tests can replace them.
function Find-SwTool([string]$Name) {
    $cmd = Get-Command $Name -CommandType Application, ExternalScript -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    if ($Name -eq 'opencode' -and $IsWindows) {
        $cand = Join-Path $env:LOCALAPPDATA 'Programs/@opencodedesktop/resources/opencode-cli.exe'
        if (Test-Path -LiteralPath $cand) { return (Get-Item -LiteralPath $cand).FullName }
    }
    $null
}

function Invoke-SwProbe([string]$Exe, [string[]]$Arguments) {
    # Captures stdout and the immediate native exit; a thrown launch is reported, not raised.
    try {
        $PSNativeCommandUseErrorActionPreference = $false
        $global:LASTEXITCODE = 0
        $out = & $Exe @Arguments 2>$null
        $code = $LASTEXITCODE
        [pscustomobject]@{ Threw = $false; ExitCode = $code; Output = (@($out) -join ' ') }
    } catch { [pscustomobject]@{ Threw = $true; ExitCode = $null; Output = '' } }
}

function Get-SwToolProbe([string]$Name) {
    # State: missing | threw | failed (nonzero exit, whatever it printed) | unparsed | ok.
    $exe = Find-SwTool $Name
    if (-not $exe) { return [pscustomobject]@{ Name = $Name; State = 'missing'; Version = $null; ExitCode = $null } }
    $r = Invoke-SwProbe $exe @('--version')
    $m = [regex]::Match([string]$r.Output, '(\d+\.\d+\.\d+)')
    $state = if ($r.Threw) { 'threw' } elseif ($r.ExitCode -ne 0) { 'failed' } elseif ($m.Success) { 'ok' } else { 'unparsed' }
    [pscustomobject]@{ Name = $Name; State = $state; Version = $(if ($state -eq 'ok') { [version]$m.Groups[1].Value }); ExitCode = $r.ExitCode }
}

function Get-SwToolVersion([string]$Name) { (Get-SwToolProbe $Name).Version }

function Get-SwGhAuth {
    # Exit code of `gh auth status`, or $null when gh cannot be run.
    $exe = Find-SwTool 'gh'
    if (-not $exe) { return $null }
    $r = Invoke-SwProbe $exe @('auth', 'status')
    if ($r.Threw) { $null } else { $r.ExitCode }
}

function Format-SwProbe($Probe) {
    switch ($Probe.State) {
        'threw' { 'version probe threw' }
        'failed' { "version probe exited $($Probe.ExitCode)" }
        'unparsed' { 'version output not recognized' }
        default { $Probe.State }
    }
}

function Get-SwUser([string]$Root) {
    $name = & git -C $Root config user.name 2>$null
    if (-not $name) { throw 'Set git config user.name, or pass -User/-From.' }
    ($name -replace '[^A-Za-z0-9_-]', '').ToLowerInvariant()
}

function ConvertTo-SwSlug([string]$Text) {
    $slug = ($Text.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    if ($slug.Length -gt 40) { $slug = $slug.Substring(0, 40).TrimEnd('-') }
    if (-not $slug) { 'note' } else { $slug }
}

# --- restricted frontmatter parser (fails loud on anything outside the subset) --

function ConvertFrom-SwScalar([string]$Value) {
    if ($Value -match '^"([^"\\]*)"$') { return $Matches[1] }
    if ($Value -match "^'([^']*)'$") { return $Matches[1] }
    if ($Value -match '^[a-zA-Z0-9][^\[\]{}#&*!|>''"`]*$' -and $Value -notmatch ':\s|\s$') { return $Value }
    throw "Unsupported scalar: $Value (restricted frontmatter subset)"
}

function Read-SwFrontmatter([string]$Path, [string[]]$Allowed, [string]$Text) {
    # Top-level scalar keys only; `permissions` as a 2-space rule list with
    # `action:` first and `resource:`/`effect:` at 4 spaces; single-line scalars.
    # -Text parses in-memory content ($Path only labels it); nothing is read then.
    $lines = @($(if ($PSBoundParameters.ContainsKey('Text')) { $Text } else { Read-SwText $Path }) -split "`n")
    if ($lines.Count -lt 3 -or $lines[0] -cne '---') { throw 'Missing opening frontmatter delimiter' }
    $data = [ordered]@{}; $rules = [Collections.Generic.List[object]]::new(); $rule = $null; $inRules = $false; $close = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -ceq '---') { $close = $i; break }
        if ($line -match '^([a-z_]+):(?: (.+))?$') {
            $key = $Matches[1]; $value = $Matches[2]
            if ($Allowed -cnotcontains $key -or $data.Contains($key)) { throw "Unknown or duplicate key: $key" }
            $inRules = $key -ceq 'permissions'
            if ($inRules) { if ($value) { throw 'permissions must be an indented rule list' }; $data[$key] = $rules }
            else { $data[$key] = ConvertFrom-SwScalar $value }
        } elseif ($inRules -and $line -match '^  - action: (.+)$') {
            $rule = [ordered]@{ action = (ConvertFrom-SwScalar $Matches[1]) }; $rules.Add($rule)
        } elseif ($inRules -and $null -ne $rule -and $line -match '^    (resource|effect): (.+)$') {
            if ($rule.Contains($Matches[1])) { throw "Duplicate rule key: $($Matches[1])" }
            $rule[$Matches[1]] = ConvertFrom-SwScalar $Matches[2]
        } else { throw "Unsupported frontmatter at line $($i + 1): $line" }
    }
    if ($close -lt 0) { throw 'Missing closing frontmatter delimiter' }
    $body = ($lines | Select-Object -Skip ($close + 1)) -join "`n"
    if ([string]::IsNullOrWhiteSpace($body)) { throw 'Empty instruction body' }
    $data['__body'] = $body
    $data
}

# --- V2 permission model (static; models matching, not runtime enforcement) ---------

function Test-SwPattern([string]$Pattern, [string]$Value) {
    # V2 whole-value wildcards: * spans '/', ? is one character. Case-insensitive on Windows.
    $regex = '\A' + [regex]::Escape($Pattern.Replace('\', '/')).Replace('\*', '.*').Replace('\?', '.') + '\z'
    $options = [Text.RegularExpressions.RegexOptions]::Singleline
    if ($IsWindows) { $options = $options -bor [Text.RegularExpressions.RegexOptions]::IgnoreCase }
    [regex]::IsMatch($Value.Replace('\', '/'), $regex, $options)
}

function Assert-SwSafeName([string]$Value, [string]$Label) {
    # Comms names become path segments; block traversal and separators.
    if ($Value -notmatch '^[A-Za-z0-9_.-]+$' -or $Value -in '.', '..') { throw "Invalid ${Label}: '$Value' (allowed: letters, digits, underscore, dot, hyphen; not '.' or '..')" }
}

function Assert-SwSafeFileName([string]$Value, [string]$Label) {
    if ($Value -ne [IO.Path]::GetFileName($Value)) { throw "Invalid ${Label}: '$Value' must be a bare file name" }
}

function Get-SwDecision($Rules, [string]$Action, [string]$Resource) {
    $effect = 'ask'
    foreach ($rule in $Rules) {
        $match = Test-SwPattern $rule.resource $Resource
        # V2 also matches the bare shell command for a trailing " *".
        if ($Action -eq 'shell' -and $rule.resource.EndsWith(' *')) {
            $match = $match -or (Test-SwPattern $rule.resource.Substring(0, $rule.resource.Length - 2) $Resource)
        }
        if ((Test-SwPattern $rule.action $Action) -and $match) { $effect = $rule.effect }
    }
    $effect
}

# --- GitHub tiers: single source for both OpenCode and Claude rules ------------------

$script:GhRead = @('gh issue list *', 'gh issue view *', 'gh issue status *', 'gh pr list *', 'gh pr view *',
    'gh pr status *', 'gh pr checks *', 'gh pr diff *', 'gh run list *', 'gh run view *', 'gh run watch *',
    'gh repo view *', 'gh label list *', 'gh release list *', 'gh release view *', 'gh auth status *',
    'gh search *', 'gh browse --no-browser *')
$script:GhTier1 = @('gh issue create *', 'gh issue edit *', 'gh issue comment *', 'gh pr comment *',
    'gh pr edit *', 'gh pr create --draft *')

function Get-SwGhRules([int]$Tier) {
    # Appended after the base `gh *` deny; last match wins.
    $allow = @($script:GhRead) + $(if ($Tier -ge 1) { $script:GhTier1 } else { @() })
    foreach ($r in $allow) { [ordered]@{ action = 'shell'; resource = $r; effect = 'allow' } }
}

# --- session rules: one list, rendered into opencode.jsonc and every agent -----------

# OpenCode v2 applies the project-level list before agent rules; the per-agent copies are kept as defence in depth (docs/decisions.md 2026-09-27).
# Shell wrappers that can hide a git command are asked first, so the git/gh denies below win when both match.
# Each git verb is denied (or asked) in its plain, global-flag (`git -C . push`), and compound/runner
# (`x && git push`, `rtk proxy git push`) forms; `*`-leading rules cover the `rtk ` rewrite on their own.
# pwsh asks whenever it mentions git; encoded-command flags are listed in both cases so CI (case-sensitive) agrees.
$script:SessionWrappers = @('bash *-c *git*', 'sh *-c *git*', 'pwsh *git*', 'powershell *git*', 'cmd */c *git*', '*rtk run *git*') +
    @(foreach ($shell in 'pwsh', 'powershell') { foreach ($flag in '-e *', '-ec *', '-enc*', '-E *', '-EC *', '-Enc*') { "$shell *$flag" } })
$script:SessionGitVerbs = @(@('commit', 'ask'), @('push', 'deny'), @('reset --hard', 'deny'), @('clean', 'deny'), @('stash', 'deny'))
$script:SessionBase = @(
    @('shell', '*', 'allow'), @('external_directory', '*', 'ask'), @('skill', '*', 'allow'), @('subagent', '*', 'deny')) +
    @($script:SessionWrappers | ForEach-Object { , @('shell', $_, 'ask') }) +
    @($script:SessionGitVerbs | ForEach-Object { $v = $_; foreach ($p in "git $($v[0]) *", "git -* $($v[0]) *", "* git $($v[0]) *", "* git -* $($v[0]) *") { , @('shell', $p, $v[1]) } }) +
    @(@('shell', 'gh *', 'deny'), @('shell', '* gh *', 'deny'))

function Test-SwRtkTwinned($Rule) {
    # `*`-leading rules (wildcard, compound forms) and `rtk `-leading rules already cover the rewrite.
    $Rule['action'] -ceq 'shell' -and -not ($Rule['resource'].StartsWith('*') -or $Rule['resource'].StartsWith('rtk '))
}

function Get-SwSessionRules($EditDeny, [int]$Tier) {
    # Base, profile edit denies, GitHub tier allows, then the .env read asks. Agent rules follow; last match wins.
    foreach ($r in $script:SessionBase) { [ordered]@{ action = $r[0]; resource = $r[1]; effect = $r[2] } }
    foreach ($g in @($EditDeny)) { if ($g) { [ordered]@{ action = 'edit'; resource = $g; effect = 'deny' } } }
    Get-SwGhRules $Tier
    # A read/write allow must not carry a compound tail: `gh issue view 1 && gh pr merge 1`.
    foreach ($op in '&', ';', '|') { [ordered]@{ action = 'shell'; resource = "gh *$op*"; effect = 'deny' } }
    [ordered]@{ action = 'read'; resource = '*.env'; effect = 'ask' }
    [ordered]@{ action = 'read'; resource = '*.env.*'; effect = 'ask' }
    [ordered]@{ action = 'read'; resource = '*.env.example'; effect = 'allow' }
}

function Add-SwRtkTwins($Rules) {
    # OpenCode 2.0.18 runs plugin shell hooks before its permission check, and the RTK plugin
    # rewrites `git push ...` to `rtk git push ...`. Each shell rule (except `*`-leading) gets an
    # `rtk ` twin with the same effect, directly after it, so last-match order is unchanged.
    foreach ($r in $Rules) {
        $r
        if (Test-SwRtkTwinned $r) { [ordered]@{ action = 'shell'; resource = "rtk $($r['resource'])"; effect = $r['effect'] } }
    }
}

function Get-SwClaudeGhDeny([int]$Tier) {
    # Claude cannot deny-all-then-allow (deny always wins), so write verbs are enumerated.
    $always = 'gh pr merge', 'gh pr ready', 'gh pr close', 'gh pr review', 'gh release create', 'gh release edit',
        'gh release delete', 'gh release upload', 'gh repo create', 'gh repo delete', 'gh repo edit', 'gh repo archive',
        'gh repo rename', 'gh repo sync', 'gh repo fork', 'gh api', 'gh secret', 'gh variable', 'gh workflow run',
        'gh workflow enable', 'gh workflow disable', 'gh run rerun', 'gh run cancel', 'gh run delete', 'gh label create',
        'gh label edit', 'gh label delete', 'gh label clone', 'gh gist', 'gh issue close', 'gh issue delete',
        'gh issue lock', 'gh issue transfer', 'gh issue pin', 'gh ruleset', 'gh cache delete',
        'gh pr update-branch', 'gh pr reopen', 'gh issue reopen', 'gh issue develop', 'gh pr lock', 'gh issue unpin',
        'gh repo deploy-key', 'gh repo unarchive', 'gh ssh-key', 'gh gpg-key', 'gh auth token', 'gh auth logout',
        'gh auth refresh', 'gh extension', 'gh project', 'gh codespace', 'gh org', 'gh alias'
    $tier0 = 'gh issue create', 'gh issue edit', 'gh issue comment', 'gh pr create', 'gh pr edit', 'gh pr comment'
    $verbs = @($always) + $(if ($Tier -lt 1) { $tier0 } else { @() })
    $verbs | ForEach-Object { "Bash($_`:*)" }
}

# --- validation -------------------------------------------------------------------

$script:Skills = @('agent-documentation', 'focused-review', 'free-models', 'minimal-change', 'project-planning',
    'research', 'structured-debugging', 'task-handoff')
$script:Routes = [ordered]@{ work = 'project-leader'; resume = 'project-leader'; 'workspace-check' = 'project-leader';
    handoff = 'project-leader'; inbox = 'project-leader'; validate = 'project-developer'; review = 'project-review';
    status = 'project-review'; research = 'project-research' }
$script:MojibakePattern = ([char]0x00E2 + [char]0x20AC) + '|' + ([char]0x00C3 + [char]0x00E9) + '|' + ([char]0x00C2 + [char]0x00A0)

# --- profile selection v1: generator-owned installation, not runtime loading or hiding -------

# Fixed v1 floor; a catalogue that drops it is rejected, never silently completed.
$script:SelectionFloor = [ordered]@{ roles = @('project-leader'); skills = @('project-planning', 'task-handoff'); context = @('core'); checks = @('diff-hygiene', 'workspace-static') }
$script:SelectionSets = @('roles', 'skills', 'context', 'checks')

function Assert-SwExactKeys($Map, [string[]]$Keys, [string]$Label) {
    if ($Map -isnot [Collections.IDictionary]) { throw "Selection ${Label} must be an object" }
    $extra = @($Map.Keys | Where-Object { $_ -cnotin $Keys }); $missing = @($Keys | Where-Object { $_ -cnotin @($Map.Keys) })
    if ($extra.Count -or $missing.Count) { throw "Selection ${Label} needs exactly keys $($Keys -join ', ')$(if ($extra.Count) { "; unsupported: $($extra -join ', ')" })$(if ($missing.Count) { "; missing: $($missing -join ', ')" })" }
}

function Assert-SwIdList($Value, [string]$Label, [string[]]$Allowed) {
    # A list of canonical IDs (also safe path segments): no scalar/null, duplicate, path-like or unknown entry.
    if ($Value -isnot [array]) { throw "Selection ${Label} must be a list" }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($v in $Value) {
        if ($v -isnot [string] -or $v -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { throw "Selection ${Label}: '$v' is not a canonical identifier" }
        if (-not $seen.Add($v)) { throw "Selection ${Label}: duplicate '$v'" }
        if ($PSBoundParameters.ContainsKey('Allowed') -and $v -cnotin $Allowed) { throw "Selection ${Label}: unknown '$v'" }
    }
}

function Join-SwIdSet { $set = [Collections.Generic.SortedSet[string]]::new([StringComparer]::Ordinal); foreach ($list in $args) { foreach ($v in $list) { $null = $set.Add($v) } }; , [string[]]@($set) }

function Resolve-SwSelection {
    <#
    .SYNOPSIS Pure v1 resolver shared by the kit renderer and installed validation: core + profile + capabilities
    + role dependency skills. Throws on any malformed input; the result lists generator-owned components only.
    #>
    param($Selection, [string]$Profile, $ProfileData, $Catalogue, [string[]]$RoleIds)
    $isOne = { param($v) ($v -is [int] -or $v -is [long]) -and $v -eq 1 }
    Assert-SwExactKeys $Catalogue @('version', 'core', 'roleSkills', 'capabilities', 'context', 'checks') 'catalogue'
    if (-not (& $isOne $Catalogue['version'])) { throw "Selection catalogue version must be 1" }
    Assert-SwIdList $Catalogue['context'] 'catalogue context'
    Assert-SwIdList $Catalogue['checks'] 'catalogue checks'
    $allowed = @{ roles = $RoleIds; context = $Catalogue['context']; checks = $Catalogue['checks'] }
    $sets = {
        param($Map, [string]$Label)
        Assert-SwExactKeys $Map $script:SelectionSets $Label
        foreach ($k in $script:SelectionSets) {
            if ($allowed.Contains($k)) { Assert-SwIdList $Map[$k] "$Label $k" $allowed[$k] } else { Assert-SwIdList $Map[$k] "$Label $k" }
        }
    }
    & $sets $Catalogue['core'] 'catalogue core'
    foreach ($k in $script:SelectionSets) {
        $lost = @($script:SelectionFloor[$k] | Where-Object { $_ -cnotin $Catalogue['core'][$k] })
        if ($lost.Count) { throw "Selection catalogue core drops the fixed v1 floor ($k): $($lost -join ', ')" }
    }
    $roleSkills = $Catalogue['roleSkills']
    if ($roleSkills -isnot [Collections.IDictionary]) { throw 'Selection catalogue roleSkills must be an object' }
    Assert-SwIdList @($roleSkills.Keys) 'catalogue roleSkills roles' $RoleIds
    $absent = @($RoleIds | Where-Object { $_ -cnotin @($roleSkills.Keys) })
    if ($absent.Count) { throw "Selection catalogue roleSkills lacks role(s): $($absent -join ', ')" }
    foreach ($r in $roleSkills.Keys) { Assert-SwIdList $roleSkills[$r] "catalogue roleSkills $r" }
    $caps = $Catalogue['capabilities']
    if ($caps -isnot [Collections.IDictionary]) { throw 'Selection catalogue capabilities must be an object' }
    Assert-SwIdList @($caps.Keys) 'catalogue capability names'
    foreach ($c in $caps.Keys) { & $sets $caps[$c] "capability $c" }

    if ($Profile -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { throw "Selection profile '$Profile' is not a canonical identifier" }
    if ($ProfileData -isnot [Collections.IDictionary]) { throw 'Selection profile data must be an object' }
    Assert-SwIdList $ProfileData['skills'] 'profile skills'
    $composition = $ProfileData['composition']
    Assert-SwExactKeys $composition @('roles', 'capabilities', 'context', 'checks') "profile $Profile composition"
    Assert-SwIdList $composition['roles'] "profile $Profile roles" $RoleIds
    Assert-SwIdList $composition['capabilities'] "profile $Profile capabilities" @($caps.Keys)
    Assert-SwIdList $composition['context'] "profile $Profile context" $allowed.context
    Assert-SwIdList $composition['checks'] "profile $Profile checks" $allowed.checks

    Assert-SwExactKeys $Selection @('version', 'capabilities') 'config'
    if (-not (& $isOne $Selection['version'])) { throw "Unsupported selection version '$($Selection['version'])' (supported: 1)" }
    Assert-SwIdList $Selection['capabilities'] 'config capabilities' @($caps.Keys)

    # Capabilities are additive to the preset's defaults; no negative overrides or fallback.
    $chosen = Join-SwIdSet $composition['capabilities'] $Selection['capabilities']
    $pick = { param([string]$Set) foreach ($c in $chosen) { $caps[$c][$Set] } }
    $roles = Join-SwIdSet $Catalogue['core']['roles'] $composition['roles'] @(& $pick 'roles')
    $skills = Join-SwIdSet $Catalogue['core']['skills'] @(foreach ($r in $roles) { $roleSkills[$r] }) @(& $pick 'skills') $ProfileData['skills']
    [ordered]@{
        version      = 1
        profile      = $Profile
        capabilities = $chosen
        roles        = $roles
        skills       = $skills
        context      = Join-SwIdSet $Catalogue['core']['context'] $composition['context'] @(& $pick 'context')
        checks       = Join-SwIdSet $Catalogue['core']['checks'] $composition['checks'] @(& $pick 'checks')
    }
}

function Get-SwSelectionCommands([string[]]$Roles) {
    # Kit commands whose target role is selected; core Leader commands always qualify.
    , [string[]]@($script:Routes.Keys | Where-Object { $script:Routes[$_] -cin $Roles })
}

function Get-SwSelectionKnown($Catalogue, $ProfileData) {
    # Kit-owned component IDs an installation can recognize; anything else is a project-owned extra.
    $skills = @($script:Skills) + @($Catalogue['core']['skills']) + @($ProfileData['skills']) +
        @(foreach ($v in $Catalogue['roleSkills'].Values) { $v }) + @(foreach ($v in $Catalogue['capabilities'].Values) { $v['skills'] })
    [ordered]@{ roles = Join-SwIdSet @($Catalogue['roleSkills'].Keys); skills = Join-SwIdSet $skills; commands = Join-SwIdSet @($script:Routes.Keys) }
}

function Test-SwLinkedPath([string]$Root, [string]$Relative) {
    # True when the path or any parent up to the root is a link or junction (never followed).
    (Invoke-SwContextRead $Root $Relative {}).Status -eq 'unsafe'
}

function Test-SwLocalOnly([string]$Root, [string]$Relative) {
    # A per-user override is allowed only when untracked AND git-ignored; git failure fails closed.
    # check-ignore works on a non-existent path too, so a missing .gitignore entry is caught either way.
    $tracked = & git -C $Root ls-files -- $Relative 2>$null
    if ($LASTEXITCODE -ne 0 -or $tracked) { return $false }
    & git -C $Root check-ignore -q -- $Relative 2>$null
    $LASTEXITCODE -eq 0
}

function Get-SwResearchWarnings([string]$Root) {
    # Lenient lint for docs/research/*.md: warnings only, never errors.
    $dir = Join-Path $Root 'docs/research'
    if (-not (Test-Path -LiteralPath $dir)) { return }
    foreach ($file in Get-ChildItem -LiteralPath $dir -Filter *.md -File -Force | Sort-Object Name) {
        $rel = "docs/research/$($file.Name)"
        $lines = @((Read-SwText $file.FullName) -split "`n")
        $missing = @(1..6 | Where-Object { $n = $_; -not @($lines | Where-Object { $_ -match "^## $n\. " }).Count })
        if ($missing.Count) { "${rel}: missing section(s) $($missing -join ', ') (expected '## 1.' to '## 6.')" }
        $first = [array]::FindIndex([string[]]$lines, [Predicate[string]] { param($l) $l -match '^## ' })
        $header = if ($first -ge 0) { $lines[0..([math]::Max(0, $first - 1))] } else { $lines }
        if (-not (($header -join "`n") -match '\d{4}-\d{2}-\d{2}')) { "${rel}: header has no YYYY-MM-DD date" }
        # Findings: F<n>. blocks under '## 2.'; a subsection heading containing "local" covers its findings.
        $inFindings = $false; $localHeading = $false; $id = $null; $block = ''
        $check = {
            if ($id -and -not $localHeading -and $block -notmatch 'https?://|Same\s[\s\S]*?\sas\s+(\d{2}-)?F\d+|\bLocal\b|\(F\d+|\b\d{2}-F\d+') {
                "${rel}: $id has no citation (URL, 'Same ... as F<n>', 'Local', or a finding cross-reference)"
            }
        }
        foreach ($line in $lines) {
            if ($line -match '^#{1,3} ') {
                & $check; $id = $null; $block = ''
                if ($line -match '^## ') { $inFindings = $line -match '^## 2\. '; $localHeading = $false }
                elseif ($line -match '^### ') { $localHeading = $line -match '(?i)local' }
                continue
            }
            if (-not $inFindings) { continue }
            if ($line -match '^(F\d+)\. ') { & $check; $id = $Matches[1]; $block = $line }
            elseif ($id) { $block += "`n$line" }
        }
        & $check
    }
}

function Get-SwOverlayRules($Agents, [string]$Role, [string]$Label) {
    # permissions a shared/local config overlay adds to one role; OpenCode applies them after the agent file's own.
    if ($Agents -isnot [Collections.IDictionary] -or -not $Agents.Contains($Role) -or $Agents[$Role] -isnot [Collections.IDictionary]) { return }
    $entry = $Agents[$Role]
    if ($entry.Contains('permission')) { throw "$Label overlay for $Role uses the unsupported key 'permission'; the kit models 'permissions' only." }
    if ($entry.Contains('permissions')) { $entry['permissions'] }
}

function Get-SwRolePolicyChecks {
    <#
    .SYNOPSIS One narrow check of a role's effective permission list, shared by validate and the session launcher.
    Emits Category/Ok/Message records: validate counts them, the launcher rejects on the first failure.
    #>
    param([string]$Name, [string]$Label, $Policy, [string]$Access, [string[]]$RoleNames, $ProfileData, [int]$Tier)
    $policy = @($Policy)
    $check = { param($Ok, [string]$Message, [string]$Category = 'Contracts') [pscustomobject]@{ Category = $Category; Ok = [bool]$Ok; Message = $Message } }
    # Structure first: later checks index action/resource/effect and must not run on a malformed rule.
    foreach ($rule in $policy) {
        $shape = $rule -is [Collections.IDictionary] -and @($rule.Keys).Count -eq 3 -and -not @($rule.Keys | Where-Object { $_ -cnotin 'action', 'resource', 'effect' }).Count
        $strings = $shape -and -not @('action', 'resource', 'effect' | Where-Object { $rule[$_] -isnot [string] -or -not $rule[$_] }).Count
        if (-not $strings -or $rule['effect'] -cnotin 'allow', 'deny', 'ask') { return (& $check $false "$Label permissions rule needs string action/resource/effect with effect allow, deny or ask") }
    }
    $session = @(Add-SwRtkTwins (Get-SwSessionRules $ProfileData['editDeny'] $Tier))
    $leads = $policy.Count -ge $session.Count
    for ($i = 0; $leads -and $i -lt $session.Count; $i++) {
        foreach ($key in 'action', 'resource', 'effect') { if ($policy[$i][$key] -cne $session[$i][$key]) { $leads = $false } }
    }
    & $check $leads "Session rule drift: $Label does not start with the session rules for this config; run sw update"
    # Every shell rule (except `*`-leading) is followed by its `rtk ` twin: the RTK plugin rewrites before the check.
    $untwinned = for ($i = 0; $i -lt $policy.Count; $i++) {
        $r = $policy[$i]
        if (-not (Test-SwRtkTwinned $r)) { continue }
        $t = if ($i + 1 -lt $policy.Count) { $policy[$i + 1] } else { @{} }
        if ($t['action'] -cne 'shell' -or $t['resource'] -cne "rtk $($r['resource'])" -or $t['effect'] -cne $r['effect']) { $r['resource'] }
    }
    & $check (-not @($untwinned).Count) "RTK twin missing: $Label shell [$(@($untwinned) -join '], [')] needs its [rtk ...] twin, same effect, directly after it; run sw update"

    # Permission matrix: what OpenCode loads for this role (build: agents.build), from this list alone.
    function Expect($Action, $Resource, $Expected) {
        # A shell case also holds for its RTK rewrite (see Add-SwRtkTwins).
        foreach ($res in @($Resource) + $(if ($Action -ceq 'shell') { "rtk $Resource" } else { @() })) {
            $actual = Get-SwDecision $policy $Action $res
            & $check ($actual -ceq $Expected) "STATIC $Name $Action [$res]: expected $Expected, got $actual" 'Permissions'
        }
    }
    $buildAllowed = @($RoleNames | Where-Object { $_ -ne 'project-leader' }) + 'general', 'explore'
    $isReadonly = $Access -eq 'readonly'
    if ($Name -eq 'project-leader') { foreach ($t in $RoleNames + 'future-agent') { Expect subagent $t allow } }
    elseif ($Name -eq 'build') {
        foreach ($t in $buildAllowed) { Expect subagent $t allow }
        foreach ($t in 'future-agent', 'project-leader') { Expect subagent $t deny }
    } else { foreach ($t in $RoleNames + 'future-agent') { Expect subagent $t deny } }
    foreach ($c in 'git push', 'git push origin main', 'git reset --hard', 'git reset --hard HEAD', 'git clean -fd', 'git stash', 'gh pr merge 1', 'gh release create v1', 'gh repo delete x', 'gh api -X POST repos') { Expect shell $c deny }
    foreach ($c in 'git status', 'git status --short --branch') { Expect shell $c allow }
    foreach ($p in '.env', '.env.local', 'nested/.env', 'nested\.env.local') { Expect read $p ask }
    foreach ($p in '.env.example', 'nested/.env.example') { Expect read $p allow }
    Expect shell 'git commit -m probe' $(if ($isReadonly) { 'deny' } else { 'ask' })
    # Prefix bypasses: global flags, compound commands, runners, and shell wrappers.
    foreach ($c in 'git -C . push', 'git -C . push origin main', 'git --no-pager push', 'git -c k=v reset --hard', 'git -C . reset --hard HEAD', 'git -C . clean -fd', 'git -C . stash',
        'git status && git push', 'git status; git push origin main', 'git log | git stash', 'rtk proxy git push', 'rtk err git -C . push', 'rtk summary git reset --hard HEAD',
        'git status && gh pr merge 1', 'rtk proxy gh pr merge 1', 'gh issue view 1 && gh pr merge 1', 'gh pr view 1; gh pr merge 1') { Expect shell $c deny }
    $askUnlessReadonly = $(if ($isReadonly) { 'deny' } else { 'ask' })
    foreach ($c in 'git -C . commit -m probe', 'git status && git commit -m probe', "bash -c 'git push'", 'sh -c "git reset --hard"', 'pwsh -NoProfile -Command "git push"',
        'rtk run "git push"', 'pwsh -EncodedCommand AAAA', 'pwsh -e AAAA') { Expect shell $c $askUnlessReadonly }
    foreach ($g in @($ProfileData['editDeny'])) { Expect edit ("Content/Probe" + $g.TrimStart('*')) deny }
    if ($isReadonly) {
        foreach ($c in 'git log --oneline -10', 'git rev-parse HEAD', 'git diff --check', 'git show --no-ext-diff --no-textconv HEAD -- src/probe.c',
            'git status -sb', 'git status --porcelain', 'git diff HEAD~1 -- src/probe.c', 'git diff --stat HEAD', 'git diff --cached --name-only',
            'git log -5 --stat', 'git log --format=%h HEAD', 'git log --oneline', 'git log --oneline -20', 'git show HEAD', 'git show --stat HEAD~1',
            'git ls-files --others --exclude-standard') { Expect shell $c allow }
        foreach ($c in 'git diff --output=probe.txt', 'git diff --ext-diff', 'git show --textconv HEAD', 'git tag probe', 'git branch probe', 'git switch main', 'Write-Output probe',
            'git status --output=probe.txt', 'git log --output=probe.txt', 'git log --oneline -20 --output=probe.txt', 'git log --oneline --output=probe.txt', 'git show --output=probe.txt HEAD',
            'git diff HEAD --ext-diff', 'git log -p --ext-diff', 'git show --ext-diff HEAD', 'git diff --textconv HEAD', 'git log -p --textconv', 'git status --textconv') { Expect shell $c deny }
        foreach ($c in 'git status && git log --oneline -5', 'git log > out.txt', 'git log $(whoami)') { Expect shell $c deny }
        foreach ($p in 'src/probe.c', 'AGENTS.md') { Expect edit $p deny }
        Expect unknown_tool '*' deny
    } else {
        Expect shell 'Write-Output probe' allow
        foreach ($c in 'git status && git log --oneline -5', 'pwsh -NoProfile -File .sw/sw.ps1 validate -CheckLinks', 'git diff --check', 'git log --grep=push', 'rg -n "git push" docs', 'pwsh -ExecutionPolicy Bypass -File x.ps1') { Expect shell $c allow }
        Expect shell 'gh issue view 1' allow
        Expect shell 'gh issue create --title probe' $(if ($Tier -ge 1) { 'allow' } else { 'deny' })
        Expect shell 'gh pr create --draft --title probe' $(if ($Tier -ge 1) { 'allow' } else { 'deny' })
        Expect shell 'gh pr create --title probe' deny
    }
    if ($Access -eq 'markdown') { Expect edit 'docs/probe.md' allow; Expect edit 'src/probe.c' deny }
    if ($Name -eq 'project-developer') { foreach ($c in 'git switch main', 'git checkout main', 'git merge main', 'git rebase main', 'git cherry-pick HEAD', 'git branch probe', 'git worktree add probe') { Expect shell $c ask } }
}

function Get-SwStartupBudget($Config, [string]$AgentsMdText, $Agents, $Skills, [string[]]$RoleNames) {
    # Static kit estimate shared by validate and context: AGENTS.md + role body + skill names/descriptions,
    # per role; project-leader also sees the subagent catalogue, so it adds the other agents' descriptions.
    $cap = if ($Config.Contains('startupBudgetBytes')) { [int]$Config['startupBudgetBytes'] } else { 12100 }
    $agentsMd = [Text.Encoding]::UTF8.GetByteCount($AgentsMdText)
    $skillBytes = 0
    foreach ($s in $Skills.GetEnumerator()) { $skillBytes += [Text.Encoding]::UTF8.GetByteCount($s.Key + $s.Value['description']) }
    $catalogueBytes = 0
    foreach ($a in $Agents.GetEnumerator()) { if ($a.Key -ne 'project-leader') { $catalogueBytes += [Text.Encoding]::UTF8.GetByteCount($a.Value['description']) } }
    foreach ($name in $RoleNames) {
        if (-not $Agents.ContainsKey($name)) { continue }
        $body = [Text.Encoding]::UTF8.GetByteCount($Agents[$name]['__body'])
        $catalogue = if ($name -eq 'project-leader') { $catalogueBytes } else { 0 }
        $total = $agentsMd + $body + $skillBytes + $catalogue
        [pscustomobject]@{ Role = $name; AgentsMd = $agentsMd; Body = $body; Skills = $skillBytes; Catalogue = $catalogue; Total = $total; Tokens = [math]::Ceiling($total / 4); Cap = $cap }
    }
}

function Test-SwProject {
    <#
    .SYNOPSIS Static workspace contract check (definitions, permissions matrix, portability, budget, hygiene, Claude drift).
    #>
    [CmdletBinding()]
    param([string]$Path, [switch]$CheckLinks, [switch]$Quiet)
    $problems = [Collections.Generic.List[string]]::new()
    $counts = [ordered]@{ Contracts = 0; Permissions = 0; HygieneFiles = 0; LocalLinks = 0 }
    $warnings = @()
    function Require($Condition, [string]$Message, [string]$Category = 'Contracts') {
        $counts[$Category]++
        if (-not $Condition) { $problems.Add($Message) }
    }
    function Rules($Items, [string]$Label) {
        Require ($Items -is [Collections.IEnumerable] -and $Items -isnot [string]) "$Label must be a list"
        foreach ($item in $Items) {
            $keys = @($item.Keys)
            Require (($keys.Count -eq 3) -and -not @($keys | Where-Object { $_ -cnotin 'action', 'resource', 'effect' }).Count) "$Label rule needs only action/resource/effect"
            foreach ($key in 'action', 'resource', 'effect') { Require ($item[$key] -is [string] -and $item[$key]) "$Label rule requires string $key" }
            Require ($item['effect'] -cin 'allow', 'deny', 'ask') "$Label invalid effect: $($item['effect'])"
        }
    }
    function Portable($Node, [string]$Label) {
        if ($null -eq $Node) { return }
        if ($Node -is [string]) {
            Require ($Node -notmatch '(?i)((?<![a-z])[a-z]:[\\/]|\\\\|/(?:Users|home|opt|usr|Applications)/)') "$Label contains an absolute machine path"
        } elseif ($Node -is [Collections.IDictionary]) {
            foreach ($key in @($Node.Keys)) {
                if ($key -eq '__body') { continue }
                Require ($key -notmatch '^(model|small_model|provider|providers|shell|shell_path|shellPath)$') "$Label forbidden shared pin: $key"
                Portable $Node[$key] "$Label.$key"
            }
        } elseif ($Node -is [Collections.IEnumerable]) { foreach ($entry in $Node) { Portable $entry $Label } }
    }
    function NoEffort([string]$Text, [string]$Label) {
        # Tiers are model-only: no effort/variant field and no model#variant suffix.
        Require ($Text -notmatch '(?im)(^\s*|")(effort|reasoningEffort|reasoning_effort|variant)"?\s*:') "$Label must be model-only: effort/reasoningEffort/variant field"
        Require ($Text -notmatch '(?i)"?model"?\s*:\s*"?[^\s",]*#') "$Label must be model-only: #variant model suffix"
    }
    function Expect($Policy, $Agent, $Action, $Resource, $Expected) {
        # A shell case also holds for its RTK rewrite (see Add-SwRtkTwins).
        foreach ($res in @($Resource) + $(if ($Action -ceq 'shell') { "rtk $Resource" } else { @() })) {
            $actual = Get-SwDecision $Policy $Action $res
            Require ($actual -ceq $Expected) "STATIC $Agent $Action [$res]: expected $Expected, got $actual" Permissions
        }
    }

    try {
        $Root = Resolve-SwRoot $Path
        $config = Get-SwConfig $Root
        $tier = [int]$config['githubTier']
        $roles = Read-SwJson (Join-Path $Root '.sw/roles.json')
        $profileData = Read-SwJson (Join-Path $Root '.sw/profile.json')
        $roleNames = @($roles.Keys | Where-Object { $_ -ne 'explore' })
        # Selection v1 (config opt-in) recomputes the installed set from the catalogue; legacy keeps the all-base contract.
        $selection = $null; $known = $null
        if ($config.Contains('selection')) {
            $catalogueFile = Join-Path $Root '.sw/selection.json'
            if (-not (Test-Path -LiteralPath $catalogueFile -PathType Leaf)) { throw 'Selection v1 needs .sw/selection.json; run sw update' }
            $catalogue = Read-SwJson $catalogueFile
            $selection = Resolve-SwSelection $config['selection'] ([string]$config['profile']) $profileData $catalogue @($catalogue['roleSkills'].Keys)
            $known = Get-SwSelectionKnown $catalogue $profileData
            Require ((ConvertTo-SwJson $profileData['effectiveSelection']) -ceq (ConvertTo-SwJson $selection)) '.sw/profile.json effectiveSelection does not match config, profile and .sw/selection.json; run sw update'
            Require (-not @(Compare-Object @($roles.Keys) $selection.roles -CaseSensitive).Count) ".sw/roles.json must list exactly the selected roles: $($selection.roles -join ', ')"
        }

        $configPath = Join-Path $Root 'opencode.jsonc'
        $configText = Read-SwText $configPath
        $outside = [regex]::Replace($configText, '"(?:[^"\\]|\\.)*"', '""')
        if ($outside -match '//|/\*|,\s*[}\]]') { throw 'opencode.jsonc must stay strict JSON (no comments or trailing commas)' }
        $oc = $configText | ConvertFrom-Json -AsHashtable
        Portable $oc 'opencode.jsonc'
        Require (-not $oc.Contains('commands')) 'Inline commands are unsupported; use .opencode/commands/*.md'
        Require (-not (Test-Path -LiteralPath (Join-Path $Root 'opencode.json'))) 'Unsupported alternate project config: opencode.json'
        foreach ($alt in '.opencode/opencode.json', '.opencode/opencode.jsonc') {
            Require (Test-SwLocalOnly $Root $alt) "Per-user config must be untracked and git-ignored: $alt"
        }
        foreach ($legacy in 'agent', 'command', 'skill') {
            Require (-not (Test-Path -LiteralPath (Join-Path $Root ".opencode/$legacy"))) "Unsupported legacy directory: .opencode/$legacy"
        }
        NoEffort $configText 'opencode.jsonc'
        $localMap = Join-Path $Root '.opencode/opencode.jsonc'
        if (Test-Path -LiteralPath $localMap -PathType Leaf) { NoEffort (Read-SwText $localMap) '.opencode/opencode.jsonc (local tier map)' }
        $localOverlay = @{}
        if (Test-Path -LiteralPath $localMap -PathType Leaf) {
            try {
                $localAgents = (Read-SwJson $localMap)['agents']
                foreach ($role in $roleNames) { $localOverlay[$role] = @(Get-SwOverlayRules $localAgents $role '.opencode/opencode.jsonc') }
                if ($selection -and $localAgents -is [Collections.IDictionary]) {
                    foreach ($role in @($localAgents.Keys | Where-Object { $_ -cin $known.roles -and $_ -cnotin $selection.roles })) { Require $false ".opencode/opencode.jsonc (local tier map) configures deselected kit role $role; edit the map yourself (not rewritten by the kit)" }
                }
            } catch { $problems.Add(".opencode/opencode.jsonc (local tier map): $($_.Exception.Message)") }
        }
        Rules $oc['permissions'] 'opencode.jsonc permissions'
        Require ($oc['default_agent'] -ceq 'project-leader') 'default_agent must be project-leader'

        $agents = @{}; $commands = @{}; $skills = @{}
        $hygiene = [Collections.Generic.List[string]]::new()
        foreach ($kind in 'agents', 'commands', 'skills') {
            $dirRel = if ($kind -eq 'skills') { '.agents/skills' } else { ".opencode/$kind" }
            $dir = Join-Path $Root $dirRel
            if (-not (Test-Path -LiteralPath $dir)) { $problems.Add("Missing directory: $dirRel"); continue }
            if ($kind -eq 'skills') {
                foreach ($flat in Get-ChildItem -LiteralPath $dir -Filter *.md -File -Force) { Require $false "Unsupported flat skill: $($flat.Name)" }
                $defs = @(Get-ChildItem -LiteralPath $dir -Recurse -Filter SKILL.md -File -Force)
            } else {
                $defs = @(Get-ChildItem -LiteralPath $dir -Recurse -Filter *.md -File -Force)
                foreach ($nested in $defs | Where-Object { $_.Directory.FullName -ne (Get-Item -LiteralPath $dir).FullName }) { Require $false "Unsupported nested $kind definition: $($nested.FullName)" }
                $defs = @($defs | Where-Object { $_.Directory.FullName -eq (Get-Item -LiteralPath $dir).FullName })
            }
            foreach ($file in $defs) {
                $hygiene.Add($file.FullName)
                try {
                    $allowed = switch ($kind) { agents { 'description', 'mode', 'color', 'permissions' } commands { 'description', 'agent', 'subagent' } skills { 'name', 'description' } }
                    $data = Read-SwFrontmatter $file.FullName $allowed
                    if ($kind -ne 'skills') { NoEffort (((Read-SwText $file.FullName) -split "`n---`n", 2)[0]) $file.Name }
                    Portable $data $file.Name
                    Require ($data.Contains('description') -and $data['description']) "$($file.Name): description required"
                    switch ($kind) {
                        agents {
                            Require ($data['mode'] -cin 'primary', 'subagent', 'all') "$($file.Name): invalid mode"
                            if ($data.Contains('permissions')) { Rules $data['permissions'] $file.Name }
                            $agents[$file.BaseName] = $data
                        }
                        commands {
                            Require (-not $data['__body'].Contains('!`')) "Command shell expansion is forbidden: $($file.Name)"
                            Require (-not $data.Contains('subagent') -or $data['subagent'] -cin 'true', 'false') "$($file.Name): invalid subagent boolean"
                            $commands[$file.BaseName] = $data
                        }
                        skills {
                            Require ($data['name'] -ceq $file.Directory.Name) "$($file.FullName): name must equal directory"
                            # Agent Skills spec: lowercase letters, digits and single inner hyphens, at most 64 characters.
                            Require ($data['name'] -cmatch '^[a-z0-9]+(-[a-z0-9]+)*$' -and $data['name'].Length -le 64) "$($file.FullName): name must be 1-64 lowercase letters, digits and single hyphens (Agent Skills spec)"
                            Require ($data['description'].Length -le 1024) "$($file.FullName): description exceeds 1024 characters (Agent Skills spec)"
                            Require (-not $skills.ContainsKey($data['name'])) "Duplicate skill: $($data['name'])"
                            $skills[$data['name']] = $data
                        }
                    }
                } catch { $problems.Add("$($file.FullName): $($_.Exception.Message)") }
            }
        }
        # Do not manufacture dependent failures after a parser/layout failure.
        if ($problems.Count) { throw 'Definition validation failed; dependent contract checks were skipped' }

        foreach ($name in $roleNames) { Require ($agents.ContainsKey($name)) "Missing agent: $name" }
        $requiredSkills = if ($selection) { $selection.skills } else { @($script:Skills) + @($profileData['skills']) }
        $routes = [ordered]@{}
        foreach ($name in $script:Routes.Keys) { if (-not $selection -or $script:Routes[$name] -cin $selection.roles) { $routes[$name] = $script:Routes[$name] } }
        if ($selection) {
            # Known deselected kit components must be gone; unknown project-owned ones are kept and disclosed, not adopted.
            $installed = @{ roles = @($agents.Keys); skills = @($skills.Keys); commands = @($commands.Keys) }
            $selected = @{ roles = $selection.roles; skills = $selection.skills; commands = @($routes.Keys) }
            $where = @{ roles = '.opencode/agents/{0}.md'; skills = '.agents/skills/{0}/'; commands = '.opencode/commands/{0}.md' }
            foreach ($kind in 'roles', 'skills', 'commands') {
                foreach ($id in $installed[$kind] | Sort-Object) {
                    $path = $where[$kind] -f $id
                    if ($id -cin $known[$kind]) { Require ($id -cin $selected[$kind]) "Deselected kit component installed: $path (remove it or select it; not hidden by selection)" }
                    else { $warnings += "Project-owned extra kept, outside the selection: $path (not adopted; not shown to be hidden or safe)" }
                }
            }
            # The supported pre-move layout: a deselected kit skill copy under .opencode/skills/ is still installed.
            foreach ($id in @($known.skills | Where-Object { $_ -cnotin $selection.skills })) {
                Require (-not (Test-Path -LiteralPath (Join-Path $Root ".opencode/skills/$id/SKILL.md"))) "Deselected kit component installed: .opencode/skills/$id/ (legacy layout; remove it or select it; not hidden by selection)"
            }
        }
        foreach ($name in $requiredSkills) {
            Require ($skills.ContainsKey($name)) "Missing skill: $name"
            Require (-not (Test-Path -LiteralPath (Join-Path $Root ".opencode/skills/$name/SKILL.md"))) "Kit skill '$name' also exists under .opencode/skills/$name, which shadows the kit copy in OpenCode; move the edit into .agents/skills/$name or delete it"
        }
        Require ($agents['project-leader']['mode'] -ceq 'primary') 'project-leader must be primary'
        foreach ($name in $commands.Keys) { Require ($agents.ContainsKey([string]$commands[$name]['agent'])) "Command $name references missing agent: $($commands[$name]['agent'])" }
        foreach ($name in $routes.Keys) {
            Require ($commands.ContainsKey($name) -and $commands[$name]['agent'] -ceq $routes[$name]) "Command $name must route to $($routes[$name])"
        }
        $ocAgents = if ($oc.Contains('agents')) { $oc['agents'] } else { @{} }
        foreach ($name in $ocAgents.Keys) {
            Rules $ocAgents[$name]['permissions'] "agents.$name permissions"
            Require (-not $agents.ContainsKey($name)) "Agent $name defined in both JSON and Markdown; ambiguous merge"
        }
        foreach ($glob in @($profileData['editDeny'])) {
            Require (@($oc['permissions'] | Where-Object { $_['action'] -ceq 'edit' -and $_['resource'] -ceq $glob -and $_['effect'] -ceq 'deny' }).Count) "opencode.jsonc must deny edit $glob for every role"
        }
        # OpenCode loads each agent's own list only, so the session rules must lead every kit agent.
        $session = @(Add-SwRtkTwins (Get-SwSessionRules $profileData['editDeny'] $tier))
        # Every rendered shell rule is followed by its `rtk ` twin (the RTK plugin rewrites before the check).
        $untwinned = {
            param($Items)
            $items = @($Items)
            for ($i = 0; $i -lt $items.Count; $i++) {
                $r = $items[$i]
                if (-not (Test-SwRtkTwinned $r)) { continue }
                $t = if ($i + 1 -lt $items.Count) { $items[$i + 1] } else { @{} }
                if ($t['action'] -cne 'shell' -or $t['resource'] -cne "rtk $($r['resource'])" -or $t['effect'] -cne $r['effect']) { $r['resource'] }
            }
        }
        $missing = @(& $untwinned $oc['permissions'])
        Require (-not $missing.Count) "RTK twin missing: opencode.jsonc permissions shell [$($missing -join '], [')] needs its [rtk ...] twin, same effect, directly after it; run sw update"
        $buildAllowed = @($roleNames | Where-Object { $_ -ne 'project-leader' }) + 'general', 'explore'
        $buildPerms = @($ocAgents['build']['permissions'])
        $next = if ($buildPerms.Count -gt $session.Count) { $buildPerms[$session.Count] } else { @{} }
        Require ($next['action'] -ceq 'subagent' -and $next['resource'] -ceq '*' -and $next['effect'] -ceq 'deny') 'agents.build must follow the session rules with a subagent wildcard deny'
        $actual = @($buildPerms | Where-Object { $_['action'] -ceq 'subagent' -and $_['effect'] -ceq 'allow' } | ForEach-Object { [string]$_['resource'] } | Sort-Object -Unique)
        Require (-not @(Compare-Object $actual @($buildAllowed | Sort-Object)).Count) "agents.build allowlist must be exactly: $($buildAllowed -join ', ')"
        $ghRules = @(Get-SwGhRules $tier | ForEach-Object { $_['resource'] })
        $ocGh = @($oc['permissions'] | Where-Object { $_['effect'] -ceq 'allow' -and $_['resource'] -like 'gh *' } | ForEach-Object { $_['resource'] })
        Require (-not @(Compare-Object $ocGh $ghRules).Count) "opencode.jsonc GitHub rules do not match githubTier $tier; run sw update"

        $agentsMdText = Read-SwText (Join-Path $Root 'AGENTS.md')
        Require ($agentsMdText -cmatch '(?m)^## Project identity\s*$') 'AGENTS.md must have a "## Project identity" heading (the project-owned section)'
        foreach ($b in Get-SwStartupBudget $config $agentsMdText $agents $skills $roleNames) {
            if (-not $Quiet) { Write-Output "Startup budget: $($b.Role) = $($b.Total) bytes, ~$($b.Tokens) tokens (bytes/4 estimate; tokenizer varies); cap $($b.Cap)" }
            Require ($b.Total -le $b.Cap) "Startup budget exceeded for $($b.Role): $($b.Total) > $($b.Cap) bytes (trim AGENTS.md or raise startupBudgetBytes with evidence)"
        }

        # Permission matrix: what OpenCode loads, each agent's own list only (build: agents.build), plus any local overlay.
        Require (Test-SwPattern 'docs/*.m?' 'docs/nested/file.md') 'Wildcard model regression'
        Require (-not (Test-SwPattern '*.md' 'file.md.cpp')) 'Whole-value model regression'
        foreach ($name in @($roleNames) + 'build') {
            $policy = if ($name -eq 'build') { $buildPerms } elseif ($agents[$name].Contains('permissions')) { @($agents[$name]['permissions']) } else { @() }
            if ($localOverlay.ContainsKey($name)) { $policy += @($localOverlay[$name]) }
            $access = if ($name -eq 'build') { 'full' } else { $roles[$name]['access'] }
            $label = if ($name -eq 'build') { 'opencode.jsonc agents.build' } else { ".opencode/agents/$name.md" }
            foreach ($r in Get-SwRolePolicyChecks -Name $name -Label $label -Policy $policy -Access $access -RoleNames $roleNames -ProfileData $profileData -Tier $tier) { Require $r.Ok $r.Message $r.Category }
        }

        # Claude adapter drift (only when the local adapter has been generated).
        if (Test-Path -LiteralPath (Join-Path $Root '.claude/.sw-generated')) {
            foreach ($entry in (Get-SwClaudeFiles $Root).GetEnumerator()) {
                Require (Test-SwFileMatches (Join-Path $Root $entry.Key) $entry.Value) "Claude adapter drift: $($entry.Key) (run sw claude enable)"
            }
            $importFile = Join-Path $Root '.claude/CLAUDE.md'
            $import = (Read-SwText $importFile).Trim()
            $importTarget = if ($import -match '^@([^\r\n]+)$') { [IO.Path]::GetFullPath((Join-Path (Split-Path $importFile) $Matches[1])) } else { '' }
            Require ($importTarget -eq (Join-Path $Root 'AGENTS.md') -and (Test-Path -LiteralPath $importTarget -PathType Leaf)) 'Claude import must resolve to canonical root AGENTS.md'
            $localModels = Read-SwJson (Join-Path $Root '.opencode/opencode.jsonc')
            # Structure from roles.json, independent of the generator's output.
            foreach ($role in @($roleNames | Where-Object { $_ -ne 'project-leader' })) {
                $target = Join-Path $Root ".claude/agents/$role.md"
                $model = if ($localModels['agents'].Contains($role)) { Get-SwClaudeModel $localModels['agents'][$role]['model'] } else { $null }
                if (-not $model) { Require (-not (Test-Path -LiteralPath $target)) "Claude agent ${role}: unmapped/non-Claude role must not be generated"; continue }
                if (-not (Test-Path -LiteralPath $target)) { Require $false "Missing Claude agent: .claude/agents/$role.md"; continue }
                $fm = ((Read-SwText $target) -split "`n---`n", 2)[0]
                Require ($fm -cmatch "(?m)^model: $([regex]::Escape($model))$") "Claude agent ${role}: model must match the local role map"
                NoEffort $fm "Claude agent $role"
                $tools = [string]$roles[$role]['claudeTools']
                if ($tools) { Require ($fm -cmatch "(?m)^tools: $([regex]::Escape($tools))$") "Claude agent ${role}: tools must be $tools (roles.json claudeTools)" }
                else { Require ($fm -cnotmatch '(?m)^tools:') "Claude agent ${role}: no tools line expected (roles.json claudeTools is empty)" }
                Require ($fm -cmatch '(?m)^disallowedTools: Agent$') "Claude agent ${role}: must set disallowedTools: Agent"
                if ($roles[$role]['access'] -eq 'readonly') { Require ($tools -and $tools -notmatch '\b(Bash|Edit|Write|Agent)\b') "Claude agent ${role}: readonly tools cannot include Bash, Edit, Write or Agent" }
            }
            $claudeSettings = Read-SwJson (Join-Path $Root '.claude/settings.json')
            foreach ($rule in Get-SwClaudeGitRules) { Require ($rule.Rule -cin $claudeSettings['permissions'][$rule.Effect]) "Claude Git rule missing: $($rule.Rule) ($($rule.Effect)); presence only, not runtime enforcement" }
            Require ('Bash(*)' -cnotin $claudeSettings['permissions']['allow']) 'Claude must not allow Bash(*)'
            Require (-not $claudeSettings.Contains('model')) 'Claude settings must not pin a session model'
            NoEffort (Read-SwText (Join-Path $Root '.claude/settings.json')) 'Claude settings'
            # V1 mirrors selected kit commands only; legacy mirrors every installed command.
            foreach ($name in $(if ($selection) { $routes.Keys } else { $commands.Keys })) {
                Require (Test-Path -LiteralPath (Join-Path $Root ".claude/commands/$name.md")) "Missing Claude command: .claude/commands/$name.md"
            }
        }

        # Hygiene: shared workspace files, including untracked ones.
        foreach ($rel in 'AGENTS.md', 'opencode.jsonc', '.sw/config.json', '.sw/workspace.md', '.sw/collaboration.md', '.sw/sw.ps1', '.sw/lib/Sw.Project.psm1') {
            $full = Join-Path $Root $rel
            if (Test-Path -LiteralPath $full -PathType Leaf) { $hygiene.Add($full) }
        }
        $plugins = Join-Path $Root '.opencode/plugins'
        if (Test-Path -LiteralPath $plugins) { Get-ChildItem -LiteralPath $plugins -Recurse -File -Force | ForEach-Object { $hygiene.Add($_.FullName) } }
        foreach ($file in $hygiene | Select-Object -Unique) {
            $counts.HygieneFiles++
            $n = 0
            foreach ($line in (Read-SwText $file) -split "`n") {
                $n++
                if ($line -match '[\t ]+$') { $problems.Add("${file}:${n}: trailing whitespace") }
                if ($line -match '^(<<<<<<<|=======|>>>>>>>)( |$)') { $problems.Add("${file}:${n}: conflict marker") }
                if ($file.EndsWith('.md') -and $line -match $script:MojibakePattern) { $problems.Add("${file}:${n}: possible mojibake") }
                if ($CheckLinks -and $file.EndsWith('.md')) {
                    foreach ($link in [regex]::Matches($line, '\]\(([^\s)]+)\)')) {
                        $target = $link.Groups[1].Value
                        if ($target -match '^(#|[a-zA-Z][a-zA-Z0-9+.-]*:)') { continue }
                        $target = [Uri]::UnescapeDataString(($target -split '#', 2)[0])
                        Require (Test-Path -LiteralPath (Join-Path (Split-Path $file -Parent) $target)) "${file}:${n}: missing local link $target" LocalLinks
                    }
                }
            }
        }

        # Research lint (warnings only; never changes the exit code).
        $warnings += @(Get-SwResearchWarnings $Root)
    } catch { $problems.Add($_.Exception.Message) }

    Write-Output "Static workspace validation: contracts=$($counts.Contracts); permission cases=$($counts.Permissions); hygiene files=$($counts.HygieneFiles); local links=$($counts.LocalLinks). NOT runtime enforcement."
    foreach ($w in $warnings) { Write-Output "WARNING: $w" }
    if ($problems.Count) {
        foreach ($p in $problems) { Write-Output "ERROR: $p" }
        Write-Output "FAILED: $($problems.Count) error(s)."
        $global:LASTEXITCODE = 1
        return
    }
    Write-Output 'PASS: workspace contracts and static permission matrix.'
    $global:LASTEXITCODE = 0
}

# --- Claude adapter (generated, git-ignored, opt-in per user) -----------------------

function Get-SwClaudeModel([string]$Model) {
    # Explicit aliases/full IDs only; no inherit/default or guessed family conversion.
    # Provider-qualified Anthropic IDs are translated to Claude's native model spelling.
    if (-not $Model -or $Model -match '[\s#]' -or $Model -in 'default', 'inherit', 'opusplan') { throw 'Local role model must be explicit and model-only (no default, inherit, whitespace or #variant).' }
    if ($Model -cmatch '^(opus|sonnet|haiku|fable|best|opus\[1m\]|sonnet\[1m\])$') { return $Model }
    if ($Model -cmatch '^(?:anthropic/)?(claude-[a-z0-9][a-z0-9.-]*(?:\[1m\])?)$') { return $Matches[1] }
    if ($Model -cmatch '^[a-zA-Z0-9._-]+/[a-zA-Z0-9._:/-]+$' -and $Model -cnotmatch '^anthropic/|(?i)claude') { return $null }
    throw 'Unsupported local model spelling: use a documented Claude alias/ID, anthropic/claude-ID, or a non-Claude provider/model ID.'
}

function Get-SwClaudeGitRules {
    # Same verb/wrapper lists as OpenCode; Claude wildcard syntax, deny before ask.
    # These are command-text guardrails, not an offline Claude permission evaluator.
    $rules = foreach ($r in $script:SessionBase) {
        if ($r[0] -ne 'shell' -or $r[2] -notin 'ask', 'deny' -or $r[1] -like '*gh *') { continue }
        [ordered]@{ action = 'shell'; resource = $r[1]; effect = $r[2] }
        if ($r[1].EndsWith(' *')) { [ordered]@{ action = 'shell'; resource = $r[1].Substring(0, $r[1].Length - 2); effect = $r[2] } }
    }
    foreach ($r in Add-SwRtkTwins $rules) { [pscustomobject]@{ Effect = $r['effect']; Rule = "Bash($($r['resource']))" } }
}

$script:ClaudeMarker = "Generated by SuperWorkspace. Regenerate with: pwsh .sw/sw.ps1 claude enable`nOnly explicit local Claude roles are generated. Unmapped/non-Claude roles have STOP commands, never a default model. Main-session model selection and live instruction loading require separate verification.`n"

function Get-SwClaudeInputs([string]$Root) {
    # Everything Claude generation reads, from the installed project. Get-SwClaudeFiles also accepts this shape built
    # in memory (the update preflight's candidate), so generation inputs are never staged or copied elsewhere.
    $files = [ordered]@{}
    foreach ($kind in 'agents', 'commands') {
        foreach ($f in Get-ChildItem -LiteralPath (Join-Path $Root ".opencode/$kind") -Filter *.md -File -Force) { $files[".opencode/$kind/$($f.Name)"] = Read-SwText $f.FullName }
    }
    foreach ($skillDir in Get-ChildItem -LiteralPath (Join-Path $Root '.agents/skills') -Directory -Force | Sort-Object Name) {
        foreach ($f in Get-ChildItem -LiteralPath $skillDir.FullName -Recurse -File -Force) {
            $files[".agents/skills/$($skillDir.Name)/$([IO.Path]::GetRelativePath($skillDir.FullName, $f.FullName).Replace('\', '/'))"] = Read-SwText $f.FullName
        }
    }
    $mapPath = Join-Path $Root '.opencode/opencode.jsonc'
    [pscustomobject]@{
        Config  = Get-SwConfig $Root
        Roles   = Read-SwJson (Join-Path $Root '.sw/roles.json')
        Profile = Read-SwJson (Join-Path $Root '.sw/profile.json')
        Map     = $(if (Test-Path -LiteralPath $mapPath -PathType Leaf) { Read-SwJson $mapPath } else { $null })
        Files   = $files
    }
}

function Get-SwClaudeFiles([string]$Root, $Inputs) {
    if (-not $Inputs) { $Inputs = Get-SwClaudeInputs $Root }
    $config = $Inputs.Config
    $roles = $Inputs.Roles
    $profileData = $Inputs.Profile
    $tier = [int]$config['githubTier']
    # V1 mirrors the selected kit commands/skills only, never unselected project-owned extras; legacy mirrors all.
    $selected = $null
    if ($config.Contains('selection')) {
        $selected = $profileData['effectiveSelection']
        if ($selected -isnot [Collections.IDictionary]) { throw 'Selection v1 needs .sw/profile.json effectiveSelection; run sw update.' }
        $selectedCommands = Get-SwSelectionCommands $selected['roles']
    }
    $out = [ordered]@{}
    $note = '<!-- Generated by SuperWorkspace (sw claude enable) from .opencode/; do not edit. -->'
    if ($null -eq $Inputs.Map) { throw 'Claude generation needs an explicit local agents[role].model map (.opencode/opencode.jsonc); run sw tiers with owner-selected models first.' }
    $map = $Inputs.Map
    if ($map['agents'] -isnot [Collections.IDictionary]) { throw 'Local tier map must contain agents[role].model, not a tier dictionary.' }
    $models = [ordered]@{}
    foreach ($role in $roles.Keys) {
        if (-not $map['agents'].Contains($role)) { continue }
        if ($map['agents'][$role] -isnot [Collections.IDictionary] -or $map['agents'][$role]['model'] -isnot [string]) { throw "Local role ${role} needs an explicit model string." }
        $model = Get-SwClaudeModel $map['agents'][$role]['model']
        if ($model) { $models[$role] = $model }
    }
    if (-not $models.Count) { throw 'Local map contains no explicit Claude role models; adapter generation refused (no default fallback).' }
    $workers = @($roles.Keys | Where-Object { $_ -notin 'project-leader', 'explore' -and $models.Contains($_) })
    foreach ($role in $workers) {
        $srcRel = ".opencode/agents/$role.md"
        if (-not $Inputs.Files.Contains($srcRel)) { throw "Missing role definition: $srcRel" }
        $src = Read-SwFrontmatter $srcRel @('description', 'mode', 'color', 'permissions') -Text $Inputs.Files[$srcRel]
        $fm = "---`nname: $role`ndescription: $($src['description'])`nmodel: $($models[$role])`n"
        if ($roles[$role]['claudeTools']) { $fm += "tools: $($roles[$role]['claudeTools'])`n" }
        $fm += "disallowedTools: Agent`n"
        $out[".claude/agents/$role.md"] = $fm + "---`n`n$note`nYou are ``$role``, not Project Leader. Your role contract is ``.opencode/agents/$role.md``: read it first and follow its body. Treat its OpenCode ``permissions`` as binding intent; Claude tool lists restrict available tools, while settings shell patterns are guardrails and other limits remain stated. Canonical project rules are imported by ``.claude/CLAUDE.md``; if unavailable, read root ``AGENTS.md`` before work. Live loading/compaction is not established by generation.`n`nLoad a skill it names with the Skill tool, or Read ``.claude/skills/<name>/SKILL.md``. You cannot spawn agents. When dispatched as a worker, return questions and blockers to the main session; when selected as the main role, follow this role only, without Leader orchestration.`n"
    }
    $dispatch = [ordered]@{}; $inline = [ordered]@{}; $blocked = [ordered]@{}
    $commandNames = @($Inputs.Files.Keys | ForEach-Object { if ($_ -match '^\.opencode/commands/([^/]+)\.md$') { $Matches[1] } } | Sort-Object)
    foreach ($name in $commandNames) {
        if ($selected -and $name -cnotin $selectedCommands) { continue }
        $srcPath = ".opencode/commands/$name.md"
        $cmd = Read-SwFrontmatter $srcPath @('description', 'agent', 'subagent') -Text $Inputs.Files[$srcPath]
        $agent = $cmd['agent']
        # One availability decision renders both this command's body and the Leader summary below.
        $available = $agent -in $workers -or ($agent -eq 'project-leader' -and $models.Contains($agent))
        $mode = if (-not $available) { 'stop' } elseif ($cmd['subagent'] -eq 'true') { 'dispatch' } elseif ($agent -eq 'project-leader') { 'leader' } else { 'inline' }
        switch ($mode) {
            'dispatch' { $dispatch[$agent] = @($dispatch[$agent] | Where-Object { $_ }) + "``/$name``" }
            'inline' { $inline[$agent] = @($inline[$agent] | Where-Object { $_ }) + "``/$name``" }
            'stop' { $blocked[$agent] = @($blocked[$agent] | Where-Object { $_ }) + "``/$name``" }
        }
        $body = switch ($mode) {
            'stop' { "STOP: ``$agent`` has no explicit Claude model in the local role map (unmapped or non-Claude). Do not dispatch, impersonate, or inherit a default model. Return this blocker and use the owner's configured route." }
            'dispatch' { "Dispatch the ``$agent`` agent with the Agent tool to carry out ``$srcPath`` (read it for the task text) with arguments: `$ARGUMENTS. Relay its report." }
            'leader' { "Read ``$srcPath`` and follow its body in this session. Arguments: `$ARGUMENTS" }
            'inline' { "Act as ``$agent`` in this main session for this task only: apply ``.opencode/agents/$agent.md``, then read ``$srcPath`` and follow its body. Arguments: `$ARGUMENTS" }
        }
        $out[".claude/commands/$name.md"] = "---`ndescription: $($cmd['description'])`n---`n`n$note`n$body`n"
    }
    $skillNames = @($Inputs.Files.Keys | ForEach-Object { if ($_ -match '^\.agents/skills/([^/]+)/') { $Matches[1] } } | Select-Object -Unique | Sort-Object)
    foreach ($skill in $skillNames) {
        if ($selected -and $skill -cnotin $selected['skills']) { continue }
        foreach ($rel in @($Inputs.Files.Keys | Where-Object { $_.StartsWith(".agents/skills/$skill/", [StringComparison]::Ordinal) })) {
            $out[".claude/skills/$skill/$($rel.Substring(".agents/skills/$skill/".Length))"] = $Inputs.Files[$rel]
        }
    }
    $list = ($workers | ForEach-Object { "``$_``" }) -join ', '
    $dispatchLine = if ($dispatch.Count) {
        (@($dispatch.Keys | ForEach-Object { "$($dispatch[$_] -join ' and ') $(if ($dispatch[$_].Count -gt 1) { 'dispatch' } else { 'dispatches' }) ``$_``" }) -join '; ') + '.'
    } else { 'No command dispatches a subagent.' }
    $inlineLine = @($inline.Keys | ForEach-Object { "$($inline[$_] -join ' and ') applies the ``$_`` contract inline." }) -join ' '
    $stopLine = @($blocked.Keys | ForEach-Object { "$($blocked[$_] -join ' and ') $(if ($blocked[$_].Count -gt 1) { 'stop' } else { 'stops' }) with a blocker because ``$_`` has no explicit Claude model in the local map." }) -join ' '
    $commandLine = ((@($inlineLine, $stopLine, $dispatchLine) | Where-Object { $_ }) -join ' ')
    $out['.claude/project-leader.md'] = (@"
# Project Leader (Claude main session)

$note
Use this material only when the explicitly selected main role is ``project-leader``;
it is not injected by a session-wide hook into worker/main executor sessions.
Read ``.opencode/agents/project-leader.md``
and follow its body; ``.sw/workspace.md`` owns orchestration. Claude adaptation:

- Dispatch with the Agent tool, ``subagent_type`` = role ID: $list.
  Only locally mapped Claude workers are generated; no implicit built-in fallback.
- Only this session spawns agents. Subagents cannot delegate or ask the user.
- Skills: the Skill tool, or Read ``.claude/skills/<name>/SKILL.md``.
- Commands pinned ``subagent: false`` run here; $commandLine
- GitHub tier $tier (see ``.sw/workspace.md``). Never push, merge, or release.
"@ + "`n").Replace("`r`n", "`n")
    $gitRules = @(Get-SwClaudeGitRules)
    $deny = @($gitRules | Where-Object Effect -eq 'deny' | ForEach-Object { $_.Rule }) + @(Get-SwClaudeGhDeny $tier) +
        @($profileData['editDeny'] | ForEach-Object { "Edit(**/$_)" })
    $ask = @($gitRules | Where-Object Effect -eq 'ask' | ForEach-Object { $_.Rule }) + @('Read(**/.env)', 'Read(**/.env.*)') + $(if ($tier -ge 1) { @('Bash(gh pr create:*)') } else { @() })
    $settings = [ordered]@{
        permissions = [ordered]@{ allow = @('Skill'); ask = $ask; deny = $deny }
    }
    $out['.claude/CLAUDE.md'] = "@../AGENTS.md`n"
    $out['.claude/settings.json'] = ConvertTo-SwJson $settings
    # Ownership metadata, last: a sorted per-file byte-hash inventory of everything above (never of itself).
    $paths = [string[]]@($out.Keys)
    [Array]::Sort($paths, [StringComparer]::Ordinal)
    $inventory = $paths | ForEach-Object { "$(Get-SwByteHash (Get-SwTextBytes $out[$_]))  $_" }
    $out['.claude/.sw-generated'] = $script:ClaudeMarker + "sw-ownership: 1`n" + (($inventory -join "`n") + "`n")
    $out
}

function Read-SwClaudeOwnership([string]$Root) {
    # State: absent | legacy (marker without inventory) | invalid | ok. Only 'ok' proves ownership; a bad
    # inventory is rejected whole (unknown version, duplicate, absolute/escaping path, settings.local.json).
    $path = Join-Path $Root '.claude/.sw-generated'
    $result = { param($State, $Reason, $Entries = [ordered]@{}) [pscustomobject]@{ State = $State; Reason = $Reason; Entries = $Entries } }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return (& $result 'absent' $null) }
    $lines = @((Read-SwText $path) -split "`n")
    $headers = @($lines | Where-Object { $_ -cmatch '^sw-ownership:' })
    if (-not $headers.Count) { return (& $result 'legacy' 'no ownership inventory') }
    if ($headers.Count -ne 1 -or $headers[0] -cne 'sw-ownership: 1') { return (& $result 'invalid' "unsupported or repeated ownership header: $($headers -join ' / ')") }
    $entries = [ordered]@{}; $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $claudeDir = Join-Path $Root '.claude'
    foreach ($line in @($lines | Select-Object -Skip ([array]::IndexOf($lines, $headers[0]) + 1))) {
        if ($line -ceq '') { continue }
        $m = [regex]::Match($line, '^([0-9a-f]{64})  (.+)$')
        if (-not $m.Success) { return (& $result 'invalid' "malformed inventory line: $line") }
        $hash = $m.Groups[1].Value; $rel = $m.Groups[2].Value
        $segments = $rel -split '/'
        if ($rel -match '[\\:]' -or [IO.Path]::IsPathRooted($rel) -or @($segments | Where-Object { $_ -in '', '.', '..' }).Count -or $segments[0] -cne '.claude' -or $segments.Count -lt 2) { return (& $result 'invalid' "path is not a clean relative .claude/ path: $rel") }
        if ($segments[-1] -ieq 'settings.local.json' -or $rel -ieq '.claude/.sw-generated') { return (& $result 'invalid' "path is not generated-owned: $rel") }
        if (-not (Test-SwContained $claudeDir (Join-Path $Root $rel))) { return (& $result 'invalid' "path escapes .claude/: $rel") }
        if (-not $seen.Add($rel)) { return (& $result 'invalid' "duplicate inventory path: $rel") }
        $entries[$rel] = $hash
    }
    & $result 'ok' $null $entries
}

function Test-SwFileMatches([string]$Path, [string]$Content) {
    # Byte-exact comparison against what the generator would write.
    (Test-Path -LiteralPath $Path -PathType Leaf) -and (Get-SwByteHash ([IO.File]::ReadAllBytes($Path))) -ceq (Get-SwByteHash (Get-SwTextBytes $Content))
}

function Invoke-SwClaude {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Position = 0)][ValidateSet('enable', 'disable')][string]$Action = 'enable', [string]$Path)
    $Root = Resolve-SwRoot $Path
    $own = Read-SwClaudeOwnership $Root
    $hashOf = { param($rel) Get-SwByteHash ([IO.File]::ReadAllBytes((Join-Path $Root $rel))) }
    if ($Action -eq 'disable') {
        # Removal comes from installed ownership, never from regenerating a (possibly different) replacement map.
        if ($own.State -eq 'invalid') { throw "Claude ownership record is invalid ($($own.Reason)); nothing was removed. Repair or delete .claude/.sw-generated by hand." }
        if ($own.State -eq 'absent') { Write-Output 'No Claude adapter ownership record (.claude/.sw-generated); nothing was removed.'; $global:LASTEXITCODE = 0; return }
        $owned = $own.Entries; $why = $null
        if ($own.State -eq 'legacy') {
            # An older install recorded no inventory: ownership is provable only where the original content can be regenerated exactly.
            $owned = [ordered]@{}
            try { $expected = Get-SwClaudeFiles $Root; foreach ($k in $expected.Keys) { if ($k -cne '.claude/.sw-generated') { $owned[$k] = Get-SwByteHash (Get-SwTextBytes $expected[$k]) } } }
            catch { $why = $_.Exception.Message }
        }
        $removed = [Collections.Generic.List[string]]::new(); $kept = [Collections.Generic.List[string]]::new()
        foreach ($rel in $owned.Keys) {
            if (-not (Test-Path -LiteralPath (Join-Path $Root $rel) -PathType Leaf)) { continue }
            if ((& $hashOf $rel) -ceq $owned[$rel]) {
                if ($PSCmdlet.ShouldProcess($rel, 'remove')) { Remove-Item -LiteralPath (Join-Path $Root $rel) -Force }
                $removed.Add($rel)
            } else { $kept.Add("$rel (edited)") }
        }
        if ($own.State -eq 'legacy') {
            # Anything else that merely looks generated stays loadable, so report it instead of claiming completion.
            foreach ($sub in 'agents', 'commands', 'skills') {
                $dir = Join-Path $Root ".claude/$sub"
                if (-not (Test-Path -LiteralPath $dir)) { continue }
                foreach ($f in Get-ChildItem -LiteralPath $dir -Recurse -File -Force) {
                    $rel = [IO.Path]::GetRelativePath($Root, $f.FullName).Replace('\', '/')
                    if (-not $owned.Contains($rel)) { $kept.Add("$rel (unverified legacy file)") }
                }
            }
            if ($why) { $kept.Add("all legacy files (cannot reproduce the original generation: $why)") }
        }
        if ($kept.Count) {
            Write-Output "Claude adapter disable PARTIAL (blocked): $($removed.Count) file(s) removed; preserved: $($kept -join '; '). .claude/.sw-generated kept so the rest can be resolved; settings.local.json and your own files are never touched."
            $global:LASTEXITCODE = 1
            return
        }
        if ($PSCmdlet.ShouldProcess('.claude/.sw-generated', 'remove')) { Remove-Item -LiteralPath (Join-Path $Root '.claude/.sw-generated') -Force }
        Write-Output "Claude adapter files removed: $($removed.Count) (settings.local.json and your own files kept)."
        $global:LASTEXITCODE = 0
        return
    }
    $files = Get-SwClaudeFiles $Root
    if (-not (Test-SwLocalOnly $Root '.claude/settings.json')) { throw '.claude/ must be git-ignored before generating the local adapter (run sw update).' }
    # Verified ownership only: a legacy or invalid record proves nothing, so those files are backed up, not trusted.
    $verified = if ($own.State -eq 'ok') { $own.Entries } else { [ordered]@{} }
    $backup = Join-Path $Root ".sw/backup/$(Get-SwOperationId)"
    $reserved = $false; $preserved = [Collections.Generic.List[string]]::new()
    # Stale generated files (in the old inventory, no longer generated) go only while unedited.
    foreach ($rel in $verified.Keys) {
        if ($files.Contains($rel) -or -not (Test-Path -LiteralPath (Join-Path $Root $rel) -PathType Leaf)) { continue }
        if ((& $hashOf $rel) -ceq $verified[$rel]) { if ($PSCmdlet.ShouldProcess($rel, 'remove stale')) { Remove-Item -LiteralPath (Join-Path $Root $rel) -Force } }
        else { $preserved.Add($rel) }
    }
    # Ownership metadata is last in $files, so an interrupted run leaves the previous record in place.
    foreach ($e in $files.GetEnumerator()) {
        $target = Join-Path $Root $e.Key
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            if (Test-SwFileMatches $target $e.Value) { continue }
            $ours = ($verified.Contains($e.Key) -and (& $hashOf $e.Key) -ceq $verified[$e.Key]) -or ($e.Key -ceq '.claude/.sw-generated' -and $own.State -ne 'invalid')
            if (-not $ours -and $PSCmdlet.ShouldProcess($e.Key, 'back up before replacing')) {
                if (-not $reserved) { $null = New-SwSnapshotDir $backup; $reserved = $true }
                Copy-SwNew $target (Join-Path $backup $e.Key)   # a failed copy stops here, before the replacement
            }
        }
        if ($PSCmdlet.ShouldProcess($e.Key, 'write')) { Write-SwFile $target $e.Value }
    }
    Write-Output "Claude adapter: $($files.Count) files generated under .claude/ (git-ignored)."
    if ($preserved.Count) { Write-Output "Edited stale generated file(s) kept: $($preserved -join ', ')." }
    if ($own.State -eq 'legacy') {
        # A pre-inventory install proves no ownership of files it no longer generates; they stay loadable, so say so.
        $left = foreach ($sub in 'agents', 'commands', 'skills') {
            $dir = Join-Path $Root ".claude/$sub"
            if (-not (Test-Path -LiteralPath $dir)) { continue }
            foreach ($f in Get-ChildItem -LiteralPath $dir -Recurse -File -Force) {
                $rel = [IO.Path]::GetRelativePath($Root, $f.FullName).Replace('\', '/')
                if (-not $files.Contains($rel)) { $rel }
            }
        }
        if (@($left).Count) { Write-Output "Unverified legacy file(s) left in place (not in the new inventory): $(@($left) -join ', ')." }
    }
    $global:LASTEXITCODE = 0
}

# --- per-user model tiers ---------------------------------------------------------------

function Set-SwTiers {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Light, [string]$Standard, [string]$High, [string]$Path, [switch]$Force)
    $Root = Resolve-SwRoot $Path
    $roles = Read-SwJson (Join-Path $Root '.sw/roles.json')
    $target = Join-Path $Root '.opencode/opencode.jsonc'
    if ((Test-Path -LiteralPath $target) -and -not $Force) { throw ".opencode/opencode.jsonc exists; edit it by hand or pass -Force (overwrites your local tier map)." }
    if (-not (Test-SwLocalOnly $Root '.opencode/opencode.jsonc')) { throw '.opencode/opencode.jsonc must be git-ignored first (run sw update).' }
    $models = @{ light = $Light; standard = $Standard; high = $High }
    foreach ($m in $models.Values) { if ($m -and $m.Contains('#')) { throw "Tiers are model-only: drop the #variant suffix from '$m'." } }
    $map = [ordered]@{}
    foreach ($role in $roles.Keys) {
        $m = $models[$roles[$role]['tier']]
        if ($m) { $map[$role] = [ordered]@{ model = $m } }
    }
    if ($PSCmdlet.ShouldProcess($target, "write tier map ($($map.Count) roles)")) {
        Write-SwFile $target (ConvertTo-SwJson ([ordered]@{ '$schema' = 'https://opencode.ai/config.json'; agents = $map }))
    }
    Write-Output "Tier map: $($map.Count) role(s) mapped; OpenCode unmapped roles inherit the session model. Claude generation skips them; explicit launcher selection must reject missing models."
}

# --- explicit native session entry (no broker or automatic retry) -------------------------

function Write-SwSessionEvent([string]$Root, [string]$Task, $Launch, [string]$State, $ExitCode) {
    $utc = Get-SwUtc
    $dir = Join-Path $Root ".sw/comms/tasks/$Task"
    $branch = & git -C $Root branch --show-current 2>$null
    $head = & git -C $Root rev-parse HEAD 2>$null
    $text = @"
# $Task - progress - $utc - session

- **Approval:** launch metadata only; reconcile existing approval/assignment, not new authority.
- **Status:** $(if ($State -eq 'launch') { 'in_progress' } else { 'blocked' }); $State
- **Checked revision:** $branch / $head; uncommitted scope must be reconciled with actual Git/artifacts.
- **Launch ID:** $($Launch.LaunchId) (local correlation, not native session identity)
- **Requested role / tool / model:** $($Launch.Role) / $($Launch.Tool) / $($Launch.RequestedModel)
- **Native model argument:** $($Launch.NativeModel); observed model unknown
- **Session ID:** unknown (not reported/verified)
- **Exit code:** $(if ($null -eq $ExitCode) { 'unknown' } else { $ExitCode })
- **Artifact / effects:** unknown, not accepted; exit 0 is not completion evidence.
- **Publication:** local-only, uncommitted; no prompt or native transcript retained.
- **Next action:** inspect actual artifacts, latest approval/assignment and unknown effects before kickoff/resume; no blind retry or rollback.
"@ + "`n"
    # The launch ID keeps concurrent launches apart; the exclusive allocator separates one launch's own events.
    New-SwExclusiveFile $dir "$utc-session-progress-$($Launch.LaunchId)" '.md' $text
}

function Find-SwNative([string]$Tool) {
    # Launch-time discovery (PATH only, no desktop fallback); a function so tests can substitute a stub.
    $cmd = Get-Command $Tool -CommandType Application, ExternalScript -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { $cmd.Source }
}

function Invoke-SwSession {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory)][ValidateSet('start')][string]$Action,
        [Parameter(Position = 1, Mandatory)][string]$Role,
        [Parameter(Position = 2, Mandatory)][string]$Task,
        [string]$Model, [string]$Path, [switch]$DryRun, [switch]$Headless
    )
    Assert-SwSafeName $Role 'Role'; Assert-SwSafeName $Task 'Task'
    if ($Task.StartsWith('-')) { throw 'Task must not start with a CLI flag prefix.' }
    $Root = Resolve-SwRoot $Path
    $config = Get-SwConfig $Root
    if ($config -isnot [Collections.IDictionary] -or $config['users'] -isnot [array] -or $config['githubTier'] -notin 0, 1) { throw 'Malformed workspace configuration.' }
    $oc = Read-SwJson (Join-Path $Root 'opencode.jsonc')
    if ($oc -isnot [Collections.IDictionary] -or $oc['agents'] -isnot [Collections.IDictionary]) { throw 'Malformed shared OpenCode configuration.' }
    $roles = Read-SwJson (Join-Path $Root '.sw/roles.json')
    if (-not $roles.Contains($Role) -or $roles[$Role]['access'] -eq 'builtin') { throw 'Unknown or unsupported standalone role.' }
    $roleFile = Join-Path $Root ".opencode/agents/$Role.md"
    $agent = Read-SwFrontmatter $roleFile @('description', 'mode', 'color', 'permissions')
    if ($agent['mode'] -notin 'primary', 'all') { throw 'Role cannot run as a standalone main session.' }
    $taskDir = Join-Path $Root ".sw/comms/tasks/$Task"
    if (-not (Test-Path -LiteralPath $taskDir -PathType Container) -or -not @(Get-ChildItem -LiteralPath $taskDir -Filter *.md -File).Count) { throw 'Existing task records required; a launch cannot create task authority.' }
    $mapPath = Join-Path $Root '.opencode/opencode.jsonc'
    if (-not (Test-Path -LiteralPath $mapPath -PathType Leaf)) { throw 'Explicit local agents[role].model map required.' }
    $map = Read-SwJson $mapPath
    if ($map -isnot [Collections.IDictionary] -or $map['agents'] -isnot [Collections.IDictionary]) { throw 'Malformed local agents[role].model map.' }
    # Validate every roster entry, not just the selected one: no hidden fallback.
    foreach ($id in $roles.Keys) {
        if (-not $map['agents'].Contains($id)) { continue }
        $entry = $map['agents'][$id]
        if ($entry -isnot [Collections.IDictionary] -or $entry['model'] -isnot [string] -or $entry['disable'] -eq $true) { throw 'Local role needs an enabled explicit model string.' }
        $null = Get-SwClaudeModel $entry['model']
    }
    $mapped = if ($map['agents'].Contains($Role)) { $map['agents'][$Role]['model'] } else { $null }
    if ($roles[$Role]['tier'] -eq 'session') {
        if (-not $Model) { throw 'Session-tier primary role requires explicit -Model.' }
    } else {
        if (-not $mapped) { throw 'Worker requires actual local agents[role].model; no inheritance.' }
        if ($Model -and $Model -cne $mapped) { throw 'Conflicting worker -Model override; edit the local map and regenerate first.' }
        $Model = $mapped
    }
    if ($mapped -and $mapped -cne $Model) { throw 'Primary model conflicts with the local role map.' }
    foreach ($settings in $oc['agents'], $map['agents']) {
        if (-not $settings.Contains($Role)) { continue }
        $entry = $settings[$Role]
        if ($entry -isnot [Collections.IDictionary] -or $entry['disable'] -eq $true -or ($entry['mode'] -and $entry['mode'] -cne $agent['mode']) -or ($entry['model'] -and $entry['model'] -cne $Model)) { throw 'Conflicting selected role configuration; reconcile agent/model/mode before launch.' }
    }
    # The same narrow check validate runs, on the selected role's effective list: its file, then shared and
    # local overlays (a later override must not undermine the policy just checked). Rejects before any event or process.
    $profileData = Read-SwJson (Join-Path $Root '.sw/profile.json')
    $roleNames = @($roles.Keys | Where-Object { $_ -ne 'explore' })
    $policy = @(if ($agent.Contains('permissions')) { $agent['permissions'] }) + @(Get-SwOverlayRules $oc['agents'] $Role 'opencode.jsonc') + @(Get-SwOverlayRules $map['agents'] $Role '.opencode/opencode.jsonc')
    $rejected = @(Get-SwRolePolicyChecks -Name $Role -Label ".opencode/agents/$Role.md" -Policy $policy -Access $roles[$Role]['access'] -RoleNames $roleNames -ProfileData $profileData -Tier ([int]$config['githubTier']) | Where-Object { -not $_.Ok })
    if ($rejected.Count) { throw "Selected role policy rejected before launch: $($rejected[0].Message)$(if ($rejected.Count -gt 1) { " (+$($rejected.Count - 1) more)" })" }
    $claudeModel = Get-SwClaudeModel $Model
    $tool = if ($claudeModel) { 'claude' } else { 'opencode' }
    $nativeModel = if ($claudeModel) { $claudeModel } else { $Model }
    $prompt = "Selected main role: $Role. Task: $Task. Before work, read this role contract and existing .sw/comms/tasks/$Task records; reconcile actual artifacts/current approval/assignment and unknown effects. Launch metadata is not approval. Stop for missing authority or unknown effects; no automatic retry/rollback. Follow this role only; workers never delegate."
    if ($tool -eq 'claude') {
        if ($Headless) { throw 'Headless Claude is not supported; use the interactive subscription route.' }
        if ($Role -eq 'project-leader' -and -not $mapped) { throw 'Claude Leader requires a matching explicit local Leader entry for its commands/adapter.' }
        $files = Get-SwClaudeFiles $Root
        foreach ($rel in $files.Keys) {
            if (-not (Test-SwFileMatches (Join-Path $Root $rel) $files[$rel])) { throw 'Missing or stale Claude adapter; regenerate with sw claude enable.' }
        }
        # A removed role must not remain available as a stale generated worker.
        foreach ($file in Get-ChildItem -LiteralPath (Join-Path $Root '.claude/agents') -Filter *.md -File -ErrorAction SilentlyContinue) {
            $rel = ".claude/agents/$($file.Name)"
            if ($roles.Contains($file.BaseName) -and -not $files.Contains($rel)) { throw 'Stale Claude worker adapter; regenerate before launch.' }
        }
        $argv = @('--model', $nativeModel)
        if ($Role -eq 'project-leader') { $argv += @('--append-system-prompt-file', (Join-Path $Root '.claude/project-leader.md')) }
        else {
            $argv += @('--agent', $Role, '--disallowedTools', 'Agent')
            if ($roles[$Role]['claudeTools']) { $argv += @('--tools', $roles[$Role]['claudeTools']) }
        }
        $argv += @('--', $prompt)
    } else {
        # The full-screen V2 entry lacks model/agent flags; mini supports both.
        $argv = @($(if ($Headless) { 'run' } else { 'mini' }), '--model', $nativeModel, '--agent', $Role)
        if ($Headless) { $argv += @('--', $prompt) } else { $argv += @('--prompt', $prompt) }
    }
    $native = Find-SwNative $tool
    if (-not $native) { throw "Native CLI '$tool' not installed/on PATH; no launch attempted." }
    $launch = [pscustomobject]@{ Role = $Role; Task = $Task; Tool = $tool; RequestedModel = $Model; NativeModel = $nativeModel; Arguments = $argv; SessionId = $null; LaunchId = $null; ExitCode = $null }
    if ($DryRun -or -not $PSCmdlet.ShouldProcess("$Role / $tool", 'start native session (not task approval)')) { $global:LASTEXITCODE = 0; return $launch }
    $launch.LaunchId = [guid]::NewGuid().ToString('N')
    $null = Write-SwSessionEvent $Root $Task $launch 'launch' $null
    $exitCode = $null
    Push-Location -LiteralPath $Root
    try {
        # Preserve numeric exits even if the caller opted into native-error conversion.
        $PSNativeCommandUseErrorActionPreference = $false
        $global:LASTEXITCODE = 0
        # Do not pipe/capture native stdio: interactive CLIs need the real terminal.
        & $native @argv
        $exitCode = $LASTEXITCODE
    } catch {
        $why = $null
        try { $null = Write-SwSessionEvent $Root $Task $launch 'invocation-failure; effects unknown' $null } catch { $why = $_.Exception.Message }
        throw $(if ($why) { "Native invocation failed and its event could not be recorded ($why); recording unknown/blocked, effects/session identity unknown. Inspect task records/artifacts; do not retry blindly." }
            else { 'Native invocation failed; effects/session identity unknown. Inspect task records/artifacts; do not retry blindly.' })
    } finally { Pop-Location }
    $launch.ExitCode = $exitCode
    try { $null = Write-SwSessionEvent $Root $Task $launch $(if ($exitCode -eq 0) { 'exited; acceptance pending' } else { 'exit-failure; effects unknown' }) $exitCode }
    catch {
        # The observed native exit survives a failed recording; no exit event is claimed.
        $failure = [InvalidOperationException]::new("Native session exited with code $exitCode but its exit event could not be recorded ($($_.Exception.Message)); recording unknown/blocked. Inspect task records and artifacts; do not retry blindly.")
        $failure.Data['ExitCode'] = $exitCode
        $failure.Data['Launch'] = $launch
        $global:LASTEXITCODE = $exitCode
        throw $failure
    }
    $global:LASTEXITCODE = $exitCode
    $launch
}

# --- comms ------------------------------------------------------------------------------

function Invoke-SwComms {
    <#
    .SYNOPSIS sw comms send|inbox|event|close|archive
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory)][ValidateSet('send', 'inbox', 'event', 'close', 'archive')][string]$Action,
        [string]$To, [string]$From, [string]$User, [string]$Subject, [string]$Body, [string]$Task,
        [string]$Event = 'progress', [ValidateSet('pending', 'in_progress', 'complete', 'blocked')][string]$Status = 'in_progress',
        [string]$Outcome, [string]$Message, [string]$Path
    )
    $Root = Resolve-SwRoot $Path
    $comms = Join-Path $Root '.sw/comms'
    if ($To) { Assert-SwSafeName $To 'To' }
    if ($From) { Assert-SwSafeName $From 'From' }
    if ($User) { Assert-SwSafeName $User 'User' }
    if ($Task) { Assert-SwSafeName $Task 'Task' }
    if ($Event) { Assert-SwSafeName $Event 'Event' }
    if ($Message) { Assert-SwSafeFileName $Message 'Message' }
    switch ($Action) {
        'send' {
            if (-not $To -or -not $Subject) { throw 'send needs -To and -Subject (and -Body).' }
            if (-not $From) { $From = Get-SwUser $Root }
            $dir = Join-Path $comms "inbox/$To"
            $base = "$(Get-SwUtc)-$From-$(ConvertTo-SwSlug $Subject)"
            $file = Join-Path $dir "$base.md"
            $text = "# $Subject`n`n- **From:** $From`n- **To:** $To`n- **Task:** $(if ($Task) { $Task } else { 'none' })`n- **Sent (UTC):** $([DateTime]::UtcNow.ToString('u'))`n`n$Body`n"
            if ($PSCmdlet.ShouldProcess($file, 'write message')) { $file = New-SwExclusiveFile $dir $base '.md' $text }
            Write-Output "Message written: $([IO.Path]::GetRelativePath($Root, $file)) (local until a human pushes it)."
        }
        'inbox' {
            if (-not $User) { $User = Get-SwUser $Root }
            $dir = Join-Path $comms "inbox/$User"
            $items = @(if (Test-Path -LiteralPath $dir) { Get-ChildItem -LiteralPath $dir -Filter *.md -File -Force | Sort-Object Name })
            if (-not $items.Count) { Write-Output "Inbox empty: $User"; return }
            foreach ($i in $items) { Write-Output "$($i.Name)`t$(((Read-SwText $i.FullName) -split "`n")[0].TrimStart('# '))" }
        }
        'archive' {
            if (-not $User) { $User = Get-SwUser $Root }
            if (-not $Message) { throw 'archive needs -Message <file name from sw comms inbox>.' }
            $src = Join-Path $comms "inbox/$User/$Message"
            $dst = Join-Path $comms "archive/inbox/$User/$Message"
            if ($PSCmdlet.ShouldProcess($src, 'archive')) { New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null; Move-Item -LiteralPath $src -Destination $dst }
            Write-Output "Archived: $Message"
        }
        'event' {
            if (-not $Task) { throw 'event needs -Task <task-id>.' }
            $author = if ($From) { $From } else { Get-SwUser $Root }
            $branch = (& git -C $Root branch --show-current 2>$null)
            $head = (& git -C $Root rev-parse HEAD 2>$null)
            # Task records churn on every event; list other changes only, at most 10.
            $changed = @(& git -C $Root status --porcelain 2>$null | Where-Object { $_ -and $_.Substring(3).TrimStart('"') -notlike '.sw/comms/*' })
            $dirty = @($changed | Select-Object -First 10) -join '; '
            if ($changed.Count -gt 10) { $dirty += " (+$($changed.Count - 10) more)" }
            $utc = Get-SwUtc
            $taskDir = Join-Path $comms "tasks/$Task"
            $file = Join-Path $taskDir "$utc-$author-$Event.md"
            $text = @"
# $Task - $Event - $utc - $author

- **Author / audience:** $author
- **Approval:** <who approved what, when; or "proposal, not approved">
- **Scope / acceptance:** <outcome, success evidence, exclusions>
- **Status:** $Status
- **Branch / base:** $branch; published main <full SHA, when observed>
- **Checked revision / changed:** $head$(if ($dirty) { " plus uncommitted: $dirty" } else { ' (clean)' })
- **Owners / dependencies:** <owners; dependencies and their state>
- **Decisions / remaining:** $(if ($Body) { $Body } else { '<choices made, work done, next items>' })
- **Validation:** <runner; time/zone; exact command; result; evidence location>
- **Not validated / risks:** <missing or failed checks>
- **Publication:** local-only until a human pushes
- **Next action:** <owner; executable step; completion evidence>
"@ + "`n"
            if ($PSCmdlet.ShouldProcess($file, 'write task event')) { $file = New-SwExclusiveFile $taskDir "$utc-$author-$Event" '.md' $text }
            Write-Output "Event written: $([IO.Path]::GetRelativePath($Root, $file)). Fill the <placeholders> before handing off."
        }
        'close' {
            if (-not $Task -or -not $Outcome) { throw 'close needs -Task and -Outcome.' }
            $src = Join-Path $comms "tasks/$Task"
            if (-not (Test-Path -LiteralPath $src)) { throw "No task record: .sw/comms/tasks/$Task" }
            $dst = Join-Path $comms "archive/$Task"
            $events = @(Get-ChildItem -LiteralPath $src -Filter *.md -File -Force | Sort-Object Name)
            $head = (& git -C $Root rev-parse HEAD 2>$null)
            if (Test-Path -LiteralPath $dst) { throw "Archive already exists, refusing to overwrite: .sw/comms/archive/$Task" }
            $summary = "# $Task - summary`n`n- **Outcome:** $Outcome`n- **Closed:** $([DateTime]::UtcNow.ToString('u')) by $(Get-SwUser $Root) at $head`n- **Events:** $($events.Count), kept in ``events/`` for evidence; read this summary instead.`n`n" +
                (($events | ForEach-Object { "- $($_.Name)" }) -join "`n") + "`n"
            if ($PSCmdlet.ShouldProcess($dst, 'archive task')) {
                # Move the whole task folder (not just *.md) so nothing non-markdown is silently dropped.
                New-Item -ItemType Directory -Force $dst | Out-Null
                Move-Item -LiteralPath $src -Destination (Join-Path $dst 'events')
                Write-SwFile (Join-Path $dst 'SUMMARY.md') $summary
            }
            Write-Output "Closed $Task -> .sw/comms/archive/$Task/SUMMARY.md"
        }
    }
}

function Add-SwUser {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Position = 0, Mandatory)][ValidatePattern('^[a-z0-9_-]+$')][string]$Name, [string]$Path)
    $Root = Resolve-SwRoot $Path
    $configPath = Join-Path $Root '.sw/config.json'
    $config = Read-SwJson $configPath
    $users = [Collections.Generic.List[string]]@($config['users'])
    if ($users -notcontains $Name) { $users.Add($Name) }
    $config['users'] = @($users)
    if ($PSCmdlet.ShouldProcess($configPath, "add contributor $Name")) {
        Write-SwFile $configPath (ConvertTo-SwJson $config)
        Write-SwFile (Join-Path $Root ".sw/comms/inbox/$Name/.gitkeep") ''
    }
    Write-Output "Contributor $Name recorded. Their branch (created by the owner, from published main):"
    Write-Output "  git switch -c $Name/$Name-worktree origin/main"
    Write-Output "Send them .sw/onboarding.md; they check their setup with: pwsh .sw/sw.ps1 doctor -User $Name"
}

function Get-SwDoctorHint([string]$Tool) {
    $winget = @{ git = 'Git.Git'; pwsh = 'Microsoft.PowerShell'; gh = 'GitHub.cli' }
    if ($winget.Contains($Tool)) { if ($IsWindows) { "winget install $($winget[$Tool])" } else { $Tool } }
    elseif ($Tool -eq 'opencode') { 'install OpenCode Desktop' }
    else { 'install rtk' }
}

function Test-SwDoctor {
    <#
    .SYNOPSIS Read-only setup check for a contributor: doctor [-User <name>]. Never installs or changes anything.
    #>
    [CmdletBinding()]
    param([string]$User, [string]$Path)
    $Root = Resolve-SwRoot $Path
    $rows = [Collections.Generic.List[object]]::new()
    $add = { param($n, $state, $detail) $rows.Add([pscustomobject]@{ Item = $n; State = $state; Detail = $detail }) }

    & $add 'pwsh >= 7.2' 'OK' $PSVersionTable.PSVersion.ToString()

    $hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
    & $add 'git' $(if ($hasGit) { 'OK' } else { 'MISSING' }) $(if ($hasGit) { (& git --version) } else { "Fix: $(Get-SwDoctorHint git)" })
    $userName = if ($hasGit) { & git -C $Root config user.name 2>$null }
    & $add 'git user.name' $(if ($userName) { 'OK' } else { 'MISSING' }) $(if ($userName) { $userName } else { 'Fix: git config --global user.name "<name>"' })

    # Required OpenCode: a tool that is present but cannot report a version is a failure, not OK.
    $oc = Get-SwToolProbe opencode
    & $add 'opencode' $(switch ($oc.State) { 'ok' { 'OK' } 'missing' { 'MISSING' } default { 'FAILED' } }) $(switch ($oc.State) { 'ok' { $oc.Version.ToString() } 'missing' { "Fix: $(Get-SwDoctorHint opencode)" } default { "$(Format-SwProbe $oc); Fix: $(Get-SwDoctorHint opencode)" } })

    $gh = Get-SwToolProbe gh
    & $add 'gh' $(if ($gh.State -eq 'ok') { 'OK' } else { 'WARN' }) $(switch ($gh.State) { 'ok' { $gh.Version.ToString() } 'missing' { "Fix: $(Get-SwDoctorHint gh)" } default { "$(Format-SwProbe $gh); Fix: $(Get-SwDoctorHint gh)" } })
    if ($gh.State -eq 'ok') {
        $auth = Get-SwGhAuth
        & $add 'gh auth' $(if ($auth -eq 0) { 'OK' } else { 'WARN' }) $(if ($auth -eq 0) { 'logged in' } else { 'Fix: gh auth login' })
    }

    $rtk = Get-SwToolProbe rtk
    & $add 'rtk' $(if ($rtk.State -eq 'ok') { 'OK' } else { 'WARN' }) $(switch ($rtk.State) { 'ok' { $rtk.Version.ToString() } 'missing' { "Fix: $(Get-SwDoctorHint rtk)" } default { "$(Format-SwProbe $rtk); Fix: $(Get-SwDoctorHint rtk)" } })
    if ($rtk.State -eq 'ok' -and $rtk.Version -lt [version]'0.48.0') { & $add 'rtk >= 0.48' 'WARN' "found $($rtk.Version)" }

    $config = Get-SwConfig $Root
    $users = @($config['users'])
    $listed = [bool]($User -and ($users -ccontains $User))
    if ($User) {
        & $add "user $User" $(if ($listed) { 'OK' } else { 'MISSING' }) $(if ($listed) { 'listed in .sw/config.json' } else { "Fix (project owner runs): pwsh .sw/sw.ps1 user $User" })
        $branch = "$User/$User-worktree"
        $branchExists = [bool](& git -C $Root branch --list $branch 2>$null) -or [bool](& git -C $Root branch -r --list "origin/$branch" 2>$null)
        & $add "branch $branch" $(if ($branchExists) { 'OK' } else { 'WARN' }) $(if ($branchExists) { 'exists' } else { "Fix: git switch -c $branch origin/main" })
    } else {
        & $add 'users' 'WARN' "Recorded: $(if ($users.Count) { $users -join ', ' } else { 'none' }); pass -User <name> to check yours"
    }

    # The checked-out branch, not mere existence: main only for a solo project, otherwise the recorded user's own branch.
    $current = [string](& git -C $Root branch --show-current 2>$null)
    $shown = if ($current) { $current } else { 'detached HEAD' }
    if (-not $users.Count) { $expected = 'main'; $onOwnBranch = $current -ceq 'main' }
    elseif ($listed) { $expected = "$User/$User-worktree"; $onOwnBranch = $current -ceq $expected }
    else { $expected = $null; $onOwnBranch = $false }
    & $add 'current branch' $(if ($onOwnBranch) { 'OK' } else { 'WARN' }) $(if ($onOwnBranch) { $current } elseif ($expected) { "$shown (expected $expected)" } else { "$shown (contributors are recorded; pass a listed -User <name> to check your worktree branch)" })

    $hasTiers = Test-Path -LiteralPath (Join-Path $Root '.opencode/opencode.jsonc')
    & $add 'tier map' $(if ($hasTiers) { 'OK' } else { 'WARN' }) $(if ($hasTiers) { '.opencode/opencode.jsonc' } else { 'Fix: pwsh .sw/sw.ps1 tiers -Light <id> -Standard <id> -High <id>' })

    $rows | Format-Table -AutoSize | Out-String -Width 200 | Write-Output
    Write-Output 'Reminder: OpenCode Desktop -> default environment = "Local directory" (automatic worktrees create branches outside the policy; cannot be detected).'
    Write-Output 'Startup budget (validate) counts kit files only. Harness prompt, tool schemas, user files, hooks and plugins are not counted; check `/context` (Claude) for the real total.'
    Write-Output 'Branch protection on main: not checked (needs `gh api`, which agents are denied); see .sw/collaboration.md (Protect main).'
    $global:LASTEXITCODE = if (@($rows | Where-Object State -in 'MISSING', 'FAILED').Count) { 1 } else { 0 }
}

# --- GitHub (read-only helpers; writes are human-run) -----------------------------------

function Invoke-SwGitHub {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Position = 0, Mandatory)][ValidateSet('status', 'labels')][string]$Action, [string]$Path)
    $Root = Resolve-SwRoot $Path
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'gh CLI not found.' }
    if ($Action -eq 'status') {
        Push-Location $Root
        try {
            Write-Output '== Open PRs'; & gh pr list --limit 10
            Write-Output '== Issues assigned to me'; & gh issue list --assignee '@me' --limit 10
            Write-Output '== Recent runs'; & gh run list --limit 5
        } finally { Pop-Location }
        return
    }
    # labels: a GitHub write; the human runs this, agents are denied `gh label create`.
    $labels = Read-SwJson (Join-Path $Root '.github/labels.json')
    Push-Location $Root
    try {
        foreach ($l in $labels) {
            if ($PSCmdlet.ShouldProcess($l['name'], 'gh label create --force')) {
                & gh label create $l['name'] --color $l['color'] --description $l['description'] --force
            }
        }
    } finally { Pop-Location }
}

# --- usage ------------------------------------------------------------------------------

function Get-SwUsage {
    [CmdletBinding()]
    param([string]$Path)
    $Root = Resolve-SwRoot $Path
    Write-Output '== RTK output savings (this project)'
    if (Get-Command rtk -ErrorAction SilentlyContinue) { Push-Location $Root; try { & rtk gain --project } finally { Pop-Location } } else { Write-Output 'rtk not installed.' }
    Write-Output '== OpenCode usage'
    $oc = Get-Command opencode, opencode-cli -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $oc -and $IsWindows) {
        $cand = Join-Path $env:LOCALAPPDATA 'Programs/@opencodedesktop/resources/opencode-cli.exe'
        if (Test-Path -LiteralPath $cand) { $oc = Get-Item $cand }
    }
    if ($oc) { & $(if ($oc -is [IO.FileInfo]) { $oc.FullName } else { $oc.Source }) stats } else { Write-Output 'OpenCode CLI not found.' }
    Write-Output '== Startup budget per role'
    Test-SwProject -Path $Root | Where-Object { $_ -like 'Startup budget:*' }
}

# --- context report (read-only) ---------------------------------------------------------

function Invoke-SwContextRead([string]$Root, [string]$Relative, [scriptblock]$Action) {
    # The context report's only file-system read path; never throws. Refuses a link or junction anywhere from
    # $Root down to the target before $Action touches it. Status: ok (Value = $Action result) | missing | unsafe |
    # failed (denied, unreadable, malformed or vanished). Checked, then read: not a transactional snapshot.
    $status = 'ok'; $value = $null
    try {
        $full = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
        if (-not (Test-SwContained $Root $full)) { $status = 'unsafe' }
        # Test-SwContained excludes the base itself, so the walk also stops on $Root's own attributes.
        $anchor = [IO.Path]::GetFullPath($Root).TrimEnd([char[]]@([char]92, [char]47))
        for ($c = $full; $status -ne 'unsafe' -and ((Test-SwContained $Root $c) -or $c -eq $anchor); $c = Split-Path $c -Parent) {
            try { if ([IO.File]::GetAttributes($c) -band [IO.FileAttributes]::ReparsePoint) { $status = 'unsafe' } }
            catch [IO.FileNotFoundException], [IO.DirectoryNotFoundException] { $status = 'missing' }
        }
        if ($status -eq 'ok') { $value = & $Action $full }
    } catch { $status = 'failed'; $value = $null }
    [pscustomobject]@{ Status = $status; Value = $value }
}

function Resolve-SwProjectPath([string]$Root, [string]$Relative, [string]$Label) {
    # Explicit caller paths: project-relative only; no rooted/UNC/drive/stream forms, '..' segments or links.
    if (-not $Relative -or [IO.Path]::IsPathRooted($Relative) -or $Relative -match '^[\\/]|:' -or @($Relative -split '[\\/]') -contains '..') { throw "Invalid ${Label}: '$Relative' must be a project-relative path" }
    $full = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    if (-not (Test-SwContained $Root $full)) { throw "Invalid ${Label}: '$Relative' escapes the project" }
    if ((Invoke-SwContextRead $Root $Relative {}).Status -eq 'unsafe') { throw "Invalid ${Label}: '$Relative' traverses a link or junction" }
    $full
}

function Get-SwContext {
    <#
    .SYNOPSIS Read-only project context report: static kit estimate, required-read sizes, available metadata
    and bounded task evidence references. Facts and pointers only; never an approval or acceptance verdict.
    #>
    [CmdletBinding()]
    param([string]$Task, [string]$StateFile, [string]$StateSection, [string]$Path)
    # Invalid arguments fail before any read.
    if ($Task) { Assert-SwSafeName $Task 'Task' }
    if ($StateSection -and -not $StateFile) { throw '-StateSection needs -StateFile (the state file named in AGENTS.md).' }
    if ($StateFile -and [IO.Path]::GetExtension($StateFile) -ine '.md') { throw "Invalid StateFile: '$StateFile' must be a Markdown file" }
    if ($StateFile -and -not $StateSection) { $StateSection = 'Startup' }
    if ($StateSection -and ($StateSection -match '[\r\n#]' -or $StateSection.Trim() -cne $StateSection)) { throw "Invalid StateSection: '$StateSection'" }
    # Git is optional evidence: a failed launch (missing or denied) makes it unavailable for the rest of the report,
    # never retried. core.fsmonitor=false keeps a configured fsmonitor hook from running; plain reads take no locks.
    $gitState = @{ Usable = $true }
    $git = { param([string]$Dir, [string[]]$GitArgs)
        if (-not $gitState.Usable) { return }
        try { $out = @(& git --no-optional-locks -c core.fsmonitor=false -C $Dir @GitArgs 2>$null); if ($LASTEXITCODE -eq 0) { , $out } } catch { $gitState.Usable = $false }
    }
    # Implicit discovery is best effort and context-local: no checkout or no usable Git means the current directory.
    $Root = if ($Path -or $env:SW_ROOT) { Resolve-SwRoot $Path } else {
        $here = (Get-Location).Path
        $top = & $git $here @('rev-parse', '--show-toplevel')
        (Resolve-Path -LiteralPath $(if ($top) { $top[0] } else { $here })).Path
    }
    # Every later read and Git call goes through the root: a linked root is refused before project inspection.
    if ([IO.File]::GetAttributes($Root) -band [IO.FileAttributes]::ReparsePoint) { throw "Invalid Path: project root '$Root' is a link or junction" }
    if ($StateFile) { $null = Resolve-SwProjectPath $Root $StateFile 'StateFile' }
    $taskRel = if ($Task) { ".sw/comms/tasks/$Task" } else { '.sw/comms/tasks' }
    if ($Task) { $null = Resolve-SwProjectPath $Root $taskRel 'Task' }

    $read = { param([string]$Rel, [scriptblock]$Action) Invoke-SwContextRead $Root $Rel $Action }
    $text = { param([string]$Rel) & $read $Rel { param($f) Read-SwText $f } }
    $list = { param([string]$Rel) & $read $Rel { param($f)
        if (-not [IO.Directory]::Exists($f)) { throw 'not a directory' }
        $e = @(Get-ChildItem -LiteralPath $f -Force); [Array]::Sort([string[]]@($e | ForEach-Object Name), $e, [StringComparer]::Ordinal); , $e } }
    $walk = { param([string]$Rel, [bool]$Recurse)
        # Lists a directory, entering each subdirectory only after it is checked; links are skipped, never followed.
        $top = & $list $Rel
        if ($top.Status -ne 'ok') { return [pscustomobject]@{ Status = $top.Status; Files = @(); Skipped = 0 } }
        $files = [Collections.Generic.List[string]]::new(); $skipped = 0
        $queue = [Collections.Generic.Queue[object]]::new(); $queue.Enqueue([pscustomobject]@{ Rel = $Rel; Items = $top.Value })
        while ($queue.Count) {
            $d = $queue.Dequeue()
            foreach ($i in $d.Items) {
                $r = "$($d.Rel)/$($i.Name)"
                if ($i.Attributes -band [IO.FileAttributes]::ReparsePoint) { $skipped++ }
                elseif (-not $i.PSIsContainer) { $files.Add($r) }
                elseif ($Recurse) { $sub = & $list $r; if ($sub.Status -eq 'ok') { $queue.Enqueue([pscustomobject]@{ Rel = $r; Items = $sub.Value }) } else { $skipped++ } }
            }
        }
        $sorted = $files.ToArray(); [Array]::Sort($sorted, [StringComparer]::Ordinal)
        [pscustomobject]@{ Status = $(if ($skipped) { 'incomplete' } else { 'ok' }); Files = $sorted; Skipped = $skipped }
    }
    $stamp = { param([string]$Rel) $s = & $read $Rel { param($f)
        $i = Get-Item -LiteralPath $f -Force
        if (-not $i.PSIsContainer) { "$($i.LastWriteTimeUtc.Ticks):$($i.Length)" }
        else { (@(Get-ChildItem -LiteralPath $f -Force | ForEach-Object { "$($_.Name):$($_.LastWriteTimeUtc.Ticks):$(if (-not $_.PSIsContainer) { $_.Length })" }) | Sort-Object -CaseSensitive) -join '/' } }
        "$($s.Status)|$($s.Value)" }
    $bytes = { param($Text) [Text.Encoding]::UTF8.GetByteCount($Text) }
    $ordinal = { param([string[]]$Items) $a = [string[]]@($Items); [Array]::Sort($a, [StringComparer]::Ordinal); $a }
    $stamped = @($taskRel) + @(if ($StateFile) { $StateFile })
    $before = @(foreach ($s in $stamped) { & $stamp $s })

    Write-Output 'Project context report: read-only static inspection; facts and source pointers only, not an approval or acceptance verdict.'
    Write-Output 'Measurement: UTF-8 bytes of LF-normalized text (BOM excluded); tokens are a ceil(bytes/4) estimate, not a tokenizer result or runtime bill.'
    Write-Output 'Status words: missing = absent; unsafe = link or junction, not followed; failed = denied, unreadable, malformed or vanished; incomplete = some entries not followed or unreadable. None is a measured zero.'

    Write-Output '== Core static kit estimate (same arithmetic and cap as sw validate)'
    try {
        $gaps = [Collections.Generic.List[string]]::new()
        $need = { param([string]$Rel, $Result) if ($Result.Status -ne 'ok') { $gaps.Add("$Rel $($Result.Status)") }; $Result.Value }
        $config = & $need '.sw/config.json' (& $read '.sw/config.json' { param($f) Read-SwJson $f })
        $roles = & $need '.sw/roles.json' (& $read '.sw/roles.json' { param($f) Read-SwJson $f })
        $agentsMd = & $need 'AGENTS.md' (& $text 'AGENTS.md')
        $agents = @{}; $skills = @{}
        $agentDir = & $walk '.opencode/agents' $false
        if ($agentDir.Status -ne 'ok') { $gaps.Add(".opencode/agents $($agentDir.Status)") }
        foreach ($f in $agentDir.Files | Where-Object { $_ -like '*.md' }) {
            $d = & $need $f (& $read $f { param($p) Read-SwFrontmatter $p 'description', 'mode', 'color', 'permissions' })
            if ($d) { $agents[[IO.Path]::GetFileNameWithoutExtension($f)] = $d }
        }
        $skillTree = & $walk '.agents/skills' $true
        if ($skillTree.Status -ne 'ok') { $gaps.Add(".agents/skills $($skillTree.Status)") }
        $skillFiles = @($skillTree.Files | Where-Object { ($_ -split '/')[-1] -eq 'SKILL.md' })
        foreach ($f in $skillFiles) { $d = & $need $f (& $read $f { param($p) Read-SwFrontmatter $p 'name', 'description' }); if ($d) { $skills[$d['name']] = $d } }
        $roleNames = @(if ($roles) { & $ordinal @($roles.Keys | Where-Object { $_ -ne 'explore' }) })
        # Expected-role coverage: a role without its definition would silently drop out of the shared arithmetic.
        foreach ($r in $roleNames) { if (-not $agents.ContainsKey($r) -and $agentDir.Files -notcontains ".opencode/agents/$r.md") { $gaps.Add(".opencode/agents/$r.md missing") } }
        if ($gaps.Count) { Write-Output "core: incomplete ($($gaps -join '; ')); per-role totals withheld; sw validate reports definition errors" }
        else {
            foreach ($b in Get-SwStartupBudget $config $agentsMd $agents $skills $roleNames) {
                Write-Output "$($b.Role): agents_md=$($b.AgentsMd) role_body=$($b.Body) skill_metadata=$($b.Skills) catalogue=$($b.Catalogue) total=$($b.Total) est_tokens=$($b.Tokens) cap=$($b.Cap) within_cap=$(if ($b.Total -le $b.Cap) { 'yes' } else { 'no' })"
            }
        }
    } catch { Write-Output 'core: incomplete (estimate failed); per-role totals withheld; sw validate reports definition errors' }

    Write-Output '== Additional required reads (listed sources only; no cap applies)'
    if (-not $StateFile) { Write-Output 'state: unavailable (state source not specified; pass -StateFile named by AGENTS.md)' }
    else {
        $show = $StateFile.Replace('\', '/'); $s = & $text $StateFile
        if ($s.Status -ne 'ok') { Write-Output "state: unavailable ($($s.Status): $show)" }
        else {
            $match = [regex]::Match($s.Value, '(?ms)^## ' + [regex]::Escape($StateSection) + '[ \t]*\n(.*?)(?=^## |\z)')
            if ($match.Success) { Write-Output "state: $show section `"$StateSection`" bytes=$(& $bytes $match.Groups[1].Value) (section body only; the rest of the file is not counted)" }
            else { Write-Output "state: unavailable (section `"$StateSection`" not found in $show)" }
        }
    }
    foreach ($p in '.sw/workspace.md', '.sw/collaboration.md') {
        $r = & $text $p
        Write-Output $(if ($r.Status -eq 'ok') { "policy: $p bytes=$(& $bytes $r.Value)" } else { "policy: $p unavailable ($($r.Status))" })
    }

    Write-Output '== Available, not necessarily loaded (metadata only; bodies not printed)'
    try {
        if ($skillTree.Status -notin 'ok', 'incomplete') { Write-Output "skills: unavailable ($($skillTree.Status): .agents/skills)" }
        else {
            if ($skillTree.Skipped) { Write-Output "skills: incomplete ($($skillTree.Skipped) entries not followed or unreadable)" }
            foreach ($f in $skillFiles) { $r = & $text $f; Write-Output "skill: $(($f -split '/')[-2]) $(if ($r.Status -eq 'ok') { "bytes=$(& $bytes $r.Value)" } else { "unavailable ($($r.Status))" })" }
        }
        foreach ($k in @(@('commands', '.opencode/commands', '*.md', $false), @('plugins', '.opencode/plugins', '*', $true))) {
            $w = & $walk $k[1] $k[3]
            if ($w.Status -notin 'ok', 'incomplete') { Write-Output "$($k[0]): unavailable ($($w.Status): $($k[1]))"; continue }
            $sizes = @(foreach ($f in $w.Files | Where-Object { ($_ -split '/')[-1] -like $k[2] }) { & $text $f })
            $gap = $w.Skipped + @($sizes | Where-Object Status -ne 'ok').Count
            Write-Output "$($k[0]): count=$($sizes.Count) bytes=$(($sizes | Where-Object Status -eq 'ok' | ForEach-Object { & $bytes $_.Value } | Measure-Object -Sum).Sum + 0)$(if ($gap) { " incomplete ($gap entries not followed or unreadable)" })"
        }
    } catch { Write-Output 'inventory: incomplete (listing failed)' }

    Write-Output '== Runtime, harness and global context: NOT OBSERVED by this command'
    Write-Output 'Not read or measured: tool schemas, merged global/user instructions, native memory, actual skill loads, cache/compaction, actual model-visible input.'

    Write-Output '== Source and evidence inventory (opaque references; no approval, acceptance or active task inferred)'
    $dotGit = & $read '.git' {}
    if ($dotGit.Status -ne 'ok') { Write-Output "checkout: unavailable ($($dotGit.Status): .git)" }
    elseif (-not $gitState.Usable) { Write-Output 'checkout: unavailable (git could not be run; not retried)' }
    else {
        $branch = & $git $Root @('branch', '--show-current'); $head = & $git $Root @('rev-parse', '--verify', '--quiet', 'HEAD'); $dirty = & $git $Root @('status', '--porcelain=v1')
        Write-Output "checkout: branch=$(if ($branch) { $branch[0] } else { 'unavailable' }) head=$(if ($head) { $head[0] } else { 'unavailable' }) dirty_entries=$(if ($null -ne $dirty) { @($dirty | Where-Object { $_ }).Count } else { 'unavailable' })$(if (-not $gitState.Usable) { ' (git could not be run; not retried)' })"
    }
    try {
        $t = & $list $taskRel
        if (-not $Task) {
            if ($t.Status -ne 'ok') { Write-Output "tasks: unavailable ($($t.Status): $taskRel)" }
            else {
                $dirs = @($t.Value | Where-Object PSIsContainer)
                Write-Output "tasks: candidates=$($dirs.Count) listed=$([math]::Min($dirs.Count, 20)) omitted=$([math]::Max($dirs.Count - 20, 0)) (candidates only; pass -Task <id> to inspect one)"
                foreach ($d in $dirs | Select-Object -First 20) {
                    if ($d.Attributes -band [IO.FileAttributes]::ReparsePoint) { Write-Output "candidate: $($d.Name) (link; not inspected)"; continue }
                    $e = & $list "$taskRel/$($d.Name)"
                    Write-Output "candidate: $($d.Name) events=$(if ($e.Status -eq 'ok') { @($e.Value | Where-Object { -not $_.PSIsContainer -and $_.Extension -eq '.md' }).Count } else { "unavailable ($($e.Status))" })"
                }
            }
        } elseif ($t.Status -ne 'ok') { Write-Output "task: $Task unavailable ($($t.Status): $taskRel)" }
        else {
            $all = @($t.Value)
            $events = @($all | Where-Object { -not $_.PSIsContainer -and $_.Extension -eq '.md' })
            $shown = @($events | Select-Object -Last 20)
            Write-Output "task: $Task events=$($events.Count) listed=$($shown.Count) omitted=$($events.Count - $shown.Count) other_entries=$($all.Count - $events.Count) (name order; not a status or approval ranking)"
            foreach ($e in $shown) { Write-Output "event: $taskRel/$($e.Name)" }
        }
        if ($Task) {
            $summaryRel = ".sw/comms/archive/$Task/SUMMARY.md"; $s = & $text $summaryRel
            Write-Output $(switch ($s.Status) { ok { "archive: $summaryRel bytes=$(& $bytes $s.Value) (summary only; archived events not listed)" } missing { 'archive: none' } default { "archive: unavailable ($($s.Status): $summaryRel)" } })
        }
    } catch { Write-Output 'task: incomplete (evidence could not be listed)' }
    $after = @(foreach ($s in $stamped) { & $stamp $s })
    if (($before -join "`n") -cne ($after -join "`n") -or @($before + $after | Where-Object { $_ -like 'failed|*' }).Count) {
        Write-Output 'notice: evidence changed during inspection or could not be re-checked; this report is incomplete. Re-run before relying on it.'
    }
    $global:LASTEXITCODE = 0
}

Export-ModuleMember -Function Resolve-SwRoot, Write-SwFile, Read-SwText, Read-SwJson, ConvertTo-SwJson, Get-SwHash,
    Get-SwConfig, Read-SwFrontmatter, Get-SwDecision, Test-SwPattern, Get-SwGhRules, Get-SwSessionRules, Add-SwRtkTwins, Get-SwClaudeGhDeny, Test-SwProject,
    Get-SwClaudeModel, Get-SwClaudeGitRules, Get-SwClaudeFiles, Invoke-SwClaude, Set-SwTiers, Invoke-SwSession, Invoke-SwComms, Add-SwUser, Invoke-SwGitHub, Get-SwUsage, Test-SwLocalOnly,
    Get-SwToolVersion, Get-SwToolProbe, Get-SwGhAuth, Format-SwProbe, Test-SwDoctor,
    Get-SwOperationId, Test-SwContained, New-SwSnapshotDir, Copy-SwNew, Write-SwNewFile, Get-SwByteHash, Read-SwClaudeOwnership, Test-SwFileMatches,
    Get-SwStartupBudget, Get-SwContext, Resolve-SwSelection, Get-SwSelectionCommands, Get-SwSelectionKnown, Test-SwLinkedPath
