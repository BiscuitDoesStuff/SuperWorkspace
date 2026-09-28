#requires -Version 7.2
# Pester 5+ suite for the SuperWorkspace kit. All scratch projects live under $TestDrive;
# the real user profile (~/.claude, ~/.config, ~/AGENTS.md) is never touched.

BeforeAll {
    $script:RepoRoot = Split-Path $PSScriptRoot -Parent
    Import-Module (Join-Path $RepoRoot 'product/lib/Sw.Project.psm1') -Force -DisableNameChecking
    Import-Module (Join-Path $RepoRoot 'product/lib/Sw.Kit.psm1') -Force -DisableNameChecking

    function New-SwProject {
        param([string]$Name, [string]$Profile = 'generic', [int]$GitHubTier = 0)
        $dir = Join-Path $TestDrive $Name
        Initialize-SwProject -Path $dir -Profile $Profile -Name $Name -GitHubTier $GitHubTier | Out-Null
        git -C $dir config user.name tester
        git -C $dir config user.email tester@example.com
        $dir
    }

    function New-Id { [Guid]::NewGuid().ToString('N').Substring(0, 8) }

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
        $dir = New-SwProject "session$(New-Id)" unreal 1
        $session = Get-Key (Add-SwRtkTwins (Get-SwSessionRules @('*.uasset', '*.umap') 1))
        $agents = @(Get-ChildItem -LiteralPath (Join-Path $dir '.opencode/agents') -Filter *.md -File -Force)
        $agents.Count | Should -Be 9
        foreach ($a in $agents) {
            $keys = Get-Key (Get-AgentRules $dir $a.BaseName)
            $keys[0..($session.Count - 1)] | Should -Be $session -Because $a.Name
        }
        # An agent without a permissions block gets one; a role's own rules follow the session rules.
        (Get-Key (Get-AgentRules $dir 'project-developer')).Count | Should -Be $session.Count
        (Get-Key (Get-AgentRules $dir 'project-review'))[$session.Count] | Should -Be '*|*|deny'
        (Get-Key (Get-AgentRules $dir 'project-leader'))[$session.Count] | Should -Be 'subagent|*|allow'
        $oc = Read-SwJson (Join-Path $dir 'opencode.jsonc')
        (Get-Key $oc['permissions']) | Should -Be $session
        (Get-Key $oc['agents']['build']['permissions'])[0..$session.Count] | Should -Be (@($session) + 'subagent|*|deny')
    }

    It 'keeps the canonical agent files free of session rules and RTK twins' {
        foreach ($f in Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'product/project/base/.opencode/agents') -Filter *.md -File -Force) {
            (Read-SwText $f.FullName) | Should -Not -Match 'git push|"rtk ' -Because $f.Name
        }
    }

    It 'twins each shell rule except * with an rtk rule of the same effect, directly after it' {
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
        foreach ($role in 'project-leader', 'project-review', 'project-worker') {
            $keys = Get-Key (Get-AgentRules $dir $role)
            for ($i = 0; $i -lt $keys.Count; $i++) {
                $a, $r, $e = $keys[$i] -split '\|'
                if ($a -ne 'shell' -or $r -eq '*' -or $r.StartsWith('rtk ')) { continue }
                $keys[$i + 1] | Should -Be "shell|rtk $r|$e" -Because "$role $r"
            }
        }
        $review = Get-Key (Get-AgentRules $dir 'project-review')
        [array]::IndexOf($review, 'shell|rtk git status *|allow') | Should -Be ([array]::IndexOf($review, 'shell|git status *|allow') + 1)
        (Get-Key (Get-AgentRules $dir 'project-worker')) | Should -Contain 'shell|rtk git switch *|deny'
        $leader = Get-AgentRules $dir 'project-leader'
        foreach ($c in 'rtk git push origin main', 'rtk git stash list', 'rtk gh repo list') { Get-SwDecision $leader shell $c | Should -Be 'deny' -Because $c }
        Get-SwDecision $leader shell 'rtk git commit -m x' | Should -Be 'ask'
        Get-SwDecision $leader shell 'rtk gh issue view 1' | Should -Be 'allow'
        $rules = Get-AgentRules $dir 'project-review'
        Get-SwDecision $rules shell 'rtk git status' | Should -Be 'allow'
        Get-SwDecision $rules shell 'rtk git diff --output=probe.txt' | Should -Be 'deny'
        Get-SwDecision (Get-AgentRules $dir 'project-worker') shell 'rtk git switch main' | Should -Be 'deny'
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
        foreach ($role in 'project-plan', 'project-architect', 'project-review') {
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

Describe 'Validator negative fixtures' {
    BeforeEach { $dir = New-SwProject "neg$(New-Id)" generic }

    It '<Name>' -ForEach @(
        @{ Name = 'missing agent file'; Match = 'Missing agent: project-worker'; Mutate = {
                param($d) Remove-Item (Join-Path $d '.opencode/agents/project-worker.md')
            }
        }
        @{ Name = 'unsupported frontmatter scalar'; Match = 'Unsupported scalar'; Mutate = {
                param($d) $f = Join-Path $d '.opencode/agents/project-worker.md'
                Write-SwFile $f ((Read-SwText $f) -replace '(?m)^description:.*$', 'description: [bad, value]')
            }
        }
        @{ Name = 'command routed to wrong agent'; Match = 'Command validate must route to project-build'; Mutate = {
                param($d) $f = Join-Path $d '.opencode/commands/validate.md'
                Write-SwFile $f ((Read-SwText $f) -replace '(?m)^agent: project-build$', 'agent: project-review')
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
                param($d) $f = Join-Path $d '.opencode/agents/project-worker.md'
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
        Invoke-SwClaude enable -Path $dir | Out-Null
        $f = Join-Path $dir '.claude/project-leader.md'
        Write-SwFile $f ((Read-SwText $f) + "`nedited by hand`n")
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 1
        ($result.Output -join "`n") | Should -Match 'Claude adapter drift: \.claude/project-leader\.md'
    }

    It 'Claude structure is checked against roles.json: <Name>' -ForEach @(
        @{ Name = 'wrong model'; Match = 'Claude agent project-plan: model must be opus'; Mutate = {
                param($d) $f = Join-Path $d '.claude/agents/project-plan.md'
                Write-SwFile $f ((Read-SwText $f) -replace '(?m)^model: opus$', 'model: sonnet')
            }
        }
        @{ Name = 'wrong tools'; Match = 'Claude agent project-review: tools must be'; Mutate = {
                param($d) $f = Join-Path $d '.claude/agents/project-review.md'
                Write-SwFile $f ((Read-SwText $f) -replace '(?m)^tools: .*$', 'tools: Read, Edit')
            }
        }
        @{ Name = 'missing disallowedTools'; Match = 'Claude agent project-worker: must set disallowedTools: Agent'; Mutate = {
                param($d) $f = Join-Path $d '.claude/agents/project-worker.md'
                Write-SwFile $f ((Read-SwText $f) -replace "(?m)^disallowedTools: Agent`n", '')
            }
        }
        @{ Name = 'missing agent'; Match = 'Missing Claude agent: \.claude/agents/project-build\.md'; Mutate = {
                param($d) Remove-Item -LiteralPath (Join-Path $d '.claude/agents/project-build.md') -Force
            }
        }
        @{ Name = 'missing command'; Match = 'Missing Claude command: \.claude/commands/review\.md'; Mutate = {
                param($d) Remove-Item -LiteralPath (Join-Path $d '.claude/commands/review.md') -Force
            }
        }
    ) {
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
        $f = Join-Path $dir '.opencode/agents/project-worker.md'
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
    BeforeEach { $dir = New-SwProject "claude$(New-Id)" generic 0 }

    It 'enable generates agents/commands/skills and a compliant settings.json' {
        Invoke-SwClaude enable -Path $dir | Out-Null

        $roles = Read-SwJson (Join-Path $dir '.sw/roles.json')
        $workers = @($roles.Keys | Where-Object { $_ -notin 'project-leader', 'explore' })
        $efforts = @{ light = 'low'; standard = 'medium'; high = 'xhigh' }
        foreach ($r in $workers) {
            $text = Read-SwText (Join-Path $dir ".claude/agents/$r.md")
            $text | Should -Match '(?m)^model: opus$'
            $text | Should -Match "(?m)^effort: $($efforts[$roles[$r]['tier']])$"
            if ($roles[$r]['claudeTools']) { $text | Should -Match "(?m)^tools: $([regex]::Escape($roles[$r]['claudeTools']))$" }
            else { $text | Should -Not -Match '(?m)^tools:' }
            $text | Should -Match '(?m)^disallowedTools: Agent$'
        }
        @(Get-ChildItem (Join-Path $dir '.claude/agents') -Filter *.md -Force).Count | Should -Be $workers.Count
        Get-Content -LiteralPath (Join-Path $dir '.claude/agents/project-worker.md') -Raw | Should -Match '(?m)^disallowedTools: Agent$'
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
        $settings['permissions']['deny'] | Should -Contain 'Bash(git push:*)'
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
        $text | Should -Not -Match '`/review`'
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
        Test-Path (Join-Path $dir '.claude/agents/project-worker.md') | Should -BeFalse
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

Describe 'Set-SwTiers' {
    It 'writes .opencode/opencode.jsonc mapping standard/light roles to the given model, and refuses to overwrite without -Force' {
        $dir = New-SwProject "tiers$(New-Id)" generic
        Set-SwTiers -Light haiku -Standard sonnet -High opus -Path $dir | Out-Null
        $target = Join-Path $dir '.opencode/opencode.jsonc'
        $map = (Read-SwJson $target)['agents']
        $map['project-plan']['model'] | Should -Be 'sonnet'
        $map['project-architect']['model'] | Should -Be 'sonnet'
        $map['project-review']['model'] | Should -Be 'sonnet'
        $map['project-developer']['model'] | Should -Be 'haiku'
        $map['explore']['model'] | Should -Be 'haiku'
        $map.Contains('project-leader') | Should -BeFalse

        { Set-SwTiers -Light grok -Standard grok -High grok -Path $dir } | Should -Throw '*-Force*'
        Set-SwTiers -Light grok -Standard grok -High grok -Path $dir -Force | Out-Null
        (Read-SwJson $target)['agents']['project-plan']['model'] | Should -Be 'grok'
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

    It 'close refuses to overwrite an existing archive' {
        Invoke-SwComms event -Task T3 -Path $dir | Out-Null
        Invoke-SwComms close -Task T3 -Outcome 'first' -Path $dir | Out-Null
        Invoke-SwComms event -Task T3 -Path $dir | Out-Null
        { Invoke-SwComms close -Task T3 -Outcome 'second' -Path $dir } | Should -Throw '*already exists*'
        Get-Content (Join-Path $dir '.sw/comms/archive/T3/SUMMARY.md') -Raw | Should -Match 'first'
    }
}

Describe 'Test-SwDoctor' {
    It 'reports tier-map and users guidance without -User, and does not throw' {
        $dir = New-SwProject "doctor$(New-Id)" generic
        { Test-SwDoctor -Path $dir } | Should -Not -Throw
        $out = Test-SwDoctor -Path $dir | Out-String
        $out | Should -Match 'sw\.ps1 tiers'
        $out | Should -Match 'pass -User <name>'
        $out | Should -Match 'Startup budget \(validate\) counts kit files only'
        $out | Should -Match 'Branch protection on main: not checked'
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

Describe 'Shipped skill staleness' {
    It 'no shipped SKILL.md has an Observed YYYY-MM line outside an Old observations section' {
        $hits = foreach ($f in Get-ChildItem (Join-Path $RepoRoot 'product') -Recurse -Filter SKILL.md -File -Force) {
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

Describe 'product/ leak guard' {
    It 'ships no personal names or paths' {
        # CHANGELOG is dated history, so it may name the projects the kit came from.
        $hits = Get-ChildItem (Join-Path $RepoRoot 'product') -Recurse -File -Force |
            Where-Object Name -ne 'CHANGELOG.md' |
            Select-String -Pattern 'BiscuitDoesStuff|crank|MyMMO|C:\Dev'
        $hits | ForEach-Object { "$($_.Path):$($_.LineNumber)" } | Should -BeNullOrEmpty
    }
}
