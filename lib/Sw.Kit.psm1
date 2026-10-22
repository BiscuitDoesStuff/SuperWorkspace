# SuperWorkspace kit module: install/update projects and user-global setup.
# Kit-only (not copied into projects). Windows PowerShell 5.1 and PowerShell 7.
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
    $prefix = Invoke-SwNative git @('-C', $script:Kit, 'rev-parse', '--show-prefix')
    if ($LASTEXITCODE -ne 0 -or "$prefix".Trim() -ne '') { return $null }
    $sha = Invoke-SwNative git @('-C', $script:Kit, 'rev-parse', 'HEAD')
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

function Get-SwRender([Collections.IDictionary]$Config) {
    # Everything the kit owns in a project, rendered from $Config. Pure: writes nothing.
    # The profile names a source directory: only a canonical ID may reach a path.
    $null = Get-SwConfiguredTier $Config
    Assert-SwPhysicalPath $script:Kit
    Get-SwPhysicalFiles (Join-Path $script:Kit 'project') | Out-Null
    foreach ($rel in 'VERSION', 'LICENSE', 'THIRD_PARTY_NOTICES.md', 'sw.ps1', 'lib/Sw.Project.psm1') { $null = Resolve-SwManagedPath $script:Kit $rel }
    if ("$($Config['profile'])" -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { throw "Profile '$($Config['profile'])' is not a canonical identifier (lowercase letters, digits, single hyphens)" }
    $profileDir = Join-Path $script:Kit "project/profiles/$($Config['profile'])"
    if (-not (Test-Path -LiteralPath $profileDir)) { throw "Unknown profile '$($Config['profile'])'. Available: $((Get-ChildItem (Join-Path $script:Kit 'project/profiles') -Directory).Name -join ', ')" }
    $profileData = Read-SwJson (Join-Path $profileDir 'profile.json')
    $files = [ordered]@{}
    $add = {
        param($dir)
        if (-not (Test-Path -LiteralPath $dir)) { return }
        foreach ($f in Get-SwPhysicalFiles $dir | Sort-Object FullName) {
            $rel = (Get-SwRelativePath $dir $f.FullName).Replace('\', '/')
            if ($rel -eq 'AGENTS.md') { continue }
            $files[$rel] = (Read-SwText $f.FullName).Replace('{{PROJECT}}', $Config['project'])
        }
    }
    & $add (Join-Path $script:Kit 'project/base')
    & $add (Join-Path $profileDir 'files')
    if ($Config['github'] -ne $false) { & $add (Join-Path $script:Kit 'project/github') }
    # New init explicitly selects local; absent stays tracked for legacy configurations.
    $local = $Config.Contains('records') -and $Config['records'] -ceq 'local'
    if ($Config.Contains('records') -and $Config['records'] -cnotin 'tracked', 'local') { throw "Config 'records' must be 'tracked' or 'local', not '$($Config['records'])'" }
    if ($local) {
        $collab = $files['.sw/collaboration.md']
        $published = "Git is the transport: everything below is plain files in`n``.sw/comms/``, published when a human pushes their branch."
        if (-not $collab.Contains($published)) { throw 'project/base/.sw/collaboration.md lost the records sentence that records: local replaces' }
        $collab = $collab.Replace($published, "Everything below is plain files in`n``.sw/comms/``, kept local by ``records: local`` (git-ignored for new records).`nIgnoring does not untrack existing records or remove published history; review before publishing.")
        $collab = [regex]::Replace($collab, '(?s)\*\*Claims\.\*\*.*?(?=At GitHub tier 1)', '**Claims.** With local records, the owner confirms assignment at the agreed' + "`n" + 'coordination source. Conflicting assignments need an owner decision, not a push.' + "`n")
        $collab = $collab.Replace('Close a task only after its last' + "`n" + 'event is on `main`.', 'With local records, close after the owner confirms integration and the final local event.')
        $collab = [regex]::Replace($collab, '(?s)Across humans, coordination travels as files.*?an issue comment\.', "Across humans, local-only records require an explicit owner-approved handoff.`nDo not assume approvals or inbox messages arrive with a clone. At GitHub tier 1,`npublic issues/comments may carry sanitized coordination if permitted.")
        $files['.sw/collaboration.md'] = $collab
    }
    $files['.sw/profile.json'] = Read-SwText (Join-Path $profileDir 'profile.json')
    $files['.sw/sw.ps1'] = Read-SwText (Join-Path $script:Kit 'sw.ps1')
    $files['.sw/lib/Sw.Project.psm1'] = Read-SwText (Join-Path $script:Kit 'lib/Sw.Project.psm1')
    $files['.sw/LICENSE'] = Read-SwText (Join-Path $script:Kit 'LICENSE')
    $files['.sw/THIRD_PARTY_NOTICES.md'] = Read-SwText (Join-Path $script:Kit 'THIRD_PARTY_NOTICES.md')
    $agentsProfile = Read-SwText (Join-Path $profileDir 'AGENTS.section.md')

    # Selection v1 (config opt-in) filters the in-memory render; legacy keeps every base file and ignores composition.
    $selection = $null; $known = $null
    if ($Config.Contains('selection')) {
        $catalogue = Read-SwJson (Join-Path $script:Kit 'project/selection.json')
        $selection = Resolve-SwSelection $Config['selection'] ([string]$Config['profile']) $profileData $catalogue
        $known = Get-SwSelectionKnown $catalogue $profileData
        # Every component the catalogue or profile names must exist in the kit, selected or not.
        $missing = @(foreach ($s in $known.skills) { if (-not $files.Contains(".agents/skills/$s/SKILL.md")) { ".agents/skills/$s/SKILL.md" } }) +
            @(foreach ($c in $selection.capabilities) { if ($catalogue['capabilities'][$c]['context'].Count -and -not (Test-Path -LiteralPath (Join-Path $script:Kit "project/capabilities/$c/AGENTS.section.md") -PathType Leaf)) { "project/capabilities/$c/AGENTS.section.md" } })
        if ($missing.Count) { throw "Selection source definitions missing; nothing was written: $($missing -join ', ')" }
        foreach ($rel in @($files.Keys)) {
            if ($rel -match '^\.agents/skills/([^/]+)/' -and $Matches[1] -cin $known.skills -and $Matches[1] -cnotin $selection.skills) { $files.Remove($rel) }
        }
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

    # Tracked harness files: Claude loads AGENTS.md through one import and skills from its own directory (a byte copy,
    # no links); both harnesses get the hard limits as their native blocks.
    foreach ($rel in @($files.Keys | Where-Object { $_ -match '^\.agents/skills/' })) { $files[".claude/skills/$($rel.Substring('.agents/skills/'.Length))"] = $files[$rel] }
    $files['.claude/CLAUDE.md'] = "@../AGENTS.md`n"
    $files['.claude/settings.json'] = Get-SwClaudeSettings $profileData['editDeny']
    $files['.codex/rules/workspace.rules'] = Get-SwCodexRules

    $template = Read-SwText (Join-Path $script:Kit 'project/base/AGENTS.md')
    $gitPolicy = Get-SwGitPolicy $Config
    $template = $template.Replace('{{GIT_BRANCH_RULES}}', (Read-SwText (Join-Path $script:Kit "project/git-$gitPolicy.md")).TrimEnd("`n"))
    if ($gitPolicy -eq 'host') {
        $collab = $files['.sw/collaboration.md'].Replace('`main` is the' + "`n" + 'integration baseline.', 'The host project owns its integration baseline.')
        $collab = $collab.Replace('A task is claimed when its `assignment` event is on `main`; if two', 'A task is claimed at the owner-approved coordination source; if two')
        $collab = $collab.Replace('people assign the same task, the first fast-forward push wins and the other', 'people assign the same task, stop for an owner decision and')
        $collab = $collab.Replace('reconciles. At GitHub tier 1', 'reconcile. At GitHub tier 1')
        $collab = $collab.Replace('<main or t3/<name>>', '<assigned branch>')
        $collab = $collab.Replace('published main <full SHA, when observed>', 'host integration ref <full SHA, when observed>')
        $collab = $collab.Replace('refs/heads/t3/<name>', 'refs/heads/<assigned-branch>').Replace('Base: <full main SHA>', 'Base: <full host integration SHA>')
        $collab = $collab.Replace('Close a task only after its last' + "`n" + 'event is on `main`.', 'Close only after the owner confirms integration under the host workflow.')
        $branches = "## Branches`n`nFollow the host project's documented branch/worktree workflow and contributor`nsetup. If unspecified, ask its owner; no branch is created by installing the kit`nor recording a user. Work only in your assigned checkout, never another user's`nbranch. A dirty checkout needs coordination, never reset or stash. Keep automatic`nworktrees off unless the host owner explicitly approves their branch behavior.`n`n"
        $collab = [regex]::Replace($collab, '(?s)## Branches\n.*?(?=## Finish and publish)', $branches)
        $finish = "Follow the host project's commit and publication workflow; commit only within`nthe approved scope. Stage selected task paths only; inspect ``git diff --cached```nfor unrelated work and secrets; commit with a Conventional Commit message`n(``feat:``, ``fix:``, ``docs:``, ``refactor:``, ``test:``, ``chore:``). Humans own`npublication; agents never push or merge a PR. A local commit is local until`nthe remote tip is confirmed. Announce:`n`n"
        $collab = [regex]::Replace($collab, '(?s)(## Finish and publish\n\n).*?(?=```text)', '$1' + $finish)
        $integrate = "## Integrate (human)`n`nUse the host project's review, merge, protection and integration rules. The kit`ndoes not select an integration branch or configure repository settings. Agents`nnever push or merge a PR; humans own publication and repository settings.`n`n"
        $collab = [regex]::Replace($collab, '(?s)## Integrate \(human\)\n.*?(?=## Receive)', $integrate)
        $collab = [regex]::Replace($collab, '(?s)(## Receive\n\n).*?(?=\*\*Kit updates\.\*\*)', '$1Receive changes using the host workflow. Check for local work before syncing;' + "`n" + 'never discard it. Publication, receipt, build, automated checks and manual' + "`n" + "checks are separate facts.`n`n")
        $files['.sw/collaboration.md'] = $collab
    }
    $ignore = @('.claude/settings.local.json', '.sw/backup/', '.sw/models.local.md', '.env', '.env.*', '!.env.example') + $(if ($local) { '.sw/comms/' } else { @() }) -join "`n"
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
    }
}

function Format-SwSelection($Render) {
    $s = $Render.Selection
    if (-not $s) { return 'selection: legacy (no selection field; every base skill kept; composition ignored)' }
    $list = { param($v) "[$(@($v) -join ', ')]" }
    "selection: v1 profile=$($s.profile) capabilities=$(& $list $s.capabilities) skills=$(& $list $s.skills) context=$(& $list $s.context) checks=$(& $list $s.checks)"
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

function Assert-SwSelectionTransition([string]$Root, $Render) {
    # Preflight before any write or git init: a deselected kit skill that is edited, unowned, unverified or linked, in
    # either skill directory, blocks the whole run (paths are project-relative). -Force/-Adopt never reach this.
    if (-not $Render.Selection) { return }
    $drop = @($Render.Known.skills | Where-Object { $_ -cnotin $Render.Selection.skills })
    $blocked = [Collections.Generic.List[string]]::new()
    $manifestPath = Join-Path $Root '.sw/manifest.json'
    $owned = if (Test-Path -LiteralPath $manifestPath -PathType Leaf) { (Read-SwJson $manifestPath)['files'] } else { $null }
    if ($owned -isnot [Collections.IDictionary]) { $owned = @{} }
    foreach ($dir in '.agents/skills', '.claude/skills') {
        foreach ($s in $drop) {
            $rel = "$dir/$s"
            if (Test-SwLinkedPath $Root $rel) { $blocked.Add("$rel (linked)"); continue }
            $full = Join-Path $Root $rel
            $onDisk = @(if (Test-Path -LiteralPath $full -PathType Container) { Get-ChildItem -LiteralPath $full -Recurse -Force | ForEach-Object { "$rel/$((Get-SwRelativePath $full $_.FullName).Replace('\', '/'))" } })
            foreach ($f in @($onDisk) + @($owned.Keys | Where-Object { $_.StartsWith("$rel/", [StringComparison]::Ordinal) }) | Sort-Object -Unique) {
                $path = Join-Path $Root $f
                if (Test-SwLinkedPath $Root $f) { $blocked.Add("$f (linked)"); continue }
                if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
                if (-not $owned.Contains($f)) { $blocked.Add("$f (unowned or unverified)"); continue }
                if ((Get-SwHash (Read-SwText $path)) -cne $owned[$f]) { $blocked.Add("$f (modified)") }
            }
        }
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

function Get-SwKitOwnedPaths($Render) {
    # Exact current and known historical outputs, never broad manifest-authorized prefixes.
    $allowed = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($rel in $Render.Files.Keys) { $null = $allowed.Add($rel) }
    $dirs = @('project/base', 'project/github') + @(Get-ChildItem -LiteralPath (Join-Path $script:Kit 'project/profiles') -Directory | ForEach-Object { "project/profiles/$($_.Name)/files" })
    foreach ($dir in $dirs) {
        $full = Join-Path $script:Kit $dir
        foreach ($file in Get-SwPhysicalFiles $full) {
            $rel = (Get-SwRelativePath $full $file.FullName).Replace('\', '/')
            if ($rel -cne 'AGENTS.md') { $null = $allowed.Add($rel) }
        }
    }
    $null = $allowed.Add('.sw/selection.json')
    foreach ($rel in Get-SwRetiredOutputs) { $null = $allowed.Add($rel) }
    # Every skill file, current or retired, also has its generated Claude copy.
    foreach ($rel in @($allowed)) { if ($rel.StartsWith('.agents/skills/', [StringComparison]::Ordinal)) { $null = $allowed.Add(".claude/skills/$($rel.Substring('.agents/skills/'.Length))") } }
    foreach ($move in $script:Moved.GetEnumerator()) {
        if (-not $move.Key.EndsWith('/')) { if ($allowed.Contains($move.Value)) { $null = $allowed.Add($move.Key) }; continue }
        foreach ($rel in @($allowed)) { if ($rel.StartsWith($move.Value, [StringComparison]::Ordinal)) { $null = $allowed.Add($move.Key + $rel.Substring($move.Value.Length)) } }
    }
    , $allowed
}

function Read-SwManifest([string]$Root, $Allowed) {
    $path = Resolve-SwManagedPath $Root '.sw/manifest.json'
    if (-not (Test-Path -LiteralPath $path)) { return @{ files = [ordered]@{} } }
    $record = Read-SwJson $path
    if ($record -isnot [Collections.IDictionary] -or $record['files'] -isnot [Collections.IDictionary] -or @($record.Keys | Where-Object { $_ -cnotin 'kitVersion', 'kitCommit', 'files' }).Count) { throw 'Invalid project ownership manifest; nothing was written.' }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($rel in $record['files'].Keys) {
        Assert-SwRelativePath $rel
        if (-not $Allowed.Contains($rel) -or -not $seen.Add($rel) -or $record['files'][$rel] -isnot [string] -or $record['files'][$rel] -cnotmatch '^[0-9a-f]{64}$') { throw 'Invalid or unrelated project ownership manifest entry; nothing was written.' }
        $null = Resolve-SwManagedPath $Root $rel
    }
    $record
}

function Sync-SwProject {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Root, [Collections.IDictionary]$Config, [switch]$Adopt,
        # Allow running an older kit over a project a newer kit last updated.
        [switch]$Force, [switch]$Preflight)
    $render = Get-SwRender $Config
    Assert-SwPhysicalPath $Root
    foreach ($rel in @($render.Files.Keys) + @('AGENTS.md', '.gitignore', '.gitattributes', '.sw/config.json', '.sw/profile.json', '.claude/.sw-generated')) { $null = Resolve-SwManagedPath $Root $rel }
    $manifestPath = Resolve-SwManagedPath $Root '.sw/manifest.json'
    $prev = Read-SwManifest $Root (Get-SwKitOwnedPaths $render)
    # The retired opt-in adapter wrote its own .claude/ files; its installed copy removes exactly what it owns.
    if (Test-Path -LiteralPath (Join-Path $Root '.claude/.sw-generated')) {
        throw 'A local Claude adapter from an earlier kit is installed (.claude/.sw-generated); nothing was written. Remove it first with the installed copy, which needs PowerShell 7 (pwsh .sw/sw.ps1 claude disable), or remove its generated .claude files yourself, then re-run.'
    }
    Assert-SwSelectionTransition $Root $render
    $kitVersion = Get-SwKitVersion
    if ($prev['kitVersion'] -and (Compare-SwVersion $prev['kitVersion'] $kitVersion) -gt 0 -and -not $Force) {
        throw "This project was last updated by kit $($prev['kitVersion']), newer than this kit ($kitVersion); nothing was written. Update the kit clone, or re-run with -Force to downgrade."
    }
    $old = [ordered]@{}
    if ($prev['files']) { foreach ($k in $prev['files'].Keys) { $old[$k] = $prev['files'][$k] } }
    $original = [ordered]@{}; foreach ($k in $old.Keys) { $original[$k] = $old[$k] }
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
    $retired = @(Get-SwRetiredOutputs)
    foreach ($rel in @($old.Keys)) {
        if ($render.Files.Contains($rel)) { continue }
        $target = Join-Path $Root $rel
        # An edited retired output (OpenCode, roles, manager, merged skills): ownership is released once, the file stays,
        # and later updates do not report it as unresolved. A retired skill stays in a discovery directory, so it loads.
        $action = if (-not (Test-Path -LiteralPath $target)) { 'gone' } elseif ((Get-SwHash (Read-SwText $target)) -eq $old[$rel]) { 'remove' } elseif ($rel -cin $retired) { 'released' } else { 'orphan-kept' }
        $note = if ($action -ne 'released') { $null }
        elseif ($rel -match '^\.(agents|claude)/skills/') { "$rel kept as your own file: a retired kit skill with local edits, now project-owned and still discoverable, so Codex or Claude can load it; delete it or move it out of .agents/skills and .claude/skills to stop it loading" }
        else { "$rel kept as your own file: a retired kit output with local edits, no longer owned, generated or loaded" }
        $plan.Add([pscustomobject]@{ Path = $rel; Action = $action; Hash = $null; Note = $note })
    }
    $conflicts = @($plan | Where-Object Action -eq 'conflict')
    if ($conflicts.Count) {
        throw "These files exist and are not SuperWorkspace-managed; nothing was written. Re-run with -Adopt to back them up to .sw/backup/ and replace them:`n  $(($conflicts.Path) -join "`n  ")"
    }

    # Validate the managed blocks before the first move, copy, removal or write.
    $managed = Get-SwManagedContent $Root $render
    $opId = Get-SwOperationId
    $backupRoot = Join-Path $Root ".sw/backup/$opId"
    if (@($plan | Where-Object { $_.Action -in 'adopt', 'skip-modified' }).Count) { Assert-SwPhysicalPath $backupRoot }
    # The same read-only plan guards init before directory creation or git init.
    if ($Preflight) {
        foreach ($b in $managed.Blocks.GetEnumerator()) {
            $target = Join-Path $Root $b.Key
            $same = (Test-Path -LiteralPath $target) -and (Read-SwText $target) -ceq $b.Value
            $plan.Add([pscustomobject]@{ Path = $b.Key; Action = $(if ($same) { 'same' } else { 'block' }); Hash = $null; Note = $null })
        }
        return $plan
    }
    # One snapshot per operation; copies never replace an earlier generation.
    $reserved = $false
    # Consent for the record precedes file effects. Never change files then drop their inventory on a declined prompt.
    if (-not $PSCmdlet.ShouldProcess('.sw/manifest.json', 'write completed-effect ownership record')) {
        $global:LASTEXITCODE = $(if ($WhatIfPreference) { 0 } else { 1 })
        if (-not $WhatIfPreference) { Write-Warning 'PARTIAL: ownership write declined; no sync effects performed.' }
        foreach ($b in $managed.Blocks.GetEnumerator()) {
            $t = Join-Path $Root $b.Key
            $same = (Test-Path -LiteralPath $t) -and (Read-SwText $t) -ceq $b.Value
            $plan.Add([pscustomobject]@{ Path = $b.Key; Action = $(if ($same) { 'same' } else { 'block' }); Hash = $null; Note = $null })
        }
        return $plan
    }
    $partial = $false
    $manifest = [ordered]@{ kitVersion = $kitVersion; kitCommit = Get-SwKitCommit; files = $original }
    foreach ($p in $plan) {
        $target = Resolve-SwManagedPath $Root $p.Path
        if ($movedFrom.Contains($p.Path)) {
            $sourceRel = $movedFrom[$p.Path]
            if (-not $PSCmdlet.ShouldProcess($p.Path, "move from $sourceRel")) { $p.Action = 'declined'; $partial = $true; continue }
            $source = Resolve-SwManagedPath $Root $sourceRel
            New-Item -ItemType Directory -Force (Split-Path $target) -Confirm:$false | Out-Null
            Move-Item -LiteralPath $source -Destination $target -Force -Confirm:$false
            $manifest.files.Remove($sourceRel); $manifest.files[$p.Path] = $old[$p.Path]
        }
        switch ($p.Action) {
            { $_ -in 'add', 'update', 'adopt' } {
                if ($PSCmdlet.ShouldProcess($p.Path, $p.Action)) {
                    if ($p.Action -eq 'adopt') {
                        # A failed recovery copy throws here, before the replacement below.
                        if (-not $reserved) { $null = New-SwSnapshotDir $backupRoot; $reserved = $true }
                        Copy-SwNew $target (Join-Path $backupRoot $p.Path)
                    }
                    $null = Resolve-SwManagedPath $Root $p.Path
                    Write-SwFile $target $render.Files[$p.Path]
                    $manifest.files[$p.Path] = $p.Hash
                } else {
                    $p.Action = 'declined'; $partial = $true
                }
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
                    if (Test-Path -LiteralPath (Join-Path $Root $incoming)) { $p.Note = @($p.Note, "git diff --no-index $($p.Path) $incoming") -ne $null -join "`n  " }
                }
            }
            'remove' {
                if ($PSCmdlet.ShouldProcess($p.Path, 'remove (dropped from kit)')) { $null = Resolve-SwManagedPath $Root $p.Path; Remove-Item -LiteralPath $target -Force -Confirm:$false; $manifest.files.Remove($p.Path) }
                else { $p.Action = 'declined'; $partial = $true }
            }
            { $_ -in 'gone', 'released' } { $manifest.files.Remove($p.Path) }
            'orphan-kept' { $partial = $true }
        }
    }

    # Managed blocks in files the project also owns (content validated above).
    $blocks = $managed.Blocks
    $agentsNote = $managed.AgentsNote
    foreach ($b in $blocks.GetEnumerator()) {
        $t = Join-Path $Root $b.Key
        $same = (Test-Path -LiteralPath $t) -and (Read-SwText $t) -ceq $b.Value
        $plan.Add([pscustomobject]@{ Path = $b.Key; Action = $(if ($same) { 'same' } else { 'block' }); Hash = $null; Note = $(if ($b.Key -eq 'AGENTS.md') { $agentsNote } else { $null }) })
        if (-not $same) {
            if ($PSCmdlet.ShouldProcess($b.Key, 'set managed block')) { $null = Resolve-SwManagedPath $Root $b.Key; Write-SwFile $t $b.Value }
            else { $partial = $true }
        }
    }
    $null = Resolve-SwManagedPath $Root '.sw/manifest.json'
    Write-SwFile $manifestPath (ConvertTo-SwJson $manifest)
    $global:LASTEXITCODE = $(if ($partial) { 1 } else { 0 })
    if ($partial) { Write-Warning 'PARTIAL: unresolved/declined effects retained in ownership; configuration and adapter continuation must stop.' }
    $plan
}

function Get-SwManifestKit([string]$Root) {
    # The kitVersion a project was last synced with, or $null before the first sync.
    $path = Resolve-SwManagedPath $Root '.sw/manifest.json'
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

function Remove-SwRetiredConfig([Collections.IDictionary]$Config) {
    # Choices that only configured the retired OpenCode surface or the dropped free-models skill. Returns notes.
    if ($Config.Contains('context7')) { $Config.Remove('context7'); 'Retired config context7 removed: it configured the Context7 MCP server in the retired opencode.jsonc; configure MCP servers in Claude Code or Codex yourself.' }
    if ($Config.Contains('watcherIgnore')) { $Config.Remove('watcherIgnore'); 'Retired config watcherIgnore removed: it configured the retired OpenCode file watcher.' }
    $sel = $Config['selection']
    if ($sel -is [Collections.IDictionary] -and $sel['capabilities'] -is [array] -and 'provider-setup' -cin $sel['capabilities']) {
        $sel['capabilities'] = @($sel['capabilities'] | Where-Object { $_ -cne 'provider-setup' })
        'Retired capability provider-setup removed from the selection: its free-models skill was dropped.'
    }
}

function Get-SwRetiredLocalNotes([string]$Root) {
    # Per-user files earlier kits ignored and never owned; the kit no longer ignores or reads them.
    foreach ($rel in '.opencode/opencode.jsonc', '.opencode/opencode.json') {
        if (Test-Path -LiteralPath (Join-Path $Root $rel) -PathType Leaf) { "Retired local OpenCode file left in place and no longer ignored by the kit block: $rel (delete it when unused; never commit it)." }
    }
}

function Initialize-SwProject {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)][string]$Path = '.',
        [string]$Name, [string]$Profile, [ValidateSet(0, 1, 2)][int]$GitHubTier = -1,
        [switch]$Adopt, [switch]$NoGitHub, [switch]$Force,
        # Opt an existing legacy project into selection v1 (fresh projects default to it); capabilities are additive.
        [switch]$SelectionV1, [AllowEmptyCollection()][AllowEmptyString()][string[]]$Capabilities,
        [ValidateSet('local', 'tracked')][string]$Records, [ValidateSet('host', 'workspace')][string]$GitPolicy
    )
    # A nonexistent target is validated and previewed before it is created.
    $Root = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $configPath = Resolve-SwManagedPath $Root '.sw/config.json'
    $config = if (Test-Path -LiteralPath $configPath) { Read-SwJson $configPath } else {
        [ordered]@{ project = (Split-Path $Root -Leaf); profile = 'generic'; githubTier = 0; github = $true; records = 'local'; gitPolicy = 'host'; startupBudgetBytes = 12100; users = @(); selection = [ordered]@{ version = 1; capabilities = @() } }
    }
    # A package below another repository is not a new project root. Never create a nested repo implicitly.
    if (-not (Test-Path -LiteralPath $configPath) -and -not (Test-Path -LiteralPath (Join-Path $Root '.git'))) {
        $probe = $Root
        while (-not (Test-Path -LiteralPath $probe -PathType Container)) { $probe = Split-Path $probe -Parent }
        $top = Invoke-SwNative git @('-C', $probe, 'rev-parse', '--show-toplevel')
        if ($LASTEXITCODE -eq 0 -and $top) { throw "Target is inside an existing Git repository. Use its repository root or decide nested-repository setup separately; nothing was written." }
    }
    $retired = @(Remove-SwRetiredConfig $config)
    if ($Name) { $config['project'] = $Name }
    if ($Profile) { $config['profile'] = $Profile }
    if ($GitHubTier -ge 0) { $config['githubTier'] = $GitHubTier }
    if ($NoGitHub) { $config['github'] = $false }
    if ($PSBoundParameters.ContainsKey('Records')) { $config['records'] = $Records.ToLowerInvariant() }
    if ($PSBoundParameters.ContainsKey('GitPolicy')) { $config['gitPolicy'] = $GitPolicy.ToLowerInvariant() }
    Set-SwSelectionOption $config $SelectionV1 $PSBoundParameters
    # Validate everything that can fail on existing content before the first side effect, git init included.
    foreach ($d in 'tasks', 'inbox', 'archive') { $null = Resolve-SwManagedPath $Root ".sw/comms/$d/.gitkeep" }
    $preview = Sync-SwProject -Root $Root -Config $config -Adopt:$Adopt -Force:$Force -Preflight
    if (-not $PSCmdlet.ShouldProcess('.sw/config.json', 'write configuration and absent comms placeholders')) {
        if ($WhatIfPreference) { Format-SwPlan $preview (Get-SwManifestKit $Root); Format-SwSelection (Get-SwRender $config); $retired }
        else { Write-Warning 'PARTIAL: configuration declined; no initialization effects performed.' }
        $global:LASTEXITCODE = $(if ($WhatIfPreference) { 0 } else { 1 }); return
    }
    if (-not (Test-Path -LiteralPath $Root -PathType Container) -and $PSCmdlet.ShouldProcess($Root, 'create directory')) { New-Item -ItemType Directory -Path $Root | Out-Null }
    if (-not (Test-Path -LiteralPath (Join-Path $Root '.git'))) {
        if ($PSCmdlet.ShouldProcess($Root, 'git init -b main')) {
            & git -C $Root init -b main | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'git init failed; no workspace files were written. Inspect Git effects before retrying.' }
        }
    }
    $from = Get-SwManifestKit $Root
    $plan = Sync-SwProject -Root $Root -Config $config -Adopt:$Adopt -Force:$Force
    if ($global:LASTEXITCODE -ne 0) { Format-SwPlan $plan $from; return }
    if (-not $WhatIfPreference) {
        Write-SwFile $configPath (ConvertTo-SwJson $config)
        foreach ($d in 'tasks', 'inbox', 'archive') { $keep = Resolve-SwManagedPath $Root ".sw/comms/$d/.gitkeep"; if (-not (Test-Path -LiteralPath $keep)) { Write-SwFile $keep '' } }
    }
    Format-SwPlan $plan $from
    Format-SwSelection (Get-SwRender $config)
    $retired
    Get-SwRetiredLocalNotes $Root
    Write-Output "Git policy: $(Get-SwGitPolicy $config); records: $(if ($config['records']) { $config['records'] } else { 'tracked (legacy)' })."
    if ($config['records'] -eq 'local') { Write-Output 'Local records are git-ignored; existing tracked files/history are not removed. Review before publishing.' }
    Write-Output "Next: fill the project sections of AGENTS.md, then run 'powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 validate'. Models are chosen per thread in T3 Code."
}

