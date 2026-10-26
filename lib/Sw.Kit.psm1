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
    if ($LASTEXITCODE -ne 0 -or (-not (Test-SwSame ("$prefix".Trim()) '' -IgnoreCase))) { return $null }
    $sha = Invoke-SwNative git @('-C', $script:Kit, 'rev-parse', 'HEAD')
    if ($LASTEXITCODE -eq 0 -and $sha) { "$sha".Trim() } else { $null }
}

function Compare-SwVersion([string]$A, [string]$B) {
    # -1, 0 or 1 for X.Y.Z[-tag]; a tagged build (0.3.0-dev) is older than the release (0.3.0).
    $pa, $pb = foreach ($v in $A, $B) {
        if ($v -notmatch '^(\d+)\.(\d+)\.(\d+)(?:-(.+))?$') { throw "Not a kit version (X.Y.Z or X.Y.Z-tag): '$v'" }
        , @([int]$Matches[1], [int]$Matches[2], [int]$Matches[3], $Matches[4])
    }
    for ($i = 0; $i -lt 3; $i++) { if ([int]$pa[$i] -ne [int]$pb[$i]) { return $(if ($pa[$i] -lt $pb[$i]) { -1 } else { 1 }) } }
    if (Test-SwSame $pa[3] $pb[3]) { return 0 }
    if (-not $pa[3]) { return 1 }
    if (-not $pb[3]) { return -1 }
    [Math]::Sign([string]::CompareOrdinal($pa[3], $pb[3]))
}

# Kit-side renames (old path -> new path). An edited old file moves with its edit.
# A key ending in '/' is a prefix rule, expanded per-file against the old manifest (Sync-SwProject).
$script:Moved = [ordered]@{ '.opencode/skills/' = '.agents/skills/' }

function Assert-SwBlockWellFormed([string]$Text, [string]$Name, [string]$Begin, [string]$End) {
    # Absent is fine; present must be exactly one begin followed by exactly one end. Markers match ordinally.
    $b = $Text.IndexOf($Begin, [StringComparison]::Ordinal); $e = $Text.IndexOf($End, [StringComparison]::Ordinal)
    if ($b -lt 0 -and $e -lt 0) { return }
    if ($b -lt 0) { throw "Malformed managed block '$Name': '$End' without '$Begin'" }
    if ($e -lt 0) { throw "Unterminated managed block '$Name' (found '$Begin' without '$End')" }
    if ($e -lt $b) { throw "Malformed managed block '$Name': '$End' before '$Begin'" }
    if ($Text.LastIndexOf($Begin, [StringComparison]::Ordinal) -ne $b -or $Text.LastIndexOf($End, [StringComparison]::Ordinal) -ne $e) { throw "Malformed managed block '$Name': repeated markers" }
}

function Set-SwBlock([string]$Text, [string]$Name, [string]$Body, [ValidateScript({ Test-SwIn $_ 'md', 'hash' -IgnoreCase })][string]$Style = 'md') {
    # Insert or replace one named managed block; everything outside it is left alone.
    $b, $e = if (Test-SwSame $Style 'md' -IgnoreCase) { "<!-- sw:begin $Name -->", "<!-- sw:end $Name -->" } else { "# sw:begin $Name", "# sw:end $Name" }
    $block = "$b`n$($Body.Trim("`n"))`n$e"
    Assert-SwBlockWellFormed $Text $Name $b $e
    $start = $Text.IndexOf($b, [StringComparison]::Ordinal)
    if ($start -ge 0) {
        $end = $Text.IndexOf($e, $start, [StringComparison]::Ordinal)
        if ($end -lt 0) { throw "Unterminated managed block '$Name' (found '$b' without '$e')" }
        return $Text.Substring(0, $start) + $block + $Text.Substring($end + $e.Length)
    }
    $sep = if (-not $Text) { '' } elseif ($Text.EndsWith("`n`n", [StringComparison]::Ordinal)) { '' } elseif ($Text.EndsWith("`n", [StringComparison]::Ordinal)) { "`n" } else { "`n`n" }
    $Text + $sep + $block + "`n"
}

function Get-SwBlockBody([string]$Text, [string]$Name) {
    $b = "<!-- sw:begin $Name -->"; $e = "<!-- sw:end $Name -->"
    $s = $Text.IndexOf($b, [StringComparison]::Ordinal); $t = $Text.IndexOf($e, [StringComparison]::Ordinal)
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
            if (Test-SwSame $rel 'AGENTS.md' -IgnoreCase) { continue }
            $files[$rel] = (Read-SwText $f.FullName).Replace('{{PROJECT}}', $Config['project'])
        }
    }
    & $add (Join-Path $script:Kit 'project/base')
    & $add (Join-Path $profileDir 'files')
    if ($Config['github'] -ne $false) { & $add (Join-Path $script:Kit 'project/github') }
    # New init explicitly selects local; absent stays tracked for legacy configurations.
    $local = $Config.Contains('records') -and (Test-SwSame $Config['records'] 'local')
    if ($Config.Contains('records') -and (-not (Test-SwIn $Config['records'] ('tracked', 'local')))) { throw "Config 'records' must be 'tracked' or 'local', not '$($Config['records'])'" }
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
            if ($rel -match '^\.agents/skills/([^/]+)/' -and (Test-SwIn $Matches[1] $known.skills) -and (-not (Test-SwIn $Matches[1] $selection.skills))) { $files.Remove($rel) }
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

    # central-v1 stops generating only the selected product skill copies (Central); profile skills and everything else stay.
    $delivery = Get-SwSkillDelivery $Config
    $central = @(if ($selection) { Get-SwCentralSkillIds $selection $profileData })
    if (Test-SwSame $delivery 'central-v1') {
        if (-not $selection) { throw 'skillDelivery central-v1 needs selection v1; run update <path> -SelectionV1 first. Nothing was written.' }
        foreach ($rel in @($files.Keys)) { if ($rel -match '^\.agents/skills/([^/]+)/' -and (Test-SwIn $Matches[1] $central)) { $files.Remove($rel) } }
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
    if (Test-SwSame $gitPolicy 'host' -IgnoreCase) {
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
        Delivery       = $delivery
        Central        = $central
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
    $drop = @($Render.Known.skills | Where-Object { -not (Test-SwIn $_ $Render.Selection.skills) })
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
            foreach ($f in Get-SwUnique (@($onDisk) + @($owned.Keys | Where-Object { $_.StartsWith("$rel/", [StringComparison]::Ordinal) })) | Sort-Object) {
                $path = Join-Path $Root $f
                if (Test-SwLinkedPath $Root $f) { $blocked.Add("$f (linked)"); continue }
                if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
                if (-not $owned.Contains($f)) { $blocked.Add("$f (unowned or unverified)"); continue }
                if (-not (Test-SwSame (Get-SwHash (Read-SwText $path)) $owned[$f])) { $blocked.Add("$f (modified)") }
            }
        }
    }
    if ($blocked.Count) {
        throw "Selection change blocked; nothing was written. Resolve these deselected components yourself (separately authorized), then re-run; -Force and -Adopt cannot bypass this:`n  $((Get-SwUnique $blocked) -join "`n  ")"
    }
}

function Test-SwCentralCopy([string]$Path, [string[]]$Ids) {
    # A kit copy of a central-eligible skill in either generated skill directory (never project/ sources).
    ($Path -match '^\.(agents|claude)/skills/([^/]+)/') -and (Test-SwIn $Matches[2] $Ids)
}

function Assert-SwDeliveryTransition([string]$Root, $Render, [string]$From) {
    # Preflight in both skill trees before anything is removed or restored: only complete, unchanged, owned copies may
    # convert. Edited, unowned, extra, linked or nested-link content blocks the whole run. -Force/-Adopt never reach this.
    $restore = (Test-SwSame $From 'central-v1') -and -not (Test-SwSame $Render.Delivery 'central-v1')
    if (-not ($restore -or (Test-SwSame $Render.Delivery 'central-v1'))) { return }
    $blocked = [Collections.Generic.List[string]]::new()
    $manifestPath = Join-Path $Root '.sw/manifest.json'
    $owned = if (Test-Path -LiteralPath $manifestPath -PathType Leaf) { (Read-SwJson $manifestPath)['files'] } else { $null }
    if ($owned -isnot [Collections.IDictionary]) { $owned = @{} }
    foreach ($dir in '.agents/skills', '.claude/skills') {
        foreach ($id in $Render.Central) {
            $rel = "$dir/$id"
            if (Test-SwLinkedPath $Root $rel) { $blocked.Add("$rel (linked: ownerless link; left as found)"); continue }
            $full = Join-Path $Root $rel
            if (-not (Test-Path -LiteralPath $full)) { continue }
            $found = try { @(Get-SwPhysicalFiles $full) } catch { $blocked.Add("$rel (nested link)"); continue }
            $files = @($found | ForEach-Object { "$rel/$((Get-SwRelativePath $full $_.FullName).Replace('\', '/'))" })
            $mine = @($files | Where-Object { $owned.Contains($_) })
            foreach ($f in $files | Sort-Object) {
                if ($owned.Contains($f)) {
                    if (-not (Test-SwSame (Get-SwHash (Read-SwText (Join-Path $Root $f))) $owned[$f] -IgnoreCase)) { $blocked.Add("$f (changed baseline: differs from its ownership record)") }
                }
                elseif ($restore) { $blocked.Add("$f (collision: project-owned entry; never replaced, renamed or overridden)") }
                elseif (-not $mine.Count) { $blocked.Add("$f (project-owned skill with the same name; never renamed or overridden)") }
                else { $blocked.Add("$f (extra: not in the ownership record)") }
            }
        }
    }
    if ($blocked.Count) {
        throw "Skill delivery change blocked; nothing was written. Resolve these yourself (separately authorized), then re-run; -Force and -Adopt cannot bypass this:`n  $((Get-SwUnique $blocked) -join "`n  ")"
    }
}

function Get-SwConsentObservation([string]$Path) {
    $exists = Test-Path -LiteralPath $Path
    [pscustomobject]@{ Exists = $exists; Bytes = $(if ($exists) { ,([IO.File]::ReadAllBytes($Path)) } else { $null }) }
}

function Test-SwConsentFreshness([string]$Root, [string[]]$Paths, $Observed, $Item) {
    foreach ($rel in $Paths) {
        $now = Get-SwConsentObservation (Resolve-SwManagedPath $Root $rel)
        $before = $Observed[$rel]
        if ($now.Exists -ne $before.Exists -or ($now.Exists -and
            (-not (Test-SwSame ([Convert]::ToBase64String([byte[]]$now.Bytes)) ([Convert]::ToBase64String([byte[]]$before.Bytes)))))) {
            $Item.Action = 'stale'
            $Item.Note = @($Item.Note, "$rel changed while consent was pending and was left as found.") -ne $null -join "`n  "
            return $false
        }
    }
    # This is a bounded reobservation, not a lock against changes between this check and the effect.
    $true
}

function Get-SwManagedContent([string]$Root, $Render, $Observed = $null) {
    # Pure and validation-first: every managed-block replacement for files the project also owns, or a throw.
    # Nothing is written, so a malformed block or an unsafe LFS transition stops the operation before any change.
    $agentsPath = Join-Path $Root 'AGENTS.md'
    if ($null -ne $Observed) { $Observed['AGENTS.md'] = Get-SwConsentObservation $agentsPath }
    $agents = if (Test-Path -LiteralPath $agentsPath) { Set-SwBlock (Read-SwText $agentsPath) 'core' $Render.AgentsCore } else { $Render.AgentsTemplate }
    $agents = Set-SwBlock $agents 'profile' $Render.AgentsProfile
    $agentsNote = $null
    if ($agents -cnotmatch '(?m)^## Project identity\s*$') {
        # An adopted AGENTS.md lacks the project sections: insert the template's above the core block.
        $t = $Render.AgentsTemplate
        $from = $t.IndexOf("`n", [StringComparison]::Ordinal) + 1
        $sections = $t.Substring($from, $t.IndexOf('<!-- sw:begin core -->', [StringComparison]::Ordinal) - $from).Trim("`n") + "`n`n"
        $at = $agents.IndexOf('<!-- sw:begin core -->', [StringComparison]::Ordinal)
        $agents = $agents.Substring(0, $at) + $sections + $agents.Substring($at)
        $agentsNote = 'fill Project identity (and the other inserted project sections) in AGENTS.md'
    }
    $blocks = [ordered]@{ 'AGENTS.md' = $agents }
    $gi = Join-Path $Root '.gitignore'
    if ($null -ne $Observed) { $Observed['.gitignore'] = Get-SwConsentObservation $gi }
    $blocks['.gitignore'] = Set-SwBlock $(if (Test-Path -LiteralPath $gi) { Read-SwText $gi } else { '' }) 'superworkspace' $Render.GitIgnore 'hash'
    # .gitattributes is inspected even when the profile has no LFS rules, so a retained or malformed managed block is seen.
    $ga = Join-Path $Root '.gitattributes'
    if ($null -ne $Observed) { $Observed['.gitattributes'] = Get-SwConsentObservation $ga }
    $gaText = if (Test-Path -LiteralPath $ga) { Read-SwText $ga } else { '' }
    $gaBegin = '# sw:begin superworkspace'; $gaEnd = '# sw:end superworkspace'
    Assert-SwBlockWellFormed $gaText 'superworkspace' $gaBegin $gaEnd
    $gaStart = $gaText.IndexOf($gaBegin, [StringComparison]::Ordinal)
    if ($gaStart -ge 0) {
        $old = $gaText.Substring($gaStart + $gaBegin.Length, $gaText.IndexOf($gaEnd, [StringComparison]::Ordinal) - $gaStart - $gaBegin.Length) -split "`n"
        $new = @($Render.GitAttributes -split "`n")
        $dropped = @($old | Where-Object { $_ -match 'filter=lfs' -and (-not (Test-SwIn $_ $new)) })
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
            if (-not (Test-SwSame $rel 'AGENTS.md')) { $null = $allowed.Add($rel) }
        }
    }
    $null = $allowed.Add('.sw/selection.json')
    foreach ($rel in Get-SwRetiredOutputs) { $null = $allowed.Add($rel) }
    # Every skill file, current or retired, also has its generated Claude copy.
    foreach ($rel in @($allowed)) { if ($rel.StartsWith('.agents/skills/', [StringComparison]::Ordinal)) { $null = $allowed.Add(".claude/skills/$($rel.Substring('.agents/skills/'.Length))") } }
    foreach ($move in $script:Moved.GetEnumerator()) {
        if (-not $move.Key.EndsWith('/', [StringComparison]::Ordinal)) { if ($allowed.Contains($move.Value)) { $null = $allowed.Add($move.Key) }; continue }
        foreach ($rel in @($allowed)) { if ($rel.StartsWith($move.Value, [StringComparison]::Ordinal)) { $null = $allowed.Add($move.Key + $rel.Substring($move.Value.Length)) } }
    }
    , $allowed
}

