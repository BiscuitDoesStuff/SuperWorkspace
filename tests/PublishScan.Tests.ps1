#requires -Version 5.1
# Pester 5+ tests for tools/publish-scan.ps1. Fixture repositories live under $TestDrive.
# Leak fixtures are assembled at runtime so this file itself scans clean.

BeforeAll {
    $script:Scan = Join-Path (Split-Path $PSScriptRoot -Parent) 'tools/publish-scan.ps1'

    function Write-Files([string]$Dir, [hashtable]$Files) {
        foreach ($rel in $Files.Keys) {
            $full = Join-Path $Dir $rel
            New-Item -ItemType Directory -Force -Path (Split-Path $full -Parent) | Out-Null
            [IO.File]::WriteAllText($full, $Files[$rel], [Text.UTF8Encoding]::new($false))
        }
    }
    function Save-Commit([string]$Dir, [string]$Message) {
        git -C $Dir -c core.autocrlf=false add -A
        git -C $Dir -c user.name=t -c user.email=t@example.invalid commit -qm $Message
        if ($LASTEXITCODE -ne 0) { throw 'fixture commit failed' }
    }
    # A repository whose `base` tag holds $BaseFiles and whose HEAD adds $SourceFiles.
    function New-ScanRepo([hashtable]$BaseFiles = @{ 'README.md' = "base`n" }, [hashtable]$SourceFiles = @{}) {
        $dir = Join-Path $TestDrive ([guid]::NewGuid().ToString('N').Substring(0, 8))
        git -c init.defaultBranch=main init -q $dir
        Write-Files $dir $BaseFiles; Save-Commit $dir base
        git -C $dir tag base
        Write-Files $dir $SourceFiles; Save-Commit $dir source
        $dir
    }
    function Invoke-Scan([string]$Dir, [hashtable]$Options = @{}) {
        $out = @(& $script:Scan -Repo $Dir -Base base @Options)
        [pscustomobject]@{ Output = $out; Text = $out -join "`n"; ExitCode = $LASTEXITCODE }
    }
}