function Update-SwProject {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Position = 0)][string]$Path, [switch]$Adopt, [switch]$Force,
        [switch]$SelectionV1, [AllowEmptyCollection()][AllowEmptyString()][string[]]$Capabilities,
        [ValidateSet('local', 'tracked')][string]$Records, [ValidateSet('host', 'workspace')][string]$GitPolicy)
    $Root = Resolve-SwRoot $Path
    $from = Get-SwManifestKit $Root
    $config = Get-SwConfig $Root
    $before = ConvertTo-SwJson $config
    $retired = @(Remove-SwRetiredConfig $config)
    if ($PSBoundParameters.ContainsKey('Records')) { $config['records'] = $Records.ToLowerInvariant() }
    if ($PSBoundParameters.ContainsKey('GitPolicy')) { $config['gitPolicy'] = $GitPolicy.ToLowerInvariant() }
    Set-SwSelectionOption $config $SelectionV1 $PSBoundParameters
    $configChanged = (ConvertTo-SwJson $config) -cne $before
    if ($configChanged -and -not $PSCmdlet.ShouldProcess('.sw/config.json', 'write configuration after completed sync')) {
        if ($WhatIfPreference) {
            $preview = Sync-SwProject -Root $Root -Config $config -Adopt:$Adopt -Force:$Force -Preflight
            Format-SwPlan $preview $from
            Format-SwSelection (Get-SwRender $config)
            $retired
        } else { Write-Warning 'PARTIAL: configuration declined; no update effects performed.' }
        $global:LASTEXITCODE = $(if ($WhatIfPreference) { 0 } else { 1 }); return
    }
    $plan = Sync-SwProject -Root $Root -Config $config -Adopt:$Adopt -Force:$Force
    $syncExit = $global:LASTEXITCODE
    Format-SwPlan $plan $from
    Format-SwSelection (Get-SwRender $config)
    # Explicit config choices are recorded only after a successful sync.
    if ($syncExit -ne 0) { $global:LASTEXITCODE = $syncExit; return }
    if ($configChanged -and -not $WhatIfPreference) { Write-SwFile (Resolve-SwManagedPath $Root '.sw/config.json') (ConvertTo-SwJson $config) }
    $retired
    Get-SwRetiredLocalNotes $Root
    Write-Output "Git policy: $(Get-SwGitPolicy $config); records: $(if ($config['records']) { $config['records'] } else { 'tracked (legacy)' })."
    if ($config['records'] -eq 'local') { Write-Output 'Local records are git-ignored; existing tracked files/history are not removed. Review before publishing.' }
}