function Read-SwManifest([string]$Root, $Allowed) {
    $path = Resolve-SwManagedPath $Root '.sw/manifest.json'
    if (-not (Test-Path -LiteralPath $path)) { return @{ files = [ordered]@{} } }
    $record = Read-SwJson $path
    if ($record -isnot [Collections.IDictionary] -or $record['files'] -isnot [Collections.IDictionary] -or @($record.Keys | Where-Object { -not (Test-SwIn $_ ('kitVersion', 'kitCommit', 'files')) }).Count) { throw 'Invalid project ownership manifest; nothing was written.' }
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
        [switch]$Force, [switch]$Preflight, [string]$FromDelivery)
    $render = Get-SwRender $Config
    Assert-SwPhysicalPath $Root
    foreach ($rel in @($render.Files.Keys) + @('AGENTS.md', '.gitignore', '.gitattributes', '.sw/config.json', '.sw/profile.json', '.claude/.sw-generated')) { $null = Resolve-SwManagedPath $Root $rel }
    $manifestPath = Resolve-SwManagedPath $Root '.sw/manifest.json'
    # Before the manifest's own path checks, so a linked or changed skill copy is named as a delivery blocker.
    Assert-SwDeliveryTransition $Root $render $FromDelivery
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
        if (-not $m.Key.EndsWith('/', [StringComparison]::Ordinal)) { $moved[$m.Key] = $m.Value; continue }
        foreach ($k in @($old.Keys)) { if ($k.StartsWith($m.Key, [StringComparison]::Ordinal)) { $moved[$k] = $m.Value + $k.Substring($m.Key.Length) } }
    }
    # An edited file at a moved path moves with its edit: its manifest hash follows it to the new path.
    $movedFrom = @{}
    $observed = @{}
    foreach ($m in $moved.GetEnumerator()) {
        $src = Join-Path $Root $m.Key
        if (-not $old.Contains($m.Key) -or $old.Contains($m.Value) -or $render.Files.Contains($m.Key) -or -not $render.Files.Contains($m.Value)) { continue }
        $observed[$m.Key] = Get-SwConsentObservation $src
        $observed[$m.Value] = Get-SwConsentObservation (Join-Path $Root $m.Value)
        if (-not (Test-Path -LiteralPath $src) -or (Test-Path -LiteralPath (Join-Path $Root $m.Value))) { continue }
        if (Test-SwSame (Get-SwHash (Read-SwText $src)) $old[$m.Key] -IgnoreCase) { continue }  # unedited: plain remove + add
        $movedFrom[$m.Value] = $m.Key
        $old[$m.Value] = $old[$m.Key]
        $old.Remove($m.Key)
    }
    $plan = [Collections.Generic.List[object]]::new()
    foreach ($e in $render.Files.GetEnumerator()) {
        $target = Join-Path $Root $e.Key
        if (-not $observed.ContainsKey($e.Key)) { $observed[$e.Key] = Get-SwConsentObservation $target }
        $current = if ($movedFrom.Contains($e.Key)) { Join-Path $Root $movedFrom[$e.Key] } else { $target }
        $newHash = Get-SwHash $e.Value
        $known = $old.Contains($e.Key)
        $action = if (-not (Test-Path -LiteralPath $current)) { 'add' }
        else {
            $cur = Get-SwHash (Read-SwText $current)
            if (Test-SwSame $cur $newHash -IgnoreCase) { 'same' }
            elseif ($known -and (Test-SwSame $cur $old[$e.Key] -IgnoreCase)) { 'update' }
            elseif ($known -and (Test-SwSame $newHash $old[$e.Key] -IgnoreCase)) { 'kept-local' }  # edited, but the kit did not change it
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
        if (-not $observed.ContainsKey($rel)) { $observed[$rel] = Get-SwConsentObservation $target }
        # An edited retired output (OpenCode, roles, manager, merged skills): ownership is released once, the file stays,
        # and later updates do not report it as unresolved. A retired skill stays in a discovery directory, so it loads.
        $action = if (-not (Test-Path -LiteralPath $target)) { 'gone' } elseif (Test-SwSame (Get-SwHash (Read-SwText $target)) $old[$rel] -IgnoreCase) { 'remove' } elseif (Test-SwIn $rel $retired) { 'released' } else { 'orphan-kept' }
        $note = if (-not (Test-SwSame $action 'released' -IgnoreCase)) { $null }
        elseif ($rel -match '^\.(agents|claude)/skills/') { "$rel kept as your own file: a retired kit skill with local edits, now project-owned and still discoverable, so Codex or Claude can load it; delete it or move it out of .agents/skills and .claude/skills to stop it loading" }
        else { "$rel kept as your own file: a retired kit output with local edits, no longer owned, generated or loaded" }
        $plan.Add([pscustomobject]@{ Path = $rel; Action = $action; Hash = $null; Note = $note })
    }
    $conflicts = @($plan | Where-Object { Test-SwSame $_.Action 'conflict' })
    if ($conflicts.Count) {
        throw "These files exist and are not SuperWorkspace-managed; nothing was written. Re-run with -Adopt to back them up to .sw/backup/ and replace them:`n  $(($conflicts.Path) -join "`n  ")"
    }

    # Validate the managed blocks before the first move, copy, removal or write.
    $managed = Get-SwManagedContent $Root $render $observed
    $opId = Get-SwOperationId
    $backupRoot = Join-Path $Root ".sw/backup/$opId"
    # Converting to central-v1 backs up every proven kit copy before the first removal.
    $converting = @(if (Test-SwSame $render.Delivery 'central-v1') { $plan | Where-Object { (Test-SwSame $_.Action 'remove') -and (Test-SwCentralCopy $_.Path $render.Central) } })
    # Any conversion or repair that removes copies, same-mode included, first proves central delivery.
    if ($converting.Count) { Assert-SwCentralReady $render.Central (Get-SwUserHome) }
    if (@($plan | Where-Object { Test-SwIn $_.Action 'adopt', 'skip-modified' -IgnoreCase }).Count -or $converting.Count) { Assert-SwPhysicalPath $backupRoot }
    # The same read-only plan guards init before directory creation or git init.
    if ($Preflight) {
        foreach ($b in $managed.Blocks.GetEnumerator()) {
            $target = Join-Path $Root $b.Key
            $same = (Test-Path -LiteralPath $target) -and (Test-SwSame (Read-SwText $target) $b.Value)
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
            $same = (Test-Path -LiteralPath $t) -and (Test-SwSame (Read-SwText $t) $b.Value)
            $plan.Add([pscustomobject]@{ Path = $b.Key; Action = $(if ($same) { 'same' } else { 'block' }); Hash = $null; Note = $null })
        }
        return $plan
    }
    # All removal consent precedes the first backup or removal; one decline leaves the project untouched.
    $consented = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($p in $converting) {
        if ($PSCmdlet.ShouldProcess($p.Path, 'remove (dropped from kit)')) { $null = $consented.Add($p.Path); continue }
        $p.Action = 'declined'; $global:LASTEXITCODE = 1
        Write-Warning 'PARTIAL: skill delivery removal declined; nothing was written (no backup, removal, ownership record or configuration).'
        return $plan
    }
    foreach ($p in $converting) {
        if (-not $reserved) { $null = New-SwSnapshotDir $backupRoot; $reserved = $true }
        Copy-SwNew (Resolve-SwManagedPath $Root $p.Path) (Join-Path $backupRoot $p.Path)
    }
    $partial = $false
    $manifest = [ordered]@{ kitVersion = $kitVersion; kitCommit = Get-SwKitCommit; files = $original }
    foreach ($p in $plan) {
        $target = Resolve-SwManagedPath $Root $p.Path
        if ($movedFrom.Contains($p.Path)) {
            $sourceRel = $movedFrom[$p.Path]
            if (-not $PSCmdlet.ShouldProcess($p.Path, "move from $sourceRel")) { $p.Action = 'declined'; $partial = $true; continue }
            $moveNote = $p.Note; $p.Note = $null
            if (-not (Test-SwConsentFreshness $Root @($sourceRel, $p.Path) $observed $p)) { $partial = $true; continue }
            $source = Resolve-SwManagedPath $Root $sourceRel
            New-Item -ItemType Directory -Force (Split-Path $target) -Confirm:$false | Out-Null
            Move-Item -LiteralPath $source -Destination $target -Force -Confirm:$false
            $p.Note = $moveNote
            $manifest.files.Remove($sourceRel); $manifest.files[$p.Path] = $old[$p.Path]
            # A later replacement prompt must compare against the move we just completed.
            $observed[$p.Path] = Get-SwConsentObservation $target
        }
        switch ($p.Action) {
            { Test-SwIn $_ 'add', 'update', 'adopt' -IgnoreCase } {
                if ($PSCmdlet.ShouldProcess($p.Path, $p.Action)) {
                    if (-not (Test-SwConsentFreshness $Root @($p.Path) $observed $p)) { $partial = $true; break }
                    if (Test-SwSame $p.Action 'adopt' -IgnoreCase) {
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
                if ($consented.Contains($p.Path) -or $PSCmdlet.ShouldProcess($p.Path, 'remove (dropped from kit)')) {
                    if (-not (Test-SwConsentFreshness $Root @($p.Path) $observed $p)) { $partial = $true; break }
                    $null = Resolve-SwManagedPath $Root $p.Path; Remove-Item -LiteralPath $target -Force -Confirm:$false; $manifest.files.Remove($p.Path)
                }
                else { $p.Action = 'declined'; $partial = $true }
            }
            { Test-SwIn $_ 'gone', 'released' -IgnoreCase } { $manifest.files.Remove($p.Path) }
            'orphan-kept' { $partial = $true }
        }
    }

    # Managed blocks in files the project also owns (content validated above).
    $blocks = $managed.Blocks
    $agentsNote = $managed.AgentsNote
    foreach ($b in $blocks.GetEnumerator()) {
        $t = Join-Path $Root $b.Key
        $same = (Test-Path -LiteralPath $t) -and (Test-SwSame (Read-SwText $t) $b.Value)
        $item = [pscustomobject]@{ Path = $b.Key; Action = $(if ($same) { 'same' } else { 'block' }); Hash = $null; Note = $(if (Test-SwSame $b.Key 'AGENTS.md' -IgnoreCase) { $agentsNote } else { $null }) }
        $plan.Add($item)
        if (-not $same) {
            if ($PSCmdlet.ShouldProcess($b.Key, 'set managed block')) {
                if (-not (Test-SwConsentFreshness $Root @($b.Key) $observed $item)) { $partial = $true; continue }
                $null = Resolve-SwManagedPath $Root $b.Key; Write-SwFile $t $b.Value
            }
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
    $changed = @($Plan | Where-Object { -not (Test-SwSame $_.Action 'same') })
    foreach ($a in Get-SwUnique @($changed | ForEach-Object { $_.Action })) { Write-Output ("{0,-14} {1}" -f $a, (@($changed | Where-Object { Test-SwSame $_.Action $a }).Path -join ', ')) }
    Write-Output ("{0} unchanged, {1} changed." -f @($Plan | Where-Object { Test-SwSame $_.Action 'same' }).Count, @($Plan | Where-Object { -not (Test-SwSame $_.Action 'same') }).Count)
    $orphans = @($Plan | Where-Object { Test-SwSame $_.Action 'orphan-kept' })
    if ($orphans.Count) { Write-Output "Dropped from the kit but locally modified, so left in place: $(($orphans.Path) -join ', ')" }
    if (@($Plan | Where-Object { Test-SwSame $_.Action 'skip-modified' }).Count) { Write-Output 'Locally modified files the kit changed were left alone. Compare with the kit version from the project root:' }
    foreach ($p in $Plan | Where-Object Note) { Write-Output "  $($p.Note)" }
}

function Format-SwDelivery([string]$Root, $Plan, $Render, [string]$From, [string]$UserHome, [switch]$Preview, [switch]$Partial) {
    # What a delivery change converted, kept and could not claim; never which route a native command uses.
    $to = $Render.Delivery
    $central = @($Render.Central)
    if (Test-SwSame $to 'central-v1') {
        foreach ($p in $Plan | Where-Object { Test-SwCentralCopy $_.Path $central }) {
            if (Test-SwSame $p.Action 'gone') { "missing copy: $($p.Path) (removed before the ownership record was committed, or deleted locally); its ownership entry is dropped" }
            elseif (Test-SwSame $p.Action 'remove') { "$(if ($Preview) { 'retained copy' } else { 'converted copy' }): $($p.Path) (owned and unchanged; backed up under .sw/backup/ before removal)" }
        }
    }
    foreach ($dir in '.agents/skills', '.claude/skills') {
        $full = Join-Path $Root $dir
        if (-not (Test-Path -LiteralPath $full -PathType Container)) { continue }
        $kept = @(Get-ChildItem -LiteralPath $full -Directory -Force | Where-Object { -not (Test-SwIn $_.Name $central) } | ForEach-Object Name | Sort-Object)
        if ($kept.Count) { "project skills kept in ${dir}: $($kept -join ', ') (not converted)" }
    }
    if (Test-SwSame $to 'project-copy') {
        $record = $null
        $recordPath = Join-Path $UserHome '.sw/global.json'
        if (Test-Path -LiteralPath $recordPath -PathType Leaf) { try { $record = Read-SwJson $recordPath } catch { } }
        $homes = if ($record -is [Collections.IDictionary] -and $record['homes'] -is [Collections.IDictionary]) { $record['homes'] } else { @{} }
        foreach ($h in $homes.Keys) {
            $entries = $homes[$h]['entries']
            if ($entries -isnot [Collections.IDictionary]) { continue }
            foreach ($id in $central) { if ($entries.Contains("skills/$id")) { "duplicate risk: $id is also linked centrally ($(Join-Path $h "skills/$id")); both routes can reach discovery and which one a native command uses is not asserted" } }
        }
    }
    if ($Partial) { "Skill delivery: not changed ($From); no central availability is claimed. Next safe step: update '$Root' -SkillDelivery $to -WhatIf, then apply." }
    elseif ($Preview) { "Skill delivery preview: $From -> $to; nothing was written. Next safe step: re-run without -WhatIf to apply." }
    elseif (Test-SwSame $to 'central-v1') {
        # Re-read after the change: availability is reported as found, never assumed from the preflight.
        $problems = @(Get-SwCentralAvailability $central $UserHome)
        if ($problems.Count) { $problems; 'Skill delivery: central-v1; central availability is not confirmed (above). Fix it, then run validate.' }
        else { "Skill delivery: central-v1. Central availability (local record, claude and codex-skills): $($central -join ', '). Check it any time with validate." }
    }
    else { "Skill delivery: project-copy; kit skill copies are generated in .agents/skills and .claude/skills." }
}

function Remove-SwRetiredConfig([Collections.IDictionary]$Config) {
    # Choices that only configured the retired OpenCode surface or the dropped free-models skill. Returns notes.
    if ($Config.Contains('context7')) { $Config.Remove('context7'); 'Retired config context7 removed: it configured the Context7 MCP server in the retired opencode.jsonc; configure MCP servers in Claude Code or Codex yourself.' }
    if ($Config.Contains('watcherIgnore')) { $Config.Remove('watcherIgnore'); 'Retired config watcherIgnore removed: it configured the retired OpenCode file watcher.' }
    $sel = $Config['selection']
    if ($sel -is [Collections.IDictionary] -and $sel['capabilities'] -is [array] -and (Test-SwIn 'provider-setup' $sel['capabilities'])) {
        $sel['capabilities'] = @($sel['capabilities'] | Where-Object { -not (Test-SwSame $_ 'provider-setup') })
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
        [ValidateScript({ Test-SwIn $_ 'local', 'tracked' -IgnoreCase })][string]$Records, [ValidateScript({ Test-SwIn $_ 'host', 'workspace' -IgnoreCase })][string]$GitPolicy
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
    if (Test-SwSame $config['records'] 'local' -IgnoreCase) { Write-Output 'Local records are git-ignored; existing tracked files/history are not removed. Review before publishing.' }
    Write-Output "Next: fill the project sections of AGENTS.md, then run 'powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 validate'. Models are chosen per thread in T3 Code."
}

function Assert-SwCentralReady([string[]]$Ids, [string]$UserHome) {
    # Central prerequisites are checked before any effect; a conversion or repair never relies on links it cannot see.
    $problems = @(try { $null = Read-SwCentralRecord (Join-Path $UserHome '.sw/global.json') $script:Kit (Join-Path $UserHome '.sw'); Get-SwCentralAvailability $Ids $UserHome }
        catch { "central prerequisites missing: $($_.Exception.Message)" })
    if ($problems.Count) { throw "Skill delivery change blocked; nothing was written:`n  $($problems -join "`n  ")" }
}

function Update-SwProject {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Position = 0)][string]$Path, [switch]$Adopt, [switch]$Force,
        [switch]$SelectionV1, [AllowEmptyCollection()][AllowEmptyString()][string[]]$Capabilities,
        [ValidateScript({ Test-SwIn $_ 'local', 'tracked' -IgnoreCase })][string]$Records, [ValidateScript({ Test-SwIn $_ 'host', 'workspace' -IgnoreCase })][string]$GitPolicy,
        # Physical delivery of the selected kit skills; absent keeps the current mode.
        [string]$SkillDelivery)
    $Root = Resolve-SwRoot $Path
    $from = Get-SwManifestKit $Root
    $config = Get-SwConfig $Root
    $before = ConvertTo-SwJson $config
    $fromDelivery = Get-SwSkillDelivery $config
    $deliveryBound = $PSBoundParameters.ContainsKey('SkillDelivery')
    if ($deliveryBound -and -not (Test-SwIn $SkillDelivery 'project-copy', 'central-v1')) { throw "-SkillDelivery must be 'project-copy' or 'central-v1' (exact case). Nothing was written." }
    if ($deliveryBound -and -not $config.Contains('selection')) { throw 'Skill delivery needs selection v1; this legacy project has none. Run update <path> -SelectionV1 first, then re-run with -SkillDelivery. Nothing was written.' }
    $retired = @(Remove-SwRetiredConfig $config)
    if ($PSBoundParameters.ContainsKey('Records')) { $config['records'] = $Records.ToLowerInvariant() }
    if ($PSBoundParameters.ContainsKey('GitPolicy')) { $config['gitPolicy'] = $GitPolicy.ToLowerInvariant() }
    Set-SwSelectionOption $config $SelectionV1 $PSBoundParameters
    if ($deliveryBound -and -not (Test-SwSame $SkillDelivery $fromDelivery)) { $config['skillDelivery'] = $SkillDelivery }
    $render = Get-SwRender $config
    $changing = -not (Test-SwSame $render.Delivery $fromDelivery)
    $userHome = if ($deliveryBound -or $changing) { Get-SwUserHome }
    if ($changing -and (Test-SwSame $render.Delivery 'central-v1')) { Assert-SwCentralReady $render.Central $userHome }
    $configChanged = (-not (Test-SwSame (ConvertTo-SwJson $config) $before))
    if ($configChanged -and -not $PSCmdlet.ShouldProcess('.sw/config.json', 'write configuration after completed sync')) {
        if ($WhatIfPreference) {
            $preview = Sync-SwProject -Root $Root -Config $config -Adopt:$Adopt -Force:$Force -Preflight -FromDelivery $fromDelivery
            Format-SwPlan $preview $from
            Format-SwSelection $render
            if ($deliveryBound) { Format-SwDelivery $Root $preview $render $fromDelivery $userHome -Preview }
            $retired
        } else { Write-Warning 'PARTIAL: configuration declined; no update effects performed.' }
        $global:LASTEXITCODE = $(if ($WhatIfPreference) { 0 } else { 1 }); return
    }
    if ($changing) {
        # Refusals throw here, before the first backup or removal; anything thrown later is an interruption.
        $null = Sync-SwProject -Root $Root -Config $config -Adopt:$Adopt -Force:$Force -Preflight -FromDelivery $fromDelivery
        # The mode is recorded last; any failure up to and including that write is an interruption with no central claim.
        $unwritten = 'configuration and ownership record were not written'
        try {
            $plan = Sync-SwProject -Root $Root -Config $config -Adopt:$Adopt -Force:$Force -FromDelivery $fromDelivery
            if ($global:LASTEXITCODE -eq 0) {
                $unwritten = 'the ownership record was committed but configuration was not written'
                Write-SwFile (Resolve-SwManagedPath $Root '.sw/config.json') (ConvertTo-SwJson $config); $configChanged = $false
            }
        } catch {
            Write-Warning "PARTIAL: skill delivery change interrupted ($($_.Exception.Message)); $unwritten, so no central availability is claimed. Next safe step: update '$Root' -SkillDelivery $($render.Delivery) -WhatIf, then apply."
            $global:LASTEXITCODE = 1; return
        }
    } else { $plan = Sync-SwProject -Root $Root -Config $config -Adopt:$Adopt -Force:$Force -FromDelivery $fromDelivery }
    $syncExit = $global:LASTEXITCODE
    Format-SwPlan $plan $from
    Format-SwSelection $render
    if ($deliveryBound -or $changing) { Format-SwDelivery $Root $plan $render $fromDelivery $userHome -Partial:($syncExit -ne 0) }
    # Explicit config choices are recorded only after a successful sync.
    if ($syncExit -ne 0) { $global:LASTEXITCODE = $syncExit; return }
    if ($configChanged -and -not $WhatIfPreference) { Write-SwFile (Resolve-SwManagedPath $Root '.sw/config.json') (ConvertTo-SwJson $config) }
    $retired
    Get-SwRetiredLocalNotes $Root
    Write-Output "Git policy: $(Get-SwGitPolicy $config); records: $(if ($config['records']) { $config['records'] } else { 'tracked (legacy)' })."
    if (Test-SwSame $config['records'] 'local' -IgnoreCase) { Write-Output 'Local records are git-ignored; existing tracked files/history are not removed. Review before publishing.' }
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
    $raw = if ((-not (Test-SwSame $origin 'default' -IgnoreCase)) -and $given.Count -eq 1 -and "$($given[0])".Contains($Separator)) {
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
        if (Test-SwSame ($full.TrimEnd([char[]]@([char]92, [char]47))) (([IO.Path]::GetPathRoot($full)).TrimEnd([char[]]@([char]92, [char]47))) -IgnoreCase) { throw "$Kind home ($origin) is a filesystem root, nothing was written: '$t'" }
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
    $absent = @(@($Paths.Claude) + @($Paths.Codex) | Where-Object { (-not (Test-SwSame $_.Origin 'default' -IgnoreCase)) -and -not (Test-Path -LiteralPath $_.Dir -PathType Container) })
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
    [pscustomobject]@{ Path = $Destination; Files = @($copied | ForEach-Object Rel); Items = @($copied); Homes = @(Get-SwUnique (Get-SwGlobalFiles $p | ForEach-Object Home)); Partial = $partial }
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
        if (Test-SwSame $t '{') {
            $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            $t = Step
            if (Test-SwSame $t '}') { return }
            while ($true) {
                if (-not $t.StartsWith('"', [StringComparison]::Ordinal)) { throw 'not strict JSON: an object key must be a double-quoted string' }
                $name = [regex]::Unescape($t.Substring(1, $t.Length - 2))
                if (-not $names.Add($name)) { throw "duplicate key '$name'" }
                if (-not (Test-SwSame (Step) ':')) { throw "not strict JSON: ':' expected after key '$name'" }
                Read-Value
                $t = Step
                if (Test-SwSame $t '}') { return }
                if (-not (Test-SwSame $t ',')) { throw "not strict JSON: ',' or '}' expected" }
                $t = Step
            }
        }
        if (Test-SwSame $t '[') {
            if ($p.I -lt $p.T.Count -and (Test-SwSame $p.T[$p.I] ']')) { $p.I++; return }
            while ($true) {
                Read-Value
                $t = Step
                if (Test-SwSame $t ']') { return }
                if (-not (Test-SwSame $t ',')) { throw "not strict JSON: ',' or ']' expected" }
            }
        }
        if ((Test-SwSame $t '') -or (Test-SwIn $t ('}', ']', ',', ':'))) { throw 'not strict JSON: a value expected' }
    }
    Read-Value
    if ($p.I -ne $p.T.Count) { throw 'not strict JSON: text after the value' }
}

