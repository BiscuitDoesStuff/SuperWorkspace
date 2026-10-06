# SuperWorkspace kit module: install/update projects, user-global setup, remote access.
# Kit-only (not copied into projects). PowerShell 7.2+.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Sw.Project.psm1') -DisableNameChecking
$script:Kit = Split-Path $PSScriptRoot -Parent
# Never copied into a backup, whatever list asks for them.
$script:SecretName = '(?i)(^service\.json$|^\.claude\.json$|^auth.*|credential|\.env($|\.)|\.pem$|\.key$|token|secret)'

function Get-SwKitVersion { (Get-Content -LiteralPath (Join-Path $script:Kit 'VERSION')).Trim() }

function Get-SwKitCommit {
    # The exact kit used, or $null when the kit is not a git clone. A kit copied into
    # another repository sits under a different prefix there; that HEAD is not the kit's.
    # The active kit now lives at the repository root, not the retired product/ prefix.
    $prefix = & git -C $script:Kit rev-parse --show-prefix 2>$null
    if ($LASTEXITCODE -ne 0 -or "$prefix".Trim() -ne '') { return $null }
    $sha = & git -C $script:Kit rev-parse HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $sha) { "$sha".Trim() } else { $null }
}

function Compare-SwVersion([string]$A, [string]$B) {
    # -1, 0 or 1 for X.Y.Z[-tag]; a tagged build (0.3.0-dev) is older than the release (0.3.0).
    $pa, $pb = foreach ($v in $A, $B) {
        if ($v -notmatch '^(\d+)\.(\d+)\.(\d+)(?:-(.+))?$') { throw "Not a kit version (X.Y.Z or X.Y.Z-tag): '$v'" }
        , @([int]$Matches[1], [int]$Matches[2], [int]$Matches[3], $Matches[4])
    }
    for ($i = 0; $i -lt 3; $i++) { if ($pa[$i] -ne $pb[$i]) { return $(if ($pa[$i] -lt $pb[$i]) { -1 } else { 1 }) } }
    if ($pa[3] -ceq $pb[3]) { return 0 }
    if (-not $pa[3]) { return 1 }
    if (-not $pb[3]) { return -1 }
    [Math]::Sign([string]::CompareOrdinal($pa[3], $pb[3]))
}

# Kit-side renames (old path -> new path). An edited old file moves with its edit.
# A key ending in '/' is a prefix rule, expanded per-file against the old manifest (Sync-SwProject).
$script:Moved = [ordered]@{ '.opencode/skills/' = '.agents/skills/' }

function Assert-SwBlockWellFormed([string]$Text, [string]$Name, [string]$Begin, [string]$End) {
    # Absent is fine; present must be exactly one begin followed by exactly one end.
    $b = $Text.IndexOf($Begin); $e = $Text.IndexOf($End)
    if ($b -lt 0 -and $e -lt 0) { return }
    if ($b -lt 0) { throw "Malformed managed block '$Name': '$End' without '$Begin'" }
    if ($e -lt 0) { throw "Unterminated managed block '$Name' (found '$Begin' without '$End')" }
    if ($e -lt $b) { throw "Malformed managed block '$Name': '$End' before '$Begin'" }
    if ($Text.LastIndexOf($Begin) -ne $b -or $Text.LastIndexOf($End) -ne $e) { throw "Malformed managed block '$Name': repeated markers" }
}

function Set-SwBlock([string]$Text, [string]$Name, [string]$Body, [ValidateSet('md', 'hash')][string]$Style = 'md') {
    # Insert or replace one named managed block; everything outside it is left alone.
    $b, $e = if ($Style -eq 'md') { "<!-- sw:begin $Name -->", "<!-- sw:end $Name -->" } else { "# sw:begin $Name", "# sw:end $Name" }
    $block = "$b`n$($Body.Trim("`n"))`n$e"
    Assert-SwBlockWellFormed $Text $Name $b $e
    $start = $Text.IndexOf($b)
    if ($start -ge 0) {
        $end = $Text.IndexOf($e, $start)
        if ($end -lt 0) { throw "Unterminated managed block '$Name' (found '$b' without '$e')" }
        return $Text.Substring(0, $start) + $block + $Text.Substring($end + $e.Length)
    }
    $sep = if (-not $Text) { '' } elseif ($Text.EndsWith("`n`n")) { '' } elseif ($Text.EndsWith("`n")) { "`n" } else { "`n`n" }
    $Text + $sep + $block + "`n"
}

function Get-SwBlockBody([string]$Text, [string]$Name) {
    $b = "<!-- sw:begin $Name -->"; $e = "<!-- sw:end $Name -->"
    $s = $Text.IndexOf($b); $t = $Text.IndexOf($e)
    if ($s -lt 0 -or $t -lt $s) { throw "Template lacks block $Name" }
    $Text.Substring($s + $b.Length, $t - $s - $b.Length).Trim("`n")
}