# --- user-global setup ----------------------------------------------------------------

function Get-SwUserHome { [Environment]::GetFolderPath('UserProfile') }

# Home paths compare case-insensitively (Windows); every home set and record map uses this one comparer.
function Get-SwPathComparer { [StringComparer]::OrdinalIgnoreCase }

function Get-SwHomeList([string]$Kind, [string[]]$Explicit, [string]$EnvName, [string]$Default, [char]$Separator = [IO.Path]::PathSeparator) {
    # Explicit dirs win; else the provider's env variable; else the default home. Only a single string (one argument or
    # the env value) is read as a path list; elements of a real array are always literal paths. A single string holding
    # the separator that is also an existing directory is ambiguous and refused. The computed default is always literal.
    # Every path must be absolute, and a filesystem root is refused (it is no provider home).
    $origin, $given = if ($Explicit) { 'parameter', @($Explicit) }
    elseif ([Environment]::GetEnvironmentVariable($EnvName)) { "env $EnvName", @([Environment]::GetEnvironmentVariable($EnvName)) }
    else { 'default', @($Default) }
    $raw = if ($origin -ne 'default' -and $given.Count -eq 1 -and "$($given[0])".Contains($Separator)) {
        if ((Test-SwFullyQualified "$($given[0])") -and [IO.Directory]::Exists("$($given[0])")) {
            throw "Ambiguous $Kind home ($origin): '$($given[0])' is an existing directory and also a '$Separator'-separated list; nothing was written. Pass the homes as a PowerShell array instead."
        }
        @("$($given[0])".Split($Separator))
    } else { $given }
    $seen = [Collections.Generic.HashSet[string]]::new((Get-SwPathComparer))
    foreach ($r in $raw) {
        $t = "$r".Trim()
        if (-not $t) { continue }
        if (-not (Test-SwFullyQualified $t)) { throw "$Kind home ($origin) must be an absolute path, nothing was written: '$t'" }
        $full = [IO.Path]::GetFullPath($t)
        if ($full.TrimEnd([char[]]@([char]92, [char]47)) -eq ([IO.Path]::GetPathRoot($full)).TrimEnd([char[]]@([char]92, [char]47))) { throw "$Kind home ($origin) is a filesystem root, nothing was written: '$t'" }
        $dir = $full.TrimEnd([char[]]@([char]92, [char]47))
        if ($seen.Add($dir)) { [pscustomobject]@{ Kind = $Kind; Dir = $dir; Origin = $origin } }
    }
}

