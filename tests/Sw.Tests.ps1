#requires -Version 7.2
# Pester 5+ suite for the SuperWorkspace kit. All scratch projects live under $TestDrive;
# the real user profile (~/.claude, ~/.config, ~/AGENTS.md) is never touched.

BeforeAll {
    $script:RepoRoot = Split-Path $PSScriptRoot -Parent
    Import-Module (Join-Path $RepoRoot 'lib/Sw.Project.psm1') -Force -DisableNameChecking
    Import-Module (Join-Path $RepoRoot 'lib/Sw.Kit.psm1') -Force -DisableNameChecking

    function New-SwProject {
        param([string]$Name, [string]$Profile = 'generic', [int]$GitHubTier = 0,
            # A legacy (all-base, pre-selection) project: an existing config without `selection`.
            [switch]$Legacy)
        $dir = Join-Path $TestDrive $Name
        if ($Legacy) { Write-SwFile (Join-Path $dir '.sw/config.json') (ConvertTo-SwJson ([ordered]@{ project = $Name; profile = $Profile; githubTier = $GitHubTier; github = $true; startupBudgetBytes = 12100; users = @() })) }
        Initialize-SwProject -Path $dir -Profile $Profile -Name $Name -GitHubTier $GitHubTier | Out-Null
        git -C $dir config user.name tester
        git -C $dir config user.email tester@example.com
        $dir
    }

    function New-Id { [Guid]::NewGuid().ToString('N').Substring(0, 8) }

    function Set-TestClaudeMap([string]$Root) {
        # Explicit fixture-only model choices; no native/model process or user config.
        Set-SwTiers -Light opus -Standard opus -High opus -Path $Root | Out-Null
        $path = Join-Path $Root '.opencode/opencode.jsonc'
        $map = Read-SwJson $path
        $map['agents']['project-leader'] = [ordered]@{ model = 'opus' }
        Write-SwFile $path (ConvertTo-SwJson $map)
    }

    function Test-SwValidate {
        param([string]$Root)
        $out = Test-SwProject -Path $Root -Quiet
        [pscustomobject]@{ Output = $out; ExitCode = $global:LASTEXITCODE }
    }
}

Describe 'Set-SwBlock' {
    It 'appends to empty text' {
        Set-SwBlock '' 'x' 'Body' | Should -Be "<!-- sw:begin x -->`nBody`n<!-- sw:end x -->`n"
    }
    It 'appends to non-empty text' {
        Set-SwBlock "Hello`n" 'x' 'Body' | Should -Be "Hello`n`n<!-- sw:begin x -->`nBody`n<!-- sw:end x -->`n"
    }
    It 'replaces an existing block, leaving surrounding text byte-identical' {
        $orig = "before`n<!-- sw:begin x -->`nold`n<!-- sw:end x -->`nafter`n"
        Set-SwBlock $orig 'x' 'new body' | Should -Be "before`n<!-- sw:begin x -->`nnew body`n<!-- sw:end x -->`nafter`n"
    }
    It 'is idempotent on re-apply' {
        $once = Set-SwBlock "start`n" 'x' 'body'
        (Set-SwBlock $once 'x' 'body') | Should -Be $once
    }
    It 'supports hash style markers' {
        Set-SwBlock '' 'x' 'body' 'hash' | Should -Be "# sw:begin x`nbody`n# sw:end x`n"
    }
    It 'throws on an unterminated block' {
        $orig = "before`n<!-- sw:begin x -->`nold, no end marker`n"
        { Set-SwBlock $orig 'x' 'new' } | Should -Throw '*Unterminated managed block*'
    }
}

Describe 'Get-SwHash' {
    It 'is identical for CRLF and LF content' {
        (Get-SwHash "line1`r`nline2`r`n") | Should -Be (Get-SwHash "line1`nline2`n")
    }
}

Describe 'Permission model' {
    Context 'Test-SwPattern' {
        It '<Desc>' -ForEach @(
            @{ Desc = "'*' spans '/'"; Pattern = 'docs/*'; Value = 'docs/nested/file.md'; Expected = $true }
            @{ Desc = 'whole-value match required'; Pattern = '*.md'; Value = 'file.md.cpp'; Expected = $false }
            @{ Desc = "'?' matches a single char"; Pattern = 'docs/nested/file.m?'; Value = 'docs/nested/file.md'; Expected = $true }
            @{ Desc = "'?' does not match zero or many chars"; Pattern = 'file.m?'; Value = 'file.mdx'; Expected = $false }
        ) {
            Test-SwPattern $Pattern $Value | Should -Be $Expected
        }
    }
    Context 'Get-SwDecision' {
        It 'last match wins' {
            $rules = @(
                [ordered]@{ action = '*'; resource = '*'; effect = 'allow' }
                [ordered]@{ action = 'shell'; resource = 'git push *'; effect = 'deny' }
                [ordered]@{ action = 'shell'; resource = 'git push origin main'; effect = 'allow' }
            )
            Get-SwDecision $rules shell 'git push origin main' | Should -Be 'allow'
            Get-SwDecision $rules shell 'git push origin dev' | Should -Be 'deny'
        }
        It "matches the bare command for a trailing ' *' rule" {
            $rules = @([ordered]@{ action = 'shell'; resource = 'git push *'; effect = 'deny' })
            Get-SwDecision $rules shell 'git push' | Should -Be 'deny'
        }
        It 'defaults to ask when nothing matches' {
            Get-SwDecision @() shell 'git push' | Should -Be 'ask'
        }
    }
}

Describe 'Session rules' {
    BeforeAll {
        function Get-Key($Rules) { @($Rules | ForEach-Object { "$($_['action'])|$($_['resource'])|$($_['effect'])" }) }
        function Get-AgentRules([string]$Root, [string]$Role) {
            @((Read-SwFrontmatter (Join-Path $Root ".opencode/agents/$Role.md") @('description', 'mode', 'color', 'permissions'))['permissions'])
        }
    }

    It 'orders base, profile edit denies, GitHub tier, then the .env asks' {
        $keys = Get-Key (Get-SwSessionRules @('*.uasset') 1)
        $keys[0] | Should -Be 'shell|*|allow'
        $keys | Should -Contain 'shell|git push *|deny'
        $keys | Should -Contain 'shell|git commit *|ask'
        $keys | Should -Contain 'external_directory|*|ask'
        $edit = [array]::IndexOf($keys, 'edit|*.uasset|deny')
        $edit | Should -BeGreaterThan ([array]::IndexOf($keys, 'shell|gh *|deny'))
        [array]::IndexOf($keys, 'shell|gh issue create *|allow') | Should -BeGreaterThan $edit
        $keys[-3..-1] | Should -Be @('read|*.env|ask', 'read|*.env.*|ask', 'read|*.env.example|allow')
        (Get-Key (Get-SwSessionRules @() 0)) | Should -Not -Contain 'shell|gh issue create *|allow'
    }

    It 'leads every rendered agent, which the frontmatter parser accepts, with the role rules after' {
        $dir = New-SwProject "session$(New-Id)" unreal 1 -Legacy
        $session = Get-Key (Add-SwRtkTwins (Get-SwSessionRules @('*.uasset', '*.umap') 1))
        $agents = @(Get-ChildItem -LiteralPath (Join-Path $dir '.opencode/agents') -Filter *.md -File -Force)
        $agents.Count | Should -Be 4
        foreach ($a in $agents) {
            $keys = Get-Key (Get-AgentRules $dir $a.BaseName)
            $keys[0..($session.Count - 1)] | Should -Be $session -Because $a.Name
        }
        # The developer and reviewer role rules follow the shared session rules.
        (Get-Key (Get-AgentRules $dir 'project-developer')).Count | Should -BeGreaterThan $session.Count
        (Get-Key (Get-AgentRules $dir 'project-review'))[$session.Count] | Should -Be '*|*|deny'
        (Get-Key (Get-AgentRules $dir 'project-leader'))[$session.Count] | Should -Be 'subagent|*|allow'
        $oc = Read-SwJson (Join-Path $dir 'opencode.jsonc')
        (Get-Key $oc['permissions']) | Should -Be $session
        (Get-Key $oc['agents']['build']['permissions'])[0..$session.Count] | Should -Be (@($session) + 'subagent|*|deny')
    }

    It 'appends project watcherIgnore after the profile list, deduplicated, in order' {
        $config = Get-SwConfig $RepoRoot
        $config['watcherIgnore'] = @('private/**', '.scratch/**', 'runs/**')
        $oc = ConvertFrom-Json (Get-SwRender $config).Files['opencode.jsonc'] -AsHashtable
        @($oc['watcher']['ignore']) | Should -Be @('node_modules/**', 'dist/**', 'build/**', '.venv/**', '.scratch/**', 'private/**', 'runs/**')
    }

    It 'keeps the canonical agent files free of session rules and RTK twins' {
        foreach ($f in Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'project/base/.opencode/agents') -Filter *.md -File -Force) {
            (Read-SwText $f.FullName) | Should -Not -Match 'git push|"rtk ' -Because $f.Name
        }
    }

    It 'twins non-wildcard-leading shell rules with an rtk rule of the same effect, directly after it' {
        $rules = @(
            [ordered]@{ action = 'shell'; resource = '*'; effect = 'allow' }
            [ordered]@{ action = 'read'; resource = '*.env'; effect = 'ask' }
            [ordered]@{ action = 'shell'; resource = 'git push *'; effect = 'deny' }
            [ordered]@{ action = 'shell'; resource = 'git push origin main'; effect = 'allow' }
        )
        (Get-Key (Add-SwRtkTwins $rules)) | Should -Be @('shell|*|allow', 'read|*.env|ask', 'shell|git push *|deny', 'shell|rtk git push *|deny',
            'shell|git push origin main|allow', 'shell|rtk git push origin main|allow')
    }

    It 'renders the twins for session and role rules, and rtk commands get the same decisions' {
        $dir = New-SwProject "rtk$(New-Id)" generic
        foreach ($role in 'project-leader', 'project-review', 'project-developer') {
            $rules = Get-AgentRules $dir $role
            $keys = Get-Key $rules
            for ($i = 0; $i -lt $keys.Count; $i++) {
                $a = $rules[$i]['action']; $r = $rules[$i]['resource']; $e = $rules[$i]['effect']
                if ($a -ne 'shell' -or $r.StartsWith('*') -or $r.StartsWith('rtk ')) { continue }
                $keys[$i + 1] | Should -Be "shell|rtk $r|$e" -Because "$role $r"
            }
        }
        $review = Get-Key (Get-AgentRules $dir 'project-review')
        [array]::IndexOf($review, 'shell|rtk git status *|allow') | Should -Be ([array]::IndexOf($review, 'shell|git status *|allow') + 1)
        (Get-Key (Get-AgentRules $dir 'project-developer')) | Should -Contain 'shell|rtk git switch *|ask'
        $leader = Get-AgentRules $dir 'project-leader'
        foreach ($c in 'rtk git push origin main', 'rtk git stash list', 'rtk gh repo list') { Get-SwDecision $leader shell $c | Should -Be 'deny' -Because $c }
        Get-SwDecision $leader shell 'rtk git commit -m x' | Should -Be 'ask'
        Get-SwDecision $leader shell 'rtk gh issue view 1' | Should -Be 'allow'
        $rules = Get-AgentRules $dir 'project-review'
        Get-SwDecision $rules shell 'rtk git status' | Should -Be 'allow'
        Get-SwDecision $rules shell 'rtk git diff --output=probe.txt' | Should -Be 'deny'
        Get-SwDecision (Get-AgentRules $dir 'project-developer') shell 'rtk git switch main' | Should -Be 'ask'
        $oc = Read-SwJson (Join-Path $dir 'opencode.jsonc')
        Get-SwDecision $oc['permissions'] shell 'rtk git push' | Should -Be 'deny'
        Get-SwDecision $oc['agents']['build']['permissions'] shell 'rtk gh pr merge 1' | Should -Be 'deny'
    }

    It 'a githubTier change is applied to every agent by update, and -WhatIf writes nothing' {
        $dir = New-SwProject "sessionTier$(New-Id)" generic
        $f = Join-Path $dir '.sw/config.json'
        $c = Read-SwJson $f; $c['githubTier'] = 1; Write-SwFile $f (ConvertTo-SwJson $c)
        $before = Get-ChildItem -LiteralPath (Join-Path $dir '.opencode/agents') -File -Force | ForEach-Object { Get-SwHash (Read-SwText $_.FullName) }
        Update-SwProject -Path $dir -WhatIf | Out-Null
        $after = Get-ChildItem -LiteralPath (Join-Path $dir '.opencode/agents') -File -Force | ForEach-Object { Get-SwHash (Read-SwText $_.FullName) }
        $after | Should -Be $before
        (Test-SwValidate $dir).ExitCode | Should -Be 1
        Update-SwProject -Path $dir | Out-Null
        foreach ($role in 'project-developer', 'project-review') { (Get-Key (Get-AgentRules $dir $role)) | Should -Contain 'shell|gh issue create *|allow' }
        (Test-SwValidate $dir).ExitCode | Should -Be 0
    }

    It 'read-only roles allow read forms of status/diff/log/show and deny <Flag>' -ForEach @(
        @{ Flag = '--output'; Denied = 'git diff --output=probe.txt', 'git log --output=probe.txt', 'git show --output=probe.txt HEAD', 'git status --output=probe.txt', 'git log --oneline -20 --output=probe.txt' }
        @{ Flag = '--ext-diff'; Denied = 'git diff --ext-diff', 'git log -p --ext-diff', 'git show --ext-diff HEAD' }
        @{ Flag = '--textconv'; Denied = 'git diff --textconv HEAD', 'git log -p --textconv', 'git show --textconv HEAD' }
    ) {
        $dir = New-SwProject "readonly$(New-Id)" generic
        foreach ($role in 'project-review') {
            $rules = Get-AgentRules $dir $role
            foreach ($c in 'git status', 'git status -sb', 'git diff', 'git diff HEAD~1 -- src/a.c', 'git log -5 --stat', 'git log --oneline', 'git log --oneline -20', 'git show HEAD', 'git show --no-ext-diff --no-textconv HEAD -- a.c') {
                Get-SwDecision $rules shell $c | Should -Be 'allow' -Because "$role $c"
            }
            foreach ($c in $Denied) { Get-SwDecision $rules shell $c | Should -Be 'deny' -Because "$role $c" }
            Get-SwDecision $rules shell 'git push' | Should -Be 'deny'
        }
    }
}