function Add-SwSessionRules([string]$Text, $Rules, [string]$Label) {
    # Rewrite the frontmatter `permissions:` list as $Rules, then the agent's own rules, with RTK
    # twins (Add-SwRtkTwins). The list is created before the closing `---` if absent.
    $q = { param($v) if ($v -match '["\\]') { throw "${Label}: cannot quote rule value $v" }; if ($v -cmatch '^[a-z_]+$') { $v } else { "`"$v`"" } }
    if ($Text -notmatch '\A---\n') { throw "${Label}: missing frontmatter" }
    $close = $Text.IndexOf("`n---`n", 3)
    if ($close -lt 0) { throw "${Label}: missing closing frontmatter delimiter" }
    $head = $Text.Substring(0, $close + 1)
    $m = [regex]::Match($head, '(?m)^permissions:\n((?:  .*\n)*)')
    $own = @(if ($m.Success) {
        $found = [regex]::Matches($m.Groups[1].Value, '(?m)^  - action: "?([^"\n]+)"?\n    resource: "([^"\n]*)"\n    effect: ([a-z]+)\n')
        $covered = 0; foreach ($f in $found) { $covered += $f.Length }
        if ($covered -ne $m.Groups[1].Length) { throw "${Label}: permissions must use the kit's action/resource/effect line form" }
        foreach ($f in $found) { [ordered]@{ action = $f.Groups[1].Value; resource = $f.Groups[2].Value; effect = $f.Groups[3].Value } }
    })
    $lines = foreach ($r in Add-SwRtkTwins (@($Rules) + $own)) { "  - action: $(& $q $r['action'])"; "    resource: `"$($r['resource'])`""; "    effect: $($r['effect'])" }
    $block = "permissions:`n$($lines -join "`n")`n"
    if ($m.Success) { return $Text.Remove($m.Index, $m.Length).Insert($m.Index, $block) }
    $Text.Insert($close + 1, $block)
}

function Get-SwRender([Collections.IDictionary]$Config) {
    # Everything the kit owns in a project, rendered from $Config. Pure: writes nothing.
    # The profile names a source directory: only a canonical ID may reach a path.
    if ("$($Config['profile'])" -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { throw "Profile '$($Config['profile'])' is not a canonical identifier (lowercase letters, digits, single hyphens)" }
    $profileDir = Join-Path $script:Kit "project/profiles/$($Config['profile'])"
    if (-not (Test-Path -LiteralPath $profileDir)) { throw "Unknown profile '$($Config['profile'])'. Available: $((Get-ChildItem (Join-Path $script:Kit 'project/profiles') -Directory).Name -join ', ')" }
    $profileData = Read-SwJson (Join-Path $profileDir 'profile.json')
    $files = [ordered]@{}
    $add = {
        param($dir)
        if (-not (Test-Path -LiteralPath $dir)) { return }
        foreach ($f in Get-ChildItem -LiteralPath $dir -Recurse -File -Force | Sort-Object FullName) {
            $rel = [IO.Path]::GetRelativePath($dir, $f.FullName).Replace('\', '/')
            if ($rel -eq 'AGENTS.md') { continue }
            $files[$rel] = (Read-SwText $f.FullName).Replace('{{PROJECT}}', $Config['project'])
        }
    }
    & $add (Join-Path $script:Kit 'project/base')
    & $add (Join-Path $profileDir 'files')
    if ($Config['github'] -ne $false) { & $add (Join-Path $script:Kit 'project/github') }
    # `records: local` (opt-in) keeps .sw/comms/ out of Git; absent or `tracked` is the default.
    $local = $Config.Contains('records') -and $Config['records'] -ceq 'local'
    if ($Config.Contains('records') -and $Config['records'] -cnotin 'tracked', 'local') { throw "Config 'records' must be 'tracked' or 'local', not '$($Config['records'])'" }
    if ($local) {
        $collab = $files['.sw/collaboration.md']
        $published = "Git is the transport: everything below is plain files in`n``.sw/comms/``, published when a human pushes their branch."
        if (-not $collab.Contains($published)) { throw 'project/base/.sw/collaboration.md lost the records sentence that records: local replaces' }
        $files['.sw/collaboration.md'] = $collab.Replace($published, "Everything below is plain files in`n``.sw/comms/``, kept local by ``records: local`` (git-ignored, never pushed).")
    }
    $files['.sw/roles.json'] = Read-SwText (Join-Path $script:Kit 'project/roles.json')
    $files['.sw/profile.json'] = Read-SwText (Join-Path $profileDir 'profile.json')
    $files['.sw/sw.ps1'] = Read-SwText (Join-Path $script:Kit 'sw.ps1')
    $files['.sw/lib/Sw.Project.psm1'] = Read-SwText (Join-Path $script:Kit 'lib/Sw.Project.psm1')
    $files['.sw/lib/Sw.Manager.psm1'] = Read-SwText (Join-Path $script:Kit 'lib/Sw.Manager.psm1')
    $roles = Read-SwJson (Join-Path $script:Kit 'project/roles.json')
    $agentsProfile = Read-SwText (Join-Path $profileDir 'AGENTS.section.md')

    # Selection v1 (config opt-in) filters the in-memory render; legacy keeps every base file and ignores composition.
    $selection = $null; $known = $null; $commands = $null
    if ($Config.Contains('selection')) {
        $catalogue = Read-SwJson (Join-Path $script:Kit 'project/selection.json')
        $selection = Resolve-SwSelection $Config['selection'] ([string]$Config['profile']) $profileData $catalogue @($roles.Keys)
        $known = Get-SwSelectionKnown $catalogue $profileData
        # Every component the catalogue or profile names must exist in the kit, selected or not.
        $missing = @(foreach ($r in $known.roles) { if ($roles[$r]['access'] -ne 'builtin' -and -not $files.Contains(".opencode/agents/$r.md")) { ".opencode/agents/$r.md" } }) +
            @(foreach ($s in $known.skills) { if (-not $files.Contains(".agents/skills/$s/SKILL.md")) { ".agents/skills/$s/SKILL.md" } }) +
            @(foreach ($c in $selection.capabilities) { if ($catalogue['capabilities'][$c]['context'].Count -and -not (Test-Path -LiteralPath (Join-Path $script:Kit "project/capabilities/$c/AGENTS.section.md") -PathType Leaf)) { "project/capabilities/$c/AGENTS.section.md" } })
        if ($missing.Count) { throw "Selection source definitions missing; nothing was written: $($missing -join ', ')" }
        $commands = Get-SwSelectionCommands $selection.roles
        $dropRoles = @($known.roles | Where-Object { $_ -cnotin $selection.roles })
        foreach ($rel in @($files.Keys)) {
            $drop = ($rel -match '^\.opencode/agents/([^/]+)\.md$' -and $Matches[1] -cin $dropRoles) -or
                ($rel -match '^\.agents/skills/([^/]+)/' -and $Matches[1] -cin $known.skills -and $Matches[1] -cnotin $selection.skills) -or
                ($rel -match '^\.opencode/commands/([^/]+)\.md$' -and $Matches[1] -cin $known.commands -and $Matches[1] -cnotin $commands)
            if ($drop) { $files.Remove($rel) }
        }
        foreach ($rel in '.opencode/agents/project-leader.md', '.sw/workspace.md') { $files[$rel] = Remove-SwRoleLines $files[$rel] $dropRoles }
        $selected = [ordered]@{}
        foreach ($r in $roles.Keys) { if ($r -cin $selection.roles) { $selected[$r] = $roles[$r] } }
        $roles = $selected
        $files['.sw/roles.json'] = ConvertTo-SwJson $roles
        $installed = [ordered]@{}
        foreach ($k in $profileData.Keys) { $installed[$k] = $profileData[$k] }
        $installed['effectiveSelection'] = $selection
        $files['.sw/profile.json'] = ConvertTo-SwJson $installed
        $files['.sw/selection.json'] = Read-SwText (Join-Path $script:Kit 'project/selection.json')
        foreach ($c in $selection.capabilities) {
            $section = Join-Path $script:Kit "project/capabilities/$c/AGENTS.section.md"
            if (Test-Path -LiteralPath $section -PathType Leaf) { $agentsProfile = $agentsProfile.TrimEnd("`n") + "`n`n" + (Read-SwText $section) }
        }
    }

    # Session rules lead every agent's own list.
    # ponytail: deliberate duplication. OpenCode v2 does append agent rules after the top-level list
    # (opencode.ai/v2/docs/permissions, /agents; `opencode debug agents` on 2.0.18, docs/decisions.md 2026-09-27),
    # so the per-agent copy is redundant at runtime. It stays as accepted defence in depth, and because the
    # static matrix, drift check and `sw context` policy model each agent file alone. Upgrade trigger: an owner
    # decision to drop it, with validate/context composing opencode.jsonc + agent rules and a live runtime check.
    $session = @(Get-SwSessionRules $profileData['editDeny'] ([int]$Config['githubTier']))
    foreach ($rel in @($files.Keys | Where-Object { $_ -match '^\.opencode/agents/[^/]+\.md$' })) { $files[$rel] = Add-SwSessionRules $files[$rel] $session $rel }

    # opencode.jsonc: session rules (applied first to every agent in v2) + build delegation allowlist.
    $oc = Read-SwJson (Join-Path $script:Kit 'project/opencode.base.json')
    $twinned = @(Add-SwRtkTwins $session)
    $oc['permissions'] = $twinned
    $build = [Collections.Generic.List[object]]@($twinned)
    $build.Add([ordered]@{ action = 'subagent'; resource = '*'; effect = 'deny' })
    foreach ($r in @($roles.Keys | Where-Object { $_ -notin 'project-leader', 'explore' }) + 'general', 'explore') { $build.Add([ordered]@{ action = 'subagent'; resource = $r; effect = 'allow' }) }
    $oc['agents'] = [ordered]@{ build = [ordered]@{ permissions = @($build) } }
    # OpenCode's watcher ignores only its built-in list plus watcher.ignore (not .gitignore); projects may append theirs.
    $watch = @(@($profileData['watcherIgnore']) + @($Config['watcherIgnore']) | Where-Object { $_ } | Select-Object -Unique)
    if ($watch.Count) { $oc['watcher'] = [ordered]@{ ignore = $watch } }
    $files['opencode.jsonc'] = ConvertTo-SwJson $oc

    $template = Read-SwText (Join-Path $script:Kit 'project/base/AGENTS.md')
    $ignore = @('.opencode/opencode.json', '.opencode/opencode.jsonc', '.claude/', '.sw/backup/', '.env', '.env.*', '!.env.example') + $(if ($local) { '.sw/comms/' } else { @() }) -join "`n"
    $attrs = (@($profileData['lfs']) | ForEach-Object { "$_ filter=lfs diff=lfs merge=lfs -text" }) -join "`n"
    [ordered]@{
        Files          = $files
        AgentsTemplate = $template.Replace('{{PROJECT}}', $Config['project'])
        AgentsCore     = Get-SwBlockBody $template 'core'
        AgentsProfile  = $agentsProfile
        GitIgnore      = $ignore
        GitAttributes  = $attrs
        Selection      = $selection
        Known          = $known
        Commands       = $commands
    }
}

function Remove-SwRoleLines([string]$Text, [string[]]$Roles) {
    # Drops a deselected role's routing bullet (with its indented continuation) or Roles-table row.
    if (-not @($Roles).Count) { return $Text }
    $alt = (@($Roles) | ForEach-Object { [regex]::Escape($_) }) -join '|'
    $bullet = $false
    $kept = foreach ($line in $Text -split "`n") {
        if ($bullet -and $line -match '^  \S') { continue }
        $bullet = $line -cmatch "^- ($alt):"
        if ($bullet -or $line -cmatch "^\| ($alt)[ |]") { continue }
        $line
    }
    $kept -join "`n"
}

function Format-SwSelection($Render) {
    $s = $Render.Selection
    if (-not $s) { return 'selection: legacy (no selection field; every base role, skill and command kept; composition ignored)' }
    $list = { param($v) "[$(@($v) -join ', ')]" }
    "selection: v1 profile=$($s.profile) capabilities=$(& $list $s.capabilities) roles=$(& $list $s.roles) skills=$(& $list $s.skills) commands=$(& $list $Render.Commands) context=$(& $list $s.context) checks=$(& $list $s.checks)"
}

function Set-SwSelectionOption([Collections.IDictionary]$Config, [bool]$SelectionV1, $Bound) {
    # Opt-in is explicit: an existing config without `selection` stays legacy unless -SelectionV1 is passed.
    if ($SelectionV1 -and -not $Config.Contains('selection')) { $Config['selection'] = [ordered]@{ version = 1; capabilities = @() } }
    if (-not $Bound.ContainsKey('Capabilities')) { return }
    if (-not $Config.Contains('selection')) { throw '-Capabilities needs selection v1; pass -SelectionV1 to opt this project in. Nothing was written.' }
    if ($Config['selection'] -isnot [Collections.IDictionary]) { throw 'Malformed config selection; nothing was written.' }
    # Present-but-empty (-Capabilities '') clears additional capabilities; comma lists come from the CLI as one string.
    $Config['selection']['capabilities'] = @(@($Bound['Capabilities']) | ForEach-Object { "$_" -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Get-SwClaudeCandidate($Render, [Collections.IDictionary]$Config, [string]$MapPath) {
    # The adapter the enabled generator would emit after this sync: the same generator (classifier, STOP and tool
    # rules) fed in memory with the rendered, not yet written inputs and the parsed local map. Nothing is written.
    $files = [ordered]@{}
    foreach ($e in $Render.Files.GetEnumerator()) { if ($e.Key -match '^(\.opencode/(agents|commands)/|\.agents/skills/)') { $files[$e.Key] = $e.Value } }
    Get-SwClaudeFiles '' ([pscustomobject]@{
        Config  = $Config
        Roles   = $Render.Files['.sw/roles.json'] | ConvertFrom-Json -AsHashtable
        Profile = $Render.Files['.sw/profile.json'] | ConvertFrom-Json -AsHashtable
        Map     = $(if (Test-Path -LiteralPath $MapPath -PathType Leaf) { Read-SwJson $MapPath } else { $null })
        Files   = $files
    })
}

function Assert-SwSelectionTransition([string]$Root, $Render, [Collections.IDictionary]$Config) {
    # Preflight before any write or git init: a deselected kit component that is edited, unowned, unverified or
    # linked blocks the whole run (paths are project-relative). -Force/-Adopt never reach this. Not a rollback engine.
    if (-not $Render.Selection) { return }
    $sel = $Render.Selection; $known = $Render.Known
    $drop = [ordered]@{
        roles    = @($known.roles | Where-Object { $_ -cnotin $sel.roles })
        skills   = @($known.skills | Where-Object { $_ -cnotin $sel.skills })
        commands = @($known.commands | Where-Object { $_ -cnotin $Render.Commands })
    }
    $blocked = [Collections.Generic.List[string]]::new()
    $paths = {
        param([string]$Base, $Ids = $drop)
        foreach ($r in $Ids.roles) { "$Base/agents/$r.md" }
        foreach ($c in $Ids.commands) { "$Base/commands/$c.md" }
    }
    $skillFiles = {
        param([string]$Dir, $Owned, $Ids = $drop)
        foreach ($s in $Ids.skills) {
            $rel = "$Dir/$s"
            if (Test-SwLinkedPath $Root $rel) { $blocked.Add("$rel (linked)"); continue }
            $full = Join-Path $Root $rel
            $onDisk = @(if (Test-Path -LiteralPath $full -PathType Container) { Get-ChildItem -LiteralPath $full -Recurse -Force | ForEach-Object { "$rel/$([IO.Path]::GetRelativePath($full, $_.FullName).Replace('\', '/'))" } })
            @($onDisk) + @($Owned.Keys | Where-Object { $_.StartsWith("$rel/", [StringComparison]::Ordinal) }) | Sort-Object -Unique
        }
    }
    $check = {
        param([string]$Rel, $Owned, [bool]$Bytes)
        $full = Join-Path $Root $Rel
        if (Test-SwLinkedPath $Root $Rel) { $blocked.Add("$Rel (linked)"); return }
        if (Test-Path -LiteralPath $full -PathType Container) { return }
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { return }
        if (-not $Owned.Contains($Rel)) { $blocked.Add("$Rel (unowned or unverified)"); return }
        $hash = if ($Bytes) { Get-SwByteHash ([IO.File]::ReadAllBytes($full)) } else { Get-SwHash (Read-SwText $full) }
        if ($hash -cne $Owned[$Rel]) { $blocked.Add("$Rel (modified)") }
    }
    $manifestPath = Join-Path $Root '.sw/manifest.json'
    $owned = if (Test-Path -LiteralPath $manifestPath -PathType Leaf) { (Read-SwJson $manifestPath)['files'] } else { $null }
    if ($owned -isnot [Collections.IDictionary]) { $owned = @{} }
    # Includes the supported pre-move `.opencode/skills/` layout: a deselected copy there is never left active.
    foreach ($rel in @(& $paths '.opencode') + @(& $skillFiles '.agents/skills' $owned) + @(& $skillFiles '.opencode/skills' $owned)) { & $check $rel $owned $false }

    # A deselected role in the local overlay is the owner's map to edit; the kit never rewrites it.
    $mapRel = '.opencode/opencode.jsonc'
    $map = $null
    if (Test-Path -LiteralPath (Join-Path $Root $mapRel) -PathType Leaf) {
        try { $map = Read-SwJson (Join-Path $Root $mapRel) } catch { $blocked.Add("$mapRel (unreadable local map)") }
        if ($map -is [Collections.IDictionary] -and $map['agents'] -is [Collections.IDictionary]) {
            foreach ($r in @($map['agents'].Keys | Where-Object { $_ -cin $drop.roles })) { $blocked.Add("$mapRel agents.$r (deselected role in the local map)") }
        }
    }
    # Enabled Claude adapter: the candidate adapter must generate, and every file it would no longer emit must be
    # provably generated and unedited (deselected, or a selected role that became unmapped/non-Claude).
    if (Test-Path -LiteralPath (Join-Path $Root '.claude/.sw-generated')) {
        $own = Read-SwClaudeOwnership $Root
        if ($own.State -eq 'invalid') { $blocked.Add(".claude/.sw-generated (invalid ownership: $($own.Reason))") }
        $entries = if ($own.State -eq 'ok') { $own.Entries } else { @{} }
        $candidate = $null
        try { $candidate = Get-SwClaudeCandidate $Render $Config (Join-Path $Root $mapRel) }
        catch { $blocked.Add("$mapRel (Claude adapter candidate cannot be generated: $($_.Exception.Message))") }
        $stale = if (-not $candidate) { @(& $paths '.claude') + @(& $skillFiles '.claude/skills' $entries) }
        elseif ($own.State -eq 'ok') { @($entries.Keys | Where-Object { -not $candidate.Contains($_) }) }
        else { @(& $paths '.claude' $known) + @(& $skillFiles '.claude/skills' $entries $known) | Where-Object { -not $candidate.Contains($_) } }
        foreach ($rel in $stale) { & $check $rel $entries $true }
    }
    if ($blocked.Count) {
        throw "Selection change blocked; nothing was written. Resolve these deselected components yourself (separately authorized), then re-run; -Force and -Adopt cannot bypass this:`n  $(($blocked | Select-Object -Unique) -join "`n  ")"
    }
}

function Get-SwManagedContent([string]$Root, $Render) {
    # Pure and validation-first: every managed-block replacement for files the project also owns, or a throw.
    # Nothing is written, so a malformed block or an unsafe LFS transition stops the operation before any change.
    $agentsPath = Join-Path $Root 'AGENTS.md'
    $agents = if (Test-Path -LiteralPath $agentsPath) { Set-SwBlock (Read-SwText $agentsPath) 'core' $Render.AgentsCore } else { $Render.AgentsTemplate }
    $agents = Set-SwBlock $agents 'profile' $Render.AgentsProfile
    $agentsNote = $null
    if ($agents -cnotmatch '(?m)^## Project identity\s*$') {
        # An adopted AGENTS.md lacks the project sections: insert the template's above the core block.
        $t = $Render.AgentsTemplate
        $from = $t.IndexOf("`n") + 1
        $sections = $t.Substring($from, $t.IndexOf('<!-- sw:begin core -->') - $from).Trim("`n") + "`n`n"
        $at = $agents.IndexOf('<!-- sw:begin core -->')
        $agents = $agents.Substring(0, $at) + $sections + $agents.Substring($at)
        $agentsNote = 'fill Project identity (and the other inserted project sections) in AGENTS.md'
    }
    $blocks = [ordered]@{ 'AGENTS.md' = $agents }
    $gi = Join-Path $Root '.gitignore'
    $blocks['.gitignore'] = Set-SwBlock $(if (Test-Path -LiteralPath $gi) { Read-SwText $gi } else { '' }) 'superworkspace' $Render.GitIgnore 'hash'
    # .gitattributes is inspected even when the profile has no LFS rules, so a retained or malformed managed block is seen.
    $ga = Join-Path $Root '.gitattributes'
    $gaText = if (Test-Path -LiteralPath $ga) { Read-SwText $ga } else { '' }
    $gaBegin = '# sw:begin superworkspace'; $gaEnd = '# sw:end superworkspace'
    Assert-SwBlockWellFormed $gaText 'superworkspace' $gaBegin $gaEnd
    $gaStart = $gaText.IndexOf($gaBegin)
    if ($gaStart -ge 0) {
        $old = $gaText.Substring($gaStart + $gaBegin.Length, $gaText.IndexOf($gaEnd) - $gaStart - $gaBegin.Length) -split "`n"
        $new = @($Render.GitAttributes -split "`n")
        $dropped = @($old | Where-Object { $_ -match 'filter=lfs' -and $_ -cnotin $new })
        if ($dropped.Count) {
            throw "Refusing to drop $($dropped.Count) managed LFS rule(s) from .gitattributes (for example '$($dropped[0].Trim())'): a profile change must not silently stop LFS tracking. Nothing was written; -Force and -Adopt cannot bypass this. Keeping or migrating LFS content needs a separate owner decision."
        }
    }
    if ($Render.GitAttributes) { $blocks['.gitattributes'] = Set-SwBlock $gaText 'superworkspace' $Render.GitAttributes 'hash' }
    [ordered]@{ Blocks = $blocks; AgentsNote = $agentsNote }
}

function Sync-SwProject {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Root, [Collections.IDictionary]$Config, [switch]$Adopt,
        # Allow running an older kit over a project a newer kit last updated.
        [switch]$Force)
    $render = Get-SwRender $Config
    Assert-SwSelectionTransition $Root $render $Config
    $manifestPath = Join-Path $Root '.sw/manifest.json'
    $prev = if (Test-Path -LiteralPath $manifestPath) { Read-SwJson $manifestPath } else { @{} }
    $kitVersion = Get-SwKitVersion
    if ($prev['kitVersion'] -and (Compare-SwVersion $prev['kitVersion'] $kitVersion) -gt 0 -and -not $Force) {
        throw "This project was last updated by kit $($prev['kitVersion']), newer than this kit ($kitVersion); nothing was written. Update the kit clone, or re-run with -Force to downgrade."
    }
    $old = [ordered]@{}
    if ($prev['files']) { foreach ($k in $prev['files'].Keys) { $old[$k] = $prev['files'][$k] } }
    # Expand prefix rules ('.opencode/skills/' -> '.agents/skills/') into one whole-file pair per old
    # manifest key under that prefix, so the loop below (unchanged) handles them like any other rename.
    $moved = [ordered]@{}
    foreach ($m in $script:Moved.GetEnumerator()) {
        if (-not $m.Key.EndsWith('/')) { $moved[$m.Key] = $m.Value; continue }
        foreach ($k in @($old.Keys)) { if ($k.StartsWith($m.Key, [StringComparison]::Ordinal)) { $moved[$k] = $m.Value + $k.Substring($m.Key.Length) } }
    }
    # An edited file at a moved path moves with its edit: its manifest hash follows it to the new path.
    $movedFrom = @{}
    foreach ($m in $moved.GetEnumerator()) {
        $src = Join-Path $Root $m.Key
        if (-not $old.Contains($m.Key) -or $old.Contains($m.Value) -or $render.Files.Contains($m.Key) -or -not $render.Files.Contains($m.Value)) { continue }
        if (-not (Test-Path -LiteralPath $src) -or (Test-Path -LiteralPath (Join-Path $Root $m.Value))) { continue }
        if ((Get-SwHash (Read-SwText $src)) -eq $old[$m.Key]) { continue }  # unedited: plain remove + add
        $movedFrom[$m.Value] = $m.Key
        $old[$m.Value] = $old[$m.Key]
        $old.Remove($m.Key)
    }
    $plan = [Collections.Generic.List[object]]::new()
    foreach ($e in $render.Files.GetEnumerator()) {
        $target = Join-Path $Root $e.Key
        $current = if ($movedFrom.Contains($e.Key)) { Join-Path $Root $movedFrom[$e.Key] } else { $target }
        $newHash = Get-SwHash $e.Value
        $known = $old.Contains($e.Key)
        $action = if (-not (Test-Path -LiteralPath $current)) { 'add' }
        else {
            $cur = Get-SwHash (Read-SwText $current)
            if ($cur -eq $newHash) { 'same' }
            elseif ($known -and $cur -eq $old[$e.Key]) { 'update' }
            elseif ($known -and $newHash -eq $old[$e.Key]) { 'kept-local' }  # edited, but the kit did not change it
            elseif ($known) { 'skip-modified' }
            elseif ($Adopt) { 'adopt' }
            else { 'conflict' }
        }
        $note = if ($movedFrom.Contains($e.Key)) { "$($e.Key) moved from $($movedFrom[$e.Key]) with its local edits" } else { $null }
        $plan.Add([pscustomobject]@{ Path = $e.Key; Action = $action; Hash = $newHash; Note = $note })
    }
    foreach ($rel in @($old.Keys)) {
        if ($render.Files.Contains($rel)) { continue }
        $target = Join-Path $Root $rel
        $action = if (-not (Test-Path -LiteralPath $target)) { 'gone' } elseif ((Get-SwHash (Read-SwText $target)) -eq $old[$rel]) { 'remove' } else { 'orphan-kept' }
        $plan.Add([pscustomobject]@{ Path = $rel; Action = $action; Hash = $null; Note = $null })
    }
    $conflicts = @($plan | Where-Object Action -eq 'conflict')
    if ($conflicts.Count) {
        throw "These files exist and are not SuperWorkspace-managed; nothing was written. Re-run with -Adopt to back them up to .sw/backup/ and replace them:`n  $(($conflicts.Path) -join "`n  ")"
    }

    # Validate the managed blocks before the first move, copy, removal or write.
    $managed = Get-SwManagedContent $Root $render
    # One snapshot per operation; copies never replace an earlier generation.
    $opId = Get-SwOperationId
    $backupRoot = Join-Path $Root ".sw/backup/$opId"
    $reserved = $false
    $manifest = [ordered]@{ kitVersion = $kitVersion; kitCommit = Get-SwKitCommit; files = [ordered]@{} }
    foreach ($p in $plan) {
        $target = Join-Path $Root $p.Path
        if ($movedFrom.Contains($p.Path) -and $PSCmdlet.ShouldProcess($p.Path, "move from $($movedFrom[$p.Path])")) {
            New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
            Move-Item -LiteralPath (Join-Path $Root $movedFrom[$p.Path]) -Destination $target -Force
        }
        switch ($p.Action) {
            { $_ -in 'add', 'update', 'adopt' } {
                if ($PSCmdlet.ShouldProcess($p.Path, $p.Action)) {
                    if ($p.Action -eq 'adopt') {
                        # A failed recovery copy throws here, before the replacement below.
                        if (-not $reserved) { $null = New-SwSnapshotDir $backupRoot; $reserved = $true }
                        Copy-SwNew $target (Join-Path $backupRoot $p.Path)
                    }
                    Write-SwFile $target $render.Files[$p.Path]
                }
                $manifest.files[$p.Path] = $p.Hash
            }
            'same' { $manifest.files[$p.Path] = $p.Hash }
            'kept-local' { $manifest.files[$p.Path] = $old[$p.Path] }
            'skip-modified' {
                $manifest.files[$p.Path] = $old[$p.Path]  # keep old hash so the edit stays detected
                # Hand over the kit's new version to diff against; credential-like names are never copied.
                if ((Split-Path $p.Path -Leaf) -notmatch $script:SecretName) {
                    $incoming = ".sw/backup/$opId/incoming/$($p.Path)"
                    if ($PSCmdlet.ShouldProcess($incoming, 'write incoming kit version')) {
                        if (-not $reserved) { $null = New-SwSnapshotDir $backupRoot; $reserved = $true }
                        Write-SwNewFile (Join-Path $Root $incoming) $render.Files[$p.Path]
                    }
                    $p.Note = @($p.Note, "git diff --no-index $($p.Path) $incoming") -ne $null -join "`n  "
                }
            }
            'remove' { if ($PSCmdlet.ShouldProcess($p.Path, 'remove (dropped from kit)')) { Remove-Item -LiteralPath $target -Force } }
        }
    }

    # Managed blocks in files the project also owns (content validated above).
    $blocks = $managed.Blocks
    $agentsNote = $managed.AgentsNote
    foreach ($b in $blocks.GetEnumerator()) {
        $t = Join-Path $Root $b.Key
        $same = (Test-Path -LiteralPath $t) -and (Read-SwText $t) -ceq $b.Value
        $plan.Add([pscustomobject]@{ Path = $b.Key; Action = $(if ($same) { 'same' } else { 'block' }); Hash = $null; Note = $(if ($b.Key -eq 'AGENTS.md') { $agentsNote } else { $null }) })
        if (-not $same -and $PSCmdlet.ShouldProcess($b.Key, 'set managed block')) { Write-SwFile $t $b.Value }
    }
    if ($PSCmdlet.ShouldProcess('.sw/manifest.json', 'write')) { Write-SwFile $manifestPath (ConvertTo-SwJson $manifest) }
    $plan
}

function Get-SwManifestKit([string]$Root) {
    # The kitVersion a project was last synced with, or $null before the first sync.
    $path = Join-Path $Root '.sw/manifest.json'
    if (Test-Path -LiteralPath $path) { (Read-SwJson $path)['kitVersion'] } else { $null }
}

function Format-SwPlan($Plan, [string]$From, [string]$To = (Get-SwKitVersion)) {
    Write-Output "kit $(if ($From) { $From } else { 'none' }) -> $To"
    $groups = $Plan | Where-Object Action -ne 'same' | Group-Object Action
    foreach ($g in $groups) { Write-Output ("{0,-14} {1}" -f $g.Name, (($g.Group.Path) -join ', ')) }
    Write-Output ("{0} unchanged, {1} changed." -f @($Plan | Where-Object Action -eq 'same').Count, @($Plan | Where-Object Action -ne 'same').Count)
    $orphans = @($Plan | Where-Object Action -eq 'orphan-kept')
    if ($orphans.Count) { Write-Output "Dropped from the kit but locally modified, so left in place: $(($orphans.Path) -join ', ')" }
    if (@($Plan | Where-Object Action -eq 'skip-modified').Count) { Write-Output 'Locally modified files the kit changed were left alone. Compare with the kit version from the project root:' }
    foreach ($p in $Plan | Where-Object Note) { Write-Output "  $($p.Note)" }
}

function Initialize-SwProject {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)][string]$Path = '.',
        [string]$Name, [string]$Profile, [ValidateSet(0, 1)][int]$GitHubTier = -1,
        [switch]$Adopt, [switch]$Claude, [switch]$NoGitHub, [switch]$Force,
        # Opt an existing legacy project into selection v1 (fresh projects default to it); capabilities are additive.
        [switch]$SelectionV1, [AllowEmptyCollection()][AllowEmptyString()][string[]]$Capabilities
    )
    # A nonexistent target is validated and previewed before it is created.
    $Root = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $configPath = Join-Path $Root '.sw/config.json'
    $config = if (Test-Path -LiteralPath $configPath) { Read-SwJson $configPath } else {
        [ordered]@{ project = (Split-Path $Root -Leaf); profile = 'generic'; githubTier = 0; github = $true; startupBudgetBytes = 12100; users = @(); selection = [ordered]@{ version = 1; capabilities = @() } }
    }
    if ($Name) { $config['project'] = $Name }
    if ($Profile) { $config['profile'] = $Profile }
    if ($GitHubTier -ge 0) { $config['githubTier'] = $GitHubTier }
    if ($NoGitHub) { $config['github'] = $false }
    Set-SwSelectionOption $config $SelectionV1 $PSBoundParameters
    # Validate everything that can fail on existing content before the first side effect, git init included.
    $render = Get-SwRender $config
    $null = Get-SwManagedContent $Root $render
    Assert-SwSelectionTransition $Root $render $config
    if (-not (Test-Path -LiteralPath $Root -PathType Container) -and $PSCmdlet.ShouldProcess($Root, 'create directory')) { New-Item -ItemType Directory -Path $Root | Out-Null }
    if (-not (Test-Path -LiteralPath (Join-Path $Root '.git'))) {
        if ($PSCmdlet.ShouldProcess($Root, 'git init -b main')) { & git -C $Root init -b main | Out-Null }
    }
    $from = Get-SwManifestKit $Root
    $plan = Sync-SwProject -Root $Root -Config $config -Adopt:$Adopt -Force:$Force
    if ($PSCmdlet.ShouldProcess('.sw/config.json', 'write')) {
        Write-SwFile $configPath (ConvertTo-SwJson $config)
        foreach ($d in 'tasks', 'inbox', 'archive') { Write-SwFile (Join-Path $Root ".sw/comms/$d/.gitkeep") '' }
    }
    Format-SwPlan $plan $from
    Format-SwSelection $render
    if ($Claude -and -not $WhatIfPreference) { Invoke-SwClaude enable -Path $Root }
    Write-Output "Next: fill the project sections of AGENTS.md, then run 'pwsh .sw/sw.ps1 validate'. Map models with 'pwsh .sw/sw.ps1 tiers'."
}

