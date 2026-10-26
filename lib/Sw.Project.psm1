# SuperWorkspace project module: everything that runs inside an installed project.
# Copied into each project as .sw/lib/Sw.Project.psm1 so collaborators without the
# kit can still validate, run diagnostics, and use comms. Windows PowerShell 5.1 and PowerShell 7.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Utf8 = [Text.UTF8Encoding]::new($false)

# --- shared helpers -------------------------------------------------------------

function Resolve-SwRoot([string]$Path) {
    if (-not $Path -and $env:SW_ROOT) { $Path = $env:SW_ROOT }
    if (-not $Path) {
        $top = Invoke-SwNative git @('rev-parse', '--show-toplevel')
        $Path = if ($LASTEXITCODE -eq 0 -and $top) { $top } else { (Get-Location).Path }
    }
    (Resolve-Path -LiteralPath $Path).Path
}

function Write-SwFile([string]$Path, [string]$Content) {
    Assert-SwPhysicalPath $Path
    $dir = Split-Path $Path -Parent
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir -Confirm:$false | Out-Null }
    [IO.File]::WriteAllText($Path, $Content.Replace("`r`n", "`n"), $script:Utf8)
}

function Get-SwTextBytes([string]$Content) { $script:Utf8.GetBytes($Content.Replace("`r`n", "`n")) }