Describe 'Sync and init lifecycle' {
    It 'fresh init (generic) then CLI validate exits 0' {
        $dir = New-SwProject 'freshGeneric' generic
        & pwsh -NoProfile -File (Join-Path $dir '.sw/sw.ps1') validate | Out-Null
        $LASTEXITCODE | Should -Be 0
    }

    It 'fresh init (unreal) then CLI validate exits 0' {
        $dir = New-SwProject 'freshUnreal' unreal
        & pwsh -NoProfile -File (Join-Path $dir '.sw/sw.ps1') validate | Out-Null
        $LASTEXITCODE | Should -Be 0
    }

    It 'a second update reports everything as same' {
        $dir = New-SwProject 'updateSame' generic
        $plan = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
        @($plan | Where-Object Action -ne 'same').Count | Should -Be 0
    }

    It 'a user-modified managed file becomes kept-local, is not overwritten, and stays detected' {
        $dir = New-SwProject 'skipModified' generic
        $target = Join-Path $dir '.sw/workspace.md'
        $mine = (Read-SwText $target) + "`nmy local note`n"
        Write-SwFile $target $mine

        $plan1 = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
        ($plan1 | Where-Object Path -eq '.sw/workspace.md').Action | Should -Be 'kept-local'
        Read-SwText $target | Should -Be $mine

        $plan2 = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
        ($plan2 | Where-Object Path -eq '.sw/workspace.md').Action | Should -Be 'kept-local'
    }

    It 'init throws and writes nothing when an unmanaged file already exists at a managed path' {
        $dir = Join-Path $TestDrive 'conflict'
        New-Item -ItemType Directory -Force -Path (Join-Path $dir '.sw') | Out-Null
        Write-SwFile (Join-Path $dir '.sw/workspace.md') 'not managed by sw'
        { Initialize-SwProject -Path $dir -Profile generic -Name Conflict } | Should -Throw '*not SuperWorkspace-managed*'
        Test-Path (Join-Path $dir '.sw/manifest.json') | Should -BeFalse
    }

    It 'init -Adopt backs the conflicting file up under .sw/backup and replaces it' {
        $dir = Join-Path $TestDrive 'adopt'
        New-Item -ItemType Directory -Force -Path (Join-Path $dir '.sw') | Out-Null
        Write-SwFile (Join-Path $dir '.sw/workspace.md') 'not managed by sw'
        Initialize-SwProject -Path $dir -Profile generic -Name Adopt -Adopt | Out-Null

        $backups = @(Get-ChildItem -Path (Join-Path $dir '.sw/backup') -Recurse -Filter 'workspace.md' -Force)
        $backups.Count | Should -Be 1
        (Get-Content -LiteralPath $backups[0].FullName -Raw) | Should -Match 'not managed by sw'
        (Read-SwText (Join-Path $dir '.sw/workspace.md')) | Should -Not -Match 'not managed by sw'
    }

    It 'a pre-existing AGENTS.md keeps its text and gains the core and profile blocks' {
        $dir = Join-Path $TestDrive 'agentsMd'
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Write-SwFile (Join-Path $dir 'AGENTS.md') "# My Project`n`nCustom project text.`n"
        Initialize-SwProject -Path $dir -Profile generic -Name AgentsMd | Out-Null

        $text = Read-SwText (Join-Path $dir 'AGENTS.md')
        $text | Should -Match 'Custom project text\.'
        $text | Should -Match '<!-- sw:begin core -->'
        $text | Should -Match '<!-- sw:begin profile -->'
    }

    It 'the manifest records kitVersion and kitCommit' {
        $dir = New-SwProject 'kitCommit' generic
        $m = Read-SwJson (Join-Path $dir '.sw/manifest.json')
        $m['kitVersion'] | Should -Be (Get-SwKitVersion)
        $m.Contains('kitCommit') | Should -BeTrue
        $m['kitCommit'] | Should -Be (Get-SwKitCommit)
    }

    It 'kitCommit is null for a kit copied into another repository' {
        $host_ = Join-Path $TestDrive 'hostRepo'
        New-Item -ItemType Directory -Force -Path (Join-Path $host_ 'vendor-kit') | Out-Null
        Write-SwFile (Join-Path $host_ 'vendor-kit/VERSION') "0.0.0`n"
        & git -C $host_ init -q -b main
        & git -C $host_ add -A
        & git -C $host_ -c user.email=t@example.invalid -c user.name=t commit -q -m host
        InModuleScope Sw.Kit -Parameters @{ Dir = (Join-Path $host_ 'vendor-kit') } {
            param($Dir)
            $saved = $script:Kit
            try { $script:Kit = $Dir; Get-SwKitCommit | Should -BeNullOrEmpty } finally { $script:Kit = $saved }
        }
    }

    It 'kitCommit identifies the active root-layout repository' {
        $head = & git -C $RepoRoot rev-parse HEAD
        $LASTEXITCODE | Should -Be 0
        Get-SwKitCommit | Should -Be $head
    }

    It 'Compare-SwVersion orders <A> vs <B> as <Expected>' -ForEach @(
        @{ A = '0.3.0-dev'; B = '0.3.0'; Expected = -1 }
        @{ A = '0.3.0'; B = '0.3.0-dev'; Expected = 1 }
        @{ A = '0.3.0'; B = '0.3.0'; Expected = 0 }
        @{ A = '0.10.0'; B = '0.9.9'; Expected = 1 }
        @{ A = '0.3.0-dev'; B = '0.4.0-dev'; Expected = -1 }
    ) {
        Compare-SwVersion $A $B | Should -Be $Expected
    }

    It 'refuses to downgrade a project a newer kit updated, unless -Force' {
        $dir = New-SwProject 'downgrade' generic
        $mPath = Join-Path $dir '.sw/manifest.json'
        $m = Read-SwJson $mPath
        $m['kitVersion'] = '99.0.0'
        Write-SwFile $mPath (ConvertTo-SwJson $m)
        { Sync-SwProject -Root $dir -Config (Get-SwConfig $dir) } | Should -Throw '*newer than this kit*'
        (Read-SwJson $mPath)['kitVersion'] | Should -Be '99.0.0'
        Sync-SwProject -Root $dir -Config (Get-SwConfig $dir) -Force | Out-Null
        (Read-SwJson $mPath)['kitVersion'] | Should -Be (Get-SwKitVersion)
    }

    It 'Format-SwPlan prints kit A -> B' {
        $dir = New-SwProject 'planKit' generic
        $plan = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
        (Format-SwPlan $plan '0.2.0' '0.3.0')[0] | Should -Be 'kit 0.2.0 -> 0.3.0'
    }

    It 'an edited file the kit did not change is kept-local, with no incoming copy or merge hint' {
        $dir = New-SwProject 'keptLocal' generic
        $target = Join-Path $dir '.sw/workspace.md'
        Write-SwFile $target ((Read-SwText $target) + "`nmy local note`n")
        $plan = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
        ($plan | Where-Object Path -eq '.sw/workspace.md').Action | Should -Be 'kept-local'
        Test-Path (Join-Path $dir '.sw/backup') | Should -BeFalse
        (Format-SwPlan $plan) -join "`n" | Should -Not -Match 'git diff'
    }

    It 'an edited file the kit changed gets an incoming copy and one git diff line' {
        $dir = New-SwProject 'incoming' generic
        $target = Join-Path $dir '.sw/workspace.md'
        $mPath = Join-Path $dir '.sw/manifest.json'
        $m = Read-SwJson $mPath
        $m['files']['.sw/workspace.md'] = Get-SwHash "old kit text`n"
        Write-SwFile $mPath (ConvertTo-SwJson $m)
        Write-SwFile $target "old kit text`nmy local note`n"

        $plan = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
        $row = $plan | Where-Object Path -eq '.sw/workspace.md'
        $row.Action | Should -Be 'skip-modified'
        Read-SwText $target | Should -Be "old kit text`nmy local note`n"
        $incoming = @(Get-ChildItem -Path (Join-Path $dir '.sw/backup') -Recurse -File -Force)
        $incoming.Count | Should -Be 1
        $incoming[0].FullName.Replace('\', '/') | Should -Match '/\.sw/backup/[^/]+/incoming/\.sw/workspace\.md$'
        Read-SwText $incoming[0].FullName | Should -Be (Get-SwRender (Get-SwConfig $dir)).Files['.sw/workspace.md']
        @((Format-SwPlan $plan) -match '^\s*git diff --no-index \.sw/workspace\.md \.sw/backup/[^ ]+/incoming/\.sw/workspace\.md$').Count | Should -Be 1
        (Read-SwJson $mPath)['files']['.sw/workspace.md'] | Should -Be (Get-SwHash "old kit text`n")
    }

    It 'an adopted AGENTS.md without Project identity gains the project sections above the core block' {
        $dir = Join-Path $TestDrive 'adoptIdentity'
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $mine = "# My Project`n`nCustom project text.`n"
        Write-SwFile (Join-Path $dir 'AGENTS.md') $mine
        $out = Initialize-SwProject -Path $dir -Profile generic -Name AdoptIdentity -Adopt

        $text = Read-SwText (Join-Path $dir 'AGENTS.md')
        $text.StartsWith($mine) | Should -BeTrue
        $text | Should -Match '(?m)^## Project identity\s*$'
        $text.IndexOf('## Project identity') | Should -BeLessThan $text.IndexOf('<!-- sw:begin core -->')
        ($out -join "`n") | Should -Match 'fill Project identity'
        (Test-SwValidate $dir).ExitCode | Should -Be 0
        $again = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
        ($again | Where-Object Path -eq 'AGENTS.md').Action | Should -Be 'same'
    }

    Context 'rename map' {
        BeforeEach { InModuleScope Sw.Kit { $script:Moved['.sw/old-workspace.md'] = '.sw/workspace.md' } }
        AfterEach { InModuleScope Sw.Kit { $script:Moved.Remove('.sw/old-workspace.md') } }

        BeforeAll {
            function Set-OldLayout([string]$Dir, [string]$Content) {
                # Simulate a project from a kit that shipped .sw/workspace.md as .sw/old-workspace.md.
                $mPath = Join-Path $Dir '.sw/manifest.json'
                $m = Read-SwJson $mPath
                $m['files'].Remove('.sw/workspace.md')
                $m['files']['.sw/old-workspace.md'] = Get-SwHash "old kit text`n"
                Write-SwFile $mPath (ConvertTo-SwJson $m)
                Remove-Item -LiteralPath (Join-Path $Dir '.sw/workspace.md') -Force
                Write-SwFile (Join-Path $Dir '.sw/old-workspace.md') $Content
            }
        }

        It 'an unedited old file is removed and the new one added' {
            $dir = New-SwProject 'moveClean' generic
            Set-OldLayout $dir "old kit text`n"
            $plan = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
            ($plan | Where-Object Path -eq '.sw/old-workspace.md').Action | Should -Be 'remove'
            ($plan | Where-Object Path -eq '.sw/workspace.md').Action | Should -Be 'add'
            Test-Path (Join-Path $dir '.sw/old-workspace.md') | Should -BeFalse
            Read-SwText (Join-Path $dir '.sw/workspace.md') | Should -Be (Get-SwRender (Get-SwConfig $dir)).Files['.sw/workspace.md']
        }

        It 'an edited old file moves with its edit and is skip-modified' {
            $dir = New-SwProject 'moveEdited' generic
            Set-OldLayout $dir "old kit text`nmy local note`n"
            $plan = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
            @($plan | Where-Object Path -eq '.sw/old-workspace.md').Count | Should -Be 0
            ($plan | Where-Object Path -eq '.sw/workspace.md').Action | Should -Be 'skip-modified'
            Test-Path (Join-Path $dir '.sw/old-workspace.md') | Should -BeFalse
            Read-SwText (Join-Path $dir '.sw/workspace.md') | Should -Be "old kit text`nmy local note`n"
            @(Get-ChildItem -Path (Join-Path $dir '.sw/backup') -Recurse -File -Force -Filter 'workspace.md').Count | Should -Be 1
            $files = (Read-SwJson (Join-Path $dir '.sw/manifest.json'))['files']
            $files.Contains('.sw/old-workspace.md') | Should -BeFalse
            $files['.sw/workspace.md'] | Should -Be (Get-SwHash "old kit text`n")

            $again = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
            ($again | Where-Object Path -eq '.sw/workspace.md').Action | Should -Be 'skip-modified'
        }

        Context 'skills prefix' {
            BeforeAll {
                function Set-OldSkillLayout([string]$Dir, [string]$Name, [string]$Content) {
                    # Simulate a project from a kit that shipped skill $Name's SKILL.md (as "old kit text")
                    # under .opencode/skills instead of .agents/skills.
                    $old = ".opencode/skills/$Name/SKILL.md"; $new = ".agents/skills/$Name/SKILL.md"
                    $mPath = Join-Path $Dir '.sw/manifest.json'
                    $m = Read-SwJson $mPath
                    $m['files'].Remove($new)
                    $m['files'][$old] = Get-SwHash "old kit text`n"
                    Write-SwFile $mPath (ConvertTo-SwJson $m)
                    Remove-Item -LiteralPath (Join-Path $Dir ".agents/skills/$Name") -Recurse -Force
                    Write-SwFile (Join-Path $Dir $old) $Content
                }
            }

            It 'an unedited skill under the old .opencode/skills prefix is removed and the new .agents/skills copy is added' {
                $dir = New-SwProject 'moveSkillClean' generic
                Set-OldSkillLayout $dir 'minimal-change' "old kit text`n"
                $own = Join-Path $dir '.opencode/skills/my-own/SKILL.md'
                Write-SwFile $own "---`nname: my-own`ndescription: A user skill.`n---`n`nBody.`n"
                $plan = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
                ($plan | Where-Object Path -eq '.opencode/skills/minimal-change/SKILL.md').Action | Should -Be 'remove'
                ($plan | Where-Object Path -eq '.agents/skills/minimal-change/SKILL.md').Action | Should -Be 'add'
                Test-Path (Join-Path $dir '.opencode/skills/minimal-change/SKILL.md') | Should -BeFalse
                Read-SwText (Join-Path $dir '.agents/skills/minimal-change/SKILL.md') | Should -Be (Get-SwRender (Get-SwConfig $dir)).Files['.agents/skills/minimal-change/SKILL.md']
                @($plan | Where-Object Path -like '.opencode/skills/my-own/*').Count | Should -Be 0
                Test-Path $own | Should -BeTrue
                (Test-SwValidate $dir).ExitCode | Should -Be 0
            }

            It 'an edited skill under the old .opencode/skills prefix moves with its edit and is skip-modified' {
                $dir = New-SwProject 'moveSkillEdited' generic
                Set-OldSkillLayout $dir 'minimal-change' "old kit text`nmy local note`n"
                $plan = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
                @($plan | Where-Object Path -eq '.opencode/skills/minimal-change/SKILL.md').Count | Should -Be 0
                ($plan | Where-Object Path -eq '.agents/skills/minimal-change/SKILL.md').Action | Should -Be 'skip-modified'
                Test-Path (Join-Path $dir '.opencode/skills/minimal-change/SKILL.md') | Should -BeFalse
                Read-SwText (Join-Path $dir '.agents/skills/minimal-change/SKILL.md') | Should -Be "old kit text`nmy local note`n"
            }
        }
    }

    It '-WhatIf writes nothing' {
        $dir = Join-Path $TestDrive 'whatif'
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Initialize-SwProject -Path $dir -Profile generic -Name WhatIf -WhatIf
        @(Get-ChildItem -Path $dir -Recurse -Force).Count | Should -Be 0
    }
}

Describe 'Records option' {
    BeforeAll {
        function Get-RecordsRender($Value) {
            $c = [ordered]@{ project = 'R'; profile = 'generic'; githubTier = 0; github = $true; users = @() }
            if ($null -ne $Value) { $c['records'] = $Value }
            Get-SwRender $c
        }
    }

    It 'renders identically when records is absent or tracked' {
        $default = Get-RecordsRender $null
        ((Get-RecordsRender 'tracked') | ConvertTo-Json -Depth 4) | Should -BeExactly ($default | ConvertTo-Json -Depth 4)
        $default.GitIgnore | Should -Not -Match 'comms'
        $default.Files['.sw/collaboration.md'] | Should -Match 'published when a human pushes their branch'
    }

    It 'records: local ignores .sw/comms/ and rewords only collaboration.md' {
        $default = Get-RecordsRender $null
        $local = Get-RecordsRender 'local'
        @($local.GitIgnore -split "`n") | Should -Be (@($default.GitIgnore -split "`n") + '.sw/comms/')
        @($default.Files.Keys | Where-Object { $default.Files[$_] -cne $local.Files[$_] }) | Should -Be @('.sw/collaboration.md')
        $local.Files['.sw/collaboration.md'] | Should -Not -Match 'published when a human pushes'
        $local.Files['.sw/collaboration.md'] | Should -Match 'kept local by `records: local` \(git-ignored, never pushed\)'
    }

    It 'rejects any other records value' {
        foreach ($v in 'Local', 'remote', '') { { Get-RecordsRender $v } | Should -Throw "*'records' must be 'tracked' or 'local'*" }
    }

    It 'a local-records project updates, validates and leaves its records untracked' {
        $dir = New-SwProject "records$(New-Id)"
        $c = Get-SwConfig $dir; $c['records'] = 'local'; Write-SwFile (Join-Path $dir '.sw/config.json') (ConvertTo-SwJson $c)
        Update-SwProject -Path $dir | Out-Null
        git -C $dir check-ignore -q -- .sw/comms/tasks/x/README.md; $LASTEXITCODE | Should -Be 0
        (Test-SwValidate $dir).ExitCode | Should -Be 0
    }
}

Describe 'Validator negative fixtures' {
    BeforeEach { $dir = New-SwProject "neg$(New-Id)" generic }

    It '<Name>' -ForEach @(
        @{ Name = 'missing agent file'; Match = 'Missing agent: project-developer'; Mutate = {
                param($d) Remove-Item (Join-Path $d '.opencode/agents/project-developer.md')
            }
        }
        @{ Name = 'unsupported frontmatter scalar'; Match = 'Unsupported scalar'; Mutate = {
                param($d) $f = Join-Path $d '.opencode/agents/project-developer.md'
                Write-SwFile $f ((Read-SwText $f) -replace '(?m)^description:.*$', 'description: [bad, value]')
            }
        }
        @{ Name = 'command routed to wrong agent'; Match = 'Command validate must route to project-developer'; Mutate = {
                param($d) $f = Join-Path $d '.opencode/commands/validate.md'
                Write-SwFile $f ((Read-SwText $f) -replace '(?m)^agent: project-developer$', 'agent: project-review')
            }
        }
        @{ Name = 'model pin added to opencode.jsonc'; Match = 'forbidden shared pin: model'; Mutate = {
                param($d) $f = Join-Path $d 'opencode.jsonc'
                $oc = Read-SwJson $f
                $oc['model'] = 'gpt-4'
                Write-SwFile $f (ConvertTo-SwJson $oc)
            }
        }
        @{ Name = 'absolute path in agent description'; Match = 'absolute machine path'; Mutate = {
                param($d) $f = Join-Path $d '.opencode/agents/project-developer.md'
                Write-SwFile $f ((Read-SwText $f) -replace '(?m)^description:.*$', 'description: Reads files from C:\x for context')
            }
        }
        @{ Name = 'JSONC comment in opencode.jsonc'; Match = 'must stay strict JSON'; Mutate = {
                param($d) $f = Join-Path $d 'opencode.jsonc'
                Write-SwFile $f ((Read-SwText $f) -replace '^\{', "{`n  // comment")
            }
        }
        @{ Name = '.opencode/opencode.jsonc tracked by git'; Match = 'Per-user config must be untracked and git-ignored: \.opencode/opencode\.jsonc'; Mutate = {
                param($d)
                Write-SwFile (Join-Path $d '.opencode/opencode.jsonc') '{}'
                git -C $d add -f .opencode/opencode.jsonc | Out-Null
            }
        }
        @{ Name = 'githubTier changed in config without update'; Match = 'do not match githubTier 1'; Mutate = {
                param($d) $f = Join-Path $d '.sw/config.json'
                $c = Read-SwJson $f; $c['githubTier'] = 1
                Write-SwFile $f (ConvertTo-SwJson $c)
            }
        }
        @{ Name = 'agent leading rules differ from the session rules'; Match = 'Session rule drift: \.opencode/agents/project-developer\.md .*run sw update'; Mutate = {
                param($d) $f = Join-Path $d '.opencode/agents/project-developer.md'
                Write-SwFile $f ((Read-SwText $f).Replace("resource: `"git push *`"`n    effect: deny", "resource: `"git push *`"`n    effect: ask"))
            }
        }
        @{ Name = 'session shell rule without its RTK twin'; Match = 'RTK twin missing: \.opencode/agents/project-developer\.md shell \[git push \*\].*run sw update'; Mutate = {
                param($d) $f = Join-Path $d '.opencode/agents/project-developer.md'
                Write-SwFile $f ((Read-SwText $f).Replace("  - action: shell`n    resource: `"rtk git push *`"`n    effect: deny`n", ''))
            }
        }
        @{ Name = 'role shell rule without its RTK twin'; Match = 'RTK twin missing: \.opencode/agents/project-review\.md shell \[git status \*\]'; Mutate = {
                param($d) $f = Join-Path $d '.opencode/agents/project-review.md'
                Write-SwFile $f ((Read-SwText $f).Replace("  - action: shell`n    resource: `"rtk git status *`"`n    effect: allow`n", ''))
            }
        }
        @{ Name = 'opencode.jsonc shell rule without its RTK twin'; Match = 'RTK twin missing: opencode\.jsonc permissions shell \[gh \*\]'; Mutate = {
                param($d) $f = Join-Path $d 'opencode.jsonc'
                $oc = Read-SwJson $f
                $oc['permissions'] = @($oc['permissions'] | Where-Object { $_['resource'] -cne 'rtk gh *' })
                Write-SwFile $f (ConvertTo-SwJson $oc)
            }
        }
        @{ Name = 'read-only shell list re-opens --output'; Match = 'STATIC project-review shell \[git diff --output=probe\.txt\]: expected deny, got allow'; Mutate = {
                param($d) $f = Join-Path $d '.opencode/agents/project-review.md'
                Write-SwFile $f ((Read-SwText $f).Replace("`n---`n", "`n  - action: shell`n    resource: `"git diff *`"`n    effect: allow`n---`n"))
            }
        }
        @{ Name = 'startupBudgetBytes set tiny'; Match = 'Startup budget exceeded for'; Mutate = {
                param($d) $f = Join-Path $d '.sw/config.json'
                $c = Read-SwJson $f; $c['startupBudgetBytes'] = 10
                Write-SwFile $f (ConvertTo-SwJson $c)
            }
        }
        @{ Name = 'trailing whitespace in .sw/workspace.md'; Match = 'trailing whitespace'; Mutate = {
                param($d) $f = Join-Path $d '.sw/workspace.md'
                Write-SwFile $f ((Read-SwText $f) + "trailing line  `n")
            }
        }
        @{ Name = 'AGENTS.md without a Project identity heading'; Match = 'AGENTS\.md must have a "## Project identity" heading'; Mutate = {
                param($d) $f = Join-Path $d 'AGENTS.md'
                Write-SwFile $f ((Read-SwText $f) -replace '(?m)^## Project identity$', '## Identity')
            }
        }
        @{ Name = 'skill name outside the Agent Skills pattern'; Match = 'name must be 1-64 lowercase'; Mutate = {
                param($d) Write-SwFile (Join-Path $d '.agents/skills/bad--name/SKILL.md') "---`nname: bad--name`ndescription: Probe.`n---`n`nBody.`n"
            }
        }
        @{ Name = 'skill description over 1024 characters'; Match = 'description exceeds 1024 characters'; Mutate = {
                param($d) $f = Join-Path $d '.agents/skills/minimal-change/SKILL.md'
                Write-SwFile $f ((Read-SwText $f) -replace '(?m)^description:.*$', "description: $('x' * 1025)")
            }
        }
        @{ Name = 'kit skill left under .opencode/skills shadows the .agents/skills copy'; Match = 'shadows the kit copy in OpenCode'; Mutate = {
                param($d) Write-SwFile (Join-Path $d '.opencode/skills/minimal-change/SKILL.md') "---`nname: minimal-change`ndescription: Shadow copy.`n---`n`nBody.`n"
            }
        }
    ) {
        & $Mutate $dir
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 1
        ($result.Output -join "`n") | Should -Match $Match
    }

    It 'Claude adapter drift is detected after hand-editing a generated file' {
        Set-TestClaudeMap $dir
        Invoke-SwClaude enable -Path $dir | Out-Null
        $f = Join-Path $dir '.claude/project-leader.md'
        Write-SwFile $f ((Read-SwText $f) + "`nedited by hand`n")
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 1
        ($result.Output -join "`n") | Should -Match 'Claude adapter drift: \.claude/project-leader\.md'
    }

    It 'Claude structure is checked against roles.json: <Name>' -ForEach @(
        @{ Name = 'wrong model'; Match = 'Claude agent project-developer: model must match the local role map'; Mutate = {
                param($d) $f = Join-Path $d '.claude/agents/project-developer.md'
                Write-SwFile $f ((Read-SwText $f) -replace '(?m)^model: opus$', 'model: sonnet')
            }
        }
        @{ Name = 'wrong tools'; Match = 'Claude agent project-review: tools must be'; Mutate = {
                param($d) $f = Join-Path $d '.claude/agents/project-review.md'
                Write-SwFile $f ((Read-SwText $f) -replace '(?m)^tools: .*$', 'tools: Read, Edit')
            }
        }
        @{ Name = 'missing disallowedTools'; Match = 'Claude agent project-developer: must set disallowedTools: Agent'; Mutate = {
                param($d) $f = Join-Path $d '.claude/agents/project-developer.md'
                Write-SwFile $f ((Read-SwText $f) -replace "(?m)^disallowedTools: Agent`n", '')
            }
        }
        @{ Name = 'missing agent'; Match = 'Missing Claude agent: \.claude/agents/project-developer\.md'; Mutate = {
                param($d) Remove-Item -LiteralPath (Join-Path $d '.claude/agents/project-developer.md') -Force
            }
        }
        @{ Name = 'missing command'; Match = 'Missing Claude command: \.claude/commands/review\.md'; Mutate = {
                param($d) Remove-Item -LiteralPath (Join-Path $d '.claude/commands/review.md') -Force
            }
        }
    ) {
        Set-TestClaudeMap $dir
        Invoke-SwClaude enable -Path $dir | Out-Null
        & $Mutate $dir
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 1
        ($result.Output -join "`n") | Should -Match $Match
    }
}

Describe 'Research lint' {
    It 'is silent without docs/research' {
        $dir = New-SwProject "research$(New-Id)" generic
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 0
        ($result.Output -join "`n") | Should -Not -Match 'WARNING'
    }

    It 'warns on missing sections, an undated header and an uncited finding, without failing' {
        $dir = New-SwProject "research$(New-Id)" generic
        $sections = "## 1. Question`n`nQ.`n`n## 2. Findings`n`n### Web`n`nF1. **Cited.** <https://example.com>.`n`nF2. **Same.** Same page as`nF1.`n`nF3. **Uncited.** A claim.`n`n### Local analysis`n`nF4. **Covered by the heading.** A claim.`n`n## 3. Options`n`nO.`n`n## 4. Recommendation`n`nR.`n`n## 5. Open questions`n`nNone.`n`n## 6. Supersedes / updates`n`nNone.`n"
        Write-SwFile (Join-Path $dir 'docs/research/01-good.md') "# 01: Good`n`nAll sources accessed 2026-09-27.`n`n$sections"
        Write-SwFile (Join-Path $dir 'docs/research/02-bad.md') "# 02: Bad`n`nNo date here.`n`n## 1. Question`n`nQ.`n"
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 0
        $out = $result.Output -join "`n"
        $out | Should -Match 'WARNING: docs/research/01-good\.md: F3 has no citation'
        $out | Should -Not -Match '01-good\.md: (F1|F2|F4) '
        $out | Should -Not -Match '01-good\.md: (missing section|header)'
        $out | Should -Match 'WARNING: docs/research/02-bad\.md: missing section\(s\) 2, 3, 4, 5, 6'
        $out | Should -Match 'WARNING: docs/research/02-bad\.md: header has no YYYY-MM-DD date'
        $out | Should -Match 'PASS:'
    }
}

Describe 'Startup budget output' {
    It 'labels the token figure as a bytes/4 estimate and counts the subagent catalogue for project-leader only' {
        $dir = New-SwProject "budget$(New-Id)" generic
        $lines = @(Test-SwProject -Path $dir | Where-Object { $_ -like 'Startup budget:*' })
        $lines | Should -Not -BeNullOrEmpty
        foreach ($l in $lines) { $l | Should -Match '^Startup budget: \S+ = \d+ bytes, ~\d+ tokens \(bytes/4 estimate; tokenizer varies\); cap \d+$' }
        $f = Join-Path $dir '.opencode/agents/project-review.md'
        $bytes = { param($role) [int]((@(Test-SwProject -Path $dir) -like "Startup budget: $role =*")[0] -replace '^.* = (\d+) bytes.*$', '$1') }
        $leader = & $bytes project-leader; $developer = & $bytes project-developer
        Write-SwFile $f ((Read-SwText $f) -replace '(?m)^description: (.*)$', 'description: $1 Padded.')
        (& $bytes project-leader) | Should -Be ($leader + 8)
        (& $bytes project-developer) | Should -Be $developer
    }
}

Describe 'Validator positive fixture' {
    It 'GitHubTier 1 init validates' {
        $dir = New-SwProject "tier1$(New-Id)" generic 1
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 0
    }
}

Describe 'Claude adapter' {
    BeforeEach { $dir = New-SwProject "claude$(New-Id)" generic 0 -Legacy; Set-TestClaudeMap $dir }

    It 'enable generates agents/commands/skills and a compliant settings.json' {
        Invoke-SwClaude enable -Path $dir | Out-Null

        $roles = Read-SwJson (Join-Path $dir '.sw/roles.json')
        $workers = @($roles.Keys | Where-Object { $_ -notin 'project-leader', 'explore' })
        foreach ($r in $workers) {
            $text = Read-SwText (Join-Path $dir ".claude/agents/$r.md")
            $text | Should -Match '(?m)^model: opus$'
            $text | Should -Not -Match '(?m)^(effort|reasoningEffort):'
            if ($roles[$r]['claudeTools']) { $text | Should -Match "(?m)^tools: $([regex]::Escape($roles[$r]['claudeTools']))$" }
            else { $text | Should -Not -Match '(?m)^tools:' }
            $text | Should -Match '(?m)^disallowedTools: Agent$'
        }
        @(Get-ChildItem (Join-Path $dir '.claude/agents') -Filter *.md -Force).Count | Should -Be $workers.Count
        Get-Content -LiteralPath (Join-Path $dir '.claude/agents/project-developer.md') -Raw | Should -Match '(?m)^disallowedTools: Agent$'
        Get-Content -LiteralPath (Join-Path $dir '.claude/agents/project-research.md') -Raw | Should -Match 'WebSearch'
        Test-Path (Join-Path $dir '.claude/agents/project-leader.md') | Should -BeFalse
        Test-Path (Join-Path $dir '.claude/agents/explore.md') | Should -BeFalse

        foreach ($c in Get-ChildItem (Join-Path $dir '.opencode/commands') -Filter *.md) {
            Test-Path (Join-Path $dir ".claude/commands/$($c.BaseName).md") | Should -BeTrue
        }
        @(Get-ChildItem (Join-Path $dir '.claude/commands') -Filter *.md -Force).Count | Should -Be @(Get-ChildItem (Join-Path $dir '.opencode/commands') -Filter *.md -Force).Count
        (Test-SwValidate $dir).ExitCode | Should -Be 0
        foreach ($s in Get-ChildItem (Join-Path $dir '.agents/skills') -Directory) {
            Test-Path (Join-Path $dir ".claude/skills/$($s.Name)/SKILL.md") | Should -BeTrue
        }

        $settings = Read-SwJson (Join-Path $dir '.claude/settings.json')
        $settings['permissions']['deny'] | Should -Contain 'Bash(git push *)'
        $settings['permissions']['deny'] | Should -Contain 'Bash(git -* push *)'
        $settings['permissions']['deny'] | Should -Contain 'Bash(gh pr merge:*)'
        $settings['permissions']['deny'] | Should -Contain 'Bash(gh pr create:*)'
        $settings['permissions']['deny'] | Should -Contain 'Bash(gh alias:*)'
        $settings['permissions']['ask'] | Should -Contain 'Read(**/.env)'
        $settings['permissions']['ask'] | Should -Contain 'Read(**/.env.*)'
    }

    It 'builds the leader dispatch sentence from the command subagent flags' {
        Invoke-SwClaude enable -Path $dir | Out-Null
        $leader = Join-Path $dir '.claude/project-leader.md'
        Read-SwText $leader | Should -Match '`/review` and `/status` dispatch `project-review`'

        $f = Join-Path $dir '.opencode/commands/review.md'
        Write-SwFile $f ((Read-SwText $f) -replace '(?m)^subagent: true$', 'subagent: false')
        Invoke-SwClaude enable -Path $dir | Out-Null
        $text = Read-SwText $leader
        $text | Should -Match '`/status` dispatches `project-review`'
        $text | Should -Not -Match '`/review` and `/status` dispatch'
        # The summary follows the same availability decision as each command body.
        $text | Should -Match '`/review` applies the `project-review` contract inline'
        $text | Should -Match '`/validate` applies the `project-developer` contract inline'
        (Test-SwValidate $dir).ExitCode | Should -Be 0
    }

    It 'refuses to enable when .claude/ is not git-ignored' {
        Invoke-SwClaude enable -Path $dir | Out-Null
        git -C $dir add -f .claude/settings.json | Out-Null
        { Invoke-SwClaude enable -Path $dir } | Should -Throw '*git-ignored*'
    }

    It 'disable removes the generated files' {
        Invoke-SwClaude enable -Path $dir | Out-Null
        Invoke-SwClaude disable -Path $dir | Out-Null
        Test-Path (Join-Path $dir '.claude/agents/project-developer.md') | Should -BeFalse
        Test-Path (Join-Path $dir '.claude/settings.json') | Should -BeFalse
        Test-Path (Join-Path $dir '.claude/.sw-generated') | Should -BeFalse
    }

    It 'enable backs up a pre-existing user file before overwriting it, and disable keeps a user-edited file' {
        New-Item -ItemType Directory -Force (Join-Path $dir '.claude') | Out-Null
        Set-Content -LiteralPath (Join-Path $dir '.claude/settings.json') -Value '{"mine":true}' -NoNewline
        Invoke-SwClaude enable -Path $dir | Out-Null
        $backups = @(Get-ChildItem (Join-Path $dir '.sw/backup') -Recurse -Filter 'settings.json' -File -Force)
        $backups.Count | Should -Be 1
        (Get-Content -LiteralPath $backups[0].FullName -Raw) | Should -Match 'mine'

        # A user edit made after enable must survive disable.
        Set-Content -LiteralPath (Join-Path $dir '.claude/settings.json') -Value '{"edited":true}' -NoNewline
        Invoke-SwClaude disable -Path $dir | Out-Null
        Test-Path (Join-Path $dir '.claude/settings.json') | Should -BeTrue
        (Get-Content -LiteralPath (Join-Path $dir '.claude/settings.json') -Raw) | Should -Match 'edited'
    }
}

Describe 'Claude adapter ownership' {
    BeforeAll {
        function Get-Tree([string]$Dir) {
            if (-not (Test-Path -LiteralPath $Dir)) { return 'absent' }
            (@(Get-ChildItem -LiteralPath $Dir -Recurse -File -Force | Sort-Object FullName | ForEach-Object { "$($_.FullName.Substring($Dir.Length)):$((Get-FileHash $_.FullName).Hash)" }) -join "`n")
        }
        function Set-RawMap([string]$Root, $Map) { Write-SwFile (Join-Path $Root '.opencode/opencode.jsonc') (ConvertTo-SwJson $Map) }
        function Add-UserFiles([string]$Root) {
            Write-SwFile (Join-Path $Root '.claude/settings.local.json') '{"local":true}'
            Write-SwFile (Join-Path $Root '.claude/notes.md') "my notes`n"
            Write-SwFile (Join-Path $Root '.claude/agents/mine.md') "Generated by SuperWorkspace (a user wrote this text himself)`n"
        }
    }
    BeforeEach {
        $dir = New-SwProject "own$(New-Id)" generic 0
        Set-TestClaudeMap $dir
        Invoke-SwClaude enable -Path $dir | Out-Null
        $generated = @((Get-SwClaudeFiles $dir).Keys)
        Add-UserFiles $dir
    }

    It 'enable records a deterministic, versioned, sorted byte-hash inventory that never lists itself' {
        $text = Read-SwText (Join-Path $dir '.claude/.sw-generated')
        $text | Should -Match '(?m)^sw-ownership: 1$'
        $own = Read-SwClaudeOwnership $dir
        $own.State | Should -Be 'ok'
        $expected = [string[]]@($generated | Where-Object { $_ -cne '.claude/.sw-generated' })
        [Array]::Sort($expected, [StringComparer]::Ordinal)
        @($own.Entries.Keys) | Should -Be $expected
        $own.Entries.Contains('.claude/.sw-generated') | Should -BeFalse
        foreach ($rel in $own.Entries.Keys) { (Get-FileHash (Join-Path $dir $rel) -Algorithm SHA256).Hash.ToLowerInvariant() | Should -Be $own.Entries[$rel] }
        # Deterministic: a second enable changes nothing.
        $before = Get-Tree $dir
        Invoke-SwClaude enable -Path $dir | Out-Null
        Get-Tree $dir | Should -Be $before
        (Test-SwValidate $dir).ExitCode | Should -Be 0
    }

    It 'disable removes owned files whatever the replacement map says: <Name>' -ForEach @(
        @{ Name = 'all non-Claude'; Map = { @{ agents = @{ 'project-developer' = @{ model = 'openai/x' }; 'project-review' = @{ model = 'openai/x' } } } } }
        @{ Name = 'mixed'; Map = { @{ agents = @{ 'project-leader' = @{ model = 'opus' }; 'project-review' = @{ model = 'openai/x' } } } } }
        @{ Name = 'malformed'; Map = $null; Raw = '{ not json' }
        @{ Name = 'missing'; Map = $null; Remove = $true }
    ) {
        $mapPath = Join-Path $dir '.opencode/opencode.jsonc'
        if ($Map) { Set-RawMap $dir (& $Map) } elseif ($Remove) { Remove-Item -LiteralPath $mapPath -Force } else { Write-SwFile $mapPath $Raw }
        $out = Invoke-SwClaude disable -Path $dir | Out-String
        $out | Should -Not -Match 'PARTIAL'
        $global:LASTEXITCODE | Should -Be 0
        foreach ($rel in $generated) { Test-Path (Join-Path $dir $rel) | Should -BeFalse -Because $rel }
        Test-Path (Join-Path $dir '.claude/settings.local.json') | Should -BeTrue
        Test-Path (Join-Path $dir '.claude/notes.md') | Should -BeTrue
        # Marker text alone proves nothing: the user's own file is kept.
        Test-Path (Join-Path $dir '.claude/agents/mine.md') | Should -BeTrue
    }

    It 'an edited owned file is kept, disable reports PARTIAL, and the ownership record stays' {
        $edited = Join-Path $dir '.claude/agents/project-developer.md'
        Write-SwFile $edited ((Read-SwText $edited) + "my edit`n")
        $out = Invoke-SwClaude disable -Path $dir | Out-String
        $out | Should -Match 'PARTIAL'
        $out | Should -Match 'project-developer\.md \(edited\)'
        $global:LASTEXITCODE | Should -Be 1
        Test-Path $edited | Should -BeTrue
        Test-Path (Join-Path $dir '.claude/.sw-generated') | Should -BeTrue
        Test-Path (Join-Path $dir '.claude/settings.json') | Should -BeFalse
    }
    It 'the CLI forwards the PARTIAL disable exit code' {
        $edited = Join-Path $dir '.claude/agents/project-developer.md'
        Write-SwFile $edited ((Read-SwText $edited) + "my edit`n")
        & pwsh -NoProfile -File (Join-Path $RepoRoot 'sw.ps1') claude disable -Path $dir | Out-Null
        $LASTEXITCODE | Should -Be 1
    }

    It 'a no-op disable outside a Git checkout exits 0, not a stale native exit code' {
        $empty = Join-Path $TestDrive 'not-a-checkout'; $null = New-Item -ItemType Directory $empty
        Push-Location $empty
        try { & pwsh -NoProfile -File (Join-Path $RepoRoot 'sw.ps1') claude disable | Out-Null; $code = $LASTEXITCODE } finally { Pop-Location }
        $code | Should -Be 0
    }

    It 'a malformed or hostile inventory is rejected whole, with every file kept: <Name>' -ForEach @(
        @{ Name = 'unknown version'; Edit = { param($t) $t.Replace('sw-ownership: 1', 'sw-ownership: 2') } }
        @{ Name = 'repeated header'; Edit = { param($t) $t + "sw-ownership: 1`n" } }
        @{ Name = 'garbage line'; Edit = { param($t) $t + "not-a-hash  .claude/x.md`n" } }
        @{ Name = 'duplicate path'; Edit = { param($t) $l = ($t -split "`n" | Where-Object { $_ -match '^[0-9a-f]{64}  ' })[0]; $t + "$l`n" } }
        @{ Name = 'traversal'; Edit = { param($t) $t + ('0' * 64) + "  .claude/../AGENTS.md`n" } }
        @{ Name = 'absolute path'; Edit = { param($t) $t + ('0' * 64) + "  /etc/passwd`n" } }
        @{ Name = 'drive path'; Edit = { param($t) $t + ('0' * 64) + "  C:/Windows/win.ini`n" } }
        @{ Name = 'backslash path'; Edit = { param($t) $t + ('0' * 64) + "  .claude\agents\x.md`n" } }
        @{ Name = 'outside .claude'; Edit = { param($t) $t + ('0' * 64) + "  AGENTS.md`n" } }
        @{ Name = 'settings.local.json'; Edit = { param($t) $t + ('0' * 64) + "  .claude/settings.local.json`n" } }
        @{ Name = 'nested settings.local.json'; Edit = { param($t) $t + ('0' * 64) + "  .claude/agents/Settings.Local.json`n" } }
    ) {
        $record = Join-Path $dir '.claude/.sw-generated'
        Write-SwFile $record (& $Edit (Read-SwText $record))
        $before = Get-Tree $dir
        $agentsBefore = (Get-FileHash (Join-Path $dir 'AGENTS.md')).Hash
        { Invoke-SwClaude disable -Path $dir } | Should -Throw '*ownership record is invalid*'
        Get-Tree $dir | Should -Be $before
        (Get-FileHash (Join-Path $dir 'AGENTS.md')).Hash | Should -Be $agentsBefore
    }

    It 'a legacy marker-only install is removed only where its content is exactly reproducible' {
        $marker = InModuleScope Sw.Project { $script:ClaudeMarker }
        Write-SwFile (Join-Path $dir '.claude/.sw-generated') $marker
        (Read-SwClaudeOwnership $dir).State | Should -Be 'legacy'
        $edited = Join-Path $dir '.claude/commands/work.md'
        Write-SwFile $edited ((Read-SwText $edited) + "local tweak`n")
        $out = Invoke-SwClaude disable -Path $dir | Out-String
        $out | Should -Match 'PARTIAL'
        $out | Should -Match 'work\.md \(edited\)'
        Test-Path $edited | Should -BeTrue
        Test-Path (Join-Path $dir '.claude/agents/project-developer.md') | Should -BeFalse
        Test-Path (Join-Path $dir '.claude/settings.json') | Should -BeFalse
        Test-Path (Join-Path $dir '.claude/agents/mine.md') | Should -BeTrue
        Test-Path (Join-Path $dir '.claude/.sw-generated') | Should -BeTrue
    }

    It 'a legacy install whose generation cannot be reproduced keeps every byte and reports it' {
        $marker = InModuleScope Sw.Project { $script:ClaudeMarker }
        Write-SwFile (Join-Path $dir '.claude/.sw-generated') $marker
        Set-RawMap $dir @{ agents = @{ 'project-review' = @{ model = 'openai/x' } } }
        $before = Get-Tree $dir
        $out = Invoke-SwClaude disable -Path $dir | Out-String
        $out | Should -Match 'PARTIAL'
        $out | Should -Match 'cannot reproduce'
        Get-Tree $dir | Should -Be $before
    }

    It 'enabling over a legacy install reports unlisted legacy files instead of deleting them' {
        $marker = InModuleScope Sw.Project { $script:ClaudeMarker }
        Write-SwFile (Join-Path $dir '.claude/.sw-generated') $marker
        Write-SwFile (Join-Path $dir '.claude/agents/old-role.md') "Generated by SuperWorkspace`nold role`n"
        $out = Invoke-SwClaude enable -Path $dir | Out-String
        $out | Should -Match 'Unverified legacy file\(s\) left in place.*old-role\.md'
        Test-Path (Join-Path $dir '.claude/agents/old-role.md') | Should -BeTrue
        (Read-SwClaudeOwnership $dir).State | Should -Be 'ok'
    }

    It 'enable never deletes by marker text: stale pruning follows the inventory and keeps edited stale files' {
        # A role dropped from the map leaves a stale owned file: removed while unedited, kept when edited.
        $stale = Join-Path $dir '.claude/agents/project-review.md'
        Test-Path $stale | Should -BeTrue
        Set-RawMap $dir @{ agents = @{ 'project-leader' = @{ model = 'opus' }; 'project-developer' = @{ model = 'opus' } } }
        Invoke-SwClaude enable -Path $dir | Out-Null
        Test-Path $stale | Should -BeFalse
        Test-Path (Join-Path $dir '.claude/agents/mine.md') | Should -BeTrue
        Set-RawMap $dir @{ agents = @{ 'project-leader' = @{ model = 'opus' }; 'project-developer' = @{ model = 'opus' }; 'project-review' = @{ model = 'opus' } } }
        Invoke-SwClaude enable -Path $dir | Out-Null
        Write-SwFile $stale ((Read-SwText $stale) + "edited`n")
        Set-RawMap $dir @{ agents = @{ 'project-leader' = @{ model = 'opus' }; 'project-developer' = @{ model = 'opus' } } }
        $out = Invoke-SwClaude enable -Path $dir | Out-String
        Test-Path $stale | Should -BeTrue
        $out | Should -Match 'Edited stale generated file'
    }

    It 'enable backs up an edited or unverified target, even one with marker text, before replacing it' {
        $target = Join-Path $dir '.claude/commands/work.md'
        Write-SwFile $target "---`ndescription: x`n---`nGenerated by SuperWorkspace but edited by hand`n"
        $bytes = [IO.File]::ReadAllBytes($target)
        Invoke-SwClaude enable -Path $dir | Out-Null
        $backups = @(Get-ChildItem (Join-Path $dir '.sw/backup') -Recurse -File -Force | Where-Object { $_.FullName.Replace('\', '/') -match '/\.claude/commands/work\.md$' })
        $backups.Count | Should -Be 1
        ([IO.File]::ReadAllBytes($backups[0].FullName)) | Should -Be $bytes
        (Test-SwFileMatches $target (Get-SwClaudeFiles $dir)['.claude/commands/work.md']) | Should -BeTrue
    }

    It 'repeated snapshots at a fixed clock keep both generations' {
        Mock -ModuleName Sw.Project Get-SwUtc { '2000-01-01T000000Z' }
        $target = Join-Path $dir '.claude/commands/work.md'
        Write-SwFile $target "first edit`n"
        Invoke-SwClaude enable -Path $dir | Out-Null
        Write-SwFile $target "second edit`n"
        Invoke-SwClaude enable -Path $dir | Out-Null
        $backups = @(Get-ChildItem (Join-Path $dir '.sw/backup') -Recurse -File -Force | Where-Object { $_.Name -eq 'work.md' })
        $backups.Count | Should -Be 2
        @($backups | ForEach-Object { Read-SwText $_.FullName } | Sort-Object) | Should -Be @("first edit`n", "second edit`n")
    }

    It 'a failed recovery copy stops the replacement of that file' {
        $target = Join-Path $dir '.claude/commands/work.md'
        Write-SwFile $target "precious edit`n"
        Mock -ModuleName Sw.Project Copy-SwNew { throw 'injected backup failure' }
        { Invoke-SwClaude enable -Path $dir } | Should -Throw '*injected backup failure*'
        Read-SwText $target | Should -Be "precious edit`n"
    }

    It '-WhatIf leaves enable and disable filesystem state identical' {
        $target = Join-Path $dir '.claude/commands/work.md'
        Write-SwFile $target "edited`n"
        $before = Get-Tree $dir
        Invoke-SwClaude enable -Path $dir -WhatIf *> $null
        Get-Tree $dir | Should -Be $before
        Invoke-SwClaude disable -Path $dir -WhatIf *> $null
        Get-Tree $dir | Should -Be $before
    }

    It 'the Leader summary and each command body come from one availability decision: <Name>' -ForEach @(
        @{ Name = 'all Claude'; Map = { @{ agents = @{ 'project-leader' = @{ model = 'opus' }; 'project-developer' = @{ model = 'opus' }; 'project-review' = @{ model = 'opus' }; 'project-research' = @{ model = 'opus' } } } } }
        @{ Name = 'developer non-Claude'; Map = { @{ agents = @{ 'project-leader' = @{ model = 'opus' }; 'project-developer' = @{ model = 'openai/x' }; 'project-review' = @{ model = 'opus' } } } } }
        @{ Name = 'unmapped developer and review'; Map = { @{ agents = @{ 'project-leader' = @{ model = 'opus' } } } } }
    ) {
        Set-RawMap $dir (& $Map)
        $files = Get-SwClaudeFiles $dir
        $leader = $files['.claude/project-leader.md']
        foreach ($cmd in Get-ChildItem (Join-Path $dir '.opencode/commands') -Filter *.md) {
            $fm = Read-SwFrontmatter $cmd.FullName @('description', 'agent', 'subagent')
            $body = $files[".claude/commands/$($cmd.BaseName).md"]
            $stops = $body -match 'STOP:'
            if ($fm['agent'] -eq 'project-developer' -and $fm['subagent'] -eq 'false') {
                if ($stops) { $leader | Should -Match "``/$($cmd.BaseName)`` (and ``/\w+`` )?stops? with a blocker"; $leader | Should -Not -Match "``/$($cmd.BaseName)`` applies" }
                else { $leader | Should -Match "``/$($cmd.BaseName)`` applies the ``project-developer`` contract inline" }
            }
        }
        if ($Name -eq 'all Claude') { $leader | Should -Match '`/validate` applies the `project-developer` contract inline' }
        else { $leader | Should -Not -Match '`/validate` applies' ; $leader | Should -Match '`/validate`[^.]*stops? with a blocker' }
    }
}

Describe 'Get-SwNarrowedGhAllow' {
    It 'removes a short-circuiting broad Bash(gh *) allow and adds the read-only allowlist' {
        $r = Get-SwNarrowedGhAllow @('Bash(gh *)')
        $r.Changed | Should -BeTrue
        $r.Allow | Should -Not -Contain 'Bash(gh *)'
        $r.Allow | Should -Contain 'Bash(gh issue view:*)'
    }
    It 'also removes the Bash(gh:*) form even when Bash(gh *) is absent' {
        $r = Get-SwNarrowedGhAllow @('Bash(gh:*)', 'Bash(npm test:*)')
        $r.Changed | Should -BeTrue
        $r.Allow | Should -Not -Contain 'Bash(gh:*)'
        $r.Allow | Should -Contain 'Bash(npm test:*)'
    }
}

Describe 'Validation-first lifecycle' {
    BeforeAll {
        function Get-Tree([string]$Dir) {
            if (-not (Test-Path -LiteralPath $Dir)) { return 'absent' }
            (@(Get-ChildItem -LiteralPath $Dir -Recurse -File -Force | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/](?!lfs)' } | Sort-Object FullName |
                    ForEach-Object { "$($_.FullName.Substring($Dir.Length)):$((Get-FileHash $_.FullName).Hash)" }) -join "`n")
        }
        function Set-StaleKitText([string]$Root) {
            # Make the kit want to update an unedited managed file, so any write before validation would show.
            $f = Join-Path $Root '.sw/workspace.md'
            Write-SwFile $f "old kit text`n"
            $mPath = Join-Path $Root '.sw/manifest.json'
            $m = Read-SwJson $mPath
            $m['files']['.sw/workspace.md'] = Get-SwHash "old kit text`n"
            Write-SwFile $mPath (ConvertTo-SwJson $m)
        }
    }

    It 'a malformed managed block stops update before any file, manifest or config write: <Name>' -ForEach @(
        @{ Name = 'AGENTS core unterminated'; File = 'AGENTS.md'; Edit = { param($t) $t.Replace('<!-- sw:end core -->', '') } }
        @{ Name = 'AGENTS profile unterminated'; File = 'AGENTS.md'; Edit = { param($t) $t.Replace('<!-- sw:end profile -->', '') } }
        @{ Name = 'AGENTS core end without begin'; File = 'AGENTS.md'; Edit = { param($t) $t.Replace('<!-- sw:begin core -->', '') } }
        @{ Name = '.gitignore unterminated'; File = '.gitignore'; Edit = { param($t) $t.Replace('# sw:end superworkspace', '') } }
        @{ Name = '.gitignore repeated begin'; File = '.gitignore'; Edit = { param($t) $t + "# sw:begin superworkspace`n" } }
        @{ Name = '.gitattributes unterminated, empty replacement'; File = '.gitattributes'; Edit = { param($t) "# sw:begin superworkspace`n*.txt text`n" } }
        @{ Name = '.gitattributes end without begin, empty replacement'; File = '.gitattributes'; Edit = { param($t) "*.txt text`n# sw:end superworkspace`n" } }
    ) {
        $dir = New-SwProject "block$(New-Id)" generic
        $f = Join-Path $dir $File
        $current = if (Test-Path -LiteralPath $f) { Read-SwText $f } else { '' }
        Write-SwFile $f (& $Edit $current)
        Set-StaleKitText $dir
        $before = Get-Tree $dir
        { Update-SwProject -Path $dir } | Should -Throw '*managed block*'
        { Sync-SwProject -Root $dir -Config (Get-SwConfig $dir) } | Should -Throw '*managed block*'
        Get-Tree $dir | Should -Be $before
        Read-SwText (Join-Path $dir '.sw/workspace.md') | Should -Be "old kit text`n"
    }

    It 'init with a malformed block throws before git init, config, manifest or any file: <Name>' -ForEach @(
        @{ Name = 'plain'; Extra = @{} }
        @{ Name = '-Adopt'; Extra = @{ Adopt = $true } }
        @{ Name = '-Force'; Extra = @{ Force = $true } }
    ) {
        $dir = Join-Path $TestDrive "initblock$(New-Id)"
        Write-SwFile (Join-Path $dir 'AGENTS.md') "# Mine`n<!-- sw:begin core -->`nunterminated`n"
        Write-SwFile (Join-Path $dir '.gitignore') "node_modules/`n"
        $before = Get-Tree $dir
        { Initialize-SwProject -Path $dir -Profile generic -Name Block @Extra } | Should -Throw '*Unterminated managed block*'
        Test-Path (Join-Path $dir '.git') | Should -BeFalse
        Test-Path (Join-Path $dir '.sw') | Should -BeFalse
        Get-Tree $dir | Should -Be $before
    }

    It 'an unsafe Unreal-to-generic transition is refused before any write, even with -Force or -Adopt, and LFS bytes survive' {
        $dir = New-SwProject "lfs$(New-Id)" unreal
        $ga = Join-Path $dir '.gitattributes'
        $attrs = Read-SwText $ga
        $attrs | Should -Match 'filter=lfs'
        Write-SwFile $ga ("# project rules`n*.png binary`n`n" + $attrs + "`n# trailing project rule`n*.mp4 binary`n")
        $pointer = "version https://git-lfs.github.com/spec/v1`noid sha256:$('ab' * 32)`nsize 12345`n"
        Write-SwFile (Join-Path $dir 'Content/Big.uasset') $pointer
        Write-SwFile (Join-Path $dir ".git/lfs/objects/ab/ab/$('ab' * 32)") 'synthetic lfs object bytes'
        $before = Get-Tree $dir
        $configBefore = Read-SwText (Join-Path $dir '.sw/config.json')
        foreach ($mode in @{}, @{ Force = $true }, @{ Adopt = $true }, @{ Force = $true; Adopt = $true }) {
            { Initialize-SwProject -Path $dir -Profile generic @mode } | Should -Throw '*Refusing to drop*LFS*'
        }
        $c = Read-SwJson (Join-Path $dir '.sw/config.json'); $c['profile'] = 'generic'
        Write-SwFile (Join-Path $dir '.sw/config.json') (ConvertTo-SwJson $c)
        { Update-SwProject -Path $dir } | Should -Throw '*Refusing to drop*LFS*'
        { Update-SwProject -Path $dir -Force -Adopt } | Should -Throw '*Refusing to drop*LFS*'
        Write-SwFile (Join-Path $dir '.sw/config.json') $configBefore
        Get-Tree $dir | Should -Be $before
        (Read-SwText $ga) | Should -Match 'trailing project rule'
        # The same profile still updates cleanly and idempotently.
        $plan = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
        @($plan | Where-Object Action -ne 'same').Count | Should -Be 0
    }

    It 'a retained managed .gitattributes block without LFS rules is left alone by a generic update' {
        $dir = New-SwProject "keepblock$(New-Id)" generic
        $ga = Join-Path $dir '.gitattributes'
        Write-SwFile $ga "*.png binary`n# sw:begin superworkspace`n# no lfs here`n# sw:end superworkspace`n"
        $before = Get-Tree $dir
        Update-SwProject -Path $dir | Out-Null
        Read-SwText $ga | Should -Be "*.png binary`n# sw:begin superworkspace`n# no lfs here`n# sw:end superworkspace`n"
        (Test-SwValidate $dir).ExitCode | Should -Be 0
    }

    It 'adoption snapshots at a fixed clock keep every generation' {
        Mock -ModuleName Sw.Project Get-SwUtc { '2000-01-01T000000Z' }
        $dir = Join-Path $TestDrive "adoptgen$(New-Id)"
        Write-SwFile (Join-Path $dir '.sw/workspace.md') 'unmanaged one'
        Initialize-SwProject -Path $dir -Profile generic -Name AdoptGen -Adopt | Out-Null
        # A second unmanaged file at the same path (the kit no longer knows it), same clock.
        $mPath = Join-Path $dir '.sw/manifest.json'
        $m = Read-SwJson $mPath; $m['files'].Remove('.sw/workspace.md'); Write-SwFile $mPath (ConvertTo-SwJson $m)
        Write-SwFile (Join-Path $dir '.sw/workspace.md') 'unmanaged two'
        Update-SwProject -Path $dir -Adopt | Out-Null
        $backups = @(Get-ChildItem (Join-Path $dir '.sw/backup') -Recurse -File -Force -Filter workspace.md)
        $backups.Count | Should -Be 2
        @($backups | ForEach-Object { Read-SwText $_.FullName } | Sort-Object) | Should -Be @('unmanaged one', 'unmanaged two')
        @(Get-ChildItem (Join-Path $dir '.sw/backup') -Directory).Count | Should -Be 2
    }

    It 'incoming-copy snapshots at a fixed clock keep every generation' {
        Mock -ModuleName Sw.Project Get-SwUtc { '2000-01-01T000000Z' }
        $dir = New-SwProject "incgen$(New-Id)" generic
        $f = Join-Path $dir '.sw/workspace.md'
        Write-SwFile $f "old kit text`nmy note`n"
        $mPath = Join-Path $dir '.sw/manifest.json'
        $m = Read-SwJson $mPath; $m['files']['.sw/workspace.md'] = Get-SwHash "old kit text`n"; Write-SwFile $mPath (ConvertTo-SwJson $m)
        Sync-SwProject -Root $dir -Config (Get-SwConfig $dir) | Out-Null
        Sync-SwProject -Root $dir -Config (Get-SwConfig $dir) | Out-Null
        $copies = @(Get-ChildItem (Join-Path $dir '.sw/backup') -Recurse -File -Force -Filter workspace.md)
        $copies.Count | Should -Be 2
        Read-SwText $f | Should -Be "old kit text`nmy note`n"
    }

    It 'a reservation or copy failure (<Failing>) stops the adoption replacement' -ForEach @(
        @{ Failing = 'New-SwSnapshotDir' }
        @{ Failing = 'Copy-SwNew' }
    ) {
        $dir = Join-Path $TestDrive "adoptfail$(New-Id)"
        Write-SwFile (Join-Path $dir '.sw/workspace.md') 'unmanaged and precious'
        Mock -ModuleName Sw.Kit $Failing { throw 'injected recovery failure' }
        { Initialize-SwProject -Path $dir -Profile generic -Name AdoptFail -Adopt } | Should -Throw '*injected recovery failure*'
        Read-SwText (Join-Path $dir '.sw/workspace.md') | Should -Be 'unmanaged and precious'
    }

    It '-WhatIf adoption creates no snapshot and changes nothing' {
        $dir = Join-Path $TestDrive "adoptwhatif$(New-Id)"
        Write-SwFile (Join-Path $dir '.sw/workspace.md') 'unmanaged'
        $before = Get-Tree $dir
        Initialize-SwProject -Path $dir -Profile generic -Name W -Adopt -WhatIf *> $null
        Get-Tree $dir | Should -Be $before
        Test-Path (Join-Path $dir '.sw/backup') | Should -BeFalse
    }
}

Describe 'Get-SwNarrowedGhAllow (all broad forms)' {
    It 'removes every exact broad occurrence, keeps unrelated rules in order, and is idempotent' {
        $in = @('Bash(gh *)', 'Bash(npm test:*)', 'Bash(gh *)', 'Bash(gh:*)', 'Read(x)', 'Bash(gh:*)', 'Bash(gh *)')
        $r = Get-SwNarrowedGhAllow $in
        $r.Changed | Should -BeTrue
        $r.Allow | Should -Not -Contain 'Bash(gh *)'
        $r.Allow | Should -Not -Contain 'Bash(gh:*)'
        @($r.Allow | Select-Object -First 2) | Should -Be @('Bash(npm test:*)', 'Read(x)')
        $again = Get-SwNarrowedGhAllow @($r.Allow)
        $again.Changed | Should -BeFalse
        @($again.Allow) | Should -Be @($r.Allow)
    }
    It 'does not touch narrow forms such as Bash(gh issue view:*)' {
        $r = Get-SwNarrowedGhAllow @('Bash(gh issue view:*)')
        $r.Allow | Should -Contain 'Bash(gh issue view:*)'
        @($r.Allow | Where-Object { $_ -eq 'Bash(gh issue view:*)' }).Count | Should -Be 1
    }
}

Describe 'Set-SwTiers' {
    It 'writes .opencode/opencode.jsonc mapping standard/light roles to the given model, and refuses to overwrite without -Force' {
        $dir = New-SwProject "tiers$(New-Id)" generic -Legacy
        Set-SwTiers -Light haiku -Standard sonnet -High opus -Path $dir | Out-Null
        $target = Join-Path $dir '.opencode/opencode.jsonc'
        $map = (Read-SwJson $target)['agents']
        $map['project-research']['model'] | Should -Be 'sonnet'
        $map['project-review']['model'] | Should -Be 'sonnet'
        $map['project-developer']['model'] | Should -Be 'haiku'
        $map['explore']['model'] | Should -Be 'haiku'
        $map.Contains('project-leader') | Should -BeFalse

        { Set-SwTiers -Light grok -Standard grok -High grok -Path $dir } | Should -Throw '*-Force*'
        Set-SwTiers -Light grok -Standard grok -High grok -Path $dir -Force | Out-Null
        (Read-SwJson $target)['agents']['project-review']['model'] | Should -Be 'grok'
    }
}

Describe 'Comms' {
    BeforeEach { $dir = New-SwProject "comms$(New-Id)" generic }

    It 'send creates an inbox message containing the subject' {
        Invoke-SwComms send -To alice -Subject 'Hello world' -Body 'content' -Path $dir | Out-Null
        $msg = @(Get-ChildItem (Join-Path $dir '.sw/comms/inbox/alice') -Filter *.md)
        $msg.Count | Should -Be 1
        (Get-Content -LiteralPath $msg[0].FullName -Raw) | Should -Match 'Hello world'
    }

    It 'event writes a task record with the given status' {
        Invoke-SwComms event -Task T1 -Status blocked -Path $dir | Out-Null
        $ev = @(Get-ChildItem (Join-Path $dir '.sw/comms/tasks/T1') -Filter *.md)
        $ev.Count | Should -Be 1
        (Get-Content -LiteralPath $ev[0].FullName -Raw) | Should -Match '\*\*Status:\*\* blocked'
    }

    It 'event lists at most 10 changed paths, drops .sw/comms/ entries, and counts the rest' {
        git -C $dir add -A | Out-Null
        git -C $dir commit -q -m init | Out-Null
        Invoke-SwComms event -Task T0 -Path $dir | Out-Null
        1..12 | ForEach-Object { Write-SwFile (Join-Path $dir ('f{0:d2}.txt' -f $_)) 'x' }
        Invoke-SwComms event -Task T4 -Path $dir | Out-Null
        $ev = @(Get-ChildItem (Join-Path $dir '.sw/comms/tasks/T4') -Filter *.md)
        $line = @((Read-SwText $ev[0].FullName) -split "`n" | Where-Object { $_ -like '- **Checked revision / changed:**' + '*' })[0]
        $line | Should -Not -Match '\.sw/comms'
        $line | Should -Match 'f10\.txt \(\+2 more\)$'
        $line | Should -Not -Match 'f11\.txt'
        ([regex]::Matches($line, 'f\d\d\.txt')).Count | Should -Be 10
    }

    It 'close moves events into archive and writes SUMMARY.md' {
        Invoke-SwComms event -Task T2 -Path $dir | Out-Null
        Invoke-SwComms close -Task T2 -Outcome 'shipped' -Path $dir | Out-Null
        Test-Path (Join-Path $dir '.sw/comms/tasks/T2') | Should -BeFalse
        $events = @(Get-ChildItem (Join-Path $dir '.sw/comms/archive/T2/events') -Filter *.md)
        $events.Count | Should -Be 1
        Test-Path (Join-Path $dir '.sw/comms/archive/T2/SUMMARY.md') | Should -BeTrue
    }

    It 'Add-SwUser adds the contributor to config and creates their inbox' {
        Add-SwUser bob -Path $dir | Out-Null
        (Read-SwJson (Join-Path $dir '.sw/config.json'))['users'] | Should -Contain 'bob'
        Test-Path (Join-Path $dir '.sw/comms/inbox/bob/.gitkeep') | Should -BeTrue
    }

    It 'rejects path traversal in -To/-User/-From/-Task/-Message' {
        { Invoke-SwComms send -To '../../evil' -Subject s -Path $dir } | Should -Throw '*Invalid*'
        { Invoke-SwComms inbox -User '..' -Path $dir } | Should -Throw '*Invalid*'
        { Invoke-SwComms send -To alice -Subject s -From '..' -Path $dir } | Should -Throw '*Invalid*'
        { Invoke-SwComms event -Task '../../../etc' -Path $dir } | Should -Throw '*Invalid*'
        { Invoke-SwComms archive -User alice -Message '../../evil.md' -Path $dir } | Should -Throw '*Invalid*'
    }

    It '`comms close -Task ..` does not delete unrelated comms content' {
        Invoke-SwComms event -Task Real -Path $dir | Out-Null
        { Invoke-SwComms close -Task '..' -Outcome x -Path $dir } | Should -Throw '*Invalid*'
        Test-Path (Join-Path $dir '.sw/comms/tasks/Real') | Should -BeTrue
    }

    It 'send appends -2 on a same-second filename collision instead of overwriting' {
        Invoke-SwComms send -To alice -Subject dup -Body first -Path $dir | Out-Null
        Invoke-SwComms send -To alice -Subject dup -Body second -Path $dir | Out-Null
        $msgs = @(Get-ChildItem (Join-Path $dir '.sw/comms/inbox/alice') -Filter *.md | Sort-Object Name)
        $msgs.Count | Should -Be 2
        ($msgs | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join '' | Should -Match 'first'
        ($msgs | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join '' | Should -Match 'second'
    }

    It 'send and event -WhatIf leave the filesystem untouched' {
        Invoke-SwComms event -Task W1 -Path $dir | Out-Null
        $tree = { @(Get-ChildItem -LiteralPath (Join-Path $dir '.sw/comms') -Recurse -File -Force | Sort-Object FullName | ForEach-Object { "$($_.FullName):$((Get-FileHash $_.FullName).Hash)" }) -join "`n" }
        $before = & $tree
        Invoke-SwComms send -To alice -Subject whatif -Body x -Path $dir -WhatIf *> $null
        Invoke-SwComms event -Task W1 -Path $dir -WhatIf *> $null
        Invoke-SwComms event -Task Brand-New -Path $dir -WhatIf *> $null
        & $tree | Should -Be $before
        Test-Path (Join-Path $dir '.sw/comms/tasks/Brand-New') | Should -BeFalse
    }

    It 'close refuses to overwrite an existing archive' {
        Invoke-SwComms event -Task T3 -Path $dir | Out-Null
        Invoke-SwComms close -Task T3 -Outcome 'first' -Path $dir | Out-Null
        Invoke-SwComms event -Task T3 -Path $dir | Out-Null
        { Invoke-SwComms close -Task T3 -Outcome 'second' -Path $dir } | Should -Throw '*already exists*'
        Get-Content (Join-Path $dir '.sw/comms/archive/T3/SUMMARY.md') -Raw | Should -Match 'first'
    }
}

Describe 'Exclusive record allocation' {
    It 'coordinated independent writers each get a distinct, complete file' {
        $dir = Join-Path $TestDrive "excl$(New-Id)"
        $modulePath = Join-Path $RepoRoot 'lib/Sw.Project.psm1'
        $payloads = 1..8 | ForEach-Object { "writer-$_`n" + ('x' * 20000) + "`nend-$_`n" }
        $barrier = [Threading.Barrier]::new(8)
        $paths = 0..7 | ForEach-Object -ThrottleLimit 8 -Parallel {
            Import-Module $using:modulePath -Force -DisableNameChecking
            ($using:barrier).SignalAndWait()
            & (Get-Module Sw.Project) { param($d, $c) New-SwExclusiveFile $d 'rec' '.md' $c } $using:dir (($using:payloads)[$_])
        }
        @($paths | Select-Object -Unique).Count | Should -Be 8
        $files = @(Get-ChildItem -LiteralPath $dir -File)
        $files.Count | Should -Be 8
        @($files | ForEach-Object { Read-SwText $_.FullName } | Sort-Object) | Should -Be @($payloads | Sort-Object)
    }

    It 'concurrent comms send and event writers at one fixed clock never overwrite or lose a record' {
        $dir = New-SwProject "race$(New-Id)" generic
        Mock -ModuleName Sw.Project Get-SwUtc { '2000-01-01T000000Z' }
        Invoke-SwComms send -To alice -From bob -Subject same -Body 'first' -Path $dir | Out-Null
        $first = @(Get-ChildItem (Join-Path $dir '.sw/comms/inbox/alice') -Filter *.md)[0]
        $firstHash = (Get-FileHash $first.FullName).Hash
        $modulePath = Join-Path $RepoRoot 'lib/Sw.Project.psm1'
        $barrier = [Threading.Barrier]::new(6)
        0..5 | ForEach-Object -ThrottleLimit 6 -Parallel {
            Import-Module $using:modulePath -Force -DisableNameChecking
            & (Get-Module Sw.Project) { function script:Get-SwUtc { '2000-01-01T000000Z' } }
            ($using:barrier).SignalAndWait()
            Invoke-SwComms send -To alice -From bob -Subject same -Body "body-$_" -Path $using:dir | Out-Null
            Invoke-SwComms event -Task T9 -From bob -Event progress -Body "event-$_" -Path $using:dir | Out-Null
        }
        $sent = @(Get-ChildItem (Join-Path $dir '.sw/comms/inbox/alice') -Filter *.md)
        $sent.Count | Should -Be 7
        (Get-FileHash $first.FullName).Hash | Should -Be $firstHash
        $bodies = ($sent | ForEach-Object { Read-SwText $_.FullName }) -join "`n"
        foreach ($n in 0..5) { $bodies | Should -Match "body-$n" }
        $events = @(Get-ChildItem (Join-Path $dir '.sw/comms/tasks/T9') -Filter *.md)
        $events.Count | Should -Be 6
        $text = ($events | ForEach-Object { Read-SwText $_.FullName }) -join "`n"
        foreach ($n in 0..5) { $text | Should -Match "event-$n" }
    }

    It 'bounds retries on real name collisions and never touches the existing records' {
        $dir = Join-Path $TestDrive "bound$(New-Id)"
        Write-SwFile (Join-Path $dir 'rec.md') 'one'
        foreach ($n in 2..5) { Write-SwFile (Join-Path $dir "rec-$n.md") "taken $n" }
        $before = @(Get-ChildItem $dir -File | Sort-Object Name | ForEach-Object { "$($_.Name):$((Get-FileHash $_.FullName).Hash)" })
        { InModuleScope Sw.Project -Parameters @{ Dir = $dir } { param($Dir) New-SwExclusiveFile $Dir 'rec' '.md' 'new' 5 } } | Should -Throw '*No free name*'
        @(Get-ChildItem $dir -File | Sort-Object Name | ForEach-Object { "$($_.Name):$((Get-FileHash $_.FullName).Hash)" }) | Should -Be $before
    }

    It 'a non-collision I/O failure surfaces at once instead of retrying' {
        $dir = Join-Path $TestDrive "noncoll$(New-Id)"
        New-Item -ItemType Directory -Force (Join-Path $dir 'rec.md') | Out-Null
        { InModuleScope Sw.Project -Parameters @{ Dir = $dir } { param($Dir) New-SwExclusiveFile $Dir 'rec' '.md' 'new' } } | Should -Throw
        Test-Path (Join-Path $dir 'rec-2.md') | Should -BeFalse
    }

    It 'returns a new name rather than truncating an immutable record' {
        $dir = Join-Path $TestDrive "immut$(New-Id)"
        Write-SwFile (Join-Path $dir 'rec.md') 'immutable'
        $path = InModuleScope Sw.Project -Parameters @{ Dir = $dir } { param($Dir) New-SwExclusiveFile $Dir 'rec' '.md' 'second' }
        Split-Path $path -Leaf | Should -Be 'rec-2.md'
        Read-SwText (Join-Path $dir 'rec.md') | Should -Be 'immutable'
    }
}

Describe 'Session event persistence' {
    BeforeAll {
        Mock -ModuleName Sw.Project Find-SwNative { $global:SwNativeStub }
        $script:Stub = Join-Path $TestDrive 'native-stub.ps1'
        Write-SwFile $script:Stub @'
[IO.File]::WriteAllText((Join-Path $env:SW_TEST_COUNT_DIR ([guid]::NewGuid().ToString('N'))), 'x')
$launchEvent = @(Get-ChildItem $env:SW_TEST_TASKDIR -Filter '*session-progress-*.md')[0]
if ($launchEvent -and $env:SW_TEST_MODE -eq 'dir') { New-Item -ItemType Directory (Join-Path $env:SW_TEST_TASKDIR ($launchEvent.BaseName + '-2.md')) | Out-Null }
if ($launchEvent -and $env:SW_TEST_MODE -eq 'exhaust') { 2..100 | ForEach-Object { Set-Content -LiteralPath (Join-Path $env:SW_TEST_TASKDIR "$($launchEvent.BaseName)-$_.md") -Value 'taken' } }
if ($env:SW_TEST_THROW -eq '1') { throw 'fixture native failure' }
$global:LASTEXITCODE = [int]$env:SW_TEST_EXIT
'@
        $global:SwNativeStub = $script:Stub
    }
    BeforeEach {
        $dir = New-SwProject "sess$(New-Id)" generic
        Set-SwTiers -Light openai/fixture -Standard openai/fixture -High openai/fixture -Path $dir | Out-Null
        $taskDir = Join-Path $dir '.sw/comms/tasks/t1'
        Write-SwFile (Join-Path $taskDir 'approval.md') "# fixture approval`n"
        $countDir = Join-Path $TestDrive "count$(New-Id)"
        New-Item -ItemType Directory $countDir | Out-Null
        $env:SW_TEST_COUNT_DIR = $countDir; $env:SW_TEST_TASKDIR = $taskDir
        $env:SW_TEST_MODE = ''; $env:SW_TEST_EXIT = '7'; $env:SW_TEST_THROW = '0'
        Mock -ModuleName Sw.Project Get-SwUtc { '2000-01-01T000000Z' }
    }
    AfterAll {
        Remove-Variable SwNativeStub -Scope Global -ErrorAction SilentlyContinue
        foreach ($n in 'SW_TEST_COUNT_DIR', 'SW_TEST_TASKDIR', 'SW_TEST_MODE', 'SW_TEST_EXIT', 'SW_TEST_THROW') { [Environment]::SetEnvironmentVariable($n, $null, 'Process') }
    }

    It 'records a distinct launch and exit event for one launch id, runs the native once and returns the exit' {
        $launch = Invoke-SwSession start project-developer t1 -Path $dir -Headless
        $launch.ExitCode | Should -Be 7
        $global:LASTEXITCODE | Should -Be 7
        @(Get-ChildItem $env:SW_TEST_COUNT_DIR).Count | Should -Be 1
        $events = @(Get-ChildItem $taskDir -Filter '*session-progress-*.md')
        $events.Count | Should -Be 2
        @($events.Name | Select-Object -Unique).Count | Should -Be 2
        foreach ($e in $events) { $e.Name | Should -Match $launch.LaunchId; (Read-SwText $e.FullName) | Should -Match "Launch ID:\*\* $($launch.LaunchId)" }
        (($events | ForEach-Object { Read-SwText $_.FullName }) -join "`n") | Should -Match 'exit-failure; effects unknown'
    }

    It 'a prelaunch recording failure blocks the launch: no native process runs' {
        Mock -ModuleName Sw.Project New-SwExclusiveFile { throw 'injected prelaunch recording failure' }
        { Invoke-SwSession start project-developer t1 -Path $dir -Headless } | Should -Throw '*injected prelaunch recording failure*'
        @(Get-ChildItem $env:SW_TEST_COUNT_DIR).Count | Should -Be 0
    }

    It 'a post-exit recording failure (<Mode>) reports unknown recording with the observed exit and never retries the native' -ForEach @(
        @{ Mode = 'dir'; Note = 'non-collision I/O failure' }
        @{ Mode = 'exhaust'; Note = 'bounded collision exhaustion' }
    ) {
        $env:SW_TEST_MODE = $Mode
        $err = $null
        try { Invoke-SwSession start project-developer t1 -Path $dir -Headless } catch { $err = $_ }
        $err | Should -Not -BeNullOrEmpty
        $err.Exception.Message | Should -Match 'exited with code 7'
        $err.Exception.Message | Should -Match 'recording unknown/blocked'
        $err.Exception.Data['ExitCode'] | Should -Be 7
        $err.Exception.Data['Launch'].ExitCode | Should -Be 7
        $global:LASTEXITCODE | Should -Be 7
        @(Get-ChildItem $env:SW_TEST_COUNT_DIR).Count | Should -Be 1
        # Only the launch event is a real record; no exit event is claimed.
        @(Get-ChildItem $taskDir -File -Filter '*session-progress-*.md' | Where-Object { (Read-SwText $_.FullName) -match 'Exit code:\*\* 7' }).Count | Should -Be 0
        if ($Mode -eq 'exhaust') { @(Get-ChildItem $taskDir -File -Filter '*session-progress-*.md').Count | Should -Be 100; Test-Path (Join-Path $taskDir "2000-01-01T000000Z-session-progress-$($err.Exception.Data['Launch'].LaunchId)-101.md") | Should -BeFalse }
    }

    It 'a thrown native invocation whose event cannot be recorded still reports unknown effects' {
        $env:SW_TEST_MODE = 'dir'; $env:SW_TEST_THROW = '1'
        { Invoke-SwSession start project-developer t1 -Path $dir -Headless } | Should -Throw '*event could not be recorded*effects/session identity unknown*'
        @(Get-ChildItem $env:SW_TEST_COUNT_DIR).Count | Should -Be 1
    }
}

Describe 'Native probe boundary' {
    # Diagnostics reach installed tools only through Find-SwTool and Invoke-SwProbe. Both are replaced
    # inside Sw.Project; any other tool or probe throws, so a real opencode/claude/rtk/gh/winget run fails the test.
    BeforeAll {
        # Mock bodies run outside the module's script scope, so the fake state lives in one global that AfterAll removes.
        Mock -ModuleName Sw.Project Find-SwTool {
            if (-not $global:SwFake.Tools.ContainsKey($Name)) { throw "unexpected tool discovery: $Name" }
            $global:SwFake.Tools[$Name]
        }
        Mock -ModuleName Sw.Project Invoke-SwProbe {
            $key = "$Exe|$($Arguments -join ' ')"
            if (-not $global:SwFake.Probes.ContainsKey($key)) { throw "unexpected native probe: $key" }
            $global:SwFake.Log += $key
            $global:SwFake.Probes[$key]
        }
        function Set-FakeTools([hashtable]$Tools) {
            $global:SwFake = @{ Tools = @{}; Probes = @{}; Log = @() }
            foreach ($name in $Tools.Keys) {
                $t = $Tools[$name]
                if ($t['Missing']) { $global:SwFake.Tools[$name] = $null; continue }
                $global:SwFake.Tools[$name] = "fake/$name"
                $exit = if ($t.ContainsKey('ExitCode')) { $t['ExitCode'] } else { 0 }
                $global:SwFake.Probes["fake/$name|--version"] = [pscustomobject]@{ Threw = [bool]$t['Threw']; ExitCode = $exit; Output = [string]$t['Output'] }
                if ($t.ContainsKey('AuthExit')) { $global:SwFake.Probes["fake/$name|auth status"] = [pscustomobject]@{ Threw = $false; ExitCode = $t['AuthExit']; Output = '' } }
            }
        }
        function Get-ProbeLog { @($global:SwFake.Log) }
    }
    AfterAll { Remove-Variable SwFake -Scope Global -ErrorAction SilentlyContinue }

    Context 'Get-SwToolProbe / Get-SwToolVersion' {
        It '<Name>: state <State>' -ForEach @(
            @{ Name = 'valid'; Tool = @{ Output = 'tool 1.4.2 (abc)' }; State = 'ok'; Version = '1.4.2' }
            @{ Name = 'missing'; Tool = @{ Missing = $true }; State = 'missing'; Version = $null }
            @{ Name = 'thrown'; Tool = @{ Threw = $true }; State = 'threw'; Version = $null }
            @{ Name = 'nonzero exit with plausible version text'; Tool = @{ Output = 'tool 1.4.2'; ExitCode = 3 }; State = 'failed'; Version = $null }
            @{ Name = 'unparseable output'; Tool = @{ Output = 'no digits here' }; State = 'unparsed'; Version = $null }
            @{ Name = 'empty output'; Tool = @{ Output = '' }; State = 'unparsed'; Version = $null }
        ) {
            Set-FakeTools @{ tool = $Tool }
            (Get-SwToolProbe tool).State | Should -Be $State
            $version = Get-SwToolVersion tool
            # No fabricated 0.0.0 for a tool that did not report a version.
            if ($Version) { $version | Should -Be ([version]$Version) } else { $version | Should -BeNullOrEmpty }
        }
        It 'preserves the native exit code in the probe and runs exactly one probe' {
            Set-FakeTools @{ tool = @{ Output = '1.0.0'; ExitCode = 5 } }
            (Get-SwToolProbe tool).ExitCode | Should -Be 5
            (Get-ProbeLog) | Should -Be @('fake/tool|--version')
        }
    }

    Context 'Get-SwGhAuth' {
        It 'reports the immediate exit of gh auth status: <Name>' -ForEach @(
            @{ Name = 'logged in'; Tools = @{ gh = @{ Output = 'gh 2.0.0'; AuthExit = 0 } }; Expected = 0 }
            @{ Name = 'logged out'; Tools = @{ gh = @{ Output = 'gh 2.0.0'; AuthExit = 1 } }; Expected = 1 }
            @{ Name = 'gh missing'; Tools = @{ gh = @{ Missing = $true } }; Expected = $null }
        ) {
            Set-FakeTools $Tools
            Get-SwGhAuth | Should -Be $Expected
        }
    }
}

Describe 'Invoke-SwProbe (real boundary, deterministic stub process)' {
    It 'captures stdout and the exact native exit, and reports a launch failure without throwing' {
        $r = InModuleScope Sw.Project -Parameters @{ Pwsh = (Get-Process -Id $PID).Path } {
            param($Pwsh)
            Invoke-SwProbe $Pwsh @('-NoProfile', '-Command', 'Write-Output v9.8.7; exit 7')
        }
        $r.ExitCode | Should -Be 7
        $r.Threw | Should -BeFalse
        $r.Output | Should -Match 'v9\.8\.7'
        $gone = InModuleScope Sw.Project -Parameters @{ Missing = (Join-Path ([IO.Path]::GetTempPath()) "sw-no-such-$([guid]::NewGuid().ToString('N')).exe") } {
            param($Missing)
            Invoke-SwProbe $Missing @('--version')
        }
        $gone.Threw | Should -BeTrue
    }
}

Describe 'Test-SwDoctor' {
    BeforeAll {
        # Mock bodies run outside the module's script scope, so the fake state lives in one global that AfterAll removes.
        Mock -ModuleName Sw.Project Find-SwTool {
            if (-not $global:SwFake.Tools.ContainsKey($Name)) { throw "unexpected tool discovery: $Name" }
            $global:SwFake.Tools[$Name]
        }
        Mock -ModuleName Sw.Project Invoke-SwProbe {
            $key = "$Exe|$($Arguments -join ' ')"
            if (-not $global:SwFake.Probes.ContainsKey($key)) { throw "unexpected native probe: $key" }
            $global:SwFake.Log += $key
            $global:SwFake.Probes[$key]
        }
        function Set-FakeTools([hashtable]$Tools) {
            $global:SwFake = @{ Tools = @{}; Probes = @{}; Log = @() }
            foreach ($name in $Tools.Keys) {
                $t = $Tools[$name]
                if ($t['Missing']) { $global:SwFake.Tools[$name] = $null; continue }
                $global:SwFake.Tools[$name] = "fake/$name"
                $exit = if ($t.ContainsKey('ExitCode')) { $t['ExitCode'] } else { 0 }
                $global:SwFake.Probes["fake/$name|--version"] = [pscustomobject]@{ Threw = [bool]$t['Threw']; ExitCode = $exit; Output = [string]$t['Output'] }
                if ($t.ContainsKey('AuthExit')) { $global:SwFake.Probes["fake/$name|auth status"] = [pscustomobject]@{ Threw = $false; ExitCode = $t['AuthExit']; Output = '' } }
            }
        }
        $script:GoodTools = @{ opencode = @{ Output = 'opencode 1.2.3' }; gh = @{ Output = 'gh 2.60.0'; AuthExit = 0 }; rtk = @{ Output = 'rtk 0.49.0' } }
    }
    AfterAll { Remove-Variable SwFake -Scope Global -ErrorAction SilentlyContinue }

    It 'reports tier-map and users guidance without -User, and does not throw' {
        Set-FakeTools $script:GoodTools
        $dir = New-SwProject "doctor$(New-Id)" generic
        { Test-SwDoctor -Path $dir } | Should -Not -Throw
        $out = Test-SwDoctor -Path $dir | Out-String
        $out | Should -Match 'sw\.ps1 tiers'
        $out | Should -Match 'pass -User <name>'
        $out | Should -Match 'Startup budget \(validate\) counts kit files only'
        $out | Should -Match 'Branch protection on main: not checked'
        $global:LASTEXITCODE | Should -Be 0
    }

    It 'a present but broken required OpenCode is FAILED, never OK: <Name>' -ForEach @(
        @{ Name = 'thrown'; Tool = @{ Threw = $true } }
        @{ Name = 'nonzero exit with version text'; Tool = @{ Output = 'opencode 1.2.3'; ExitCode = 1 } }
        @{ Name = 'unparseable output'; Tool = @{ Output = 'launcher error' } }
    ) {
        Set-FakeTools @{ opencode = $Tool; gh = $script:GoodTools.gh; rtk = $script:GoodTools.rtk }
        $dir = New-SwProject "doctor$(New-Id)" generic
        $out = Test-SwDoctor -Path $dir | Out-String
        $out | Should -Match '(?m)^opencode\s+FAILED'
        $out | Should -Not -Match '(?m)^opencode\s+OK'
        $global:LASTEXITCODE | Should -Be 1
    }

    It 'a missing required OpenCode is MISSING and fails the check' {
        Set-FakeTools @{ opencode = @{ Missing = $true }; gh = $script:GoodTools.gh; rtk = $script:GoodTools.rtk }
        $dir = New-SwProject "doctor$(New-Id)" generic
        (Test-SwDoctor -Path $dir | Out-String) | Should -Match '(?m)^opencode\s+MISSING'
        $global:LASTEXITCODE | Should -Be 1
    }

    It 'optional gh/rtk problems warn without failing: <Name>' -ForEach @(
        @{ Name = 'gh nonzero'; Tools = @{ gh = @{ Output = 'gh 2.60.0'; ExitCode = 2 }; rtk = @{ Output = 'rtk 0.49.0' } }; Item = 'gh' }
        @{ Name = 'rtk thrown'; Tools = @{ gh = @{ Output = 'gh 2.60.0'; AuthExit = 0 }; rtk = @{ Threw = $true } }; Item = 'rtk' }
        @{ Name = 'rtk missing'; Tools = @{ gh = @{ Output = 'gh 2.60.0'; AuthExit = 0 }; rtk = @{ Missing = $true } }; Item = 'rtk' }
        @{ Name = 'rtk too old'; Tools = @{ gh = @{ Output = 'gh 2.60.0'; AuthExit = 0 }; rtk = @{ Output = 'rtk 0.40.0' } }; Item = 'rtk >= 0.48' }
    ) {
        Set-FakeTools (@{ opencode = $script:GoodTools.opencode } + $Tools)
        $dir = New-SwProject "doctor$(New-Id)" generic
        (Test-SwDoctor -Path $dir | Out-String) | Should -Match "(?m)^$([regex]::Escape($Item))\s+WARN"
        $global:LASTEXITCODE | Should -Be 0
    }

    It 'gh auth follows the immediate probe exit and is skipped when gh is unusable' {
        $dir = New-SwProject "doctor$(New-Id)" generic
        Set-FakeTools @{ opencode = $script:GoodTools.opencode; gh = @{ Output = 'gh 2.60.0'; AuthExit = 0 }; rtk = $script:GoodTools.rtk }
        (Test-SwDoctor -Path $dir | Out-String) | Should -Match '(?m)^gh auth\s+OK\s+logged in'
        Set-FakeTools @{ opencode = $script:GoodTools.opencode; gh = @{ Output = 'gh 2.60.0'; AuthExit = 4 }; rtk = $script:GoodTools.rtk }
        (Test-SwDoctor -Path $dir | Out-String) | Should -Match '(?m)^gh auth\s+WARN'
        Set-FakeTools @{ opencode = $script:GoodTools.opencode; gh = @{ Output = 'gh 2.60.0'; ExitCode = 1; AuthExit = 0 }; rtk = $script:GoodTools.rtk }
        (Test-SwDoctor -Path $dir | Out-String) | Should -Not -Match 'gh auth'
    }

    It 'checks the branch actually checked out: <Name>' -ForEach @(
        @{ Name = 'solo on main'; Users = @(); Branch = 'main'; User = $null; State = 'OK' }
        @{ Name = 'solo on another branch'; Users = @(); Branch = 'alice/alice-worktree'; User = $null; State = 'WARN' }
        @{ Name = 'solo on another branch with -User'; Users = @(); Branch = 'alice/alice-worktree'; User = 'alice'; State = 'WARN' }
        @{ Name = 'solo detached'; Users = @(); Branch = 'DETACHED'; User = $null; State = 'WARN' }
        @{ Name = 'team, main, no identity'; Users = @('alice', 'bob'); Branch = 'main'; User = $null; State = 'WARN' }
        @{ Name = 'team, main, listed user'; Users = @('alice', 'bob'); Branch = 'main'; User = 'alice'; State = 'WARN' }
        @{ Name = 'team, own branch, listed user'; Users = @('alice', 'bob'); Branch = 'alice/alice-worktree'; User = 'alice'; State = 'OK' }
        @{ Name = 'team, own branch, no identity'; Users = @('alice', 'bob'); Branch = 'alice/alice-worktree'; User = $null; State = 'WARN' }
        @{ Name = "team, another user's branch"; Users = @('alice', 'bob'); Branch = 'bob/bob-worktree'; User = 'alice'; State = 'WARN' }
        @{ Name = 'team, wrong branch name for the user'; Users = @('alice', 'bob'); Branch = 'alice/other'; User = 'alice'; State = 'WARN' }
        @{ Name = 'team, unlisted identity on its own-named branch'; Users = @('alice', 'bob'); Branch = 'carol/carol-worktree'; User = 'carol'; State = 'WARN' }
        @{ Name = 'team, detached HEAD'; Users = @('alice', 'bob'); Branch = 'DETACHED'; User = 'alice'; State = 'WARN' }
    ) {
        Set-FakeTools $script:GoodTools
        $dir = New-SwProject "branch$(New-Id)" generic
        foreach ($u in $Users) { Add-SwUser $u -Path $dir | Out-Null }
        git -C $dir add -A 2>$null
        git -C $dir commit -q -m init 2>$null
        if ($Branch -eq 'DETACHED') { git -C $dir checkout -q --detach 2>$null } elseif ($Branch -ne 'main') { git -C $dir switch -q -c $Branch 2>$null }
        $out = if ($User) { Test-SwDoctor -Path $dir -User $User | Out-String } else { Test-SwDoctor -Path $dir | Out-String }
        $out | Should -Match "(?m)^current branch\s+$State\b"
        if ($Name -eq 'team, unlisted identity on its own-named branch') { $out | Should -Match '(?m)^user carol\s+MISSING'; $global:LASTEXITCODE | Should -Be 1 }
    }
}

Describe 'Global setup (synthetic home)' {
    # Everything runs against a home under TestDrive. Sentinels make any real tool, auth or installer reach fail.
    BeforeAll {
        Mock -ModuleName Sw.Kit Get-SwGlobalPaths {
            $h = $global:SwTestHome
            [ordered]@{
                Home = $h
                OpenCodeRules = Join-Path $h '.config/opencode/AGENTS.md'
                OpenCodeConfig = Join-Path $h '.config/opencode/opencode.json'
                ClaudeRules = Join-Path $h '.claude/CLAUDE.md'
                ClaudeRtk = Join-Path $h '.claude/RTK.md'
                ClaudeSettings = Join-Path $h '.claude/settings.json'
                HomeAgents = $(if ($global:SwTestHomeAgents) { $global:SwTestHomeAgents } else { Join-Path $h 'AGENTS.md' })
                Backups = Join-Path $h '.sw/backups'
            }
        }
        Mock -ModuleName Sw.Kit Get-SwToolProbe { [pscustomobject]@{ Name = $Name; State = 'ok'; Version = [version]'9.9.9'; ExitCode = 0 } }
        Mock -ModuleName Sw.Kit Get-SwToolVersion { [version]'9.9.9' }
        Mock -ModuleName Sw.Kit Get-SwGhAuth { 0 }
        InModuleScope Sw.Kit { function script:winget { throw 'unexpected winget run' } }
        function New-Home {
            $global:SwTestHome = Join-Path $TestDrive "home$(New-Id)"
            $global:SwTestHomeAgents = $null
            Write-SwFile (Join-Path $global:SwTestHome '.claude/CLAUDE.md') "mine`n"
            Write-SwFile (Join-Path $global:SwTestHome '.claude/settings.json') ('{"permissions":{"allow":["Bash(gh *)","Bash(npm test:*)","Bash(gh *)","Bash(gh:*)"]}}' + "`n")
            Write-SwFile (Join-Path $global:SwTestHome '.config/opencode/AGENTS.md') "opencode mine`n"
            $global:SwTestHome
        }
        function Get-Tree([string]$Dir) {
            if (-not (Test-Path -LiteralPath $Dir)) { return 'absent' }
            (@(Get-ChildItem -LiteralPath $Dir -Recurse -File -Force | Sort-Object FullName | ForEach-Object { "$($_.FullName.Substring($Dir.Length)):$((Get-FileHash $_.FullName).Hash)" }) -join "`n")
        }
    }
    AfterAll {
        InModuleScope Sw.Kit { Remove-Item Function:script:winget -ErrorAction SilentlyContinue }
        Remove-Variable SwTestHome, SwTestHomeAgents -Scope Global -ErrorAction SilentlyContinue
    }

    It 'backs up recognised files into a snapshot under the synthetic home, never the real profile' {
        $h = New-Home
        $b = Backup-SwGlobal
        $b.Path.StartsWith($h) | Should -BeTrue
        $b.Files.Count | Should -Be 3
        Read-SwText (Join-Path $b.Path '.claude/CLAUDE.md') | Should -Be "mine`n"
        $b.Path | Should -Not -Match ([regex]::Escape([Environment]::GetFolderPath('UserProfile')) + '[\\/]\.sw')
    }

    It 'keeps every generation when the clock is fixed' {
        $h = New-Home
        Mock -ModuleName Sw.Project Get-SwUtc { '2000-01-01T000000Z' }
        $first = Backup-SwGlobal
        Write-SwFile (Join-Path $h '.claude/CLAUDE.md') "second generation`n"
        $second = Backup-SwGlobal
        $first.Path | Should -Not -Be $second.Path
        Read-SwText (Join-Path $first.Path '.claude/CLAUDE.md') | Should -Be "mine`n"
        Read-SwText (Join-Path $second.Path '.claude/CLAUDE.md') | Should -Be "second generation`n"
        @(Get-ChildItem (Join-Path $h '.sw/backups') -Directory).Count | Should -Be 2
    }

    It 'rejects an explicit destination that already exists, leaving it untouched' {
        $h = New-Home
        $dest = Join-Path $TestDrive "dest$(New-Id)"
        Write-SwFile (Join-Path $dest 'sentinel.txt') 'keep me'
        $before = Get-Tree $dest
        { Backup-SwGlobal -Destination $dest } | Should -Throw '*already exists*'
        { Backup-SwGlobal -Destination $dest -WhatIf } | Should -Throw '*already exists*'
        Get-Tree $dest | Should -Be $before
        $file = Join-Path $TestDrive "destfile$(New-Id)"
        Write-SwFile $file 'file sentinel'
        { Backup-SwGlobal -Destination $file } | Should -Throw '*already exists*'
        Read-SwText $file | Should -Be 'file sentinel'
        $fresh = Join-Path $TestDrive "fresh$(New-Id)"
        (Backup-SwGlobal -Destination $fresh).Path | Should -Be $fresh
        Test-Path (Join-Path $fresh '.claude/CLAUDE.md') | Should -BeTrue
    }

    It 'rejects a source that escapes the home directory, before copying anything' {
        $h = New-Home
        $outside = Join-Path $TestDrive "outside$(New-Id)"
        Write-SwFile (Join-Path $outside 'AGENTS.md') "outside`n"
        $global:SwTestHomeAgents = Join-Path $outside 'AGENTS.md'
        $before = Get-Tree $h
        { Backup-SwGlobal } | Should -Throw '*outside the home directory*'
        Get-Tree $h | Should -Be $before
    }

    It '-WhatIf creates nothing' {
        $h = New-Home
        $before = Get-Tree $h
        Backup-SwGlobal -WhatIf *> $null
        Install-SwGlobal -Claude -WhatIf *> $null
        Get-Tree $h | Should -Be $before
    }

    It 'a reservation or copy failure (<Failing>) stops install before any global file is replaced' -ForEach @(
        @{ Failing = 'New-SwSnapshotDir' }
        @{ Failing = 'Copy-SwNew' }
    ) {
        $h = New-Home
        $before = Get-Tree $h
        Mock -ModuleName Sw.Kit $Failing { throw 'injected recovery-copy failure' }
        { Install-SwGlobal -Claude } | Should -Throw '*injected recovery-copy failure*'
        Get-Tree $h | Should -Be $before
    }

    It 'install narrows every broad gh allow, keeps the rest, backs up the old settings and is idempotent' {
        $h = New-Home
        Install-SwGlobal -Claude | Out-Null
        $s = Read-SwJson (Join-Path $h '.claude/settings.json')
        $s['permissions']['allow'] | Should -Not -Contain 'Bash(gh *)'
        $s['permissions']['allow'] | Should -Not -Contain 'Bash(gh:*)'
        $s['permissions']['allow'] | Should -Contain 'Bash(npm test:*)'
        $s['permissions']['allow'] | Should -Contain 'Bash(gh issue view:*)'
        $backup = @(Get-ChildItem (Join-Path $h '.sw/backups') -Recurse -Filter settings.json -File)
        $backup.Count | Should -Be 1
        (Read-SwText $backup[0].FullName) | Should -Match 'Bash\(gh \*\)'
        $after = Get-Tree $h
        $again = Get-SwNarrowedGhAllow @($s['permissions']['allow'])
        $again.Changed | Should -BeFalse
    }
}

Describe 'Backup secret filter' {
    It '<Name> -> secret:<Expected>' -ForEach @(
        @{ Name = 'service.json'; Expected = $true }
        @{ Name = '.claude.json'; Expected = $true }
        @{ Name = 'auth.json'; Expected = $true }
        @{ Name = '.env'; Expected = $true }
        @{ Name = 'x.env.local'; Expected = $true }
        @{ Name = 'id.pem'; Expected = $true }
        @{ Name = 'CLAUDE.md'; Expected = $false }
        @{ Name = 'settings.json'; Expected = $false }
        @{ Name = 'opencode.json'; Expected = $false }
        @{ Name = 'AGENTS.md'; Expected = $false }
    ) {
        $matched = InModuleScope Sw.Kit -Parameters @{ Name = $Name } { $Name -match $script:SecretName }
        $matched | Should -Be $Expected
    }
}

Describe 'Generated copies and current guidance' {
    BeforeAll { $script:Render = Get-SwRender (Get-SwConfig $RepoRoot) }

    It 'the tracked generated copies and manifest match what the kit renders for this repository' {
        $manifest = Read-SwJson (Join-Path $RepoRoot '.sw/manifest.json')
        foreach ($rel in '.sw/lib/Sw.Project.psm1', '.sw/onboarding.md', '.sw/workspace.md') {
            Read-SwText (Join-Path $RepoRoot $rel) | Should -Be $script:Render.Files[$rel] -Because $rel
            $manifest['files'][$rel] | Should -Be (Get-SwHash $script:Render.Files[$rel]) -Because "manifest $rel"
        }
    }

    It 'onboarding enters the checkout directory between clone and doctor' {
        $script:Render.Files['.sw/onboarding.md'] | Should -Match '(?m)^git clone <repo-url>
cd <checkout-directory>
pwsh \.sw/sw\.ps1 doctor -User <you>$'
    }

    It 'guidance qualifies static checks and documents ownership, backups and profile transitions' {
        $text = $script:Render.Files['.sw/workspace.md']
        $text | Should -Match 'does not scan for credentials'
        $text | Should -Not -Match 'sw validate` enforces this'
        $text | Should -Match 'reports PARTIAL \(blocked\)'
        $text | Should -Match '(?m)^## Backups and profile changes$'
        $text | Should -Match 'contents are never scanned'
        $text | Should -Match 'refused while the managed `\.gitattributes` block carries'
    }
}

Describe 'Shipped skill staleness' {
    It 'no shipped SKILL.md has an Observed YYYY-MM line outside an Old observations section' {
        $hits = foreach ($f in Get-ChildItem (Join-Path $RepoRoot 'project') -Recurse -Filter SKILL.md -File -Force) {
            $old = $false; $n = 0
            foreach ($line in (Read-SwText $f.FullName) -split "`n") {
                $n++
                if ($line -match '^#+ ') { $old = $line -match '(?i)old observations' }
                elseif (-not $old -and $line -match '(?i)\bobserved \d{4}-\d{2}') { "$($f.FullName):$n" }
            }
        }
        $hits | Should -BeNullOrEmpty
    }
}

Describe 'Portable source leak guard' {
    It 'ships no personal names or paths' {
        # CHANGELOG is dated history, so it may name the projects the kit came from.
        $sourcePaths = @('sw.ps1', 'VERSION', 'lib', 'project', 'global') | ForEach-Object { Join-Path $RepoRoot $_ }
        $hits = Get-ChildItem -LiteralPath $sourcePaths -Recurse -File -Force |
            Where-Object Name -ne 'CHANGELOG.md' |
            Select-String -Pattern 'BiscuitDoesStuff|crank|MyMMO|C:\Dev'
        $hits | ForEach-Object { "$($_.Path):$($_.LineNumber)" } | Should -BeNullOrEmpty
    }
}

Describe 'Context and recovery reporting' {
    BeforeAll {
        function Get-TreeHash([string]$Dir) {
            (Get-ChildItem -LiteralPath $Dir -Recurse -File -Force | Sort-Object FullName | ForEach-Object { "$($_.FullName)|$((Get-FileHash -LiteralPath $_.FullName).Hash)" }) -join "`n"
        }
        function New-ContextProject {
            $dir = New-SwProject "ctx$(New-Id)" generic
            Write-SwFile (Join-Path $dir 'docs/state.md') "# State`n`n## Startup`n`nCurrent scope.`n`n## History`n`nOLD-APPROVAL-SENTINEL`n"
            $dir
        }
    }

    It 'shared budget arithmetic matches known byte fixtures, the leader catalogue and the default or configured cap' {
        $agents = @{ 'project-leader' = @{ description = 'd1'; __body = 'xx' }; 'project-developer' = @{ description = 'dd2'; __body = ([string][char]0xE9) } }
        $skills = @{ sk = @{ description = 'zz' } }
        $rows = @(Get-SwStartupBudget @{} 'abc' $agents $skills @('project-leader', 'project-developer', 'absent-role'))
        $rows.Role | Should -Be @('project-leader', 'project-developer')
        $rows[0].Total | Should -Be (3 + 2 + 4 + 3)
        $rows[0].Catalogue | Should -Be 3
        $rows[1].Total | Should -Be (3 + 2 + 4)
        $rows[1].Catalogue | Should -Be 0
        $rows[0].Tokens | Should -Be 3
        $rows[0].Cap | Should -Be 12100
        (Get-SwStartupBudget @{ startupBudgetBytes = 10 } 'abc' $agents $skills @('project-leader'))[0].Cap | Should -Be 10
    }

    It 'reports the same per-role totals and cap as validate, and a lowered cap still fails validate only' {
        $dir = New-ContextProject
        $validate = @(Test-SwProject -Path $dir | Where-Object { $_ -like 'Startup budget:*' } | ForEach-Object { $_ -replace '^Startup budget: (\S+) = (\d+) bytes.*cap (\d+)$', '$1 $2 $3' })
        $context = @(Get-SwContext -Path $dir | Where-Object { $_ -match '^project-\S+: agents_md=' } | ForEach-Object { $_ -replace '^(\S+): .* total=(\d+) .* cap=(\d+) .*$', '$1 $2 $3' })
        $validate.Count | Should -BeGreaterThan 0
        @($context | Sort-Object) | Should -Be @($validate | Sort-Object)
        $config = Get-SwConfig $dir; $config['startupBudgetBytes'] = 100
        Write-SwFile (Join-Path $dir '.sw/config.json') (ConvertTo-SwJson $config)
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 1
        ($result.Output -join "`n") | Should -Match 'Startup budget exceeded for project-leader: \d+ > 100 bytes'
        $out = @(Get-SwContext -Path $dir)
        $global:LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'cap=100 within_cap=no'
    }

    It 'is deterministic for unchanged inputs and writes nothing, including Git metadata' {
        $dir = New-ContextProject
        git -C $dir add -A 2>$null; git -C $dir commit -qm init 2>$null
        Invoke-SwComms event -Task t1 -From tester -Path $dir | Out-Null
        $before = Get-TreeHash $dir
        $a = @(Get-SwContext -Path $dir -Task t1 -StateFile docs/state.md)
        $b = @(Get-SwContext -Path $dir -Task t1 -StateFile docs/state.md)
        ($a -join "`n") | Should -Be ($b -join "`n")
        Get-TreeHash $dir | Should -Be $before
        ($a -join "`n") | Should -Match 'checkout: branch=\S+ head=[0-9a-f]{40} dirty_entries=\d+'
    }

    It 'rejects unsafe task identifiers and state paths before reading' {
        $dir = New-ContextProject
        $outside = Join-Path $TestDrive "outside$(New-Id).md"; Write-SwFile $outside "## Startup`nx`n"
        foreach ($bad in @($outside, '../x.md', 'docs/../../x.md', '\\server\share\x.md', '/x.md', 'C:x.md', 'docs/state.md:alt.md', 'docs/state.txt')) {
            { Get-SwContext -Path $dir -StateFile $bad } | Should -Throw -Because $bad
        }
        foreach ($bad in '..', '../t', 't/x', 'a b') { { Get-SwContext -Path $dir -Task $bad } | Should -Throw -Because $bad }
        { Get-SwContext -Path $dir -StateSection Startup } | Should -Throw '*needs -StateFile*'
        { Get-SwContext -Path $dir -StateFile docs/state.md -StateSection "a`nb" } | Should -Throw
        $target = Join-Path $TestDrive "linked$(New-Id)"; New-Item -ItemType Directory $target | Out-Null
        Write-SwFile (Join-Path $target 'state.md') "## Startup`nlinked`n"
        New-Item -ItemType $(if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }) -Path (Join-Path $dir 'linked') -Target $target | Out-Null
        { Get-SwContext -Path $dir -StateFile linked/state.md } | Should -Throw '*link or junction*'
    }

    It 'reports missing state, sections, tasks and Git as unavailable, and finds an archive summary' {
        $dir = New-ContextProject
        $text = (Get-SwContext -Path $dir) -join "`n"
        $text | Should -Match 'state: unavailable \(state source not specified'
        $text | Should -Match 'head=unavailable'
        (Get-SwContext -Path $dir -StateFile docs/none.md) -join "`n" | Should -Match 'state: unavailable \(missing: docs/none.md\)'
        (Get-SwContext -Path $dir -StateFile docs/state.md -StateSection Absent) -join "`n" | Should -Match 'section "Absent" not found'
        $text = (Get-SwContext -Path $dir -StateFile docs/state.md) -join "`n"
        $text | Should -Match 'state: docs/state.md section "Startup" bytes=17 '
        $text | Should -Not -Match 'OLD-APPROVAL-SENTINEL'
        $text = (Get-SwContext -Path $dir -Task gone) -join "`n"
        $text | Should -Match 'task: gone unavailable \(missing: \.sw/comms/tasks/gone\)'
        $text | Should -Match 'archive: none'
        Write-SwFile (Join-Path $dir '.sw/comms/archive/gone/SUMMARY.md') "# gone - summary`n"
        (Get-SwContext -Path $dir -Task gone) -join "`n" | Should -Match 'archive: \.sw/comms/archive/gone/SUMMARY\.md bytes=\d+ \(summary only'
        Remove-Item -LiteralPath (Join-Path $dir '.git') -Recurse -Force
        (Get-SwContext -Path $dir) -join "`n" | Should -Match 'checkout: unavailable'
        Write-SwFile (Join-Path $dir '.opencode/agents/project-leader.md') "not frontmatter`n"
        $text = (Get-SwContext -Path $dir) -join "`n"
        $global:LASTEXITCODE | Should -Be 0
        $text | Should -Match 'core: incomplete \(\.opencode/agents/project-leader\.md failed\)'
    }

    It 'lists bounded opaque event references without bodies, approval or active-task selection' {
        $dir = New-ContextProject
        $taskDir = Join-Path $dir '.sw/comms/tasks/many'
        foreach ($i in 1..25) { Write-SwFile (Join-Path $taskDir ('2026-01-01T0000{0:d2}Z-owner-approval.md' -f $i)) "APPROVED BODY-SENTINEL $i`n" }
        Write-SwFile (Join-Path $taskDir 'notes.txt') 'x'
        Write-SwFile (Join-Path $dir '.sw/comms/tasks/other/2026-01-02T000000Z-owner-approval.md') "approved`n"
        $text = (Get-SwContext -Path $dir -Task many) -join "`n"
        $text | Should -Match 'task: many events=25 listed=20 omitted=5 other_entries=1'
        @([regex]::Matches($text, '(?m)^event: ')).Count | Should -Be 20
        $text | Should -Match 'event: \.sw/comms/tasks/many/2026-01-01T000025Z-owner-approval\.md'
        $text | Should -Not -Match '2026-01-01T000005Z'
        $text | Should -Not -Match 'BODY-SENTINEL'
        $text | Should -Not -Match 'tasks/other'
        $text = (Get-SwContext -Path $dir) -join "`n"
        $text | Should -Match 'tasks: candidates=2 listed=2 omitted=0 \(candidates only'
        $text | Should -Match 'candidate: many events=25'
        $text | Should -Not -Match '(?im)^(active|approved)'
        $text | Should -Match 'not an approval or acceptance verdict'
    }

    It 'keeps runtime/global context unobserved and prints skill metadata, not bodies' {
        $dir = New-ContextProject
        $skill = Get-ChildItem -LiteralPath (Join-Path $dir '.agents/skills') -Recurse -Filter SKILL.md -File | Select-Object -First 1
        Write-SwFile $skill.FullName ((Read-SwText $skill.FullName) + "SKILL-BODY-SENTINEL`n")
        $text = (Get-SwContext -Path $dir) -join "`n"
        $text | Should -Not -Match 'SKILL-BODY-SENTINEL'
        $text | Should -Match "skill: $($skill.Directory.Name) bytes=\d+"
        $text | Should -Match '== Runtime, harness and global context: NOT OBSERVED'
        $text | Should -Match 'bytes/4\) estimate, not a tokenizer result'
    }

    It 'project CLI exposes context with explicit exits; a manager-only installation does not' {
        $dir = New-ContextProject
        $cli = Join-Path $dir '.sw/sw.ps1'
        & pwsh -NoProfile -File $cli context -StateFile docs/state.md | Out-Null
        $LASTEXITCODE | Should -Be 0
        & pwsh -NoProfile -File $cli context -StateFile ../x.md 2>&1 | Out-Null
        $LASTEXITCODE | Should -Not -Be 0
        (& pwsh -NoProfile -File $cli help) -join "`n" | Should -Match '(?m)^  context '
        $manager = Join-Path $TestDrive "mgr$(New-Id)"
        New-Item -ItemType Directory (Join-Path $manager '.sw/lib') -Force | Out-Null
        Copy-Item (Join-Path $RepoRoot 'sw.ps1') (Join-Path $manager '.sw/sw.ps1')
        Copy-Item (Join-Path $RepoRoot 'lib/Sw.Project.psm1') (Join-Path $manager '.sw/lib/Sw.Project.psm1')
        Write-SwFile (Join-Path $manager '.sw/manager-manifest.json') "{}`n"
        $help = (& pwsh -NoProfile -File (Join-Path $manager '.sw/sw.ps1') help) -join "`n"
        $help | Should -Not -Match '(?m)^  context '
        $help | Should -Match '(?m)^  validate '
        $out = (& pwsh -NoProfile -File (Join-Path $manager '.sw/sw.ps1') context) -join "`n"
        $LASTEXITCODE | Should -Be 2
        $out | Should -Match 'Unknown command: context'
    }

    It 'status, resume and handoff carry the recovery card and keep exits, effects and approval separate' {
        $render = Get-SwRender (Get-SwConfig $RepoRoot)
        $status = $render.Files['.opencode/commands/status.md']
        foreach ($field in 'Task / objective:', 'Applicable approval / allowed scope / source:', 'Owner / dependencies / conflicts:', 'Artifacts / checked revision / dirty scope:', 'Last verified checkpoint / evidence:', 'Process outcome: observed exit | missing/unknown', 'Effects: confirmed occurred | confirmed did not occur | unknown', 'Outstanding checks / missing evidence:', 'One permitted next action / responsible owner:') {
            $status | Should -Match ([regex]::Escape($field))
        }
        $status | Should -Match 'missing exit is unknown, not success or\s+failure'
        $status | Should -Match 'not approval'
        $resume = $render.Files['.opencode/commands/resume.md']
        $resume | Should -Match 'never\s+retry an operation with unknown effects'
        $resume | Should -Match 'superseded approval is never approval'
        $render.Files['.opencode/commands/handoff.md'] | Should -Match 'not native\s+delivery, acknowledgment or approval'
    }

    Context 'C1 correction: scoped reads, completeness, Git and stability' {
        BeforeAll {
            function New-Link([string]$Path, [string]$Target, [string]$Type = $(if ($IsWindows) { 'Junction' } else { 'SymbolicLink' })) {
                New-Item -ItemType $Type -Path $Path -Target $Target -ErrorAction Stop | Out-Null
            }
            function New-Outside {
                $out = Join-Path $TestDrive "outside$(New-Id)"
                Write-SwFile (Join-Path $out 'agents/project-leader.md') "---`ndescription: OUTSIDE-SENTINEL`nmode: primary`n---`nOUTSIDE-SENTINEL body`n"
                Write-SwFile (Join-Path $out 'skill/SKILL.md') "---`nname: linked`ndescription: OUTSIDE-SENTINEL`n---`nOUTSIDE-SENTINEL`n"
                Write-SwFile (Join-Path $out 'plugin/x.js') "// OUTSIDE-SENTINEL`n"
                Write-SwFile (Join-Path $out 'commands/x.md') "---`ndescription: OUTSIDE-SENTINEL`n---`n"
                Write-SwFile (Join-Path $out 'archive/SUMMARY.md') "OUTSIDE-SENTINEL`n"
                Write-SwFile (Join-Path $out 'policy.md') "OUTSIDE-SENTINEL`n"
                $out
            }
            function Start-ReadSpy {
                # Pass-through spies on every read/enumeration primitive the report uses; records each path touched.
                $global:SwCtxTouched = [Collections.Generic.List[string]]::new()
                $global:SwCtxFrontmatter = & (Get-Module Sw.Project) { ${function:Read-SwFrontmatter} }
                Mock -ModuleName Sw.Project Read-SwText { $global:SwCtxTouched.Add($Path); [IO.File]::ReadAllText($Path).Replace("`r`n", "`n") }
                Mock -ModuleName Sw.Project Read-SwFrontmatter { $global:SwCtxTouched.Add($Path); & $global:SwCtxFrontmatter $Path $Allowed }
                Mock -ModuleName Sw.Project Get-ChildItem { $global:SwCtxTouched.Add($LiteralPath); Microsoft.PowerShell.Management\Get-ChildItem -LiteralPath $LiteralPath -Force }
                Mock -ModuleName Sw.Project Get-Item { $global:SwCtxTouched.Add($LiteralPath); Microsoft.PowerShell.Management\Get-Item -LiteralPath $LiteralPath -Force }
            }
            function Get-InsideLink([string[]]$Links) {
                # Touched paths at or below any link (entering or reading through it); the link's own attributes are not a read.
                $sep = [IO.Path]::DirectorySeparatorChar
                @($global:SwCtxTouched | Where-Object { $p = [IO.Path]::GetFullPath($_); @($Links | Where-Object { $p -eq $_ -or $p.StartsWith($_ + $sep, [StringComparison]::OrdinalIgnoreCase) }).Count })
            }
        }
        AfterEach { Remove-Variable SwCtxTouched, SwCtxFrontmatter -Scope Global -ErrorAction Ignore }

        It 'never reads or enters linked directories in definitions, skills, plugins, commands, tasks or archive' {
            $dir = New-ContextProject; $out = New-Outside
            $agentsDir = Join-Path $dir '.opencode/agents'
            Move-Item -LiteralPath $agentsDir -Destination (Join-Path $out 'real-agents')
            $links = @(
                @($agentsDir, (Join-Path $out 'real-agents')),
                @((Join-Path $dir '.agents/skills/linked'), (Join-Path $out 'skill')),
                @((Join-Path $dir '.opencode/plugins/linked'), (Join-Path $out 'plugin')),
                @((Join-Path $dir '.opencode/commands'), (Join-Path $out 'commands')),
                @((Join-Path $dir '.sw/comms/tasks/linked'), (Join-Path $out 'agents')),
                @((Join-Path $dir '.sw/comms/archive/t1'), (Join-Path $out 'archive')))
            New-Item -ItemType Directory (Join-Path $dir '.opencode/plugins'), (Join-Path $dir '.sw/comms/tasks/t1'), (Join-Path $dir '.sw/comms/archive') -Force | Out-Null
            Remove-Item -LiteralPath (Join-Path $dir '.opencode/commands') -Recurse -Force
            foreach ($l in $links) { New-Link $l[0] $l[1] }
            Start-ReadSpy
            $text = (Get-SwContext -Path $dir -Task t1) -join "`n"
            $global:LASTEXITCODE | Should -Be 0
            $text | Should -Not -Match 'OUTSIDE-SENTINEL'
            $text | Should -Match 'core: incomplete \([^)]*\.opencode/agents unsafe'
            $text | Should -Not -Match '(?m)^project-\S+: agents_md='
            $text | Should -Match 'skills: incomplete \(1 entries not followed'
            $text | Should -Not -Match 'skill: linked'
            $text | Should -Match 'plugins: count=\d+ bytes=\d+ incomplete \(1 entries'
            $text | Should -Match 'commands: unavailable \(unsafe: \.opencode/commands\)'
            $text | Should -Match 'archive: unavailable \(unsafe: \.sw/comms/archive/t1/SUMMARY\.md\)'
            $text = (Get-SwContext -Path $dir) -join "`n"
            $text | Should -Match 'candidate: linked \(link; not inspected\)'
            $global:SwCtxTouched.Count | Should -BeGreaterThan 0
            Get-InsideLink @($links | ForEach-Object { [IO.Path]::GetFullPath($_[0]) }) | Should -BeNullOrEmpty
            { Get-SwContext -Path $dir -Task linked } | Should -Throw '*link or junction*'
        }

        It 'rejects a project root reached through a directory junction before reading through it' {
            $dir = New-ContextProject
            $alias = Join-Path $TestDrive "alias$(New-Id)"
            New-Link $alias $dir
            Start-ReadSpy
            { Get-SwContext -Path $alias } | Should -Throw '*link or junction*'
            Get-InsideLink @([IO.Path]::GetFullPath($alias)) | Should -BeNullOrEmpty
            (InModuleScope Sw.Project -Parameters @{ Alias = $alias } { param($Alias) Invoke-SwContextRead $Alias 'AGENTS.md' { param($f) Read-SwText $f } }).Status | Should -Be 'unsafe'
            Get-InsideLink @([IO.Path]::GetFullPath($alias)) | Should -BeNullOrEmpty
            (Get-SwContext -Path $dir) -join "`n" | Should -Match '(?m)^project-leader: agents_md='
        }

        It 'never reads linked definition, policy or state files (needs file-symlink privilege)' {
            $dir = New-ContextProject; $out = New-Outside
            $files = @('.opencode/agents/project-review.md', '.sw/workspace.md', 'docs/linked.md')
            try {
                foreach ($f in $files) { $p = Join-Path $dir $f; Remove-Item -LiteralPath $p -Force -ErrorAction Ignore; New-Link $p (Join-Path $out 'policy.md') 'SymbolicLink' }
            } catch { Set-ItResult -Skipped -Because "file symbolic links unavailable here: $($_.Exception.Message)"; return }
            Start-ReadSpy
            $text = (Get-SwContext -Path $dir) -join "`n"
            $text | Should -Not -Match 'OUTSIDE-SENTINEL'
            $text | Should -Match 'core: incomplete \([^)]*project-review\.md unsafe'
            $text | Should -Match 'policy: \.sw/workspace\.md unavailable \(unsafe\)'
            Get-InsideLink @($files | ForEach-Object { [IO.Path]::GetFullPath((Join-Path $dir $_)) }) | Should -BeNullOrEmpty
            { Get-SwContext -Path $dir -StateFile docs/linked.md } | Should -Throw '*link or junction*'
        }

        It 'distinguishes missing sources and role definitions from genuinely empty directories' {
            $dir = New-ContextProject
            foreach ($d in '.opencode/commands', '.opencode/plugins', '.sw/comms/tasks') { Remove-Item -LiteralPath (Join-Path $dir $d) -Recurse -Force -ErrorAction Ignore }
            $text = (Get-SwContext -Path $dir) -join "`n"
            $text | Should -Match 'commands: unavailable \(missing: \.opencode/commands\)'
            $text | Should -Match 'plugins: unavailable \(missing: \.opencode/plugins\)'
            $text | Should -Match 'tasks: unavailable \(missing: \.sw/comms/tasks\)'
            $text | Should -Not -Match 'count=0'
            foreach ($d in '.opencode/commands', '.opencode/plugins', '.sw/comms/tasks') { New-Item -ItemType Directory (Join-Path $dir $d) -Force | Out-Null }
            $text = (Get-SwContext -Path $dir) -join "`n"
            $text | Should -Match 'commands: count=0 bytes=0(?! incomplete)'
            $text | Should -Match 'plugins: count=0 bytes=0(?! incomplete)'
            $text | Should -Match 'tasks: candidates=0 listed=0 omitted=0'
            $text | Should -Match '(?m)^project-leader: agents_md='
            Remove-Item -LiteralPath (Join-Path $dir '.opencode/agents/project-review.md')
            $text = (Get-SwContext -Path $dir) -join "`n"
            $global:LASTEXITCODE | Should -Be 0
            $text | Should -Match 'core: incomplete \(\.opencode/agents/project-review\.md missing\); per-role totals withheld'
            $text | Should -Not -Match '(?m)^project-\S+: agents_md='
            (Test-SwValidate $dir).ExitCode | Should -Be 1
        }

        It 'turns denied, failing or vanishing reads, listings and stamps into an incomplete report that exits zero' {
            $dir = New-ContextProject
            Invoke-SwComms event -Task t1 -From tester -Path $dir | Out-Null
            Mock -ModuleName Sw.Project Read-SwText { throw [UnauthorizedAccessException]::new('denied PRIVATE-VALUE') } -ParameterFilter { $Path -like '*workspace.md' }
            Mock -ModuleName Sw.Project Read-SwFrontmatter { throw 'Unsupported frontmatter at line 2: PRIVATE-VALUE' } -ParameterFilter { $Path -like '*project-developer.md' }
            Mock -ModuleName Sw.Project Get-ChildItem { throw [IO.DirectoryNotFoundException]::new('vanished') } -ParameterFilter { $LiteralPath -like '*commands' -or $LiteralPath -like '*tasks*t1' }
            Mock -ModuleName Sw.Project Get-Item { throw [UnauthorizedAccessException]::new('denied') }
            $out = @(Get-SwContext -Path $dir -Task t1 -StateFile docs/state.md)
            $global:LASTEXITCODE | Should -Be 0
            $text = $out -join "`n"
            $text | Should -Match 'policy: \.sw/workspace\.md unavailable \(failed\)'
            $text | Should -Match 'core: incomplete \(\.opencode/agents/project-developer\.md failed\)'
            $text | Should -Match 'commands: unavailable \(failed: \.opencode/commands\)'
            $text | Should -Match 'task: t1 unavailable \(failed: \.sw/comms/tasks/t1\)'
            $text | Should -Match 'notice: evidence changed during inspection or could not be re-checked; this report is incomplete'
            $text | Should -Match 'state: docs/state\.md section "Startup" bytes=17 '
            $text | Should -Not -Match 'PRIVATE-VALUE'
            { Get-SwContext -Path $dir -StateFile ../x.md } | Should -Throw
        }

        It 'implicit discovery falls back to the current directory when Git is denied or missing; Git is not retried' {
            $dir = New-ContextProject
            $saved = $env:SW_ROOT; Remove-Item Env:SW_ROOT -ErrorAction Ignore
            Push-Location -LiteralPath $dir
            try {
                Mock -ModuleName Sw.Project git { throw [ComponentModel.Win32Exception]::new(5, 'Access is denied') }
                $text = (Get-SwContext) -join "`n"
                $global:LASTEXITCODE | Should -Be 0
                $text | Should -Match '(?m)^project-leader: agents_md='
                $text | Should -Match 'checkout: unavailable \(git could not be run; not retried\)'
                Should -Invoke git -ModuleName Sw.Project -Times 1 -Exactly
                # The installed CLI sets SW_ROOT itself; the real missing-Git child imports the module to exercise implicit discovery.
                $pwshExe = (Get-Process -Id $PID).Path
                $script = "Remove-Item Env:SW_ROOT -ErrorAction Ignore; `$env:PATH = '$PSHOME'; if (Get-Command git -ErrorAction Ignore) { 'git still on PATH'; exit 9 }; Import-Module ./.sw/lib/Sw.Project.psm1 -DisableNameChecking; Get-SwContext; exit `$LASTEXITCODE"
                $child = (& $pwshExe -NoProfile -Command $script) -join "`n"
                $LASTEXITCODE | Should -Be 0
                $child | Should -Match '(?m)^project-leader: agents_md='
                $child | Should -Match 'checkout: unavailable \(git could not be run; not retried\)'
            } finally { Pop-Location; if ($null -ne $saved) { $env:SW_ROOT = $saved } }
            { Get-SwContext -Path (Join-Path $TestDrive "missing$(New-Id)") } | Should -Throw
        }

        It 'reports a controlled concurrent change or disappearance as incomplete' {
            $dir = New-ContextProject
            Invoke-SwComms event -Task t1 -From tester -Path $dir | Out-Null
            $global:SwCtxTaskDir = Join-Path $dir '.sw/comms/tasks/t1'
            try {
                # The fixture actor runs inside the mocked git call, mid-report; it is not a report side effect.
                Mock -ModuleName Sw.Project git { Write-SwFile (Join-Path $global:SwCtxTaskDir "2026-01-01T00000$(Get-Random -Maximum 9)Z-actor-added.md") "x`n" }
                $text = (Get-SwContext -Path $dir -Task t1) -join "`n"
                $text | Should -Match 'notice: evidence changed during inspection'
                Should -Invoke git -ModuleName Sw.Project -Exactly -Times 3
                Mock -ModuleName Sw.Project git { Remove-Item -LiteralPath $global:SwCtxTaskDir -Recurse -Force -ErrorAction Ignore }
                $text = (Get-SwContext -Path $dir -Task t1) -join "`n"
                $global:LASTEXITCODE | Should -Be 0
                $text | Should -Match 'task: t1 unavailable \(missing: \.sw/comms/tasks/t1\)'
                $text | Should -Match 'notice: evidence changed during inspection'
            } finally { Remove-Variable SwCtxTaskDir -Scope Global -ErrorAction Ignore }
        }

        It 'gives identical output for unchanged input in two fresh PowerShell processes' {
            $dir = New-ContextProject
            Invoke-SwComms event -Task t1 -From tester -Path $dir | Out-Null
            foreach ($n in 'c3', 'B2', 'a1') { New-Item -ItemType Directory (Join-Path $dir ".sw/comms/tasks/$n") -Force | Out-Null }
            $pwshExe = (Get-Process -Id $PID).Path
            $cli = Join-Path $dir '.sw/sw.ps1'
            $a = (& $pwshExe -NoProfile -File $cli context -Task t1 -StateFile docs/state.md) -join "`n"; $exitA = $LASTEXITCODE
            $b = (& $pwshExe -NoProfile -File $cli context -Task t1 -StateFile docs/state.md) -join "`n"; $exitB = $LASTEXITCODE
            $exitA, $exitB | Should -Be @(0, 0)
            $a | Should -Be $b
            $a | Should -Match '(?m)^project-leader: agents_md='
            $c = (& $pwshExe -NoProfile -File $cli context) -join "`n"
            [regex]::Matches($c, '(?m)^candidate: (\S+)').ForEach({ $_.Groups[1].Value }) | Should -Be @('B2', 'a1', 'c3', 't1')
        }

        It 'does not run a configured fsmonitor hook or change index bytes' {
            $dir = New-ContextProject
            git -C $dir add -A 2>$null; git -C $dir commit -qm init 2>$null
            $marker = Join-Path $TestDrive "fsmonitor$(New-Id).log"
            $hook = Join-Path $TestDrive "fsmonitor$(New-Id).sh"
            [IO.File]::WriteAllText($hook, "#!/bin/sh`necho invoked >> '$($marker.Replace('\', '/'))'`nexit 1`n")
            git -C $dir config core.fsmonitor $hook.Replace('\', '/')
            git -C $dir status 2>$null | Out-Null
            Test-Path -LiteralPath $marker | Should -BeTrue -Because 'positive control: plain status runs the fixture hook'
            Remove-Item -LiteralPath $marker
            $index = Join-Path $dir '.git/index'
            $before = (Get-FileHash -LiteralPath $index).Hash
            $text = (Get-SwContext -Path $dir) -join "`n"
            $text | Should -Match 'checkout: branch=\S+ head=[0-9a-f]{40} dirty_entries=\d+'
            Test-Path -LiteralPath $marker | Should -BeFalse
            (Get-FileHash -LiteralPath $index).Hash | Should -Be $before
        }
    }
}

Describe 'Profile selection v1' {
    BeforeAll {
        function New-SelProject {
            param([string]$Name, [string]$Profile = 'generic', [string[]]$Capabilities)
            $dir = Join-Path $TestDrive $Name
            $extra = if ($PSBoundParameters.ContainsKey('Capabilities')) { @{ Capabilities = $Capabilities } } else { @{} }
            Initialize-SwProject -Path $dir -Profile $Profile -Name $Name @extra | Out-Null
            git -C $dir config user.name tester
            git -C $dir config user.email tester@example.com
            $dir
        }
        function Get-Tree([string]$Root) {
            # Every file's bytes (including .git and .claude): proof that a refused or WhatIf run wrote nothing.
            $map = [ordered]@{}
            foreach ($f in Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Sort-Object FullName) { $map[[IO.Path]::GetRelativePath($Root, $f.FullName)] = Get-SwByteHash ([IO.File]::ReadAllBytes($f.FullName)) }
            $map | ConvertTo-Json -Compress
        }
        function Get-SkillNames([string]$Root) { @(Get-ChildItem -LiteralPath (Join-Path $Root '.agents/skills') -Directory -Force | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') } | ForEach-Object Name | Sort-Object) }
        function Get-Effective([string]$Root) { (Read-SwJson (Join-Path $Root '.sw/profile.json'))['effectiveSelection'] }
        function Set-Selection([string]$Root, [string]$Profile) {
            $c = Get-SwConfig $Root; $c['profile'] = $Profile; Write-SwFile (Join-Path $Root '.sw/config.json') (ConvertTo-SwJson $c)
        }
        function New-KitCopy([string]$Name) {
            # Isolated kit for source-corruption cases; the live source tree is never rewritten.
            $kit = Join-Path $TestDrive $Name
            New-Item -ItemType Directory -Path $kit | Out-Null
            foreach ($p in 'lib', 'project', 'sw.ps1', 'VERSION') { Copy-Item -LiteralPath (Join-Path $RepoRoot $p) -Destination (Join-Path $kit $p) -Recurse }
            $kit
        }
        function Use-Kit([string]$Kit, [scriptblock]$Action) {
            $saved = InModuleScope Sw.Kit { $script:Kit }
            InModuleScope Sw.Kit -Parameters @{ K = $Kit } { param($K) $script:Kit = $K }
            try { & $Action } finally { InModuleScope Sw.Kit -Parameters @{ K = $saved } { param($K) $script:Kit = $K } }
        }
        function Get-V1Config([string]$Profile = 'generic', [string[]]$Capabilities = @()) {
            [ordered]@{ project = 'P'; profile = $Profile; githubTier = 0; github = $true; startupBudgetBytes = 12100; users = @(); selection = [ordered]@{ version = 1; capabilities = @($Capabilities) } }
        }
        $script:Generic = @('agent-documentation', 'focused-review', 'minimal-change', 'project-planning', 'structured-debugging', 'task-handoff')
    }

    Context 'A1 fresh generic default' {
        It 'installs exactly the resolved roles, six kit skills and their commands; no research or provider setup' {
            $dir = New-SelProject "a1$(New-Id)"
            (Get-SwConfig $dir)['selection']['version'] | Should -Be 1
            @((Read-SwJson (Join-Path $dir '.sw/roles.json')).Keys | Sort-Object) | Should -Be @('explore', 'project-developer', 'project-leader', 'project-review')
            Get-SkillNames $dir | Should -Be $script:Generic
            @(Get-ChildItem (Join-Path $dir '.opencode/commands') -Filter *.md | ForEach-Object BaseName | Sort-Object) | Should -Be @('handoff', 'inbox', 'resume', 'review', 'status', 'validate', 'work', 'workspace-check')
            Test-Path (Join-Path $dir '.opencode/agents/project-research.md') | Should -BeFalse
            Read-SwText (Join-Path $dir 'AGENTS.md') | Should -Not -Match 'Capability: research'
            $sel = Get-Effective $dir
            @($sel['checks']) | Should -Not -Contain 'research-evidence'
            @($sel['context']) | Should -Be @('core', 'generic')
            Read-SwText (Join-Path $dir '.opencode/agents/project-leader.md') | Should -Not -Match 'project-research'
            Read-SwText (Join-Path $dir '.sw/workspace.md') | Should -Not -Match '(?m)^\| project-research '
            (Test-SwValidate $dir).ExitCode | Should -Be 0
        }

        It 'repeated render, sync and update are deterministic and idempotent' {
            $dir = New-SelProject "a1r$(New-Id)"
            $c = Get-SwConfig $dir
            ((Get-SwRender $c).Files | ConvertTo-Json -Depth 3) | Should -Be ((Get-SwRender $c).Files | ConvertTo-Json -Depth 3)
            $tree = Get-Tree $dir
            @(Sync-SwProject -Root $dir -Config (Get-SwConfig $dir) | Where-Object Action -ne 'same').Count | Should -Be 0
            Update-SwProject -Path $dir | Out-Null
            Get-Tree $dir | Should -Be $tree
        }
    }

    Context 'A2 research preset and capability' {
        It 'the research preset and generic + research add exactly the researcher, skill, command, guidance and checks' {
            $base = Get-SwRender (Get-V1Config)
            foreach ($cfg in (Get-V1Config research), (Get-V1Config generic @('research'))) {
                $r = Get-SwRender $cfg
                @($r.Files.Keys | Where-Object { -not $base.Files.Contains($_) } | Sort-Object) | Should -Be @('.agents/skills/research/SKILL.md', '.opencode/agents/project-research.md', '.opencode/commands/research.md')
                @($base.Files.Keys | Where-Object { -not $r.Files.Contains($_) }).Count | Should -Be 0
                @($r.Selection.checks) | Should -Contain 'research-evidence'
                @($r.Selection.context) | Should -Contain 'research'
                @($r.Selection.capabilities) | Should -Be @('research')
                ([regex]::Matches($r.AgentsProfile, '## Capability: research')).Count | Should -Be 1
                $r.AgentsProfile | Should -Match 'Availability is not approval to\s+collect'
                $r.Files['.opencode/agents/project-leader.md'] | Should -Match '(?m)^- project-research:'
            }
            # Naming the preset's own capability again duplicates nothing.
            ((Get-SwRender (Get-V1Config research @('research'))).Files | ConvertTo-Json -Depth 3) | Should -Be ((Get-SwRender (Get-V1Config research)).Files | ConvertTo-Json -Depth 3)
        }

        It 'a research-preset install validates and keeps research guidance short and request-scoped' {
            $dir = New-SelProject "a2$(New-Id)" research
            (Test-SwValidate $dir).ExitCode | Should -Be 0
            $agents = Read-SwText (Join-Path $dir 'AGENTS.md')
            $agents | Should -Match '## Profile: research'
            $agents | Should -Match 'does not authorize implementation'
        }
    }

    Context 'A3 provider-setup capability' {
        It 'adds only free-models; no adapter, model map, provider, plugin, MCP or permission change' {
            $base = Get-SwRender (Get-V1Config)
            $r = Get-SwRender (Get-V1Config generic @('provider-setup'))
            @($r.Files.Keys | Where-Object { -not $base.Files.Contains($_) }) | Should -Be @('.agents/skills/free-models/SKILL.md')
            foreach ($k in $base.Files.Keys | Where-Object { $_ -ne '.sw/profile.json' }) { $r.Files[$k] | Should -Be $base.Files[$k] -Because $k }
            $r.AgentsProfile | Should -Be $base.AgentsProfile
            $dir = New-SelProject "a3$(New-Id)" generic @('provider-setup')
            foreach ($p in '.claude', '.opencode/opencode.jsonc', '.opencode/opencode.json') { Test-Path (Join-Path $dir $p) | Should -BeFalse }
            (Test-SwValidate $dir).ExitCode | Should -Be 0
        }

        It 'both capabilities combine deterministically in any order' {
            $a = Get-SwRender (Get-V1Config generic @('research', 'provider-setup'))
            $b = Get-SwRender (Get-V1Config generic @('provider-setup', 'research'))
            ($a.Files | ConvertTo-Json -Depth 3) | Should -Be ($b.Files | ConvertTo-Json -Depth 3)
            @($a.Selection.skills).Count | Should -Be 8
        }
    }

    Context 'A4 Unreal preset' {
        It 'keeps its validation skill, context, checks, edit denies, LFS and watcher ignores' {
            $dir = New-SelProject "a4$(New-Id)" unreal
            Get-SkillNames $dir | Should -Contain 'unreal-validation'
            @((Get-Effective $dir)['checks']) | Should -Contain 'unreal-validation'
            Read-SwText (Join-Path $dir 'AGENTS.md') | Should -Match 'Profile: Unreal Engine'
            Read-SwText (Join-Path $dir '.gitattributes') | Should -Match '\*\.uasset filter=lfs'
            $oc = Read-SwJson (Join-Path $dir 'opencode.jsonc')
            @($oc['permissions'] | Where-Object { $_['action'] -eq 'edit' -and $_['resource'] -eq '*.umap' -and $_['effect'] -eq 'deny' }).Count | Should -Be 1
            @($oc['watcher']['ignore']) | Should -Contain 'DerivedDataCache/**'
            (Test-SwValidate $dir).ExitCode | Should -Be 0
        }

        It 'refuses to drop managed LFS rules even with -Force and -Adopt, writing nothing' {
            $dir = New-SelProject "a4l$(New-Id)" unreal
            Set-Selection $dir generic
            $tree = Get-Tree $dir
            { Update-SwProject -Path $dir } | Should -Throw '*Refusing to drop*LFS*'
            { Update-SwProject -Path $dir -Force -Adopt } | Should -Throw '*Refusing to drop*LFS*'
            Get-Tree $dir | Should -Be $tree
        }
    }

    Context 'A5 roster agreement' {
        It 'roles, dependencies, routes, guidance and the Build allowlist agree; workers cannot delegate' {
            $dir = New-SelProject "a5$(New-Id)" research
            $sel = Get-Effective $dir
            @((Read-SwJson (Join-Path $dir '.sw/roles.json')).Keys | Sort-Object) | Should -Be @($sel['roles'])
            $oc = Read-SwJson (Join-Path $dir 'opencode.jsonc')
            $allow = @($oc['agents']['build']['permissions'] | Where-Object { $_['action'] -eq 'subagent' -and $_['effect'] -eq 'allow' } | ForEach-Object { $_['resource'] } | Sort-Object -Unique)
            $allow | Should -Be @('explore', 'general', 'project-developer', 'project-research', 'project-review')
            foreach ($c in Get-ChildItem (Join-Path $dir '.opencode/commands') -Filter *.md) { (Read-SwFrontmatter $c.FullName @('description', 'agent', 'subagent'))['agent'] | Should -BeIn @($sel['roles']) }
            $leader = Read-SwText (Join-Path $dir '.opencode/agents/project-leader.md')
            foreach ($r in 'project-developer', 'project-research', 'project-review') { $leader | Should -Match "(?m)^- ${r}:" }
            $dev = @((Read-SwFrontmatter (Join-Path $dir '.opencode/agents/project-developer.md') @('description', 'mode', 'color', 'permissions'))['permissions'])
            Get-SwDecision $dev 'subagent' 'project-review' | Should -Be 'deny'
        }

        It 'a profile omitting an optional role omits its commands and dependency skill, never core rules' {
            $kit = New-KitCopy "kitLean$(New-Id)"
            $lean = Join-Path $kit 'project/profiles/lean'
            Copy-Item -LiteralPath (Join-Path $kit 'project/profiles/generic') -Destination $lean -Recurse
            $p = Read-SwJson (Join-Path $lean 'profile.json'); $p['composition']['roles'] = @('project-leader', 'project-developer', 'explore')
            Write-SwFile (Join-Path $lean 'profile.json') (ConvertTo-SwJson $p)
            Use-Kit $kit {
                $dir = Join-Path $TestDrive "a5lean$(New-Id)"
                Initialize-SwProject -Path $dir -Profile lean -Name Lean | Out-Null
                Test-Path (Join-Path $dir '.opencode/agents/project-review.md') | Should -BeFalse
                foreach ($c in 'review', 'status') { Test-Path (Join-Path $dir ".opencode/commands/$c.md") | Should -BeFalse }
                foreach ($c in 'work', 'resume', 'handoff', 'inbox', 'workspace-check', 'validate') { Test-Path (Join-Path $dir ".opencode/commands/$c.md") | Should -BeTrue }
                Get-SkillNames $dir | Should -Be @('agent-documentation', 'minimal-change', 'project-planning', 'structured-debugging', 'task-handoff')
                Read-SwText (Join-Path $dir 'AGENTS.md') | Should -Match '## Required startup'
                Read-SwText (Join-Path $dir '.opencode/agents/project-leader.md') | Should -Not -Match '(?m)^- project-review:'
                Read-SwText (Join-Path $dir '.sw/workspace.md') | Should -Not -Match '(?m)^\| project-review '
                (Test-SwValidate $dir).ExitCode | Should -Be 0
            }
        }
    }

    Context 'A6 malformed selection fails closed' {
        BeforeAll {
            $script:CatText = Read-SwText (Join-Path $RepoRoot 'project/selection.json')
            $script:RoleIds = @((Read-SwJson (Join-Path $RepoRoot 'project/roles.json')).Keys)
            function Invoke-Resolve([scriptblock]$Mutate) {
                $x = @{ cat = ($script:CatText | ConvertFrom-Json -AsHashtable); prof = (Read-SwJson (Join-Path $RepoRoot 'project/profiles/generic/profile.json')); sel = [ordered]@{ version = 1; capabilities = @() } }
                & $Mutate $x
                Resolve-SwSelection $x.sel 'generic' $x.prof $x.cat $script:RoleIds
            }
        }

        It 'the unmodified catalogue resolves' { @((Invoke-Resolve { }).skills).Count | Should -Be 6 }

        It 'rejects <Name>' -ForEach @(
            @{ Name = 'catalogue version 2'; M = { param($x) $x.cat['version'] = 2 } }
            @{ Name = 'an unsupported catalogue key'; M = { param($x) $x.cat['hooks'] = @() } }
            @{ Name = 'a scalar list'; M = { param($x) $x.cat['capabilities']['research']['skills'] = 'research' } }
            @{ Name = 'a null list'; M = { param($x) $x.cat['core']['checks'] = $null } }
            @{ Name = 'a duplicate list entry'; M = { param($x) $x.cat['roleSkills']['project-review'] = @('focused-review', 'focused-review') } }
            @{ Name = 'a path-like ID'; M = { param($x) $x.cat['roleSkills']['project-review'] = @('../escape') } }
            @{ Name = 'a noncanonical ID'; M = { param($x) $x.sel['capabilities'] = @('Research') } }
            @{ Name = 'an unknown capability'; M = { param($x) $x.sel['capabilities'] = @('telemetry') } }
            @{ Name = 'config version 2'; M = { param($x) $x.sel['version'] = 2 } }
            @{ Name = 'an unsupported config key'; M = { param($x) $x.sel['roles'] = @('project-review') } }
            @{ Name = 'scalar config capabilities'; M = { param($x) $x.sel['capabilities'] = 'research' } }
            @{ Name = 'a duplicate config capability'; M = { param($x) $x.sel['capabilities'] = @('research', 'research') } }
            @{ Name = 'a non-object selection'; M = { param($x) $x.sel = 'v1' } }
            @{ Name = 'a dropped core skill floor'; M = { param($x) $x.cat['core']['skills'] = @('project-planning') } }
            @{ Name = 'a dropped core role floor'; M = { param($x) $x.cat['core']['roles'] = @() } }
            @{ Name = 'a dropped core check floor'; M = { param($x) $x.cat['core']['checks'] = @('workspace-static') } }
            @{ Name = 'roleSkills without a kit role'; M = { param($x) $x.cat['roleSkills'].Remove('project-review') } }
            @{ Name = 'an unknown profile role'; M = { param($x) $x.prof['composition']['roles'] = @('project-leader', 'ghost') } }
            @{ Name = 'an invalid context ID'; M = { param($x) $x.prof['composition']['context'] = @('mobile') } }
            @{ Name = 'an invalid check ID'; M = { param($x) $x.cat['capabilities']['research']['checks'] = @('run-anything') } }
            @{ Name = 'a composition missing a key'; M = { param($x) $x.prof['composition'].Remove('checks') } }
            @{ Name = 'a missing composition'; M = { param($x) $x.prof.Remove('composition') } }
        ) {
            { Invoke-Resolve $M } | Should -Throw '*election*'
        }

        It 'a malformed config selection fails before git init, manifest or any file' {
            $dir = Join-Path $TestDrive "a6cfg$(New-Id)"
            Write-SwFile (Join-Path $dir '.sw/config.json') (ConvertTo-SwJson (Get-V1Config generic @('nope')))
            $tree = Get-Tree $dir
            { Initialize-SwProject -Path $dir -Profile generic } | Should -Throw '*unknown*nope*'
            Get-Tree $dir | Should -Be $tree
            Test-Path (Join-Path $dir '.git') | Should -BeFalse
        }

        It 'missing <Name> fails before git init or any write; no download or fallback' -ForEach @(
            @{ Name = 'role definition'; Rel = 'project/base/.opencode/agents/project-review.md'; Caps = @() }
            @{ Name = 'dependency skill'; Rel = 'project/base/.agents/skills/focused-review/SKILL.md'; Caps = @() }
            @{ Name = 'capability skill (unselected)'; Rel = 'project/base/.agents/skills/free-models/SKILL.md'; Caps = @() }
            @{ Name = 'capability context resource'; Rel = 'project/capabilities/research/AGENTS.section.md'; Caps = @('research') }
        ) {
            $kit = New-KitCopy "kitMissing$(New-Id)"
            Remove-Item -LiteralPath (Join-Path $kit $Rel) -Force
            Use-Kit $kit {
                $dir = Join-Path $TestDrive "a6m$(New-Id)"
                New-Item -ItemType Directory -Path $dir | Out-Null
                { Initialize-SwProject -Path $dir -Profile generic -Capabilities $Caps } | Should -Throw '*definitions missing*'
                @(Get-ChildItem -LiteralPath $dir -Force).Count | Should -Be 0
            }
        }

        It 'a role dependency naming a skill the kit lacks fails' {
            $kit = New-KitCopy "kitDep$(New-Id)"
            $cat = Read-SwJson (Join-Path $kit 'project/selection.json'); $cat['roleSkills']['project-review'] = @('focused-review', 'ghost-skill')
            Write-SwFile (Join-Path $kit 'project/selection.json') (ConvertTo-SwJson $cat)
            Use-Kit $kit { { Get-SwRender (Get-V1Config) } | Should -Throw '*ghost-skill*' }
        }
    }

    Context 'A7 legacy compatibility' {
        It 'legacy <Profile> keeps all base components and the old profile.skills meaning; update never opts in' -ForEach @(
            @{ Profile = 'generic' }, @{ Profile = 'unreal' }
        ) {
            $dir = New-SwProject "a7$Profile$(New-Id)" $Profile -Legacy
            $expected = @(@('agent-documentation', 'focused-review', 'free-models', 'minimal-change', 'project-planning', 'research', 'structured-debugging', 'task-handoff') + @(if ($Profile -eq 'unreal') { 'unreal-validation' }) | Sort-Object)
            Get-SkillNames $dir | Should -Be $expected
            Test-Path (Join-Path $dir '.opencode/agents/project-research.md') | Should -BeTrue
            Test-Path (Join-Path $dir '.sw/selection.json') | Should -BeFalse
            (Read-SwJson (Join-Path $dir '.sw/profile.json')).Contains('effectiveSelection') | Should -BeFalse
            Read-SwText (Join-Path $dir '.sw/roles.json') | Should -Be (Read-SwText (Join-Path $RepoRoot 'project/roles.json'))
            (Test-SwValidate $dir).ExitCode | Should -Be 0
            $tree = Get-Tree $dir
            $out = Update-SwProject -Path $dir
            ($out -join "`n") | Should -Match 'selection: legacy'
            Get-Tree $dir | Should -Be $tree
            (Get-SwConfig $dir).Contains('selection') | Should -BeFalse
        }

        It '-Capabilities without -SelectionV1 on a legacy project is refused with nothing written' {
            $dir = New-SwProject "a7c$(New-Id)" generic -Legacy
            $tree = Get-Tree $dir
            { Update-SwProject -Path $dir -Capabilities research } | Should -Throw '*-SelectionV1*'
            Get-Tree $dir | Should -Be $tree
        }
    }

    Context 'A8 transitions' {
        It 'explicit legacy-to-v1 removes only unedited owned deselected files and records the selection' {
            $dir = New-SwProject "a8$(New-Id)" generic -Legacy
            Update-SwProject -Path $dir -SelectionV1 | Out-Null
            Get-SkillNames $dir | Should -Be $script:Generic
            foreach ($p in '.opencode/agents/project-research.md', '.opencode/commands/research.md') { Test-Path (Join-Path $dir $p) | Should -BeFalse }
            (Get-SwConfig $dir)['selection']['version'] | Should -Be 1
            (Test-SwValidate $dir).ExitCode | Should -Be 0
        }

        It 'a <Name> deselected file blocks legacy-to-v1 with nothing written, even with -Force -Adopt' -ForEach @(
            @{ Name = 'modified'; Prep = { param($d) Write-SwFile (Join-Path $d '.agents/skills/research/SKILL.md') ((Read-SwText (Join-Path $d '.agents/skills/research/SKILL.md')) + "`nlocal edit`n") }; Expect = '*research/SKILL.md (modified)*' }
            @{ Name = 'unowned resource'; Prep = { param($d) Write-SwFile (Join-Path $d '.agents/skills/free-models/notes.md') "mine`n" }; Expect = '*free-models/notes.md (unowned*' }
            @{ Name = 'unowned role'; Prep = { param($d) $m = Read-SwJson (Join-Path $d '.sw/manifest.json'); $m['files'].Remove('.opencode/agents/project-research.md'); Write-SwFile (Join-Path $d '.sw/manifest.json') (ConvertTo-SwJson $m) }; Expect = '*project-research.md (unowned*' }
        ) {
            $dir = New-SwProject "a8b$(New-Id)" generic -Legacy
            & $Prep $dir
            $tree = Get-Tree $dir
            { Update-SwProject -Path $dir -SelectionV1 } | Should -Throw $Expect
            { Update-SwProject -Path $dir -SelectionV1 -Force -Adopt } | Should -Throw '*Selection change blocked*'
            Get-Tree $dir | Should -Be $tree
        }

        It 'a linked deselected skill directory blocks with nothing written' {
            $dir = New-SwProject "a8j$(New-Id)" generic -Legacy
            $target = Join-Path $TestDrive "linkTarget$(New-Id)"
            Copy-Item -LiteralPath (Join-Path $dir '.agents/skills/research') -Destination $target -Recurse
            Remove-Item -LiteralPath (Join-Path $dir '.agents/skills/research') -Recurse -Force
            try { New-Item -ItemType Junction -Path (Join-Path $dir '.agents/skills/research') -Target $target -ErrorAction Stop | Out-Null }
            catch { Set-ItResult -Skipped -Because "a directory link cannot be created here: $($_.Exception.Message)"; return }
            $tree = Get-Tree $dir
            { Update-SwProject -Path $dir -SelectionV1 } | Should -Throw '*skills/research (linked)*'
            Get-Tree $dir | Should -Be $tree
        }

        It 'v1 capability-off removes multi-file capability skills as a unit; an edit blocks it' {
            $kit = New-KitCopy "kitRes$(New-Id)"
            Write-SwFile (Join-Path $kit 'project/base/.agents/skills/research/reference.md') "extra resource`n"
            Use-Kit $kit {
                $dir = New-SelProject "a8off$(New-Id)" generic @('research')
                Test-Path (Join-Path $dir '.agents/skills/research/reference.md') | Should -BeTrue
                Write-SwFile (Join-Path $dir '.agents/skills/research/reference.md') "edited`n"
                $tree = Get-Tree $dir
                { Update-SwProject -Path $dir -Capabilities '' } | Should -Throw '*reference.md (modified)*'
                Get-Tree $dir | Should -Be $tree
                Write-SwFile (Join-Path $dir '.agents/skills/research/reference.md') "extra resource`n"
                Update-SwProject -Path $dir -Capabilities '' | Out-Null
                @(Get-ChildItem -LiteralPath (Join-Path $dir '.agents/skills/research') -Recurse -File -ErrorAction SilentlyContinue).Count | Should -Be 0
                @((Get-SwConfig $dir)['selection']['capabilities']).Count | Should -Be 0
                (Test-SwValidate $dir).ExitCode | Should -Be 0
            }
        }
    }

    Context 'A9 WhatIf' {
        It 'fresh init -WhatIf reports mode and sets and writes nothing, Git included' {
            $dir = Join-Path $TestDrive "a9f$(New-Id)"
            New-Item -ItemType Directory -Path $dir | Out-Null
            $out = Initialize-SwProject -Path $dir -Capabilities research -WhatIf 6> $null
            ($out -join "`n") | Should -Match 'selection: v1 profile=generic capabilities=\[research\]'
            @(Get-ChildItem -LiteralPath $dir -Force).Count | Should -Be 0
        }

        It 'existing update -WhatIf with an opt-in reports the plan and changes nothing, adapter inventory included' {
            $dir = New-SwProject "a9e$(New-Id)" generic -Legacy
            Set-TestClaudeMap $dir
            $m = Read-SwJson (Join-Path $dir '.opencode/opencode.jsonc'); $m['agents'].Remove('project-research')
            Write-SwFile (Join-Path $dir '.opencode/opencode.jsonc') (ConvertTo-SwJson $m)
            Invoke-SwClaude enable -Path $dir | Out-Null
            $tree = Get-Tree $dir
            $out = (Update-SwProject -Path $dir -SelectionV1 -Capabilities provider-setup -WhatIf 6> $null) -join "`n"
            $out | Should -Match 'selection: v1 profile=generic capabilities=\[provider-setup\]'
            $out | Should -Match '(?m)^remove\s+.*\.agents/skills/research/SKILL\.md'
            $out | Should -Match 'Would regenerate the Claude adapter'
            Get-Tree $dir | Should -Be $tree
        }
    }

    Context 'A10 Claude adapter under v1' {
        It 'emits selected kit components only and keeps STOPs, import, tools and ownership' {
            $dir = New-SelProject "a10$(New-Id)"
            Write-SwFile (Join-Path $dir '.agents/skills/my-extra/SKILL.md') "---`nname: my-extra`ndescription: Project-owned extra.`n---`n`nBody.`n"
            Set-TestClaudeMap $dir
            $map = Read-SwJson (Join-Path $dir '.opencode/opencode.jsonc'); $map['agents']['project-review']['model'] = 'openrouter/vendor-model'
            Write-SwFile (Join-Path $dir '.opencode/opencode.jsonc') (ConvertTo-SwJson $map)
            Invoke-SwClaude enable -Path $dir | Out-Null
            @(Get-ChildItem (Join-Path $dir '.claude/skills') -Directory | ForEach-Object Name | Sort-Object) | Should -Be $script:Generic
            @(Get-ChildItem (Join-Path $dir '.claude/agents') -Filter *.md | ForEach-Object BaseName) | Should -Be @('project-developer')
            @(Get-ChildItem (Join-Path $dir '.claude/commands') -Filter *.md | ForEach-Object BaseName | Sort-Object) | Should -Be @('handoff', 'inbox', 'resume', 'review', 'status', 'validate', 'work', 'workspace-check')
            Read-SwText (Join-Path $dir '.claude/commands/review.md') | Should -Match 'STOP: `project-review`'
            Read-SwText (Join-Path $dir '.claude/CLAUDE.md') | Should -Be "@../AGENTS.md`n"
            Read-SwText (Join-Path $dir '.claude/agents/project-developer.md') | Should -Match '(?m)^disallowedTools: Agent$'
            (Read-SwClaudeOwnership $dir).State | Should -Be 'ok'
            $out = Test-SwValidate $dir
            $out.ExitCode | Should -Be 0
            ($out.Output -join "`n") | Should -Match 'Project-owned extra kept, outside the selection: \.agents/skills/my-extra/'
        }

        It 'a <Name> stale Claude component blocks before any project write' -ForEach @(
            @{ Name = 'modified'; Prep = { param($d) Write-SwFile (Join-Path $d '.claude/agents/project-research.md') ((Read-SwText (Join-Path $d '.claude/agents/project-research.md')) + "edit`n") }; Expect = '*.claude/agents/project-research.md (modified)*' }
            @{ Name = 'unverified legacy'; Prep = { param($d) Write-SwFile (Join-Path $d '.claude/.sw-generated') (InModuleScope Sw.Project { $script:ClaudeMarker }) }; Expect = '*.claude/agents/project-research.md (unowned or unverified)*' }
        ) {
            $dir = New-SelProject "a10s$(New-Id)" generic @('research')
            Set-TestClaudeMap $dir
            Invoke-SwClaude enable -Path $dir | Out-Null
            & $Prep $dir
            $tree = Get-Tree $dir
            { Update-SwProject -Path $dir -Capabilities '' } | Should -Throw $Expect
            Get-Tree $dir | Should -Be $tree
        }

        It 'an unedited stale Claude component goes with its capability; the real adapter stays absent' {
            $dir = New-SelProject "a10ok$(New-Id)" generic @('research')
            Set-TestClaudeMap $dir
            Invoke-SwClaude enable -Path $dir | Out-Null
            $m = Read-SwJson (Join-Path $dir '.opencode/opencode.jsonc'); $m['agents'].Remove('project-research')
            Write-SwFile (Join-Path $dir '.opencode/opencode.jsonc') (ConvertTo-SwJson $m)
            Update-SwProject -Path $dir -Capabilities '' | Out-Null
            foreach ($p in '.claude/agents/project-research.md', '.claude/commands/research.md', '.claude/skills/research/SKILL.md') { Test-Path (Join-Path $dir $p) | Should -BeFalse }
            (Test-SwValidate $dir).ExitCode | Should -Be 0
            Test-Path (Join-Path $RepoRoot '.claude') | Should -BeFalse
        }
    }

    Context 'A11 extras, overlays and budget' {
        It 'keeps project-owned extras, counts their metadata, and validate and context agree on the budget' {
            $dir = New-SelProject "a11$(New-Id)"
            $leader = { param($d)
                $ctx = (Get-SwContext -Path $d) -join "`n"
                $m = [regex]::Match($ctx, '(?m)^project-leader: .*skill_metadata=(\d+) .*total=(\d+)')
                $v = [regex]::Match(((Test-SwProject -Path $d) -join "`n"), '(?m)^Startup budget: project-leader = (\d+) bytes')
                [pscustomobject]@{ Skills = [int]$m.Groups[1].Value; Total = [int]$m.Groups[2].Value; Validate = [int]$v.Groups[1].Value }
            }
            $before = & $leader $dir
            $before.Total | Should -BeGreaterThan 0
            $before.Total | Should -Be $before.Validate
            $desc = 'Project-owned helper skill.'
            Write-SwFile (Join-Path $dir '.agents/skills/my-skill/SKILL.md') "---`nname: my-skill`ndescription: $desc`n---`n`nBody.`n"
            Update-SwProject -Path $dir | Out-Null
            Test-Path (Join-Path $dir '.agents/skills/my-skill/SKILL.md') | Should -BeTrue
            $after = & $leader $dir
            $after.Skills | Should -Be ($before.Skills + [Text.Encoding]::UTF8.GetByteCount("my-skill$desc"))
            $after.Total | Should -Be $after.Validate
        }

        It 'flags a known deselected <Name> and blocks the update' -ForEach @(
            @{ Name = 'command'; Prep = { param($d) Copy-Item -LiteralPath (Join-Path $RepoRoot 'project/base/.opencode/commands/research.md') -Destination (Join-Path $d '.opencode/commands/research.md') }; Expect = 'Deselected kit component installed: \.opencode/commands/research\.md' }
            @{ Name = 'overlay role'; Prep = { param($d) Set-SwTiers -Light haiku -Standard sonnet -Path $d | Out-Null; $m = Read-SwJson (Join-Path $d '.opencode/opencode.jsonc'); $m['agents']['project-research'] = [ordered]@{ model = 'sonnet' }; Write-SwFile (Join-Path $d '.opencode/opencode.jsonc') (ConvertTo-SwJson $m) }; Expect = 'deselected kit role project-research' }
        ) {
            $dir = New-SelProject "a11k$(New-Id)"
            & $Prep $dir
            $out = Test-SwValidate $dir
            $out.ExitCode | Should -Be 1
            ($out.Output -join "`n") | Should -Match $Expect
            $tree = Get-Tree $dir
            { Update-SwProject -Path $dir } | Should -Throw '*Selection change blocked*'
            Get-Tree $dir | Should -Be $tree
        }

        It 'a mismatched effectiveSelection is reported' {
            $dir = New-SelProject "a11m$(New-Id)"
            $p = Read-SwJson (Join-Path $dir '.sw/profile.json'); $p['effectiveSelection']['skills'] = @('task-handoff')
            Write-SwFile (Join-Path $dir '.sw/profile.json') (ConvertTo-SwJson $p)
            ((Test-SwValidate $dir).Output -join "`n") | Should -Match 'effectiveSelection does not match'
        }
    }

    Context 'A12 free-models wording' {
        It 'stops on quota and unknown effects, keeps tiers model-only and the qualified variant section' {
            $text = Read-SwText (Join-Path $RepoRoot 'project/base/.agents/skills/free-models/SKILL.md')
            $text | Should -Not -Match 'retry once, then route around'
            $text | Should -Not -Match 'free models or effort levels'
            foreach ($p in 'On quota, 429, rate or session limits: stop and checkpoint', 'do not retry, spawn or route around', 'reconcile the exit, artifacts and unknown effects first',
                'new evidence and applicable approval', 'three-failed-attempts ceiling', 'tiers are model-only', '(?m)^## Variants$', 'one-off session') { $text | Should -Match $p }
            Read-SwText (Join-Path $RepoRoot 'project/base/.sw/workspace.md') | Should -Match 'Do not retry into the limit'
        }
    }

    Context 'R1 nonexistent fresh target' {
        It 'an invalid <Name> leaves a nonexistent target absent' -ForEach @(
            @{ Name = 'capability'; Opts = @{ Capabilities = @('nope') }; Expect = '*unknown*nope*' }
            @{ Name = 'profile'; Opts = @{ Profile = 'no-such' }; Expect = '*Unknown profile*' }
            @{ Name = 'path-like profile'; Opts = @{ Profile = '../generic' }; Expect = '*canonical*' }
        ) {
            $dir = Join-Path $TestDrive "r1$(New-Id)"
            { Initialize-SwProject -Path $dir @Opts } | Should -Throw $Expect
            Test-Path -LiteralPath $dir | Should -BeFalse
        }

        It 'a missing kit component leaves a nonexistent target absent' {
            $kit = New-KitCopy "kitR1$(New-Id)"
            Remove-Item -LiteralPath (Join-Path $kit 'project/base/.agents/skills/focused-review/SKILL.md') -Force
            Use-Kit $kit {
                $dir = Join-Path $TestDrive "r1m$(New-Id)"
                { Initialize-SwProject -Path $dir } | Should -Throw '*definitions missing*'
                Test-Path -LiteralPath $dir | Should -BeFalse
            }
        }

        It 'WhatIf on a nonexistent target reports mode, sets and actions and leaves it absent' {
            $dir = Join-Path $TestDrive "r1w$(New-Id)"
            $out = (Initialize-SwProject -Path $dir -Capabilities research -WhatIf 6> $null) -join "`n"
            $out | Should -Match 'selection: v1 profile=generic capabilities=\[research\]'
            $out | Should -Match '(?m)^add\s+.*\.opencode/agents/project-research\.md'
            Test-Path -LiteralPath $dir | Should -BeFalse
        }

        It 'the renderer rejects a path-like profile before deriving a source path, legacy or v1' {
            { Get-SwRender (Get-V1Config '../profiles/generic') } | Should -Throw '*canonical*'
            $legacy = Get-V1Config; $legacy.Remove('selection'); $legacy['profile'] = '..\generic'
            { Get-SwRender $legacy } | Should -Throw '*canonical*'
        }
    }

    Context 'R2 candidate Claude adapter preflight' {
        BeforeEach {
            $script:Dir = New-SelProject "r2$(New-Id)"
            Set-TestClaudeMap $script:Dir
            Invoke-SwClaude enable -Path $script:Dir | Out-Null
            $script:SetModel = { param($Role, $Model) $m = Read-SwJson (Join-Path $script:Dir '.opencode/opencode.jsonc'); $m['agents'][$Role] = [ordered]@{ model = $Model }; Write-SwFile (Join-Path $script:Dir '.opencode/opencode.jsonc') (ConvertTo-SwJson $m) }
        }

        It 'a <Name> fails the update with tree, config and inventory unchanged' -ForEach @(
            @{ Name = 'malformed selected model'; Prep = { & $script:SetModel 'project-developer' 'default' }; Expect = '*explicit and model-only*' }
            @{ Name = 'non-string selected model'; Prep = { $m = Read-SwJson (Join-Path $script:Dir '.opencode/opencode.jsonc'); $m['agents']['project-developer'] = [ordered]@{ model = 5 }; Write-SwFile (Join-Path $script:Dir '.opencode/opencode.jsonc') (ConvertTo-SwJson $m) }; Expect = '*explicit model string*' }
            @{ Name = 'map without Claude roles'; Prep = { foreach ($r in 'project-leader', 'project-developer', 'project-review', 'explore') { & $script:SetModel $r 'openrouter/vendor-model' } }; Expect = '*no explicit Claude role models*' }
        ) {
            & $Prep
            $tree = Get-Tree $script:Dir
            { Update-SwProject -Path $script:Dir -Capabilities provider-setup } | Should -Throw $Expect
            Get-Tree $script:Dir | Should -Be $tree
        }

        It 'an edited worker made stale by its selected role turning non-Claude blocks with nothing written' {
            Write-SwFile (Join-Path $script:Dir '.claude/agents/project-review.md') ((Read-SwText (Join-Path $script:Dir '.claude/agents/project-review.md')) + "edit`n")
            & $script:SetModel 'project-review' 'openrouter/vendor-model'
            $tree = Get-Tree $script:Dir
            { Update-SwProject -Path $script:Dir -Capabilities provider-setup } | Should -Throw '*.claude/agents/project-review.md (modified)*'
            { Update-SwProject -Path $script:Dir -Capabilities provider-setup -Force -Adopt } | Should -Throw '*Selection change blocked*'
            Get-Tree $script:Dir | Should -Be $tree
        }

        It 'an unedited stale worker goes; STOP routing and tool lists stay' {
            & $script:SetModel 'project-review' 'openrouter/vendor-model'
            Update-SwProject -Path $script:Dir -Capabilities provider-setup | Out-Null
            Test-Path (Join-Path $script:Dir '.claude/agents/project-review.md') | Should -BeFalse
            Read-SwText (Join-Path $script:Dir '.claude/commands/review.md') | Should -Match 'STOP: `project-review`'
            Read-SwText (Join-Path $script:Dir '.claude/agents/project-developer.md') | Should -Match '(?m)^disallowedTools: Agent$'
            Test-Path (Join-Path $script:Dir '.claude/skills/free-models/SKILL.md') | Should -BeTrue
            (Test-SwValidate $script:Dir).ExitCode | Should -Be 0
        }

        It 'R4: enabled-adapter <Name> stages nothing outside the project' -ForEach @(
            @{ Name = 'WhatIf'; Refuse = $false }
            @{ Name = 'refused update'; Refuse = $true }
        ) {
            if ($Refuse) {
                Write-SwFile (Join-Path $script:Dir '.claude/agents/project-review.md') ((Read-SwText (Join-Path $script:Dir '.claude/agents/project-review.md')) + "edit`n")
                & $script:SetModel 'project-review' 'openrouter/vendor-model'
            }
            $tree = Get-Tree $script:Dir
            # Instrumentation: every temp-directory variable points below a regular file, so any staging write
            # (directory or file) fails and surfaces; the probe path must still not exist afterwards.
            $blocker = Join-Path $TestDrive "notADirectory$(New-Id)"
            Set-Content -LiteralPath $blocker -Value 'x'
            $probe = Join-Path $blocker 'tmp'
            $saved = @{}
            foreach ($v in 'TMP', 'TEMP', 'TMPDIR') { $saved[$v] = [Environment]::GetEnvironmentVariable($v); [Environment]::SetEnvironmentVariable($v, $probe) }
            try {
                [IO.Path]::GetTempPath() | Should -BeLike "$probe*"
                if ($Refuse) {
                    $err = $null
                    try { Update-SwProject -Path $script:Dir -Capabilities provider-setup | Out-Null } catch { $err = $_.Exception.Message }
                    $err | Should -BeLike '*.claude/agents/project-review.md (modified)*'
                    $err | Should -Not -BeLike '*candidate cannot be generated*'
                } else {
                    $out = (Update-SwProject -Path $script:Dir -Capabilities provider-setup -WhatIf 6> $null) -join "`n"
                    $out | Should -Match 'selection: v1 profile=generic capabilities=\[provider-setup\]'
                    $out | Should -Match 'Would regenerate the Claude adapter'
                }
            } finally { foreach ($v in $saved.Keys) { [Environment]::SetEnvironmentVariable($v, $saved[$v]) } }
            Test-Path -LiteralPath $probe | Should -BeFalse
            Get-Tree $script:Dir | Should -Be $tree
        }
    }

    Context 'R3 legacy .opencode/skills copies' {
        BeforeAll {
            function Set-OldSkillCopy([string]$Dir, [string]$Name) {
                # The pre-move layout an older kit installed, with its manifest ownership.
                $old = Join-Path $Dir ".opencode/skills/$Name"
                New-Item -ItemType Directory -Force -Path (Split-Path $old) | Out-Null
                Move-Item -LiteralPath (Join-Path $Dir ".agents/skills/$Name") -Destination $old
                $m = Read-SwJson (Join-Path $Dir '.sw/manifest.json')
                foreach ($k in @($m['files'].Keys | Where-Object { $_ -like ".agents/skills/$Name/*" })) { $m['files'][".opencode/skills/$($k.Substring(".agents/skills/".Length))"] = $m['files'][$k]; $m['files'].Remove($k) }
                Write-SwFile (Join-Path $Dir '.sw/manifest.json') (ConvertTo-SwJson $m)
            }
        }

        It 'a <Name> deselected old-prefix copy blocks the opt-in, even with -Force -Adopt' -ForEach @(
            @{ Name = 'modified'; Prep = { param($d) Write-SwFile (Join-Path $d '.opencode/skills/research/SKILL.md') ((Read-SwText (Join-Path $d '.opencode/skills/research/SKILL.md')) + "`nlocal edit`n") }; Expect = '*.opencode/skills/research/SKILL.md (modified)*' }
            @{ Name = 'unowned'; Prep = { param($d) $m = Read-SwJson (Join-Path $d '.sw/manifest.json'); $m['files'].Remove('.opencode/skills/research/SKILL.md'); Write-SwFile (Join-Path $d '.sw/manifest.json') (ConvertTo-SwJson $m) }; Expect = '*.opencode/skills/research/SKILL.md (unowned*' }
        ) {
            $dir = New-SwProject "r3$(New-Id)" generic -Legacy
            Set-OldSkillCopy $dir research
            & $Prep $dir
            $tree = Get-Tree $dir
            { Update-SwProject -Path $dir -SelectionV1 } | Should -Throw $Expect
            { Update-SwProject -Path $dir -SelectionV1 -Force -Adopt } | Should -Throw '*Selection change blocked*'
            Get-Tree $dir | Should -Be $tree
        }

        It 'an unedited owned old-prefix copy is removed safely' {
            $dir = New-SwProject "r3ok$(New-Id)" generic -Legacy
            Set-OldSkillCopy $dir research
            Update-SwProject -Path $dir -SelectionV1 | Out-Null
            Test-Path (Join-Path $dir '.opencode/skills/research/SKILL.md') | Should -BeFalse
            (Test-SwValidate $dir).ExitCode | Should -Be 0
        }

        It 'v1 validation flags a deselected known old-prefix copy and update blocks it' {
            $dir = New-SelProject "r3v$(New-Id)"
            New-Item -ItemType Directory -Path (Join-Path $dir '.opencode/skills') | Out-Null
            Copy-Item -LiteralPath (Join-Path $RepoRoot 'project/base/.agents/skills/research') -Destination (Join-Path $dir '.opencode/skills/research') -Recurse
            $out = Test-SwValidate $dir
            $out.ExitCode | Should -Be 1
            ($out.Output -join "`n") | Should -Match 'Deselected kit component installed: \.opencode/skills/research/'
            $tree = Get-Tree $dir
            { Update-SwProject -Path $dir } | Should -Throw '*.opencode/skills/research/SKILL.md (unowned*'
            Get-Tree $dir | Should -Be $tree
        }
    }
}