function Update-SwProject {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Position = 0)][string]$Path, [switch]$Adopt, [switch]$Force,
        [switch]$SelectionV1, [AllowEmptyCollection()][AllowEmptyString()][string[]]$Capabilities)
    $Root = Resolve-SwRoot $Path
    $from = Get-SwManifestKit $Root
    $config = Get-SwConfig $Root
    $before = ConvertTo-SwJson $config
    Set-SwSelectionOption $config $SelectionV1 $PSBoundParameters
    $plan = Sync-SwProject -Root $Root -Config $config -Adopt:$Adopt -Force:$Force
    Format-SwPlan $plan $from
    Format-SwSelection (Get-SwRender $config)
    # The selection is recorded only after a successful sync, before the adapter reads it.
    if ((ConvertTo-SwJson $config) -cne $before -and $PSCmdlet.ShouldProcess('.sw/config.json', 'write selection')) { Write-SwFile (Join-Path $Root '.sw/config.json') (ConvertTo-SwJson $config) }
    if (Test-Path -LiteralPath (Join-Path $Root '.claude/.sw-generated')) {
        if (-not $WhatIfPreference) { Invoke-SwClaude enable -Path $Root } else { Write-Output 'Would regenerate the Claude adapter.' }
    }
}

# --- user-global setup ----------------------------------------------------------------