function Get-SwGlobalPaths([string[]]$ClaudeConfigDir, [string[]]$CodexHome) {
    $h = Get-SwUserHome
    [ordered]@{
        Home       = $h
        Claude     = @(Get-SwHomeList 'Claude' $ClaudeConfigDir 'CLAUDE_CONFIG_DIR' (Join-Path $h '.claude'))
        Codex      = @(Get-SwHomeList 'Codex' $CodexHome 'CODEX_HOME' (Join-Path $h '.codex'))
        HomeAgents = Join-Path $h 'AGENTS.md'
        HomeRtk    = Join-Path $h '.claude/RTK.md'
        Backups    = Join-Path $h '.sw/backups'
    }
}

function Get-SwGlobalFiles([Collections.IDictionary]$Paths) {
    # Every file install edits or once edited (the pre-install snapshot), with the directory it must stay inside.
    foreach ($c in $Paths.Claude) { foreach ($f in 'CLAUDE.md', 'RTK.md', 'settings.json') { [pscustomobject]@{ Kind = 'claude'; Home = "Claude home $($c.Dir)"; Root = $c.Dir; Src = Join-Path $c.Dir $f } } }
    foreach ($c in $Paths.Codex) { [pscustomobject]@{ Kind = 'codex'; Home = "Codex home $($c.Dir)"; Root = $c.Dir; Src = Join-Path $c.Dir 'AGENTS.md' } }
    [pscustomobject]@{ Kind = 'user'; Home = "User home $($Paths.Home)"; Root = $Paths.Home; Src = $Paths.HomeAgents }
    [pscustomobject]@{ Kind = 'user'; Home = "User home $($Paths.Home)"; Root = $Paths.Home; Src = Join-Path $Paths.Home '.sw/global.json' }
}

