#requires -Version 5.1
<#
.SYNOPSIS
Screens a publication for leaks before the owner pushes it (docs/workspace-outline.md O13).

.DESCRIPTION
Scans the added and changed lines of `git diff <Base> <Source>`, or with -Tree every line of
<Source>, for personal paths, private patterns from an optional local file, the owner handle in
kit sources, common secret shapes and email addresses. Prints `path:line: rule` per hit, never the
matched text. Exit 0 when clean, 1 on any hit, 2 on a usage or Git error. Read-only: no fetch, no
network, no writes.
#>
[CmdletBinding()]
param(
    [string]$Base = 'origin/main',
    [string]$Source = 'HEAD',
    [string]$PatternFile,
    [switch]$Tree,
    [string]$Repo
)

$ErrorActionPreference = 'Stop'

# ponytail: the personal-path pattern and the pattern-file format duplicate the "Portable source
# leak guard" in tests/Sw.Tests.ps1; dedupe into one shared list when that file is next opened.
$ignoreCase = [Text.RegularExpressions.RegexOptions]::IgnoreCase
$rules = [Collections.Generic.List[object]]::new()
function Add-Rule([string]$Name, [string]$Pattern, $Options = 'None', [scriptblock]$Applies) {
    $rules.Add([pscustomobject]@{ Name = $Name; Regex = [regex]::new($Pattern, $Options); Applies = $Applies })
}
Add-Rule 'personal-path' '[A-Za-z]:\\+Users\\' $ignoreCase
# The public owner handle is allowed outside kit sources and flagged inside them, as in the guard.
Add-Rule 'owner-handle' 'BiscuitDoesStuff' $ignoreCase { param($Path) $Path -match '^(sw\.ps1|VERSION|(lib|project|global)/)' }
Add-Rule 'github-token' '\b(gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{22,})'
Add-Rule 'api-key' '\bsk-[A-Za-z0-9_-]{20,}'
Add-Rule 'aws-key' '\b(AKIA|ASIA)[0-9A-Z]{16}\b'
Add-Rule 'private-key' '-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----'

$emailRegex = [regex]'[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}'
# noreply addresses (commit trailers, GitHub users.noreply) and RFC 2606 reserved domains are not personal.
$emailAllowed = '(?i)^no-?reply@|@(.+\.)?no-?reply\.|@(.+\.)?(example\.(com|net|org)|invalid|test|example|localhost)$'

$exit = 0
$savedEncoding = $null
try {
    # Windows PowerShell 5.1 leaves $PSScriptRoot empty in parameter defaults.
    if (-not $Repo) { $Repo = Split-Path $PSScriptRoot -Parent }
    if (-not $PatternFile) { $PatternFile = Join-Path $Repo 'tests/leak-patterns.local.txt' }
    if (Test-Path -LiteralPath $PatternFile -PathType Leaf) {
        $n = 0; $count = 0
        foreach ($line in [IO.File]::ReadAllLines((Resolve-Path -LiteralPath $PatternFile).ProviderPath)) {
            $n++; $p = $line.Trim()
            if (-not $p -or $p.StartsWith('#')) { continue }
            try { Add-Rule "local-pattern-$n" $p $ignoreCase } catch { throw "Pattern file line $n is not a valid regex." }
            $count++
        }
        $patternStatus = "loaded ($count patterns)"
    } else {
        $patternStatus = 'not found, built-in rules only'
    }

    # Git output is UTF-8; decode it as such on Windows PowerShell 5.1 too.
    try { $savedEncoding = [Console]::OutputEncoding; [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false) } catch { $savedEncoding = $null }

    function Invoke-Git { $out = & git -C $Repo -c core.quotePath=false @args 2>$null; if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') failed in $Repo." }; $out }
    $null = Invoke-Git rev-parse --verify --quiet "$Source^{tree}"
    if ($Tree) {
        # Diffing from the empty tree marks every line of Source as added.
        $Base = if ((Invoke-Git rev-parse --show-object-format) -eq 'sha256') { '6ef19b41225c5369f1c104d45d8d85efa9b057b53b14b4b9b939dd74decc5321' } else { '4b825dc642cb6eb9a060e54bf8d69288fbee4904' }
    } else {
        $null = Invoke-Git rev-parse --verify --quiet "$Base^{tree}"
    }
    # Fixed prefixes so diff.noprefix, diff.mnemonicPrefix or diff.dstPrefix cannot hide kit-source paths;
    # no inter-hunk context so diff.interHunkContext cannot add unnumbered context lines.
    $diff = Invoke-Git diff --src-prefix=a/ --dst-prefix=b/ --inter-hunk-context=0 --no-color --no-ext-diff --no-renames --no-textconv -U0 $Base $Source --

    $hits = 0; $path = $null; $lineNo = 0; $inHeader = $false
    foreach ($raw in $diff) {
        $line = $raw.TrimEnd("`r")
        if ($line.StartsWith('diff --git ')) { $inHeader = $true; $path = $null; continue }
        if ($inHeader) {
            if ($line -match '^\+\+\+ (.*)$') {
                $name = $Matches[1].TrimEnd("`t")
                $path = if ($name -eq '/dev/null') { $null } else { $name.Trim('"') -replace '^b/', '' }
            } elseif ($line -match '^Binary files .* and "?b/(.*?)"? differ$') {
                Write-Output "$($Matches[1]): binary, not scanned"
            } elseif ($line -match '^@@ -\S+ \+(\d+)') {
                $inHeader = $false; $lineNo = [int]$Matches[1]
            }
            continue
        }
        if ($line -match '^@@ -\S+ \+(\d+)') { $lineNo = [int]$Matches[1]; continue }
        # Context lines still occupy Source lines if GIT_DIFF_OPTS overrides -U0; diff.suppressBlankEmpty
        # prints blank ones as empty lines.
        if ($line -eq '' -or $line.StartsWith(' ')) { $lineNo++; continue }
        if (-not $line.StartsWith('+') -or -not $path) { continue }
        $text = $line.Substring(1)
        foreach ($rule in $rules) {
            if ($rule.Applies -and -not (& $rule.Applies $path)) { continue }
            if ($rule.Regex.IsMatch($text)) { Write-Output "${path}:${lineNo}: $($rule.Name)"; $hits++ }
        }
        foreach ($m in $emailRegex.Matches($text)) {
            if ($m.Value -notmatch $emailAllowed) { Write-Output "${path}:${lineNo}: email"; $hits++; break }
        }
        $lineNo++
    }

    $scope = if ($Tree) { "tree $Source" } else { "diff $Base..$Source" }
    Write-Output "Scanned $scope; pattern file $patternStatus; $hits hit(s)."
    if ($hits) { $exit = 1 }
} catch {
    Write-Output "publish-scan: $($_.Exception.Message)"
    $exit = 2
} finally {
    if ($savedEncoding) { [Console]::OutputEncoding = $savedEncoding }
}
exit $exit