function Get-SwGlobalPaths {
    $h = [Environment]::GetFolderPath('UserProfile')
    [ordered]@{
        Home           = $h
        OpenCodeRules  = Join-Path $h '.config/opencode/AGENTS.md'
        OpenCodeConfig = Join-Path $h '.config/opencode/opencode.json'
        ClaudeRules    = Join-Path $h '.claude/CLAUDE.md'
        ClaudeRtk      = Join-Path $h '.claude/RTK.md'
        ClaudeSettings = Join-Path $h '.claude/settings.json'
        HomeAgents     = Join-Path $h 'AGENTS.md'
        Backups        = Join-Path $h '.sw/backups'
    }
}

function Backup-SwGlobal {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Destination)
    $p = Get-SwGlobalPaths
    # Every operation gets its own snapshot; an explicit destination must be new (nothing is merged into or replaced).
    if ($Destination) {
        $Destination = [IO.Path]::GetFullPath($Destination)
        if (Test-Path -LiteralPath $Destination) { throw "Backup destination already exists, refusing to reuse it: $Destination" }
    } else { $Destination = Join-Path $p.Backups (Get-SwOperationId) }
    # OpenCodeConfig (opencode.json) can hold a provider apiKey and install never edits it; not backed up.
    # Only files whose names match the credential-name filter are skipped; contents are never scanned.
    $items = foreach ($src in $p.OpenCodeRules, $p.ClaudeRules, $p.ClaudeRtk, $p.ClaudeSettings, $p.HomeAgents) {
        if (-not (Test-Path -LiteralPath $src -PathType Leaf)) { continue }
        if ((Split-Path $src -Leaf) -match $script:SecretName) { continue }
        $rel = [IO.Path]::GetRelativePath($p.Home, $src)
        $dst = Join-Path $Destination $rel
        if (-not (Test-SwContained $p.Home $src) -or -not (Test-SwContained $Destination $dst)) { throw "Backup source is outside the home directory: $src" }
        [pscustomobject]@{ Src = $src; Rel = $rel; Dst = $dst }
    }
    $copied = [Collections.Generic.List[string]]::new()
    $reserved = $false
    foreach ($item in @($items)) {
        if ($PSCmdlet.ShouldProcess($item.Src, "back up to $($item.Dst)")) {
            if (-not $reserved) { $null = New-SwSnapshotDir $Destination; $reserved = $true }
            Copy-SwNew $item.Src $item.Dst
        }
        $copied.Add($item.Rel)
    }
    [pscustomobject]@{ Path = $Destination; Files = @($copied) }
}