function Assert-SwGlobalHomes([Collections.IDictionary]$Paths) {
    # A home named by parameter or env variable must already exist: a typo must not create a stray config directory,
    # and a backup of only some of the named homes must not look complete.
    $absent = @(@($Paths.Claude) + @($Paths.Codex) | Where-Object { $_.Origin -ne 'default' -and -not (Test-Path -LiteralPath $_.Dir -PathType Container) })
    if ($absent.Count) { throw "Home not found, nothing written: $(($absent | ForEach-Object { "$($_.Kind) $($_.Dir) ($($_.Origin))" }) -join '; ')" }
}

function Backup-SwGlobal {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Destination, [string[]]$ClaudeConfigDir, [string[]]$CodexHome)
    $p = Get-SwGlobalPaths $ClaudeConfigDir $CodexHome
    Assert-SwPhysicalPath $p.Home
    Assert-SwGlobalHomes $p
    # Every operation gets its own snapshot; an explicit destination must be new (nothing is merged into or replaced).
    if ($Destination) {
        $Destination = [IO.Path]::GetFullPath($Destination)
        if (Test-Path -LiteralPath $Destination) { throw "Backup destination already exists, refusing to reuse it: $Destination" }
    } else { $Destination = Join-Path $p.Backups (Get-SwOperationId) }
    Assert-SwPhysicalPath $Destination
    # Only the files install may edit. Only files whose names match the credential-name filter are skipped; contents are never scanned.
    # A file outside the user home (a provider home set elsewhere) is stored under external/<kind>-<path hash>/.
    $seen = [Collections.Generic.HashSet[string]]::new((Get-SwPathComparer))
    $items = foreach ($f in Get-SwGlobalFiles $p) {
        $src = [IO.Path]::GetFullPath($f.Src)
        if (-not (Test-SwContained $f.Root $src)) { throw "Backup source is outside the home directory: $src" }
        Assert-SwPhysicalPath $src
        if (-not $seen.Add($src) -or -not (Test-Path -LiteralPath $src -PathType Leaf)) { continue }
        if ((Split-Path $src -Leaf) -match $script:SecretName) { continue }
        $rel = if (Test-SwContained $p.Home $src) { (Get-SwRelativePath $p.Home $src) }
        else { Join-Path "external/$($f.Kind)-$((Get-SwHash $f.Root).Substring(0, 12))" (Split-Path $src -Leaf) }
        $dst = Join-Path $Destination $rel
        if (-not (Test-SwContained $Destination $dst)) { throw "Backup source is outside the home directory: $src" }
        [pscustomobject]@{ Home = $f.Home; Src = $src; Rel = $rel; Dst = $dst }
    }
    $copied = [Collections.Generic.List[object]]::new()
    $reserved = $false; $partial = $false
    foreach ($item in @($items)) {
        if ($PSCmdlet.ShouldProcess($item.Src, "back up to $($item.Dst)")) {
            if (-not $reserved) { $null = New-SwSnapshotDir $Destination; $reserved = $true }
            Copy-SwNew $item.Src $item.Dst
            $copied.Add($item)
        } else {
            if (-not $WhatIfPreference) { $partial = $true }
        }
    }
    [pscustomobject]@{ Path = $Destination; Files = @($copied | ForEach-Object Rel); Items = @($copied); Homes = @(Get-SwGlobalFiles $p | ForEach-Object Home | Select-Object -Unique); Partial = $partial }
}

# Hashes of every global/rules.md ever committed (git log --follow -- global/rules.md), in the block hash domain of
# Get-SwGlobalBody. They prove a block unedited when no baseline was recorded (homes set up before baselines existed).
# Every rules change must add its hash here; a test checks that the current rules are listed.
$script:GlobalShipped = @(
    '3920f81fbabb661d9920a9d7cc57489a402b811fdc2528b56cf8a37f89ed9f2f' # 3f3a4a5
    '0d7bc74091fe9f509a28fd0a8a6389ec6bf88d9242dd7e686363abb50ff49d79' # fa7115d
    'fc06d08b945227b9226fbaefef4032121c7d02f1cd2d2ee3588c09a1b6cdd286' # 05df1c0
    '752a2d148bbe4a8ea45c478166cec48e803973552bc53c7e333698815cefe2d2' # b252c19
    '9cecd4e62bf7ee1c59098c674b08306e43b08e6244d6ba625af805559af235f6' # b800136
    'a6b4ac86c9263c8f3ef5eacccdf3002b5d29a0523f593fbd44dabfd4cfa8d93a' # b1068ff
    'edff6b54207c91a217630615a46d76d0c59343619f180bef0b95ea9708caf595' # 6d7ab32
    '9032a5829e56e6d48aeb47c3b1c5d52629ee5c0d0f5bb1f2526098377097e943' # 92a6ea3
    'bcfa0cb415554b42fd4bd6978a2dd1cc7fba710d301add78a19fe43497dd94f4' # 8d598dc
    '0c0b81d62952b0cff11398d5133a625b46ecc739062420bf0f7bcbf0398abd5e' # 9ca5907
)
$script:GlobalEntry = [ordered]@{ claude = 'CLAUDE.md#global'; codex = 'AGENTS.md#global' }