function Get-SwByteHash([byte[]]$Bytes) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { [BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-', '').ToLowerInvariant() } finally { $sha.Dispose() }
}

# Ordinal string identity. PowerShell's -eq/-in/-contains, switch, ValidateSet, Sort/Select -Unique and the
# culture-default IndexOf/StartsWith/EndsWith ignore characters such as U+00AD, so two different names compare equal.
# Every comparison between two runtime strings under lib/ goes through these (a static test in tests/ enforces it).
function Test-SwSame($A, $B, [switch]$IgnoreCase) {
    if ($null -eq $A -or $null -eq $B) { return ($null -eq $A -and $null -eq $B) }
    $cmp = if ($IgnoreCase) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    [string]::Equals([string]$A, [string]$B, $cmp)
}

function Test-SwIn($Value, $List, [switch]$IgnoreCase) {
    foreach ($item in @($List)) { if (Test-SwSame $Value $item -IgnoreCase:$IgnoreCase) { return $true } }
    $false
}

function Get-SwUnique($Values, [StringComparer]$Comparer = [StringComparer]::Ordinal) {
    # First occurrence of each string, in input order.
    $seen = [Collections.Generic.HashSet[string]]::new($Comparer)
    @(foreach ($v in @($Values)) { if ($null -ne $v -and $seen.Add([string]$v)) { $v } })
}

# --- one code path on Windows PowerShell 5.1 (.NET Framework) and PowerShell 7 ----------------------------------

function Get-SwRelativePath([string]$Base, [string]$Path) {
    # [IO.Path]::GetRelativePath for Windows paths: case-insensitive parts, '\' separators, '.' for the base itself.
    $seps = [char[]]@([char]92, [char]47)
    $full = [IO.Path]::GetFullPath($Path)
    $b = @([IO.Path]::GetFullPath($Base).TrimEnd($seps).Split($seps))
    $p = @($full.TrimEnd($seps).Split($seps))
    if (-not (Test-SwSame $b[0] $p[0] -IgnoreCase)) { return $full }
    $i = 1
    while ($i -lt $b.Count -and $i -lt $p.Count -and (Test-SwSame $b[$i] $p[$i] -IgnoreCase)) { $i++ }
    $parts = @(for ($k = $i; $k -lt $b.Count; $k++) { '..' }) + @(for ($k = $i; $k -lt $p.Count; $k++) { $p[$k] })
    if ($parts.Count -eq 0) { '.' } else { $parts -join '\' }
}

# [IO.Path]::IsPathFullyQualified on Windows: a drive with a separator, or a UNC or device path.
function Test-SwFullyQualified([string]$Path) { $Path -match '^(?:[A-Za-z]:[\\/]|[\\/]{2})' }

function ConvertTo-SwNativeArgument([string]$Value) {
    # One argument quoted for the Windows CommandLineToArgvW rules: backslashes double only before a quote or the closing quote.
    if ($Value -and $Value -notmatch '[\s"]') { return $Value }
    '"' + ($Value -replace '(\\*)"', '$1$1\"' -replace '(\\+)\z', '$1$1') + '"'
}

function Invoke-SwNative([string]$Exe, [string[]]$Arguments) {
    # A native command with stderr discarded; the caller reads $LASTEXITCODE. A failed launch (a missing or denied
    # command) still throws, whatever the caller's preference: try turns it into a terminating error.
    # An .exe or .com runs as its own process in the current location, its stdout decoded as UTF-8 (Git prints paths
    # and names in UTF-8) and its stderr drained to nowhere; the console encoding is never changed. It gets its own
    # hidden console, so a parent without a console never shows a window; stdin is still inherited. Whatever else the
    # name resolves to first, as the call operator would (a function or mock, a script run in-process, a .cmd/.bat
    # shim with cmd's own quoting) or nothing found, keeps the call operator and the console code page.
    $ErrorActionPreference = 'Continue'
    $PSNativeCommandUseErrorActionPreference = $false
    $cmd = Get-Command -Name $Exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not ($cmd -and (Test-SwSame $cmd.CommandType 'Application' -IgnoreCase) -and (Test-SwIn $cmd.Extension '.exe', '.com' -IgnoreCase))) {
        # Windows PowerShell 5.1 turns redirected stderr into error records that 'Stop' makes terminating, so this scope continues.
        try { & $Exe @Arguments 2>$null } catch { throw }
        return
    }
    $start = [Diagnostics.ProcessStartInfo]::new($cmd.Path)
    $start.Arguments = @(foreach ($a in $Arguments) { ConvertTo-SwNativeArgument $a }) -join ' '
    $start.WorkingDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.StandardOutputEncoding = $script:Utf8
    $p = $null
    try {
        $p = [Diagnostics.Process]::Start($start)
        # stderr drains while stdout is read, so a full pipe cannot block the child.
        $drain = $p.StandardError.BaseStream.CopyToAsync([IO.Stream]::Null)
        while ($null -ne ($line = $p.StandardOutput.ReadLine())) { $line }
        $p.WaitForExit(); $drain.Wait()
        $global:LASTEXITCODE = $p.ExitCode
    } catch { throw } finally {
        # A consumer that stops early (Select-Object -First) leaves no child blocked on a full pipe.
        if ($p) { try { if (-not $p.HasExited) { $p.Kill() } } catch { }; $p.Dispose() }
    }
}

function Get-SwOperationId { "$(Get-SwUtc)-$([guid]::NewGuid().ToString('N').Substring(0, 8))" }

function Test-SwContained([string]$Base, [string]$Path) {
    # True when $Path resolves inside $Base (never equal to it); catches '..' escapes.
    $b = [IO.Path]::GetFullPath($Base).TrimEnd([char[]]@([char]92, [char]47)) + [IO.Path]::DirectorySeparatorChar
    $cmp = [StringComparison]::OrdinalIgnoreCase
    [IO.Path]::GetFullPath($Path).StartsWith($b, $cmp)
}

function Get-SwOnDiskCase([string]$Root, [string]$Full) {
    # $Full below $Root rebuilt from the names on disk (an exact match first, else one differing only in case); $null
    # when a part is missing. Lists each folder on the way, so call it only on a path already checked for links.
    $path = [IO.Path]::GetFullPath($Root).TrimEnd([char[]]@([char]92, [char]47))
    foreach ($part in @((Get-SwRelativePath $path $Full) -split '[\\/]' | Where-Object { $_ -and (-not (Test-SwSame $_ '.' -IgnoreCase)) })) {
        $names = @([IO.Directory]::EnumerateFileSystemEntries($path) | ForEach-Object { [IO.Path]::GetFileName($_) } | Where-Object { Test-SwSame $_ $part -IgnoreCase })
        if (-not $names) { return $null }
        $path = Join-Path $path $(if (Test-SwIn $part $names) { $part } else { $names[0] })
    }
    $path
}

function Assert-SwRelativePath($Relative) {
    # Ownership keys have one portable spelling, never a rooted/stream/alias path.
    if ($Relative -isnot [string] -or -not $Relative -or $Relative -match '[\\:<>"|?*\x00-\x1f]' -or [IO.Path]::IsPathRooted($Relative)) { throw 'Ownership path must be a clean relative path.' }
    foreach ($part in $Relative -split '/') {
        if ((Test-SwIn $part '', '.', '..' -IgnoreCase) -or $part -match '[. ]$' -or ($part -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)')) { throw 'Ownership path contains an ambiguous or invalid segment.' }
    }
}

function Assert-SwPhysicalPath([string]$Path) {
    # Checked then used, not an atomic defence against hostile swaps or hard links.
    $full = [IO.Path]::GetFullPath($Path)
    for ($current = $full; $current; $current = [IO.Path]::GetDirectoryName($current)) {
        try {
            $attributes = [IO.File]::GetAttributes($current)
            if ($attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Participating path traverses a link or junction: $current" }
            if ((-not (Test-SwSame $current $full -IgnoreCase)) -and -not ($attributes -band [IO.FileAttributes]::Directory)) { throw "Participating ancestor is not a directory: $current" }
        } catch [IO.FileNotFoundException], [IO.DirectoryNotFoundException] { }
    }
}

function Resolve-SwManagedPath([string]$Root, $Relative) {
    Assert-SwRelativePath $Relative
    $full = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    if (-not (Test-SwContained $Root $full)) { throw 'Ownership path escapes its root.' }
    Assert-SwPhysicalPath $full
    $full
}

function Get-SwPhysicalFiles([string]$Directory) {
    # Never enter a linked directory while enumerating participating source trees.
    Assert-SwPhysicalPath $Directory
    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { return }
    $queue = [Collections.Generic.Queue[string]]::new(); $queue.Enqueue($Directory)
    while ($queue.Count) {
        foreach ($item in Get-ChildItem -LiteralPath $queue.Dequeue() -Force) {
            Assert-SwPhysicalPath $item.FullName
            if ($item.PSIsContainer) { $queue.Enqueue($item.FullName) } else { $item }
        }
    }
}

function Write-SwBytesNew([string]$Path, [byte[]]$Bytes) {
    # CreateNew: IOException if the path exists; a failed write removes the file this call created.
    Assert-SwPhysicalPath $Path
    $stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($Bytes, 0, $Bytes.Length) }
    catch { $stream.Dispose(); $stream = $null; Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue; throw }
    finally { if ($stream) { $stream.Dispose() } }
}

function Write-SwNewFile([string]$Path, [string]$Content) {
    # Exact path, never replaces: recovery copies must not clobber an earlier generation.
    Assert-SwPhysicalPath $Path
    [IO.Directory]::CreateDirectory((Split-Path $Path -Parent)) | Out-Null
    Write-SwBytesNew $Path (Get-SwTextBytes $Content)
}

function Copy-SwNew([string]$Source, [string]$Destination) {
    Assert-SwPhysicalPath $Source
    Assert-SwPhysicalPath $Destination
    [IO.Directory]::CreateDirectory((Split-Path $Destination -Parent)) | Out-Null
    [IO.File]::Copy($Source, $Destination, $false)
}

function New-SwSnapshotDir([string]$Path) {
    # Reserve a recovery directory; fails if anything already exists there.
    Assert-SwPhysicalPath $Path
    [IO.Directory]::CreateDirectory((Split-Path $Path -Parent)) | Out-Null
    New-Item -ItemType Directory -Path $Path -Confirm:$false | Out-Null
    $Path
}

function New-SwExclusiveFile([string]$Dir, [string]$BaseName, [string]$Extension, [string]$Content, [int]$MaxAttempts = 100) {
    # The one allocator for immutable records: CreateNew wins the name or fails. Retry only on a real name
    # collision (-2, -3, ...); any other I/O failure surfaces at once.
    Assert-SwPhysicalPath $Dir
    [IO.Directory]::CreateDirectory($Dir) | Out-Null
    $bytes = Get-SwTextBytes $Content
    for ($n = 1; $n -le $MaxAttempts; $n++) {
        $path = Join-Path $Dir $(if ($n -eq 1) { "$BaseName$Extension" } else { "$BaseName-$n$Extension" })
        try { Write-SwBytesNew $path $bytes; return $path }
        catch {
            $e = $_.Exception
            while ($e.InnerException -and $e -isnot [IO.IOException]) { $e = $e.InnerException }
            if ($e -is [IO.IOException] -and [IO.File]::Exists($path)) { continue }
            throw
        }
    }
    throw "No free name for $BaseName$Extension in $Dir after $MaxAttempts attempts"
}

function Read-SwText([string]$Path) { [IO.File]::ReadAllText($Path).Replace("`r`n", "`n") }

function Read-SwJson([string]$Path) { ConvertFrom-SwJson (Read-SwText $Path) }

function ConvertFrom-SwJson([string]$Text) {
    # PowerShell 7's ConvertFrom-Json -AsHashtable on both shells: ordered objects with case-sensitive keys, arrays kept
    # whole (also at the root), integers as [long] and other numbers as [double]. Keys that differ only in case are
    # refused by ConvertFrom-Json on both shells (Windows PowerShell 5.1 cannot hold them in one object).
    $root = try { if ($Text.TrimStart().StartsWith('[', [StringComparison]::Ordinal)) { (('{"v":' + $Text + '}') | ConvertFrom-Json).v } else { $Text | ConvertFrom-Json } }
    catch {
        if ($_.Exception.Message -match 'different casing|duplicated keys') { throw 'JSON keys that differ only in letter case are not supported' }
        throw
    }
    , (ConvertFrom-SwJsonNode $root)
}

function ConvertFrom-SwJsonNode($Node) {
    if ($Node -is [Management.Automation.PSCustomObject]) {
        $d = [Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal)
        foreach ($p in $Node.PSObject.Properties) { $d[$p.Name] = ConvertFrom-SwJsonNode $p.Value }
        return , $d
    }
    if ($Node -is [array]) { return , [object[]]@(foreach ($e in $Node) { , (ConvertFrom-SwJsonNode $e) }) }
    if ($Node -is [int]) { return [long]$Node }
    if ($Node -is [decimal]) { return [double]$Node }
    $Node
}

function ConvertTo-SwJson($Value) { (ConvertTo-SwJsonText $Value '') + "`n" }

function ConvertTo-SwJsonText($Value, [string]$Indent) {
    # PowerShell 7's ConvertTo-Json layout on both shells: two-space indent, `"key": value`, `[]` and `{}` when empty,
    # and only quotes, backslashes and control characters (plus U+0085, U+2028, U+2029) escaped.
    if ($null -eq $Value) { return 'null' }
    if ($Value -is [bool]) { return $(if ($Value) { 'true' } else { 'false' }) }
    if ($Value -is [string] -or $Value -is [char]) { return ConvertTo-SwJsonString ([string]$Value) }
    if ($Value -is [int] -or $Value -is [long] -or $Value -is [int16] -or $Value -is [byte] -or $Value -is [uint32] -or $Value -is [uint64]) {
        return $Value.ToString([Globalization.CultureInfo]::InvariantCulture)
    }
    if ($Value -is [double] -or $Value -is [single] -or $Value -is [decimal]) {
        $t = ([double]$Value).ToString('R', [Globalization.CultureInfo]::InvariantCulture)
        return $(if ($t -match '^-?\d+$') { "$t.0" } else { $t })
    }
    $inner = "$Indent  "
    if ($Value -is [Collections.IDictionary]) {
        $items = @(foreach ($k in $Value.Keys) { $inner + (ConvertTo-SwJsonString ([string]$k)) + ': ' + (ConvertTo-SwJsonText $Value[$k] $inner) })
        if (-not $items.Count) { return '{}' }
        return "{`n" + ($items -join ",`n") + "`n$Indent}"
    }
    if ($Value -is [Management.Automation.PSCustomObject]) {
        $items = @(foreach ($p in $Value.PSObject.Properties) { $inner + (ConvertTo-SwJsonString $p.Name) + ': ' + (ConvertTo-SwJsonText $p.Value $inner) })
        if (-not $items.Count) { return '{}' }
        return "{`n" + ($items -join ",`n") + "`n$Indent}"
    }
    if ($Value -is [Collections.IEnumerable]) {
        $items = @(foreach ($e in $Value) { $inner + (ConvertTo-SwJsonText $e $inner) })
        if (-not $items.Count) { return '[]' }
        return "[`n" + ($items -join ",`n") + "`n$Indent]"
    }
    throw "ConvertTo-SwJson: unsupported value type $($Value.GetType().FullName)"
}

function ConvertTo-SwJsonString([string]$Text) {
    $sb = [Text.StringBuilder]::new('"')
    foreach ($ch in $Text.ToCharArray()) {
        $c = [int]$ch
        if ($c -eq 34) { $null = $sb.Append('\"') }
        elseif ($c -eq 92) { $null = $sb.Append('\\') }
        elseif ($c -eq 10) { $null = $sb.Append('\n') }
        elseif ($c -eq 13) { $null = $sb.Append('\r') }
        elseif ($c -eq 9) { $null = $sb.Append('\t') }
        elseif ($c -eq 8) { $null = $sb.Append('\b') }
        elseif ($c -eq 12) { $null = $sb.Append('\f') }
        elseif ($c -lt 32 -or $c -eq 0x85 -or $c -eq 0x2028 -or $c -eq 0x2029) { $null = $sb.Append(('\u{0:x4}' -f $c)) }
        else { $null = $sb.Append($ch) }
    }
    $null = $sb.Append('"')
    $sb.ToString()
}

function Get-SwHash([string]$Content) {
    Get-SwByteHash ($script:Utf8.GetBytes($Content.Replace("`r`n", "`n")))
}

function Get-SwConfig([string]$Root) {
    $path = Resolve-SwManagedPath $Root '.sw/config.json'
    if (-not (Test-Path -LiteralPath $path)) { throw "Not a SuperWorkspace project (missing .sw/config.json): $Root" }
    $config = Read-SwJson $path
    $null = Get-SwConfiguredTier $config
    $config
}

function Get-SwConfiguredTier($Config) {
    # Tiers are stated GitHub rules (.sw/workspace.md); only the hard limits are enforced.
    if ($Config -isnot [Collections.IDictionary]) { throw 'Workspace configuration must be an object.' }
    if (-not $Config.Contains('githubTier')) { return 0 }
    $tier = $Config['githubTier']
    if (($tier -isnot [int] -and $tier -isnot [long]) -or $tier -notin 0, 1, 2) { throw 'githubTier must be the supported integer 0, 1 or 2.' }
    [int]$tier
}

function Get-SwGitPolicy([Collections.IDictionary]$Config) {
    if (-not $Config.Contains('gitPolicy')) { return 'workspace' } # Preserve legacy installations.
    if (-not (Test-SwIn $Config['gitPolicy'] ('host', 'workspace'))) { throw "Config 'gitPolicy' must be 'host' or 'workspace'." }
    $Config['gitPolicy']
}

function Get-SwSkillDelivery([Collections.IDictionary]$Config) {
    # Physical delivery of the selected kit skills only; logical selection is unchanged. Missing keeps project copies.
    if (-not $Config.Contains('skillDelivery')) { return 'project-copy' }
    $mode = $Config['skillDelivery']
    if ($mode -isnot [string] -or -not (Test-SwIn $mode ('project-copy', 'central-v1'))) { throw "Config 'skillDelivery' must be 'project-copy' or 'central-v1'." }
    $mode
}

function Get-SwCentralSkillIds($Selection, $ProfileData) {
    # central-v1 covers the selected product skills only; profile skills have no central source and stay project copies.
    @($Selection.skills | Where-Object { -not (Test-SwIn $_ @($ProfileData['skills'])) })
}

function Get-SwProfileHome { [Environment]::GetFolderPath('UserProfile') }

function Get-SwCentralAvailability([string[]]$Ids, [string]$UserHome) {
    # Read-only: the installed local central record (schema 2) and the links and sources it names. Never scans
    # other homes and never installs. Availability is not a claim of which route a native command uses.
    $recordPath = Join-Path $UserHome '.sw/global.json'
    $install = "run sw.ps1 global install -Delivery central-v1 -Harness both -Component skills -Skills $($Ids -join ',')"
    $record = $null
    if (Test-Path -LiteralPath $recordPath -PathType Leaf) { try { $record = Read-SwJson $recordPath } catch { } }
    if ($record -isnot [Collections.IDictionary] -or $record['schema'] -ne 2 -or $record['homes'] -isnot [Collections.IDictionary]) {
        return "central prerequisites missing: no valid central delivery record ($recordPath); $install"
    }
    $owners = @{}
    foreach ($homeDir in $record['homes'].Keys) {
        $entries = $record['homes'][$homeDir]['entries']
        if ($entries -isnot [Collections.IDictionary]) { continue }
        foreach ($id in $Ids) {
            $leaf = Join-Path $homeDir "skills/$id"
            $item = Get-Item -LiteralPath $leaf -Force -ErrorAction SilentlyContinue
            $linked = $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
            $e = $entries["skills/$id"]
            if ($e -isnot [Collections.IDictionary]) {
                if ($linked) { "ownerless central link: $leaf (no record entry; left as found)" }
                continue
            }
            if (-not $linked) { "central link missing: $id ($leaf)"; continue }
            $target = [string]$e['normalizedTarget']
            if (-not $target -or -not (Test-SwIn ([string]@($item.Target)[0]) @([string]$e['rawReparseTarget']) -IgnoreCase)) { "central link changed: $id ($leaf)"; continue }
            if (-not (Test-SwSame ([string]$item.LinkType) 'Junction' -IgnoreCase)) { "central link changed: $id ($leaf is not a junction)"; continue }
            # Only the product source satisfies a selected kit skill; a personal namesake carries other instructions.
            $expected = if (Test-SwSame $id 'unreal-validation' -IgnoreCase) { 'project/profiles/unreal/files/.agents/skills/unreal-validation' } else { "project/base/.agents/skills/$id" }
            $productRoot = [string]$record['productRoot']
            $source = [string]$e['sourcePath']
            if (-not $productRoot -or -not $source -or -not (Test-SwSame ([string]$e['sourceTier']) 'product') -or
                -not (Test-SwSame ([IO.Path]::GetFullPath($source)) ([IO.Path]::GetFullPath((Join-Path $productRoot $expected))) -IgnoreCase) -or
                -not (Test-SwSame ([IO.Path]::GetFullPath($target)) ([IO.Path]::GetFullPath($source)) -IgnoreCase)) { "central source is not the product skill: $id ($target; a personal namesake does not count)"; continue }
            # The recorded leaf junction is the only link allowed; a redirected ancestor or source path is refused before any source is read.
            $redirect = try { Assert-SwPhysicalPath (Split-Path $leaf -Parent); Assert-SwPhysicalPath (Join-Path $target 'SKILL.md'); Assert-SwPhysicalPath (Join-Path $target 'agents/openai.yaml'); $null } catch { $_.Exception.Message }
            if ($redirect) { "central source redirected: $id ($redirect)"; continue }
            if (-not (Test-Path -LiteralPath (Join-Path $target 'SKILL.md') -PathType Leaf)) { "central source missing: $id ($target)"; continue }
            if (Test-SwIn $id $script:UserInvoked) {
                $data = try { Read-SwFrontmatter (Join-Path $target 'SKILL.md') @('name', 'description', 'disable-model-invocation') } catch { @{} }
                $meta = Join-Path $target 'agents/openai.yaml'
                $explicit = (Test-Path -LiteralPath $meta -PathType Leaf) -and (Read-SwText $meta) -cmatch '(?m)^policy:[ \t]*\n[ \t]+allow_implicit_invocation:[ \t]*false[ \t]*$'
                if (-not ((Test-SwSame $data['disable-model-invocation'] 'true') -and $explicit)) { "central invocation metadata missing: $id must stay user-invoked and explicit-only ($target)"; continue }
            }
            $owners[$id] = @($owners[$id]) + @($e['scopeOwners']) | Where-Object { $_ }
        }
    }
    foreach ($id in $Ids) {
        $lacking = @('claude', 'codex-skills' | Where-Object { -not (Test-SwIn $_ @($owners[$id])) })
        if ($lacking.Count) { "central prerequisites missing: $id not available for $($lacking -join ', '); $install" }
    }
}

function Get-SwUtc { [DateTime]::UtcNow.ToString('yyyy-MM-ddTHHmmssZ') }

# Diagnostics touch installed tools only through these two functions, so tests can replace them.
function Find-SwTool([string]$Name) {
    $cmd = Get-Command $Name -CommandType Application, ExternalScript -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { $cmd.Source } else { $null }
}

function Invoke-SwProbe([string]$Exe, [string[]]$Arguments) {
    # Captures stdout and the immediate native exit; a thrown launch is reported, not raised.
    try {
        $global:LASTEXITCODE = 0
        $out = Invoke-SwNative $Exe $Arguments
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
    [pscustomobject]@{ Name = $Name; State = $state; Version = $(if (Test-SwSame $state 'ok' -IgnoreCase) { [version]$m.Groups[1].Value }); ExitCode = $r.ExitCode }
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
    $config = Get-SwConfig $Root
    $users = @($config['users'] | Where-Object { $_ })
    if ($users.Count -gt 1) { throw 'Contributor identity is ambiguous; pass explicit -User/-From (Git display names are not contributor IDs).' }
    if ($users.Count -eq 1) { Assert-SwSafeName $users[0] 'contributor'; return $users[0] }
    # Legacy solo fallback, never a multi-contributor identity mapping.
    $name = Invoke-SwNative git @('-C', $Root, 'config', 'user.name')
    if (-not $name) { throw 'Set git config user.name, or pass -User/-From.' }
    $id = ($name -replace '[^A-Za-z0-9_-]', '').ToLowerInvariant()
    if (-not $id) { throw 'Pass explicit -User/-From; Git display name has no usable solo ID.' }
    $id
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

function Read-SwFrontmatter([string]$Path, [string[]]$Allowed) {
    # Top-level single-line scalar keys only (lowercase, `_` or `-`), each from $Allowed.
    $lines = @((Read-SwText $Path) -split "`n")
    if ($lines.Count -lt 3 -or (-not (Test-SwSame $lines[0] '---'))) { throw 'Missing opening frontmatter delimiter' }
    $data = [ordered]@{}; $close = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if (Test-SwSame $line '---') { $close = $i; break }
        if ($line -match '^([a-z][a-z_-]*): (.+)$') {
            $key = $Matches[1]
            if ((-not (Test-SwIn $key $Allowed)) -or $data.Contains($key)) { throw "Unknown or duplicate key: $key" }
            $data[$key] = ConvertFrom-SwScalar $Matches[2]
        } else { throw "Unsupported frontmatter at line $($i + 1): $line" }
    }
    if ($close -lt 0) { throw 'Missing closing frontmatter delimiter' }
    $body = ($lines | Select-Object -Skip ($close + 1)) -join "`n"
    if ([string]::IsNullOrWhiteSpace($body)) { throw 'Empty instruction body' }
    $data['__body'] = $body
    $data
}

# --- hard limits: the only Git/GitHub blocks, one table for both harnesses -------------

# Claude: each pattern becomes `Bash(*<p>)` and `PowerShell(*<p>)` deny rules in tracked .claude/settings.json. `*` is
# any text, so the leading `*` also covers a runner prefix such as `rtk` or a program path, `git*` covers git.exe, and
# a quoted mention (a commit message or a search) can match and be refused. A target that can end the command also gets `"` and `'` forms for a quoted runner
# (pwsh -c "git push origin main"), and `)` and backtick forms for a substitution ($(git push origin main)). Live (one
# Claude Code version, a scratch project) `bash -lc "git push origin main"` was denied while ordinary quoted commands
# (`git log --oneline -1 "main"`, `git push --dry-run origin "t3/x"`) ran; `git push origin "main"` was not tried. Codex: each
# pattern becomes a `forbidden` prefix_rule in .codex/rules: literal leading words, one alternative list per position,
# no wildcards; the placeholders below expand to the lists named.
# Both stop the command as written, not every spelling: guardrails, not a sandbox. .sw/workspace.md (Git flow) lists
# the known gaps and over-blocks; each command in its tables is a case below, so validate keeps the tables honest.
$script:HardLimitLists = [ordered]@{
    GIT        = '["git", "git.exe"]'
    GH         = '["gh", "gh.exe"]'
    REMOTE     = '["origin", "upstream", "personal"]'
    FORCE      = '["--force", "-f", "--force-with-lease", "--force-if-includes", "-uf", "-fu", "-vf", "-fv", "-qf", "-fq", "-nf", "-fn", "-df", "-fd"]'
    MAIN       = '["main", "HEAD:main", "refs/heads/main", "HEAD:refs/heads/main", ":main", "+main", "+HEAD:main"]'
    RESET_MODE = '["--hard", "--soft", "--mixed", "--merge", "--keep"]'
    COMMIT     = '["HEAD~", "HEAD~1", "HEAD~2", "HEAD~3", "HEAD~4", "HEAD~5", "HEAD^", "HEAD^^", "HEAD^1", "HEAD^2", "@~", "@~1", "@~2", "@~3", "@^", "@{u}", "@{upstream}", "@{1}", "HEAD@{1}", "ORIG_HEAD", "FETCH_HEAD", "MERGE_HEAD", "CHERRY_PICK_HEAD", "REBASE_HEAD", "REVERT_HEAD", "main", "origin/main", "upstream/main", "personal/main", "refs/heads/main"]'
    REBASE     = '["--rebase", "-r", "-vr", "-qr", "-rv", "-rq", "--rebase=true", "--rebase=merges", "--rebase=interactive", "--rebase=i", "--rebase=m", "--rebase=yes", "--rebase=on", "--rebase=1"]'
}
$script:HardLimits = @(
    [ordered]@{
        # A short-flag cluster with f first is caught by ` -f`; clusters ending in f are listed for the common push flags.
        Why    = 'Hard limit: no force-push. Hand the owner the exact command.'
        Claude = @('git*push*--force*', 'git*push* -f*', 'git*push* -uf*', 'git*push* -vf*', 'git*push* -qf*', 'git*push* -nf*', 'git*push* -df*', 'git*push* +*',
            'git*push *"+*', 'git*push *''+*')
        Codex  = @('[GIT, "push", FORCE]', '[GIT, "push", REMOTE, FORCE]', '[GIT, "push", REMOTE, "+HEAD"]')
    }
    [ordered]@{
        Why    = 'Hard limit: no push to main. Publish through a t3/ branch and a pull request.'
        Claude = @('git*push * main', 'git*push * main *', 'git*push * main"*', 'git*push * main''*', 'git*push * main)*', 'git*push * main`*', 'git*push *"main"*',
            'git*push *''main''*', 'git*push *:main', 'git*push *:main *', 'git*push *:main"*', 'git*push *:main''*', 'git*push *:main)*', 'git*push *:main`*',
            'git*push *refs/heads/main*', 'git*push *--all*', 'git*push *--mirror*')
        Codex  = @('[GIT, "push", REMOTE, MAIN]', '[GIT, "push", ["-u", "--set-upstream"], REMOTE, MAIN]', '[GIT, "push", ["--all", "--mirror"]]',
            '[GIT, "push", REMOTE, ["--all", "--mirror"]]', '[GIT, "push", ["--delete", "-d"], REMOTE, "main"]', '[GIT, "push", REMOTE, ["--delete", "-d"], "main"]')
    }
    [ordered]@{
        Why    = 'Hard limit: no gh release writes. Releases belong to the owner.'
        Claude = @(foreach ($gh in 'gh', 'gh.exe') { foreach ($v in 'create', 'edit', 'delete', 'upload') { "$gh release $v*" } })
        Codex  = @('[GH, "release", ["create", "edit", "delete", "delete-asset", "upload"]]')
    }
    [ordered]@{
        Why    = 'Hard limit: no repository-setting changes. Settings belong to the owner.'
        Claude = @(foreach ($gh in 'gh', 'gh.exe') { foreach ($v in 'repo edit', 'repo delete', 'repo rename', 'repo archive', 'ruleset', 'secret', 'variable') { "$gh $v*" } })
        Codex  = @('[GH, "repo", ["edit", "delete", "rename", "archive"]]', '[GH, ["ruleset", "secret", "variable"]]')
    }
    [ordered]@{
        # A branch flag is matched after any earlier options (`git branch -q -f main`); an option between the flag and
        # `main`, or an unlisted cluster (`-qfB main`, `-qBmain`, `-qCmain`), is a documented gap. Each flag starts a word,
        # after a space or a tab (` -B main`, "`t-Bmain"), so a branch name holding one (`t3/plan-b`, `t3/webmain`,
        # `t3/Bmain`) is not refused; the verb may still sit inside a word (`git log --branches -M main` is refused), so a
        # tab after `git` stays covered. No pattern puts `*` between `-b` and `main`: the PowerShell rules ignore case, so
        # it would refuse `git checkout -b t3/x main`.
        Why    = 'Hard limit: never rewrite main history.'
        Claude = @('git*filter-branch*', 'git*filter-repo*', 'git*update-ref *main*', 'git*branch main -f*', 'git*branch main --force*') +
            @(foreach ($w in ' ', "`t") {
                foreach ($f in '-f main', '--force main', '-D main', '-M main', '-C main') { "git*branch*$w$f*" }
                foreach ($f in '-B main', '-fB main', '-Bmain', '-fBmain') { "git*checkout*$w$f*" }
                foreach ($f in '-C main', '-Cmain', '--force-create main', '--force-create=main') { "git*switch*$w$f*" }
            })
        Codex  = @('[GIT, ["filter-branch", "filter-repo"]]', '[GIT, "update-ref", ["main", "refs/heads/main"]]', '[GIT, "update-ref", "-d", ["main", "refs/heads/main"]]',
            '[GIT, "branch", ["-f", "--force", "-D", "-M", "-C"], "main"]', '[GIT, "branch", ["-q", "--quiet"], ["-f", "--force", "-D", "-M", "-C"], "main"]',
            '[GIT, "branch", "main", ["-f", "--force"]]', '[GIT, ["checkout", "switch"], ["-B", "-fB", "-C", "--force-create"], "main"]',
            '[GIT, ["checkout", "switch"], ["-f", "--force", "-q", "--quiet", "--discard-changes"], ["-B", "-C", "--force-create"], "main"]',
            '[GIT, ["checkout", "switch"], ["-Bmain", "-fBmain", "-Cmain", "--force-create=main"]]',
            '[GIT, ["checkout", "switch"], ["-f", "--force", "-q", "--quiet", "--discard-changes"], ["-Bmain", "-Cmain", "--force-create=main"]]')
    }
    [ordered]@{
        # Neither harness sees the current branch, so these hold on every branch. Claude: a mode, `--amend` or
        # `--rebase` flag is matched anywhere after the verb, so any spelling of the program and verb (git.exe, git -C, a
        # quoted verb, doubled spaces) is covered; a HEAD~ HEAD^ @~ @^ @{ operator anywhere after `reset `. A rule cannot
        # tell `git reset <sha>` from `git reset <path>` or see a `--` separator, so a commit-like name (a hex digit,
        # ORIG_HEAD, main, t3/, a remote or refs/ prefix) is matched only as the first argument after `git`, `git -* ` or
        # `git.* ` (never after `--`; a hex-led path such as docs/x.md is refused too), and a reset with `-q`, `-N` or
        # `--end-of-options` and an argument is refused outright. `git -* <verb>` covers options before the verb without
        # matching the word inside a message or `--no-rebase`. Codex lists common commit names only. Plain `git reset`,
        # `git reset HEAD <path>`, `git reset -- <path>` and `git restore --staged` stay open for unstaging.
        # No pattern contains a doubled space: installed alone in a live Claude Code session (2026-10-15, one version),
        # `git  *` also denied `git diff --stat`, as if the two spaces were read as one; `git "*` and `git '*` alone did
        # not deny it in the same test. No pattern ends in a lone quote after a verb either (`git "*`, `git reset "*`):
        # how Claude Code reads a quote in a pattern is undocumented, that test did not show such a pattern denying the
        # quoted spelling it targets, and read literally `git reset "*` would refuse quoted-path unstaging. A quoted or
        # doubled-space verb or argument is a documented gap instead.
        Why    = 'Hard limit: never rewrite or discard history. Make a new commit, merge instead of rebasing (git pull --no-rebase, git merge main), and unstage with git restore --staged.'
        Claude = @('git*reset*--hard*', 'git*reset*--soft*', 'git*reset*--mixed *', 'git*reset*--merge *', 'git*reset*--keep *', 'git*reset *HEAD~*', 'git*reset *HEAD^*',
            'git*reset *@~*', 'git*reset *@^*', 'git*reset *@{*', 'git*reset -q *', 'git*reset --quiet *', 'git*reset -N *', 'git*reset --end-of-options *',
            'git*commit*--amend*', 'git*pull*--rebase*', 'git*pull* -r*', 'git*pull* -vr*', 'git*pull* -qr*') +
            @(foreach ($g in 'git', 'git -*', 'git.*') {
                foreach ($a in @('ORIG_HEAD', 'FETCH_HEAD', 'MERGE_HEAD', 'CHERRY_PICK_HEAD', 'REBASE_HEAD', 'REVERT_HEAD', 'main', 't3/', 'origin/', 'upstream/', 'personal/',
                        'refs/') + [char[]]'0123456789abcdef') { "$g reset $a*" }
                "$g rebase*"
            })
        Codex  = @('[GIT, "reset", RESET_MODE]', '[GIT, "reset", ["-q", "--quiet"], RESET_MODE]', '[GIT, "reset", COMMIT]', '[GIT, "reset", ["-q", "--quiet", "-N", "--end-of-options"], COMMIT]',
            '[GIT, "commit", "--amend"]', '[GIT, "commit", ["-a", "--all", "--no-edit", "--no-verify", "-q", "--quiet"], "--amend"]', '[GIT, "rebase"]',
            '[GIT, "pull", REBASE]', '[GIT, "pull", REMOTE, REBASE]', '[GIT, "pull", REMOTE, "main", REBASE]')
    }
)
# Static decision cases for validate: the expected decision of each rule set as written (a model, not the harness).
# Every command in the gap and over-block tables of .sw/workspace.md is one of these cases (the kit's tests check it
# against the row's Harness column), so a kind can hold a hard-limit form, a documented gap or a documented over-block.
# Both: Claude denies and Codex forbids (a hard-limit form, or an over-block in both). ClaudeOnly: Claude denies and
# Codex does not (a Codex gap, or a Claude over-block). CodexOnly: Codex forbids and Claude does not (a Claude gap, or a
# Codex over-block). PowerShellOnly: only Claude's PowerShell rules, which ignore case, deny (a Claude Bash and Codex gap,
# or a PowerShell over-block). Neither: work the limits must not block. Gap: a form neither rule set blocks that the
# limits should cover, or that only a stated rule forbids (proved still open; closing one moves its case).
$script:HardLimitCases = [ordered]@{
    Both           = @('git push --force', 'git push -f origin t3/x', 'git push origin --force-with-lease', 'git push origin +HEAD', 'git push origin "+main"', 'git push origin main',
        'git push -u origin main', 'git push origin HEAD:main', 'git push origin "main"', 'git push origin --delete main', 'git push --mirror', 'gh release create v1',
        'gh release upload v1 a.zip', 'gh repo edit --visibility public', 'gh repo delete x', 'gh ruleset list', 'gh secret set TOKEN', 'gh variable set NAME', 'git filter-branch',
        'git update-ref refs/heads/main HEAD~1', 'git branch -f main HEAD~1', 'git switch -C main', 'git reset --hard', 'git reset --hard HEAD~1', 'git reset HEAD~1 --hard',
        'git reset --soft', 'git reset --soft HEAD~1', 'git reset --mixed HEAD~1', 'git reset HEAD~1', 'git reset HEAD^', 'git reset @~2', 'git reset ORIG_HEAD',
        'git reset origin/main', 'git reset main', 'git reset --merge ORIG_HEAD', 'git reset --keep HEAD~1', 'git reset -q HEAD~1', 'git commit --amend --no-edit',
        'git rebase -i HEAD~3', 'git rebase main', 'git pull --rebase', 'git pull -r', 'git pull --rebase origin main', 'git pull origin --rebase', 'git pull origin main --rebase',
        'git pull -r origin main', 'git pull origin main -r', 'git pull --rebase=merges', 'git pull --rebase=interactive origin main', 'git reset FETCH_HEAD',
        'git reset CHERRY_PICK_HEAD', 'git reset refs/heads/main', 'git reset -q origin/main', 'git reset --quiet ORIG_HEAD', 'git reset "HEAD~1"', 'git.exe reset --hard',
        'git.exe reset HEAD~1', 'git.exe reset origin/main', 'git.exe commit --amend', 'git.exe rebase main', 'git.exe pull --rebase', 'git.exe push --force',
        'git.exe push origin main', 'git.exe branch -f main HEAD~1', 'gh.exe release create v1', 'gh.exe repo edit --visibility public', 'gh.exe secret set TOKEN',
        'git push -uf origin t3/x', 'git push -fu origin t3/x', 'git push -vf origin t3/x', 'git push -qf origin t3/x', 'git "reset" --hard', "git 'push' --force",
        'git.exe "push" --force', 'git  reset --hard', 'git checkout -B main', 'git checkout -B main HEAD~1', 'git checkout -Bmain HEAD~1', 'git checkout -fB main HEAD~1',
        'git checkout -f -B main HEAD~1', 'git switch -Cmain HEAD~1', 'git switch --force-create main', 'git switch --force-create=main HEAD~1',
        'git switch --discard-changes -C main HEAD~1', 'git branch --force main HEAD~1', 'git branch -q -f main HEAD~1', 'git branch main -f x', 'git reset -N origin/main',
        'git reset --end-of-options origin/main', 'git pull -vr', 'git pull -qr', 'git pull -rv origin main', 'git checkout -fBmain HEAD~1',
        "git`tbranch -f main HEAD~1", "git`tcheckout -B main HEAD~1", "git`tswitch -Cmain HEAD~1", "git`treset -N origin/main",
        "git branch -q`t-f main HEAD~1", "git checkout -q`t-B main HEAD~1", "git switch -q`t-Cmain HEAD~1", 'git switch -q -Cmain HEAD~1',
        # Over-blocks in both.
        'git reset origin/main -- a.md', 'git reset HEAD~1 -- a.md', 'gh ruleset view 1', 'gh secret list', 'gh variable list', 'gh release create --help', 'git rebase --help',
        'git rebase --continue', 'git rebase --abort', 'git rebase --show-current-patch')
    ClaudeOnly     = @('git reset 1a2b3c4', 'git reset 1a2b3c4 --hard', 'git reset HEAD~7', 'git reset t3/other', 'git commit -m x --amend', 'git -C . push --force',
        'git -c x=y push origin main', 'git -C . reset --hard', 'git -C . reset 1a2b3c4', 'git -C . rebase main', 'git -c core.editor=true rebase -i main', 'git -C . pull --rebase',
        'git pull origin t3/x --rebase', 'git push origin t3/x --force', 'rtk git push --force', 'rtk git reset --hard', 'rtk proxy gh release create v1', 'env A=1 git push --force',
        'cmd /c git push --force', 'bash -lc "git push origin main"', "pwsh -c 'git rebase main'", '$(git push origin main)', 'echo `git push origin main`',
        'bash -c "git reset --hard HEAD~1"', 'git reset -q 1a2b3c4', 'git.exe reset 1a2b3c4', 'git.exe -C . reset t3/other', 'git reset --no-refresh HEAD~1',
        'git push origin --force-with-lease=refs/heads/t3/x:abcd123', 'git push origin t3/x:main', 'git push origin @:main', 'git push --no-verify origin main',
        'git push https://example.com/o/r.git main', 'git push origin +t3/x', 'git pull --rebase=TRUE', '/usr/bin/git reset --hard', 'C:/Git/cmd/git.exe push --force',
        'C:/Git/cmd/git.exe reset 1a2b3c4', 'git push -fuv origin t3/x', 'git -C . "push" --force', 'git -C . checkout -B main HEAD~1',
        # Claude over-blocks.
        'git commit -m "note: git rebase is a hard limit"', 'gh pr create --body "never git push origin main"', 'git log --grep "reset --hard"', 'git -C . log --grep rebase',
        'git checkout -b t3/push-x -f', 'git reset docs/a.md', 'git reset build.ps1', 'git reset maintenance.md', 'git reset refs/x.md', 'git reset -q -- notes.md',
        'git reset --quiet HEAD a.md', 'git reset --quiet -- a.md', 'git reset -N -- a.md', 'git reset -- notes@{1}.md', 'git pull --rebase=false', 'git branch -D main-old',
        'git push origin refs/heads/main-docs', 'git update-ref refs/heads/t3/x main', 'git log --branches -M main')
    CodexOnly      = @('git reset --mixed', 'git reset --merge', 'git reset --keep', '"git" reset origin/main', "git`treset origin/main", 'git.exe "reset" origin/main',
        'git "rebase" main', 'git  reset origin/main', 'git  rebase main', 'git reset  origin/main', 'git reset "origin/main"')
    PowerShellOnly = @('git reset ABCD123', 'git reset BISECT_HEAD', 'Git push --force', 'GIT.EXE reset --hard', 'git reset AGENTS.md', 'git reset CHANGELOG.md', 'git reset Docs/a.md',
        'git checkout -b main-x', 'git switch -c main-x', 'git checkout -bmain-x', 'git switch -cmain-x', 'git log t3/fix-reset -n 5')
    Neither        = @('git push origin t3/rebuild-b-kit', 'git push -u origin t3/fix-flow', 'git push --set-upstream origin t3/x', 'git push origin t3/x --follow-tags',
        'git push origin HEAD', 'git push origin t3/main-docs', 'pwsh -c "git push origin t3/main-docs"', "bash -c 'git push origin t3/x'", 'gh pr create --draft --title x',
        'gh pr merge --auto --squash 12', 'gh pr merge --disable-auto 12', 'git commit -m tidy', 'git commit -am "merge main into t3/x"', 'git status', 'git merge main',
        'git branch -d t3/old', 'gh release view v1', 'gh release list', 'gh repo view', 'gh repo clone x', 'git fetch origin main', 'git log main', 'git switch main',
        'git checkout main', 'git update-ref refs/heads/t3/x HEAD', 'git reset', 'git reset HEAD', 'git reset HEAD notes.md', 'git reset HEAD -- docs/a.md', 'git reset -- notes.md',
        'git reset -- docs/a.md', 'git reset notes.md', 'git reset -p', 'git restore --staged notes.md', 'git restore --staged .', 'git pull origin main',
        'git pull --no-rebase origin main', 'git pull --ff-only', 'git config pull.rebase false', 'git reset HEAD -- docs/origin/a.md', 'git reset -- src/ORIG_HEAD.txt',
        'git reset HEAD -- refs/x.md', 'git reset -- main/notes.md', 'git reset -- t3/notes.md', 'git reset HEAD -- upstream/a.md personal/b.md', 'git reset -- 1a2b.md',
        'git reset -q', 'git reset --quiet', 'git.exe status', 'gh.exe pr view 12', 'git.exe reset -- docs/a.md', 'git -C . reset HEAD -- origin/a.md',
        'git commit -m "fix reset docs"', 'git push -u origin t3/fix-reset-rules', 'git checkout -b t3/x', 'git checkout -b t3/x main', 'git checkout -b t3/web main',
        'git switch -c t3/x main', 'git branch t3/x main', 'git reset -N', 'git reset -- AGENTS.md', 'gh help release create', 'git help rebase',
        # A thread-branch name holding a flag or `main` (review round 5).
        'git checkout -b t3/webmain main', 'git switch -c t3/cmain main', 'git checkout t3/Bmain', 'git switch t3/Cmain', 'git checkout -b t3/plan-b main',
        'git checkout -b t3/x-fb main', 'git switch -c t3/plan-c main', 'git branch t3/plan-f main', 'git branch t3/plan-d main', 'git branch t3/plan-m main',
        'git branch t3/plan-c main', 'git log -n 5 t3/fix-reset', "git checkout -q`t-b t3/plan-b main", "git switch -q`t-c t3/webmain main", "git checkout -q`tt3/Bmain",
        "git branch -q`tt3/plan-f main")
    Gap            = @('git reset v1.0', 'git reset topic', 'git reset origin', 'git reset ":/text"', 'git reset --no-refresh origin/main', 'git reset --recurse-submodules 1a2b3c4',
        'git push -uvf origin t3/x', 'git push -4f origin t3/x', 'git pull -vqr', 'git pull -4r', 'git -C . "reset" 1a2b3c4', 'git reset --har', 'git commit --amen',
        'git pull --reb', 'git push origin --mirr', 'git pu""sh --force', 'git p\ush --force', '$g push --force', "git push \`n--force", 'gh release -R o/r create v1',
        'gh api -X PATCH repos/o/r -f visibility=public', 'git undo', 'gh repo sync --force', 'git push origin main>push.log', 'git push origin :', "git push origin 'refs/heads/*'",
        'git branch -f -q main HEAD~1', 'git branch --force --no-track main x', 'git checkout -qfB main HEAD~1', 'git checkout -qfBmain HEAD~1', 'git branch -M t3/x main',
        'git fetch . +HEAD~1:main', 'git checkout -qBmain HEAD~1', 'git switch -qCmain HEAD~1',
        'git branch -f t3/x HEAD~1', 'git update-ref refs/heads/t3/x HEAD~1', 'git checkout -B t3/x HEAD~1', 'gh repo unarchive', 'gh repo deploy-key add key.pub',
        'gh repo autolink create', 'gh workflow disable ci.yml', 'gh label delete bug', 'gh pr merge 12', 'git checkout -- .', 'git restore .', 'git clean -fd', 'git stash',
        'git reset "1a2b3c4"', "git reset '1a2b3c4'", 'git  reset 1a2b3c4', 'git "reset" 1a2b3c4')
}

function Get-SwHardLimitCases { $script:HardLimitCases }

function Get-SwClaudeDeny {
    # The hard-limit deny rules for tracked .claude/settings.json, Bash and PowerShell alike.
    foreach ($limit in $script:HardLimits) { foreach ($p in $limit.Claude) { "Bash(*$p)"; "PowerShell(*$p)" } }
}

function Get-SwClaudeSettings($EditDeny) {
    # Shared project settings: hard limits and profile edit denies, .env reads ask. No model, mode or hook.
    $deny = @(Get-SwClaudeDeny) + @(@($EditDeny) | Where-Object { $_ } | ForEach-Object { "Edit(**/$_)" })
    ConvertTo-SwJson ([ordered]@{ permissions = [ordered]@{ allow = @('Skill'); ask = @('Read(**/.env)', 'Read(**/.env.*)'); deny = $deny } })
}

function Get-SwCodexRuleBlocks {
    # One `prefix_rule` per pattern; `match` gives Codex a load-time example built from each position's first word.
    foreach ($limit in $script:HardLimits) {
        foreach ($p in $limit.Codex) {
            # Whole words only: a list value may contain a placeholder name (REBASE_HEAD).
            foreach ($k in $script:HardLimitLists.Keys) { $v = $script:HardLimitLists[$k]; $p = [regex]::Replace($p, "\b$k\b", { $v }) }
            $example = @((ConvertFrom-SwJson $p) | ForEach-Object { @($_)[0] }) -join ' '
            "prefix_rule(`n    pattern = $p,`n    decision = `"forbidden`",`n    justification = `"$($limit.Why)`",`n    match = [`"$example`"],`n)"
        }
    }
}

function Get-SwCodexRules {
    $head = @(
        '# Generated by SuperWorkspace from its hard limits; sw update rewrites this file.'
        '# Put project-owned rules in another .rules file. Codex loads project rules only'
        '# when it trusts this project, and rules are experimental.'
        '# Prefix rules match literal leading words only. Not matched: options or runner'
        '# prefixes before them (git -C <dir> push, rtk git push, env, cmd /c), a'
        '# path-qualified or differently cased program (/usr/bin/git, Git), remotes'
        '# other than origin, upstream and personal, a branch before the force or rebase'
        '# flag (git push origin <branch> --force), an argument before the amend flag'
        '# (git commit -m <msg> --amend), a reset to an unlisted commit (a SHA, another'
        '# branch or tag), --force-with-lease=<ref>, a <src>:main refspec other than'
        '# HEAD:main, +refspecs other than +HEAD and +main, an abbreviated long option'
        '# (git commit --amen), Git aliases and configuration, and a bare git push while'
        '# main is checked out. A shell-wrapped command meets these rules only when'
        '# Codex parses it as plain words; an unquoted word with ~ ^ { } * ? [ ] $'
        '# or a backtick (git reset --hard HEAD~1) leaves it unchecked (openai/codex'
        '# source, not verified live). .sw/workspace.md lists the known gaps.'
        '# Guardrails, not a sandbox.'
    )
    ($head -join "`n") + "`n`n" + (@(Get-SwCodexRuleBlocks) -join "`n`n") + "`n"
}

function Read-SwCodexRules([string]$Text) {
    # Parses the kit's own rendering only: one-line `pattern = [...]` and `decision = "..."` per prefix_rule.
    foreach ($block in @($Text -split '(?m)^prefix_rule\(' | Select-Object -Skip 1)) {
        $p = [regex]::Match($block, '(?m)^\s*pattern = (\[.*\]),\s*$')
        $d = [regex]::Match($block, '(?m)^\s*decision = "([a-z]+)",\s*$')
        if (-not $p.Success -or -not $d.Success) { throw 'Codex rules: each prefix_rule needs a one-line pattern and decision (kit format)' }
        [pscustomobject]@{ Pattern = (ConvertFrom-SwJson $p.Groups[1].Value); Decision = $d.Groups[1].Value }
    }
}

$script:ClaudeRuleRegex = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
function Get-SwClaudeRuleRegex([string]$Rule) {
    # The static model's regex for one Claude Bash/PowerShell rule, built once; $null for any other rule. `*` is any
    # text; a trailing ` *` (or `:*`) as the only wildcard also matches the bare command; PowerShell ignores case.
    $regex = $null
    if ($script:ClaudeRuleRegex.TryGetValue($Rule, [ref]$regex)) { return $regex }
    if ($Rule -match '^(Bash|PowerShell)\((.*)\)$') {
        $options = if (Test-SwSame $Matches[1] 'PowerShell') { 'IgnoreCase, Singleline' } else { 'Singleline' }
        $pattern = $Matches[2]
        if ($pattern.EndsWith(':*', [StringComparison]::Ordinal)) { $pattern = $pattern.Substring(0, $pattern.Length - 2) + ' *' }
        $text = '\A' + [regex]::Escape($pattern).Replace('\*', '.*') + '\z'
        if ($pattern.EndsWith(' *', [StringComparison]::Ordinal) -and $pattern.IndexOf('*', [StringComparison]::Ordinal) -eq $pattern.Length - 1) { $text = '\A' + [regex]::Escape($pattern.Substring(0, $pattern.Length - 2)) + '(?: .*)?\z' }
        $regex = [regex]::new($text, $options)
    }
    $script:ClaudeRuleRegex[$Rule] = $regex
    $regex
}

function Split-SwClaudeCommand([string]$Command) {
    # The parts the Claude model checks: a compound command matches when any part does.
    foreach ($part in $Command -split '&&|\|\||[;|&\n]') { if ($part.Trim()) { $part.Trim() } }
}

function Test-SwClaudeRule([string]$Rule, [string]$Command) {
    # Static model of one Claude Bash/PowerShell rule (Get-SwClaudeRuleRegex) over each part of a compound command.
    # Not Claude's evaluator: no quote-aware parsing or wrapper stripping.
    $regex = Get-SwClaudeRuleRegex $Rule
    if ($null -eq $regex) { return $false }
    foreach ($part in Split-SwClaudeCommand $Command) { if ($regex.IsMatch($part)) { return $true } }
    $false
}

function Test-SwCodexRule($Pattern, [string]$Command) {
    # Static model of one Codex prefix_rule pattern: the leading words equal the pattern's literals (any of a list),
    # after splitting a plain chain on && || ; | and dropping the quotes around a fully quoted word, as a shell passes
    # it. Not Codex's evaluator: no other shell parsing, no wrapper unwrapping, no runtime plain-word filter.
    $p = @($Pattern)
    foreach ($part in $Command -split '&&|\|\||[;|]') {
        $words = @($part.Trim() -split '\s+' | Where-Object { $_ } | ForEach-Object { $_ -replace '^"([^"]*)"$', '$1' -replace "^'([^']*)'$", '$1' })
        if ($words.Count -lt $p.Count) { continue }
        $ok = $true
        for ($i = 0; $ok -and $i -lt $p.Count; $i++) { $ok = (Test-SwIn $words[$i] @($p[$i])) }
        if ($ok) { return $true }
    }
    $false
}

function Assert-SwSafeName([string]$Value, [string]$Label) {
    # Comms names become path segments; block traversal and separators.
    if ($Value -notmatch '^[A-Za-z0-9_.-]+$' -or (Test-SwIn $Value '.', '..' -IgnoreCase)) { throw "Invalid ${Label}: '$Value' (allowed: letters, digits, underscore, dot, hyphen; not '.' or '..')" }
}

function Assert-SwSafeFileName([string]$Value, [string]$Label) {
    if (-not (Test-SwSame $Value ([IO.Path]::GetFileName($Value)) -IgnoreCase)) { throw "Invalid ${Label}: '$Value' must be a bare file name" }
}

# --- validation -------------------------------------------------------------------

# The kit skill set (a legacy installation keeps every one); user-invoked skills keep model invocation off.
$script:Skills = @('agent-documentation', 'handoff', 'minimal-change', 'research', 'resume', 'review', 'status',
    'structured-debugging', 'validate', 'work')
$script:UserInvoked = @('handoff', 'research', 'resume', 'review', 'status', 'validate', 'work')
# Outputs earlier kits owned and this one no longer renders (OpenCode, roles, manager, merged skills). Update removes
# them while unedited and releases an edited one to the project, keeping its bytes.
$script:RetiredOutputs = @('opencode.jsonc', '.sw/roles.json', '.sw/lib/Sw.Manager.psm1', '.opencode/plugins/rtk.ts') +
    @(foreach ($r in 'project-leader', 'project-developer', 'project-research', 'project-review', 'project-plan', 'project-architect', 'project-worker', 'project-build', 'project-documentation') { ".opencode/agents/$r.md" }) +
    @(foreach ($c in 'work', 'resume', 'workspace-check', 'handoff', 'inbox', 'validate', 'review', 'status', 'research') { ".opencode/commands/$c.md" }) +
    @(foreach ($s in 'project-planning', 'focused-review', 'task-handoff', 'free-models') { ".agents/skills/$s/SKILL.md" })
$script:MojibakePattern = ([char]0x00E2 + [char]0x20AC) + '|' + ([char]0x00C3 + [char]0x00E9) + '|' + ([char]0x00C2 + [char]0x00A0)

function Get-SwRetiredOutputs { $script:RetiredOutputs }

# --- profile selection v1: generator-owned installation, not runtime loading or hiding -------

# Fixed floor; a catalogue that drops it is rejected, never silently completed.
$script:SelectionFloor = [ordered]@{ skills = @('handoff', 'resume', 'review', 'status', 'validate', 'work'); context = @('core'); checks = @('diff-hygiene', 'workspace-static') }
$script:SelectionSets = @('skills', 'context', 'checks')

function Assert-SwExactKeys($Map, [string[]]$Keys, [string]$Label) {
    if ($Map -isnot [Collections.IDictionary]) { throw "Selection ${Label} must be an object" }
    $extra = @($Map.Keys | Where-Object { -not (Test-SwIn $_ $Keys) }); $missing = @($Keys | Where-Object { -not (Test-SwIn $_ @($Map.Keys)) })
    if ($extra.Count -or $missing.Count) { throw "Selection ${Label} needs exactly keys $($Keys -join ', ')$(if ($extra.Count) { "; unsupported: $($extra -join ', ')" })$(if ($missing.Count) { "; missing: $($missing -join ', ')" })" }
}

function Assert-SwIdList($Value, [string]$Label, [string[]]$Allowed) {
    # A list of canonical IDs (also safe path segments): no scalar/null, duplicate, path-like or unknown entry.
    if ($Value -isnot [array]) { throw "Selection ${Label} must be a list" }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($v in $Value) {
        if ($v -isnot [string] -or $v -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { throw "Selection ${Label}: '$v' is not a canonical identifier" }
        if (-not $seen.Add($v)) { throw "Selection ${Label}: duplicate '$v'" }
        if ($PSBoundParameters.ContainsKey('Allowed') -and (-not (Test-SwIn $v $Allowed))) { throw "Selection ${Label}: unknown '$v'" }
    }
}

function Join-SwIdSet { $set = [Collections.Generic.SortedSet[string]]::new([StringComparer]::Ordinal); foreach ($list in $args) { foreach ($v in $list) { $null = $set.Add($v) } }; , [string[]]@($set) }

function Resolve-SwSelection {
    <#
    .SYNOPSIS Pure v1 resolver shared by the kit renderer and installed validation: core + profile + capabilities.
    Throws on any malformed input; the result lists generator-owned components only.
    #>
    param($Selection, [string]$Profile, $ProfileData, $Catalogue)
    $isInt = { param($v, $n) ($v -is [int] -or $v -is [long]) -and $v -eq [long]$n }
    Assert-SwExactKeys $Catalogue @('version', 'core', 'capabilities', 'context', 'checks') 'catalogue'
    if (-not (& $isInt $Catalogue['version'] 2)) { throw 'Selection catalogue version must be 2' }
    Assert-SwIdList $Catalogue['context'] 'catalogue context'
    Assert-SwIdList $Catalogue['checks'] 'catalogue checks'
    $allowed = @{ context = $Catalogue['context']; checks = $Catalogue['checks'] }
    $sets = {
        param($Map, [string]$Label)
        Assert-SwExactKeys $Map $script:SelectionSets $Label
        foreach ($k in $script:SelectionSets) {
            if ($allowed.Contains($k)) { Assert-SwIdList $Map[$k] "$Label $k" $allowed[$k] } else { Assert-SwIdList $Map[$k] "$Label $k" }
        }
    }
    & $sets $Catalogue['core'] 'catalogue core'
    foreach ($k in $script:SelectionSets) {
        $lost = @($script:SelectionFloor[$k] | Where-Object { -not (Test-SwIn $_ $Catalogue['core'][$k]) })
        if ($lost.Count) { throw "Selection catalogue core drops the fixed v1 floor ($k): $($lost -join ', ')" }
    }
    $caps = $Catalogue['capabilities']
    if ($caps -isnot [Collections.IDictionary]) { throw 'Selection catalogue capabilities must be an object' }
    Assert-SwIdList @($caps.Keys) 'catalogue capability names'
    foreach ($c in $caps.Keys) { & $sets $caps[$c] "capability $c" }

    if ($Profile -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { throw "Selection profile '$Profile' is not a canonical identifier" }
    if ($ProfileData -isnot [Collections.IDictionary]) { throw 'Selection profile data must be an object' }
    Assert-SwIdList $ProfileData['skills'] 'profile skills'
    $composition = $ProfileData['composition']
    Assert-SwExactKeys $composition @('capabilities', 'context', 'checks') "profile $Profile composition"
    Assert-SwIdList $composition['capabilities'] "profile $Profile capabilities" @($caps.Keys)
    Assert-SwIdList $composition['context'] "profile $Profile context" $allowed.context
    Assert-SwIdList $composition['checks'] "profile $Profile checks" $allowed.checks

    Assert-SwExactKeys $Selection @('version', 'capabilities') 'config'
    if (-not (& $isInt $Selection['version'] 1)) { throw "Unsupported selection version '$($Selection['version'])' (supported: 1)" }
    Assert-SwIdList $Selection['capabilities'] 'config capabilities' @($caps.Keys)

    # Capabilities are additive to the preset's defaults; no negative overrides or fallback.
    $chosen = Join-SwIdSet $composition['capabilities'] $Selection['capabilities']
    $pick = { param([string]$Set) foreach ($c in $chosen) { $caps[$c][$Set] } }
    [ordered]@{
        version      = 1
        profile      = $Profile
        capabilities = $chosen
        skills       = Join-SwIdSet $Catalogue['core']['skills'] @(& $pick 'skills') $ProfileData['skills']
        context      = Join-SwIdSet $Catalogue['core']['context'] $composition['context'] @(& $pick 'context')
        checks       = Join-SwIdSet $Catalogue['core']['checks'] $composition['checks'] @(& $pick 'checks')
    }
}

function Get-SwSelectionKnown($Catalogue, $ProfileData) {
    # Kit-owned skill IDs an installation can recognize; anything else is a project-owned extra.
    $skills = @($script:Skills) + @($Catalogue['core']['skills']) + @($ProfileData['skills']) + @(foreach ($v in $Catalogue['capabilities'].Values) { $v['skills'] })
    [ordered]@{ skills = Join-SwIdSet $skills }
}

function Test-SwLinkedPath([string]$Root, [string]$Relative) {
    # True when the path or any parent up to the root is a link or junction (never followed).
    Test-SwSame ((Invoke-SwContextRead $Root $Relative {}).Status) 'unsafe' -IgnoreCase
}

function Test-SwLocalOnly([string]$Root, [string]$Relative) {
    # A per-user override is allowed only when untracked AND git-ignored; git failure fails closed.
    # check-ignore works on a non-existent path too, so a missing .gitignore entry is caught either way.
    $tracked = Invoke-SwNative git @('-C', $Root, 'ls-files', '--', $Relative)
    if ($LASTEXITCODE -ne 0 -or $tracked) { return $false }
    Invoke-SwNative git @('-C', $Root, 'check-ignore', '-q', '--', $Relative)
    $LASTEXITCODE -eq 0
}

function Get-SwResearchWarnings([string]$Root) {
    # Lenient lint for docs/research/*.md: warnings only, never errors.
    $dir = Join-Path $Root 'docs/research'
    if (-not (Test-Path -LiteralPath $dir)) { return }
    foreach ($file in Get-ChildItem -LiteralPath $dir -Filter *.md -File -Force | Sort-Object Name) {
        $rel = "docs/research/$($file.Name)"
        $lines = @((Read-SwText $file.FullName) -split "`n")
        $first = [array]::FindIndex([string[]]$lines, [Predicate[string]] { param($l) $l -match '^## ' })
        $header = if ($first -ge 0) { $lines[0..([math]::Max(0, $first - 1))] } else { $lines }
        # Explicit dated snapshots are not six-section topics; date and finding lint still applies.
        if (-not (Test-SwIn '<!-- sw:research-format: snapshot -->' $header)) {
            $missing = @(1..6 | Where-Object { $n = $_; -not @($lines | Where-Object { $_ -match "^## $n\. " }).Count })
            if ($missing.Count) { "${rel}: missing section(s) $($missing -join ', ') (expected '## 1.' to '## 6.')" }
        }
        if (-not (($header -join "`n") -match '\d{4}-\d{2}-\d{2}')) { "${rel}: header has no YYYY-MM-DD date" }
        # Findings: F<n>. blocks under '## 2.'; a subsection heading containing "local" covers its findings.
        $inFindings = $false; $localHeading = $false; $id = $null; $block = ''
        $check = {
            if ($id -and -not $localHeading -and $block -notmatch 'https?://|Same\s[\s\S]*?\sas\s+(\d{2}-)?F\d+|\bLocal\b|\(F\d+|\b\d{2}-F\d+|\bSources?\s+(?:\d{2}-)?F\d+\b') {
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

function Get-SwStartupBudget($Config, [string]$AgentsMdText, $Skills) {
    # Static kit estimate shared by validate and context: AGENTS.md plus every installed skill's name and description,
    # the metadata a fresh thread can see before any skill loads. One session total; there are no roles.
    $cap = if ($Config.Contains('startupBudgetBytes')) { [int]$Config['startupBudgetBytes'] } else { 12100 }
    $agentsMd = [Text.Encoding]::UTF8.GetByteCount($AgentsMdText)
    $skillBytes = 0
    foreach ($s in $Skills.GetEnumerator()) { $skillBytes += [Text.Encoding]::UTF8.GetByteCount($s.Key + $s.Value['description']) }
    $total = $agentsMd + $skillBytes
    [pscustomobject]@{ Scope = 'session'; AgentsMd = $agentsMd; Skills = $skillBytes; Total = $total; Tokens = [math]::Ceiling($total / 4); Cap = $cap }
}

function Test-SwProject {
    <#
    .SYNOPSIS Static workspace contract check (skills, generated harness files, hard limits, portability, budget, hygiene).
    #>
    [CmdletBinding()]
    param([string]$Path, [switch]$CheckLinks, [switch]$Quiet)
    $problems = [Collections.Generic.List[string]]::new()
    $counts = [ordered]@{ Contracts = 0; HardLimits = 0; HygieneFiles = 0; LocalLinks = 0 }
    $warnings = @()
    function Require($Condition, [string]$Message, [string]$Category = 'Contracts') {
        $counts[$Category]++
        if (-not $Condition) { $problems.Add($Message) }
    }
    function Portable($Node, [string]$Label) {
        if ($null -eq $Node) { return }
        if ($Node -is [string]) {
            Require ($Node -notmatch '(?i)((?<![a-z])[a-z]:[\\/]|\\\\|/(?:Users|home|opt|usr|Applications)/)') "$Label contains an absolute machine path"
        } elseif ($Node -is [Collections.IDictionary]) {
            foreach ($key in @($Node.Keys)) {
                if (Test-SwSame $key '__body' -IgnoreCase) { continue }
                Require ($key -notmatch '^(model|small_model|provider|providers|shell|shell_path|shellPath)$') "$Label forbidden shared pin: $key"
                Portable $Node[$key] "$Label.$key"
            }
        } elseif ($Node -is [Collections.IEnumerable]) { foreach ($entry in $Node) { Portable $entry $Label } }
    }
    function NoEffort([string]$Text, [string]$Label) {
        # Models are chosen per thread: no effort/variant field and no model#variant suffix in shared files.
        Require ($Text -notmatch '(?im)(^\s*|")(effort|effortLevel|reasoningEffort|reasoning_effort|variant)"?\s*:') "$Label must be model-free: effort/reasoningEffort/variant field"
        Require ($Text -notmatch '(?i)"?model"?\s*:\s*"?[^\s",]*#') "$Label must be model-free: #variant model suffix"
    }
    function Links([string]$File, [string]$Text) {
        # -CheckLinks: each local Markdown link (inline or image, with an optional title or an <angle> destination, and each
        # reference definition) resolves inside the root without crossing a link or junction (never followed), with the
        # same letter case as the names on disk (GitHub and Linux are case-sensitive). Fenced code blocks, inline code
        # spans, escaped brackets (an odd number of backslashes) and footnotes hold no links. A rooted target (/x,
        # \\server, C:/x, C:x, file:) is refused before URLs are skipped, so a drive letter is never taken for a scheme;
        # `scheme://` and mailto:/tel: URLs and pure anchors are skipped, any other colon (notes.md:x, docs:a.md, a
        # stream such as a.md::$DATA) is refused, and an anchor after a file name is not checked. Line-based: a title or
        # code span that continues on the next line is not followed, and indented code blocks are read as text.
        $dest = '(?:<([^<>\n]*)>|((?!<)(?:[^\s()\\]|\\.|\((?:[^\s()\\]|\\.)*\))+))'
        $title = '(?:\s+(?:"(?:[^"\\]|\\.)*"|''(?:[^''\\]|\\.)*''|\((?:[^()\\]|\\.)*\)))?'
        $inline = '(?<=(?:^|[^\\])(?:\\\\)*)\]\(\s*' + $dest + $title + '\s*\)'
        $definition = '^ {0,3}\[(?!\^)(?:[^\]\\]|\\.)+\]:[ \t]*' + $dest + $title + '[ \t]*$'
        $rooted = '^([a-zA-Z]:|[\\/]|file:)'
        $rel = (Get-SwRelativePath $Root $File).Replace('\', '/')
        $fence = ''; $n = 0
        foreach ($line in $Text -split "`n") {
            $n++
            if ($fence) { if ($line -match ('^[ \t]*' + [regex]::Escape($fence) + [regex]::Escape([string]$fence[0]) + '*[ \t]*$')) { $fence = '' }; continue }
            if ($line -match '^[ \t]*(`{3,}(?=[^`]*$)|~{3,})') { $fence = $Matches[1]; continue }
            $plain = [regex]::Replace($line, '(?<!`)(`+)(?!`).*?(?<!`)\1(?!`)', '')
            foreach ($m in @([regex]::Matches($plain, $inline)) + @([regex]::Matches($plain, $definition))) {
                $target = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
                $at = "${rel}:$n"
                if ($target -match $rooted) { Require $false "${at}: rooted local link refused, not checked: $target" LocalLinks; continue }
                if (-not $target -or $target -match '^(#|[a-zA-Z][a-zA-Z0-9+.-]*://|(?i:mailto|tel):)') { continue }
                $target = [Uri]::UnescapeDataString((($target -split '#', 2)[0] -replace '\\([!-/:-@\[-`{-~])', '$1'))
                if ($target -match $rooted -or [IO.Path]::IsPathRooted($target)) { Require $false "${at}: rooted local link refused, not checked: $target" LocalLinks; continue }
                if ($target.Contains(':')) { Require $false "${at}: local link with a colon refused (a stream or an unknown scheme), not checked: $target" LocalLinks; continue }
                try { $full = [IO.Path]::GetFullPath((Join-Path (Split-Path $File -Parent) $target)) }
                catch { Require $false "${at}: unreadable local link, not checked: $target" LocalLinks; continue }
                # Windows matches names ignoring case: compare the link as written (from the file's on-disk folder) with the disk.
                $folder = Get-SwOnDiskCase $Root (Split-Path $File -Parent)
                $written = [IO.Path]::GetFullPath((Join-Path $(if ($folder) { $folder } else { Split-Path $File -Parent }) $target)).TrimEnd([char[]]@([char]92, [char]47))
                $top = ([IO.Path]::GetFullPath($Root)).TrimEnd([char[]]@([char]92, [char]47))
                # The root itself, perhaps named from above it (../../<root>): the case check below starts at the root.
                if (Test-SwSame ($full.TrimEnd([char[]]@([char]92, [char]47))) $top -IgnoreCase) { Require (Test-SwSame $written $top) "${at}: local link differs in letter case from the name on disk (breaks on GitHub and Linux): $target (on disk: the project root, $(Split-Path $top -Leaf))" LocalLinks; continue }
                if (-not (Test-SwContained $Root $full)) { Require $false "${at}: local link escapes the project root, refused and not checked: $target" LocalLinks; continue }
                $status = (Invoke-SwContextRead $Root ((Get-SwRelativePath $Root $full)) {}).Status
                if (-not (Test-SwSame $status 'ok' -IgnoreCase)) { Require $false "${at}: $(if (Test-SwSame $status 'unsafe' -IgnoreCase) { 'local link crosses a link or junction, not followed:' } else { 'missing local link' }) $target" LocalLinks; continue }
                $disk = Get-SwOnDiskCase $Root $written
                Require (Test-SwSame $disk $written) "${at}: local link differs in letter case from the name on disk (breaks on GitHub and Linux): $target (on disk: $(if ($disk) { (Get-SwRelativePath $Root $disk).Replace('\', '/') } else { 'not found' }))" LocalLinks
            }
        }
    }
    function Json([string]$Rel) {
        # A generated shared JSON file stays strict JSON (no comments or trailing commas).
        $text = Read-SwText (Join-Path $Root $Rel)
        $outside = [regex]::Replace($text, '"(?:[^"\\]|\\.)*"', '""')
        if ($outside -match '//|/\*|,\s*[}\]]') { throw "$Rel must stay strict JSON (no comments or trailing commas)" }
        try { ConvertFrom-SwJson $text } catch { throw "$($_.Exception.Message): $Rel" }
    }

    try {
        $Root = Resolve-SwRoot $Path
        $config = Get-SwConfig $Root
        $null = Get-SwGitPolicy $config
        $delivery = Get-SwSkillDelivery $config
        foreach ($key in 'context7', 'watcherIgnore') { if ($config.Contains($key)) { $warnings += "Retired config key '$key' (OpenCode) is ignored; run sw update to remove it" } }
        $profileData = Read-SwJson (Join-Path $Root '.sw/profile.json')
        # Selection v1 (config opt-in) recomputes the installed set from the catalogue; legacy keeps the all-base contract.
        $selection = $null; $known = $null
        if ($config.Contains('selection')) {
            $catalogueFile = Join-Path $Root '.sw/selection.json'
            if (-not (Test-Path -LiteralPath $catalogueFile -PathType Leaf)) { throw 'Selection v1 needs .sw/selection.json; run sw update' }
            $catalogue = Read-SwJson $catalogueFile
            $selection = Resolve-SwSelection $config['selection'] ([string]$config['profile']) $profileData $catalogue
            $known = Get-SwSelectionKnown $catalogue $profileData
            Require (Test-SwSame (ConvertTo-SwJson $profileData['effectiveSelection']) (ConvertTo-SwJson $selection)) '.sw/profile.json effectiveSelection does not match config, profile and .sw/selection.json; run sw update'
        }
        # central-v1: the selected kit skills come from the local central record, not project copies; project-owned skills stay here.
        $central = @()
        if (Test-SwSame $delivery 'central-v1') {
            if (-not $selection) { throw 'skillDelivery central-v1 needs selection v1; run sw update <path> -SelectionV1' }
            $central = Get-SwCentralSkillIds $selection $profileData
        }
        if (Test-Path -LiteralPath (Join-Path $Root '.claude/.sw-generated')) { $warnings += 'Retired local Claude adapter present (.claude/.sw-generated); remove it with the previous kit, which needs PowerShell 7 (pwsh .sw/sw.ps1 claude disable), before sw update' }
        # Per-user files stay untracked and ignored (checked even when absent, so the ignore entry is proven).
        foreach ($rel in '.claude/settings.local.json', '.sw/models.local.md') { Require (Test-SwLocalOnly $Root $rel) "Per-user file must be untracked and git-ignored: $rel" }

        $skills = @{}
        $hygiene = [Collections.Generic.List[string]]::new()
        $skillDir = Join-Path $Root '.agents/skills'
        if (-not (Test-Path -LiteralPath $skillDir)) { if (-not $central.Count) { $problems.Add('Missing directory: .agents/skills') } }
        else {
            foreach ($flat in Get-ChildItem -LiteralPath $skillDir -Filter *.md -File -Force) { Require $false "Unsupported flat skill: $($flat.Name)" }
            foreach ($file in @(Get-ChildItem -LiteralPath $skillDir -Recurse -Filter SKILL.md -File -Force)) {
                $hygiene.Add($file.FullName)
                try {
                    $data = Read-SwFrontmatter $file.FullName @('name', 'description', 'disable-model-invocation')
                    Portable $data $file.Name
                    Require ($data.Contains('description') -and $data['description']) "$($file.Name): description required"
                    Require (Test-SwSame $data['name'] $file.Directory.Name) "$($file.FullName): name must equal directory"
                    # Agent Skills spec: lowercase letters, digits and single inner hyphens, at most 64 characters.
                    Require ($data['name'] -cmatch '^[a-z0-9]+(-[a-z0-9]+)*$' -and $data['name'].Length -le 64) "$($file.FullName): name must be 1-64 lowercase letters, digits and single hyphens (Agent Skills spec)"
                    Require ($data['description'].Length -le 1024) "$($file.FullName): description exceeds 1024 characters (Agent Skills spec)"
                    Require (-not $skills.ContainsKey($data['name'])) "Duplicate skill: $($data['name'])"
                    $skills[$data['name']] = $data
                } catch { $problems.Add("$($file.FullName): $($_.Exception.Message)") }
            }
        }
        # Do not manufacture dependent failures after a parser/layout failure.
        if ($problems.Count) { throw 'Definition validation failed; dependent contract checks were skipped' }

        $requiredSkills = @(if ($selection) { $selection.skills | Where-Object { -not (Test-SwIn $_ $central) } } else { @($script:Skills) + @($profileData['skills']) })
        if ($selection) {
            # Known deselected kit skills must be gone; unknown project-owned ones are kept and disclosed, not adopted.
            foreach ($id in $skills.Keys | Sort-Object) {
                if (Test-SwIn $id $known.skills) { Require (Test-SwIn $id $selection.skills) "Deselected kit component installed: .agents/skills/$id/ (remove it or select it; not hidden by selection)" }
                else { $warnings += "Project-owned extra kept, outside the selection: .agents/skills/$id/ (not adopted; not shown to be hidden or safe)" }
            }
        }
        foreach ($name in $requiredSkills) {
            Require ($skills.ContainsKey($name)) "Missing skill: $name"
            if ((Test-SwIn $name $script:UserInvoked) -and $skills.ContainsKey($name)) {
                Require (Test-SwSame $skills[$name]['disable-model-invocation'] 'true') "Skill $name must stay user-invoked (disable-model-invocation: true)"
                # Codex reads explicit-only from agents/openai.yaml beside SKILL.md (policy.allow_implicit_invocation, default true).
                $meta = Join-Path $skillDir "$name/agents/openai.yaml"
                $explicit = (Test-Path -LiteralPath $meta -PathType Leaf) -and (Read-SwText $meta) -cmatch '(?m)^policy:[ \t]*\n[ \t]+allow_implicit_invocation:[ \t]*false[ \t]*$'
                Require $explicit "Skill $name must stay explicit-only in Codex: .agents/skills/$name/agents/openai.yaml with policy.allow_implicit_invocation: false (run sw update)"
            }
        }
        # Claude reads project skills from .claude/skills only: each installed kit skill has a byte-equal copy there.
        foreach ($name in $skills.Keys | Sort-Object | Where-Object { -not (Test-SwIn $_ $central) }) {
            $src = Join-Path $skillDir $name
            foreach ($f in Get-SwPhysicalFiles $src) {
                $rel = (Get-SwRelativePath $src $f.FullName).Replace('\', '/')
                $copy = Join-Path $Root ".claude/skills/$name/$rel"
                $same = (Test-Path -LiteralPath $copy -PathType Leaf) -and (Test-SwSame (Read-SwText $copy) (Read-SwText $f.FullName))
                if (Test-SwIn $name $requiredSkills) { Require $same "Claude skill copy differs or is missing: .claude/skills/$name/$rel (run sw update; edit both copies together)" }
                elseif (-not $same) { $warnings += "Project-owned skill without a matching Claude copy: .claude/skills/$name/$rel (Claude threads do not see it)" }
            }
        }
        foreach ($id in $central) {
            foreach ($rel in ".agents/skills/$id", ".claude/skills/$id") {
                if (Test-SwLinkedPath $Root $rel) { Require $false "Ownerless link at $rel in central-v1 (neither a project copy nor the recorded central link; left as found)"; continue }
                $files = try { @(Get-SwPhysicalFiles (Join-Path $Root $rel)).Count } catch { -1 }
                # Both routes would be discoverable; which one a native command uses is not asserted.
                if ($files) { Require $false "Stray kit copy retained in central-v1: $rel/$(if ($files -lt 0) { ' (contains a nested link)' }) (duplicate risk; remove it with update <path> -SkillDelivery central-v1)" }
            }
        }
        if ($central.Count) { foreach ($p in @(Get-SwCentralAvailability $central (Get-SwProfileHome))) { Require $false $p } }

        # Claude loads the canonical rules through one import; no rules copy.
        $importFile = Join-Path $Root '.claude/CLAUDE.md'
        $import = if (Test-Path -LiteralPath $importFile -PathType Leaf) { (Read-SwText $importFile).Trim() } else { '' }
        $importTarget = if ($import -match '^@([^\r\n]+)$') { [IO.Path]::GetFullPath((Join-Path (Split-Path $importFile) $Matches[1])) } else { '' }
        Require ((Test-SwSame $importTarget (Join-Path $Root 'AGENTS.md') -IgnoreCase) -and (Test-Path -LiteralPath $importTarget -PathType Leaf)) 'Claude import .claude/CLAUDE.md must be @../AGENTS.md, resolving to the root AGENTS.md'

        # Hard limits, the only Git/GitHub blocks: rule presence plus static decision cases. Not runtime enforcement.
        $settingsRel = '.claude/settings.json'; $rulesRel = '.codex/rules/workspace.rules'
        $deny = $null; $codex = $null
        if (-not (Test-Path -LiteralPath (Join-Path $Root $settingsRel) -PathType Leaf)) { Require $false "Missing $settingsRel (run sw update)" }
        else {
            $settings = Json $settingsRel
            Portable $settings $settingsRel
            NoEffort (Read-SwText (Join-Path $Root $settingsRel)) $settingsRel
            $perm = if ($settings['permissions'] -is [Collections.IDictionary]) { $settings['permissions'] } else { @{} }
            $deny = @($perm['deny'] | Where-Object { $_ -is [string] })
            foreach ($rule in Get-SwClaudeDeny) { Require (Test-SwIn $rule $deny) "Claude hard limit missing from ${settingsRel}: $rule (presence only, not runtime enforcement)" }
            foreach ($g in @($profileData['editDeny'] | Where-Object { $_ })) { Require (Test-SwIn ("Edit(**/$g)") $deny) "Claude profile edit deny missing from ${settingsRel}: Edit(**/$g)" }
            Require (-not (Test-SwIn 'Bash(*)' @($perm['allow']))) 'Claude must not allow Bash(*)'
        }
        if (-not (Test-Path -LiteralPath (Join-Path $Root $rulesRel) -PathType Leaf)) { Require $false "Missing $rulesRel (run sw update)" }
        else {
            $rulesText = Read-SwText (Join-Path $Root $rulesRel)
            foreach ($block in Get-SwCodexRuleBlocks) { Require ($rulesText.Contains($block)) "Codex hard limit missing from ${rulesRel}: $(($block -split "`n")[1].Trim()) (presence only; loads only in a trusted project)" }
            $codex = @(Read-SwCodexRules $rulesText | Where-Object { Test-SwSame $_.Decision 'forbidden' })
        }
        # A denial is proved on the installed file; an allowed case on the kit's own rules, so stricter project additions
        # still validate.
        $kitDeny = @(Get-SwClaudeDeny); $kitCodex = @(Read-SwCodexRules (Get-SwCodexRules) | Where-Object { Test-SwSame $_.Decision 'forbidden' })
        $claudeRegex = @{}
        foreach ($set in 'installed', 'kit') {
            foreach ($tool in 'Bash', 'PowerShell') {
                $claudeRegex["$set $tool"] = @(@(if (Test-SwSame $set 'kit' -IgnoreCase) { $kitDeny } else { $deny }) | Where-Object { $_ -and $_.StartsWith("$tool(", [StringComparison]::Ordinal) } | ForEach-Object { Get-SwClaudeRuleRegex $_ } | Where-Object { $_ })
            }
        }
        foreach ($kind in $script:HardLimitCases.Keys) {
            $wantCodex = (Test-SwIn $kind 'Both', 'CodexOnly' -IgnoreCase)
            foreach ($c in $script:HardLimitCases[$kind]) {
                if ($null -ne $deny) {
                    $parts = @(Split-SwClaudeCommand $c)
                    foreach ($tool in 'Bash', 'PowerShell') {
                        $wantClaude = (Test-SwIn $kind 'Both', 'ClaudeOnly' -IgnoreCase) -or ((Test-SwSame $kind 'PowerShellOnly' -IgnoreCase) -and (Test-SwSame $tool 'PowerShell' -IgnoreCase))
                        $hit = $false
                        foreach ($regex in $claudeRegex["$(if ($wantClaude) { 'installed' } else { 'kit' }) $tool"]) {
                            foreach ($part in $parts) { if ($regex.IsMatch($part)) { $hit = $true; break } }
                            if ($hit) { break }
                        }
                        Require ($hit -eq [bool]$wantClaude) "STATIC claude $tool [$c]: $(if ($wantClaude) { 'expected deny, got no deny' } elseif (Test-SwSame $kind 'Gap' -IgnoreCase) { 'documented gap is now denied by the kit rules; move the case and update the gap list' } else { 'expected no deny from the kit rules, got deny' })" HardLimits
                    }
                }
                if ($null -ne $codex) {
                    $hit = $false
                    foreach ($rule in $(if ($wantCodex) { $codex } else { $kitCodex })) { if (Test-SwCodexRule $rule.Pattern $c) { $hit = $true; break } }
                    Require ($hit -eq [bool]$wantCodex) "STATIC codex [$c]: $(if ($wantCodex) { 'expected forbidden, got not forbidden' } elseif (Test-SwSame $kind 'Gap' -IgnoreCase) { 'documented gap is now forbidden by the kit rules; move the case and update the gap list' } else { 'expected not forbidden by the kit rules, got forbidden' })" HardLimits
                }
            }
        }

        # T3 Code project scripts: the read-only tools stay one click away.
        if (-not (Test-Path -LiteralPath (Join-Path $Root 't3.json') -PathType Leaf)) { Require $false 'Missing t3.json (run sw update)' }
        else {
            $t3 = Json 't3.json'
            Portable $t3 't3.json'
            $scripts = @($t3['scripts'] | Where-Object { $_ -is [Collections.IDictionary] } | ForEach-Object { [string]$_['command'] })
            # Either shell, with or without the process-scope execution policy bypass the kit writes.
            foreach ($c in 'validate', 'doctor', 'context') { Require (@($scripts | Where-Object { $_ -cmatch "^(?:powershell|pwsh)(?:\.exe)? -NoProfile(?: -ExecutionPolicy Bypass)? -File \.sw/sw\.ps1 $c`$" }).Count -gt 0) "t3.json must keep the $c script: powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 $c" }
        }

        $agentsMdText = Read-SwText (Join-Path $Root 'AGENTS.md')
        Require ($agentsMdText -cmatch '(?m)^## Project identity\s*$') 'AGENTS.md must have a "## Project identity" heading (the project-owned section)'
        foreach ($block in 'core', 'profile') {
            Require ($agentsMdText -cmatch "(?s)<!-- sw:begin $block -->.*?<!-- sw:end $block -->" -and ([regex]::Matches($agentsMdText, "<!-- sw:begin $block -->")).Count -eq 1 -and ([regex]::Matches($agentsMdText, "<!-- sw:end $block -->")).Count -eq 1) "AGENTS.md requires one complete managed $block block"
        }
        $ignoreText = Read-SwText (Join-Path $Root '.gitignore')
        Require ($ignoreText -cmatch '(?ms)^# sw:begin superworkspace\n.*?^# sw:end superworkspace$' -and ([regex]::Matches($ignoreText, '(?m)^# sw:(begin|end) superworkspace$')).Count -eq 2) '.gitignore requires one complete managed block'
        if (@($profileData['lfs']).Count) {
            $attrsPath = Join-Path $Root '.gitattributes'
            $attrs = if (Test-Path -LiteralPath $attrsPath -PathType Leaf) { Read-SwText $attrsPath } else { '' }
            $match = [regex]::Match($attrs, '(?ms)^# sw:begin superworkspace\n(.*?)^# sw:end superworkspace$')
            Require ($match.Success -and ([regex]::Matches($attrs, '(?m)^# sw:(begin|end) superworkspace$')).Count -eq 2) '.gitattributes requires one complete profile LFS block'
            foreach ($pattern in $profileData['lfs']) { Require (Test-SwIn ("$pattern filter=lfs diff=lfs merge=lfs -text") @($match.Groups[1].Value -split "`n")) ".gitattributes missing profile LFS rule: $pattern" }
        }
        $b = Get-SwStartupBudget $config $agentsMdText $skills
        if (-not $Quiet) { Write-Output "Startup budget: $($b.Scope) = $($b.Total) bytes, ~$($b.Tokens) tokens (bytes/4 estimate; tokenizer varies); cap $($b.Cap)" }
        Require ($b.Total -le $b.Cap) "Startup budget exceeded for $($b.Scope): $($b.Total) > $($b.Cap) bytes (trim AGENTS.md or raise startupBudgetBytes with evidence)"

        # Hygiene: shared workspace files, including untracked ones.
        foreach ($rel in 'AGENTS.md', '.sw/config.json', '.sw/workspace.md', '.sw/collaboration.md', '.sw/sw.ps1', '.sw/lib/Sw.Project.psm1', '.claude/CLAUDE.md', $settingsRel, $rulesRel, 't3.json') {
            $full = Join-Path $Root $rel
            if (Test-Path -LiteralPath $full -PathType Leaf) { $hygiene.Add($full) }
        }
        foreach ($file in Get-SwUnique $hygiene ([StringComparer]::OrdinalIgnoreCase)) {
            $counts.HygieneFiles++
            $n = 0
            $text = Read-SwText $file
            foreach ($line in $text -split "`n") {
                $n++
                if ($line -match '[\t ]+$') { $problems.Add("${file}:${n}: trailing whitespace") }
                if ($line -match '^(<<<<<<<|=======|>>>>>>>)( |$)') { $problems.Add("${file}:${n}: conflict marker") }
                if ($file.EndsWith('.md', [StringComparison]::Ordinal) -and $line -match $script:MojibakePattern) { $problems.Add("${file}:${n}: possible mojibake") }
            }
            if ($CheckLinks -and $file.EndsWith('.md', [StringComparison]::Ordinal)) { Links $file $text }
        }
        # -CheckLinks also checks the local links in docs/**/*.md (links only, not hygiene). Each directory is checked before
        # it is listed; a link or junction inside docs/ is reported and never followed.
        if ($CheckLinks) {
            $queue = [Collections.Generic.Queue[string]]::new(); $queue.Enqueue('docs')
            while ($queue.Count) {
                $dir = $queue.Dequeue()
                $listing = Invoke-SwContextRead $Root $dir { param($f) if ([IO.Directory]::Exists($f)) { , @(Get-ChildItem -LiteralPath $f -Force | Sort-Object Name) } }
                if (Test-SwSame $listing.Status 'unsafe' -IgnoreCase) { $warnings += "-CheckLinks did not follow linked $dir"; continue }
                foreach ($item in @($listing.Value | Where-Object { $_ })) {
                    $rel = "$dir/$($item.Name)"
                    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { $warnings += "-CheckLinks did not follow linked $rel"; continue }
                    if ($item.PSIsContainer) { $queue.Enqueue($rel) }
                    elseif (Test-SwSame $item.Extension '.md' -IgnoreCase) { Links $item.FullName (Read-SwText $item.FullName) }
                }
            }
        }

        # Research lint (warnings only; never changes the exit code).
        $warnings += @(Get-SwResearchWarnings $Root)
    } catch { $problems.Add($_.Exception.Message) }

    Write-Output "Static workspace validation: contracts=$($counts.Contracts); hard-limit cases=$($counts.HardLimits); hygiene files=$($counts.HygieneFiles); local links=$($counts.LocalLinks). NOT runtime enforcement."
    foreach ($w in $warnings) { Write-Output "WARNING: $w" }
    if ($problems.Count) {
        foreach ($p in $problems) { Write-Output "ERROR: $p" }
        Write-Output "FAILED: $($problems.Count) error(s)."
        $global:LASTEXITCODE = 1
        return
    }
    Write-Output 'PASS: workspace contracts and static hard-limit cases.'
    $global:LASTEXITCODE = 0
}

# --- comms ------------------------------------------------------------------------------

function Invoke-SwComms {
    <#
    .SYNOPSIS sw comms send|inbox|event|close|archive
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory)][ValidateScript({ Test-SwIn $_ 'send', 'inbox', 'event', 'close', 'archive' -IgnoreCase })][string]$Action,
        [string]$To, [string]$From, [string]$User, [string]$Subject, [string]$Body, [string]$Task,
        [string]$Event = 'progress', [ValidateScript({ Test-SwIn $_ 'pending', 'in_progress', 'complete', 'blocked' -IgnoreCase })][string]$Status = 'in_progress',
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
            if ($PSCmdlet.ShouldProcess($file, 'write message')) {
                $file = New-SwExclusiveFile $dir $base '.md' $text
                Write-Output "Message written: $((Get-SwRelativePath $Root $file)) (local until a human pushes it)."
            }
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
            $src = Resolve-SwManagedPath $Root ".sw/comms/inbox/$User/$Message"
            $dst = Resolve-SwManagedPath $Root ".sw/comms/archive/inbox/$User/$Message"
            if ($PSCmdlet.ShouldProcess($src, 'archive')) {
                # The outer approval covers directory creation and the move.
                New-Item -ItemType Directory -Force (Split-Path $dst) -Confirm:$false -ErrorAction Stop | Out-Null
                Move-Item -LiteralPath $src -Destination $dst -Confirm:$false -ErrorAction Stop
                Write-Output "Archived: $Message"
            }
        }
        'event' {
            if (-not $Task) { throw 'event needs -Task <task-id>.' }
            $author = if ($From) { $From } else { Get-SwUser $Root }
            $branch = (Invoke-SwNative git @('-C', $Root, 'branch', '--show-current'))
            $head = (Invoke-SwNative git @('-C', $Root, 'rev-parse', 'HEAD'))
            # Task records churn on every event; list other changes only, at most 10.
            $changed = @(Invoke-SwNative git @('-C', $Root, 'status', '--porcelain') | Where-Object { $_ -and (-not ([string]$_.Substring(3).TrimStart('"')).StartsWith('.sw/comms/', [StringComparison]::OrdinalIgnoreCase)) })
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
            if ($PSCmdlet.ShouldProcess($file, 'write task event')) {
                $file = New-SwExclusiveFile $taskDir "$utc-$author-$Event" '.md' $text
                Write-Output "Event written: $((Get-SwRelativePath $Root $file)). Fill the <placeholders> before handing off."
            }
        }
        'close' {
            if (-not $Task -or -not $Outcome) { throw 'close needs -Task and -Outcome.' }
            $src = Resolve-SwManagedPath $Root ".sw/comms/tasks/$Task"
            $dst = Resolve-SwManagedPath $Root ".sw/comms/archive/$Task"
            $eventDir = Resolve-SwManagedPath $Root ".sw/comms/archive/$Task/events"
            $summaryPath = Resolve-SwManagedPath $Root ".sw/comms/archive/$Task/SUMMARY.md"
            if (-not (Test-Path -LiteralPath $src)) { throw "No task record: .sw/comms/tasks/$Task" }
            $events = @(Get-ChildItem -LiteralPath $src -Filter *.md -File -Force | Sort-Object Name)
            $head = (Invoke-SwNative git @('-C', $Root, 'rev-parse', 'HEAD'))
            if (Test-Path -LiteralPath $dst) { throw "Archive already exists, refusing to overwrite: .sw/comms/archive/$Task" }
            $author = if ($From) { $From } elseif ($User) { $User } else { Get-SwUser $Root }
            $summary = "# $Task - summary`n`n- **Outcome:** $Outcome`n- **Closed:** $([DateTime]::UtcNow.ToString('u')) by $author at $head`n- **Events:** $($events.Count), kept in ``events/`` for evidence; read this summary instead.`n`n" +
                (($events | ForEach-Object { "- $($_.Name)" }) -join "`n") + "`n"
            if ($PSCmdlet.ShouldProcess($dst, 'archive task')) {
                # Move the whole task folder (not just *.md) so nothing non-markdown is silently dropped.
                New-Item -ItemType Directory -Force $dst -Confirm:$false -ErrorAction Stop | Out-Null
                Move-Item -LiteralPath $src -Destination $eventDir -Confirm:$false -ErrorAction Stop
                # Catch statement-terminating writer errors even when the caller uses -ErrorAction Continue.
                try { Write-SwFile $summaryPath $summary } catch { throw }
                Write-Output "Closed $Task -> .sw/comms/archive/$Task/SUMMARY.md"
            }
        }
    }
}

function Add-SwUser {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Position = 0, Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+\z', Options = 'None')][string]$Name, [string]$Path)
    $Root = Resolve-SwRoot $Path
    $configPath = Join-Path $Root '.sw/config.json'
    $config = Read-SwJson $configPath
    $gitPolicy = Get-SwGitPolicy $config
    $users = [Collections.Generic.List[string]]@($config['users'])
    if (-not (Test-SwIn $Name $users -IgnoreCase)) { $users.Add($Name) }
    $config['users'] = @($users)
    $placeholder = Resolve-SwManagedPath $Root ".sw/comms/inbox/$Name/.gitkeep"
    if ($PSCmdlet.ShouldProcess($configPath, "add contributor $Name")) {
        Write-SwFile $configPath (ConvertTo-SwJson $config)
        if (-not (Test-Path -LiteralPath $placeholder)) { Write-SwFile $placeholder '' }
    }
    Write-Output "Contributor $Name recorded."
    if (Test-SwSame $gitPolicy 'host' -IgnoreCase) { Write-Output 'Use the project-owned Git onboarding workflow; no branch is created or prescribed.' }
    else { Write-Output 'They work in T3 Code threads: on main, or in a T3 worktree thread (branch prefix t3/) from published main. No personal branch is created.' }
    Write-Output "Send them .sw/onboarding.md; they check their setup with: powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 doctor -User $Name"
}

function Get-SwDoctorHint([string]$Tool) {
    $winget = @{ git = 'Git.Git'; gh = 'GitHub.cli' }
    if ($winget.Contains($Tool)) { "winget install $($winget[$Tool])" }
    elseif (Test-SwSame $Tool 't3' -IgnoreCase) { 'T3 Code desktop: Settings > General > About > Install t3 command; or the CLI from https://t3.codes' }
    elseif (Test-SwSame $Tool 'claude' -IgnoreCase) { 'install Claude Code (T3 Code Claude threads run the claude binary)' }
    elseif (Test-SwSame $Tool 'codex' -IgnoreCase) { 'connect Codex in T3 Code (Settings > Providers) or install the Codex CLI' }
    else { 'install rtk' }
}

function Get-SwCodexTrust([string]$Root, [string]$CodexHome) {
    # Best effort, read-only: 'trusted' when the user's Codex config marks this project root (or a parent) trusted,
    # 'untrusted' when it does not, 'unknown' when the config is missing or unreadable. Codex owns the real decision.
    # The Codex home is -CodexHome (a T3 Code provider instance with its own home), else CODEX_HOME, else ~/.codex.
    try {
        $codexHome = if ($CodexHome) { $CodexHome } elseif ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex' }
        $file = Join-Path $codexHome 'config.toml'
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { return 'unknown' }
        $cmp = [StringComparison]::OrdinalIgnoreCase
        $trim = [char[]]@([char]92, [char]47)
        $here = [IO.Path]::GetFullPath($Root).TrimEnd($trim)
        $section = $null
        foreach ($line in (Read-SwText $file) -split "`n") {
            if ($line -match '^\s*\[') {
                $section = if ($line -match "^\s*\[projects\.(?:'([^']+)'|`"((?:[^`"\\]|\\.)*)`")\]\s*$") { if ($Matches[1]) { $Matches[1] } else { $Matches[2].Replace('\\', '\') } } else { $null }
            } elseif ($section -and $line -match '^\s*trust_level\s*=\s*"trusted"\s*$') {
                $p = [IO.Path]::GetFullPath($section).TrimEnd($trim)
                if ($here.Equals($p, $cmp) -or $here.StartsWith($p + [IO.Path]::DirectorySeparatorChar, $cmp)) { return 'trusted' }
            }
        }
        'untrusted'
    } catch { 'unknown' }
}

function Test-SwDoctor {
    <#
    .SYNOPSIS Read-only setup check for a contributor: doctor [-User <name>] [-CodexHome <dir>]. Never installs or changes anything.
    #>
    [CmdletBinding()]
    param([string]$User, [string]$Path, [string]$CodexHome)
    $Root = Resolve-SwRoot $Path
    $rows = [Collections.Generic.List[object]]::new()
    $add = { param($n, $state, $detail) $rows.Add([pscustomobject]@{ Item = $n; State = $state; Detail = $detail }) }
    $optional = { param([string]$Name)
        $probe = Get-SwToolProbe $Name
        & $add $Name $(if (Test-SwSame $probe.State 'ok' -IgnoreCase) { 'OK' } else { 'WARN' }) $(switch ($probe.State) { 'ok' { $probe.Version.ToString() } 'missing' { "Fix: $(Get-SwDoctorHint $Name)" } default { "$(Format-SwProbe $probe); Fix: $(Get-SwDoctorHint $Name)" } })
        $probe
    }

    & $add 'PowerShell >= 5.1' 'OK' $PSVersionTable.PSVersion.ToString()

    $hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
    & $add 'git' $(if ($hasGit) { 'OK' } else { 'MISSING' }) $(if ($hasGit) { (& git --version) } else { "Fix: $(Get-SwDoctorHint git)" })
    $userName = if ($hasGit) { Invoke-SwNative git @('-C', $Root, 'config', 'user.name') }
    & $add 'git user.name' $(if ($userName) { 'OK' } else { 'MISSING' }) $(if ($userName) { $userName } else { 'Fix: git config --global user.name "<name>"' })

    # T3 Code is the required app, but only its `t3` command is discoverable (the desktop app installs it on request);
    # its Claude and Codex providers are each optional. Absence warns.
    $null = & $optional 't3'
    $null = & $optional 'claude'
    $null = & $optional 'codex'

    $gh = & $optional 'gh'
    if (Test-SwSame $gh.State 'ok' -IgnoreCase) {
        $auth = Get-SwGhAuth
        & $add 'gh auth' $(if ($auth -eq 0) { 'OK' } else { 'WARN' }) $(if ($auth -eq 0) { 'logged in' } else { 'Fix: gh auth login' })
    }

    $rtk = & $optional 'rtk'
    if ((Test-SwSame $rtk.State 'ok' -IgnoreCase) -and $rtk.Version -lt [version]'0.48.0') { & $add 'rtk >= 0.48' 'WARN' "found $($rtk.Version)" }

    $config = Get-SwConfig $Root
    $hostPolicy = (Test-SwSame ((Get-SwGitPolicy $config)) 'host' -IgnoreCase)
    $users = @($config['users'])
    $listed = [bool]($User -and (Test-SwIn $User $users))
    if ($User) {
        & $add "user $User" $(if ($listed) { 'OK' } else { 'MISSING' }) $(if ($listed) { 'listed in .sw/config.json' } else { "Fix (project owner runs): powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 user $User" })
    } else {
        & $add 'users' 'WARN' "Recorded: $(if ($users.Count) { $users -join ', ' } else { 'none' }); pass -User <name> to check yours"
    }

    # The checked-out branch: main, or a T3 Code worktree thread branch (t3/<name>).
    $current = [string](Invoke-SwNative git @('-C', $Root, 'branch', '--show-current'))
    $shown = if ($current) { $current } else { 'detached HEAD' }
    $allowed = -not $hostPolicy -and ((Test-SwSame $current 'main') -or $current -cmatch '^t3/[^/]')
    & $add 'current branch' $(if ($allowed) { 'OK' } else { 'WARN' }) $(if ($hostPolicy) { "$shown (host Git policy; verify against your project rules, not checked here)" } elseif ($allowed) { $current } else { "$shown (expected main or a T3 Code t3/<name> thread branch)" })

    # Codex loads the project's .codex/rules hard limits only when it trusts the project; trusting is the owner's choice.
    $trust = Get-SwCodexTrust $Root $CodexHome
    & $add 'codex trust' $(if (Test-SwSame $trust 'trusted' -IgnoreCase) { 'OK' } else { 'WARN' }) $(switch ($trust) { 'trusted' { 'project trusted in the Codex config' } 'untrusted' { 'not trusted: Codex skips .codex/rules (hard limits); trust the project in Codex if you use it' } default { 'unknown (no readable Codex config)' } })

    $rows | Format-Table -AutoSize | Out-String -Width 200 | Write-Output
    Write-Output 'Reminder: T3 Code -> runtime mode Auto or Full access, not Supervised; worktree branch prefix "t3/", automatic pull and merge-based worktree cleanup under workspace Git policy. None can be detected.'
    Write-Output 'Hard limits: Claude applies .claude/settings.json deny rules in every mode; Codex applies .codex/rules only in a trusted project. sw validate checks them statically.'
    Write-Output 'Startup budget (validate) counts kit files only. Harness prompt, tool schemas, user files, hooks and plugins are not counted; check `/context` (Claude) for the real total.'
    if ($hostPolicy) { Write-Output 'Host branch protection and workflow: not checked; consult the project owner.' }
    else { Write-Output 'Branch protection on main: not checked; see .sw/collaboration.md.' }
    $global:LASTEXITCODE = if (@($rows | Where-Object { Test-SwIn $_.State 'MISSING', 'FAILED' }).Count) { 1 } else { 0 }
}

# --- GitHub (read-only helpers; writes are human-run) -----------------------------------

function Invoke-SwGitHub {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Position = 0, Mandatory)][ValidateScript({ Test-SwIn $_ 'status', 'labels' -IgnoreCase })][string]$Action, [string]$Path)
    $Root = Resolve-SwRoot $Path
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'gh CLI not found.' }
    if (Test-SwSame $Action 'status' -IgnoreCase) {
        Push-Location $Root
        try {
            Write-Output '== Open PRs'; & gh pr list --limit 10
            Write-Output '== Issues assigned to me'; & gh issue list --assignee '@me' --limit 10
            Write-Output '== Recent runs'; & gh run list --limit 5
        } finally { Pop-Location }
        return
    }
    # labels: a GitHub write the human runs.
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
    <#
    .SYNOPSIS Workspace estimates only: RTK's local output-savings report and the static startup-budget estimate.
    Never reads provider request telemetry (requests, tokens, cost, quota).
    #>
    [CmdletBinding()]
    param([string]$Path)
    $Root = Resolve-SwRoot $Path
    Write-Output 'Workspace estimates only, not provider request telemetry: actual requests, tokens, cost and quota are not read.'
    Write-Output '== RTK output savings (this project; RTK''s own local estimate)'
    $rtk = Find-SwTool 'rtk'
    if ($rtk) { Push-Location $Root; try { & $rtk gain --project } finally { Pop-Location } } else { Write-Output 'rtk not installed.' }
    Write-Output '== Startup budget (static kit estimate)'
    Test-SwProject -Path $Root | Where-Object { (([string]$_).StartsWith('Startup budget:', [StringComparison]::OrdinalIgnoreCase)) }
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
        for ($c = $full; (-not (Test-SwSame $status 'unsafe' -IgnoreCase)) -and ((Test-SwContained $Root $c) -or (Test-SwSame $c $anchor -IgnoreCase)); $c = Split-Path $c -Parent) {
            try { if ([IO.File]::GetAttributes($c) -band [IO.FileAttributes]::ReparsePoint) { $status = 'unsafe' } }
            catch [IO.FileNotFoundException], [IO.DirectoryNotFoundException] { $status = 'missing' }
        }
        if (Test-SwSame $status 'ok' -IgnoreCase) { $value = & $Action $full }
    } catch { $status = 'failed'; $value = $null }
    [pscustomobject]@{ Status = $status; Value = $value }
}

function Resolve-SwProjectPath([string]$Root, [string]$Relative, [string]$Label) {
    # Explicit caller paths: project-relative only; no rooted/UNC/drive/stream forms, '..' segments or links.
    if (-not $Relative -or [IO.Path]::IsPathRooted($Relative) -or $Relative -match '^[\\/]|:' -or (Test-SwIn '..' (@($Relative -split '[\\/]')) -IgnoreCase)) { throw "Invalid ${Label}: '$Relative' must be a project-relative path" }
    $full = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    if (-not (Test-SwContained $Root $full)) { throw "Invalid ${Label}: '$Relative' escapes the project" }
    if (Test-SwSame ((Invoke-SwContextRead $Root $Relative {}).Status) 'unsafe' -IgnoreCase) { throw "Invalid ${Label}: '$Relative' traverses a link or junction" }
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
    if ($StateFile -and (-not (Test-SwSame ([IO.Path]::GetExtension($StateFile)) '.md' -IgnoreCase))) { throw "Invalid StateFile: '$StateFile' must be a Markdown file" }
    if ($StateFile -and -not $StateSection) { $StateSection = 'Startup' }
    if ($StateSection -and ($StateSection -match '[\r\n#]' -or (-not (Test-SwSame ($StateSection.Trim()) $StateSection)))) { throw "Invalid StateSection: '$StateSection'" }
    # Git is optional evidence: a failed launch (missing or denied) makes it unavailable for the rest of the report,
    # never retried. core.fsmonitor=false keeps a configured fsmonitor hook from running; plain reads take no locks.
    $gitState = @{ Usable = $true }
    $git = { param([string]$Dir, [string[]]$GitArgs)
        if (-not $gitState.Usable) { return }
        try { $out = @(Invoke-SwNative git (@('--no-optional-locks', '-c', 'core.fsmonitor=false', '-C', $Dir) + $GitArgs)); if ($LASTEXITCODE -eq 0) { , $out } } catch { $gitState.Usable = $false }
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
        if (-not (Test-SwSame $top.Status 'ok' -IgnoreCase)) { return [pscustomobject]@{ Status = $top.Status; Files = @(); Skipped = 0 } }
        $files = [Collections.Generic.List[string]]::new(); $skipped = 0
        $queue = [Collections.Generic.Queue[object]]::new(); $queue.Enqueue([pscustomobject]@{ Rel = $Rel; Items = $top.Value })
        while ($queue.Count) {
            $d = $queue.Dequeue()
            foreach ($i in $d.Items) {
                $r = "$($d.Rel)/$($i.Name)"
                if ($i.Attributes -band [IO.FileAttributes]::ReparsePoint) { $skipped++ }
                elseif (-not $i.PSIsContainer) { $files.Add($r) }
                elseif ($Recurse) { $sub = & $list $r; if (Test-SwSame $sub.Status 'ok' -IgnoreCase) { $queue.Enqueue([pscustomobject]@{ Rel = $r; Items = $sub.Value }) } else { $skipped++ } }
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
    $stamped = @($taskRel) + @(if ($StateFile) { $StateFile })
    $before = @(foreach ($s in $stamped) { & $stamp $s })

    Write-Output 'Project context report: read-only static inspection; facts and source pointers only, not an approval or acceptance verdict.'
    Write-Output 'Measurement: UTF-8 bytes of LF-normalized text (BOM excluded); tokens are a ceil(bytes/4) estimate, not a tokenizer result or runtime bill.'
    Write-Output 'Status words: missing = absent; unsafe = link or junction, not followed; failed = denied, unreadable, malformed or vanished; incomplete = some entries not followed or unreadable. None is a measured zero.'

    Write-Output '== Core static kit estimate (same arithmetic and cap as sw validate)'
    try {
        $gaps = [Collections.Generic.List[string]]::new()
        $need = { param([string]$Rel, $Result) if (-not (Test-SwSame $Result.Status 'ok' -IgnoreCase)) { $gaps.Add("$Rel $($Result.Status)") }; $Result.Value }
        $config = & $need '.sw/config.json' (& $read '.sw/config.json' { param($f) Read-SwJson $f })
        $agentsMd = & $need 'AGENTS.md' (& $text 'AGENTS.md')
        $skills = @{}
        $skillTree = & $walk '.agents/skills' $true
        if (-not (Test-SwSame $skillTree.Status 'ok' -IgnoreCase)) { $gaps.Add(".agents/skills $($skillTree.Status)") }
        $skillFiles = @($skillTree.Files | Where-Object { Test-SwSame (($_ -split '/')[-1]) 'SKILL.md' -IgnoreCase })
        foreach ($f in $skillFiles) { $d = & $need $f (& $read $f { param($p) Read-SwFrontmatter $p 'name', 'description', 'disable-model-invocation' }); if ($d) { $skills[$d['name']] = $d } }
        if ($gaps.Count) { Write-Output "core: incomplete ($($gaps -join '; ')); session total withheld; sw validate reports definition errors" }
        else {
            $b = Get-SwStartupBudget $config $agentsMd $skills
            Write-Output "$($b.Scope): agents_md=$($b.AgentsMd) skill_metadata=$($b.Skills) total=$($b.Total) est_tokens=$($b.Tokens) cap=$($b.Cap) within_cap=$(if ($b.Total -le $b.Cap) { 'yes' } else { 'no' })"
        }
    } catch { Write-Output 'core: incomplete (estimate failed); session total withheld; sw validate reports definition errors' }

    Write-Output '== Additional required reads (listed sources only; no cap applies)'
    if (-not $StateFile) { Write-Output 'state: unavailable (state source not specified; pass -StateFile named by AGENTS.md)' }
    else {
        $show = $StateFile.Replace('\', '/'); $s = & $text $StateFile
        if (-not (Test-SwSame $s.Status 'ok' -IgnoreCase)) { Write-Output "state: unavailable ($($s.Status): $show)" }
        else {
            $match = [regex]::Match($s.Value, '(?ms)^## ' + [regex]::Escape($StateSection) + '[ \t]*\n(.*?)(?=^## |\z)')
            if ($match.Success) { Write-Output "state: $show section `"$StateSection`" bytes=$(& $bytes $match.Groups[1].Value) (section body only; the rest of the file is not counted)" }
            else { Write-Output "state: unavailable (section `"$StateSection`" not found in $show)" }
        }
    }
    foreach ($p in '.sw/workspace.md', '.sw/collaboration.md') {
        $r = & $text $p
        Write-Output $(if (Test-SwSame $r.Status 'ok' -IgnoreCase) { "policy: $p bytes=$(& $bytes $r.Value)" } else { "policy: $p unavailable ($($r.Status))" })
    }

    Write-Output '== Available, not necessarily loaded (metadata only; bodies not printed)'
    try {
        if (-not (Test-SwIn $skillTree.Status 'ok', 'incomplete' -IgnoreCase)) { Write-Output "skills: unavailable ($($skillTree.Status): .agents/skills)" }
        else {
            if ($skillTree.Skipped) { Write-Output "skills: incomplete ($($skillTree.Skipped) entries not followed or unreadable)" }
            foreach ($f in $skillFiles) { $r = & $text $f; Write-Output "skill: $(($f -split '/')[-2]) $(if (Test-SwSame $r.Status 'ok' -IgnoreCase) { "bytes=$(& $bytes $r.Value)" } else { "unavailable ($($r.Status))" })" }
        }
    } catch { Write-Output 'inventory: incomplete (listing failed)' }

    Write-Output '== Runtime, harness and global context: NOT OBSERVED by this command'
    Write-Output 'Not read or measured: tool schemas, merged global/user instructions, native memory, actual skill loads, cache/compaction, actual model-visible input.'

    Write-Output '== Source and evidence inventory (opaque references; no approval, acceptance or active task inferred)'
    $dotGit = & $read '.git' {}
    if (-not (Test-SwSame $dotGit.Status 'ok' -IgnoreCase)) { Write-Output "checkout: unavailable ($($dotGit.Status): .git)" }
    elseif (-not $gitState.Usable) { Write-Output 'checkout: unavailable (git could not be run; not retried)' }
    else {
        $branch = & $git $Root @('branch', '--show-current'); $head = & $git $Root @('rev-parse', '--verify', '--quiet', 'HEAD'); $dirty = & $git $Root @('status', '--porcelain=v1')
        Write-Output "checkout: branch=$(if ($branch) { $branch[0] } else { 'unavailable' }) head=$(if ($head) { $head[0] } else { 'unavailable' }) dirty_entries=$(if ($null -ne $dirty) { @($dirty | Where-Object { $_ }).Count } else { 'unavailable' })$(if (-not $gitState.Usable) { ' (git could not be run; not retried)' })"
    }
    try {
        $t = & $list $taskRel
        if (-not $Task) {
            if (-not (Test-SwSame $t.Status 'ok' -IgnoreCase)) { Write-Output "tasks: unavailable ($($t.Status): $taskRel)" }
            else {
                $dirs = @($t.Value | Where-Object PSIsContainer)
                Write-Output "tasks: candidates=$($dirs.Count) listed=$([math]::Min($dirs.Count, 20)) omitted=$([math]::Max($dirs.Count - 20, 0)) (candidates only; pass -Task <id> to inspect one)"
                foreach ($d in $dirs | Select-Object -First 20) {
                    if ($d.Attributes -band [IO.FileAttributes]::ReparsePoint) { Write-Output "candidate: $($d.Name) (link; not inspected)"; continue }
                    $e = & $list "$taskRel/$($d.Name)"
                    Write-Output "candidate: $($d.Name) events=$(if (Test-SwSame $e.Status 'ok' -IgnoreCase) { @($e.Value | Where-Object { -not $_.PSIsContainer -and (Test-SwSame $_.Extension '.md' -IgnoreCase) }).Count } else { "unavailable ($($e.Status))" })"
                }
            }
        } elseif (-not (Test-SwSame $t.Status 'ok' -IgnoreCase)) { Write-Output "task: $Task unavailable ($($t.Status): $taskRel)" }
        else {
            $all = @($t.Value)
            $events = @($all | Where-Object { -not $_.PSIsContainer -and (Test-SwSame $_.Extension '.md' -IgnoreCase) })
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
    if ((-not (Test-SwSame ($before -join "`n") ($after -join "`n"))) -or @($before + $after | Where-Object { (([string]$_).StartsWith('failed|', [StringComparison]::OrdinalIgnoreCase)) }).Count) {
        Write-Output 'notice: evidence changed during inspection or could not be re-checked; this report is incomplete. Re-run before relying on it.'
    }
    $global:LASTEXITCODE = 0
}

Export-ModuleMember -Function Resolve-SwRoot, Write-SwFile, Read-SwText, Read-SwJson, ConvertTo-SwJson, Get-SwHash, Get-SwGitPolicy,
    Get-SwConfig, Read-SwFrontmatter, Test-SwProject, Invoke-SwComms, Add-SwUser, Invoke-SwGitHub, Get-SwUsage, Test-SwLocalOnly,
    Get-SwToolVersion, Get-SwToolProbe, Get-SwGhAuth, Format-SwProbe, Test-SwDoctor, Get-SwCodexTrust,
    Get-SwOperationId, Test-SwContained, New-SwSnapshotDir, Copy-SwNew, Write-SwNewFile, Get-SwByteHash,
    Get-SwStartupBudget, Get-SwContext, Resolve-SwSelection, Get-SwSelectionKnown, Test-SwLinkedPath, Get-SwRetiredOutputs,
    Get-SwClaudeDeny, Get-SwClaudeSettings, Get-SwCodexRules, Get-SwCodexRuleBlocks, Read-SwCodexRules, Test-SwClaudeRule, Test-SwCodexRule, Get-SwHardLimitCases,
    Assert-SwRelativePath, Assert-SwPhysicalPath, Resolve-SwManagedPath, Get-SwPhysicalFiles, Get-SwConfiguredTier,
    Get-SwRelativePath, Test-SwFullyQualified, Invoke-SwNative, ConvertFrom-SwJson,
    Test-SwSame, Test-SwIn, Get-SwUnique, Get-SwSkillDelivery, Get-SwCentralSkillIds, Get-SwProfileHome, Get-SwCentralAvailability