Describe 'Publish leak scan' {
    It 'flags <Rule> on the changed line without printing the match' -TestCases @(
        @{ Rule = 'personal-path'; Value = 'C:' + '\Users\someone\notes' }
        @{ Rule = 'github-token'; Value = 'ghp' + '_' + ('a1' * 18) }
        @{ Rule = 'github-token'; Value = 'github' + '_pat_' + ('A1' * 15) }
        @{ Rule = 'api-key'; Value = 'sk' + '-proj-' + ('a1' * 12) }
        @{ Rule = 'api-key'; Value = 'sk' + '-' + ('ab' * 24) }
        @{ Rule = 'aws-key'; Value = 'AK' + 'IA' + ('A2' * 8) }
        @{ Rule = 'private-key'; Value = '-----BEGIN ' + 'RSA PRIVATE KEY-----' }
        @{ Rule = 'email'; Value = 'someone' + '@' + 'mail.net' }
    ) {
        $dir = New-ScanRepo -SourceFiles @{ 'docs/f.txt' = "clean line`nvalue: $Value`n" }
        $r = Invoke-Scan $dir
        $r.ExitCode | Should -Be 1
        $r.Output | Should -Contain "docs/f.txt:2: $Rule"
        $r.Text | Should -Not -Match ([regex]::Escape($Value))
        $r.Text | Should -Match '1 hit\(s\)\.$'
    }

    It 'allows the owner handle outside kit sources and flags it inside them' {
        $handle = 'Biscuit' + 'DoesStuff'
        $dir = New-ScanRepo -SourceFiles @{ 'README.md' = "by $handle`n"; 'docs/a.md' = "$handle`n"; 'lib/x.psm1' = "# $handle`n"; 'sw.ps1' = "# $handle`n" }
        $r = Invoke-Scan $dir
        $r.ExitCode | Should -Be 1
        @($r.Output | Where-Object { $_ -match ': owner-handle$' }) | Should -Be @('lib/x.psm1:1: owner-handle', 'sw.ps1:1: owner-handle')
    }

    It 'exempts noreply and reserved-domain addresses' {
        $lines = @(('noreply' + '@' + 'anthropic.com'), ('1+u' + '@users.noreply.' + 'github.com'), ('ci' + '@' + 'example.invalid')) -join "`n"
        $r = Invoke-Scan (New-ScanRepo -SourceFiles @{ 'AGENTS.md' = "$lines`n" })
        $r.ExitCode | Should -Be 0
        $r.Text | Should -Match '0 hit\(s\)\.$'
    }

    It 'flags personal addresses that merely contain noreply' {
        $lines = @(('alice' + '@' + 'noreplyconsulting.com'), ('bob.noreply' + '@' + 'mail.net')) -join "`n"
        $r = Invoke-Scan (New-ScanRepo -SourceFiles @{ 'AGENTS.md' = "$lines`n" })
        $r.Output | Should -Contain 'AGENTS.md:1: email'
        $r.Output | Should -Contain 'AGENTS.md:2: email'
    }

    It 'ignores diff prefix configuration when matching kit sources' {
        $dir = New-ScanRepo -SourceFiles @{ 'lib/a.ps1' = "# $('Biscuit' + 'DoesStuff')`n" }
        git -C $dir config diff.dstPrefix destination/
        (Invoke-Scan $dir).Output | Should -Contain 'lib/a.ps1:1: owner-handle'
    }

    It 'reports correct line numbers despite inter-hunk context configuration' {
        $email = 'someone' + '@' + 'mail.net'
        $dir = New-ScanRepo -BaseFiles @{ 'f.md' = "a`nb`nc`nd`n" } -SourceFiles @{ 'f.md' = "$email`nb`nc`n$email`n" }
        git -C $dir config diff.interHunkContext 20
        $r = Invoke-Scan $dir
        $r.Output | Should -Contain 'f.md:1: email'
        $r.Output | Should -Contain 'f.md:4: email'
    }

    It 'reports correct line numbers when GIT_DIFF_OPTS adds context' {
        $email = 'someone' + '@' + 'mail.net'
        $dir = New-ScanRepo -BaseFiles @{ 'f.md' = "a`n`nc`nd`n" } -SourceFiles @{ 'f.md' = "a`n`nc`n$email`n" }
        git -C $dir config diff.suppressBlankEmpty true
        $saved = $env:GIT_DIFF_OPTS
        try { $env:GIT_DIFF_OPTS = '--unified=20'; $r = Invoke-Scan $dir } finally { $env:GIT_DIFF_OPTS = $saved }
        $r.Output | Should -Contain 'f.md:4: email'
    }

    It 'loads the default pattern file and reports it without its contents' {
        $dir = New-ScanRepo -SourceFiles @{ 'tests/leak-patterns.local.txt' = "# private names`nzebra-codename`n"; 'docs/a.md' = "the Zebra-Codename plan`n" }
        $r = Invoke-Scan $dir
        $r.ExitCode | Should -Be 1
        $r.Text | Should -Match 'pattern file loaded \(1 patterns\)'
        $r.Output | Should -Contain 'docs/a.md:1: local-pattern-2'
        @($r.Output | Where-Object { $_ -match 'zebra' -and $_ -notmatch '^tests/leak-patterns' }) | Should -BeNullOrEmpty
    }

    It 'reports a missing pattern file and still runs the built-in rules' {
        $dir = New-ScanRepo -SourceFiles @{ 'docs/a.md' = "zebra-codename`n" }
        $r = Invoke-Scan $dir @{ PatternFile = (Join-Path $TestDrive 'absent.txt') }
        $r.ExitCode | Should -Be 0
        $r.Text | Should -Match 'pattern file not found, built-in rules only; 0 hit\(s\)\.$'
    }

    It 'scans only added lines in diff mode and every line with -Tree' {
        $email = 'someone' + '@' + 'mail.net'
        $dir = New-ScanRepo -BaseFiles @{ 'old.md' = "$email`n"; 'keep.md' = "one`ntwo`nthree`n" } -SourceFiles @{ 'keep.md' = "one`ntwo`n$email`n" }
        $diff = Invoke-Scan $dir
        $diff.Output | Should -Contain 'keep.md:3: email'
        $diff.Output | Should -Not -Contain 'old.md:1: email'
        $tree = Invoke-Scan $dir @{ Tree = $true }
        $tree.ExitCode | Should -Be 1
        $tree.Output | Should -Contain 'old.md:1: email'
        $tree.Output | Should -Contain 'keep.md:3: email'
        $tree.Text | Should -Match 'Scanned tree HEAD;'
    }

    It 'passes clean changes with exit 0 and fails a bad ref with exit 2' {
        $dir = New-ScanRepo -SourceFiles @{ 'docs/a.md' = "plain text, task-name and risk-free words`n" }
        $r = Invoke-Scan $dir
        $r.ExitCode | Should -Be 0
        $r.Output | Should -Be @('Scanned diff base..HEAD; pattern file not found, built-in rules only; 0 hit(s).')
        (Invoke-Scan $dir @{ Source = 'no-such-ref' }).ExitCode | Should -Be 2
    }
}