# The exact text Set-SwBlock writes between the global markers; block hashes are taken over this text.
function Get-SwGlobalBody([string]$Rules) { "`n$($Rules.Trim("`n"))`n" }

function Get-SwGlobalKind([Collections.IDictionary]$Entries) { (@($script:GlobalEntry.Keys | Where-Object { $Entries.Contains($script:GlobalEntry[$_]) })) -join '+' }

function Find-SwGlobalHome([Collections.IDictionary]$Homes, [string]$Dir) {
    $cmp = Get-SwPathComparer
    foreach ($k in @($Homes.Keys)) { if ($cmp.Equals($k, $Dir)) { return $k } }
}

function Assert-SwStrictJson([string]$Text) {
    # Strict RFC 8259 JSON with no duplicate key in any object. ConvertFrom-Json also takes single-quoted and unquoted
    # keys (and, on PowerShell 7, comments and trailing commas) and keeps only the last of duplicate keys; a strict
    # record must not hide one, so this runs on the text before ConvertFrom-Json does.
    $token = [regex]'\G[ \t\n\r]*(?:"(?:[^"\\\x00-\x1F]|\\["\\/bfnrt]|\\u[0-9A-Fa-f]{4})*"|-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?|true|false|null|[{}\[\],:])'
    $p = @{ T = [Collections.Generic.List[string]]::new(); I = 0 }
    $at = 0
    for ($m = $token.Match($Text); $m.Success; $m = $m.NextMatch()) { $p.T.Add($m.Value.TrimStart(" `t`n`r")); $at += $m.Length }
    if ($Text.Substring($at) -notmatch '^[ \t\n\r]*$') { throw "not strict JSON at character $at" }
    function Step { $t = if ($p.I -lt $p.T.Count) { $p.T[$p.I] } else { '' }; $p.I++; $t }
    function Read-Value {
        $t = Step
        if ($t -ceq '{') {
            $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
            $t = Step
            if ($t -ceq '}') { return }
            while ($true) {
                if (-not $t.StartsWith('"')) { throw 'not strict JSON: an object key must be a double-quoted string' }
                $name = [regex]::Unescape($t.Substring(1, $t.Length - 2))
                if (-not $names.Add($name)) { throw "duplicate key '$name'" }
                if ((Step) -cne ':') { throw "not strict JSON: ':' expected after key '$name'" }
                Read-Value
                $t = Step
                if ($t -ceq '}') { return }
                if ($t -cne ',') { throw "not strict JSON: ',' or '}' expected" }
                $t = Step
            }
        }
        if ($t -ceq '[') {
            if ($p.I -lt $p.T.Count -and $p.T[$p.I] -ceq ']') { $p.I++; return }
            while ($true) {
                Read-Value
                $t = Step
                if ($t -ceq ']') { return }
                if ($t -cne ',') { throw "not strict JSON: ',' or ']' expected" }
            }
        }
        if ($t -ceq '' -or $t -cin '}', ']', ',', ':') { throw 'not strict JSON: a value expected' }
    }
    Read-Value
    if ($p.I -ne $p.T.Count) { throw 'not strict JSON: text after the value' }
}

function Read-SwGlobalBaseline([string]$Path) {
    # ~/.sw/global.json: the hash of each global block as delivered, per home. Strict: anything unexpected throws, so
    # install writes nothing and check reports FAILED. No file means no baselines.
    Assert-SwPhysicalPath $Path
    if (-not (Test-Path -LiteralPath $Path)) { return [ordered]@{ homes = [ordered]@{} } }
    $bad = "Invalid global baseline record (nothing is written while it is invalid): $Path"
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "$bad (not a file)" }
    $r = try {
        $text = Read-SwText $Path
        Assert-SwStrictJson $text
        ConvertFrom-SwJson $text
    } catch { throw "$bad ($($_.Exception.Message))" }
    if ($r -isnot [Collections.IDictionary] -or @($r.Keys | Where-Object { $_ -cnotin 'schema', 'kitVersion', 'kitCommit', 'homes' }).Count -or $r.Count -ne 4 -or
        $r['schema'] -isnot [long] -or $r['schema'] -ne 1 -or $r['homes'] -isnot [Collections.IDictionary] -or
        $r['kitVersion'] -isnot [string] -or ($null -ne $r['kitCommit'] -and $r['kitCommit'] -isnot [string])) { throw $bad }
    $seen = [Collections.Generic.HashSet[string]]::new((Get-SwPathComparer))
    foreach ($dir in $r['homes'].Keys) {
        $h = $r['homes'][$dir]
        if (-not (Test-SwFullyQualified $dir) -or [IO.Path]::GetFullPath($dir).TrimEnd([char[]]@([char]92, [char]47)) -cne $dir -or -not $seen.Add($dir) -or
            $h -isnot [Collections.IDictionary] -or $h.Count -ne 2 -or $h['entries'] -isnot [Collections.IDictionary] -or $h['entries'].Count -eq 0) { throw $bad }
        foreach ($k in $h['entries'].Keys) { if ($k -cnotin $script:GlobalEntry.Values -or $h['entries'][$k] -isnot [string] -or $h['entries'][$k] -cnotmatch '^[0-9a-f]{64}$') { throw $bad } }
        if ($h['kind'] -isnot [string] -or $h['kind'] -cne (Get-SwGlobalKind $h['entries'])) { throw $bad }
    }
    $r
}

function Move-SwFileReplace([string]$Source, [string]$Destination) {
    # One rename over the old file (.NET Framework has no overwriting File.Move). ReplaceFile can fail after moving the
    # old file aside; with a backup name the old file is kept there and put back, never lost. The backup is named after
    # the per-operation $Source, so a leftover one is never read as the file and never blocks a later write.
    if (-not [IO.File]::Exists($Destination)) { [IO.File]::Move($Source, $Destination); return }
    $backup = "$Source.bak"
    try { [IO.File]::Replace($Source, $Destination, $backup) }
    catch {
        $failed = $_.Exception.Message
        if (-not [IO.File]::Exists($Destination) -and [IO.File]::Exists($backup)) {
            try { [IO.File]::Move($backup, $Destination) }
            catch { throw "Replacing $Destination failed ($failed), and putting the old file back failed too ($($_.Exception.Message)); the old file is at $backup" }
        }
        throw
    }
    try { [IO.File]::Delete($backup) } catch { Write-Verbose "Kept the replaced copy $backup ($($_.Exception.Message))." }
}

function Write-SwFileAtomic([string]$Path, [string]$Content) {
    # A complete temp sibling, then one rename over the old file: a failed or interrupted write leaves the old file whole.
    Assert-SwPhysicalPath $Path
    $tmp = "$Path.$(Get-SwOperationId).tmp"
    Write-SwNewFile $tmp $Content
    try { Move-SwFileReplace $tmp $Path } catch { Remove-Item -LiteralPath $tmp -Force -Confirm:$false -ErrorAction SilentlyContinue; throw }
}

function Write-SwGlobalGuarded($State, [string]$Content, [switch]$CheckOnly) {
    # 'ok' when the file still holds exactly the judged text and (unless -CheckOnly) now holds $Content. One exclusive
    # handle serves the compare and the write, so no edit can land in between. 'changed' (a changed file, one open
    # elsewhere, or one that appeared where none was judged) and 'read-only' mean the file is kept, never overwritten.
    $file = $State.Target.File
    Assert-SwPhysicalPath $file
    $fs = $null
    try {
        try {
            if ($State.State -eq 'missing-file') {
                [IO.Directory]::CreateDirectory((Split-Path $file -Parent)) | Out-Null
                $fs = [IO.FileStream]::new($file, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            } else {
                # -CheckOnly only reads, so a read-only file holding a current block is still recorded.
                $fs = [IO.FileStream]::new($file, [IO.FileMode]::Open, $(if ($CheckOnly) { [IO.FileAccess]::Read } else { [IO.FileAccess]::ReadWrite }), [IO.FileShare]::None)
                $reader = [IO.StreamReader]::new($fs, [Text.Encoding]::UTF8, $true, 4096, $true)
                $now = $reader.ReadToEnd().Replace("`r`n", "`n"); $reader.Dispose()
                if ($now -cne $State.Text) { return 'changed' }
                if ($CheckOnly) { return 'ok' }
            }
        } catch [UnauthorizedAccessException] { return 'read-only' } catch [IO.IOException] { return 'changed' }
        # Past this point a failure is not a conflict: the file may be damaged, so it surfaces as a failure.
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Content.Replace("`r`n", "`n"))
        try {
            $fs.SetLength(0); $fs.Position = 0
            Write-SwStreamBytes $fs $bytes
        } catch { throw "FAILED writing $($file): $($_.Exception.Message)" }
        'ok'
    } finally { if ($fs) { try { $fs.Dispose() } catch { } } }
}