function Get-SwNarrowedGhAllow([string[]]$Allow) {
    # Replace a broad `gh *` (or `gh:*`) Bash allow with the specific read-only gh commands.
    $list = [Collections.Generic.List[string]]@($Allow)
    $changed = $list.RemoveAll([Predicate[string]] { param($x) $x -ceq 'Bash(gh *)' -or $x -ceq 'Bash(gh:*)' }) -gt 0
    $read = 'Bash(gh issue list:*)', 'Bash(gh issue view:*)', 'Bash(gh pr list:*)', 'Bash(gh pr view:*)', 'Bash(gh pr checks:*)', 'Bash(gh pr diff:*)', 'Bash(gh run list:*)', 'Bash(gh run view:*)', 'Bash(gh run watch:*)', 'Bash(gh repo view:*)', 'Bash(gh auth status:*)'
    foreach ($r in $read) { if (-not $list.Contains($r)) { $list.Add($r); $changed = $true } }
    [pscustomobject]@{ Allow = @($list); Changed = $changed }
}

function Install-SwGlobal {
    [CmdletBinding(SupportsShouldProcess)]
    param([switch]$Claude, [switch]$ReplaceUnmanaged)
    $p = Get-SwGlobalPaths
    $rules = Read-SwText (Join-Path $script:Kit 'global/rules.md')
    $b = Backup-SwGlobal
    Write-Output "Backup: $($b.Path) ($($b.Files.Count) files; files named like credentials are skipped by name only, contents are not scanned)"

    $oc = if (Test-Path -LiteralPath $p.OpenCodeRules) { Read-SwText $p.OpenCodeRules } else { '' }
    $new = Set-SwBlock $oc 'global' $rules
    if ($new -cne $oc -and $PSCmdlet.ShouldProcess($p.OpenCodeRules, 'set global rules block')) { Write-SwFile $p.OpenCodeRules $new; Write-Output "OpenCode global rules: $($p.OpenCodeRules)" }

    if ($Claude) {
        $cur = if (Test-Path -LiteralPath $p.ClaudeRules) { Read-SwText $p.ClaudeRules } else { '' }
        $include = if (Test-Path -LiteralPath $p.ClaudeRtk) { "@RTK.md`n`n" } else { '' }
        $unmanaged = $cur -and -not $cur.Contains('<!-- sw:begin global -->')
        $base = if ($unmanaged -and $ReplaceUnmanaged) { $include } else { $cur }
        if (-not $base -and $include) { $base = $include }
        $new = Set-SwBlock $base 'global' $rules
        if ($new -cne $cur -and $PSCmdlet.ShouldProcess($p.ClaudeRules, 'set global rules block')) { Write-SwFile $p.ClaudeRules $new; Write-Output "Claude global rules: $($p.ClaudeRules)" }
        if ($unmanaged -and -not $ReplaceUnmanaged) { Write-Output "Note: $($p.ClaudeRules) keeps its earlier unmanaged text above the block; pass -ReplaceUnmanaged to drop it (it is in the backup)." }

        if (Test-Path -LiteralPath $p.ClaudeSettings) {
            $s = Read-SwJson $p.ClaudeSettings
            $allowIn = @(if ($s.Contains('permissions') -and $s['permissions'].Contains('allow')) { $s['permissions']['allow'] } else { @() })
            $result = Get-SwNarrowedGhAllow $allowIn
            if ($result.Changed -and $PSCmdlet.ShouldProcess($p.ClaudeSettings, 'narrow gh allow rules to read-only')) {
                if (-not $s.Contains('permissions')) { $s['permissions'] = [ordered]@{} }
                $s['permissions']['allow'] = @($result.Allow)
                Write-SwFile $p.ClaudeSettings (ConvertTo-SwJson $s)
                Write-Output 'Claude settings: gh allow rules narrowed to read-only commands.'
            }
        }
    }

    # ~/AGENTS.md include pointing at a missing ~/RTK.md (left by an RTK setup).
    if (Test-Path -LiteralPath $p.HomeAgents) {
        $t = Read-SwText $p.HomeAgents
        $h = Split-Path $p.HomeAgents -Parent
        if ($t -match '(?m)^@RTK\.md\s*$' -and -not (Test-Path (Join-Path $h 'RTK.md')) -and (Test-Path -LiteralPath $p.ClaudeRtk) -and $PSCmdlet.ShouldProcess($p.HomeAgents, 'point @RTK.md include at .claude/RTK.md')) {
            Write-SwFile $p.HomeAgents ($t -replace '(?m)^@RTK\.md\s*$', '@.claude/RTK.md')
            Write-Output "Fixed broken include in $($p.HomeAgents)."
        }
    }

    $rtk = Get-SwToolVersion rtk
    if ((-not $rtk -or $rtk -lt [version]'0.48.0') -and $IsWindows) {
        if ($PSCmdlet.ShouldProcess('rtk-ai.rtk', 'winget install')) { & winget install --id rtk-ai.rtk --exact --accept-source-agreements --accept-package-agreements }
    } elseif (-not $rtk -or $rtk -lt [version]'0.48.0') { Write-Output 'rtk missing/outdated; winget install is Windows-only, install rtk manually.' }
    Test-SwGlobal
}