function Assert-SwGlobalBaselineFields($r, [string]$Path) {
    $bad = "Invalid global baseline record (nothing is written while it is invalid): $Path"
    if ($r -isnot [Collections.IDictionary] -or @($r.Keys | Where-Object { -not (Test-SwIn $_ ('schema', 'kitVersion', 'kitCommit', 'homes')) }).Count -or $r.Count -ne 4 -or
        $r['schema'] -isnot [long] -or $r['schema'] -ne 1 -or $r['homes'] -isnot [Collections.IDictionary] -or
        $r['kitVersion'] -isnot [string] -or ($null -ne $r['kitCommit'] -and $r['kitCommit'] -isnot [string])) { throw $bad }
    $seen = [Collections.Generic.HashSet[string]]::new((Get-SwPathComparer))
    foreach ($dir in $r['homes'].Keys) {
        $h = $r['homes'][$dir]
        if (-not (Test-SwFullyQualified $dir) -or (-not (Test-SwSame ([IO.Path]::GetFullPath($dir).TrimEnd([char[]]@([char]92, [char]47))) $dir)) -or -not $seen.Add($dir) -or
            $h -isnot [Collections.IDictionary] -or $h.Count -ne 2 -or $h['entries'] -isnot [Collections.IDictionary] -or $h['entries'].Count -eq 0) { throw $bad }
        foreach ($k in $h['entries'].Keys) { if ((-not (Test-SwIn $k $script:GlobalEntry.Values)) -or $h['entries'][$k] -isnot [string] -or $h['entries'][$k] -cnotmatch '^[0-9a-f]{64}$') { throw $bad } }
        if ($h['kind'] -isnot [string] -or (-not (Test-SwSame $h['kind'] (Get-SwGlobalKind $h['entries'])))) { throw $bad }
    }
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
    if ($r -is [Collections.IDictionary] -and $r['schema'] -eq 2) {
        throw "$bad (schema2 is unsupported by legacy delivery; preview with '$($script:Kit)\sw.ps1' global check -Delivery central-v1 -Harness both)"
    }
    Assert-SwGlobalBaselineFields $r $Path
    $r
}

# Central delivery extends the A7 record in memory. The legacy reader/writer above deliberately remains schema1-only.
# E5 writes rules blocks and E4 one junction per selected skill, each with its own receipt; migration is not implemented. Unrelated recorded paths are validated as data, never visited.
$script:CentralScopes = @('claude', 'codex', 'codex-skills')

function Assert-SwCentralKeys($Value, [string[]]$Keys) {
    if ($Value -isnot [Collections.IDictionary] -or $Value.Count -ne $Keys.Count -or @($Value.Keys | Where-Object { -not (Test-SwIn $_ $Keys) }).Count) {
        throw "Unexpected object keys; expected $($Keys -join ', ')"
    }
}