function Write-SwStreamBytes([IO.FileStream]$Stream, [byte[]]$Bytes) { $Stream.Write($Bytes, 0, $Bytes.Length); $Stream.Flush($true) }

function Get-SwGlobalTargets([Collections.IDictionary]$Paths) {
    # The global rules block in every targeted home: Claude Code (<home>/CLAUDE.md) and Codex (<home>/AGENTS.md).
    foreach ($c in $Paths.Claude) { [pscustomobject]@{ Kind = 'claude'; Dir = $c.Dir; Origin = $c.Origin; File = Join-Path $c.Dir 'CLAUDE.md'; Key = $script:GlobalEntry.claude; Include = $(if (Test-Path -LiteralPath (Join-Path $c.Dir 'RTK.md')) { "@RTK.md`n`n" } else { '' }) } }
    foreach ($c in $Paths.Codex) { [pscustomobject]@{ Kind = 'codex'; Dir = $c.Dir; Origin = $c.Origin; File = Join-Path $c.Dir 'AGENTS.md'; Key = $script:GlobalEntry.codex; Include = '' } }
}

function Get-SwGlobalState($Target, [Collections.IDictionary]$Record, [string]$Hash) {
    # Read-only judgement of one global block against the current rules hash, its baseline and the shipped list.
    $s = [pscustomobject]@{ Target = $Target; State = $null; Text = ''; Error = $null; Baseline = $null }
    $k = Find-SwGlobalHome $Record['homes'] $Target.Dir
    if ($null -ne $k) { $s.Baseline = $Record['homes'][$k]['entries'][$Target.Key] }
    try { Assert-SwPhysicalPath $Target.File } catch { $s.State = 'foreign-type'; $s.Error = $_.Exception.Message; return $s }
    if (Test-Path -LiteralPath $Target.File -PathType Container) { $s.State = 'foreign-type'; $s.Error = "not a file: $($Target.File)"; return $s }
    if (-not (Test-Path -LiteralPath $Target.File)) { $s.State = 'missing-file'; return $s }
    $s.Text = Read-SwText $Target.File
    $b, $e = '<!-- sw:begin global -->', '<!-- sw:end global -->'
    try { Assert-SwBlockWellFormed $s.Text 'global' $b $e } catch { $s.State = 'malformed'; $s.Error = "$($_.Exception.Message) in $($Target.File)"; return $s }
    $start = $s.Text.IndexOf($b)
    if ($start -lt 0) { $s.State = 'missing-block'; return $s }
    $start += $b.Length
    $have = Get-SwHash $s.Text.Substring($start, $s.Text.IndexOf($e) - $start)
    # No trust on first use: without a baseline only a byte-identical shipped version counts as unedited.
    $s.State = if ($have -ceq $Hash) { 'current' } elseif ($s.Baseline) { if ($have -ceq $s.Baseline) { 'stale' } else { 'edited' } }
    elseif ($have -cin $script:GlobalShipped) { 'stale-shipped' } else { 'unverified' }
    $s
}

function Get-SwGlobalPlan([Collections.IDictionary]$Paths, [string]$Hash) {
    # Read-only judgement of the record and every target. A missing named home, a broken or foreign record, or a malformed
    # or foreign target throws, so the whole run stops with nothing written. RecordText is $null when no record exists.
    Assert-SwGlobalHomes $Paths
    $recordPath = Join-Path $Paths.Home '.sw/global.json'
    $text = if (Test-Path -LiteralPath $recordPath -PathType Leaf) { Read-SwText $recordPath } else { $null }
    $record = Read-SwGlobalBaseline $recordPath
    $plan = @(foreach ($t in Get-SwGlobalTargets $Paths) { Get-SwGlobalState $t $record $Hash })
    $stop = @($plan | Where-Object State -In 'malformed', 'foreign-type')
    if ($stop.Count) { throw "Global rules block cannot be judged, nothing was written: $(($stop | ForEach-Object Error) -join '; ')" }
    [pscustomobject]@{ RecordPath = $recordPath; RecordText = $text; Record = $record; Plan = $plan }
}

function Install-SwGlobal {
    [CmdletBinding(SupportsShouldProcess)]
    param([switch]$InstallRtk, [string[]]$ClaudeConfigDir, [string[]]$CodexHome)
    $p = Get-SwGlobalPaths $ClaudeConfigDir $CodexHome
    $rules = Read-SwText (Join-Path $script:Kit 'global/rules.md')
    $hash = Get-SwHash (Get-SwGlobalBody $rules)
    # Read-only preflight before consent: anything broken stops the whole run here, with nothing created.
    $pre = Get-SwGlobalPlan $p $hash
    $recordPath = $pre.RecordPath; $record = $pre.Record; $plan = $pre.Plan

    # Consent for the record precedes every effect (lock, backup, blocks): a declined run or -WhatIf creates nothing.
    $apply = $PSCmdlet.ShouldProcess($recordPath, 'write global rules blocks, then record their baselines')
    if (-not $apply -and -not $WhatIfPreference) { Write-Warning 'PARTIAL: baseline record write declined; no global rules block written.'; $global:LASTEXITCODE = 1; return }
    # One install at a time per user home, from here through the final record replace, so concurrent runs cannot drop
    # each other's entries. Created new and deleted on close: a run never opens or removes another run's lock.
    $lock = $null
    if ($apply) {
        $lockPath = Join-Path $p.Home '.sw/global.lock'
        Assert-SwPhysicalPath $lockPath
        [IO.Directory]::CreateDirectory((Split-Path $lockPath -Parent)) | Out-Null
        $lock = try { [IO.FileStream]::new($lockPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None, 1, [IO.FileOptions]::DeleteOnClose) }
        catch [IO.IOException] { throw "Another global install holds $lockPath, nothing was written. If none is running, delete that file and retry." }
    }
    try {
        if ($lock) {
            # Judge everything again under the lock, before backup or any write: a record or target that became broken
            # stops the whole run; a changed record means another install ran; a target changed since preflight is kept.
            $now = Get-SwGlobalPlan $p $hash
            if ($now.RecordText -cne $pre.RecordText) {
                throw "The global baseline record changed after it was read (another install ran), nothing was written: $recordPath. Run global install again."
            }
            for ($i = 0; $i -lt $plan.Count; $i++) {
                if ($now.Plan[$i].State -ne $plan[$i].State -or $now.Plan[$i].Text -cne $plan[$i].Text) { $plan[$i].State = 'changed' }
            }
        }
        $b = Backup-SwGlobal -ClaudeConfigDir $ClaudeConfigDir -CodexHome $CodexHome
        if ($b.Partial) { Write-Warning 'PARTIAL: required global backup declined; no replacement performed.'; $global:LASTEXITCODE = 1; return }
        Write-Output "Backup: $($b.Path) ($($b.Files.Count) files; files named like credentials are skipped by name only, contents are not scanned)"
        # Not [ordered]@{} (always case-insensitive): off Windows, /a and /A are distinct homes with distinct entries.
        $homes = [Collections.Specialized.OrderedDictionary]::new((Get-SwPathComparer))
        foreach ($k in $record['homes'].Keys) {
            $entries = [Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal)
            foreach ($e in $record['homes'][$k]['entries'].GetEnumerator()) { $entries[$e.Key] = $e.Value }
            $homes[$k] = [ordered]@{ kind = $record['homes'][$k]['kind']; entries = $entries }
        }
        $setEntry = {
            param($t)
            $k = Find-SwGlobalHome $homes $t.Dir
            if ($null -eq $k) { $k = $t.Dir; $homes[$k] = [ordered]@{ kind = ''; entries = [Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal) } }
            $homes[$k]['entries'][$t.Key] = $hash
            $homes[$k]['kind'] = Get-SwGlobalKind $homes[$k]['entries']
        }
        # Right before a block is written or recorded, the file must still hold exactly the text that was judged
        # (Write-SwGlobalGuarded). An edit made while a prompt was open (and possibly after the backup) is kept, never overwritten.
        $partial = $false; $kept = 0
        foreach ($s in $plan) {
            $t = $s.Target; $file = $t.File
            $write = $s.State -in 'missing-file', 'missing-block', 'stale', 'stale-shipped'
            if ($s.State -eq 'current' -or ($write -and $PSCmdlet.ShouldProcess($file, 'set global rules block'))) {
                $base = if (-not $s.Text -and $t.Include) { $t.Include } else { $s.Text }
                # A failed write stops the run before the record is written, so that entry is never recorded.
                $result = try { if ($write) { Write-SwGlobalGuarded $s (Set-SwBlock $base 'global' $rules) } else { Write-SwGlobalGuarded $s -CheckOnly } }
                catch { throw "$($_.Exception.Message). Its prior content is in the pre-install snapshot $($b.Path); the run stopped and its baseline was not recorded." }
                if ($result -ne 'ok') { $s.State = $result }
                elseif ($write) {
                    & $setEntry $t
                    Write-Output "$($t.Kind) global rules ($($s.State)): $file"
                    if ($s.State -eq 'missing-block' -and $s.Text) { Write-Output "Note: $file keeps its earlier unmanaged text above the block (it is also in the backup)." }
                } else { & $setEntry $t }
            } elseif ($write -and -not $WhatIfPreference) { $partial = $true }
            if ($s.State -eq 'changed') {
                $kept++
                Write-Output "Kept $($file): it changed while install was running, or is open elsewhere; run global install again to judge it."
            }
            if ($s.State -eq 'read-only') {
                # Install never clears a read-only attribute or changes permissions.
                $kept++
                Write-Output "Kept $($file): it is read-only (or not writable); make it writable, then run global install again."
            }
            if ($s.State -in 'edited', 'unverified') {
                # A7: an installed copy that was edited, or cannot be shown unedited, is never overwritten. No switch bypasses this.
                $kept++
                $why = if ($s.State -eq 'edited') { 'was edited after install' } else { 'cannot be shown unedited (no baseline, and it matches no shipped version)' }
                Write-Output "Kept $($file): its global rules block $why."
                $incoming = Join-Path $b.Path "incoming/$($t.Kind)-$((Get-SwHash $t.Dir).Substring(0, 12))/$(Split-Path $file -Leaf)"
                if ($PSCmdlet.ShouldProcess($incoming, 'write incoming global rules version')) {
                    Write-SwNewFile $incoming (Set-SwBlock $s.Text 'global' $rules)
                    Write-Output "  Compare: git diff --no-index `"$file`" `"$incoming`""
                }
                Write-Output '  Resolve: move the edit to the central source (personal lines outside the block, rule changes into the kit''s global/rules.md),'
                Write-Output '  delete the block from <!-- sw:begin global --> through <!-- sw:end global -->, then run global install again.'
            }
        }
        if ($apply) {
            $new = [ordered]@{ schema = 1; kitVersion = Get-SwKitVersion; kitCommit = Get-SwKitCommit; homes = $homes }
            Write-SwFileAtomic $recordPath (ConvertTo-SwJson $new)
        }
    } finally { if ($lock) { $lock.Dispose() } }

    # RTK is optional; the kit installs it only when asked to (-InstallRtk).
    $rtk = Get-SwToolVersion rtk
    if (-not $rtk -or $rtk -lt [version]'0.48.0') {
        if ($InstallRtk) {
            if ($PSCmdlet.ShouldProcess('rtk-ai.rtk', 'winget install')) { & winget install --id rtk-ai.rtk --exact --accept-source-agreements --accept-package-agreements }
        } else { Write-Output 'rtk missing or older than 0.48 (optional; not installed). Install it yourself (winget install --id rtk-ai.rtk --exact), or re-run with -InstallRtk.' }
    }
    Test-SwGlobal -ClaudeConfigDir $ClaudeConfigDir -CodexHome $CodexHome
    if ($kept) { Write-Warning "PARTIAL: $kept edited, unverified, changed or read-only global rules block(s) kept; see the notes above." }
    if ($partial) { Write-Warning 'PARTIAL: a global rules block write was declined.' }
    if ($kept -or $partial) { $global:LASTEXITCODE = 1 }
}