function Test-SwGlobal {
    [CmdletBinding()]
    param()
    $p = Get-SwGlobalPaths
    $rows = [Collections.Generic.List[object]]::new()
    $add = { param($n, $state, $detail) $rows.Add([pscustomobject]@{ Item = $n; State = $state; Detail = $detail }) }
    & $add 'pwsh' 'OK' $PSVersionTable.PSVersion.ToString()
    $probes = @{}
    foreach ($t in @(@('git', $true), @('gh', $false), @('rtk', $false), @('opencode', $false), @('node', $false), @('claude', $false), @('tailscale', $false))) {
        $probe = Get-SwToolProbe $t[0]
        $probes[$t[0]] = $probe
        $state = if ($probe.State -eq 'ok') { 'OK' } elseif ($t[1]) { $(if ($probe.State -eq 'missing') { 'MISSING' } else { 'FAILED' }) } else { 'WARN' }
        & $add $t[0] $state $(if ($probe.State -eq 'ok') { $probe.Version.ToString() } elseif ($probe.State -eq 'missing') { 'not found' } else { Format-SwProbe $probe })
    }
    $rtk = $probes['rtk']
    if ($rtk.State -eq 'ok' -and $rtk.Version -lt [version]'0.48.0') { & $add 'rtk >= 0.48' 'WARN' "found $($rtk.Version)" }
    if ($probes['gh'].State -eq 'ok') {
        $auth = Get-SwGhAuth
        & $add 'gh auth' $(if ($auth -eq 0) { 'OK' } else { 'WARN' }) $(if ($auth -eq 0) { 'logged in' } else { 'run gh auth login' })
    }
    $has = { param($f) (Test-Path -LiteralPath $f) -and (Read-SwText $f).Contains('<!-- sw:begin global -->') }
    & $add 'opencode rules' $(if (& $has $p.OpenCodeRules) { 'OK' } else { 'WARN' }) $p.OpenCodeRules
    if (Test-Path -LiteralPath (Split-Path $p.ClaudeRules)) {
        & $add 'claude rules' $(if (& $has $p.ClaudeRules) { 'OK' } else { 'WARN' }) $p.ClaudeRules
        $settingsText = if (Test-Path -LiteralPath $p.ClaudeSettings) { Read-SwText $p.ClaudeSettings } else { '' }
        $broad = $settingsText -match '"Bash\(gh (\*|:\*)\)"|"Bash\(gh\)"'
        & $add 'claude gh allow' $(if ($broad) { 'WARN' } else { 'OK' }) $(if ($broad) { 'Bash(gh *) allows gh writes; run global install -Claude' } else { 'read-only' })
    }
    foreach ($svc in (Join-Path $p.Home '.config/opencode/service.json'), (Join-Path $p.Home '.local/state/opencode/service.json')) {
        if (Test-Path -LiteralPath $svc) {
            $hostName = (Read-SwJson $svc)['hostname']
            & $add 'opencode bind' $(if ($hostName -in '127.0.0.1', 'localhost', $null) { 'OK' } else { 'WARN' }) "$hostName ($svc); see sw remote setup"
        }
    }
    $rows | Format-Table -AutoSize | Out-String -Width 200 | Write-Output
    $global:LASTEXITCODE = if (@($rows | Where-Object State -in 'MISSING', 'FAILED').Count) { 1 } else { 0 }
}