function Assert-SwCentralPath($Value) {
    if ($Value -isnot [string] -or $Value -cnotmatch '^[A-Za-z]:\\' -or
        (-not (Test-SwSame ([IO.Path]::GetFullPath($Value).TrimEnd('\')) $Value))) { throw "Expected normalized absolute local path: '$Value'" }
    Assert-SwRelativePath $Value.Substring(3).Replace('\', '/')
}

function Assert-SwCentralIds($Value, [string[]]$Allowed) {
    if ($Value -isnot [array]) { throw 'Selection must be an array' }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($id in $Value) {
        if ($id -isnot [string] -or $id -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$' -or -not $seen.Add($id) -or ($Allowed -and (-not (Test-SwIn $id $Allowed)))) {
            throw [Management.Automation.PSArgumentException]::new("Invalid or duplicate selection ID: '$id'")
        }
    }
}

function Get-SwCentralSourcePath([string]$Tier, [string]$Id, [string]$ProductRoot, [string]$PersonalRoot) {
    if (Test-SwSame $Tier 'personal' -IgnoreCase) { return Join-Path $PersonalRoot "skills/$Id" }
    if (Test-SwSame $Id 'unreal-validation' -IgnoreCase) { return Join-Path $ProductRoot 'project/profiles/unreal/files/.agents/skills/unreal-validation' }
    Join-Path $ProductRoot "project/base/.agents/skills/$Id"
}

function ConvertFrom-SwCentralReparseTarget([string]$Raw) {
    $path = $Raw
    foreach ($prefix in @('\??\', '\\?\')) { if ($path.StartsWith($prefix, [StringComparison]::Ordinal)) { $path = $path.Substring($prefix.Length); break } }
    Assert-SwCentralPath $path
    $path
}

function Read-SwCentralRecord([string]$Path, [string]$ProductRoot, [string]$PersonalRoot, [ref]$Snapshot) {
    # $Snapshot receives the exact text that was parsed, so a freshness snapshot never differs from the record.
    Assert-SwPhysicalPath $Path
    $empty = [ordered]@{ schema = [long]2; kitVersion = Get-SwKitVersion; kitCommit = $null; productRoot = $ProductRoot; personalRoot = $PersonalRoot; homes = [ordered]@{} }
    if (-not (Test-Path -LiteralPath $Path)) { return $empty }
    $bad = "Invalid global delivery record (nothing was written): $Path"
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'not a file' }
        $text = Read-SwText $Path
        if ($Snapshot) { $Snapshot.Value = $text }
        Assert-SwStrictJson $text
        $r = ConvertFrom-SwJson $text
    } catch { throw "$bad ($($_.Exception.Message))" }
    if ($r -is [Collections.IDictionary] -and $r['schema'] -is [long] -and $r['schema'] -eq 1) {
        # Validate the complete old schema FIRST; never rescue an invalid old record through normalization.
        Assert-SwGlobalBaselineFields $r $Path
        $old = $r
        $empty.kitVersion = $old.kitVersion; $empty.kitCommit = $old.kitCommit
        foreach ($dir in $old.homes.Keys) {
            $h = $old.homes[$dir]
            $n = [ordered]@{ kind = $h.kind; delivery = [ordered]@{}; selection = [ordered]@{}; entries = [ordered]@{} }
            foreach ($scope in $h.kind.Split('+')) {
                $n.delivery[$scope] = 'rules'
                $n.selection[$scope] = [ordered]@{ productSkills = @(); personalSkills = @(); personalRules = @() }
            }
            foreach ($key in $h.entries.Keys) {
                $n.entries[$key] = [ordered]@{ kind = 'rules-block'; sourceMode = 'literal'; bodySha256 = $h.entries[$key]; hashFormat = 'a7-lf-utf8'; inputs = @() }
            }
            $empty.homes[$dir] = $n
        }
        return $empty
    }
    try {
        Assert-SwCentralKeys $r @('schema', 'kitVersion', 'kitCommit', 'productRoot', 'personalRoot', 'homes')
        if ($r.schema -isnot [long] -or $r.schema -ne 2 -or $r.kitVersion -isnot [string] -or
            ($null -ne $r.kitCommit -and $r.kitCommit -isnot [string]) -or $r.homes -isnot [Collections.IDictionary]) { throw 'Unsupported schema or field types' }
        Assert-SwCentralPath $r.productRoot; Assert-SwCentralPath $r.personalRoot
        if (-not (Get-SwPathComparer).Equals($r.personalRoot, $PersonalRoot)) { throw 'Personal root must be the user home/.sw containing this record' }
        $seen = [Collections.Generic.HashSet[string]]::new((Get-SwPathComparer))
        foreach ($dir in $r.homes.Keys) {
            Assert-SwCentralPath $dir
            if (-not $seen.Add($dir)) { throw 'Colliding homes' }
            $h = $r.homes[$dir]
            Assert-SwCentralKeys $h @('kind', 'delivery', 'selection', 'entries')
            if ($h.delivery -isnot [Collections.IDictionary] -or -not $h.delivery.Count -or $h.entries -isnot [Collections.IDictionary] -or -not $h.entries.Count) { throw 'Empty or invalid home maps' }
            $tags = @($script:CentralScopes | Where-Object { Test-SwIn $_ @($h.delivery.Keys) })
            Assert-SwCentralKeys $h.delivery $tags; Assert-SwCentralKeys $h.selection $tags
            if ($h.kind -isnot [string] -or (-not (Test-SwSame $h.kind ($tags -join '+')))) { throw 'Home kind does not match canonical scopes' }
            foreach ($scope in $tags) {
                if ($h.delivery[$scope] -isnot [string] -or (-not (Test-SwIn $h.delivery[$scope] ('rules', 'central-v1'))) -or ((Test-SwSame $scope 'codex-skills' -IgnoreCase) -and (-not (Test-SwSame $h.delivery[$scope] 'central-v1')))) { throw 'Invalid delivery scope' }
                $s = $h.selection[$scope]
                Assert-SwCentralKeys $s @('productSkills', 'personalSkills', 'personalRules')
                Assert-SwCentralIds $s.productSkills; Assert-SwCentralIds $s.personalSkills
                Assert-SwCentralIds $s.personalRules @('shared', 'claude', 'codex')
                if (@($s.productSkills | Where-Object { Test-SwIn $_ $s.personalSkills -IgnoreCase }).Count) { throw 'Product/personal skill collision' }
                if (((Test-SwSame $h.delivery[$scope] 'rules' -IgnoreCase) -and ($s.productSkills.Count + $s.personalSkills.Count + $s.personalRules.Count)) -or
                    ((Test-SwSame $scope 'codex' -IgnoreCase) -and ($s.productSkills.Count + $s.personalSkills.Count)) -or
                    ((Test-SwSame $scope 'codex-skills' -IgnoreCase) -and $s.personalRules.Count) -or
                    @($s.personalRules | Where-Object { -not (Test-SwIn $_ @('shared', $scope)) }).Count) { throw 'Selection does not match scope' }
            }
            $entryScopes = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
            foreach ($key in $h.entries.Keys) {
                $e = $h.entries[$key]
                if ($e -isnot [Collections.IDictionary]) { throw 'Invalid entry type' }
                if (Test-SwIn $key $script:GlobalEntry.Values) {
                    $scope = if (Test-SwSame $key $script:GlobalEntry.claude) { 'claude' } else { 'codex' }
                    if (-not (Test-SwIn $scope $tags)) { throw 'Rule entry has no scope' }
                    $null = $entryScopes.Add($scope)
                    Assert-SwCentralKeys $e @('kind', 'sourceMode', 'bodySha256', 'hashFormat', 'inputs')
                    if ($e.kind -isnot [string] -or (-not (Test-SwSame $e.kind 'rules-block')) -or $e.sourceMode -isnot [string] -or (-not (Test-SwIn $e.sourceMode ('literal', 'imports'))) -or
                        ((Test-SwSame $scope 'codex' -IgnoreCase) -and (-not (Test-SwSame $e.sourceMode 'literal'))) -or
                        ((Test-SwSame $h.delivery[$scope] 'rules' -IgnoreCase) -and ((-not (Test-SwSame $e.sourceMode 'literal')) -or $e.inputs.Count)) -or
                        $e.bodySha256 -isnot [string] -or $e.bodySha256 -cnotmatch '^[0-9a-f]{64}$' -or $e.hashFormat -isnot [string] -or (-not (Test-SwSame $e.hashFormat 'a7-lf-utf8')) -or $e.inputs -isnot [array] -or
                        ((Test-SwSame $e.sourceMode 'imports' -IgnoreCase) -and -not $e.inputs.Count) -or ((Test-SwSame $scope 'claude' -IgnoreCase) -and $e.inputs.Count -and (-not (Test-SwSame $e.sourceMode 'imports')))) { throw 'Invalid rules-block fields' }
                    $inputPaths = @((Join-Path $r.productRoot 'global/rules.md'), (Join-Path $r.personalRoot 'rules/shared.md'), (Join-Path $r.personalRoot "rules/$scope.md"))
                    $lastIndex = -1
                    foreach ($ruleInput in $e.inputs) {
                        Assert-SwCentralKeys $ruleInput @('tier', 'path', 'sha256'); Assert-SwCentralPath $ruleInput.path
                        $index = [Array]::IndexOf($inputPaths, $ruleInput.path)
                        if ($index -le $lastIndex -or ($lastIndex -eq -1 -and $index -ne 0) -or $ruleInput.tier -isnot [string] -or (-not (Test-SwSame $ruleInput.tier $(if ($index -eq 0) { 'product' } else { 'personal' }))) -or
                            $ruleInput.sha256 -isnot [string] -or $ruleInput.sha256 -cnotmatch '^[0-9a-f]{64}$') { throw 'Invalid ordered rule input' }
                        $lastIndex = $index
                    }
                } elseif ($key -cmatch '^skills/([a-z0-9]+(?:-[a-z0-9]+)*)$') {
                    $id = $Matches[1]
                    Assert-SwCentralKeys $e @('kind', 'scopeOwners', 'sourceTier', 'sourceId', 'sourcePath', 'linkType', 'normalizedTarget', 'rawReparseTarget')
                    Assert-SwCentralIds $e.scopeOwners @('claude', 'codex-skills')
                    $owners = @('claude', 'codex-skills' | Where-Object { Test-SwIn $_ $e.scopeOwners })
                    if ($e.kind -isnot [string] -or (-not (Test-SwSame $e.kind 'skill-link')) -or -not $owners.Count -or (-not (Test-SwSame ($owners -join '+') ($e.scopeOwners -join '+'))) -or
                        $e.sourceTier -isnot [string] -or (-not (Test-SwIn $e.sourceTier ('product', 'personal'))) -or $e.sourceId -isnot [string] -or (-not (Test-SwSame $e.sourceId $id)) -or
                        $e.linkType -isnot [string] -or (-not (Test-SwSame $e.linkType 'junction')) -or $e.rawReparseTarget -isnot [string]) { throw 'Invalid skill-link fields' }
                    foreach ($owner in $owners) {
                        if ((-not (Test-SwIn $owner $tags)) -or (-not (Test-SwSame $h.delivery[$owner] 'central-v1'))) { throw 'Link owner has no central scope' }
                        $null = $entryScopes.Add($owner)
                    }
                    if ((Test-SwIn 'codex-skills' $owners) -and -not (Get-SwPathComparer).Equals($dir, (Join-Path (Split-Path $r.personalRoot -Parent) '.agents'))) { throw 'Codex skills must use the shared user home' }
                    Assert-SwCentralPath $e.sourcePath; Assert-SwCentralPath $e.normalizedTarget
                    if ((-not (Test-SwSame $e.sourcePath (Get-SwCentralSourcePath $e.sourceTier $id $r.productRoot $r.personalRoot))) -or
                        -not (Get-SwPathComparer).Equals($e.sourcePath, $e.normalizedTarget) -or
                        -not (Get-SwPathComparer).Equals((ConvertFrom-SwCentralReparseTarget $e.rawReparseTarget), $e.normalizedTarget)) { throw 'Skill source/target mismatch' }
                } else { throw "Unknown artifact: $key" }
            }
            foreach ($scope in $tags) { if (-not $entryScopes.Contains($scope)) { throw 'Home scope has no owned artifact' } }
        }
    } catch { throw "$bad ($($_.Exception.Message))" }
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
            if (Test-SwSame $State.State 'missing-file' -IgnoreCase) {
                [IO.Directory]::CreateDirectory((Split-Path $file -Parent)) | Out-Null
                $fs = [IO.FileStream]::new($file, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            } else {
                # -CheckOnly only reads, so a read-only file holding a current block is still recorded.
                $fs = [IO.FileStream]::new($file, [IO.FileMode]::Open, $(if ($CheckOnly) { [IO.FileAccess]::Read } else { [IO.FileAccess]::ReadWrite }), [IO.FileShare]::None)
                $reader = [IO.StreamReader]::new($fs, [Text.Encoding]::UTF8, $true, 4096, $true)
                $now = $reader.ReadToEnd().Replace("`r`n", "`n"); $reader.Dispose()
                if (-not (Test-SwSame $now $State.Text)) { return 'changed' }
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
    $start = $s.Text.IndexOf($b, [StringComparison]::Ordinal)
    if ($start -lt 0) { $s.State = 'missing-block'; return $s }
    $start += $b.Length
    $have = Get-SwHash $s.Text.Substring($start, $s.Text.IndexOf($e, [StringComparison]::Ordinal) - $start)
    # No trust on first use: without a baseline only a byte-identical shipped version counts as unedited.
    $s.State = if (Test-SwSame $have $Hash) { 'current' } elseif ($s.Baseline) { if (Test-SwSame $have $s.Baseline) { 'stale' } else { 'edited' } }
    elseif (Test-SwIn $have $script:GlobalShipped) { 'stale-shipped' } else { 'unverified' }
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
    $stop = @($plan | Where-Object { Test-SwIn $_.State 'malformed', 'foreign-type' })
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
            if (-not (Test-SwSame $now.RecordText $pre.RecordText)) {
                throw "The global baseline record changed after it was read (another install ran), nothing was written: $recordPath. Run global install again."
            }
            for ($i = 0; $i -lt $plan.Count; $i++) {
                if ((-not (Test-SwSame $now.Plan[$i].State $plan[$i].State -IgnoreCase)) -or (-not (Test-SwSame $now.Plan[$i].Text $plan[$i].Text))) { $plan[$i].State = 'changed' }
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
            $write = (Test-SwIn $s.State 'missing-file', 'missing-block', 'stale', 'stale-shipped' -IgnoreCase)
            if ((Test-SwSame $s.State 'current' -IgnoreCase) -or ($write -and $PSCmdlet.ShouldProcess($file, 'set global rules block'))) {
                $base = if (-not $s.Text -and $t.Include) { $t.Include } else { $s.Text }
                # A failed write stops the run before the record is written, so that entry is never recorded.
                $result = try { if ($write) { Write-SwGlobalGuarded $s (Set-SwBlock $base 'global' $rules) } else { Write-SwGlobalGuarded $s -CheckOnly } }
                catch { throw "$($_.Exception.Message). Its prior content is in the pre-install snapshot $($b.Path); the run stopped and its baseline was not recorded." }
                if (-not (Test-SwSame $result 'ok' -IgnoreCase)) { $s.State = $result }
                elseif ($write) {
                    & $setEntry $t
                    Write-Output "$($t.Kind) global rules ($($s.State)): $file"
                    if ((Test-SwSame $s.State 'missing-block' -IgnoreCase) -and $s.Text) { Write-Output "Note: $file keeps its earlier unmanaged text above the block (it is also in the backup)." }
                } else { & $setEntry $t }
            } elseif ($write -and -not $WhatIfPreference) { $partial = $true }
            if (Test-SwSame $s.State 'changed' -IgnoreCase) {
                $kept++
                Write-Output "Kept $($file): it changed while install was running, or is open elsewhere; run global install again to judge it."
            }
            if (Test-SwSame $s.State 'read-only' -IgnoreCase) {
                # Install never clears a read-only attribute or changes permissions.
                $kept++
                Write-Output "Kept $($file): it is read-only (or not writable); make it writable, then run global install again."
            }
            if (Test-SwIn $s.State 'edited', 'unverified' -IgnoreCase) {
                # A7: an installed copy that was edited, or cannot be shown unedited, is never overwritten. No switch bypasses this.
                $kept++
                $why = if (Test-SwSame $s.State 'edited' -IgnoreCase) { 'was edited after install' } else { 'cannot be shown unedited (no baseline, and it matches no shipped version)' }
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
    $rtkInstallFailed = $false
    $rtk = Get-SwToolVersion rtk
    if (-not $rtk -or $rtk -lt [version]'0.48.0') {
        if ($InstallRtk) {
            if ($PSCmdlet.ShouldProcess('rtk-ai.rtk', 'winget install')) {
                & winget install --id rtk-ai.rtk --exact --accept-source-agreements --accept-package-agreements
                $rtkInstallFailed = $LASTEXITCODE -ne 0
            }
        } else { Write-Output 'rtk missing or older than 0.48 (optional; not installed). Install it yourself (winget install --id rtk-ai.rtk --exact), or re-run with -InstallRtk.' }
    }
    Test-SwGlobal -ClaudeConfigDir $ClaudeConfigDir -CodexHome $CodexHome
    if ($kept) { Write-Warning "PARTIAL: $kept edited, unverified, changed or read-only global rules block(s) kept; see the notes above." }
    if ($partial) { Write-Warning 'PARTIAL: a global rules block write was declined.' }
    if ($kept -or $partial -or $rtkInstallFailed) { $global:LASTEXITCODE = 1 }
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
        $state = if (Test-SwSame $probe.State 'ok' -IgnoreCase) { 'OK' } elseif ($t[1]) { $(if (Test-SwSame $probe.State 'missing' -IgnoreCase) { 'MISSING' } else { 'FAILED' }) } else { 'WARN' }
        & $add $t[0] $state $(if (Test-SwSame $probe.State 'ok' -IgnoreCase) { $probe.Version.ToString() } elseif (Test-SwSame $probe.State 'missing' -IgnoreCase) { 'not found' } else { Format-SwProbe $probe })
    }
    $rtk = $probes['rtk']
    if ((Test-SwSame $rtk.State 'ok' -IgnoreCase) -and $rtk.Version -lt [version]'0.48.0') { & $add 'rtk >= 0.48' 'WARN' "found $($rtk.Version)" }
    if (Test-SwSame $probes['gh'].State 'ok' -IgnoreCase) {
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
                { Test-SwIn $_ 'missing-file', 'missing-block' -IgnoreCase } { 'WARN', "$where; missing, run global install" }
                { Test-SwIn $_ 'stale', 'stale-shipped' -IgnoreCase } { 'WARN', "$where; outdated, run global install" }
                'edited' { 'WARN', "$where; edited locally, install keeps it: move the edit to the central source, delete the block, run global install" }
                'unverified' { 'WARN', "$where; cannot be shown unedited, install keeps it: move any edit to the central source, delete the block, run global install" }
                default { 'FAILED', "$where; $($s.State): $($s.Error)" }
            }
        }
        & $add "$($t.Kind) rules" $state $detail
        if (-not (Test-SwSame $t.Kind 'claude' -IgnoreCase)) { continue }
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
    $global:LASTEXITCODE = if (@($rows | Where-Object { Test-SwIn $_.State 'MISSING', 'FAILED' }).Count) { 1 } else { 0 }
}

function Get-SwCentralSkillSource([string]$Tier, [string]$Id, [string]$ProductRoot, [string]$PersonalRoot) {
    Assert-SwCentralIds @($Id)
    $path = Get-SwCentralSourcePath $Tier $Id $ProductRoot $PersonalRoot
    Assert-SwCentralPath $path; Assert-SwPhysicalPath $path
    if (-not (Test-Path -LiteralPath $path -PathType Container)) { throw "Selected skill source missing: $Tier/$Id ($path)" }
    if (-not (Test-SwSame (Get-Item -LiteralPath $path -Force).Name $Id)) { throw "Skill source directory name must exactly match ID '$Id': $path" }
    Get-SwPhysicalFiles $path | Out-Null
    $front = Read-SwFrontmatter (Join-Path $path 'SKILL.md') @('name', 'description', 'disable-model-invocation', 'user-invocable', 'argument-hint', 'allowed-tools')
    if ($front['name'] -isnot [string] -or (-not (Test-SwSame $front['name'] $Id))) { throw "Skill frontmatter name must exactly match '$Id': $path" }
    [pscustomobject]@{ Tier = $Tier; Id = $Id; Path = $path }
}

function ConvertTo-SwCentralImport([string]$Path) {
    # Deliberately bounded grammar; do not guess native quoting/recursive-import behavior.
    if ($Path -match '[^\p{L}\p{M}\p{N} :\\/._-]') { throw "Unsupported Claude import path grammar: $Path" }
    Assert-SwCentralPath $Path
    '@' + $Path.Replace('\', '/').Replace(' ', '\ ')
}

function Get-SwCentralRules([string]$Scope, [string[]]$PersonalRules, [string]$ProductRoot, [string]$PersonalRoot) {
    $paths = @([pscustomobject]@{ Tier='product'; Path=(Join-Path $ProductRoot 'global/rules.md') }) +
        @(foreach ($id in @('shared', $Scope)) { if (Test-SwIn $id $PersonalRules) { [pscustomobject]@{ Tier='personal'; Path=(Join-Path $PersonalRoot "rules/$id.md") } } })
    $inputs = [Collections.Generic.List[object]]::new(); $texts = [Collections.Generic.List[string]]::new()
    foreach ($source in $paths) {
        Assert-SwCentralPath $source.Path; Assert-SwPhysicalPath $source.Path
        if (-not (Test-Path -LiteralPath $source.Path -PathType Leaf)) { throw "Selected rule source missing: $($source.Path)" }
        $raw = [IO.File]::ReadAllBytes($source.Path)
        $text = Read-SwText $source.Path
        # Conservative first slice: reject standalone @ tokens, including extensionless/quoted/inline imports.
        if ((Test-SwSame $source.Tier 'personal' -IgnoreCase) -and $text -match '(?m)(?:^|[\s`"''(])@') { throw "Personal rule nested import is unsupported: $($source.Path)" }
        $inputs.Add([ordered]@{ tier=$source.Tier; path=$source.Path; sha256=(Get-SwByteHash $raw) })
        $texts.Add($(if (Test-SwSame $Scope 'claude' -IgnoreCase) { ConvertTo-SwCentralImport $source.Path } else { $text.Trim("`n") }))
    }
    $body = Get-SwGlobalBody ($texts -join "`n`n")
    [pscustomobject]@{ Body=$body; Inputs=@($inputs); Hash=(Get-SwHash $body); KnownBytes=([Text.Encoding]::UTF8.GetByteCount($body)) }
}

function Get-SwCentralLinkObservation([string]$Path, $Entry) {
    # Only this exact managed leaf may be a junction. The broad participating-path guards stay unchanged.
    # Get-Item exposes reparse metadata even for a broken junction; never enumerate/open the leaf or its source here.
    try {
        Assert-SwPhysicalPath (Split-Path $Path -Parent)
        $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    } catch [Management.Automation.ItemNotFoundException], [IO.FileNotFoundException], [IO.DirectoryNotFoundException] {
        return [pscustomobject]@{ State='missing-link'; Error=$null }
    } catch { return [pscustomobject]@{ State='foreign-type'; Error=$_.Exception.Message } }
    if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return [pscustomobject]@{ State='foreign-type'; Error="Real file or directory at skill leaf: $Path" } }
    if (-not $Entry) { return [pscustomobject]@{ State='unowned-link'; Error="Unowned link cannot be adopted: $Path. If it is yours, remove only that link (cmd /c rmdir `"$Path`", never /s), then run global install again." } }
    $targets = @($item.Target)
    $matches = $false
    if ((Test-SwSame $item.LinkType 'Junction') -and $targets.Count -eq 1 -and (Test-SwSame $targets[0] $Entry.rawReparseTarget)) {
        try { $matches = (Get-SwPathComparer).Equals((ConvertFrom-SwCentralReparseTarget $targets[0]), $Entry.normalizedTarget) } catch { }
    }
    if (-not $matches) { return [pscustomobject]@{ State='tampered'; Error="Recorded link type/target changed: $Path" } }
    # Only the recorded source path is probed, never the leaf. A dangling owned link is not current.
    if (-not [IO.Directory]::Exists($Entry.normalizedTarget)) { return [pscustomobject]@{ State='broken'; Error="Owned link is broken, its source is missing or moved: $Path -> $($Entry.normalizedTarget). It is kept and never re-pointed by name; clear it with sw.ps1 global remove -Delivery central-v1 -Component skills and its -Harness, or remove only that link (cmd /c rmdir `"$Path`", never /s), then run global install again." } }
    [pscustomobject]@{ State='current'; Error=$null }
}

function Get-SwCentralDecision($Artifact, [string]$Operation) {
    # Pure state/action mapping over observations; no filesystem, lock, record or native calls.
    $row = [ordered]@{}
    foreach ($property in $Artifact.PSObject.Properties) { $row[$property.Name] = $property.Value }
    $row.Action = 'no-op'; $row.State = 'OK'; $row.DesiredOwners = @($Artifact.ScopeOwners)
    $remove = (Test-SwSame $Operation 'remove' -IgnoreCase)
    if ($Artifact.Refusal -or (Test-SwIn $Artifact.Current 'foreign-type', 'malformed', 'tampered', 'unowned-link' -IgnoreCase)) {
        $row.Action = 'refuse'; $row.State = 'FAILED'
        if (-not $row.Refusal) { $row.Refusal = "Conflicting artifact: $($Artifact.Current)" }
    } elseif (Test-SwSame $Artifact.Kind 'skill-link' -IgnoreCase) {
        if ($remove) {
            $row.DesiredOwners = @($Artifact.ScopeOwners | Where-Object { -not (Test-SwIn $_ $Artifact.Scopes) })
            $row.Action = if ($row.DesiredOwners.Count -eq $Artifact.ScopeOwners.Count) { 'no-op' }
                elseif ($row.DesiredOwners.Count) { 'detach-owner' }
                elseif (Test-SwSame $Artifact.Current 'missing-link' -IgnoreCase) { 'forget-missing' } else { 'remove-link' }
        } elseif (-not $Artifact.Desired) { $row.Action = 'retain-owned'; $row.State = 'WARN' }
        elseif ($Artifact.SourceChanged -and @($Artifact.ScopeOwners | Where-Object { -not (Test-SwIn $_ $Artifact.Scopes) }).Count) {
            $row.Action = 'refuse'; $row.State = 'FAILED'; $row.Refusal = 'Retarget requires every owning scope at the physical home to be selected'
        } else {
            $row.DesiredOwners = @('claude', 'codex-skills' | Where-Object { Test-SwIn $_ (@($Artifact.ScopeOwners) + @($Artifact.Scopes)) })
            $row.Action = if (Test-SwSame $Artifact.Current 'missing-link' -IgnoreCase) { 'create-link' } elseif ($Artifact.SourceChanged) { 'retarget-link' }
                elseif (@($Artifact.Scopes | Where-Object { -not (Test-SwIn $_ $Artifact.ScopeOwners) }).Count) { 'attach-owner' } else { 'no-op' }
        }
        if ((-not (Test-SwSame $row.State 'FAILED' -IgnoreCase)) -and ((Test-SwSame $Artifact.Current 'missing-link' -IgnoreCase) -or (Test-SwIn $row.Action 'retarget-link', 'attach-owner' -IgnoreCase))) { $row.State = 'WARN' }
    } else {
        if (Test-SwIn $Artifact.Current 'edited', 'unverified' -IgnoreCase) { $row.Action = 'preserve'; $row.State = 'WARN' }
        elseif ($remove) {
            $row.Action = if (-not (Test-SwSame $Artifact.Ownership 'record' -IgnoreCase)) { 'preserve' }
                elseif (Test-SwIn $Artifact.Current 'missing-file', 'missing-block' -IgnoreCase) { 'forget-missing' } else { 'remove-block' }
        } else {
            $row.Action = switch ($Artifact.Current) {
                { Test-SwIn $_ 'missing-file', 'missing-block' -IgnoreCase } { 'create-block' }
                { Test-SwIn $_ 'stale', 'stale-shipped' -IgnoreCase } { 'replace-block' }
                default { if (Test-SwSame $Artifact.Ownership 'record' -IgnoreCase) { 'no-op' } else { 'record-baseline' } }
            }
        }
        if ((-not (Test-SwSame $Artifact.Current 'current' -IgnoreCase)) -or $Artifact.SourceDrift) { $row.State = 'WARN' }
    }
    # Backup and check report the prospective state; neither schedules an application effect.
    if ((Test-SwSame $Operation 'check' -IgnoreCase) -and (-not (Test-SwSame $row.Action 'refuse' -IgnoreCase))) { $row.Action = 'inspect' }
    if ((Test-SwSame $Operation 'backup' -IgnoreCase) -and (-not (Test-SwSame $row.Action 'refuse' -IgnoreCase))) { $row.Action = 'snapshot-metadata' }
    $row.Desired = if (Test-SwSame $Artifact.Kind 'rules-block' -IgnoreCase) { if ($remove) { 'block-absent' } else { 'current-block' } }
        elseif ($remove) { if ($row.DesiredOwners.Count) { 'owned-by-remaining-scopes' } else { 'absent' } }
        elseif ($Artifact.Desired) { 'selected-owned-link' } else { 'owned-out-of-selection' }
    [pscustomobject]$row
}

function Get-SwCentralList([string[]]$Values) {
    # A single CLI token may be a comma list; an actual PowerShell array is already a list.
    if (@($Values).Count -eq 0 -or (@($Values).Count -eq 1 -and [string]::IsNullOrWhiteSpace($Values[0]))) { return }
    $ids = @(if ($Values.Count -eq 1) { $Values[0].Split(',') } else { $Values })
    @($ids | ForEach-Object { $_.Trim() })
}

function Get-SwCentralHomeList([string]$Kind, [string[]]$Explicit, [string]$EnvName, [string]$Default) {
    $raw = if ($Explicit) { $Explicit } else { @([Environment]::GetEnvironmentVariable($EnvName)) }
    # Get-SwHomeList checks ambiguous lists against disk. Reject network/device paths before that possible probe.
    foreach ($value in $raw) {
        if ($value -and $value.TrimStart() -match '^[\\/]{2}') { throw 'Central homes must be local absolute paths; network/device paths are unsupported' }
    }
    Get-SwHomeList $Kind $Explicit $EnvName $Default
}

function Get-SwCentralPlan {
    [CmdletBinding()]
    param([string]$Action = 'check', [Parameter(Mandatory)][string]$Harness, [string]$Component = 'all',
        [AllowEmptyCollection()][AllowEmptyString()][string[]]$Skills, [AllowEmptyCollection()][AllowEmptyString()][string[]]$PersonalSkills,
        [AllowEmptyCollection()][AllowEmptyString()][string[]]$PersonalRules, [string[]]$ClaudeConfigDir, [string[]]$CodexHome)
    $userDir = Get-SwUserHome
    $product = $script:Kit; $personal = Join-Path $userDir '.sw'
    Assert-SwCentralPath $userDir; Assert-SwPhysicalPath $userDir
    Assert-SwCentralPath $product; Assert-SwPhysicalPath $product; Assert-SwPhysicalPath (Join-Path $product 'VERSION')
    $recordPath = Join-Path $personal 'global.json'
    # Read-SwCentralRecord guards the record path against links, then reads it once for both the record and its snapshot.
    $recordText = $null
    $record = Read-SwCentralRecord $recordPath $product $personal ([ref]$recordText)
    $diagnostics = [Collections.Generic.List[string]]::new()
    if ($WhatIfPreference -or (-not (Test-SwIn $Action 'install', 'remove' -IgnoreCase))) { $diagnostics.Add('Read-only plan; no adoption or native loading proof. Instruction size visibility is incomplete.') }
    if (Test-SwSame $Action 'backup' -IgnoreCase) { $diagnostics.Add("Record snapshot: $recordPath (if present); rule-file bytes and exact link metadata only, never skill-source contents") }
    $given = @{}
    foreach ($pair in @(@('Skills', 'productSkills'), @('PersonalSkills', 'personalSkills'), @('PersonalRules', 'personalRules'))) {
        if ($PSBoundParameters.ContainsKey($pair[0])) {
            $given[$pair[1]] = @(Get-SwCentralList $PSBoundParameters[$pair[0]])
            if (Test-SwSame $pair[0] 'PersonalRules' -IgnoreCase) { Assert-SwCentralIds $given[$pair[1]] @('shared', 'claude', 'codex') }
            else { Assert-SwCentralIds $given[$pair[1]] }
        }
    }
    $scopeTargets = [Collections.Generic.List[object]]::new()
    if (Test-SwIn $Harness 'claude', 'both' -IgnoreCase) {
        foreach ($h in @(Get-SwCentralHomeList 'Claude' $ClaudeConfigDir 'CLAUDE_CONFIG_DIR' (Join-Path $userDir '.claude'))) {
            $scopeTargets.Add([pscustomobject]@{ Scope='claude'; Dir=$h.Dir; Origin=$h.Origin })
        }
    }
    if (Test-SwIn $Harness 'codex', 'both' -IgnoreCase) {
        if (-not (Test-SwSame $Component 'skills' -IgnoreCase)) {
            foreach ($h in @(Get-SwCentralHomeList 'Codex' $CodexHome 'CODEX_HOME' (Join-Path $userDir '.codex'))) {
                $scopeTargets.Add([pscustomobject]@{ Scope='codex'; Dir=$h.Dir; Origin=$h.Origin })
            }
        }
        if (-not (Test-SwSame $Component 'rules' -IgnoreCase)) { $scopeTargets.Add([pscustomobject]@{ Scope='codex-skills'; Dir=(Join-Path $userDir '.agents'); Origin='shared user scope' }) }
    }
    $rows = [Collections.Generic.List[object]]::new()
    $links = [Collections.Specialized.OrderedDictionary]::new((Get-SwPathComparer))
    $recordedRuleSources = @(); $recordedSkillSources = @()
    foreach ($target in $scopeTargets) {
        Assert-SwCentralPath $target.Dir; Assert-SwPhysicalPath $target.Dir
        if (Test-Path -LiteralPath $target.Dir -PathType Leaf) { throw "Provider home is not a directory: $($target.Dir)" }
        if ((-not (Test-SwIn $target.Origin 'default', 'shared user scope' -IgnoreCase)) -and -not (Test-Path -LiteralPath $target.Dir -PathType Container)) { throw "Home not found, nothing written: $($target.Dir) ($($target.Origin))" }
        $homeKey = Find-SwGlobalHome $record.homes $target.Dir
        $homeRecord = if ($null -ne $homeKey) { $record.homes[$homeKey] } else { $null }
        $recordedSelection = if ($homeRecord -and $homeRecord.selection.Contains($target.Scope) -and (Test-SwSame $homeRecord.delivery[$target.Scope] 'central-v1' -IgnoreCase)) { $homeRecord.selection[$target.Scope] } else { $null }
        $selection = [ordered]@{}
        foreach ($name in @('productSkills', 'personalSkills', 'personalRules')) {
            $selection[$name] = @(if ($given.ContainsKey($name)) { $given[$name] } elseif ($recordedSelection) { $recordedSelection[$name] })
        }
        # A scope composes and records only shared plus its own personal rules, as the record reader requires.
        $selection.personalRules = @(if (-not (Test-SwSame $target.Scope 'codex-skills' -IgnoreCase)) { $selection.personalRules | Where-Object { Test-SwIn $_ ('shared', $target.Scope) } })
        # Codex rules homes carry no skills; the shared ~/.agents scope owns Codex skill links.
        if (Test-SwSame $target.Scope 'codex' -IgnoreCase) { $selection.productSkills = @(); $selection.personalSkills = @() }
        foreach ($id in @($selection.productSkills | Where-Object { Test-SwIn $_ $selection.personalSkills -IgnoreCase })) { throw "Product/personal skill collision for '$id' at $(Join-Path $target.Dir "skills/$id"): $(Get-SwCentralSourcePath 'product' $id $product $personal) and $(Get-SwCentralSourcePath 'personal' $id $product $personal)" }
        $isSkillScope = (Test-SwIn $target.Scope 'claude', 'codex-skills' -IgnoreCase) -and (-not (Test-SwSame $Component 'rules' -IgnoreCase))
        if ($isSkillScope -and -not $recordedSelection -and -not $given.ContainsKey('productSkills')) {
            if (Test-SwSame $Action 'install' -IgnoreCase) { throw [Management.Automation.PSArgumentException]::new("Initial central skills install requires explicit -Skills for $($target.Scope) at $($target.Dir)") }
            if (Test-SwSame $Action 'check' -IgnoreCase) { $diagnostics.Add("$($target.Scope) at $($target.Dir): no recorded selection; no catalogue defaults inferred") }
        }
        if ((Test-SwIn $target.Scope 'claude', 'codex' -IgnoreCase) -and (-not (Test-SwSame $Component 'skills' -IgnoreCase))) {
            $key = $script:GlobalEntry[$target.Scope]
            $entry = if ($homeRecord) { $homeRecord.entries[$key] } else { $null }
            if ($entry) { $recordedRuleSources += @($entry.inputs | ForEach-Object { $_.path }) }
            $inputs = @(); $body = ''; $hash = ''; $knownBytes = 0
            if (-not (Test-SwIn $Action 'remove', 'backup' -IgnoreCase)) {
                $rules = Get-SwCentralRules $target.Scope $selection.personalRules $product $personal
                $inputs = $rules.Inputs; $body = $rules.Body; $hash = $rules.Hash; $knownBytes = $rules.KnownBytes
            } elseif ($entry) { $hash = $entry.bodySha256; $inputs = $entry.inputs }
            $fileName = if (Test-SwSame $target.Scope 'claude' -IgnoreCase) { 'CLAUDE.md' } else { 'AGENTS.md' }
            $ruleTarget = [pscustomobject]@{ Dir=$target.Dir; File=(Join-Path $target.Dir $fileName); Key=$key }
            $baseline = [ordered]@{ homes=[ordered]@{} }
            if ($entry) { $baseline.homes[$target.Dir] = [ordered]@{ entries=[ordered]@{ $key=$entry.bodySha256 } } }
            $observation = Get-SwGlobalState $ruleTarget $baseline $hash
            $refusal = $observation.Error
            if (Test-SwSame $target.Scope 'codex' -IgnoreCase) {
                $override = Join-Path $target.Dir 'AGENTS.override.md'
                Assert-SwPhysicalPath $override
                if (Test-Path -LiteralPath $override -PathType Container) { $refusal = "AGENTS.override.md is not a file: $override" }
                elseif ((Test-Path -LiteralPath $override -PathType Leaf) -and (Get-Item -LiteralPath $override -Force).Length -gt 0) {
                    if (-not (Test-SwSame $Action 'remove' -IgnoreCase)) { $refusal = "Nonempty AGENTS.override.md masks requested rules: $override" }
                    else { $diagnostics.Add("Override retained during base-block removal: $override") }
                }
            }
            # A managed marker inside the body would leave the target malformed after writing.
            if (-not $refusal -and $body -match '<!-- sw:(begin|end) ') { $refusal = "Composed rules contain a reserved sw marker: $(@($inputs | ForEach-Object { $_.path }) -join ', ')" }
            $artifact = [pscustomobject]@{ Artifact=$key; Kind='rules-block'; SourceTier=((Get-SwUnique ($inputs | ForEach-Object { $_.tier })) -join '+'); Source=@($inputs | ForEach-Object { $_.path });
                TargetHome=$target.Dir; Target=$ruleTarget.File; Current=$observation.State; Desired=(-not (Test-SwSame $Action 'remove' -IgnoreCase)); Scopes=@($target.Scope); ScopeOwners=@();
                Ownership=$(if ($entry) { 'record' } else { 'no baseline' }); Refusal=$refusal; BlastRadius="$($target.Scope) rules in this configuration home only";
                SourceChanged=$false; SourceDrift=$(if ($null -ne $entry -and $entry.inputs.Count -and (-not (Test-SwIn $Action 'remove', 'backup' -IgnoreCase))) { -not (Test-SwSame (ConvertTo-SwJson $inputs) (ConvertTo-SwJson $entry.inputs)) } else { $null });
                Body=$body; Inputs=$inputs; KnownBytes=$knownBytes; Hash=$hash; Scope=$target.Scope; Selection=$selection; Entry=$entry; Observation=$observation;
                Include=$(if ((Test-SwSame $target.Scope 'claude' -IgnoreCase) -and (Test-Path -LiteralPath (Join-Path $target.Dir 'RTK.md') -PathType Leaf)) { "@RTK.md`n`n" } else { '' });
                Evidence=$(if ($entry) { "bodySha256=$($entry.bodySha256); hashFormat=$($entry.hashFormat)" } else { 'A7 shipped/desired body comparison only; no recorded baseline' }) }
            $rows.Add((Get-SwCentralDecision $artifact $Action))
        }
        if (-not $isSkillScope) { continue }
        $wanted = [ordered]@{}
        if (-not (Test-SwIn $Action 'remove', 'backup' -IgnoreCase)) {
            foreach ($tier in @('product', 'personal')) {
                $name = if (Test-SwSame $tier 'product' -IgnoreCase) { 'productSkills' } else { 'personalSkills' }
                foreach ($id in $selection[$name]) {
                    # A selected source missing behind its broken owned link is reported on that link's row instead.
                    $entry = if ($homeRecord) { $homeRecord.entries["skills/$id"] } else { $null }
                    if ($entry -and -not (Test-Path -LiteralPath (Get-SwCentralSourcePath $tier $id $product $personal) -PathType Container) -and
                        (Test-SwSame (Get-SwCentralLinkObservation (Join-Path $target.Dir "skills/$id") $entry).State 'broken')) { continue }
                    $wanted["skills/$id"] = Get-SwCentralSkillSource $tier $id $product $personal
                }
            }
        }
        # Include owned/out-of-selection leaves without scanning the native skills directory or the source catalogue.
        $keys = @($wanted.Keys)
        if ($homeRecord) {
            foreach ($key in $homeRecord.entries.Keys) {
                $entry = $homeRecord.entries[$key]
                if ((-not (Test-SwSame $entry.kind 'skill-link' -IgnoreCase)) -or (-not (Test-SwIn $target.Scope $entry.scopeOwners))) { continue }
                if ((Test-SwIn $Action 'remove', 'backup' -IgnoreCase) -and ($given.ContainsKey('productSkills') -or $given.ContainsKey('personalSkills'))) {
                    $name = if (Test-SwSame $entry.sourceTier 'product' -IgnoreCase) { 'productSkills' } else { 'personalSkills' }
                    if (-not $given.ContainsKey($name) -or (-not (Test-SwIn $entry.sourceId $given[$name]))) { continue }
                }
                if (-not (Test-SwIn $key $keys)) { $keys += $key }
            }
        }
        foreach ($key in $keys) {
            $entry = if ($homeRecord) { $homeRecord.entries[$key] } else { $null }
            if ($entry) { $recordedSkillSources += $entry.sourcePath }
            $desired = $wanted.Contains($key)
            $source = if ($desired) { $wanted[$key].Path } else { $entry.sourcePath }
            $tier = if ($desired) { $wanted[$key].Tier } else { $entry.sourceTier }
            $leaf = Join-Path $target.Dir $key
            if ($links.Contains($leaf)) {
                $artifact = $links[$leaf]
                if ($desired -and $artifact.Desired -and -not (Get-SwPathComparer).Equals($artifact.Source, $source)) { $artifact.Refusal = "Conflicting sources at the same physical skill leaf: $leaf" }
                if ($desired -and -not $artifact.Desired) {
                    $artifact.Source = $source; $artifact.SourceTier = $tier; $artifact.Desired = $true
                    $artifact.SourceChanged = ($null -ne $entry -and -not (Get-SwPathComparer).Equals($entry.sourcePath, $source))
                    $artifact.Scopes = @()
                }
                if (($desired -or (Test-SwSame $Action 'remove' -IgnoreCase)) -and (-not (Test-SwIn $target.Scope $artifact.Scopes))) { $artifact.Scopes += $target.Scope }
                if (Test-SwSame $target.Scope 'codex-skills' -IgnoreCase) { $artifact.BlastRadius = 'shared Codex user scope, independent of CODEX_HOME; includes any aliased Claude owners' }
            } else {
                $links[$leaf] = [pscustomobject]@{ Artifact=$key; Kind='skill-link'; SourceTier=$tier; Source=$source; TargetHome=$target.Dir; Target=$leaf; Selections=@{};
                    Current=$null; Desired=$desired; Scopes=@(if ($desired -or (Test-SwSame $Action 'remove' -IgnoreCase)) { $target.Scope }); ScopeOwners=@(if ($entry) { $entry.scopeOwners });
                    Ownership=$(if ($entry) { 'record' } else { 'no baseline' }); Refusal=$null;
                    BlastRadius=$(if (Test-SwSame $target.Scope 'codex-skills' -IgnoreCase) { 'shared Codex user scope, independent of CODEX_HOME; includes any aliased Claude owners' } else { 'Claude configuration home; retains any other recorded physical-home owners' });
                    SourceChanged=($null -ne $entry -and -not (Get-SwPathComparer).Equals($entry.sourcePath, $source)); SourceDrift=$false;
                    Evidence=$(if ($entry) { "junction; rawReparseTarget=$($entry.rawReparseTarget); normalizedTarget=$($entry.normalizedTarget)" } else { 'No recorded link ownership' }) }
            }
            # Each owning scope records its own selection with the link receipt.
            $links[$leaf].Selections[$target.Scope] = $selection
        }
    }
    foreach ($artifact in $links.Values) {
        $homeKey = Find-SwGlobalHome $record.homes $artifact.TargetHome
        $entry = if ($null -ne $homeKey) { $record.homes[$homeKey].entries[$artifact.Artifact] } else { $null }
        $observation = Get-SwCentralLinkObservation $artifact.Target $entry
        $artifact.Current = $observation.State
        # Remove and backup may still unlink or snapshot a broken owned link; install and check refuse it.
        if ($observation.Error -and -not ((Test-SwSame $observation.State 'broken') -and (Test-SwIn $Action 'remove', 'backup' -IgnoreCase))) { $artifact.Refusal = $observation.Error }
        $rows.Add((Get-SwCentralDecision $artifact $Action))
    }
    # Check the whole requested graph, including cross-scope aliases. A native target may never edit/hide a source.
    # Paths alone suffice: removal/backup still never opens or traverses a recorded skill source.
    # Canonical containers protect unselected skills too; derive paths without catalogue or home discovery.
    # Retargeting also preserves recorded sources from requested artifacts.
    $productRoots = @(Get-SwUnique @($product, $record.productRoot) ([StringComparer]::OrdinalIgnoreCase))
    $sourceFiles = @(foreach ($root in $productRoots) { Join-Path $root 'global/rules.md' }) +
        @(foreach ($id in @('shared', 'claude', 'codex')) { Join-Path $personal "rules/$id.md" }) +
        @($rows | Where-Object { Test-SwSame $_.Kind 'rules-block' } | ForEach-Object { $_.Source }) + $recordedRuleSources
    $sourceDirs = @((Join-Path $personal 'skills')) + @(foreach ($root in $productRoots) {
        Join-Path $root 'project/base/.agents/skills'
        Join-Path $root 'project/profiles/unreal/files/.agents/skills'
    }) + @($rows | Where-Object { Test-SwSame $_.Kind 'skill-link' } | ForEach-Object { $_.Source }) + $recordedSkillSources
    foreach ($row in $rows) {
        $overlap = @($sourceFiles | Where-Object { (Get-SwPathComparer).Equals($_, $row.Target) -or ((Test-SwSame $row.Kind 'skill-link' -IgnoreCase) -and (Test-SwContained $row.Target $_)) }) +
            @($sourceDirs | Where-Object { (Get-SwPathComparer).Equals($_, $row.Target) -or (Test-SwContained $_ $row.Target) -or ((Test-SwSame $row.Kind 'skill-link' -IgnoreCase) -and (Test-SwContained $row.Target $_)) })
        if ($overlap.Count) { $row.Refusal = "Source and target overlap: $($overlap -join ', ') -> $($row.Target)"; $row.Action = 'refuse'; $row.State = 'FAILED' }
    }
    [pscustomobject]@{ Record=$record; RecordPath=$recordPath; RecordText=$recordText; Rows=@($rows); Diagnostics=@($diagnostics); ExitCode=$(if (@($rows | Where-Object { Test-SwSame $_.State 'FAILED' }).Count) { 1 } else { 0 }) }
}

function Write-SwCentralBlock($Row, [switch]$Remove, [switch]$CheckOnly) {
    # Write-SwGlobalGuarded for one central rules block: the same exclusive compare-and-write, but only the marker span
    # changes; bytes outside it (BOM, CRLF, other text) stay exactly as found, and the file is kept even when emptied.
    # Text that is not strict UTF-8 (UTF-16, for one) cannot be proven unchanged, so it reports 'changed'.
    $file = $Row.Target; $seen = $Row.Observation
    Assert-SwPhysicalPath $file
    $b = '<!-- sw:begin global -->'; $e = '<!-- sw:end global -->'
    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    if (Test-SwSame $seen.State 'missing-file' -IgnoreCase) {
        if (Test-Path -LiteralPath $file) { return 'changed' }
        if ($Remove -or $CheckOnly) { return 'ok' }
        [IO.Directory]::CreateDirectory((Split-Path $file -Parent)) | Out-Null
        try { $fs = [IO.FileStream]::new($file, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None) }
        catch [UnauthorizedAccessException] { return 'read-only' } catch [IO.IOException] { return 'changed' }
        try { Write-SwStreamBytes $fs $utf8.GetBytes((Set-SwBlock $Row.Include 'global' $Row.Body)) }
        catch { throw "FAILED writing $($file): $($_.Exception.Message)" }
        finally { $fs.Dispose() }
        return 'ok'
    }
    $access = if ($CheckOnly) { [IO.FileAccess]::Read } else { [IO.FileAccess]::ReadWrite }
    try { $fs = [IO.FileStream]::new($file, [IO.FileMode]::Open, $access, [IO.FileShare]::None) }
    catch [UnauthorizedAccessException] { return 'read-only' } catch [IO.IOException] { return 'changed' }
    try {
        $bytes = [byte[]]::new($fs.Length); $read = 0
        while ($read -lt $bytes.Length) { $n = $fs.Read($bytes, $read, $bytes.Length - $read); if ($n -le 0) { break }; $read += $n }
        $bom = [byte[]]@(); if ($read -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $bom = [byte[]]@(0xEF, 0xBB, 0xBF) }
        try { $text = $utf8.GetString($bytes, $bom.Length, $read - $bom.Length) } catch { return 'changed' }
        if (-not (Test-SwSame ($text.Replace("`r`n", "`n")) $seen.Text)) { return 'changed' }
        if ($CheckOnly) { return 'ok' }
        $nl = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
        $start = $text.IndexOf($b, [StringComparison]::Ordinal)
        $end = if ($start -ge 0) { $text.IndexOf($e, $start, [StringComparison]::Ordinal) } else { -1 }
        if ($Remove) {
            if ($start -lt 0 -or $end -lt 0) { return 'ok' }
            $stop = $end + $e.Length
            # Take the trailing newline only when the block starts its own line; otherwise it ends unmarked text.
            if ($start -eq 0 -or (Test-SwSame $text[$start - 1] "`n" -IgnoreCase)) {
                if ($text.Substring($stop).StartsWith("`r`n", [StringComparison]::Ordinal)) { $stop += 2 } elseif ($text.Substring($stop).StartsWith("`n", [StringComparison]::Ordinal)) { $stop += 1 }
            }
            $new = $text.Substring(0, $start) + $text.Substring($stop)
        } else {
            $block = "$b`n$($Row.Body.Trim("`n"))`n$e".Replace("`n", $nl)
            $new = if ($start -ge 0 -and $end -ge 0) { $text.Substring(0, $start) + $block + $text.Substring($end + $e.Length) }
            elseif (-not $text.Length) { (Set-SwBlock $Row.Include 'global' $Row.Body).Replace("`n", $nl) }
            else { $text + $(if ($text.EndsWith("$nl$nl", [StringComparison]::Ordinal)) { '' } elseif ($text.EndsWith($nl, [StringComparison]::Ordinal)) { $nl } else { "$nl$nl" }) + $block + $nl }
        }
        try { $fs.SetLength(0); $fs.Position = 0; Write-SwStreamBytes $fs ([byte[]]($bom + $utf8.GetBytes($new))) }
        catch { throw "FAILED writing $($file): $($_.Exception.Message)" }
        'ok'
    } finally { $fs.Dispose() }
}

function Write-SwCentralReceipt($Record, [string]$RecordPath, $Known, $Row, [string]$Raw, [switch]$Drop) {
    # One atomic record replace per verified effect. The record must still be exactly what this run last wrote or read;
    # anything else means another writer ran, so stop before overwriting its receipt.
    $now = if (Test-Path -LiteralPath $RecordPath -PathType Leaf) { Read-SwText $RecordPath } else { $null }
    if (-not (Test-SwSame $now $Known)) { throw "The global baseline record changed after it was read (another install ran): $RecordPath. Run global install again." }
    $homes = $Record.homes
    $k = Find-SwGlobalHome $homes $Row.TargetHome
    if ($null -eq $k) {
        if ($Drop) { return $Known }
        $k = $Row.TargetHome; $homes[$k] = [ordered]@{ kind = ''; delivery = [ordered]@{}; selection = [ordered]@{}; entries = [ordered]@{} }
    }
    $h = $homes[$k]
    if (Test-SwSame $Row.Kind 'skill-link' -IgnoreCase) {
        # One entry per physical leaf. An owning scope records its own selection; a detached scope drops only this ID.
        $owners = @($Row.DesiredOwners); $id = $Row.Artifact.Substring(7); $old = $h.entries[$Row.Artifact]
        if ($Drop -or -not $owners.Count) { $h.entries.Remove($Row.Artifact) }
        else {
            $h.entries[$Row.Artifact] = [ordered]@{ kind = 'skill-link'; scopeOwners = $owners; sourceTier = $Row.SourceTier; sourceId = $id; sourcePath = $Row.Source;
                linkType = 'junction'; normalizedTarget = $Row.Source; rawReparseTarget = $(if ($Raw) { $Raw } elseif ($old) { $old.rawReparseTarget }) }
        }
        $list = if (Test-SwSame $Row.SourceTier 'product' -IgnoreCase) { 'productSkills' } else { 'personalSkills' }
        foreach ($s in @($Row.Scopes)) {
            $owned = Test-SwIn $s $owners
            $from = if ($owned) { $Row.Selections[$s] } else { $h.selection[$s] }
            if (-not $from) { continue }
            $copy = [ordered]@{}
            foreach ($name in @('productSkills', 'personalSkills', 'personalRules')) {
                $copy[$name] = @($from[$name] | Where-Object { $owned -or -not ((Test-SwSame $name $list) -and (Test-SwSame $_ $id -IgnoreCase)) })
            }
            if ($owned) { $h.delivery[$s] = 'central-v1' }
            $h.selection[$s] = $copy
        }
    } elseif ($Drop) { $h.entries.Remove($Row.Artifact) }
    else {
        $scope = $Row.Scope
        $mode = if ((Test-SwSame $scope 'claude' -IgnoreCase) -and @($Row.Inputs).Count) { 'imports' } else { 'literal' }
        $h.entries[$Row.Artifact] = [ordered]@{ kind = 'rules-block'; sourceMode = $mode; bodySha256 = $Row.Hash; hashFormat = 'a7-lf-utf8'; inputs = @($Row.Inputs) }
        $h.delivery[$scope] = 'central-v1'; $h.selection[$scope] = $Row.Selection
    }
    # A scope stays delivered while it still owns a rules block or a skill link.
    foreach ($s in @($h.delivery.Keys)) {
        if (($script:GlobalEntry.Contains($s) -and $h.entries.Contains($script:GlobalEntry[$s])) -or
            @($h.entries.Values | Where-Object { (Test-SwSame $_.kind 'skill-link' -IgnoreCase) -and (Test-SwIn $s @($_.scopeOwners)) }).Count) { continue }
        $h.delivery.Remove($s); $h.selection.Remove($s)
    }
    if (-not $h.entries.Count) { $homes.Remove($k) }
    else { $h.kind = @($script:CentralScopes | Where-Object { Test-SwIn $_ @($h.delivery.Keys) }) -join '+' }
    $Record.schema = [long]2; $Record.kitVersion = Get-SwKitVersion; $Record.kitCommit = $(try { Get-SwKitCommit } catch { $null }); $Record.productRoot = $script:Kit
    $text = ConvertTo-SwJson $Record
    Write-SwFileAtomic $RecordPath $text
    $text
}

function Invoke-SwCentralLink($Row, $Entry) {
    # The only link effects: one junction at an exact managed leaf, or a nonrecursive unlink of a proven owned one.
    # Containment, ownership, leaf type and target are proven again just before the effect; a source is never opened,
    # followed or retargeted by name. No copy fallback and no elevation.
    $leaf = $Row.Target; $raw = if ($Entry) { $Entry.rawReparseTarget } else { $null }
    if (-not (Test-SwContained $Row.TargetHome $leaf)) { return [pscustomobject]@{ Status='leaf outside its home'; Raw=$null } }
    $seen = Get-SwCentralLinkObservation $leaf $Entry
    $need = if (Test-SwIn $Row.Action 'create-link', 'forget-missing' -IgnoreCase) { @('missing-link') } elseif (Test-SwSame $Row.Action 'detach-owner' -IgnoreCase) { @('current', 'broken', 'missing-link') }
        elseif (Test-SwSame $Row.Action 'remove-link' -IgnoreCase) { @('current', 'broken') } else { @('current') }
    if (-not (Test-SwIn $seen.State $need)) { return [pscustomobject]@{ Status="changed ($($seen.State))"; Raw=$null } }
    if ($Entry -and (-not (Test-SwSame (@($Entry.scopeOwners) -join '+') (@($Row.ScopeOwners) -join '+')))) { return [pscustomobject]@{ Status='changed owners'; Raw=$null } }
    $unrecorded = "it is unrecorded, so later runs keep it and report it as unowned (remove only that link: cmd /c rmdir `"$leaf`", then run global install again)"
    if (Test-SwSame $Row.Action 'create-link' -IgnoreCase) {
        try {
            Assert-SwCentralPath $Row.Source; Assert-SwPhysicalPath $Row.Source
            if (-not (Test-Path -LiteralPath $Row.Source -PathType Container)) { throw 'missing' }
        } catch { return [pscustomobject]@{ Status="source missing or moved since the plan, not retargeted by name: $($Row.Source)"; Raw=$null } }
        [IO.Directory]::CreateDirectory((Split-Path $leaf -Parent)) | Out-Null
        try { New-Item -ItemType Junction -Path $leaf -Value $Row.Source -ErrorAction Stop | Out-Null }
        catch {
            if (-not (Test-SwSame (Get-SwCentralLinkObservation $leaf $null).State 'missing-link')) { throw "Creating $leaf failed after something appeared there; $unrecorded`: $($_.Exception.Message)" }
            return [pscustomobject]@{ Status="link not created ($($_.Exception.Message))"; Raw=$null }
        }
        $item = Get-Item -LiteralPath $leaf -Force
        $targets = @($item.Target)
        $matches = (Test-SwSame $item.LinkType 'Junction') -and $targets.Count -eq 1 -and $(try { (Get-SwPathComparer).Equals((ConvertFrom-SwCentralReparseTarget $targets[0]), $Row.Source) } catch { $false })
        if (-not $matches) { throw "Created $leaf but it does not point at $($Row.Source); $unrecorded" }
        $raw = $targets[0]
    } elseif (Test-SwSame $Row.Action 'remove-link' -IgnoreCase) {
        [IO.Directory]::Delete($leaf, $false)
    }
    [pscustomobject]@{ Status='ok'; Raw=$raw }
}

function Invoke-SwCentralEffects {
    # E5/E4 effects for central rules blocks and skill links: consent, one lock per user home, a re-plan under it, a
    # backup of every file that may change, then each effect followed by its own receipt, so a crash leaves at most one
    # effect unrecorded (the next run finds a block current and records it, or keeps a link and reports it as unowned).
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)]$Plan, [Parameter(Mandatory)][hashtable]$Options)
    if (-not $PSCmdlet.ShouldProcess($Plan.RecordPath, 'write central global rules blocks and skill links, then record each receipt')) {
        if (-not $WhatIfPreference) { Write-Warning 'PARTIAL: central delivery effects declined; nothing was written.'; $global:LASTEXITCODE = 1 }
        return
    }
    $userDir = Get-SwUserHome
    $lockPath = Join-Path $userDir '.sw/global.lock'
    try {
        Assert-SwPhysicalPath $lockPath
        [IO.Directory]::CreateDirectory((Split-Path $lockPath -Parent)) | Out-Null
        $lock = try { [IO.FileStream]::new($lockPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None, 1, [IO.FileOptions]::DeleteOnClose) }
        catch [IO.IOException] { throw "Another global install holds $lockPath, nothing was written. If none is running, delete that file and retry." }
    } catch { Write-Output "FAILED central delivery: $($_.Exception.Message)"; $global:LASTEXITCODE = 1; return }
    try {
        # Judge again under the lock: a changed record means another install ran; a target changed since the plan is kept.
        $fresh = Get-SwCentralPlan @Options
        $recordPath = $fresh.RecordPath
        if (-not (Test-SwSame $fresh.RecordText $Plan.RecordText)) { throw "The global baseline record changed after it was read (another install ran), nothing was written: $recordPath. Run global install again." }
        if ($fresh.ExitCode) { throw 'A target became unsafe after the plan, nothing was written. Run global check -Delivery central-v1 again.' }
        $record = $fresh.Record; $rows = @($fresh.Rows); $rules = @($rows | Where-Object { Test-SwSame $_.Kind 'rules-block' })
        $planned = @{}; foreach ($r in $Plan.Rows) { $planned["$($r.TargetHome)|$($r.Artifact)"] = $r }
        if ($record.productRoot -and (-not (Test-SwSame $record.productRoot $script:Kit))) {
            # Every recorded input and product skill path is tied to the record's product root; a partial move across homes would leave an unreadable record.
            foreach ($hk in @($record.homes.Keys)) {
                foreach ($ek in @($record.homes[$hk].entries.Keys)) {
                    $entry = $record.homes[$hk].entries[$ek]
                    if (@($entry.inputs).Count -or ((Test-SwSame $entry.kind 'skill-link' -IgnoreCase) -and (Test-SwSame $entry.sourceTier 'product' -IgnoreCase))) {
                        throw "The record names another product root ($($record.productRoot)) for $ek in $hk, nothing was written. Moving the product root of recorded rules or product skills is not supported yet."
                    }
                }
            }
        }
        $touch = @(Get-SwUnique @($rules | Where-Object { (Test-SwIn $_.Action 'create-block', 'replace-block', 'remove-block' -IgnoreCase) -and (-not (Test-SwSame $_.Observation.State 'missing-file' -IgnoreCase)) } | ForEach-Object Target) ([StringComparer]::OrdinalIgnoreCase))
        $backup = $null
        # Link effects change no file content, so only the record is saved for them; skill sources are never copied.
        if ($touch.Count -or @($rules | Where-Object { Test-SwSame $_.Action 'preserve' }).Count -or
            @($rows | Where-Object { Test-SwIn $_.Action 'create-link', 'attach-owner', 'detach-owner', 'remove-link', 'forget-missing' -IgnoreCase }).Count) {
            $backup = New-SwSnapshotDir (Join-Path $userDir ".sw/backups/$(Get-SwOperationId)")
            $saved = 0
            foreach ($path in @($touch) + @(if ($null -ne $fresh.RecordText) { $recordPath })) {
                if ((Split-Path $path -Leaf) -match $script:SecretName) { continue }
                $rel = if (Test-SwContained $userDir $path) { Get-SwRelativePath $userDir $path } else { "external/rules-$((Get-SwHash $path).Substring(0, 12))/$(Split-Path $path -Leaf)" }
                Copy-SwNew $path (Join-Path $backup $rel); $saved++
            }
            Write-Output "Backup: $backup ($saved files; files named like credentials are skipped by name only, contents are not scanned)"
        }
        $known = $fresh.RecordText; $clean = $true
        foreach ($row in $rows) {
            $was = $planned["$($row.TargetHome)|$($row.Artifact)"]
            if (Test-SwSame $row.Kind 'skill-link' -IgnoreCase) {
                if (-not $was -or (-not (Test-SwSame $was.Action $row.Action)) -or (-not (Test-SwSame $was.Current $row.Current)) -or
                    (-not (Test-SwSame (@($was.Source) -join '|') (@($row.Source) -join '|'))) -or (-not (Test-SwSame (@($was.DesiredOwners) -join '+') (@($row.DesiredOwners) -join '+')))) { $status = 'changed' }
                elseif (Test-SwSame $row.Action 'retain-owned' -IgnoreCase) { Write-Output "Retained $($row.Target): owned link outside the current selection, unchanged."; continue }
                elseif (Test-SwSame $row.Action 'retarget-link' -IgnoreCase) {
                    $clean = $false
                    Write-Output "Kept $($row.Target): its recorded source differs from $($row.Source); links are never retargeted. Remove that skill (global remove -Component skills), then run global install again."
                    continue
                }
                elseif ((Test-SwSame $row.Action 'no-op' -IgnoreCase) -and (Test-SwSame $Options.Action 'remove' -IgnoreCase)) { continue }
                else {
                    $hk = Find-SwGlobalHome $record.homes $row.TargetHome
                    $res = Invoke-SwCentralLink $row $(if ($null -ne $hk) { $record.homes[$hk].entries[$row.Artifact] })
                    $status = $res.Status
                }
                if (-not (Test-SwSame $status 'ok' -IgnoreCase)) { $clean = $false; Write-Output "Kept $($row.Target): $status since this run checked it, nothing written there. Run global install again."; continue }
                try { $known = Write-SwCentralReceipt $record $recordPath $known $row $res.Raw -Drop:(Test-SwIn $row.Action 'remove-link', 'forget-missing' -IgnoreCase) }
                catch {
                    if (Test-SwSame $row.Action 'create-link' -IgnoreCase) { throw "Created $($row.Target) but its receipt was not recorded; it is unrecorded, so later runs keep it and report it as unowned (remove only that link: cmd /c rmdir `"$($row.Target)`", then run global install again): $($_.Exception.Message)" }
                    throw
                }
                Write-Output "OK $($row.Action) $($row.Target) (receipt recorded)"
                continue
            }
            if (-not $was -or (-not (Test-SwSame $was.Action $row.Action)) -or (-not (Test-SwSame $was.Observation.State $row.Observation.State)) -or (-not (Test-SwSame $was.Observation.Text $row.Observation.Text))) { $status = 'changed' }
            elseif (Test-SwSame $row.Action 'preserve' -IgnoreCase) {
                $clean = $false
                Write-Output "Kept $($row.Target): $($row.Ownership) block, nothing written there."
                if ((Test-SwSame $Options.Action 'install' -IgnoreCase) -and $row.Hash) {
                    $incoming = Join-Path $backup "incoming/$($row.Scope)-$($row.Hash.Substring(0, 12))/$(Split-Path $row.Target -Leaf)"
                    try { Write-SwNewFile $incoming (Set-SwBlock "$($row.Observation.Text)" 'global' $row.Body); Write-Output "  Compare: $incoming" } catch { Write-Output "  Compare: no incoming copy ($($_.Exception.Message))" }
                    Write-Output '  Resolve: merge the incoming block by hand, or delete the marked block, then run global install again.'
                }
                continue
            }
            elseif (Test-SwSame $row.Action 'forget-missing' -IgnoreCase) { $status = 'ok' }
            else { $status = Write-SwCentralBlock $row -Remove:(Test-SwSame $row.Action 'remove-block' -IgnoreCase) -CheckOnly:(Test-SwIn $row.Action 'no-op', 'record-baseline' -IgnoreCase) }
            if (-not (Test-SwSame $status 'ok' -IgnoreCase)) { $clean = $false; Write-Output "Kept $($row.Target): $status since this run checked it, nothing written there. Run global install again."; continue }
            $known = Write-SwCentralReceipt $record $recordPath $known $row -Drop:(Test-SwIn $row.Action 'remove-block', 'forget-missing' -IgnoreCase)
            Write-Output "OK $($row.Action) $($row.Target) (receipt recorded)"
        }
        if ($clean) { $global:LASTEXITCODE = 0 } else { Write-Warning 'PARTIAL: some central artifacts were kept; see the lines above.'; $global:LASTEXITCODE = 1 }
    } catch { Write-Output "FAILED central delivery: $($_.Exception.Message)"; $global:LASTEXITCODE = 1 }
    finally { $lock.Dispose() }
}

function Invoke-SwGlobal {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Position = 0)][ValidateScript({ Test-SwIn $_ 'install', 'check', 'backup', 'remove' -IgnoreCase })][string]$Action = 'check', [switch]$InstallRtk,
        [string[]]$ClaudeConfigDir, [string[]]$CodexHome,
        [ValidateScript({ Test-SwIn $_ 'central-v1' -IgnoreCase })][string]$Delivery, [ValidateScript({ Test-SwIn $_ 'claude', 'codex', 'both' -IgnoreCase })][string]$Harness,
        [ValidateScript({ Test-SwIn $_ 'all', 'rules', 'skills' -IgnoreCase })][string]$Component = 'all',
        [AllowEmptyCollection()][AllowEmptyString()][string[]]$Skills, [AllowEmptyCollection()][AllowEmptyString()][string[]]$PersonalSkills,
        [AllowEmptyCollection()][AllowEmptyString()][string[]]$PersonalRules)
    $centralOptions = @('Harness', 'Component', 'Skills', 'PersonalSkills', 'PersonalRules')
    $usage = if ($Delivery) {
        if (-not $Harness) { '-Delivery central-v1 requires explicit -Harness claude|codex|both' }
        elseif ($InstallRtk -and (-not (Test-SwSame $Action 'install' -IgnoreCase))) { '-InstallRtk is install-only; no central runtime probes are performed' }
        elseif (((Test-SwSame $Harness 'codex' -IgnoreCase) -and $ClaudeConfigDir) -or ((Test-SwSame $Harness 'claude' -IgnoreCase) -and $CodexHome)) { 'Home arguments must match the explicitly selected harness' }
        elseif (((Test-SwSame $Component 'rules' -IgnoreCase) -and ($PSBoundParameters.ContainsKey('Skills') -or $PSBoundParameters.ContainsKey('PersonalSkills'))) -or
            ((Test-SwSame $Component 'skills' -IgnoreCase) -and $PSBoundParameters.ContainsKey('PersonalRules'))) { 'Selection lists must match -Component' }
    } elseif ((Test-SwSame $Action 'remove' -IgnoreCase) -or @($centralOptions | Where-Object { $PSBoundParameters.ContainsKey($_) }).Count) { 'Central options and remove require -Delivery central-v1' }
    elseif ($InstallRtk -and (-not (Test-SwSame $Action 'install' -IgnoreCase))) { '-InstallRtk is install-only' }
    if ($usage) { Write-Output "Usage: $usage"; $global:LASTEXITCODE = 2; return }
    if ($Delivery) {
        # Hard boundary before home resolution, source reads, locks or legacy dispatch: central backup has no effects yet.
        if ((Test-SwSame $Action 'backup' -IgnoreCase) -and -not $WhatIfPreference) {
            Write-Output "Central backup effects are not implemented. Use -WhatIf or global check -Delivery central-v1 -Harness $Harness."
            $global:LASTEXITCODE = 1; return
        }
        $options = @{ Action=$Action; Harness=$Harness; Component=$Component }
        foreach ($name in @('ClaudeConfigDir', 'CodexHome', 'Skills', 'PersonalSkills', 'PersonalRules')) {
            if ($PSBoundParameters.ContainsKey($name)) { $options[$name] = $PSBoundParameters[$name] }
        }
        try { $plan = Get-SwCentralPlan @options }
        catch [Management.Automation.PSArgumentException] { Write-Output "Usage: $($_.Exception.Message)"; $global:LASTEXITCODE = 2; return }
        catch { Write-Output "FAILED central preflight: $($_.Exception.Message)"; $global:LASTEXITCODE = 1; return }
        if ($InstallRtk) { Write-Output 'RTK requested: central delivery neither probes nor installs it.' }
        foreach ($detail in $plan.Diagnostics) { Write-Output $detail }
        foreach ($row in $plan.Rows) {
            Write-Output "$($row.State) $($row.Artifact) [$($row.Kind)] $($row.SourceTier):$($row.Source -join ', ') -> $($row.Target) (home=$($row.TargetHome)); current=$($row.Current); desired=$($row.Desired); action=$($row.Action)"
            Write-Output "  ownership=$($row.Ownership); scopes=$($row.Scopes -join ','); owners=$($row.ScopeOwners -join ','); desiredOwners=$($row.DesiredOwners -join ','); blast radius=$($row.BlastRadius)"
            Write-Output "  evidence=$($row.Evidence)"
            if (Test-SwSame $row.Kind 'rules-block' -IgnoreCase) { Write-Output "  known composed bytes=$($row.KnownBytes); source drift=$(if ($null -eq $row.SourceDrift) { 'unrecorded/not compared' } else { $row.SourceDrift })" }
            else { Write-Output '  Live source content is not version-frozen; link ownership compares metadata, not a directory hash.' }
            if ($row.Refusal) { Write-Output "  refusal=$($row.Refusal)" }
        }
        if ((Test-SwIn $Action 'install', 'remove' -IgnoreCase) -and -not $WhatIfPreference -and -not $plan.ExitCode) { Invoke-SwCentralEffects $plan $options; return }
        $global:LASTEXITCODE = $plan.ExitCode; return
    }
    $homes = @{ ClaudeConfigDir = $ClaudeConfigDir; CodexHome = $CodexHome }
    switch ($Action) {
        'install' { Install-SwGlobal -InstallRtk:$InstallRtk @homes }
        'check' { Test-SwGlobal @homes }
        'backup' {
            $b = Backup-SwGlobal @homes
            Write-Output "Backup: $($b.Path)"
            foreach ($h in $b.Homes) {
                $files = @($b.Items | Where-Object { Test-SwSame $_.Home $h })
                Write-Output "  $($h):$(if (-not $files.Count) { ' nothing to back up (no file install may edit is present)' })"
                $files | ForEach-Object { Write-Output "    $($_.Rel)" }
            }
        }
    }
}

Export-ModuleMember -Function Set-SwBlock, Get-SwRender, Sync-SwProject, Format-SwPlan, Initialize-SwProject, Update-SwProject,
    Backup-SwGlobal, Install-SwGlobal, Test-SwGlobal, Invoke-SwGlobal, Get-SwKitVersion, Get-SwKitCommit, Compare-SwVersion, Format-SwSelection