function Test-SwGlobal {
    [CmdletBinding()]
    param([string[]]$ClaudeConfigDir, [string[]]$CodexHome)
    $p = Get-SwGlobalPaths $ClaudeConfigDir $CodexHome
    $rows = [Collections.Generic.List[object]]::new()
    $add = { param($n, $state, $detail) $rows.Add([pscustomobject]@{ Item = $n; State = $state; Detail = $detail }) }
    & $add 'PowerShell' 'OK' $PSVersionTable.PSVersion.ToString()
    $probes = @{}
    foreach ($t in @(@('git', $true), @('gh', $false), @('rtk', $false), @('t3', $false), @('claude', $false), @('codex', $false))) {
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
    # Rows per targeted home; the detail names the file and where the home came from (parameter, env or default).
    # Read-only: the baseline record is read, never created or changed.
    $hash = Get-SwHash (Get-SwGlobalBody (Read-SwText (Join-Path $script:Kit 'global/rules.md')))
    $recordError = $null
    $record = try { Read-SwGlobalBaseline (Join-Path $p.Home '.sw/global.json') } catch { $recordError = $_.Exception.Message; [ordered]@{ homes = [ordered]@{} } }
    foreach ($t in Get-SwGlobalTargets $p) {
        $s = Get-SwGlobalState $t $record $hash
        $where = "$($t.File) ($($t.Origin))"
        $state, $detail = if ($recordError) { 'FAILED', "$where; $recordError" } else {
            switch ($s.State) {
                'current' { 'OK', $where }
                { $_ -in 'missing-file', 'missing-block' } { 'WARN', "$where; missing, run global install" }
                { $_ -in 'stale', 'stale-shipped' } { 'WARN', "$where; outdated, run global install" }
                'edited' { 'WARN', "$where; edited locally, install keeps it: move the edit to the central source, delete the block, run global install" }
                'unverified' { 'WARN', "$where; cannot be shown unedited, install keeps it: move any edit to the central source, delete the block, run global install" }
                default { 'FAILED', "$where; $($s.State): $($s.Error)" }
            }
        }
        & $add "$($t.Kind) rules" $state $detail
        if ($t.Kind -ne 'claude') { continue }
        # User-owned settings are reported, never rewritten by install.
        $settings = Join-Path $t.Dir 'settings.json'
        $settingsText = if (Test-Path -LiteralPath $settings -PathType Leaf) { Read-SwText $settings } else { '' }
        $broad = $settingsText -match '"Bash\(gh( \*|:\*)?\)"'
        & $add 'claude gh allow' $(if ($broad) { 'WARN' } else { 'OK' }) $(if ($broad) { "broad gh allow permits gh writes; suggested: use read-only rules such as Bash(gh pr view:*) instead ($settings)" } else { "read-only ($settings)" })
    }
    # ~/AGENTS.md include pointing at a missing ~/RTK.md (left by an RTK setup); reported, never rewritten.
    if (Test-Path -LiteralPath $p.HomeAgents -PathType Leaf) {
        $h = Split-Path $p.HomeAgents -Parent
        if ((Read-SwText $p.HomeAgents) -match '(?m)^@RTK\.md\s*$' -and -not (Test-Path -LiteralPath (Join-Path $h 'RTK.md')) -and (Test-Path -LiteralPath $p.HomeRtk)) {
            & $add 'home RTK include' 'WARN' "@RTK.md points at a missing file; suggested: change the line to @.claude/RTK.md ($($p.HomeAgents))"
        }
    }
    $rows | Format-Table -AutoSize | Out-String -Width 300 | Write-Output
    $global:LASTEXITCODE = if (@($rows | Where-Object State -in 'MISSING', 'FAILED').Count) { 1 } else { 0 }
}

function Invoke-SwGlobal {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Position = 0)][ValidateSet('install', 'check', 'backup')][string]$Action = 'check', [switch]$InstallRtk,
        [string[]]$ClaudeConfigDir, [string[]]$CodexHome)
    $homes = @{ ClaudeConfigDir = $ClaudeConfigDir; CodexHome = $CodexHome }
    switch ($Action) {
        'install' { Install-SwGlobal -InstallRtk:$InstallRtk @homes }
        'check' { Test-SwGlobal @homes }
        'backup' {
            $b = Backup-SwGlobal @homes
            Write-Output "Backup: $($b.Path)"
            foreach ($h in $b.Homes) {
                $files = @($b.Items | Where-Object Home -EQ $h)
                Write-Output "  $($h):$(if (-not $files.Count) { ' nothing to back up (no file install may edit is present)' })"
                $files | ForEach-Object { Write-Output "    $($_.Rel)" }
            }
        }
    }
}

Export-ModuleMember -Function Set-SwBlock, Get-SwRender, Sync-SwProject, Format-SwPlan, Initialize-SwProject, Update-SwProject,
    Backup-SwGlobal, Install-SwGlobal, Test-SwGlobal, Invoke-SwGlobal, Get-SwKitVersion, Get-SwKitCommit, Compare-SwVersion, Format-SwSelection