function Invoke-SwGlobal {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Position = 0)][ValidateSet('install', 'check', 'backup')][string]$Action = 'check', [switch]$Claude, [switch]$ReplaceUnmanaged)
    switch ($Action) {
        'install' { Install-SwGlobal -Claude:$Claude -ReplaceUnmanaged:$ReplaceUnmanaged }
        'check' { Test-SwGlobal }
        'backup' { $b = Backup-SwGlobal; Write-Output "Backup: $($b.Path)"; $b.Files | ForEach-Object { Write-Output "  $_" } }
    }
}

# --- remote access: OpenCode on loopback, published to the tailnet --------------------

function Get-SwServiceFiles {
    $h = [Environment]::GetFolderPath('UserProfile')
    @((Join-Path $h '.config/opencode/service.json'), (Join-Path $h '.local/state/opencode/service.json')) | Where-Object { Test-Path -LiteralPath $_ }
}

function Invoke-SwRemote {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Position = 0)][ValidateSet('setup', 'check')][string]$Action = 'check', [int]$Port = 0,
        # Keep the LAN bind for a browser-only device that cannot run Tailscale.
        [switch]$KeepLan)
    if (-not (Get-Command tailscale -ErrorAction SilentlyContinue)) { throw 'tailscale CLI not found.' }
    $svc = @(Get-SwServiceFiles)
    if (-not $Port) {
        $Port = 49374
        foreach ($f in $svc) { $j = Read-SwJson $f; if ($j.Contains('port') -and $j['port']) { $Port = [int]$j['port']; break } }
    }
    if ($Action -eq 'setup') {
        foreach ($f in $(if ($KeepLan) { @() } else { $svc })) {
            $text = Read-SwText $f
            $j = $text | ConvertFrom-Json -AsHashtable
            if ($j['hostname'] -in '127.0.0.1', 'localhost') { continue }
            # Only the hostname changes; the file holds a credential, so it is edited in place, never copied.
            if ($PSCmdlet.ShouldProcess($f, "hostname $($j['hostname']) -> 127.0.0.1")) {
                Write-SwFile $f ($text -replace '("hostname"\s*:\s*)"[^"]*"', '$1"127.0.0.1"')
                Write-Output "OpenCode bind: $f now 127.0.0.1 (was $($j['hostname'])). Revert by setting it back."
            }
        }
        if ($PSCmdlet.ShouldProcess("tailnet https -> http://127.0.0.1:$Port", 'tailscale serve --bg')) {
            & tailscale serve --bg "http://127.0.0.1:$Port"
            if ($LASTEXITCODE -ne 0) { throw "tailscale serve failed ($LASTEXITCODE). Is Tailscale up and HTTPS enabled for your tailnet?" }
        }
        if ($KeepLan) { Write-Output 'LAN bind kept (-KeepLan): the service stays reachable on the LAN with its password.'; }
        else { Write-Output 'Restart the OpenCode service (quit and reopen OpenCode Desktop) so it rebinds to 127.0.0.1.' }
        if ($IsWindows) {
            $rules = @(Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match '(?i)opencode' })
            if ($rules.Count -and -not $KeepLan) {
                Write-Output 'LAN firewall rules for OpenCode are no longer needed. Review, then remove them yourself from an elevated shell:'
                $rules | ForEach-Object { Write-Output "  Remove-NetFirewallRule -Name '$($_.Name)'   # $($_.DisplayName)" }
            }
        } else { Write-Output 'Firewall rule check skipped (Windows-only).' }
    }
    $status = & tailscale status --json 2>$null | ConvertFrom-Json -AsHashtable
    $dns = if ($status) { ([string]$status['Self']['DNSName']).TrimEnd('.') } else { '' }
    Write-Output "Tailscale: $(if ($status) { $status['BackendState'] } else { 'unavailable' }) $dns"
    Write-Output '== tailscale serve status'; & tailscale serve status
    foreach ($f in $svc) { Write-Output "OpenCode bind: $((Read-SwJson $f)['hostname']) ($f)" }
    if ($dns) {
        try { $r = Invoke-WebRequest "https://$dns/" -Method Head -TimeoutSec 10 -SkipHttpErrorCheck; Write-Output "Tailnet HTTPS https://$dns/ -> HTTP $($r.StatusCode) (401 means reachable and password-protected)" }
        catch { Write-Output "Tailnet HTTPS https://$dns/ -> unreachable: $($_.Exception.Message)" }
    }
    $lan = if ($IsWindows) { @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notmatch '^(127\.|169\.254\.|100\.)' } | Select-Object -ExpandProperty IPAddress) } else { Write-Output 'LAN address check skipped (Windows-only).'; @() }
    foreach ($ip in $lan) {
        $open = Test-Connection -TargetName $ip -TcpPort $Port -TimeoutSeconds 2 -ErrorAction SilentlyContinue
        Write-Output "LAN ${ip}:$Port -> $(if ($open) { 'OPEN (expected closed after setup)' } else { 'closed' })"
    }
}

Export-ModuleMember -Function Set-SwBlock, Get-SwRender, Sync-SwProject, Format-SwPlan, Initialize-SwProject, Update-SwProject,
    Backup-SwGlobal, Install-SwGlobal, Test-SwGlobal, Invoke-SwGlobal, Invoke-SwRemote, Get-SwKitVersion, Get-SwKitCommit, Compare-SwVersion, Get-SwNarrowedGhAllow, Format-SwSelection
