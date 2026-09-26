#requires -Version 7.2
# Pester 5+ suite for the SuperWorkspace kit. All scratch projects live under $TestDrive;
# the real user profile (~/.claude, ~/.config, ~/AGENTS.md) is never touched.

BeforeAll {
    $script:RepoRoot = Split-Path $PSScriptRoot -Parent
    Import-Module (Join-Path $RepoRoot 'lib/Sw.Project.psm1') -Force -DisableNameChecking
    Import-Module (Join-Path $RepoRoot 'lib/Sw.Kit.psm1') -Force -DisableNameChecking

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

    It 'a user-modified managed file becomes skip-modified, is not overwritten, and stays detected' {
        $dir = New-SwProject 'skipModified' generic
        $target = Join-Path $dir '.sw/workspace.md'
        $mine = (Read-SwText $target) + "`nmy local note`n"
        Write-SwFile $target $mine

        $plan1 = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
        ($plan1 | Where-Object Path -eq '.sw/workspace.md').Action | Should -Be 'skip-modified'
        Read-SwText $target | Should -Be $mine

        $plan2 = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir)
        ($plan2 | Where-Object Path -eq '.sw/workspace.md').Action | Should -Be 'skip-modified'
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
        foreach ($r in $workers) { Test-Path (Join-Path $dir ".claude/agents/$r.md") | Should -BeTrue }
        Test-Path (Join-Path $dir '.claude/agents/project-leader.md') | Should -BeFalse
        Test-Path (Join-Path $dir '.claude/agents/explore.md') | Should -BeFalse

        foreach ($c in Get-ChildItem (Join-Path $dir '.opencode/commands') -Filter *.md) {
            Test-Path (Join-Path $dir ".claude/commands/$($c.BaseName).md") | Should -BeTrue
        }
        foreach ($s in Get-ChildItem (Join-Path $dir '.opencode/skills') -Directory) {
            Test-Path (Join-Path $dir ".claude/skills/$($s.Name)/SKILL.md") | Should -BeTrue
        }

        $settings = Read-SwJson (Join-Path $dir '.claude/settings.json')
        $settings['permissions']['deny'] | Should -Contain 'Bash(git push:*)'
        $settings['permissions']['deny'] | Should -Contain 'Bash(gh pr merge:*)'
        $settings['permissions']['deny'] | Should -Contain 'Bash(gh pr create:*)'
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
        $backups = @(Get-ChildItem (Join-Path $dir '.sw/backup') -Recurse -Filter 'settings.json' -File)
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
    It 'writes .opencode/opencode.jsonc mapping reasoning roles to the given model, and refuses to overwrite without -Force' {
        $dir = New-SwProject "tiers$(New-Id)" generic
        Set-SwTiers -Reasoning opus -Standard sonnet -Fast haiku -Path $dir | Out-Null
        $target = Join-Path $dir '.opencode/opencode.jsonc'
        $map = (Read-SwJson $target)['agents']
        $map['project-plan']['model'] | Should -Be 'opus'
        $map['project-architect']['model'] | Should -Be 'opus'
        $map['project-review']['model'] | Should -Be 'opus'
        $map['project-developer']['model'] | Should -Be 'sonnet'
        $map['explore']['model'] | Should -Be 'haiku'
        $map.Contains('project-leader') | Should -BeFalse

        { Set-SwTiers -Reasoning grok -Standard grok -Fast grok -Path $dir } | Should -Throw '*-Force*'
        Set-SwTiers -Reasoning grok -Standard grok -Fast grok -Path $dir -Force | Out-Null
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
