#requires -Version 5.1
# Pester 5+ suite for the SuperWorkspace kit. All scratch projects live under $TestDrive;
# the real user profile (~/.claude, ~/.codex, ~/AGENTS.md) is never touched.

BeforeAll {
    $script:RepoRoot = Split-Path $PSScriptRoot -Parent
    # Child CLI runs use the shell running the suite: Windows PowerShell 5.1 or PowerShell 7.
    $script:Shell = (Get-Process -Id $PID).Path

    function Invoke-InParallel([int]$Count, [scriptblock]$Script, [hashtable]$Parameters) {
        # ForEach-Object -Parallel on both shells: one runspace per index ($Index), all started before any is awaited;
        # an error in any runspace fails the test.
        $pool = [runspacefactory]::CreateRunspacePool(1, $Count)
        $pool.Open()
        try {
            $runs = @(foreach ($i in 0..($Count - 1)) {
                $ps = [powershell]::Create()
                $ps.RunspacePool = $pool
                $null = $ps.AddScript($Script.ToString()).AddParameter('Index', $i).AddParameters($Parameters)
                [pscustomobject]@{ Shell = $ps; Handle = $ps.BeginInvoke() }
            })
            foreach ($run in $runs) {
                try {
                    $run.Shell.EndInvoke($run.Handle)
                    if ($run.Shell.Streams.Error.Count) { throw $run.Shell.Streams.Error[0] }
                } finally { $run.Shell.Dispose() }
            }
        } finally { $pool.Dispose() }
    }
    Import-Module (Join-Path $RepoRoot 'lib/Sw.Project.psm1') -Force -DisableNameChecking
    Import-Module (Join-Path $RepoRoot 'lib/Sw.Kit.psm1') -Force -DisableNameChecking

    function New-SwProject {
        param([string]$Name, [string]$Profile = 'generic', [int]$GitHubTier = 0,
            # A legacy (all-base, pre-selection) project: an existing config without `selection`.
            [switch]$Legacy)
        $dir = Join-Path $TestDrive $Name
        if ($Legacy) { Write-SwFile (Join-Path $dir '.sw/config.json') (ConvertTo-SwJson ([ordered]@{ project = $Name; profile = $Profile; githubTier = $GitHubTier; github = $true; startupBudgetBytes = 12100; users = @() })) }
        Initialize-SwProject -Path $dir -Profile $Profile -Name $Name -GitHubTier $GitHubTier -GitPolicy workspace | Out-Null
        git -C $dir config user.name tester
        git -C $dir config user.email tester@example.com
        $dir
    }

    function New-Id { [Guid]::NewGuid().ToString('N').Substring(0, 8) }

    # Existing Pester harness, in-memory host only: actual mixed ShouldProcess decisions.
    if (-not ('SwAuditPromptHost' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Globalization;
using System.IO;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Security;
using System.Text.RegularExpressions;
using System.Management.Automation;
using System.Management.Automation.Host;
public sealed class SwAuditPromptHost : PSHost {
    private readonly Guid id = Guid.NewGuid();
    private readonly AuditUI ui;
    public int Denied { get { return ui.Denied; } }
    public SwAuditPromptHost(PSHost parent, string deny) { ui = new AuditUI(parent.UI, deny, null, null, null); }
    // Appends editText to editPath once, while the first prompt matching editOn is open (a user editing mid-prompt);
    // an empty editText creates a directory at editPath instead.
    public SwAuditPromptHost(PSHost parent, string deny, string editOn, string editPath, string editText) { ui = new AuditUI(parent.UI, deny, editOn, editPath, editText); }
    public int Edited { get { return ui.Edited; } }
    public override Guid InstanceId { get { return id; } }
    public override string Name { get { return "Audit prompt fixture"; } }
    public override Version Version { get { return new Version(1,0); } }
    public override CultureInfo CurrentCulture { get { return CultureInfo.InvariantCulture; } }
    public override CultureInfo CurrentUICulture { get { return CultureInfo.InvariantCulture; } }
    public override PSHostUserInterface UI { get { return ui; } }
    public override void SetShouldExit(int code) { }
    public override void EnterNestedPrompt() { throw new NotSupportedException(); }
    public override void ExitNestedPrompt() { throw new NotSupportedException(); }
    public override void NotifyBeginApplication() { }
    public override void NotifyEndApplication() { }
    private sealed class AuditUI : PSHostUserInterface {
        private readonly PSHostUserInterface parent; private readonly string deny, editOn, editPath, editText;
        public int Denied, Edited;
        public AuditUI(PSHostUserInterface parent, string deny, string editOn, string editPath, string editText) { this.parent = parent; this.deny = deny; this.editOn = editOn; this.editPath = editPath; this.editText = editText; }
        public override PSHostRawUserInterface RawUI { get { return parent.RawUI; } }
        public override int PromptForChoice(string caption, string message, Collection<ChoiceDescription> choices, int def) {
            if (editOn != null && Edited == 0 && Regex.IsMatch(message, editOn)) { if (editText.Length == 0) Directory.CreateDirectory(editPath); else File.AppendAllText(editPath, editText); Edited++; }
            string answer = Regex.IsMatch(message, deny) ? "No" : "Yes";
            if (answer == "No") Denied++;
            for (int i=0; i<choices.Count; i++) if (choices[i].Label.Replace("&", "") == answer) return i;
            throw new InvalidOperationException("Unexpected confirmation choices");
        }
        public override string ReadLine() { throw new NotSupportedException(); }
        public override SecureString ReadLineAsSecureString() { throw new NotSupportedException(); }
        public override Dictionary<string,PSObject> Prompt(string c,string m,Collection<FieldDescription> f) { throw new NotSupportedException(); }
        public override PSCredential PromptForCredential(string c,string m,string u,string t) { throw new NotSupportedException(); }
        public override PSCredential PromptForCredential(string c,string m,string u,string t,PSCredentialTypes a,PSCredentialUIOptions b) { throw new NotSupportedException(); }
        public override void Write(string s) { }
        public override void Write(ConsoleColor f,ConsoleColor b,string s) { }
        public override void WriteLine(string s) { }
        public override void WriteErrorLine(string s) { }
        public override void WriteDebugLine(string s) { }
        public override void WriteVerboseLine(string s) { }
        public override void WriteWarningLine(string s) { }
        public override void WriteProgress(long n,ProgressRecord p) { }
    }
}
'@
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

Describe 'Hard limits' {
    # Static models of Claude rule matching and Codex prefix rules; neither is the harness's own evaluator.
    BeforeAll {
        $script:Deny = @(Get-SwClaudeDeny)
        $script:Codex = @(Read-SwCodexRules (Get-SwCodexRules))
        function Test-ClaudeDenied([string]$Tool, [string]$Command) { @($script:Deny | Where-Object { $_.StartsWith("$Tool(") -and (Test-SwClaudeRule $_ $Command) }).Count -gt 0 }
        function Test-CodexForbidden([string]$Command) { @($script:Codex | Where-Object { $_.Decision -ceq 'forbidden' -and (Test-SwCodexRule $_.Pattern $Command) }).Count -gt 0 }
        # D9 work that must stay possible: thread-branch pushes, draft PRs, auto-merge, unstaging, ordinary Git and gh reads.
        $script:Cases = Get-SwHardLimitCases
        $script:Allowed = @($script:Cases['Neither'])
    }

    Context 'static matching models' {
        It 'Claude: <Rule> vs [<Command>] -> <Expected>' -ForEach @(
            @{ Rule = 'Bash(git push *)'; Command = 'git push'; Expected = $true }
            @{ Rule = 'Bash(git push *)'; Command = 'git push origin main'; Expected = $true }
            @{ Rule = 'Bash(git push *)'; Command = 'git pushx'; Expected = $false }
            @{ Rule = 'Bash(git push:*)'; Command = 'git push'; Expected = $true }
            @{ Rule = 'Bash(*git *push *--force*)'; Command = 'rtk git -C . push origin x --force'; Expected = $true }
            @{ Rule = 'Bash(*git *push *--force*)'; Command = 'git status && git push --force'; Expected = $true }
            @{ Rule = 'Bash(*git *push *--force*)'; Command = 'git pull --force'; Expected = $false }
            @{ Rule = 'Bash(*git *branch -D main*)'; Command = 'git branch -d main'; Expected = $false }
            @{ Rule = 'PowerShell(*git *branch -D main*)'; Command = 'git branch -d main'; Expected = $true }
            @{ Rule = 'Bash(*git -* rebase*)'; Command = 'git -c core.editor=true rebase -i main'; Expected = $true }
            @{ Rule = 'Bash(*git -* rebase*)'; Command = 'git log --grep rebase'; Expected = $false }
            @{ Rule = 'Bash(*git *push * main"*)'; Command = 'pwsh -c "git push origin main"'; Expected = $true }
            @{ Rule = 'Bash(*git *push * main)'; Command = 'pwsh -c "git push origin main"'; Expected = $false }
            @{ Rule = 'Edit(**/*.uasset)'; Command = 'git push --force'; Expected = $false }
        ) {
            Test-SwClaudeRule $Rule $Command | Should -Be $Expected
        }

        It 'Codex: <Pattern> vs [<Command>] -> <Expected>' -ForEach @(
            @{ Pattern = '["git", "push", ["--force", "-f"]]'; Command = 'git push -f origin x'; Expected = $true }
            @{ Pattern = '["git", "push", ["--force", "-f"]]'; Command = 'git push origin x -f'; Expected = $false }
            @{ Pattern = '["git", "push", ["--force", "-f"]]'; Command = 'git push'; Expected = $false }
            @{ Pattern = '["gh", ["secret", "variable"]]'; Command = 'gh variable list'; Expected = $true }
            @{ Pattern = '["gh", ["secret", "variable"]]'; Command = 'gh pr view && gh secret set X'; Expected = $true }
            @{ Pattern = '["git", "branch", "-D", "main"]'; Command = 'git branch -d main'; Expected = $false }
            @{ Pattern = '["git", "push", "origin", "main"]'; Command = 'git push origin "main"'; Expected = $true }
            @{ Pattern = '["git", "push", "origin", "main"]'; Command = 'bash -c "git push origin main"'; Expected = $false }
            @{ Pattern = '[["git", "git.exe"], "rebase"]'; Command = 'git.exe rebase main'; Expected = $true }
        ) {
            Test-SwCodexRule (ConvertFrom-SwJson $Pattern) $Command | Should -Be $Expected
        }
    }

    Context 'decisions' {
        It 'the static case table has the six kinds, and every case gets its expected decision in both harnesses' {
            @($script:Cases.Keys) | Should -Be @('Both', 'ClaudeOnly', 'CodexOnly', 'PowerShellOnly', 'Neither', 'Gap')
            foreach ($kind in $script:Cases.Keys) {
                foreach ($c in $script:Cases[$kind]) {
                    Test-ClaudeDenied 'Bash' $c | Should -Be ($kind -in 'Both', 'ClaudeOnly') -Because "$kind claude Bash [$c]"
                    Test-ClaudeDenied 'PowerShell' $c | Should -Be ($kind -in 'Both', 'ClaudeOnly', 'PowerShellOnly') -Because "$kind claude PowerShell [$c]"
                    Test-CodexForbidden $c | Should -Be ($kind -in 'Both', 'CodexOnly') -Because "$kind codex [$c]"
                }
            }
        }

        It 'every command in the workspace gap and over-block tables is a case whose decisions match its Harness column' {
            # Owner M7 decision 15: the owner accepts these tables as written, and validate re-checks only cases.
            $kinds = @{
                'Gap'        = @{ 'Both' = 'Gap'; 'Claude' = 'CodexOnly'; 'Codex' = 'ClaudeOnly'; 'Claude Bash, Codex' = 'PowerShellOnly' }
                'Over-block' = @{ 'Both' = 'Both'; 'Claude' = 'ClaudeOnly'; 'Codex' = 'CodexOnly'; 'Claude PowerShell' = 'PowerShellOnly' }
            }
            # A code span cannot hold a tab or a newline; these examples stand for the cases.
            $spelled = @{ 'git<TAB>reset origin/main' = "git`treset origin/main"; 'git push \' = "git push \`n--force" }
            $command = '^(?:"?(?i:git|gh)(?i:\.exe)?"?|\S*/(?i:git)(?i:\.exe)?|rtk|env|cmd|bash|pwsh|\$\w+)(?: |<TAB>)'
            $table = $null; $rows = @{ 'Gap' = 0; 'Over-block' = 0 }; $checked = 0
            foreach ($line in (Read-SwText (Join-Path $RepoRoot 'project/base/.sw/workspace.md')) -split "`n") {
                if ($line -match '^\| (Gap|Over-block) \| Harness \| Example \|') { $table = $Matches[1]; continue }
                if (-not $line.StartsWith('|')) { $table = $null; continue }
                if (-not $table -or $line.StartsWith('| ---')) { continue }
                $cells = @($line.Trim('|') -split ' \| ' | ForEach-Object Trim)
                $kinds[$table].ContainsKey($cells[1]) | Should -BeTrue -Because "$table row harness [$($cells[1])]: $line"
                $kind = $kinds[$table][$cells[1]]
                $found = 0
                foreach ($m in [regex]::Matches(($cells[2] -split '\*not a rule case\*', 2)[0], '`([^`]+)`')) {
                    $c = $m.Groups[1].Value
                    if ($c -notmatch $command) { continue }
                    if ($spelled.ContainsKey($c)) { $c = $spelled[$c] }
                    $found++
                    $c -cin $script:Cases[$kind] | Should -BeTrue -Because "$table row [$($cells[0])] ($($cells[1])) lists [$c], so it must be a $kind case"
                }
                ($found -gt 0 -or $cells[2] -match '\*not a rule case\*') | Should -BeTrue -Because "a row without a case must say not a rule case: $line"
                $rows[$table]++; $checked += $found
            }
            $rows['Gap'] | Should -BeGreaterThan 20
            $rows['Over-block'] | Should -BeGreaterThan 10
            $checked | Should -BeGreaterThan 100
        }

        It 'Claude <Tool> rules deny every hard-limit case' -ForEach @(@{ Tool = 'Bash' }, @{ Tool = 'PowerShell' }) {
            foreach ($c in @($script:Cases['Both']) + 'git push origin +main', 'git push origin --mirror', 'git push origin --all', 'git push origin :main', 'gh release edit v1', 'gh release delete v1',
                'gh repo rename y', 'gh repo archive', 'git filter-repo --force', 'git branch -D main', 'git branch -M main', 'git checkout -B main', 'git push origin refs/heads/main',
                'git reset --hard origin/main', 'git commit --no-edit --amend', 'git rebase', 'git rebase --continue') {
                Test-ClaudeDenied $Tool $c | Should -BeTrue -Because $c
            }
        }

        It 'Codex rules forbid every hard-limit case' {
            foreach ($c in @($script:Cases['Both']) + 'git push origin +main', 'git push origin --mirror', 'git push personal main', 'git push upstream --force', 'git push origin :main', 'gh release delete-asset v1 a',
                'gh repo rename y', 'gh repo archive', 'git filter-repo --force', 'git branch -D main', 'git checkout -B main', 'git push --set-upstream origin main', 'git update-ref -d refs/heads/main',
                'git reset --hard origin/main', 'git commit --no-edit --amend', 'git commit -a --amend', 'git rebase', 'git rebase --continue') {
                Test-CodexForbidden $c | Should -BeTrue -Because $c
            }
        }

        It 'both harnesses block history-moving resets and rebasing pulls in each argument order, and keep unstaging open' {
            foreach ($c in 'git reset --soft HEAD~2', 'git reset --keep ORIG_HEAD', 'git reset --quiet HEAD^', 'git reset HEAD~1 --soft', 'git reset upstream/main', 'git reset @{u}',
                'git pull --rebase=true', 'git pull --rebase=yes upstream main', 'git pull upstream -r', 'git pull origin main --rebase=merges') {
                foreach ($tool in 'Bash', 'PowerShell') { Test-ClaudeDenied $tool $c | Should -BeTrue -Because "$tool $c" }
                Test-CodexForbidden $c | Should -BeTrue -Because "codex $c"
            }
            foreach ($c in 'git reset -- src/HEAD.md', 'git reset HEAD -- notes.md', 'git restore --staged -- docs/a.md', 'git pull --no-rebase', 'git pull upstream main --ff-only') {
                foreach ($tool in 'Bash', 'PowerShell') { Test-ClaudeDenied $tool $c | Should -BeFalse -Because "$tool $c" }
                Test-CodexForbidden $c | Should -BeFalse -Because "codex $c"
            }
        }

        It 'Claude <Tool> rules deny the command-substitution and quoted-target forms of a push to main' -ForEach @(@{ Tool = 'Bash' }, @{ Tool = 'PowerShell' }) {
            # Claude documents checking commands nested in $() and backticks; these patterns hold even if it did not.
            foreach ($c in '$(git push origin main)', 'x=$(git push origin HEAD:main)', 'echo `git push origin main`', 'echo `git push origin :main`', "git push origin 'main'",
                'git push origin "HEAD:main"', "git push origin '+HEAD'") {
                Test-ClaudeDenied $Tool $c | Should -BeTrue -Because $c
            }
        }

        It 'Claude never reads a word after the -- separator as a commit, and still refuses a commit-like first argument' {
            # Codex review round 3: the selectors once matched anywhere, refusing path-only unstaging.
            foreach ($c in 'git reset HEAD -- docs/origin/a.md', 'git reset -- src/ORIG_HEAD.txt', 'git reset HEAD -- refs/x.md', 'git reset -- main/notes.md', 'git reset -- t3/a.md',
                'git reset HEAD -- upstream/a.md', 'git reset -- personal/a.md', 'git reset -- 1a2b.md', 'git reset -- FETCH_HEAD.md', 'git -C . reset -- origin/a.md',
                'git.exe reset HEAD -- main/a.md', 'git reset -q', 'git reset HEAD -- "a b.md"') {
                foreach ($tool in 'Bash', 'PowerShell') { Test-ClaudeDenied $tool $c | Should -BeFalse -Because "$tool $c" }
            }
            foreach ($c in 'git reset origin/main', 'git reset ORIG_HEAD', 'git reset refs/heads/main', 'git reset t3/x', 'git reset main~1', 'git reset -q origin/main',
                'git reset --quiet ORIG_HEAD', 'git -C . reset ORIG_HEAD', 'git.exe reset ORIG_HEAD', 'git reset REVERT_HEAD',
                'git reset HEAD@{2}', 'git reset 1a2b3c4 -- a.md') {
                foreach ($tool in 'Bash', 'PowerShell') { Test-ClaudeDenied $tool $c | Should -BeTrue -Because "$tool $c" }
            }
        }

        It 'Claude <Tool> rules deny quoted runner forms whose closing quote follows the target' -ForEach @(@{ Tool = 'Bash' }, @{ Tool = 'PowerShell' }) {
            # Static model only: whether Claude Code splits or unquotes a runner's script natively is live check L5.
            foreach ($c in 'pwsh -c "git push origin HEAD:main"', "pwsh -c 'git push origin HEAD:main'", 'pwsh -Command "git push origin main"', "pwsh -Command 'git push -u origin main'",
                'bash -c "git push origin main"', "bash -c 'git push origin HEAD:main'", 'bash -c "git push origin :main"', 'pwsh -c "git push origin --delete main"',
                'bash -c "git push origin t3/x --force"', "pwsh -c 'git push -f origin t3/x'", 'pwsh -Command "git push origin +HEAD"', 'bash -c "git reset --hard HEAD~1"',
                "pwsh -c 'git commit --amend'", 'pwsh -Command "git commit --amend --no-edit"', "bash -c 'git rebase -i HEAD~3'", 'pwsh -c "git rebase main"') {
                Test-ClaudeDenied $Tool $c | Should -BeTrue -Because $c
            }
        }

        It 'neither harness blocks the D9 thread, pull-request and read workflow' {
            foreach ($c in $script:Allowed) {
                foreach ($tool in 'Bash', 'PowerShell') { Test-ClaudeDenied $tool $c | Should -BeFalse -Because "$tool $c" }
                Test-CodexForbidden $c | Should -BeFalse -Because "codex $c"
            }
        }

        It 'Claude also covers the runner, option and late-flag forms the Codex rules file documents as unmatched (and its own over-blocks)' {
            foreach ($c in @($script:Cases['ClaudeOnly'])) {
                Test-ClaudeDenied 'Bash' $c | Should -BeTrue -Because $c
                Test-CodexForbidden $c | Should -BeFalse -Because "documented prefix limit: $c"
            }
            $text = Get-SwCodexRules
            $text | Should -Match '\(git -C <dir> push, rtk git push, env, cmd /c\)'
            $text | Should -Match 'git push origin <branch> --force'
            $text | Should -Match '\(git commit -m <msg> --amend\), a reset to an unlisted commit \(a SHA'
            $text | Should -Match 'an unquoted word with ~ \^ \{ \} \* \? \[ \] \$\s+# or a backtick \(git reset --hard HEAD~1\) leaves it unchecked'
        }
    }

    Context 'rendered files' {
        It 'Claude settings carry the hard limits for Bash and PowerShell, profile edit denies and .env asks, with no model or mode' {
            $r = Get-SwRender ([ordered]@{ project = 'U'; profile = 'unreal'; githubTier = 2; github = $true; users = @() })
            $s = ConvertFrom-SwJson $r.Files['.claude/settings.json']
            @($s.Keys) | Should -Be @('permissions')
            @($s['permissions']['deny'] | Where-Object { $_ -like 'Bash(*' }).Count | Should -Be @($s['permissions']['deny'] | Where-Object { $_ -like 'PowerShell(*' }).Count
            foreach ($rule in Get-SwClaudeDeny) { $s['permissions']['deny'] | Should -Contain $rule }
            $s['permissions']['deny'] | Should -Contain 'Edit(**/*.uasset)'
            $s['permissions']['deny'] | Should -Contain 'Edit(**/*.umap)'
            $s['permissions']['ask'] | Should -Be @('Read(**/.env)', 'Read(**/.env.*)')
            $s['permissions']['allow'] | Should -Be @('Skill')
            $r.Files['.claude/CLAUDE.md'] | Should -Be "@../AGENTS.md`n"
        }

        It 'Codex rules are forbidden prefix rules, each with a load-time example that matches its own pattern' {
            $text = Get-SwCodexRules
            $rules = @(Read-SwCodexRules $text)
            $rules.Count | Should -Be @(Get-SwCodexRuleBlocks).Count
            @($rules | Where-Object Decision -cne 'forbidden').Count | Should -Be 0
            foreach ($m in [regex]::Matches($text, '(?ms)^    pattern = (\[.*?\]),$.*?^    match = \["([^"]+)"\],$')) {
                Test-SwCodexRule (ConvertFrom-SwJson $m.Groups[1].Value) $m.Groups[2].Value | Should -BeTrue -Because $m.Groups[2].Value
            }
            $text | Should -Match 'Codex loads project rules only'
        }

        It 'no Claude rule contains a doubled space or ends in a lone quote after the program or verb' {
            # Live (2026-10-15, one Claude Code version), Bash(git  *) installed alone also denied git diff --stat, as if the
            # two spaces were read as one; Bash(git "*) and Bash(git '*) alone did not. Quote handling in patterns is
            # undocumented and that test did not show a quote-ending pattern denying its target, so both stay forbidden.
            foreach ($rule in Get-SwClaudeDeny) {
                $rule | Should -Not -Match '\s\s' -Because $rule
                $rule | Should -Not -Match '(git|reset)\s+["'']\*\)$' -Because $rule
            }
        }

        It 'hard limits are the same at every GitHub tier' {
            $files = foreach ($tier in 0, 1, 2) { (Get-SwRender ([ordered]@{ project = 'T'; profile = 'generic'; githubTier = $tier; github = $true; users = @() })).Files }
            foreach ($rel in '.claude/settings.json', '.codex/rules/workspace.rules') { $files[1][$rel] | Should -Be $files[0][$rel]; $files[2][$rel] | Should -Be $files[0][$rel] }
        }

        It 'the kit t3.json exposes the read-only tools as T3 Code project scripts' {
            $t3 = ConvertFrom-SwJson (Get-SwRender ([ordered]@{ project = 'T'; profile = 'generic'; github = $true; users = @() })).Files['t3.json']
            $t3['$schema'] | Should -Be 'https://t3.codes/schema/t3.json'
            @($t3['scripts'] | ForEach-Object { $_['command'] }) | Should -Be @('powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 validate', 'powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 doctor', 'powershell -NoProfile -ExecutionPolicy Bypass -File .sw/sw.ps1 context')
            foreach ($s in $t3['scripts']) { $s['icon'] | Should -BeIn @('play', 'test', 'lint', 'configure', 'build', 'debug'); $s.Contains('runOnWorktreeCreate') | Should -BeFalse }
        }
    }
}

Describe 'Sync and init lifecycle' {
    It 'fresh init (generic) then CLI validate exits 0' {
        $dir = New-SwProject 'freshGeneric' generic
        & $script:Shell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dir '.sw/sw.ps1') validate | Out-Null
        $LASTEXITCODE | Should -Be 0
    }

    It 'fresh init (unreal) then CLI validate exits 0' {
        $dir = New-SwProject 'freshUnreal' unreal
        & $script:Shell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dir '.sw/sw.ps1') validate | Out-Null
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

Describe 'Retired surface migration' {
    BeforeAll {
        function Get-Tree([string]$Dir) {
            (@(Get-ChildItem -LiteralPath $Dir -Recurse -File -Force | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } | Sort-Object FullName | ForEach-Object { "$($_.FullName):$((Get-FileHash -LiteralPath $_.FullName).Hash)" }) -join "`n")
        }
        function Set-OldInstall([string]$Dir) {
            # The owned outputs and choices an earlier kit left: OpenCode files, roles, the manager module, a merged
            # skill, Context7 and the provider-setup capability.
            $m = Read-SwJson (Join-Path $Dir '.sw/manifest.json')
            foreach ($rel in 'opencode.jsonc', '.opencode/agents/project-leader.md', '.opencode/commands/work.md', '.opencode/plugins/rtk.ts', '.sw/roles.json', '.sw/lib/Sw.Manager.psm1', '.agents/skills/free-models/SKILL.md') {
                Write-SwFile (Join-Path $Dir $rel) "old kit $rel`n"
                $m['files'][$rel] = Get-SwHash "old kit $rel`n"
            }
            $m['kitVersion'] = '0.3.0-dev'
            Write-SwFile (Join-Path $Dir '.sw/manifest.json') (ConvertTo-SwJson $m)
            $c = Get-SwConfig $Dir
            $c['context7'] = 'enabled'; $c['watcherIgnore'] = @('runs/**'); $c['selection']['capabilities'] = @('provider-setup')
            Write-SwFile (Join-Path $Dir '.sw/config.json') (ConvertTo-SwJson $c)
        }
    }

    It 'update removes unedited retired outputs, drops retired choices and validates' {
        $dir = New-SwProject "retire$(New-Id)"
        Set-OldInstall $dir
        (Test-SwValidate $dir).Output -join "`n" | Should -Match "Retired config key 'context7'"
        $out = (Update-SwProject -Path $dir) -join "`n"
        $global:LASTEXITCODE | Should -Be 0
        $out | Should -Match 'kit 0\.3\.0-dev -> '
        $out | Should -Match 'Retired config context7 removed'
        $out | Should -Match 'Retired capability provider-setup removed'
        foreach ($rel in 'opencode.jsonc', '.opencode/agents/project-leader.md', '.opencode/plugins/rtk.ts', '.sw/roles.json', '.sw/lib/Sw.Manager.psm1', '.agents/skills/free-models/SKILL.md') { Test-Path (Join-Path $dir $rel) | Should -BeFalse -Because $rel }
        $c = Get-SwConfig $dir
        foreach ($k in 'context7', 'watcherIgnore') { $c.Contains($k) | Should -BeFalse }
        @($c['selection']['capabilities']).Count | Should -Be 0
        $files = (Read-SwJson (Join-Path $dir '.sw/manifest.json'))['files']
        @($files.Keys | Where-Object { $_ -cin @(Get-SwRetiredOutputs) }).Count | Should -Be 0
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 0
        ($result.Output -join "`n") | Should -Not -Match 'WARNING'
    }

    It 'an edited retired output keeps its bytes and is released to the project once, so update and validate succeed' {
        $dir = New-SwProject "retireEdit$(New-Id)"
        Set-OldInstall $dir
        Write-SwFile (Join-Path $dir 'opencode.jsonc') "old kit opencode.jsonc`nmy edit`n"
        $out = (Update-SwProject -Path $dir) -join "`n"
        $global:LASTEXITCODE | Should -Be 0
        $out | Should -Match '(?m)^released\s+opencode\.jsonc$'
        $out | Should -Match 'opencode\.jsonc kept as your own file'
        Read-SwText (Join-Path $dir 'opencode.jsonc') | Should -Be "old kit opencode.jsonc`nmy edit`n"
        (Read-SwJson (Join-Path $dir '.sw/manifest.json'))['files'].Contains('opencode.jsonc') | Should -BeFalse
        (Get-SwConfig $dir).Contains('context7') | Should -BeFalse
        (Test-SwValidate $dir).ExitCode | Should -Be 0
        $again = (Update-SwProject -Path $dir) -join "`n"
        $global:LASTEXITCODE | Should -Be 0
        $again | Should -Not -Match 'opencode\.jsonc'
    }

    It 'an edited retired skill is released as project-owned and still discoverable, with how to stop it loading' {
        $dir = New-SwProject "retireSkill$(New-Id)"
        Set-OldInstall $dir
        $rel = '.agents/skills/free-models/SKILL.md'
        $mine = "---`nname: free-models`ndescription: My edited copy of a retired kit skill.`n---`n`nMy own steps.`n"
        Write-SwFile (Join-Path $dir $rel) $mine
        $out = (Update-SwProject -Path $dir) -join "`n"
        $global:LASTEXITCODE | Should -Be 0
        $out | Should -Match '(?m)^released\s+\.agents/skills/free-models/SKILL\.md$'
        $out | Should -Match 'free-models/SKILL\.md kept as your own file: a retired kit skill with local edits, now project-owned and still discoverable'
        $out | Should -Match 'delete it or move it out of \.agents/skills and \.claude/skills to stop it loading'
        $out | Should -Not -Match 'free-models/SKILL\.md kept as your own file: a retired kit output'
        Read-SwText (Join-Path $dir $rel) | Should -Be $mine
        (Read-SwJson (Join-Path $dir '.sw/manifest.json'))['files'].Contains($rel) | Should -BeFalse
        (Test-SwValidate $dir).ExitCode | Should -Be 0
    }

    It 'an edited non-retired file the kit dropped still stays owned and unresolved' {
        $dir = New-SwProject "orphan$(New-Id)"
        $m = Read-SwJson (Join-Path $dir '.sw/manifest.json'); $m['files']['.sw/old-guide.md'] = Get-SwHash "old`n"
        Write-SwFile (Join-Path $dir '.sw/manifest.json') (ConvertTo-SwJson $m)
        Write-SwFile (Join-Path $dir '.sw/old-guide.md') "old`nedited`n"
        InModuleScope Sw.Kit { $script:Moved['.sw/old-guide.md'] = '.sw/workspace.md' }
        try {
            $plan = Sync-SwProject -Root $dir -Config (Get-SwConfig $dir) 3> $null
            ($plan | Where-Object Path -eq '.sw/old-guide.md').Action | Should -Be 'orphan-kept'
            $global:LASTEXITCODE | Should -Be 1
        } finally { InModuleScope Sw.Kit { $script:Moved.Remove('.sw/old-guide.md') } }
    }

    It 'update refuses while the earlier local Claude adapter is installed, writing nothing' {
        $dir = New-SwProject "adapter$(New-Id)"
        Write-SwFile (Join-Path $dir '.claude/.sw-generated') "Generated by SuperWorkspace.`nsw-ownership: 1`n"
        $before = Get-Tree $dir
        { Update-SwProject -Path $dir } | Should -Throw '*nothing was written*sw.ps1 claude disable*'
        { Update-SwProject -Path $dir -Adopt -Force } | Should -Throw '*Claude adapter from an earlier kit*'
        Get-Tree $dir | Should -Be $before
        ((Test-SwValidate $dir).Output -join "`n") | Should -Match 'Retired local Claude adapter present'
    }

    It 'a per-user OpenCode map from an earlier kit is reported and left alone' {
        $dir = New-SwProject "localMap$(New-Id)"
        Write-SwFile (Join-Path $dir '.opencode/opencode.jsonc') '{"agents":{}}'
        $out = (Update-SwProject -Path $dir) -join "`n"
        $out | Should -Match 'Retired local OpenCode file left in place and no longer ignored by the kit block: \.opencode/opencode\.jsonc'
        Read-SwText (Join-Path $dir '.opencode/opencode.jsonc') | Should -Be '{"agents":{}}'
    }

    It 'retired commands are gone from the CLI; the project copy keeps validate, doctor, context, comms, user, gh and usage' {
        $dir = New-SwProject "cli$(New-Id)"
        $help = (& $script:Shell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dir '.sw/sw.ps1') help) -join "`n"
        foreach ($c in 'validate', 'doctor', 'context', 'comms', 'user', 'gh', 'usage') { $help | Should -Match "(?m)^  $c " }
        $help | Should -Match '(?m)^  usage +Workspace estimates: RTK output savings and the static startup budget; not provider request telemetry$'
        foreach ($c in 'init', 'update', 'global', 'claude', 'tiers', 'manager', 'remote', 'session') { $help | Should -Not -Match "(?m)^  $c " }
        $kitHelp = (& $script:Shell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'sw.ps1') help) -join "`n"
        foreach ($c in 'init', 'update', 'global', 'validate', 'doctor', 'context', 'comms') { $kitHelp | Should -Match "(?m)^  $c " }
        foreach ($c in 'claude', 'tiers', 'manager', 'remote', 'session') {
            (& $script:Shell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'sw.ps1') $c) -join "`n" | Should -Match "Unknown command: $c"
            $LASTEXITCODE | Should -Be 2
        }
        Test-Path (Join-Path $RepoRoot 'lib/Sw.Manager.psm1') | Should -BeFalse
    }
}

Describe 'Public adoption' {
    BeforeAll {
        function Get-AdoptionTree([string]$Root) {
            if (-not (Test-Path -LiteralPath $Root)) { return 'absent' }
            $items = foreach ($f in Get-ChildItem -LiteralPath $Root -Recurse -Force | Sort-Object FullName) {
                $rel = (Get-SwRelativePath $Root $f.FullName).Replace('\', '/')
                if ($f.PSIsContainer) { "dir:$rel" } else { "file:${rel}:$((Get-FileHash -LiteralPath $f.FullName).Hash)" }
            }
            $items -join "`n"
        }
        function New-AdoptionTarget([switch]$Git) {
            $d = Join-Path $TestDrive "host$(New-Id)"
            Write-SwFile (Join-Path $d 'app.txt') 'host-app'
            Write-SwFile (Join-Path $d 'app.tests.ps1') 'if ((Get-Content -LiteralPath (Join-Path $PSScriptRoot "app.txt") -Raw) -ne "host-app") { throw "application regression" }'
            if ($Git) {
                Invoke-SwNative git @('-C', $d, 'init', '-b', 'develop') | Out-Null
                if ($LASTEXITCODE) { throw 'Fixture git init failed' }
                git -C $d config user.name tester
                git -C $d config user.email tester@example.invalid
            }
            $d
        }
        function Get-HostRender([string]$Policy = 'host') {
            Get-SwRender ([ordered]@{ project = 'H'; profile = 'generic'; githubTier = 0; github = $false; users = @(); records = 'local'; gitPolicy = $Policy })
        }
    }

    It 'fresh <Profile> defaults to host policy and local records; preview creates nothing' -ForEach @(
        @{ Profile = 'generic' }, @{ Profile = 'research' }, @{ Profile = 'unreal' }
    ) {
        $d = Join-Path $TestDrive "fresh$Profile$(New-Id)"
        Initialize-SwProject $d -Profile $Profile -WhatIf | Out-Null
        Get-AdoptionTree $d | Should -Be 'absent'
        Initialize-SwProject $d -Profile $Profile | Out-Null
        $c = Get-SwConfig $d
        $c['gitPolicy'] | Should -Be 'host'
        $c['records'] | Should -Be 'local'
        $c['selection']['version'] | Should -Be 1
        git -C $d check-ignore -q -- .sw/comms/tasks/approval.md
        $LASTEXITCODE | Should -Be 0
        git -C $d ls-files -- .sw/comms | Should -BeNullOrEmpty
        Read-SwText (Join-Path $d '.sw/LICENSE') | Should -Be (Read-SwText (Join-Path $RepoRoot 'LICENSE'))
        Read-SwText (Join-Path $d '.sw/THIRD_PARTY_NOTICES.md') | Should -Be (Read-SwText (Join-Path $RepoRoot 'THIRD_PARTY_NOTICES.md'))
        (Test-SwValidate $d).ExitCode | Should -Be 0
    }

    It 'preserves host application/text/extras and Git state in an existing <Kind> root' -ForEach @(
        @{ Kind = 'Git'; UseGit = $true }, @{ Kind = 'non-Git'; UseGit = $false }
    ) {
        $d = New-AdoptionTarget -Git:$UseGit
        Write-SwFile (Join-Path $d 'AGENTS.md') "# Host rules`n`n## Project identity`nHost app; Startup state is docs/state.md. No task approved.`n`n## Git workflow`nUse develop and reviewed topic branches.`n"
        Write-SwFile (Join-Path $d '.gitignore') "host-cache/`n"
        Write-SwFile (Join-Path $d '.gitattributes') "*.txt text`n"
        Write-SwFile (Join-Path $d '.opencode/agents/host-helper.md') "---`ndescription: Host-owned helper`nmode: subagent`n---`nHost helper.`n"
        Write-SwFile (Join-Path $d '.opencode/plugins/host-plugin.ts') '// host plugin fixture, not executed'
        Write-SwFile (Join-Path $d '.github/workflows/host.yml') "name: host`non: workflow_dispatch`n"
        $preserved = @('app.txt', 'app.tests.ps1', '.opencode/agents/host-helper.md', '.opencode/plugins/host-plugin.ts', '.github/workflows/host.yml')
        $hashes = @($preserved | ForEach-Object { (Get-FileHash (Join-Path $d $_)).Hash })
        $agents = Read-SwText (Join-Path $d 'AGENTS.md')
        $gitTree = if ($UseGit) { Get-AdoptionTree (Join-Path $d '.git') }
        & (Join-Path $d 'app.tests.ps1')
        $tree = Get-AdoptionTree $d
        Initialize-SwProject $d -Profile generic -NoGitHub -WhatIf | Out-Null
        Get-AdoptionTree $d | Should -BeExactly $tree
        Initialize-SwProject $d -Profile generic -NoGitHub | Out-Null
        @($preserved | ForEach-Object { (Get-FileHash (Join-Path $d $_)).Hash }) | Should -Be $hashes
        (Read-SwText (Join-Path $d 'AGENTS.md')).StartsWith($agents) | Should -BeTrue
        Read-SwText (Join-Path $d '.gitignore') | Should -Match '\Ahost-cache/\n'
        Read-SwText (Join-Path $d '.gitattributes') | Should -Be "*.txt text`n"
        (Get-SwConfig $d)['github'] | Should -BeFalse
        Test-Path (Join-Path $d '.github/workflows/sw-validate.yml') | Should -BeFalse
        if ($UseGit) {
            Get-AdoptionTree (Join-Path $d '.git') | Should -BeExactly $gitTree
            git -C $d branch --show-current | Should -Be 'develop'
        } else { git -C $d branch --show-current | Should -Be 'main' }
        & (Join-Path $d 'app.tests.ps1')
        (Test-SwValidate $d).ExitCode | Should -Be 0
    }

    It 'treats host OpenCode configuration <Rel> as host-owned: kept byte-identical, never refused or validated' -ForEach @(
        @{ Rel = 'opencode.json'; Body = '{"mcp":{"host":{}}}' },
        @{ Rel = 'opencode.jsonc'; Body = "{ // host config`n}" },
        @{ Rel = '.opencode/opencode.jsonc'; Body = "{ // host config`n}" },
        @{ Rel = '.opencode/agent/host.md'; Body = 'legacy' },
        @{ Rel = '.opencode/skills/host/SKILL.md'; Body = 'legacy' }
    ) {
        $d = New-AdoptionTarget
        Write-SwFile (Join-Path $d $Rel) $Body
        $hash = (Get-FileHash (Join-Path $d $Rel)).Hash
        Initialize-SwProject $d | Out-Null
        (Get-FileHash (Join-Path $d $Rel)).Hash | Should -Be $hash
        (Read-SwJson (Join-Path $d '.sw/manifest.json'))['files'].Contains($Rel) | Should -BeFalse
        (Test-SwValidate $d).ExitCode | Should -Be 0
    }

    It 'refuses unmanaged <Rel> without whole-tree/Git effects' -ForEach @(
        @{ Rel = '.claude/settings.json'; Body = '{"permissions":{"allow":["Bash(npm test:*)"]}}' },
        @{ Rel = '.claude/CLAUDE.md'; Body = "Host Claude rules.`n" },
        @{ Rel = '.claude/skills/work/SKILL.md'; Body = 'host skill' },
        @{ Rel = '.codex/rules/workspace.rules'; Body = 'prefix_rule(pattern = ["rm"], decision = "prompt")' },
        @{ Rel = 't3.json'; Body = '{"scripts":[]}' },
        @{ Rel = '.agents/skills/work/SKILL.md'; Body = 'host skill' },
        @{ Rel = '.github/workflows/sw-validate.yml'; Body = 'host workflow' }
    ) {
        $d = New-AdoptionTarget
        Write-SwFile (Join-Path $d $Rel) $Body
        $tree = Get-AdoptionTree $d
        { Initialize-SwProject $d } | Should -Throw '*not SuperWorkspace-managed*nothing was written*'
        Get-AdoptionTree $d | Should -BeExactly $tree
        Test-Path (Join-Path $d '.git') | Should -BeFalse
    }

    It 'refuses a downgrade before initializing Git or changing the config/manifest/tree' {
        $d = New-AdoptionTarget
        Write-SwFile (Join-Path $d '.sw/config.json') '{"project":"legacy","profile":"generic","githubTier":0,"users":[]}'
        Write-SwFile (Join-Path $d '.sw/manifest.json') '{"kitVersion":"99.0.0","files":{}}'
        $tree = Get-AdoptionTree $d
        { Initialize-SwProject $d -Name changed } | Should -Throw '*newer than this kit*nothing was written*'
        Get-AdoptionTree $d | Should -BeExactly $tree
        Test-Path (Join-Path $d '.git') | Should -BeFalse
    }

    It 'refuses a subpackage and an absent nested target without changing the parent repo' {
        $parent = New-AdoptionTarget -Git
        Write-SwFile (Join-Path $parent 'package/app.txt') 'subpackage'
        $tree = Get-AdoptionTree $parent
        foreach ($rel in 'package', 'absent') {
            { Initialize-SwProject (Join-Path $parent $rel) } | Should -Throw '*inside an existing Git repository*nothing was written*'
            Get-AdoptionTree $parent | Should -BeExactly $tree
        }
    }

    It 'Adopt is explicit backup-and-replace, not a settings merge; preview writes nothing' {
        $d = New-AdoptionTarget -Git
        $body = '{"permissions":{"allow":["Bash(npm test:*)"]},"model":"host-fixture"}'
        Write-SwFile (Join-Path $d '.claude/settings.json') $body
        $tree = Get-AdoptionTree $d
        Initialize-SwProject $d -Adopt -WhatIf | Out-Null
        Get-AdoptionTree $d | Should -BeExactly $tree
        Initialize-SwProject $d -Adopt | Out-Null
        $backups = @(Get-ChildItem (Join-Path $d '.sw/backup') -Recurse -File -Force -Filter settings.json)
        $backups.Count | Should -Be 1
        Read-SwText $backups[0].FullName | Should -BeExactly $body
        Read-SwText (Join-Path $d '.claude/settings.json') | Should -Not -Match 'host-fixture'
        (Test-SwValidate $d).ExitCode | Should -Be 0
    }

    It 'host guidance does not prescribe workspace branches/main integration and rejects invalid policy' {
        $r = Get-HostRender
        $r.AgentsCore | Should -Match "project's documented branch"
        $r.AgentsCore | Should -Not -Match 'Branches are `main` plus T3 Code'
        $collab = $r.Files['.sw/collaboration.md']
        $collab | Should -Not -Match '\bmain\b|first fast-forward push|<user>/<user>-worktree'
        $collab | Should -Match "host project's review"
        { Get-HostRender 'custom' } | Should -Throw "*'gitPolicy' must be*"
    }

    It 'host publication stays human-owned at tier <Tier> with <Records> records; workspace keeps D9' -ForEach @(
        @{ Tier = 0; Records = 'local' }, @{ Tier = 1; Records = 'local' }, @{ Tier = 2; Records = 'local' },
        @{ Tier = 0; Records = 'tracked' }, @{ Tier = 1; Records = 'tracked' }, @{ Tier = 2; Records = 'tracked' }
    ) {
        $config = [ordered]@{ project = 'H'; profile = 'generic'; githubTier = $Tier; github = $true; users = @(); records = $Records; gitPolicy = 'host' }
        $hostCollab = (Get-SwRender $config).Files['.sw/collaboration.md']
        $config['gitPolicy'] = 'workspace'
        $workCollab = (Get-SwRender $config).Files['.sw/collaboration.md']
        $finishPattern = '(?s)## Finish and publish\n.*?(?=## Integrate)'
        $hostFinish = [regex]::Match($hostCollab, $finishPattern).Value
        $workFinish = [regex]::Match($workCollab, $finishPattern).Value
        $hostFinish | Should -Match "Follow the host project's commit and publication workflow"
        $hostFinish | Should -Match 'Humans own\s+publication; agents never push or merge a PR'
        $hostCollab | Should -Not -Match 't3/|by the agent pushing its own'
        $hostFinish | Should -Not -Match 'GitHub tier 2|draft pull request'
        foreach ($text in 'Stage selected task paths only', 'inspect `git diff --cached`', 'and secrets', 'Conventional Commit') {
            $hostFinish | Should -Match ([regex]::Escape($text))
        }
        $hostFinish | Should -Match 'local commit is local until\s+the remote tip is confirmed'
        $receiptPattern = '(?s)```text\n.*?```'
        [regex]::Match($hostFinish, $receiptPattern).Value | Should -BeExactly (
            [regex]::Match($workFinish, $receiptPattern).Value.Replace('refs/heads/t3/<name>', 'refs/heads/<assigned-branch>').Replace('Base: <full main SHA>', 'Base: <full host integration SHA>')
        )
        $source = Read-SwText (Join-Path $RepoRoot 'project/base/.sw/collaboration.md')
        $workFinish | Should -BeExactly ([regex]::Match($source, $finishPattern).Value)
        $workFinish | Should -Match 'by the agent pushing its own `t3/` branch and opening a draft pull request'
    }

    It 'the installed AGENTS.md carries D9 routing once under workspace policy and none under host policy' {
        $hostDir = New-AdoptionTarget -Git
        Initialize-SwProject $hostDir | Out-Null
        $workDir = New-AdoptionTarget -Git
        Initialize-SwProject $workDir -GitPolicy workspace | Out-Null
        $hostAgents = Read-SwText (Join-Path $hostDir 'AGENTS.md')
        $workAgents = Read-SwText (Join-Path $workDir 'AGENTS.md')
        $hostAgents | Should -Not -Match 't3/'
        $hostAgents | Should -Not -Match 'commits on `main`'
        $hostAgents | Should -Not -Match 'Pull requests: at GitHub tier 2'
        foreach ($text in 'commits on `main`', 'Pull requests: at GitHub tier 2', '`t3/<name>` worktree thread and a pull request') {
            [regex]::Matches($workAgents, [regex]::Escape($text)).Count | Should -Be 1 -Because $text
        }
        foreach ($text in 'Commit as you go', 'Stage selected paths only', 'Hard limits, never crossed', '`git commit --amend`, `git rebase`, `git pull --rebase` and a `git reset`') {
            [regex]::Matches($hostAgents, [regex]::Escape($text)).Count | Should -Be 1 -Because "host: $text"
            [regex]::Matches($workAgents, [regex]::Escape($text)).Count | Should -Be 1 -Because "workspace: $text"
        }
    }

    It 'the installed AGENTS.md tells agents to hand the owner directory-independent commands' {
        $d = New-AdoptionTarget -Git
        Initialize-SwProject $d | Out-Null
        $agents = Read-SwText (Join-Path $d 'AGENTS.md')
        foreach ($text in 'give the exact copy-paste commands', '`git -C <repo-path>`', '`gh ... --repo <owner>/<repo>`', 'never rely on the shell''s current directory', 'Hand the owner the exact command (Authority) instead.') {
            [regex]::Matches($agents, [regex]::Escape($text)).Count | Should -Be 1 -Because $text
        }
    }

    It 'legacy update/init retain absent fields; explicit choices are previewed and opt in separately' {
        $d = New-AdoptionTarget -Git
        Write-SwFile (Join-Path $d '.sw/config.json') '{"project":"legacy","profile":"generic","githubTier":0,"users":[]}'
        Initialize-SwProject $d | Out-Null
        Update-SwProject $d | Out-Null
        $c = Get-SwConfig $d
        $c.Contains('gitPolicy') | Should -BeFalse
        $c.Contains('records') | Should -BeFalse
        Get-SwGitPolicy $c | Should -Be 'workspace'
        Read-SwText (Join-Path $d 'AGENTS.md') | Should -Match 'Branches are `main` plus T3 Code'
        $tree = Get-AdoptionTree $d
        Update-SwProject $d -GitPolicy host -Records local -WhatIf | Out-Null
        Get-AdoptionTree $d | Should -BeExactly $tree
        Update-SwProject $d -GitPolicy host -Records local | Out-Null
        Update-SwProject $d | Out-Null
        (Get-SwConfig $d)['gitPolicy'] | Should -Be 'host'
        (Get-SwConfig $d)['records'] | Should -Be 'local'
        (Test-SwValidate $d).ExitCode | Should -Be 0
    }

    It 'explicit tracked/workspace opt-in is preserved; local choice never silently untracks records' {
        $d = New-AdoptionTarget -Git
        Initialize-SwProject $d -GitPolicy workspace -Records tracked | Out-Null
        Write-SwFile (Join-Path $d '.sw/comms/tasks/test/approval.md') 'synthetic public approval'
        git -C $d add -- .sw/comms/tasks/test/approval.md
        Update-SwProject $d | Out-Null
        (Get-SwConfig $d)['records'] | Should -Be 'tracked'
        (Get-SwConfig $d)['gitPolicy'] | Should -Be 'workspace'
        $output = (Update-SwProject $d -Records local) -join "`n"
        $output | Should -Match 'existing tracked files/history are not removed'
        git -C $d ls-files -- .sw/comms/tasks/test/approval.md | Should -Be '.sw/comms/tasks/test/approval.md'
    }

    It 'host doctor/user do not invent a branch policy (native tool discovery stubbed)' {
        $d = New-AdoptionTarget -Git
        Initialize-SwProject $d | Out-Null
        $out = (Add-SwUser alice -Path $d) -join "`n"
        $out | Should -Match 'project-owned Git onboarding'
        $out | Should -Not -Match 'git switch|origin/main'
        Mock -ModuleName Sw.Project Get-SwToolProbe { [pscustomobject]@{ State = 'missing'; Version = $null } }
        Mock -ModuleName Sw.Project Get-SwCodexTrust { 'unknown' }
        $out = (Test-SwDoctor -Path $d -User alice) -join "`n"
        $out | Should -Match 'develop \(host Git policy;.*not checked here'
        $out | Should -Not -Match 'expected alice/alice-worktree|git switch|Branch protection on main'
    }

    It 'an invalid Git policy refuses contributor recording before any effects' {
        $d = New-AdoptionTarget -Git
        Initialize-SwProject $d | Out-Null
        $c = Get-SwConfig $d; $c['gitPolicy'] = 'custom'
        Write-SwFile (Join-Path $d '.sw/config.json') (ConvertTo-SwJson $c)
        $tree = Get-AdoptionTree $d
        { Add-SwUser alice -Path $d } | Should -Throw "*'gitPolicy' must be*"
        Get-AdoptionTree $d | Should -BeExactly $tree
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
        $local.Files['.sw/collaboration.md'] | Should -Match 'kept local by `records: local` \(git-ignored for new records\)'
        $local.Files['.sw/collaboration.md'] | Should -Match 'does not untrack existing records'
        $local.Files['.sw/collaboration.md'] | Should -Not -Match 'first fast-forward push wins|published by push and received|event is on `main`'
        $local.Files['.sw/collaboration.md'] | Should -Match 'local-only records require an explicit owner-approved handoff'
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
        @{ Name = 'unsupported frontmatter scalar'; Match = 'Unsupported scalar'; Mutate = {
                param($d) $f = Join-Path $d '.agents/skills/minimal-change/SKILL.md'
                Write-SwFile $f ((Read-SwText $f) -replace '(?m)^description:.*$', 'description: [bad, value]')
            }
        }
        @{ Name = 'unknown skill frontmatter key'; Match = 'Unknown or duplicate key: model'; Mutate = {
                param($d) $f = Join-Path $d '.agents/skills/minimal-change/SKILL.md'
                Write-SwFile $f ((Read-SwText $f) -replace '(?m)^description:', "model: opus`ndescription:")
            }
        }
        @{ Name = 'missing kit skill'; Match = 'Missing skill: minimal-change'; Mutate = {
                param($d) Remove-Item -LiteralPath (Join-Path $d '.agents/skills/minimal-change') -Recurse -Force
            }
        }
        @{ Name = 'user-invoked skill opened to model invocation'; Match = 'Skill work must stay user-invoked'; Mutate = {
                param($d) foreach ($root in '.agents', '.claude') { $f = Join-Path $d "$root/skills/work/SKILL.md"; Write-SwFile $f ((Read-SwText $f) -replace "(?m)^disable-model-invocation: true`n", '') }
            }
        }
        @{ Name = 'Codex explicit-only metadata removed'; Match = 'Skill review must stay explicit-only in Codex: \.agents/skills/review/agents/openai\.yaml'; Mutate = {
                param($d) foreach ($root in '.agents', '.claude') { Remove-Item -LiteralPath (Join-Path $d "$root/skills/review/agents") -Recurse -Force }
            }
        }
        @{ Name = 'Codex explicit-only metadata opened to implicit invocation'; Match = 'Skill work must stay explicit-only in Codex'; Mutate = {
                param($d) foreach ($root in '.agents', '.claude') { $f = Join-Path $d "$root/skills/work/agents/openai.yaml"; Write-SwFile $f ((Read-SwText $f).Replace('allow_implicit_invocation: false', 'allow_implicit_invocation: true')) }
            }
        }
        @{ Name = 'Claude skill copy edited'; Match = 'Claude skill copy differs or is missing: \.claude/skills/minimal-change/SKILL\.md'; Mutate = {
                param($d) $f = Join-Path $d '.claude/skills/minimal-change/SKILL.md'; Write-SwFile $f ((Read-SwText $f) + "drift`n")
            }
        }
        @{ Name = 'Claude skill copy missing'; Match = 'Claude skill copy differs or is missing: \.claude/skills/review/SKILL\.md'; Mutate = {
                param($d) Remove-Item -LiteralPath (Join-Path $d '.claude/skills/review') -Recurse -Force
            }
        }
        @{ Name = 'Claude import not resolving to the root AGENTS.md'; Match = 'Claude import \.claude/CLAUDE\.md must be @\.\./AGENTS\.md'; Mutate = {
                param($d) Write-SwFile (Join-Path $d '.claude/CLAUDE.md') "@AGENTS.md`n"
            }
        }
        @{ Name = 'model pin added to Claude settings'; Match = 'forbidden shared pin: model'; Mutate = {
                param($d) $f = Join-Path $d '.claude/settings.json'; $s = Read-SwJson $f; $s['model'] = 'opus'; Write-SwFile $f (ConvertTo-SwJson $s)
            }
        }
        @{ Name = 'effort pinned in Claude settings'; Match = 'must be model-free: effort'; Mutate = {
                param($d) $f = Join-Path $d '.claude/settings.json'; $s = Read-SwJson $f; $s['effortLevel'] = 'high'; Write-SwFile $f (ConvertTo-SwJson $s)
            }
        }
        @{ Name = 'JSONC comment in Claude settings'; Match = 'must stay strict JSON'; Mutate = {
                param($d) $f = Join-Path $d '.claude/settings.json'; Write-SwFile $f ((Read-SwText $f) -replace '^\{', "{`n  // comment")
            }
        }
        @{ Name = 'blanket Bash allow'; Match = 'Claude must not allow Bash\(\*\)'; Mutate = {
                param($d) $f = Join-Path $d '.claude/settings.json'; $s = Read-SwJson $f; $s['permissions']['allow'] = @('Skill', 'Bash(*)'); Write-SwFile $f (ConvertTo-SwJson $s)
            }
        }
        @{ Name = 'one Claude hard limit removed'; Match = 'Claude hard limit missing from \.claude/settings\.json: PowerShell\(\*gh secret\*\)'; Mutate = {
                param($d) $f = Join-Path $d '.claude/settings.json'; $s = Read-SwJson $f; $s['permissions']['deny'] = @($s['permissions']['deny'] | Where-Object { $_ -cne 'PowerShell(*gh secret*)' }); Write-SwFile $f (ConvertTo-SwJson $s)
            }
        }
        @{ Name = 'every Claude force-push rule removed'; Match = 'STATIC claude Bash \[git push --force\]: expected deny, got no deny'; Mutate = {
                param($d) $f = Join-Path $d '.claude/settings.json'; $s = Read-SwJson $f; $s['permissions']['deny'] = @($s['permissions']['deny'] | Where-Object { $_ -notlike 'Bash(*git`*push*' }); Write-SwFile $f (ConvertTo-SwJson $s)
            }
        }
        @{ Name = 'Claude settings deleted'; Match = 'Missing \.claude/settings\.json \(run sw update\)'; Mutate = {
                param($d) Remove-Item -LiteralPath (Join-Path $d '.claude/settings.json') -Force
            }
        }
        @{ Name = 'one Codex hard limit removed'; Match = 'Codex hard limit missing from \.codex/rules/workspace\.rules: pattern = \[\["gh", "gh\.exe"\], \["ruleset"'; Mutate = {
                param($d) $f = Join-Path $d '.codex/rules/workspace.rules'; $t = Read-SwText $f
                Write-SwFile $f ([regex]::Replace($t, '(?s)prefix_rule\(\n    pattern = \[\["gh", "gh\.exe"\], \["ruleset".*?\n\)\n\n?', ''))
            }
        }
        @{ Name = 'Codex force-push rules weakened to prompt'; Match = 'STATIC codex \[git push --force\]: expected forbidden, got not forbidden'; Mutate = {
                param($d) $f = Join-Path $d '.codex/rules/workspace.rules'; $t = Read-SwText $f
                Write-SwFile $f ([regex]::Replace($t, '(?s)(pattern = \[\["git", "git\.exe"\], "push", \["--force".*?)decision = "forbidden"', '$1decision = "prompt"'))
            }
        }
        @{ Name = 'Codex rules deleted'; Match = 'Missing \.codex/rules/workspace\.rules \(run sw update\)'; Mutate = {
                param($d) Remove-Item -LiteralPath (Join-Path $d '.codex/rules/workspace.rules') -Force
            }
        }
        @{ Name = 't3.json script removed'; Match = 't3\.json must keep the doctor script'; Mutate = {
                param($d) $f = Join-Path $d 't3.json'; $t = Read-SwJson $f; $t['scripts'] = @($t['scripts'] | Where-Object { $_['command'] -notlike '*doctor' }); Write-SwFile $f (ConvertTo-SwJson $t)
            }
        }
        @{ Name = 'settings keys differing only in letter case'; Match = 'JSON keys that differ only in letter case are not supported: \.claude/settings\.json'; Mutate = {
                param($d) $f = Join-Path $d '.claude/settings.json'
                Write-SwFile $f ((Read-SwText $f) -replace '^\{', '{ "env": { "HTTP_PROXY": "a", "http_proxy": "b" },')
            }
        }
        @{ Name = 't3.json script running another file'; Match = 't3\.json must keep the validate script: powershell -NoProfile -ExecutionPolicy Bypass -File \.sw/sw\.ps1 validate'; Mutate = {
                param($d) $f = Join-Path $d 't3.json'; $t = Read-SwJson $f
                foreach ($s in $t['scripts']) { $s['command'] = $s['command'].Replace('.sw/sw.ps1 validate', 'other.ps1 validate') }
                Write-SwFile $f (ConvertTo-SwJson $t)
            }
        }
        @{ Name = 'absolute path in t3.json'; Match = 't3\.json.*absolute machine path'; Mutate = {
                param($d) $f = Join-Path $d 't3.json'; $t = Read-SwJson $f; $t['iconPath'] = 'C:\x\icon.png'; Write-SwFile $f (ConvertTo-SwJson $t)
            }
        }
        @{ Name = 't3.json deleted'; Match = 'Missing t3\.json'; Mutate = {
                param($d) Remove-Item -LiteralPath (Join-Path $d 't3.json') -Force
            }
        }
        @{ Name = 'local model tier table tracked by git'; Match = 'Per-user file must be untracked and git-ignored: \.sw/models\.local\.md'; Mutate = {
                param($d) Write-SwFile (Join-Path $d '.sw/models.local.md') "| tier | model |`n"; git -C $d add -f .sw/models.local.md | Out-Null
            }
        }
        @{ Name = 'Claude local settings tracked by git'; Match = 'Per-user file must be untracked and git-ignored: \.claude/settings\.local\.json'; Mutate = {
                param($d) Write-SwFile (Join-Path $d '.claude/settings.local.json') '{}'; git -C $d add -f .claude/settings.local.json | Out-Null
            }
        }
        @{ Name = 'startupBudgetBytes set tiny'; Match = 'Startup budget exceeded for session'; Mutate = {
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
        @{ Name = 'githubTier outside 0-2'; Match = 'githubTier must be the supported integer 0, 1 or 2'; Mutate = {
                param($d) $f = Join-Path $d '.sw/config.json'; $c = Read-SwJson $f; $c['githubTier'] = 3; Write-SwFile $f (ConvertTo-SwJson $c)
            }
        }
    ) {
        & $Mutate $dir
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 1
        ($result.Output -join "`n") | Should -Match $Match
    }

    It 'a profile edit deny removed from the Unreal Claude settings fails validation' {
        $u = New-SwProject "negUnreal$(New-Id)" unreal
        $f = Join-Path $u '.claude/settings.json'; $s = Read-SwJson $f
        $s['permissions']['deny'] = @($s['permissions']['deny'] | Where-Object { $_ -cne 'Edit(**/*.umap)' }); Write-SwFile $f (ConvertTo-SwJson $s)
        $result = Test-SwValidate $u
        $result.ExitCode | Should -Be 1
        ($result.Output -join "`n") | Should -Match 'Claude profile edit deny missing from \.claude/settings\.json: Edit\(\*\*/\*\.umap\)'
    }

    It 't3.json scripts may name either shell, with or without the execution policy bypass' {
        $f = Join-Path $dir 't3.json'; $t = Read-SwJson $f
        $forms = @('pwsh -NoProfile -File', 'powershell.exe -NoProfile -File', 'pwsh -NoProfile -ExecutionPolicy Bypass -File')
        for ($i = 0; $i -lt 3; $i++) { $t['scripts'][$i]['command'] = $t['scripts'][$i]['command'].Replace('powershell -NoProfile -ExecutionPolicy Bypass -File', $forms[$i]) }
        Write-SwFile $f (ConvertTo-SwJson $t)
        (Test-SwValidate $dir).ExitCode | Should -Be 0
    }

    It 'stricter project settings and extra project rules files still validate' {
        $f = Join-Path $dir '.claude/settings.json'; $s = Read-SwJson $f
        $s['permissions']['deny'] = @($s['permissions']['deny']) + 'Bash(git push *)'
        $s['permissions']['allow'] = @($s['permissions']['allow']) + 'Bash(npm test *)'
        Write-SwFile $f (ConvertTo-SwJson $s)
        Write-SwFile (Join-Path $dir '.codex/rules/project.rules') "prefix_rule(`n    pattern = [`"git`", `"push`"],`n    decision = `"prompt`",`n)`n"
        (Test-SwValidate $dir).ExitCode | Should -Be 0
    }

    It 'a project-owned skill without a Claude copy is disclosed, not failed' {
        Write-SwFile (Join-Path $dir '.agents/skills/my-own/SKILL.md') "---`nname: my-own`ndescription: Project helper.`n---`n`nBody.`n"
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 0
        ($result.Output -join "`n") | Should -Match 'Project-owned skill without a matching Claude copy: \.claude/skills/my-own/SKILL\.md'
        Write-SwFile (Join-Path $dir '.claude/skills/my-own/SKILL.md') (Read-SwText (Join-Path $dir '.agents/skills/my-own/SKILL.md'))
        ((Test-SwValidate $dir).Output -join "`n") | Should -Not -Match 'without a matching Claude copy'
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

    It 'exempts explicit header snapshots from topic sections, not date or finding checks' {
        $dir = New-SwProject "research$(New-Id)" generic
        $marker = '<!-- sw:research-format: snapshot -->'
        Write-SwFile (Join-Path $dir 'docs/research/01-snapshot.md') "# Snapshot`n`n$marker`n`nObserved 2026-10-12; local evidence.`n`n## Observations`n`nA dated snapshot.`n"
        Write-SwFile (Join-Path $dir 'docs/research/02-undated.md') "# Snapshot`n`n$marker`n`n## 2. Findings`n`nF1. **Uncited.** A claim.`n"
        Write-SwFile (Join-Path $dir 'docs/research/03-body-marker.md') "# Topic`n`nAccessed 2026-10-12.`n`n## 1. Question`n`n$marker`n"
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 0
        $out = $result.Output -join "`n"
        $out | Should -Not -Match 'WARNING: docs/research/01-snapshot\.md:'
        $out | Should -Not -Match '02-undated\.md: missing section'
        $out | Should -Match '02-undated\.md: header has no YYYY-MM-DD date'
        $out | Should -Match '02-undated\.md: F1 has no citation'
        $out | Should -Match '03-body-marker\.md: missing section\(s\) 2, 3, 4, 5, 6'
    }

    It 'recognizes explicit Source and Sources finding references, not arbitrary mentions' {
        $dir = New-SwProject "research$(New-Id)" generic
        $text = "# Topic`n`nAccessed 2026-10-12.`n`n## 1. Question`n`nQ.`n`n## 2. Findings`n`nF1. **Cited.** <https://example.com>.`n`nF2. **Cross-reference.** Sources F1.`n`nF3. **Cross-references.** Sources F1, F2.`n`nF4. **Singular reference.** Source F1.`n`nF5. **Malformed reference.** Sources F1ish.`n`nF6. **Mention only.** This claim mentions F1.`n`n## 3. Options`n`nO.`n`n## 4. Recommendation`n`nR.`n`n## 5. Open questions`n`nNone.`n`n## 6. Supersedes / updates`n`nNone.`n"
        Write-SwFile (Join-Path $dir 'docs/research/01-topic.md') $text
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 0
        $out = $result.Output -join "`n"
        $out | Should -Not -Match '01-topic\.md: (F1|F2|F3|F4) '
        $out | Should -Match '01-topic\.md: F5 has no citation'
        $out | Should -Match '01-topic\.md: F6 has no citation'
    }
}

Describe 'Startup budget output' {
    It 'labels the token figure as a bytes/4 estimate and counts AGENTS.md plus skill names and descriptions once per session' {
        $dir = New-SwProject "budget$(New-Id)" generic
        $lines = @(Test-SwProject -Path $dir | Where-Object { $_ -like 'Startup budget:*' })
        $lines.Count | Should -Be 1
        $lines[0] | Should -Match '^Startup budget: session = \d+ bytes, ~\d+ tokens \(bytes/4 estimate; tokenizer varies\); cap \d+$'
        $bytes = { [int]((@(Test-SwProject -Path $dir) -like 'Startup budget: session =*')[0] -replace '^.* = (\d+) bytes.*$', '$1') }
        $before = & $bytes
        foreach ($root in '.agents', '.claude') { $f = Join-Path $dir "$root/skills/minimal-change/SKILL.md"; Write-SwFile $f ((Read-SwText $f) -replace '(?m)^description: (.*)$', 'description: $1 Padded.') }
        (& $bytes) | Should -Be ($before + 8)
    }
}

Describe 'Validator positive fixture' {
    It 'GitHubTier <Tier> init validates' -ForEach @(@{ Tier = 1 }, @{ Tier = 2 }) {
        $dir = New-SwProject "tier$Tier$(New-Id)" generic $Tier
        (Get-SwConfig $dir)['githubTier'] | Should -Be $Tier
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 0
    }

    It 'init refuses an unsupported GitHub tier before any effect' {
        $dir = Join-Path $TestDrive "tier3$(New-Id)"
        { Initialize-SwProject -Path $dir -GitHubTier 3 } | Should -Throw
        Test-Path -LiteralPath $dir | Should -BeFalse
    }
}

Describe 'Docs link check' {
    # Owner M7 decision 17: -CheckLinks covers local Markdown links in docs/**/*.md, inside the root, never through a link.
    BeforeEach {
        $dir = New-SwProject "links$(New-Id)" generic
        Write-SwFile (Join-Path $dir 'docs/b.md') "# B`n"
        Write-SwFile (Join-Path $dir 'docs/sub/c.md') "Back to [b](../b.md) and [root](../../AGENTS.md).`n"
        function Test-Links { $out = Test-SwProject -Path $dir -CheckLinks -Quiet; [pscustomobject]@{ Text = ($out -join "`n"); ExitCode = $global:LASTEXITCODE } }
    }

    It 'a good relative link, with or without an anchor, passes and is counted' {
        Write-SwFile (Join-Path $dir 'docs/a.md') "See [b](b.md), [section](b.md#b), [c](sub/c.md) and [here](#top).`n"
        $r = Test-Links
        $r.ExitCode | Should -Be 0 -Because $r.Text
        $r.Text | Should -Match 'local links=5\. '
    }

    It 'a broken local link fails with its file and line' {
        Write-SwFile (Join-Path $dir 'docs/a.md') "Line one.`nSee [gone](missing.md#x).`n"
        $r = Test-Links
        $r.ExitCode | Should -Be 1
        $r.Text | Should -Match 'ERROR: docs/a\.md:2: missing local link missing\.md'
    }

    It 'an external URL or other scheme is ignored, not counted' {
        Write-SwFile (Join-Path $dir 'docs/a.md') "[web](https://example.com/missing.md) [mail](mailto:x@example.com) [thread](t3-thread://v1/x)`n"
        $r = Test-Links
        $r.ExitCode | Should -Be 0 -Because $r.Text
        $r.Text | Should -Match 'local links=2\. '
    }

    It 'a link escaping the root, or a rooted path, is refused even when the target exists' {
        Write-SwFile (Join-Path $TestDrive 'outside.md') "# Outside`n"
        Write-SwFile (Join-Path $dir 'docs/a.md') "[out](../../outside.md)`n[abs](/outside.md)`n"
        $r = Test-Links
        $r.ExitCode | Should -Be 1
        $r.Text | Should -Match 'ERROR: docs/a\.md:1: local link escapes the project root, refused and not checked: \.\./\.\./outside\.md'
        $r.Text | Should -Match 'ERROR: docs/a\.md:2: rooted local link refused, not checked: /outside\.md'
    }

    It 'a Windows drive, UNC, file: or encoded rooted target is refused as rooted, never skipped as a URL scheme' {
        # Codex review round 3: C: once matched the scheme exclusion, so the link passed with nothing checked.
        Write-SwFile (Join-Path $dir 'docs/a.md') @'
[a](C:/definitely-missing/review.md)
[b](C:\definitely-missing\review.md)
[c](c:relative.md)
[d](\\server\share\x.md)
[e](//server/share/x.md)
[f](file:///C:/x.md)
[g](%2Fetc%2Fx.md)

'@
        $r = Test-Links
        $r.ExitCode | Should -Be 1
        $r.Text | Should -Match 'local links=9\. '
        foreach ($case in @(@(1, 'C:/definitely-missing/review\.md'), @(2, 'C:\\definitely-missing\\review\.md'), @(3, 'c:relative\.md'), @(4, '\\\\server\\share\\x\.md'),
                @(5, '//server/share/x\.md'), @(6, 'file:///C:/x\.md'), @(7, '/etc/x\.md'))) {
            $r.Text | Should -Match "ERROR: docs/a\.md:$($case[0]): rooted local link refused, not checked: $($case[1])"
        }
    }

    It 'a destination with a title, in angle brackets, or in a reference definition is checked' {
        Write-SwFile (Join-Path $dir 'docs/sub/c d.md') "# CD`n"
        Write-SwFile (Join-Path $dir 'docs/a.md') @'
[t1](b.md "Title") [t2](b.md 'Title') [t3](b.md (Title)) [v](<../AGENTS.md>) [sp](<sub/c d.md>)
![img](b.md) [deep](sub/c.md#x "T")
[ref]: b.md "T"
   [ref2]: <sub/c.md>

'@
        $r = Test-Links
        $r.ExitCode | Should -Be 0 -Because $r.Text
        $r.Text | Should -Match 'local links=11\. '
        Write-SwFile (Join-Path $dir 'docs/a.md') @'
[m1](missing1.md "Title")
[target]: missing2.md
[m3](<missing three.md>)
  [t]: <missing4.md> 'T'

'@
        $r = Test-Links
        $r.ExitCode | Should -Be 1
        foreach ($i in 1..4) { $r.Text | Should -Match "ERROR: docs/a\.md:${i}: missing local link missing$(if ($i -eq 3) { ' three' } else { $i })\.md" }
    }

    It 'code blocks, code spans, escaped brackets, footnotes and indented definitions hold no links, and the text after each is checked' {
        # Review round 4: a real missing link (goneN) follows each construct, so a fence that never closed or a skip
        # that swallowed the rest of a line fails here.
        Write-SwFile (Join-Path $dir 'docs/a.md') @'
```md
[x](missing1.md)
```
[after-fence](gone1.md)
~~~
[y]: missing2.md
~~~
[after-tilde](gone2.md)
````
```
[z](missing3.md)
````
[after-long-fence](gone3.md)
Inline `[w](missing4.md)` and ``[v](missing5.md)`` then [after-code](gone4.md).
\[not\](missing6.md) then [after-escape](gone5.md).
[^1]: missing7.md [after-note](gone6.md)
    [ind]: missing8.md
  - item
    ```text
    [i](missing9.md)
    ```
[after-indented-fence](gone7.md)
[a\\](gone8.md) and [b\\\](missing10.md)

'@
        $r = Test-Links
        $r.ExitCode | Should -Be 1
        $r.Text | Should -Match 'local links=10\. '
        $r.Text | Should -Match 'FAILED: 8 error\(s\)\.'
        foreach ($case in @(@(4, 1), @(8, 2), @(13, 3), @(14, 4), @(15, 5), @(16, 6), @(22, 7), @(23, 8))) {
            $r.Text | Should -Match "ERROR: docs/a\.md:$($case[0]): missing local link gone$($case[1])\.md"
        }
        $r.Text | Should -Not -Match 'missing\d'
    }

    It 'a colon in a local target is refused, while scheme:// and mailto: URLs are skipped' {
        # Review round 4: notes.md:x, docs:intro.md and a.md::$DATA once passed as URL schemes, unchecked.
        Write-SwFile (Join-Path $dir 'docs/a.md') "[s](notes.md:x)`n[t](docs:intro.md)`n[u](b.md::`$DATA)`n[w](https://example.com/a.md) [m](mailto:x@example.com)`n"
        $r = Test-Links
        $r.ExitCode | Should -Be 1
        $r.Text | Should -Match 'local links=5\. '
        foreach ($case in @(@(1, 'notes\.md:x'), @(2, 'docs:intro\.md'), @(3, 'b\.md::\$DATA'))) {
            $r.Text | Should -Match "ERROR: docs/a\.md:$($case[0]): local link with a colon refused \(a stream or an unknown scheme\), not checked: $($case[1])"
        }
    }

    It 'a link whose letter case differs from the name on disk is refused' {
        # Review round 4: Windows matched ../agents.md to AGENTS.md; GitHub and Linux do not.
        Write-SwFile (Join-Path $dir 'docs/a.md') "[ok](../AGENTS.md) [bad](../agents.md) [sub](SUB/c.md)`n"
        $r = Test-Links
        $r.ExitCode | Should -Be 1
        $r.Text | Should -Match 'local links=5\. '
        # Exact-case matching: Should -Match ignores case.
        $r.Text | Should -MatchExactly 'ERROR: docs/a\.md:1: local link differs in letter case from the name on disk \(breaks on GitHub and Linux\): \.\./agents\.md \(on disk: AGENTS\.md\)'
        $r.Text | Should -MatchExactly 'ERROR: docs/a\.md:1: local link differs in letter case [^\n]*: SUB/c\.md \(on disk: docs/sub/c\.md\)'
        $r.Text | Should -Not -MatchExactly 'ERROR: [^\n]*\.\./AGENTS\.md'
    }

    It 'a link naming the project root from above it needs the root''s letter case' {
        # Review round 5: ../../LINKS-FIXTURE matched the root ignoring case and passed before any case check.
        $leaf = Split-Path $dir -Leaf
        Write-SwFile (Join-Path $dir 'docs/a.md') "[up](..) [ok](../../$leaf/) [bad](../../$($leaf.ToUpperInvariant()))`n"
        $r = Test-Links
        $r.ExitCode | Should -Be 1
        $r.Text | Should -Match 'local links=5\. '
        $r.Text | Should -Match 'FAILED: 1 error\(s\)\.'
        $r.Text | Should -MatchExactly "ERROR: docs/a\.md:1: local link differs in letter case from the name on disk \(breaks on GitHub and Linux\): \.\./\.\./$([regex]::Escape($leaf.ToUpperInvariant())) \(on disk: the project root, $([regex]::Escape($leaf))\)"
    }

    It 'a linked directory under docs is reported, not followed, and a link through it is refused' {
        $target = Join-Path $TestDrive "linktarget$(New-Id)"
        Write-SwFile (Join-Path $target 'x.md') "[gone](nowhere.md)`n"
        New-Item -ItemType Junction -Path (Join-Path $dir 'docs/linked') -Target $target | Out-Null
        Write-SwFile (Join-Path $dir 'docs/a.md') "[x](linked/x.md)`n"
        $r = Test-Links
        $r.ExitCode | Should -Be 1
        $r.Text | Should -Match 'WARNING: -CheckLinks did not follow linked docs/linked'
        $r.Text | Should -Match 'ERROR: docs/a\.md:1: local link crosses a link or junction, not followed: linked/x\.md'
        $r.Text | Should -Not -Match 'nowhere\.md'
    }

    It 'without -CheckLinks docs links are not checked' {
        Write-SwFile (Join-Path $dir 'docs/a.md') "[gone](missing.md)`n"
        (Test-SwValidate $dir).ExitCode | Should -Be 0
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

    It 'the documented close command works through the installed CLI' {
        $doc = Read-SwText (Join-Path $dir '.sw/collaboration.md')
        $doc | Should -Match 'sw comms close -Task <task-id> -Outcome "<summary>"'
        $cli = Join-Path $dir '.sw/sw.ps1'
        & $script:Shell -NoProfile -ExecutionPolicy Bypass -File $cli comms event -Task cli-close | Out-Null
        $LASTEXITCODE | Should -Be 0
        & $script:Shell -NoProfile -ExecutionPolicy Bypass -File $cli comms close -Task cli-close -Outcome 'shipped with evidence' | Out-Null
        $LASTEXITCODE | Should -Be 0
        Test-Path (Join-Path $dir '.sw/comms/tasks/cli-close') | Should -BeFalse
        $events = @(Get-ChildItem (Join-Path $dir '.sw/comms/archive/cli-close/events') -Filter *.md)
        $events.Count | Should -Be 1
        (Read-SwText (Join-Path $dir '.sw/comms/archive/cli-close/SUMMARY.md')) | Should -Match 'shipped with evidence'
    }

    It 'Add-SwUser adds the contributor to config and creates their inbox' {
        $out = (Add-SwUser bob -Path $dir) -join "`n"
        $out | Should -Match 'T3 Code threads.*t3/'
        $out | Should -Not -Match 'git switch|-worktree'
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
        $paths = Invoke-InParallel 8 {
            param($Index, $ModulePath, $Barrier, $Dir, $Payloads)
            Import-Module $ModulePath -Force -DisableNameChecking
            $Barrier.SignalAndWait()
            & (Get-Module Sw.Project) { param($d, $c) New-SwExclusiveFile $d 'rec' '.md' $c } $Dir $Payloads[$Index]
        } @{ ModulePath = $modulePath; Barrier = $barrier; Dir = $dir; Payloads = $payloads }
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
        Invoke-InParallel 6 {
            param($Index, $ModulePath, $Barrier, $Dir)
            Import-Module $ModulePath -Force -DisableNameChecking
            & (Get-Module Sw.Project) { function script:Get-SwUtc { '2000-01-01T000000Z' } }
            $Barrier.SignalAndWait()
            Invoke-SwComms send -To alice -From bob -Subject same -Body "body-$Index" -Path $Dir | Out-Null
            Invoke-SwComms event -Task T9 -From bob -Event progress -Body "event-$Index" -Path $Dir | Out-Null
        } @{ ModulePath = $modulePath; Barrier = $barrier; Dir = $dir } | Out-Null
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

    Context 'Get-SwUsage' {
        It 'reports Workspace estimates, never provider telemetry, and runs no tool when rtk is missing' {
            $dir = New-SwProject "usage$(New-Id)"
            Set-FakeTools @{ rtk = @{ Missing = $true } }
            $out = (Get-SwUsage -Path $dir) -join "`n"
            $out | Should -Match 'Workspace estimates only, not provider request telemetry'
            $out | Should -Match 'rtk not installed\.'
            $out | Should -Match 'Startup budget: session = \d+ bytes'
            Get-ProbeLog | Should -BeNullOrEmpty
        }
    }

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

Describe 'Invoke-SwNative (real child processes)' {
    It 'resolves a non-ASCII Git root under a legacy console code page and leaves that code page alone' {
        # Git prints the path in UTF-8; decoding it with the console code page garbled it and Resolve-Path failed.
        $dir = Join-Path $TestDrive "Jos$([char]0xE9)-$([char]0x6F22)-$(New-Id)"
        New-Item -ItemType Directory $dir | Out-Null
        Invoke-SwNative git @('-C', $dir, 'init', '-q') | Out-Null
        $initial = [Console]::OutputEncoding
        try {
            [Console]::OutputEncoding = [Text.Encoding]::GetEncoding(437)
            Push-Location -LiteralPath $dir
            try { Resolve-SwRoot '' | Should -Be $dir } finally { Pop-Location }
            [Console]::OutputEncoding.CodePage | Should -Be 437
        } finally { [Console]::OutputEncoding = $initial }
    }

    It 'returns one string per stdout line, keeping an empty middle line, and sets the exit code' {
        $out = Invoke-SwNative $script:Shell @('-NoProfile', '-Command', "[Console]::Out.Write('a' + [char]10 + [char]10 + 'b' + [char]10); exit 7")
        $LASTEXITCODE | Should -Be 7
        $out.Count | Should -Be 3
        $out | Should -Be @('a', '', 'b')
        Invoke-SwNative $script:Shell @('-NoProfile', '-Command', 'exit 0') | Should -BeNullOrEmpty
        $LASTEXITCODE | Should -Be 0
    }

    It 'discards a large stderr without blocking or raising errors under Stop' {
        $ErrorActionPreference = 'Stop'
        $errors = $Error.Count
        Invoke-SwNative $script:Shell @('-NoProfile', '-Command', "[Console]::Error.Write('e' * 1MB); [Console]::Error.Flush(); 'done'") | Should -Be 'done'
        $LASTEXITCODE | Should -Be 0
        $Error.Count | Should -Be $errors
    }

    It 'throws on a launch failure, whatever the caller preference' {
        $bad = Join-Path $TestDrive "bad$(New-Id).exe"
        Set-Content -LiteralPath $bad -Value 'not a program'
        { $ErrorActionPreference = 'SilentlyContinue'; Invoke-SwNative $bad @() } | Should -Throw
        { $ErrorActionPreference = 'SilentlyContinue'; Invoke-SwNative (Join-Path $TestDrive "missing$(New-Id).exe") @() } | Should -Throw
    }

    It 'runs in the current PowerShell location' {
        $wd = Join-Path $TestDrive "wd$(New-Id)"
        New-Item -ItemType Directory $wd | Out-Null
        Push-Location -LiteralPath $wd
        try {
            [Environment]::CurrentDirectory | Should -Not -Be $wd
            Invoke-SwNative $script:Shell @('-NoProfile', '-Command', '[Environment]::CurrentDirectory') | Should -Be $wd
        } finally { Pop-Location }
    }

    It 'passes spaces, quotes, backslashes, tabs, newlines and empty arguments unchanged' {
        # git rev-parse --sq-quote echoes each argument as it arrived: ' <arg>' with the value in single quotes.
        $values = @('plain', 'with space', '', 'quote"inside', '"', 'trail\', 'dir with space\', 'back\\"q', "tab`there", 'C:\p\f', "nl\`n", 'a\\b', '\\server\share\')
        $out = Invoke-SwNative git (@('rev-parse', '--sq-quote') + $values)
        $LASTEXITCODE | Should -Be 0
        (@($out) -join "`n") | Should -BeExactly (-join ($values | ForEach-Object { " '$_'" }))
    }

    It 'keeps the call operator for a .cmd shim and a .ps1 script' {
        $cmd = Join-Path $TestDrive "shim$(New-Id).cmd"
        Set-Content -LiteralPath $cmd -Value "@echo off`r`necho cmd %~1`r`nexit /b 3"
        Invoke-SwNative $cmd @('x y') | Should -Be 'cmd x y'
        $LASTEXITCODE | Should -Be 3
        $ps1 = Join-Path $TestDrive "script$(New-Id).ps1"
        Set-Content -LiteralPath $ps1 -Value 'param($A) "ps1 $A"'
        Invoke-SwNative $ps1 @('x y') | Should -Be 'ps1 x y'
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
        # The real check reads the user's Codex config; doctor tests never do.
        Mock -ModuleName Sw.Project Get-SwCodexTrust { $global:SwFake.Trust }
        function Set-FakeTools([hashtable]$Tools, [string]$Trust = 'trusted') {
            $global:SwFake = @{ Tools = @{}; Probes = @{}; Log = @(); Trust = $Trust }
            foreach ($name in $Tools.Keys) {
                $t = $Tools[$name]
                if ($t['Missing']) { $global:SwFake.Tools[$name] = $null; continue }
                $global:SwFake.Tools[$name] = "fake/$name"
                $exit = if ($t.ContainsKey('ExitCode')) { $t['ExitCode'] } else { 0 }
                $global:SwFake.Probes["fake/$name|--version"] = [pscustomobject]@{ Threw = [bool]$t['Threw']; ExitCode = $exit; Output = [string]$t['Output'] }
                if ($t.ContainsKey('AuthExit')) { $global:SwFake.Probes["fake/$name|auth status"] = [pscustomobject]@{ Threw = $false; ExitCode = $t['AuthExit']; Output = '' } }
            }
        }
        function Get-GoodTools { @{ t3 = @{ Output = 't3 0.0.46' }; claude = @{ Output = '2.1.286 (Claude Code)' }; codex = @{ Output = 'codex-cli 0.162.1' }; gh = @{ Output = 'gh 2.60.0'; AuthExit = 0 }; rtk = @{ Output = 'rtk 0.49.0' } } }
    }
    AfterAll { Remove-Variable SwFake -Scope Global -ErrorAction SilentlyContinue }

    It 'checks T3 Code prerequisites, users and Codex trust, prints the T3 and hard-limit reminders, and does not throw' {
        Set-FakeTools (Get-GoodTools)
        $dir = New-SwProject "doctor$(New-Id)" generic
        { Test-SwDoctor -Path $dir } | Should -Not -Throw
        $out = Test-SwDoctor -Path $dir | Out-String
        foreach ($item in 't3', 'claude', 'codex', 'gh', 'gh auth', 'rtk', 'codex trust') { $out | Should -Match "(?m)^$([regex]::Escape($item))\s+OK" }
        $out | Should -Match 'pass -User <name>'
        $out | Should -Match 'Startup budget \(validate\) counts kit files only'
        $out | Should -Match 'Branch protection on main: not checked'
        $out | Should -Match 'runtime mode Auto or Full access, not Supervised'
        $out | Should -Match 'Codex applies \.codex/rules only in a trusted project'
        $out | Should -Not -Match '(?im)opencode|tier map|Claude adapter|sw\.ps1 (tiers|claude)'
        $global:LASTEXITCODE | Should -Be 0
    }

    It 'optional tool problems warn without failing: <Name>' -ForEach @(
        @{ Name = 't3 CLI missing (desktop-only installs are undetectable)'; Tool = 't3'; Fake = @{ Missing = $true }; Item = 't3' }
        @{ Name = 'claude missing'; Tool = 'claude'; Fake = @{ Missing = $true }; Item = 'claude' }
        @{ Name = 'codex thrown'; Tool = 'codex'; Fake = @{ Threw = $true }; Item = 'codex' }
        @{ Name = 'gh nonzero'; Tool = 'gh'; Fake = @{ Output = 'gh 2.60.0'; ExitCode = 2 }; Item = 'gh' }
        @{ Name = 'rtk thrown'; Tool = 'rtk'; Fake = @{ Threw = $true }; Item = 'rtk' }
        @{ Name = 'rtk missing'; Tool = 'rtk'; Fake = @{ Missing = $true }; Item = 'rtk' }
        @{ Name = 'rtk too old'; Tool = 'rtk'; Fake = @{ Output = 'rtk 0.40.0' }; Item = 'rtk >= 0.48' }
    ) {
        $tools = Get-GoodTools; $tools[$Tool] = $Fake; Set-FakeTools $tools
        $dir = New-SwProject "doctor$(New-Id)" generic
        (Test-SwDoctor -Path $dir | Out-String) | Should -Match "(?m)^$([regex]::Escape($Item))\s+WARN"
        $global:LASTEXITCODE | Should -Be 0
    }

    It 'Codex trust is reported, never required: <Trust>' -ForEach @(
        @{ Trust = 'trusted'; State = 'OK'; Detail = 'project trusted' }
        @{ Trust = 'untrusted'; State = 'WARN'; Detail = 'Codex skips \.codex/rules' }
        @{ Trust = 'unknown'; State = 'WARN'; Detail = 'no readable Codex config' }
    ) {
        Set-FakeTools (Get-GoodTools) $Trust
        $dir = New-SwProject "trust$(New-Id)" generic
        (Test-SwDoctor -Path $dir | Out-String) | Should -Match "(?m)^codex trust\s+$State\s+.*$Detail"
        $global:LASTEXITCODE | Should -Be 0
    }

    It 'gh auth follows the immediate probe exit and is skipped when gh is unusable' {
        $dir = New-SwProject "doctor$(New-Id)" generic
        $tools = Get-GoodTools; Set-FakeTools $tools
        (Test-SwDoctor -Path $dir | Out-String) | Should -Match '(?m)^gh auth\s+OK\s+logged in'
        $tools['gh'] = @{ Output = 'gh 2.60.0'; AuthExit = 4 }; Set-FakeTools $tools
        (Test-SwDoctor -Path $dir | Out-String) | Should -Match '(?m)^gh auth\s+WARN'
        $tools['gh'] = @{ Output = 'gh 2.60.0'; ExitCode = 1; AuthExit = 0 }; Set-FakeTools $tools
        (Test-SwDoctor -Path $dir | Out-String) | Should -Not -Match 'gh auth'
    }

    It 'checks the branch actually checked out: <Name>' -ForEach @(
        @{ Name = 'solo on main'; Users = @(); Branch = 'main'; User = $null; State = 'OK' }
        @{ Name = 'solo on a T3 Code thread branch'; Users = @(); Branch = 't3/fix-docs'; User = $null; State = 'OK' }
        @{ Name = 'solo on a retired contributor branch'; Users = @(); Branch = 'alice/alice-worktree'; User = $null; State = 'WARN' }
        @{ Name = 'solo on a non-T3 task branch'; Users = @(); Branch = 'feat/thing'; User = $null; State = 'WARN' }
        @{ Name = 'solo detached'; Users = @(); Branch = 'DETACHED'; User = $null; State = 'WARN' }
        @{ Name = 'team, main, no identity'; Users = @('alice', 'bob'); Branch = 'main'; User = $null; State = 'OK' }
        @{ Name = 'team, T3 Code thread branch, listed user'; Users = @('alice', 'bob'); Branch = 't3/alice-task'; User = 'alice'; State = 'OK' }
        @{ Name = 'team, retired contributor branch'; Users = @('alice', 'bob'); Branch = 'alice/alice-worktree'; User = 'alice'; State = 'WARN' }
        @{ Name = 'team, unlisted identity on a T3 Code thread branch'; Users = @('alice', 'bob'); Branch = 't3/carol-task'; User = 'carol'; State = 'OK' }
        @{ Name = 'team, detached HEAD'; Users = @('alice', 'bob'); Branch = 'DETACHED'; User = 'alice'; State = 'WARN' }
    ) {
        Set-FakeTools (Get-GoodTools)
        $dir = New-SwProject "branch$(New-Id)" generic
        foreach ($u in $Users) { Add-SwUser $u -Path $dir | Out-Null }
        Invoke-SwNative git @('-C', $dir, 'add', '-A')
        Invoke-SwNative git @('-C', $dir, 'commit', '-q', '-m', 'init')
        if ($Branch -eq 'DETACHED') { Invoke-SwNative git @('-C', $dir, 'checkout', '-q', '--detach') } elseif ($Branch -ne 'main') { Invoke-SwNative git @('-C', $dir, 'switch', '-q', '-c', $Branch) }
        $out = if ($User) { Test-SwDoctor -Path $dir -User $User | Out-String } else { Test-SwDoctor -Path $dir | Out-String }
        $out | Should -Match "(?m)^current branch\s+$State\b"
        if ($Name -eq 'team, unlisted identity on a T3 Code thread branch') { $out | Should -Match '(?m)^user carol\s+MISSING'; $global:LASTEXITCODE | Should -Be 1 }
    }
}

Describe 'Get-SwCodexTrust (synthetic Codex home)' {
    BeforeAll {
        $script:SavedCodexHome = $env:CODEX_HOME
        function Set-CodexConfig($Text) {
            $env:CODEX_HOME = Join-Path $TestDrive "codex$(New-Id)"
            if ($null -ne $Text) { Write-SwFile (Join-Path $env:CODEX_HOME 'config.toml') $Text }
        }
    }
    AfterAll { if ($null -ne $script:SavedCodexHome) { $env:CODEX_HOME = $script:SavedCodexHome } else { Remove-Item Env:CODEX_HOME -ErrorAction Ignore } }

    It '<Name> -> <Expected>' -ForEach @(
        @{ Name = 'single-quoted project key, trusted'; Key = "'{0}'"; Level = 'trusted'; Under = ''; Expected = 'trusted' }
        @{ Name = 'double-quoted project key, trusted'; Key = '"{1}"'; Level = 'trusted'; Under = ''; Expected = 'trusted' }
        @{ Name = 'trusted parent folder'; Key = "'{0}'"; Level = 'trusted'; Under = 'child'; Expected = 'trusted' }
        @{ Name = 'untrusted level'; Key = "'{0}'"; Level = 'untrusted'; Under = ''; Expected = 'untrusted' }
    ) {
        $root = Join-Path $TestDrive "proj$(New-Id)"
        $project = Join-Path $root $Under
        New-Item -ItemType Directory -Force -Path $project | Out-Null
        $quoted = $Key -f $root, $root.Replace('\', '\\')
        Set-CodexConfig "model = `"x`"`n`n[projects.$quoted]`ntrust_level = `"$Level`"`n`n[other]`ntrust_level = `"trusted`"`n"
        Get-SwCodexTrust $project | Should -Be $Expected
    }

    It 'another project trusted is untrusted here; no config is unknown' {
        Set-CodexConfig "[projects.'$(Join-Path $TestDrive 'elsewhere')']`ntrust_level = `"trusted`"`n"
        Get-SwCodexTrust (Join-Path $TestDrive 'here') | Should -Be 'untrusted'
        Set-CodexConfig $null
        Get-SwCodexTrust $TestDrive | Should -Be 'unknown'
    }

    It 'an explicit Codex home wins over CODEX_HOME' {
        $project = Join-Path $TestDrive "proj$(New-Id)"
        Set-CodexConfig "[projects.'$project']`ntrust_level = `"trusted`"`n"
        $trustedHome = $env:CODEX_HOME
        Set-CodexConfig $null
        Get-SwCodexTrust $project | Should -Be 'unknown'
        Get-SwCodexTrust $project $trustedHome | Should -Be 'trusted'
    }
}

Describe 'Global setup (synthetic home)' {
    # Everything runs against a home under TestDrive. Sentinels make any real tool, auth or installer reach fail.
    # The shell running the suite may set CLAUDE_CONFIG_DIR/CODEX_HOME to real homes: both are cleared here and restored after.
    BeforeAll {
        $script:SavedProviderHomes = @{ CLAUDE_CONFIG_DIR = $env:CLAUDE_CONFIG_DIR; CODEX_HOME = $env:CODEX_HOME }
        Remove-Item Env:CLAUDE_CONFIG_DIR, Env:CODEX_HOME -ErrorAction Ignore
        Mock -ModuleName Sw.Kit Get-SwUserHome { $global:SwTestHome }
        Mock -ModuleName Sw.Kit Get-SwToolProbe { [pscustomobject]@{ Name = $Name; State = 'ok'; Version = [version]'9.9.9'; ExitCode = 0 } }
        Mock -ModuleName Sw.Kit Get-SwToolVersion { [version]'9.9.9' }
        Mock -ModuleName Sw.Kit Get-SwGhAuth { 0 }
        InModuleScope Sw.Kit { function script:winget { throw 'unexpected winget run' } }
        function New-Home {
            $global:SwTestHome = Join-Path $TestDrive "home$(New-Id)"
            Write-SwFile (Join-Path $global:SwTestHome '.claude/CLAUDE.md') "mine`n"
            Write-SwFile (Join-Path $global:SwTestHome '.claude/settings.json') ('{"permissions":{"allow":["Bash(gh *)","Bash(npm test:*)","Bash(gh *)","Bash(gh:*)"]}}' + "`n")
            Write-SwFile (Join-Path $global:SwTestHome '.codex/AGENTS.md') "codex mine`n"
            Write-SwFile (Join-Path $global:SwTestHome '.config/opencode/AGENTS.md') "opencode mine`n"
            $global:SwTestHome
        }
        # -Dirs also lists directories, so a run that must create nothing cannot leave an empty one behind.
        function Get-Tree([string]$Dir, [switch]$Dirs) {
            if (-not (Test-Path -LiteralPath $Dir)) { return 'absent' }
            (@(Get-ChildItem -LiteralPath $Dir -Recurse -Force -File:(-not $Dirs) | Sort-Object FullName | ForEach-Object { "$($_.FullName.Substring($Dir.Length)):$(if ($_.PSIsContainer) { 'dir' } else { (Get-FileHash $_.FullName).Hash })" }) -join "`n")
        }
    }
    AfterEach { Remove-Item Env:CLAUDE_CONFIG_DIR, Env:CODEX_HOME -ErrorAction Ignore }
    AfterAll {
        InModuleScope Sw.Kit { Remove-Item Function:script:winget -ErrorAction SilentlyContinue }
        Remove-Variable SwTestHome, SwTestPaths -Scope Global -ErrorAction SilentlyContinue
        foreach ($k in $script:SavedProviderHomes.Keys) { if ($null -ne $script:SavedProviderHomes[$k]) { Set-Item "Env:$k" $script:SavedProviderHomes[$k] } }
    }

    It 'backs up the files install may edit into a snapshot under the synthetic home, never the real profile' {
        $h = New-Home
        $b = Backup-SwGlobal
        $b.Path.StartsWith($h) | Should -BeTrue
        @($b.Files | ForEach-Object { $_.Replace('\', '/') } | Sort-Object) | Should -Be @('.claude/CLAUDE.md', '.claude/settings.json', '.codex/AGENTS.md')
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
        $global:SwTestPaths = InModuleScope Sw.Kit { Get-SwGlobalPaths }
        $global:SwTestPaths.HomeAgents = Join-Path $outside 'AGENTS.md'
        Mock -ModuleName Sw.Kit Get-SwGlobalPaths { $global:SwTestPaths }
        $before = Get-Tree $h
        { Backup-SwGlobal } | Should -Throw '*outside the home directory*'
        Get-Tree $h | Should -Be $before
    }

    It '-WhatIf creates nothing' {
        $h = New-Home
        $before = Get-Tree $h -Dirs
        Backup-SwGlobal -WhatIf *> $null
        Install-SwGlobal -WhatIf *> $null
        Get-Tree $h -Dirs | Should -Be $before
        Test-Path (Join-Path $h '.sw') | Should -BeFalse
    }

    It 'a reservation or copy failure (<Failing>) stops install before any global file is replaced' -ForEach @(
        @{ Failing = 'New-SwSnapshotDir' }
        @{ Failing = 'Copy-SwNew' }
    ) {
        $h = New-Home
        $before = Get-Tree $h
        Mock -ModuleName Sw.Kit $Failing { throw 'injected recovery-copy failure' }
        { Install-SwGlobal } | Should -Throw '*injected recovery-copy failure*'
        Get-Tree $h | Should -Be $before
    }

    It 'install sets the global block for Claude and Codex below their unmanaged text and leaves OpenCode alone' {
        $h = New-Home
        $out = (Install-SwGlobal) -join "`n"
        $rules = Read-SwText (Join-Path $RepoRoot 'global/rules.md')
        foreach ($f in '.claude/CLAUDE.md', '.codex/AGENTS.md') {
            $text = Read-SwText (Join-Path $h $f)
            $text | Should -Match '<!-- sw:begin global -->'
            $text.Contains($rules.Trim("`n")) | Should -BeTrue
        }
        (Read-SwText (Join-Path $h '.claude/CLAUDE.md')).StartsWith("mine`n") | Should -BeTrue
        (Read-SwText (Join-Path $h '.codex/AGENTS.md')).StartsWith("codex mine`n") | Should -BeTrue
        $out | Should -Match 'keeps its earlier unmanaged text'
        Read-SwText (Join-Path $h '.config/opencode/AGENTS.md') | Should -Be "opencode mine`n"
        $out | Should -Match '(?m)^codex rules\s+OK'
    }

    It '-ReplaceUnmanaged is retired: install rejects it' {
        $h = New-Home
        $before = Get-Tree $h
        { Install-SwGlobal -ReplaceUnmanaged } | Should -Throw '*ReplaceUnmanaged*'
        { Invoke-SwGlobal install -ReplaceUnmanaged } | Should -Throw '*ReplaceUnmanaged*'
        Get-Tree $h | Should -Be $before
    }

    It 'install leaves settings.json and ~/AGENTS.md alone; check reports them with the suggested change' {
        $h = New-Home
        Write-SwFile (Join-Path $h 'AGENTS.md') "@RTK.md`n"
        Write-SwFile (Join-Path $h '.claude/RTK.md') "rtk`n"
        $settings = Get-FileHash (Join-Path $h '.claude/settings.json'); $agents = Get-FileHash (Join-Path $h 'AGENTS.md')
        $out = (Install-SwGlobal) -join "`n"
        (Get-FileHash (Join-Path $h '.claude/settings.json')).Hash | Should -Be $settings.Hash
        (Get-FileHash (Join-Path $h 'AGENTS.md')).Hash | Should -Be $agents.Hash
        $out | Should -Match '(?m)^claude gh allow\s+WARN\s+broad gh allow permits gh writes; suggested: .*Bash\(gh pr view:\*\)'
        $out | Should -Match '(?m)^home RTK include\s+WARN\s+.*suggested: change the line to @\.claude/RTK\.md'
        $global:LASTEXITCODE | Should -Be 0
    }

    It 'homes come from parameters (repeatable or a path list), else CLAUDE_CONFIG_DIR/CODEX_HOME, else the defaults' {
        $h = New-Home
        $a = Join-Path $TestDrive "claudeA$(New-Id)"; $b = Join-Path $TestDrive "claudeB$(New-Id)"; $x = Join-Path $TestDrive "codexX$(New-Id)"
        $paths = InModuleScope Sw.Kit { Get-SwGlobalPaths }
        @($paths.Claude.Dir) | Should -Be @((Join-Path $h '.claude'))
        @($paths.Codex.Dir) | Should -Be @((Join-Path $h '.codex'))
        $paths.Claude[0].Origin | Should -Be 'default'
        $env:CLAUDE_CONFIG_DIR = $a; $env:CODEX_HOME = $x
        $paths = InModuleScope Sw.Kit { Get-SwGlobalPaths }
        @($paths.Claude.Dir) | Should -Be @($a)
        $paths.Claude[0].Origin | Should -Be 'env CLAUDE_CONFIG_DIR'
        @($paths.Codex.Dir) | Should -Be @($x)
        $paths = InModuleScope Sw.Kit -Parameters @{ A = $a; B = $b } { param($A, $B) Get-SwGlobalPaths -ClaudeConfigDir $B, $A, $B }
        @($paths.Claude.Dir) | Should -Be @($b, $a)
        $paths.Claude[0].Origin | Should -Be 'parameter'
        @($paths.Codex.Dir) | Should -Be @($x) -Because 'the Codex home still falls back to CODEX_HOME'
        $list = "$a$([IO.Path]::PathSeparator)$b"
        $paths = InModuleScope Sw.Kit -Parameters @{ L = $list } { param($L) Get-SwGlobalPaths -ClaudeConfigDir $L }
        @($paths.Claude.Dir) | Should -Be @($a, $b)
    }

    It 'install writes the block into every targeted home, keeps unmanaged text, backs up each home and checks each' {
        $h = New-Home
        $a = Join-Path $TestDrive "claudeA$(New-Id)"; $b = Join-Path $TestDrive "claudeB$(New-Id)"; $x = Join-Path $TestDrive "codexX$(New-Id)"
        Write-SwFile (Join-Path $a 'CLAUDE.md') "a mine`n"
        Write-SwFile (Join-Path $a 'settings.json') ('{"permissions":{"allow":["Bash(gh *)"]}}' + "`n")
        New-Item -ItemType Directory -Path $b | Out-Null
        Write-SwFile (Join-Path $x 'AGENTS.md') "x mine`n"
        $defaults = (Get-Tree (Join-Path $h '.claude')) + '|' + (Get-Tree (Join-Path $h '.codex'))
        $out = (Install-SwGlobal -ClaudeConfigDir $a, $b -CodexHome $x) -join "`n"
        $global:LASTEXITCODE | Should -Be 0
        foreach ($f in (Join-Path $a 'CLAUDE.md'), (Join-Path $b 'CLAUDE.md'), (Join-Path $x 'AGENTS.md')) { Read-SwText $f | Should -Match '<!-- sw:begin global -->' }
        (Read-SwText (Join-Path $a 'CLAUDE.md')).StartsWith("a mine`n") | Should -BeTrue
        (Read-SwText (Join-Path $x 'AGENTS.md')).StartsWith("x mine`n") | Should -BeTrue
        (Read-SwJson (Join-Path $a 'settings.json'))['permissions']['allow'] | Should -Contain 'Bash(gh *)' -Because 'install never rewrites user settings'
        (Get-Tree (Join-Path $h '.claude')) + '|' + (Get-Tree (Join-Path $h '.codex')) | Should -Be $defaults -Because 'untargeted default homes are left alone'
        $backups = @(Get-ChildItem (Join-Path $h '.sw/backups') -Recurse -File -Force)
        @($backups | Where-Object Name -EQ 'CLAUDE.md' | ForEach-Object { Read-SwText $_.FullName }) | Should -Be @("a mine`n")
        @($backups | Where-Object Name -EQ 'AGENTS.md' | ForEach-Object { Read-SwText $_.FullName }) | Should -Be @("x mine`n")
        @($backups | Where-Object { $_.FullName -match '[\\/]external[\\/](claude|codex)-[0-9a-f]{12}[\\/]' }).Count | Should -Be 3
        foreach ($d in $a, $b) { $out | Should -Match "(?m)^claude rules\s+OK\s+$([regex]::Escape((Join-Path $d 'CLAUDE.md'))) \(parameter\)" }
        $out | Should -Match "(?m)^codex rules\s+OK\s+$([regex]::Escape((Join-Path $x 'AGENTS.md'))) \(parameter\)"
        $report = (Invoke-SwGlobal backup -ClaudeConfigDir $a -CodexHome $x) -join "`n"
        $report | Should -Match ([regex]::Escape("Claude home $a"))
        $report | Should -Match ([regex]::Escape("Codex home $x"))
    }

    It 'install and backup refuse a named home that does not exist, writing nothing (not even a backup)' {
        $h = New-Home
        $before = Get-Tree $h -Dirs
        $missing = Join-Path $TestDrive "absent$(New-Id)"
        $x = Join-Path $TestDrive "codexX$(New-Id)"
        Write-SwFile (Join-Path $x 'AGENTS.md') "x mine`n"
        { Install-SwGlobal -CodexHome $missing } | Should -Throw '*Home not found, nothing written*'
        Test-Path -LiteralPath $missing | Should -BeFalse
        Get-Tree $h -Dirs | Should -Be $before
        { Backup-SwGlobal -ClaudeConfigDir $missing -CodexHome $x } | Should -Throw "*Claude $missing (parameter)*"
        { Invoke-SwGlobal backup -ClaudeConfigDir $missing -CodexHome $x } | Should -Throw '*Home not found*'
        Get-Tree $h -Dirs | Should -Be $before
        $env:CLAUDE_CONFIG_DIR = $missing
        { Install-SwGlobal } | Should -Throw '*(env CLAUDE_CONFIG_DIR)*'
        { Backup-SwGlobal } | Should -Throw '*(env CLAUDE_CONFIG_DIR)*'
        Get-Tree $h -Dirs | Should -Be $before
    }

    It 'backup reports an existing home with nothing to back up' {
        $h = New-Home
        $a = Join-Path $TestDrive "claudeEmpty$(New-Id)"; $x = Join-Path $TestDrive "codexX$(New-Id)"
        New-Item -ItemType Directory -Path $a | Out-Null
        Write-SwFile (Join-Path $x 'AGENTS.md') "x mine`n"
        $report = (Invoke-SwGlobal backup -ClaudeConfigDir $a -CodexHome $x) -join "`n"
        $report | Should -Match ([regex]::Escape("Claude home $($a): nothing to back up"))
        $report | Should -Match ([regex]::Escape("Codex home $($x):") + '\s+external')
    }

    It 'a single string is a path list; array elements stay literal; ambiguous and relative homes are refused' {
        $h = New-Home
        $sep = [IO.Path]::PathSeparator
        $odd = Join-Path $TestDrive "alpha$($sep)beta$(New-Id)"
        New-Item -ItemType Directory -Path $odd | Out-Null
        $other = Join-Path $TestDrive "other$(New-Id)"
        $paths = InModuleScope Sw.Kit -Parameters @{ O = $odd; T = $other } { param($O, $T) Get-SwGlobalPaths -ClaudeConfigDir $O, $T }
        @($paths.Claude.Dir) | Should -Be @($odd, $other) -Because 'elements of a real array are never split'
        { InModuleScope Sw.Kit -Parameters @{ O = $odd } { param($O) Get-SwGlobalPaths -ClaudeConfigDir $O } } | Should -Throw '*Ambiguous Claude home*'
        $env:CODEX_HOME = $odd
        { InModuleScope Sw.Kit { Get-SwGlobalPaths } } | Should -Throw '*Ambiguous Codex home (env CODEX_HOME)*'
        Remove-Item Env:CODEX_HOME
        { InModuleScope Sw.Kit { Get-SwGlobalPaths -ClaudeConfigDir 'relative/claude' } } | Should -Throw '*must be an absolute path*'
        { InModuleScope Sw.Kit -Parameters @{ L = "$other$($sep)relative" } { param($L) Get-SwGlobalPaths -CodexHome $L } } | Should -Throw "*must be an absolute path*'relative'*"
        $before = Get-Tree $h -Dirs
        { Install-SwGlobal -ClaudeConfigDir $odd } | Should -Throw '*Ambiguous*'
        Get-Tree $h -Dirs | Should -Be $before
        # Under ':' list rules a Windows drive-letter path splits into relative pieces and is refused, never half-used.
        { InModuleScope Sw.Kit { Get-SwHomeList 'Claude' @('C:\one:C:	wo') 'SW_TEST_UNSET' 'unused' ([char]':') } } | Should -Throw "*must be an absolute path*'C'*"
    }

    It 'a computed default home is literal, even when the user home holds the list separator' {
        $global:SwTestHome = Join-Path $TestDrive "user$([IO.Path]::PathSeparator)name$(New-Id)"
        $paths = InModuleScope Sw.Kit { Get-SwGlobalPaths }
        @($paths.Claude.Dir) | Should -Be @((Join-Path $global:SwTestHome '.claude'))
        @($paths.Codex.Dir) | Should -Be @((Join-Path $global:SwTestHome '.codex'))
        $paths.Codex[0].Origin | Should -Be 'default'
    }

    It 'a filesystem root is refused as a home before any backup or write (<Name>)' -ForEach @(
        @{ Name = 'root of the test drive (C:\ style on Windows)'; Root = 'drive' }
        @{ Name = 'slash root'; Root = '/' }
    ) {
        $Root = if ($Root -eq 'drive') { [IO.Path]::GetPathRoot($TestDrive) } else { $Root }
        $Root | Should -Not -BeNullOrEmpty
        $h = New-Home
        $before = Get-Tree $h -Dirs
        $expected = if ($Root -eq '/') { '*must be an absolute path*' } else { '*is a filesystem root, nothing was written*' }
        { InModuleScope Sw.Kit -Parameters @{ R = $Root } { param($R) Get-SwGlobalPaths -CodexHome $R } } | Should -Throw $expected
        { Install-SwGlobal -ClaudeConfigDir $Root } | Should -Throw $expected
        { Backup-SwGlobal -CodexHome $Root } | Should -Throw $expected
        Get-Tree $h -Dirs | Should -Be $before
    }

    It 'install never installs RTK unless -InstallRtk is passed' {
        $h = New-Home
        Mock -ModuleName Sw.Kit Get-SwToolVersion { $null }
        $out = (Install-SwGlobal) -join "`n"
        $out | Should -Match 'not installed'
        $out | Should -Match '-InstallRtk'
        InModuleScope Sw.Kit { function script:winget { $global:SwWingetArgs = $args -join ' ' } }
        try {
            Install-SwGlobal -InstallRtk | Out-Null
            $global:SwWingetArgs | Should -Match 'install --id rtk-ai\.rtk'
        } finally {
            InModuleScope Sw.Kit { function script:winget { throw 'unexpected winget run' } }
            Remove-Variable SwWingetArgs -Scope Global -ErrorAction SilentlyContinue
        }
    }

    Context 'baselines: an edited or unprovable installed block is never overwritten (A7)' {
        BeforeAll {
            $script:RulesPath = Join-Path $RepoRoot 'global/rules.md'
            function Get-Block([string]$Body) { "<!-- sw:begin global -->`n$($Body.Trim("`n"))`n<!-- sw:end global -->`n" }
            function Get-BodyHash([string]$Body) { Get-SwHash "`n$($Body.Trim("`n"))`n" }
            function Get-Record([string]$UserDir) { $f = Join-Path $UserDir '.sw/global.json'; if (Test-Path -LiteralPath $f) { Read-SwJson $f } }
            function Get-Entry([string]$UserDir, [string]$Dir, [string]$Key) { $r = Get-Record $UserDir; if ($r -and $r['homes'].Contains($Dir)) { $r['homes'][$Dir]['entries'][$Key] } }
            function Set-NewRules { Mock -ModuleName Sw.Kit Read-SwText -ParameterFilter { $Path.EndsWith('rules.md') } { "new rules`n" } }
            function Edit-Block([string]$File) { Write-SwFile $File ((Read-SwText $File).Replace('<!-- sw:end global -->', "my edit`n<!-- sw:end global -->")) }
            $script:RulesHash = Get-BodyHash (Read-SwText $RulesPath)
            function Invoke-ConfirmInstall([string]$UserHome, [string]$Deny, [string]$EditOn, [string]$EditPath, [string]$EditText, [switch]$NewRules) {
                # install -Confirm in a fresh runspace answered by SwAuditPromptHost. That runspace has no Pester mocks: the user
                # home, every tool reach and (with -NewRules) the rules text are replaced inside the module, as the mocks do here.
                $fixtureHost = if ($EditOn) { [SwAuditPromptHost]::new($Host, $Deny, $EditOn, $EditPath, $EditText) } else { [SwAuditPromptHost]::new($Host, $Deny) }
                $space = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($fixtureHost)
                $space.Open(); $ps = [Management.Automation.PowerShell]::Create(); $ps.Runspace = $space
                try {
                    $null = $ps.AddScript({
                        param($Lib, $UserHome, $NewRules)
                        Import-Module (Join-Path $Lib 'Sw.Project.psm1') -Force -DisableNameChecking
                        Import-Module (Join-Path $Lib 'Sw.Kit.psm1') -Force -DisableNameChecking
                        & (Get-Module Sw.Kit) {
                            param($u, $n)
                            $script:SwTestUserHome = $u
                            function script:Get-SwUserHome { $script:SwTestUserHome }
                            function script:Get-SwToolProbe([string]$Name) { [pscustomobject]@{ Name = $Name; State = 'ok'; Version = [version]'9.9.9'; ExitCode = 0 } }
                            function script:Get-SwToolVersion { [version]'9.9.9' }
                            function script:Get-SwGhAuth { 0 }
                            function script:winget { throw 'unexpected winget run' }
                            if ($n) { function script:Read-SwText([string]$Path) { if ($Path.EndsWith('rules.md')) { "new rules`n" } else { [IO.File]::ReadAllText($Path).Replace("`r`n", "`n") } } }
                        } $UserHome $NewRules
                        Install-SwGlobal -ClaudeConfigDir (Join-Path $UserHome '.claude') -CodexHome (Join-Path $UserHome '.codex') -Confirm | Out-Null
                        $global:LASTEXITCODE
                    }.ToString()).AddArgument((Join-Path $RepoRoot 'lib')).AddArgument($UserHome).AddArgument([bool]$NewRules)
                    $values = @($ps.Invoke())
                    if ($ps.HadErrors) { throw ($ps.Streams.Error -join "`n") }
                    [pscustomobject]@{ ExitCode = $values[-1]; Denied = $fixtureHost.Denied; Edited = $fixtureHost.Edited }
                } finally { $ps.Dispose(); $space.Dispose() }
            }
            $script:NewHash = Get-BodyHash "new rules`n"
        }

        It 'the shipped list holds the current global/rules.md hash' {
            InModuleScope Sw.Kit -Parameters @{ H = $RulesHash } { param($H) $script:GlobalShipped | Should -Contain $H }
        }

        It 'first install records each block hash; a re-run with unchanged rules writes no block; a lost record is rebuilt from current blocks' {
            $h = New-Home
            Install-SwGlobal | Out-Null
            $global:LASTEXITCODE | Should -Be 0
            $r = Get-Record $h
            $r['schema'] | Should -Be 1
            $r['homes'][(Join-Path $h '.claude')]['kind'] | Should -Be 'claude'
            Get-Entry $h (Join-Path $h '.claude') 'CLAUDE.md#global' | Should -Be $RulesHash
            Get-Entry $h (Join-Path $h '.codex') 'AGENTS.md#global' | Should -Be $RulesHash
            $homes = { (Get-Tree (Join-Path $h '.claude')) + '|' + (Get-Tree (Join-Path $h '.codex')) }
            $before = & $homes; $record = Read-SwText (Join-Path $h '.sw/global.json')
            $out = (Install-SwGlobal) -join "`n"
            $global:LASTEXITCODE | Should -Be 0
            $out | Should -Not -Match 'global rules \('
            & $homes | Should -Be $before
            Read-SwText (Join-Path $h '.sw/global.json') | Should -Be $record
            Remove-Item (Join-Path $h '.sw/global.json')
            Install-SwGlobal | Out-Null
            $global:LASTEXITCODE | Should -Be 0
            & $homes | Should -Be $before -Because 'blocks identical to the current rules are provably unedited'
            Get-Entry $h (Join-Path $h '.codex') 'AGENTS.md#global' | Should -Be $RulesHash
        }

        It 'a rules change updates an unedited block and records the new hash; with no record, a shipped version is updated too' {
            $h = New-Home
            Install-SwGlobal | Out-Null
            Set-NewRules
            Install-SwGlobal | Out-Null
            $global:LASTEXITCODE | Should -Be 0
            foreach ($f in '.claude/CLAUDE.md', '.codex/AGENTS.md') { Read-SwText (Join-Path $h $f) | Should -Match "(?s)begin global -->`nnew rules`n<!-- sw:end" }
            Get-Entry $h (Join-Path $h '.claude') 'CLAUDE.md#global' | Should -Be $NewHash
            $h = New-Home
            Write-SwFile (Join-Path $h '.claude/CLAUDE.md') ("mine`n`n" + (Get-Block (Read-SwText $RulesPath)))
            Install-SwGlobal | Out-Null
            $global:LASTEXITCODE | Should -Be 0
            Read-SwText (Join-Path $h '.claude/CLAUDE.md') | Should -Be ("mine`n`n" + (Get-Block "new rules"))
            Get-Entry $h (Join-Path $h '.claude') 'CLAUDE.md#global' | Should -Be $NewHash
        }

        It 'an edited block is kept with its baseline, whether or not the rules changed; the incoming version is saved for diff' {
            $h = New-Home
            Install-SwGlobal | Out-Null
            $file = Join-Path $h '.claude/CLAUDE.md'
            Edit-Block $file
            $bytes = (Get-FileHash $file).Hash
            $out = (Install-SwGlobal 3>&1) -join "`n"
            $global:LASTEXITCODE | Should -Be 1
            (Get-FileHash $file).Hash | Should -Be $bytes
            $out | Should -Match ([regex]::Escape("Kept $($file): its global rules block was edited after install"))
            $out | Should -Match '(?m)^claude rules\s+WARN\s+.*edited locally'
            $out | Should -Match 'PARTIAL: 1 edited, unverified, changed or read-only'
            Get-Entry $h (Join-Path $h '.claude') 'CLAUDE.md#global' | Should -Be $RulesHash
            Set-NewRules
            $out = (Install-SwGlobal 3>&1) -join "`n"
            $global:LASTEXITCODE | Should -Be 1
            (Get-FileHash $file).Hash | Should -Be $bytes
            Get-Entry $h (Join-Path $h '.claude') 'CLAUDE.md#global' | Should -Be $RulesHash -Because 'the baseline is kept so the edit stays detected'
            Get-Entry $h (Join-Path $h '.codex') 'AGENTS.md#global' | Should -Be $NewHash -Because 'other targets proceed'
            $out | Should -Match 'Resolve: move the edit to the central source'
            $out | Should -Match 'delete the block from <!-- sw:begin global --> through <!-- sw:end global -->'
            # Each refused install has its own snapshot and incoming copy; the second operation's copy holds the new rules.
            $incoming = @(Get-ChildItem (Join-Path $h '.sw/backups') -Recurse -File -Force | Where-Object { $_.FullName -match '[\\/]incoming[\\/]claude-[0-9a-f]{12}[\\/]CLAUDE\.md$' })
            $incoming.Count | Should -Be 2
            $m = [regex]::Match($out, [regex]::Escape("git diff --no-index `"$file`" `"") + '(?<in>[^"]+)"')
            $m.Success | Should -BeTrue
            $second = $m.Groups['in'].Value
            @($incoming.FullName) | Should -Contain $second
            Read-SwText $second | Should -Be ("mine`n`n" + (Get-Block 'new rules'))
        }

        It 'with no record, a block matching no shipped version is refused and never adopted; deleting it resolves the block' {
            $h = New-Home
            $file = Join-Path $h '.claude/CLAUDE.md'
            Write-SwFile $file ("mine`n`n" + (Get-Block 'hand made') + "after`n")
            $bytes = (Get-FileHash $file).Hash
            $out = (Install-SwGlobal 3>&1) -join "`n"
            $global:LASTEXITCODE | Should -Be 1
            (Get-FileHash $file).Hash | Should -Be $bytes
            $out | Should -Match 'cannot be shown unedited'
            Get-Entry $h (Join-Path $h '.claude') 'CLAUDE.md#global' | Should -BeNullOrEmpty
            Get-Entry $h (Join-Path $h '.codex') 'AGENTS.md#global' | Should -Be $RulesHash
            # The user moves the edit to the source and deletes the block; install then writes it from the source.
            Write-SwFile $file "mine`n`nafter`n"
            Install-SwGlobal | Out-Null
            $global:LASTEXITCODE | Should -Be 0
            Read-SwText $file | Should -Be ("mine`n`nafter`n`n" + (Get-Block (Read-SwText $RulesPath)))
            Get-Entry $h (Join-Path $h '.claude') 'CLAUDE.md#global' | Should -Be $RulesHash
        }

        It 'multi-home: an edit in one home blocks only that home; untargeted homes and their entries are untouched' {
            $h = New-Home
            Install-SwGlobal | Out-Null
            $defaults = (Get-Tree (Join-Path $h '.claude')) + '|' + (Get-Tree (Join-Path $h '.codex'))
            $a = Join-Path $TestDrive "claudeA$(New-Id)"; $b = Join-Path $TestDrive "claudeB$(New-Id)"; $x = Join-Path $TestDrive "codexX$(New-Id)"
            foreach ($d in $a, $b, $x) { New-Item -ItemType Directory -Path $d | Out-Null }
            Install-SwGlobal -ClaudeConfigDir $a, $b -CodexHome $x | Out-Null
            $global:LASTEXITCODE | Should -Be 0
            Edit-Block (Join-Path $a 'CLAUDE.md')
            $aBytes = (Get-FileHash (Join-Path $a 'CLAUDE.md')).Hash
            Set-NewRules
            Install-SwGlobal -ClaudeConfigDir $a, $b -CodexHome $x 3>&1 | Out-Null
            $global:LASTEXITCODE | Should -Be 1
            (Get-FileHash (Join-Path $a 'CLAUDE.md')).Hash | Should -Be $aBytes
            Read-SwText (Join-Path $b 'CLAUDE.md') | Should -Be (Get-Block 'new rules')
            Get-Entry $h $a 'CLAUDE.md#global' | Should -Be $RulesHash
            Get-Entry $h $b 'CLAUDE.md#global' | Should -Be $NewHash
            Get-Entry $h $x 'AGENTS.md#global' | Should -Be $NewHash
            (Get-Tree (Join-Path $h '.claude')) + '|' + (Get-Tree (Join-Path $h '.codex')) | Should -Be $defaults
            Get-Entry $h (Join-Path $h '.claude') 'CLAUDE.md#global' | Should -Be $RulesHash -Because 'untargeted entries are carried over'
            Get-Entry $h (Join-Path $h '.codex') 'AGENTS.md#global' | Should -Be $RulesHash
        }

        It 'one directory used as both a Claude and a Codex home keeps one entry per file' {
            $h = New-Home
            $d = Join-Path $TestDrive "both$(New-Id)"
            New-Item -ItemType Directory -Path $d | Out-Null
            Install-SwGlobal -ClaudeConfigDir $d -CodexHome $d | Out-Null
            $global:LASTEXITCODE | Should -Be 0
            (Get-Record $h)['homes'][$d]['kind'] | Should -Be 'claude+codex'
            Get-Entry $h $d 'CLAUDE.md#global' | Should -Be $RulesHash
            Get-Entry $h $d 'AGENTS.md#global' | Should -Be $RulesHash
            Install-SwGlobal -ClaudeConfigDir $d -CodexHome $d | Out-Null
            $global:LASTEXITCODE | Should -Be 0
        }

        It 'broken markers in a later home or a directory at the block file stop the run before any write (<Name>)' -ForEach @(
            @{ Name = 'malformed markers'; Expect = '*nothing was written*Unterminated managed block*' }
            @{ Name = 'directory at CLAUDE.md'; Expect = '*nothing was written*not a file*' }
        ) {
            $h = New-Home
            $a = Join-Path $TestDrive "claudeA$(New-Id)"; $b = Join-Path $TestDrive "claudeB$(New-Id)"
            Write-SwFile (Join-Path $a 'CLAUDE.md') "a mine`n"
            if ($Name -eq 'malformed markers') { Write-SwFile (Join-Path $b 'CLAUDE.md') "b mine`n<!-- sw:begin global -->`nhalf`n" }
            else { New-Item -ItemType Directory -Path (Join-Path $b 'CLAUDE.md') -Force | Out-Null }
            $before = (Get-Tree $h -Dirs) + '|' + (Get-Tree $a -Dirs) + '|' + (Get-Tree $b -Dirs)
            { Install-SwGlobal -ClaudeConfigDir $a, $b } | Should -Throw $Expect
            (Get-Tree $h -Dirs) + '|' + (Get-Tree $a -Dirs) + '|' + (Get-Tree $b -Dirs) | Should -Be $before
            Test-Path (Join-Path $h '.sw') | Should -BeFalse
            $out = (Test-SwGlobal -ClaudeConfigDir $a, $b) -join "`n"
            $out | Should -Match "(?m)^claude rules\s+FAILED\s+$([regex]::Escape((Join-Path $b 'CLAUDE.md')))"
            $global:LASTEXITCODE | Should -Be 1
        }

        It 'an invalid record (<Name>) stops install before any write; check reports FAILED and writes nothing' -ForEach @(
            @{ Name = 'not JSON'; Json = 'not json' }
            @{ Name = 'schema 2'; Json = '{"schema":2,"kitVersion":"x","kitCommit":null,"homes":{}}' }
            @{ Name = 'missing key'; Json = '{"schema":1,"homes":{}}' }
            @{ Name = 'unknown key'; Json = '{"schema":1,"kitVersion":"x","kitCommit":null,"homes":{},"extra":1}' }
            @{ Name = 'non-hex hash'; Json = '{"schema":1,"kitVersion":"x","kitCommit":null,"homes":{HOME:{"kind":"claude","entries":{"CLAUDE.md#global":"XYZ"}}}}' }
            @{ Name = 'unknown entry'; Json = '{"schema":1,"kitVersion":"x","kitCommit":null,"homes":{HOME:{"kind":"claude","entries":{"settings.json":"HASH"}}}}' }
            @{ Name = 'kind mismatch'; Json = '{"schema":1,"kitVersion":"x","kitCommit":null,"homes":{HOME:{"kind":"codex","entries":{"CLAUDE.md#global":"HASH"}}}}' }
            @{ Name = 'relative home'; Json = '{"schema":1,"kitVersion":"x","kitCommit":null,"homes":{"rel/home":{"kind":"claude","entries":{"CLAUDE.md#global":"HASH"}}}}' }
            @{ Name = 'kitVersion false'; Json = '{"schema":1,"kitVersion":false,"kitCommit":null,"homes":{}}' }
            @{ Name = 'kitVersion list'; Json = '{"schema":1,"kitVersion":[],"kitCommit":null,"homes":{}}' }
            @{ Name = 'kitVersion number'; Json = '{"schema":1,"kitVersion":1,"kitCommit":null,"homes":{}}' }
            @{ Name = 'kitCommit false'; Json = '{"schema":1,"kitVersion":"x","kitCommit":false,"homes":{}}' }
            @{ Name = 'kitCommit list'; Json = '{"schema":1,"kitVersion":"x","kitCommit":[],"homes":{}}' }
            @{ Name = 'kitCommit number'; Json = '{"schema":1,"kitVersion":"x","kitCommit":1,"homes":{}}' }
            @{ Name = 'duplicate top-level key'; Json = '{"schema":1,"schema":1,"kitVersion":"x","kitCommit":null,"homes":{}}' }
            @{ Name = 'duplicate home'; Json = '{"schema":1,"kitVersion":"x","kitCommit":null,"homes":{HOME:{"kind":"claude","entries":{"CLAUDE.md#global":"HASH"}},HOME:{"kind":"claude","entries":{"CLAUDE.md#global":"HASH"}}}}' }
            @{ Name = 'duplicate entry'; Json = '{"schema":1,"kitVersion":"x","kitCommit":null,"homes":{HOME:{"kind":"claude","entries":{"CLAUDE.md#global":"HASH","CLAUDE.md#global":"HASH"}}}}' }
            # Forms ConvertFrom-Json takes but strict JSON does not; each could hide a duplicate whose last copy wins.
            @{ Name = 'single-quoted duplicate entry'; Json = '{"schema":1,"kitVersion":"x","kitCommit":null,"homes":{HOME:{"kind":"claude","entries":{"CLAUDE.md#global":"HASH",''CLAUDE.md#global'':"HASH"}}}}' }
            @{ Name = 'unquoted key'; Json = '{schema:1,"kitVersion":"x","kitCommit":null,"homes":{}}' }
            @{ Name = 'comment hiding a duplicate'; Json = '{"schema":1,"kitVersion":"x","kitCommit":null,"homes":{HOME:{"kind":"claude","entries":{"CLAUDE.md#global":"HASH" /* } */,"CLAUDE.md#global":"HASH"}}}}' }
            @{ Name = 'trailing comma'; Json = '{"schema":1,"kitVersion":"x","kitCommit":null,"homes":{},}' }
            @{ Name = 'home differing only by case'; Json = '{"schema":1,"kitVersion":"x","kitCommit":null,"homes":{HOME:{"kind":"claude","entries":{"CLAUDE.md#global":"HASH"}},UPPER:{"kind":"claude","entries":{"CLAUDE.md#global":"HASH"}}}}' }
        ) {
            $h = New-Home
            $c = Join-Path $h '.claude'
            $json = $Json.Replace('HOME', ($c | ConvertTo-Json)).Replace('UPPER', ($c.ToUpperInvariant() | ConvertTo-Json)).Replace('HASH', $RulesHash)
            Write-SwFile (Join-Path $h '.sw/global.json') $json
            $before = Get-Tree $h -Dirs
            { Install-SwGlobal } | Should -Throw '*Invalid global baseline record*'
            Get-Tree $h -Dirs | Should -Be $before
            $out = (Test-SwGlobal) -join "`n"
            $out | Should -Match '(?m)^claude rules\s+FAILED\s+.*Invalid global baseline record'
            $global:LASTEXITCODE | Should -Be 1
            Get-Tree $h -Dirs | Should -Be $before
        }

        It 'the record check takes strict JSON only and names a hidden duplicate' {
            InModuleScope Sw.Kit {
                Assert-SwStrictJson " {`"a`":[1,-2.5e3,true,false,null,{}],`"b\/\u00e9`":{`"c`":`"x\ty`"},`"d`":[]}`r`n"
                { Assert-SwStrictJson '{1:2}' } | Should -Throw '*object key must be a double-quoted string*'
                { Assert-SwStrictJson '{"a":1,"a":2}' } | Should -Throw "*duplicate key 'a'*"
                { Assert-SwStrictJson '{"ab":1,"ab":2}' } | Should -Throw "*duplicate key 'ab'*"
                foreach ($bad in '{a:1}', '{"a":1,''a'':2}', '{"a":1,}', '[1,]', '{"a":1} // x', '{"a":01}', "{`"a`":`"x`ny`"}", '{"a":1}{}', "{`"a`":1}$([char]0xA0)", '') {
                    { Assert-SwStrictJson $bad } | Should -Throw '*not strict JSON*' -Because $bad
                }
            }
        }

        It 'the record rename keeps the old file whole when the replace fails, and leaves no backup' {
            $d = Join-Path $TestDrive "replace$(New-Id)"; New-Item -ItemType Directory -Path $d | Out-Null
            $dst = Join-Path $d 'global.json'
            $src = Join-Path $d 'global.json.op1.tmp'
            Write-SwFile $dst "old`n"; Write-SwFile $src "new`n"
            InModuleScope Sw.Kit -Parameters @{ S = $src; D = $dst } { param($S, $D) Move-SwFileReplace $S $D }
            Read-SwText $dst | Should -Be "new`n"
            @(Get-ChildItem -LiteralPath $d -Force).Name | Should -Be @('global.json')
            foreach ($held in 'source', 'destination') {
                $src = Join-Path $d "global.json.op-$held.tmp"; Write-SwFile $src "newer`n"
                $fs = [IO.FileStream]::new($(if ($held -eq 'source') { $src } else { $dst }), [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::None)
                try { { InModuleScope Sw.Kit -Parameters @{ S = $src; D = $dst } { param($S, $D) Move-SwFileReplace $S $D } } | Should -Throw } finally { $fs.Dispose() }
                Read-SwText $dst | Should -Be "new`n" -Because "the $held was held open"
                @(Get-ChildItem -LiteralPath $d -Filter '*.bak' -Force).Count | Should -Be 0
                Remove-Item -LiteralPath $src -Force
            }
        }

        It 'declined record consent writes no block' {
            $h = New-Home
            $homes = (Get-Tree (Join-Path $h '.claude')) + '|' + (Get-Tree (Join-Path $h '.codex'))
            $result = Invoke-ConfirmInstall $h 'record their baselines'
            $result.ExitCode | Should -Be 1
            $result.Denied | Should -Be 1
            (Get-Tree (Join-Path $h '.claude')) + '|' + (Get-Tree (Join-Path $h '.codex')) | Should -Be $homes
            Test-Path (Join-Path $h '.sw') | Should -BeFalse -Because 'a declined run takes no lock and no backup'
        }

        It 'a directory appearing at global.json during the consent prompt stops the run with nothing written' {
            $h = New-Home
            $homes = (Get-Tree (Join-Path $h '.claude')) + '|' + (Get-Tree (Join-Path $h '.codex'))
            $record = Join-Path $h '.sw/global.json'
            { Invoke-ConfirmInstall $h 'a^' 'record their baselines' $record '' } | Should -Throw '*Invalid global baseline record*not a file*'
            Test-Path -LiteralPath $record -PathType Container | Should -BeTrue -Because 'the hook ran during the prompt'
            (Get-Tree (Join-Path $h '.claude')) + '|' + (Get-Tree (Join-Path $h '.codex')) | Should -Be $homes
            Test-Path (Join-Path $h '.sw/backups') | Should -BeFalse
            Test-Path (Join-Path $h '.sw/global.lock') | Should -BeFalse
        }

        It 'a target turned malformed during the consent prompt stops the run before any block is written' {
            $h = New-Home
            $agents = Join-Path $h '.codex/AGENTS.md'
            { Invoke-ConfirmInstall $h 'a^' 'record their baselines' $agents "<!-- sw:begin global -->`n" } | Should -Throw '*cannot be judged, nothing was written*Unterminated managed block*'
            Read-SwText $agents | Should -Be "codex mine`n<!-- sw:begin global -->`n" -Because 'only the hook changed it'
            Read-SwText (Join-Path $h '.claude/CLAUDE.md') | Should -Be "mine`n" -Because 'the earlier target is not written either'
            Test-Path (Join-Path $h '.sw/backups') | Should -BeFalse
            Test-Path (Join-Path $h '.sw/global.json') | Should -BeFalse
            Test-Path (Join-Path $h '.sw/global.lock') | Should -BeFalse
        }

        It 'an edit made while the <Prompt> prompt is open is kept, not overwritten or recorded' -ForEach @(
            @{ Prompt = 'record consent'; EditOn = 'record their baselines'; File = '.claude/CLAUDE.md'; Other = '.codex/AGENTS.md'; Key = 'CLAUDE.md#global'; Dir = '.claude' }
            @{ Prompt = 'block write'; EditOn = 'set global rules block.*AGENTS\.md'; File = '.codex/AGENTS.md'; Other = '.claude/CLAUDE.md'; Key = 'AGENTS.md#global'; Dir = '.codex' }
        ) {
            $h = New-Home
            Install-SwGlobal | Out-Null
            $file = Join-Path $h $File
            $expected = (Read-SwText $file) + "late edit`n"
            $result = Invoke-ConfirmInstall $h 'a^' $EditOn $file "late edit`n" -NewRules
            $result.Edited | Should -Be 1
            $result.Denied | Should -Be 0
            $result.ExitCode | Should -Be 1
            Read-SwText $file | Should -Be $expected
            Get-Entry $h (Join-Path $h $Dir) $Key | Should -Be $RulesHash -Because 'the old baseline stays, so the edit is judged on the next run'
            Read-SwText (Join-Path $h $Other) | Should -Match "(?s)begin global -->`nnew rules`n<!-- sw:end" -Because 'other targets proceed'
        }

        It 'a failed record write after block writes self-heals on the next run (blocks equal the source)' {
            $h = New-Home
            $global:SwFailRecord = $true
            Mock -ModuleName Sw.Kit Move-SwFileReplace -ParameterFilter { $global:SwFailRecord } { throw 'injected record failure' }
            try {
                { Install-SwGlobal } | Should -Throw '*injected record failure*'
                Read-SwText (Join-Path $h '.claude/CLAUDE.md') | Should -Match '<!-- sw:begin global -->'
                Test-Path (Join-Path $h '.sw/global.json') | Should -BeFalse
                $global:SwFailRecord = $false
                Install-SwGlobal | Out-Null
                $global:LASTEXITCODE | Should -Be 0
                Get-Entry $h (Join-Path $h '.claude') 'CLAUDE.md#global' | Should -Be $RulesHash
            } finally { Remove-Variable SwFailRecord -Scope Global -ErrorAction SilentlyContinue }
        }

        It 'the guarded write keeps a file that changed after it was judged, or that is open elsewhere' {
            $dir = Join-Path $TestDrive "guard$(New-Id)"
            $file = Join-Path $dir 'CLAUDE.md'
            Write-SwFile $file "judged`n"
            $state = [pscustomobject]@{ Target = [pscustomobject]@{ File = $file }; State = 'stale'; Text = "judged`n" }
            Write-SwFile $file "judged`nedited after judging`n"
            InModuleScope Sw.Kit -Parameters @{ S = $state } { param($S) Write-SwGlobalGuarded $S "new`n" } | Should -Be 'changed'
            Read-SwText $file | Should -Be "judged`nedited after judging`n"
            Write-SwFile $file "judged`n"
            $held = [IO.File]::Open($file, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
            try { InModuleScope Sw.Kit -Parameters @{ S = $state } { param($S) Write-SwGlobalGuarded $S "new`n" } | Should -Be 'changed' }
            finally { $held.Dispose() }
            Read-SwText $file | Should -Be "judged`n"
            InModuleScope Sw.Kit -Parameters @{ S = $state } { param($S) Write-SwGlobalGuarded $S "new`n" } | Should -Be 'ok'
            Read-SwText $file | Should -Be "new`n"
            $missing = [pscustomobject]@{ Target = [pscustomobject]@{ File = (Join-Path $dir 'AGENTS.md') }; State = 'missing-file'; Text = '' }
            Write-SwFile $missing.Target.File "appeared`n"
            InModuleScope Sw.Kit -Parameters @{ S = $missing } { param($S) Write-SwGlobalGuarded $S "new`n" } | Should -Be 'changed'
            Read-SwText $missing.Target.File | Should -Be "appeared`n"
        }

        It 'a held install lock stops install before any write and is left in place' {
            $h = New-Home
            $lock = Join-Path $h '.sw/global.lock'
            Write-SwFile $lock ''
            $before = Get-Tree $h -Dirs
            { Install-SwGlobal } | Should -Throw "*Another global install holds*nothing was written*"
            Get-Tree $h -Dirs | Should -Be $before
            Test-Path -LiteralPath $lock | Should -BeTrue
            Remove-Item -LiteralPath $lock
            Install-SwGlobal | Out-Null
            $global:LASTEXITCODE | Should -Be 0
            Test-Path -LiteralPath $lock | Should -BeFalse -Because 'a lock this run created is removed when it ends'
        }

        It 'a read-only file: a current block is recorded; one needing an update is kept and stays read-only' {
            $h = New-Home
            Install-SwGlobal | Out-Null
            $file = Join-Path $h '.claude/CLAUDE.md'
            Remove-Item (Join-Path $h '.sw/global.json')
            (Get-Item -LiteralPath $file).IsReadOnly = $true
            try {
                Install-SwGlobal | Out-Null
                $global:LASTEXITCODE | Should -Be 0
                Get-Entry $h (Join-Path $h '.claude') 'CLAUDE.md#global' | Should -Be $RulesHash
                $bytes = (Get-FileHash $file).Hash
                Set-NewRules
                $out = (Install-SwGlobal 3>&1) -join "`n"
                $global:LASTEXITCODE | Should -Be 1
                $out | Should -Match ([regex]::Escape("Kept $($file): it is read-only"))
                (Get-FileHash $file).Hash | Should -Be $bytes
                (Get-Item -LiteralPath $file).IsReadOnly | Should -BeTrue -Because 'install never clears the attribute'
                Get-Entry $h (Join-Path $h '.claude') 'CLAUDE.md#global' | Should -Be $RulesHash
                Get-Entry $h (Join-Path $h '.codex') 'AGENTS.md#global' | Should -Be $NewHash
            } finally { (Get-Item -LiteralPath $file).IsReadOnly = $false }
        }

        It 'a write failure after truncation stops the run as FAILED naming the file and snapshot, and records nothing' {
            $h = New-Home
            $file = Join-Path $h '.claude/CLAUDE.md'
            Mock -ModuleName Sw.Kit Write-SwStreamBytes { throw 'injected write failure' }
            $err = $null
            try { Install-SwGlobal | Out-Null } catch { $err = $_.Exception.Message }
            $err | Should -Not -BeNullOrEmpty
            $err | Should -Match ([regex]::Escape("FAILED writing $($file): ") + '.*injected write failure')
            $snap = @(Get-ChildItem (Join-Path $h '.sw/backups') -Directory)
            $snap.Count | Should -Be 1
            $err | Should -Match ([regex]::Escape("pre-install snapshot $($snap[0].FullName)"))
            Read-SwText (Join-Path $snap[0].FullName '.claude/CLAUDE.md') | Should -Be "mine`n"
            Test-Path (Join-Path $h '.sw/global.json') | Should -BeFalse -Because 'the run stopped before the record'
            Test-Path (Join-Path $h '.sw/global.lock') | Should -BeFalse
            InModuleScope Sw.Kit -Parameters @{ F = $file } {
                param($F)
                Write-SwFile $F "judged`n"
                $s = [pscustomobject]@{ Target = [pscustomobject]@{ File = $F }; State = 'stale'; Text = "judged`n" }
                { Write-SwGlobalGuarded $s "new`n" } | Should -Throw '*FAILED writing*'
            }
        }

        It 'a record changed by another install after the preflight read stops the run before any write' {
            $h = New-Home
            $homes = (Get-Tree (Join-Path $h '.claude')) + '|' + (Get-Tree (Join-Path $h '.codex'))
            # The preflight read returns no baselines while another run writes the record behind it.
            Mock -ModuleName Sw.Kit Read-SwGlobalBaseline { Write-SwFile $Path ('{"schema":1,"kitVersion":"x","kitCommit":null,"homes":{}}' + "`n"); [ordered]@{ homes = [ordered]@{} } }
            { Install-SwGlobal } | Should -Throw '*record changed after it was read*nothing was written*'
            (Get-Tree (Join-Path $h '.claude')) + '|' + (Get-Tree (Join-Path $h '.codex')) | Should -Be $homes
            Test-Path (Join-Path $h '.sw/backups') | Should -BeFalse
            Test-Path (Join-Path $h '.sw/global.lock') | Should -BeFalse
        }

        It 'the record is in the pre-install snapshot, and a failed record write leaves every home''s entries whole' {
            $h = New-Home
            Install-SwGlobal | Out-Null
            $record = Join-Path $h '.sw/global.json'
            $before = Read-SwText $record
            $a = Join-Path $TestDrive "claudeA$(New-Id)"
            New-Item -ItemType Directory -Path $a | Out-Null
            Mock -ModuleName Sw.Kit Move-SwFileReplace { throw 'injected record failure' }
            { Install-SwGlobal -ClaudeConfigDir $a } | Should -Throw '*injected record failure*'
            Read-SwText $record | Should -Be $before -Because 'the untargeted default homes keep their entries'
            @(Get-ChildItem (Join-Path $h '.sw') -Filter 'global.json.*.tmp' -File -Force).Count | Should -Be 0
            $saved = @(Get-ChildItem (Join-Path $h '.sw/backups') -Recurse -File -Force | Where-Object { $_.FullName -match '[\\/]backups[\\/][^\\/]+[\\/]\.sw[\\/]global\.json$' })
            $saved.Count | Should -Be 1
            Read-SwText $saved[0].FullName | Should -Be $before
        }

        It 'check flags a broad gh allow in settings.json (<Rule>) and never rewrites it' -ForEach @(
            @{ Rule = 'Bash(gh *)'; Broad = $true }
            @{ Rule = 'Bash(gh:*)'; Broad = $true }
            @{ Rule = 'Bash(gh)'; Broad = $true }
            @{ Rule = 'Bash(gh pr view:*)'; Broad = $false }
        ) {
            $h = New-Home
            $settings = Join-Path $h '.claude/settings.json'
            Write-SwFile $settings (ConvertTo-SwJson ([ordered]@{ permissions = [ordered]@{ allow = @($Rule) } }))
            $bytes = (Get-FileHash $settings).Hash
            $out = (Test-SwGlobal) -join "`n"
            if ($Broad) { $out | Should -Match '(?m)^claude gh allow\s+WARN\s+broad gh allow permits gh writes' }
            else { $out | Should -Match '(?m)^claude gh allow\s+OK\s+read-only' }
            (Get-FileHash $settings).Hash | Should -Be $bytes
        }

        It 'check reports OK, outdated, edited, unverified and missing as WARN rows with exit 0, and never creates the record' {
            $h = New-Home
            $a = Join-Path $TestDrive "ok$(New-Id)"; $b = Join-Path $TestDrive "edited$(New-Id)"; $c = Join-Path $TestDrive "unverified$(New-Id)"; $d = Join-Path $TestDrive "missing$(New-Id)"
            foreach ($dir in $a, $b, $c, $d) { New-Item -ItemType Directory -Path $dir | Out-Null }
            $before = Get-Tree $h
            (Test-SwGlobal -ClaudeConfigDir $a) -join "`n" | Should -Match '(?m)^claude rules\s+WARN\s+.*missing, run global install'
            Get-Tree $h | Should -Be $before -Because 'check never creates the record'
            Install-SwGlobal -ClaudeConfigDir $a, $b | Out-Null
            Edit-Block (Join-Path $b 'CLAUDE.md')
            Write-SwFile (Join-Path $c 'CLAUDE.md') (Get-Block 'hand made')
            $before = Get-Tree $h
            $out = (Test-SwGlobal -ClaudeConfigDir $a, $b, $c, $d) -join "`n"
            $global:LASTEXITCODE | Should -Be 0
            $out | Should -Match "(?m)^claude rules\s+OK\s+$([regex]::Escape((Join-Path $a 'CLAUDE.md'))) \(parameter\)"
            $out | Should -Match "(?m)^claude rules\s+WARN\s+$([regex]::Escape((Join-Path $b 'CLAUDE.md'))) \(parameter\); edited locally"
            $out | Should -Match "(?m)^claude rules\s+WARN\s+$([regex]::Escape((Join-Path $c 'CLAUDE.md'))) \(parameter\); cannot be shown unedited"
            $out | Should -Match "(?m)^claude rules\s+WARN\s+$([regex]::Escape((Join-Path $d 'CLAUDE.md'))) \(parameter\); missing"
            Set-NewRules
            $out = (Test-SwGlobal -ClaudeConfigDir $a) -join "`n"
            $out | Should -Match "(?m)^claude rules\s+WARN\s+$([regex]::Escape((Join-Path $a 'CLAUDE.md'))) \(parameter\); outdated, run global install"
            $global:LASTEXITCODE | Should -Be 0
            Get-Tree $h | Should -Be $before
        }

        It 'a CRLF-only difference from a shipped version is unedited; a trailing space is an edit' {
            $h = New-Home
            $claude = Join-Path $h '.claude/CLAUDE.md'; $codex = Join-Path $h '.codex/AGENTS.md'
            [IO.File]::WriteAllText($claude, ("mine`n`n" + (Get-Block (Read-SwText $RulesPath))).Replace("`n", "`r`n"))
            Write-SwFile $codex ("codex mine`n`n" + (Get-Block (Read-SwText $RulesPath)).Replace("`n<!-- sw:end", " `n<!-- sw:end"))
            $claudeBytes = (Get-FileHash $claude).Hash; $codexBytes = (Get-FileHash $codex).Hash
            $out = (Install-SwGlobal 3>&1) -join "`n"
            $global:LASTEXITCODE | Should -Be 1
            (Get-FileHash $claude).Hash | Should -Be $claudeBytes -Because 'a current block is not rewritten'
            Get-Entry $h (Join-Path $h '.claude') 'CLAUDE.md#global' | Should -Be $RulesHash
            (Get-FileHash $codex).Hash | Should -Be $codexBytes
            $out | Should -Match ([regex]::Escape("Kept $($codex): its global rules block cannot be shown unedited"))
            Get-Entry $h (Join-Path $h '.codex') 'AGENTS.md#global' | Should -BeNullOrEmpty
        }
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
        @($manifest['files'].Keys | Sort-Object) | Should -Be @($script:Render.Files.Keys | Sort-Object) -Because 'the complete owned inventory, not a narrow sample'
        foreach ($rel in $script:Render.Files.Keys) {
            # A git-ignored rendered file (.sw/comms/README.md with local records) is absent in a fresh checkout or worktree.
            if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot $rel) -PathType Leaf)) {
                git -C $RepoRoot check-ignore -q -- $rel
                $LASTEXITCODE | Should -Be 0 -Because "$rel is missing, so it must be an ignored local file"
            }
            else { Read-SwText (Join-Path $RepoRoot $rel) | Should -Be $script:Render.Files[$rel] -Because $rel }
            $manifest['files'][$rel] | Should -Be (Get-SwHash $script:Render.Files[$rel]) -Because "manifest $rel"
        }
    }

    It 'onboarding enters the checkout directory between clone and doctor' {
        $script:Render.Files['.sw/onboarding.md'] | Should -Match '(?m)^git clone <repo-url>\r?\ncd <checkout-directory>\r?\npowershell -NoProfile -ExecutionPolicy Bypass -File \.sw/sw\.ps1 doctor -User <you>$'
    }

    It 'guidance qualifies static checks and names the generated hard-limit files' {
        $text = $script:Render.Files['.sw/workspace.md']
        $text | Should -Match 'does not scan for credentials'
        $text | Should -Not -Match 'sw validate` enforces this'
        $text | Should -Match '\.claude/settings\.json'
        $text | Should -Match '\.codex/rules/workspace\.rules'
    }

    It 'auto-merge is enabled only after review and passing CI on the current revision, never trusting unrequired checks' {
        # Owner M7 decision 2: CI is not a required check, so auto-merge alone does not wait for it.
        foreach ($text in $script:Render.AgentsTemplate, $script:Render.Files['.sw/workspace.md'], $script:Render.Files['.sw/collaboration.md']) {
            $text | Should -Match 'CI checks on the current pull request\s+revision\s+have passed'
        }
        foreach ($rel in '.sw/workspace.md', '.sw/collaboration.md') { $script:Render.Files[$rel] | Should -Match 'gh pr merge --disable-auto' -Because $rel }
        $script:Render.Files['.sw/workspace.md'] | Should -Not -Match 'GitHub merges once required checks pass'
        # Task ci-minutes: drafts run no CI (draft, review, ready, CI, auto-merge); a quota/billing stop has a local gate.
        foreach ($text in $script:Render.AgentsTemplate, $script:Render.Files['.sw/workspace.md']) {
            $text | Should -Match '(?s)Drafts? .{0,20}run no CI.*review.*gh pr ready.*gh pr merge --auto'
            $text | Should -Match '(?s)quota or\s+billing\s+reason.*full\s+(local\s+)?test\s+suite\s+on\s+every\s+shell.*sw validate`\s+and\s+review.*pull\s+request\s+body\s+and\s+task\s+record'
        }
        $script:Render.Files['.sw/collaboration.md'] | Should -Match '(?s)Drafts run no CI.*gh pr ready.*quota fallback gate'
        $script:Render.Files['.sw/workspace.md'] | Should -Match '(?m)^\| 2 \| .*`gh pr ready`.*quota fallback gate'
    }

    It 'user-invoked skills, and only they, carry Codex explicit-only metadata in both skill copies' {
        # Owner M7 decision 3; format from the Codex skills docs: <skill>/agents/openai.yaml, policy.allow_implicit_invocation.
        $files = (Get-SwRender ([ordered]@{ project = 'U'; profile = 'unreal'; github = $true; users = @() })).Files
        $names = @($files.Keys | Where-Object { $_ -match '^\.agents/skills/[^/]+/SKILL\.md$' } | ForEach-Object { $_.Split('/')[2] })
        $names.Count | Should -Be 11
        foreach ($name in $names) {
            $userInvoked = $files[".agents/skills/$name/SKILL.md"] -cmatch '(?m)^disable-model-invocation: true$'
            foreach ($root in '.agents', '.claude') {
                $meta = "$root/skills/$name/agents/openai.yaml"
                if ($userInvoked) { $files[$meta] | Should -Match '(?m)^policy:\n  allow_implicit_invocation: false$' -Because $meta }
                else { $files.Contains($meta) | Should -BeFalse -Because $meta }
            }
        }
        @($files.Keys | Where-Object { $_ -like '*/agents/openai.yaml' }).Count | Should -Be 14
        $generic = (Get-SwRender ([ordered]@{ project = 'G'; profile = 'generic'; github = $true; users = @(); selection = [ordered]@{ version = 1; capabilities = @() } })).Files
        foreach ($root in '.agents', '.claude') { $generic.Contains("$root/skills/research/agents/openai.yaml") | Should -BeFalse }
    }

    It 'core and global rules cap ordinary repair at three attempts and stop at once on quota, rate or permission failures' {
        # Owner M7 decision 7: the rule homes are the AGENTS core Safety section and the global rules.
        foreach ($text in $script:Render.AgentsCore, (Read-SwText (Join-Path $RepoRoot 'global/rules.md'))) {
            $text | Should -Match 'Ordinary repair work gets at most three attempts, then stop and\s+report'
            $text | Should -Match 'quota, rate-limit or permission failure means stop at once: never\s+retry\s+around it or bypass it'
        }
        $script:Render.AgentsCore | Should -Match 'remaining steps of an\s+approved plan \(`resume`\), proceed without asking again'
    }

    It 'no installed kit file names the retired OpenCode surface, roles or adapter commands' {
        foreach ($rel in $script:Render.Files.Keys | Where-Object { $_ -notmatch '^\.sw/lib/|^\.sw/sw\.ps1$' }) {
            $script:Render.Files[$rel] | Should -Not -Match '(?i)opencode|project-leader|sw (claude|tiers|manager) ' -Because $rel
        }
        $script:Render.AgentsTemplate | Should -Not -Match '(?i)opencode|project-leader'
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
        # Built-in patterns are generic. Private names come from an optional,
        # gitignored tests/leak-patterns.local.txt (one regex per line, # comments).
        $patterns = @('BiscuitDoesStuff', '[A-Za-z]:\\+Users\\')
        $localFile = Join-Path $RepoRoot 'tests/leak-patterns.local.txt'
        if (Test-Path -LiteralPath $localFile) {
            $patterns += @((Read-SwText $localFile) -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
        }
        $sourcePaths = @('sw.ps1', 'VERSION', 'lib', 'project', 'global') | ForEach-Object { Join-Path $RepoRoot $_ }
        $hits = Get-ChildItem -LiteralPath $sourcePaths -Recurse -File -Force |
            Select-String -Pattern $patterns
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

    It 'shared budget arithmetic matches known byte fixtures and the default or configured cap' {
        $skills = @{ sk = @{ description = 'zz' }; ([string][char]0xE9) = @{ description = 'd' } }
        $b = Get-SwStartupBudget @{} 'abc' $skills
        $b.Scope | Should -Be 'session'
        $b.AgentsMd | Should -Be 3
        $b.Skills | Should -Be (4 + 3)
        $b.Total | Should -Be 10
        $b.Tokens | Should -Be 3
        $b.Cap | Should -Be 12100
        (Get-SwStartupBudget @{ startupBudgetBytes = 10 } 'abc' $skills).Cap | Should -Be 10
    }

    It 'reports the same session total and cap as validate, and a lowered cap still fails validate only' {
        $dir = New-ContextProject
        $validate = @(Test-SwProject -Path $dir | Where-Object { $_ -like 'Startup budget:*' } | ForEach-Object { $_ -replace '^Startup budget: (\S+) = (\d+) bytes.*cap (\d+)$', '$1 $2 $3' })
        $context = @(Get-SwContext -Path $dir | Where-Object { $_ -match '^session: agents_md=' } | ForEach-Object { $_ -replace '^(\S+): .* total=(\d+) .* cap=(\d+) .*$', '$1 $2 $3' })
        $validate.Count | Should -Be 1
        $context | Should -Be $validate
        $config = Get-SwConfig $dir; $config['startupBudgetBytes'] = 100
        Write-SwFile (Join-Path $dir '.sw/config.json') (ConvertTo-SwJson $config)
        $result = Test-SwValidate $dir
        $result.ExitCode | Should -Be 1
        ($result.Output -join "`n") | Should -Match 'Startup budget exceeded for session: \d+ > 100 bytes'
        $out = @(Get-SwContext -Path $dir)
        $global:LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'cap=100 within_cap=no'
    }

    It 'is deterministic for unchanged inputs and writes nothing, including Git metadata' {
        $dir = New-ContextProject
        Invoke-SwNative git @('-C', $dir, 'add', '-A'); Invoke-SwNative git @('-C', $dir, 'commit', '-qm', 'init')
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
        New-Item -ItemType Junction -Path (Join-Path $dir 'linked') -Target $target | Out-Null
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
        Write-SwFile (Join-Path $dir '.agents/skills/work/SKILL.md') "not frontmatter`n"
        $text = (Get-SwContext -Path $dir) -join "`n"
        $global:LASTEXITCODE | Should -Be 0
        $text | Should -Match 'core: incomplete \(\.agents/skills/work/SKILL\.md failed\)'
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

    It 'project CLI exposes context with explicit exits' {
        $dir = New-ContextProject
        $cli = Join-Path $dir '.sw/sw.ps1'
        & $script:Shell -NoProfile -ExecutionPolicy Bypass -File $cli context -StateFile docs/state.md | Out-Null
        $LASTEXITCODE | Should -Be 0
        Invoke-SwNative $script:Shell @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $cli, 'context', '-StateFile', '../x.md') | Out-Null
        $LASTEXITCODE | Should -Not -Be 0
        (& $script:Shell -NoProfile -ExecutionPolicy Bypass -File $cli help) -join "`n" | Should -Match '(?m)^  context '
    }

    It 'status, resume and handoff carry the recovery card and keep exits, effects and approval separate' {
        $render = Get-SwRender ([ordered]@{ project = 'P'; profile = 'generic'; github = $true; users = @(); selection = [ordered]@{ version = 1; capabilities = @() } })
        $status = $render.Files['.agents/skills/status/SKILL.md']
        foreach ($field in 'Task / objective:', 'Applicable approval / allowed scope / source:', 'Owner / dependencies / conflicts:', 'Artifacts / checked revision / dirty scope:', 'Last verified checkpoint / evidence:', 'Process outcome: observed exit | missing/unknown', 'Effects: confirmed occurred | confirmed did not occur | unknown', 'Outstanding checks / missing evidence:', 'One permitted next action / responsible owner:') {
            $status | Should -Match ([regex]::Escape($field))
        }
        $status | Should -Match 'missing exit is unknown'
        $status | Should -Match 'superseded approval never authorizes'
        $resume = $render.Files['.agents/skills/resume/SKILL.md']
        $resume | Should -Match 'never retry it blindly'
        $resume | Should -Match 'superseded approval\s+is never approval'
        $render.Files['.agents/skills/handoff/SKILL.md'] | Should -Match 'not\s+delivery, acknowledgment or'
    }

    Context 'C1 correction: scoped reads, completeness, Git and stability' {
        BeforeAll {
            function New-Link([string]$Path, [string]$Target, [string]$Type = 'Junction') {
                New-Item -ItemType $Type -Path $Path -Target $Target -ErrorAction Stop | Out-Null
            }
            function New-Outside {
                $out = Join-Path $TestDrive "outside$(New-Id)"
                Write-SwFile (Join-Path $out 'skill/SKILL.md') "---`nname: linked`ndescription: OUTSIDE-SENTINEL`n---`nOUTSIDE-SENTINEL`n"
                Write-SwFile (Join-Path $out 'tasks/2026-01-01T000000Z-x-approval.md') "OUTSIDE-SENTINEL`n"
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

        It 'never reads or enters linked directories in skills, tasks or archive' {
            $dir = New-ContextProject; $out = New-Outside
            $links = @(
                @((Join-Path $dir '.agents/skills/linked'), (Join-Path $out 'skill')),
                @((Join-Path $dir '.sw/comms/tasks/linked'), (Join-Path $out 'tasks')),
                @((Join-Path $dir '.sw/comms/archive/t1'), (Join-Path $out 'archive')))
            New-Item -ItemType Directory (Join-Path $dir '.sw/comms/tasks/t1'), (Join-Path $dir '.sw/comms/archive') -Force | Out-Null
            foreach ($l in $links) { New-Link $l[0] $l[1] }
            Start-ReadSpy
            $text = (Get-SwContext -Path $dir -Task t1) -join "`n"
            $global:LASTEXITCODE | Should -Be 0
            $text | Should -Not -Match 'OUTSIDE-SENTINEL'
            $text | Should -Match 'core: incomplete \(\.agents/skills incomplete\)'
            $text | Should -Not -Match '(?m)^session: agents_md='
            $text | Should -Match 'skills: incomplete \(1 entries not followed'
            $text | Should -Not -Match 'skill: linked'
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
            (Get-SwContext -Path $dir) -join "`n" | Should -Match '(?m)^session: agents_md='
        }

        It 'never reads linked skill, policy or state files (needs file-symlink privilege)' {
            $dir = New-ContextProject; $out = New-Outside
            $files = @('.agents/skills/review/SKILL.md', '.sw/workspace.md', 'docs/linked.md')
            try {
                foreach ($f in $files) { $p = Join-Path $dir $f; Remove-Item -LiteralPath $p -Force -ErrorAction Ignore; New-Link $p (Join-Path $out 'policy.md') 'SymbolicLink' }
            } catch { Set-ItResult -Skipped -Because "file symbolic links unavailable here: $($_.Exception.Message)"; return }
            Start-ReadSpy
            $text = (Get-SwContext -Path $dir) -join "`n"
            $text | Should -Not -Match 'OUTSIDE-SENTINEL'
            $text | Should -Match 'core: incomplete \(\.agents/skills incomplete\)'
            $text | Should -Match 'policy: \.sw/workspace\.md unavailable \(unsafe\)'
            Get-InsideLink @($files | ForEach-Object { [IO.Path]::GetFullPath((Join-Path $dir $_)) }) | Should -BeNullOrEmpty
            { Get-SwContext -Path $dir -StateFile docs/linked.md } | Should -Throw '*link or junction*'
        }

        It 'distinguishes missing sources from genuinely empty directories' {
            $dir = New-ContextProject
            foreach ($d in '.agents/skills', '.sw/comms/tasks') { Remove-Item -LiteralPath (Join-Path $dir $d) -Recurse -Force -ErrorAction Ignore }
            $text = (Get-SwContext -Path $dir) -join "`n"
            $text | Should -Match 'skills: unavailable \(missing: \.agents/skills\)'
            $text | Should -Match 'core: incomplete \(\.agents/skills missing\); session total withheld'
            $text | Should -Match 'tasks: unavailable \(missing: \.sw/comms/tasks\)'
            $text | Should -Not -Match 'skill_metadata=0'
            foreach ($d in '.agents/skills', '.sw/comms/tasks') { New-Item -ItemType Directory (Join-Path $dir $d) -Force | Out-Null }
            $text = (Get-SwContext -Path $dir) -join "`n"
            $global:LASTEXITCODE | Should -Be 0
            $text | Should -Match '(?m)^session: agents_md=\d+ skill_metadata=0 '
            $text | Should -Match 'tasks: candidates=0 listed=0 omitted=0'
            (Test-SwValidate $dir).ExitCode | Should -Be 1
        }

        It 'turns denied, failing or vanishing reads, listings and stamps into an incomplete report that exits zero' {
            $dir = New-ContextProject
            Invoke-SwComms event -Task t1 -From tester -Path $dir | Out-Null
            Mock -ModuleName Sw.Project Read-SwText { throw [UnauthorizedAccessException]::new('denied PRIVATE-VALUE') } -ParameterFilter { $Path -like '*workspace.md' }
            Mock -ModuleName Sw.Project Read-SwFrontmatter { throw 'Unsupported frontmatter at line 2: PRIVATE-VALUE' } -ParameterFilter { $Path -like '*minimal-change*SKILL.md' }
            Mock -ModuleName Sw.Project Get-ChildItem { throw [IO.DirectoryNotFoundException]::new('vanished') } -ParameterFilter { $LiteralPath -like '*tasks*t1' }
            Mock -ModuleName Sw.Project Get-Item { throw [UnauthorizedAccessException]::new('denied') } -ParameterFilter { $LiteralPath -like '*tasks*t1' -or $LiteralPath -like '*docs*state.md' }
            $out = @(Get-SwContext -Path $dir -Task t1 -StateFile docs/state.md)
            $global:LASTEXITCODE | Should -Be 0
            $text = $out -join "`n"
            $text | Should -Match 'policy: \.sw/workspace\.md unavailable \(failed\)'
            $text | Should -Match 'core: incomplete \(\.agents/skills/minimal-change/SKILL\.md failed\)'
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
                $text | Should -Match '(?m)^session: agents_md='
                $text | Should -Match 'checkout: unavailable \(git could not be run; not retried\)'
                Should -Invoke git -ModuleName Sw.Project -Times 1 -Exactly
                # The installed CLI sets SW_ROOT itself; the real missing-Git child imports the module to exercise implicit discovery.
                $pwshExe = (Get-Process -Id $PID).Path
                $script = "Remove-Item Env:SW_ROOT -ErrorAction Ignore; `$env:PATH = '$PSHOME'; if (Get-Command git -ErrorAction Ignore) { 'git still on PATH'; exit 9 }; Import-Module ./.sw/lib/Sw.Project.psm1 -DisableNameChecking; Get-SwContext; exit `$LASTEXITCODE"
                $child = (& $pwshExe -NoProfile -Command $script) -join "`n"
                $LASTEXITCODE | Should -Be 0
                $child | Should -Match '(?m)^session: agents_md='
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
            $a = (& $pwshExe -NoProfile -ExecutionPolicy Bypass -File $cli context -Task t1 -StateFile docs/state.md) -join "`n"; $exitA = $LASTEXITCODE
            $b = (& $pwshExe -NoProfile -ExecutionPolicy Bypass -File $cli context -Task t1 -StateFile docs/state.md) -join "`n"; $exitB = $LASTEXITCODE
            $exitA, $exitB | Should -Be @(0, 0)
            $a | Should -Be $b
            $a | Should -Match '(?m)^session: agents_md='
            $c = (& $pwshExe -NoProfile -ExecutionPolicy Bypass -File $cli context) -join "`n"
            [regex]::Matches($c, '(?m)^candidate: (\S+)').ForEach({ $_.Groups[1].Value }) | Should -Be @('B2', 'a1', 'c3', 't1')
        }

        It 'does not run a configured fsmonitor hook or change index bytes' {
            $dir = New-ContextProject
            Invoke-SwNative git @('-C', $dir, 'add', '-A'); Invoke-SwNative git @('-C', $dir, 'commit', '-qm', 'init')
            $marker = Join-Path $TestDrive "fsmonitor$(New-Id).log"
            $hook = Join-Path $TestDrive "fsmonitor$(New-Id).sh"
            [IO.File]::WriteAllText($hook, "#!/bin/sh`necho invoked >> '$($marker.Replace('\', '/'))'`nexit 1`n")
            git -C $dir config core.fsmonitor $hook.Replace('\', '/')
            Invoke-SwNative git @('-C', $dir, 'status') | Out-Null
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
            foreach ($f in Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Sort-Object FullName) { $map[(Get-SwRelativePath $Root $f.FullName)] = Get-SwByteHash ([IO.File]::ReadAllBytes($f.FullName)) }
            $map | ConvertTo-Json -Compress
        }
        function Get-SkillNames([string]$Root, [string]$Dir = '.agents/skills') { @(Get-ChildItem -LiteralPath (Join-Path $Root $Dir) -Directory -Force | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') } | ForEach-Object Name | Sort-Object) }
        function Get-Effective([string]$Root) { (Read-SwJson (Join-Path $Root '.sw/profile.json'))['effectiveSelection'] }
        function Set-Selection([string]$Root, [string]$Profile) {
            $c = Get-SwConfig $Root; $c['profile'] = $Profile; Write-SwFile (Join-Path $Root '.sw/config.json') (ConvertTo-SwJson $c)
        }
        function New-KitCopy([string]$Name) {
            # Isolated kit for source-corruption cases; the live source tree is never rewritten.
            $kit = Join-Path $TestDrive $Name
            New-Item -ItemType Directory -Path $kit | Out-Null
            foreach ($p in 'lib', 'project', 'sw.ps1', 'VERSION', 'LICENSE', 'THIRD_PARTY_NOTICES.md') { Copy-Item -LiteralPath (Join-Path $RepoRoot $p) -Destination (Join-Path $kit $p) -Recurse }
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
        $script:Generic = @('agent-documentation', 'handoff', 'minimal-change', 'resume', 'review', 'status', 'structured-debugging', 'validate', 'work')
    }

    Context 'A1 fresh generic default' {
        It 'installs exactly the nine core skills in both skill directories; no research' {
            $dir = New-SelProject "a1$(New-Id)"
            (Get-SwConfig $dir)['selection']['version'] | Should -Be 1
            Get-SkillNames $dir | Should -Be $script:Generic
            Get-SkillNames $dir '.claude/skills' | Should -Be $script:Generic
            Test-Path (Join-Path $dir '.sw/roles.json') | Should -BeFalse
            Read-SwText (Join-Path $dir 'AGENTS.md') | Should -Not -Match 'Capability: research'
            $sel = Get-Effective $dir
            @($sel.Keys) | Should -Be @('version', 'profile', 'capabilities', 'skills', 'context', 'checks')
            @($sel['checks']) | Should -Not -Contain 'research-evidence'
            @($sel['context']) | Should -Be @('core', 'generic')
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

        It 'a fresh install defaults to GitHub tier 0; a project-set tier is project-owned and survives update' {
            $dir = New-SelProject "a1t$(New-Id)"
            (Get-SwConfig $dir)['githubTier'] | Should -Be 0
            $c = Get-SwConfig $dir; $c['githubTier'] = 2; Write-SwFile (Join-Path $dir '.sw/config.json') (ConvertTo-SwJson $c)
            $tree = Get-Tree $dir
            Update-SwProject -Path $dir | Out-Null
            Get-Tree $dir | Should -Be $tree
            (Get-SwConfig $dir)['githubTier'] | Should -Be 2
            (Test-SwValidate $dir).ExitCode | Should -Be 0
        }
    }

    Context 'A2 research preset and capability' {
        It 'the research preset and generic + research add exactly the research skill, both copies, guidance and checks' {
            $base = Get-SwRender (Get-V1Config)
            foreach ($cfg in (Get-V1Config research), (Get-V1Config generic @('research'))) {
                $r = Get-SwRender $cfg
                @($r.Files.Keys | Where-Object { -not $base.Files.Contains($_) } | Sort-Object) | Should -Be @('.agents/skills/research/agents/openai.yaml', '.agents/skills/research/SKILL.md',
                    '.claude/skills/research/agents/openai.yaml', '.claude/skills/research/SKILL.md')
                @($base.Files.Keys | Where-Object { -not $r.Files.Contains($_) }).Count | Should -Be 0
                @($r.Selection.checks) | Should -Contain 'research-evidence'
                @($r.Selection.context) | Should -Contain 'research'
                @($r.Selection.capabilities) | Should -Be @('research')
                ([regex]::Matches($r.AgentsProfile, '## Capability: research')).Count | Should -Be 1
            }
            # Naming the preset's own capability again duplicates nothing.
            ((Get-SwRender (Get-V1Config research @('research'))).Files | ConvertTo-Json -Depth 3) | Should -Be ((Get-SwRender (Get-V1Config research)).Files | ConvertTo-Json -Depth 3)
        }

        It 'a research-preset install validates and keeps research guidance request-scoped' {
            $dir = New-SelProject "a2$(New-Id)" research
            (Test-SwValidate $dir).ExitCode | Should -Be 0
            $agents = Read-SwText (Join-Path $dir 'AGENTS.md')
            $agents | Should -Match '## Profile: research'
            $agents | Should -Match 'does not authorize implementation'
        }
    }

    Context 'A4 Unreal preset' {
        It 'keeps its validation skill, context, checks, Claude edit denies and LFS' {
            $dir = New-SelProject "a4$(New-Id)" unreal
            Get-SkillNames $dir | Should -Contain 'unreal-validation'
            Get-SkillNames $dir '.claude/skills' | Should -Contain 'unreal-validation'
            @((Get-Effective $dir)['checks']) | Should -Contain 'unreal-validation'
            Read-SwText (Join-Path $dir 'AGENTS.md') | Should -Match 'Profile: Unreal Engine'
            Read-SwText (Join-Path $dir '.gitattributes') | Should -Match '\*\.uasset filter=lfs'
            (Read-SwJson (Join-Path $dir '.claude/settings.json'))['permissions']['deny'] | Should -Contain 'Edit(**/*.umap)'
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

    Context 'A6 malformed selection fails closed' {
        BeforeAll {
            $script:CatText = Read-SwText (Join-Path $RepoRoot 'project/selection.json')
            function Invoke-Resolve([scriptblock]$Mutate) {
                $x = @{ cat = (ConvertFrom-SwJson $script:CatText); prof = (Read-SwJson (Join-Path $RepoRoot 'project/profiles/generic/profile.json')); sel = [ordered]@{ version = 1; capabilities = @() } }
                & $Mutate $x
                Resolve-SwSelection $x.sel 'generic' $x.prof $x.cat
            }
        }

        It 'the unmodified catalogue resolves' { @((Invoke-Resolve { }).skills) | Should -Be $script:Generic }

        It 'rejects <Name>' -ForEach @(
            @{ Name = 'catalogue version 1'; M = { param($x) $x.cat['version'] = 1 } }
            @{ Name = 'an unsupported catalogue key'; M = { param($x) $x.cat['hooks'] = @() } }
            @{ Name = 'a retired roleSkills key'; M = { param($x) $x.cat['roleSkills'] = @{} } }
            @{ Name = 'a scalar list'; M = { param($x) $x.cat['capabilities']['research']['skills'] = 'research' } }
            @{ Name = 'a null list'; M = { param($x) $x.cat['core']['checks'] = $null } }
            @{ Name = 'a duplicate list entry'; M = { param($x) $x.cat['core']['skills'] = @($x.cat['core']['skills']) + 'work' } }
            @{ Name = 'a path-like ID'; M = { param($x) $x.cat['capabilities']['research']['skills'] = @('../escape') } }
            @{ Name = 'a noncanonical ID'; M = { param($x) $x.sel['capabilities'] = @('Research') } }
            @{ Name = 'an unknown capability'; M = { param($x) $x.sel['capabilities'] = @('telemetry') } }
            @{ Name = 'the retired provider-setup capability'; M = { param($x) $x.sel['capabilities'] = @('provider-setup') } }
            @{ Name = 'config version 2'; M = { param($x) $x.sel['version'] = 2 } }
            @{ Name = 'an unsupported config key'; M = { param($x) $x.sel['roles'] = @('project-review') } }
            @{ Name = 'scalar config capabilities'; M = { param($x) $x.sel['capabilities'] = 'research' } }
            @{ Name = 'a duplicate config capability'; M = { param($x) $x.sel['capabilities'] = @('research', 'research') } }
            @{ Name = 'a non-object selection'; M = { param($x) $x.sel = 'v1' } }
            @{ Name = 'a dropped core skill floor'; M = { param($x) $x.cat['core']['skills'] = @('work', 'resume', 'handoff', 'review', 'validate') } }
            @{ Name = 'a dropped core context floor'; M = { param($x) $x.cat['core']['context'] = @() } }
            @{ Name = 'a dropped core check floor'; M = { param($x) $x.cat['core']['checks'] = @('workspace-static') } }
            @{ Name = 'an invalid context ID'; M = { param($x) $x.prof['composition']['context'] = @('mobile') } }
            @{ Name = 'an invalid check ID'; M = { param($x) $x.cat['capabilities']['research']['checks'] = @('run-anything') } }
            @{ Name = 'a composition still listing roles'; M = { param($x) $x.prof['composition']['roles'] = @('project-leader') } }
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
            @{ Name = 'core skill'; Rel = 'project/base/.agents/skills/work/SKILL.md'; Caps = @() }
            @{ Name = 'capability skill (unselected)'; Rel = 'project/base/.agents/skills/research/SKILL.md'; Caps = @() }
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

        It 'a capability naming a skill the kit lacks fails' {
            $kit = New-KitCopy "kitDep$(New-Id)"
            $cat = Read-SwJson (Join-Path $kit 'project/selection.json'); $cat['capabilities']['research']['skills'] = @('research', 'ghost-skill')
            Write-SwFile (Join-Path $kit 'project/selection.json') (ConvertTo-SwJson $cat)
            Use-Kit $kit { { Get-SwRender (Get-V1Config) } | Should -Throw '*ghost-skill*' }
        }
    }

    Context 'A7 legacy compatibility' {
        It 'legacy <Profile> keeps every base skill and the old profile.skills meaning; update never opts in' -ForEach @(
            @{ Profile = 'generic' }, @{ Profile = 'unreal' }
        ) {
            $dir = New-SwProject "a7$Profile$(New-Id)" $Profile -Legacy
            $expected = @(@('agent-documentation', 'handoff', 'minimal-change', 'research', 'resume', 'review', 'status', 'structured-debugging', 'validate', 'work') + @(if ($Profile -eq 'unreal') { 'unreal-validation' }) | Sort-Object)
            Get-SkillNames $dir | Should -Be $expected
            Get-SkillNames $dir '.claude/skills' | Should -Be $expected
            Test-Path (Join-Path $dir '.sw/selection.json') | Should -BeFalse
            (Read-SwJson (Join-Path $dir '.sw/profile.json')).Contains('effectiveSelection') | Should -BeFalse
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
            foreach ($p in '.agents/skills/research/SKILL.md', '.claude/skills/research/SKILL.md') { Test-Path (Join-Path $dir $p) | Should -BeFalse }
            (Get-SwConfig $dir)['selection']['version'] | Should -Be 1
            (Test-SwValidate $dir).ExitCode | Should -Be 0
        }

        It 'a <Name> deselected file blocks legacy-to-v1 with nothing written, even with -Force -Adopt' -ForEach @(
            @{ Name = 'modified'; Prep = { param($d) Write-SwFile (Join-Path $d '.agents/skills/research/SKILL.md') ((Read-SwText (Join-Path $d '.agents/skills/research/SKILL.md')) + "`nlocal edit`n") }; Expect = '*.agents/skills/research/SKILL.md (modified)*' }
            @{ Name = 'modified Claude copy'; Prep = { param($d) Write-SwFile (Join-Path $d '.claude/skills/research/SKILL.md') ((Read-SwText (Join-Path $d '.claude/skills/research/SKILL.md')) + "`nlocal edit`n") }; Expect = '*.claude/skills/research/SKILL.md (modified)*' }
            @{ Name = 'unowned resource'; Prep = { param($d) Write-SwFile (Join-Path $d '.agents/skills/research/notes.md') "mine`n" }; Expect = '*research/notes.md (unowned*' }
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
            # Whole ownership/path preflight now rejects this before deselection-specific diagnostics.
            { Update-SwProject -Path $dir -SelectionV1 } | Should -Throw '*link or junction*'
            Get-Tree $dir | Should -Be $tree
        }

        It 'v1 capability-off removes multi-file capability skills as a unit from both directories; an edit blocks it' {
            $kit = New-KitCopy "kitRes$(New-Id)"
            Write-SwFile (Join-Path $kit 'project/base/.agents/skills/research/reference.md') "extra resource`n"
            Use-Kit $kit {
                $dir = New-SelProject "a8off$(New-Id)" generic @('research')
                Test-Path (Join-Path $dir '.agents/skills/research/reference.md') | Should -BeTrue
                Test-Path (Join-Path $dir '.claude/skills/research/reference.md') | Should -BeTrue
                Write-SwFile (Join-Path $dir '.agents/skills/research/reference.md') "edited`n"
                $tree = Get-Tree $dir
                { Update-SwProject -Path $dir -Capabilities '' } | Should -Throw '*reference.md (modified)*'
                Get-Tree $dir | Should -Be $tree
                Write-SwFile (Join-Path $dir '.agents/skills/research/reference.md') "extra resource`n"
                Update-SwProject -Path $dir -Capabilities '' | Out-Null
                foreach ($root in '.agents', '.claude') { @(Get-ChildItem -LiteralPath (Join-Path $dir "$root/skills/research") -Recurse -File -ErrorAction SilentlyContinue).Count | Should -Be 0 }
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

        It 'existing update -WhatIf with an opt-in reports the plan and changes nothing' {
            $dir = New-SwProject "a9e$(New-Id)" generic -Legacy
            $tree = Get-Tree $dir
            $out = (Update-SwProject -Path $dir -SelectionV1 -WhatIf 6> $null) -join "`n"
            $out | Should -Match 'selection: v1 profile=generic capabilities=\[\]'
            $out | Should -Match '(?m)^remove\s+.*\.agents/skills/research/SKILL\.md'
            Get-Tree $dir | Should -Be $tree
        }
    }

    Context 'A11 extras and budget' {
        It 'keeps project-owned extras, counts their metadata, and validate and context agree on the budget' {
            $dir = New-SelProject "a11$(New-Id)"
            $session = { param($d)
                $ctx = (Get-SwContext -Path $d) -join "`n"
                $m = [regex]::Match($ctx, '(?m)^session: .*skill_metadata=(\d+) .*total=(\d+)')
                $v = [regex]::Match(((Test-SwProject -Path $d) -join "`n"), '(?m)^Startup budget: session = (\d+) bytes')
                [pscustomobject]@{ Skills = [int]$m.Groups[1].Value; Total = [int]$m.Groups[2].Value; Validate = [int]$v.Groups[1].Value }
            }
            $before = & $session $dir
            $before.Total | Should -BeGreaterThan 0
            $before.Total | Should -Be $before.Validate
            $desc = 'Project-owned helper skill.'
            Write-SwFile (Join-Path $dir '.agents/skills/my-skill/SKILL.md') "---`nname: my-skill`ndescription: $desc`n---`n`nBody.`n"
            Update-SwProject -Path $dir | Out-Null
            Test-Path (Join-Path $dir '.agents/skills/my-skill/SKILL.md') | Should -BeTrue
            $after = & $session $dir
            $after.Skills | Should -Be ($before.Skills + [Text.Encoding]::UTF8.GetByteCount("my-skill$desc"))
            $after.Total | Should -Be $after.Validate
            $out = Test-SwValidate $dir
            $out.ExitCode | Should -Be 0
            ($out.Output -join "`n") | Should -Match 'Project-owned extra kept, outside the selection: \.agents/skills/my-skill/'
        }

        It 'flags a known deselected skill and blocks the update' {
            $dir = New-SelProject "a11k$(New-Id)"
            Copy-Item -LiteralPath (Join-Path $RepoRoot 'project/base/.agents/skills/research') -Destination (Join-Path $dir '.agents/skills/research') -Recurse
            $out = Test-SwValidate $dir
            $out.ExitCode | Should -Be 1
            ($out.Output -join "`n") | Should -Match 'Deselected kit component installed: \.agents/skills/research/'
            $tree = Get-Tree $dir
            { Update-SwProject -Path $dir } | Should -Throw '*Selection change blocked*'
            Get-Tree $dir | Should -Be $tree
        }

        It 'a mismatched effectiveSelection is reported' {
            $dir = New-SelProject "a11m$(New-Id)"
            $p = Read-SwJson (Join-Path $dir '.sw/profile.json'); $p['effectiveSelection']['skills'] = @('handoff')
            Write-SwFile (Join-Path $dir '.sw/profile.json') (ConvertTo-SwJson $p)
            ((Test-SwValidate $dir).Output -join "`n") | Should -Match 'effectiveSelection does not match'
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
            Remove-Item -LiteralPath (Join-Path $kit 'project/base/.agents/skills/review/SKILL.md') -Force
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
            $out | Should -Match '(?m)^add\s+.*\.claude/skills/research/SKILL\.md'
            Test-Path -LiteralPath $dir | Should -BeFalse
        }

        It 'the renderer rejects a path-like profile before deriving a source path, legacy or v1' {
            { Get-SwRender (Get-V1Config '../profiles/generic') } | Should -Throw '*canonical*'
            $legacy = Get-V1Config; $legacy.Remove('selection'); $legacy['profile'] = '..\generic'
            { Get-SwRender $legacy } | Should -Throw '*canonical*'
        }
    }
}

Describe 'Audit repair regressions' {
    BeforeAll {
        function Audit-Tree([string]$Dir) {
            (@(Get-ChildItem -LiteralPath $Dir -Recurse -File -Force | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } | Sort-Object FullName | ForEach-Object { "$($_.FullName):$((Get-FileHash -LiteralPath $_.FullName).Hash)" }) -join "`n")
        }
        function Audit-Link([string]$Path, [string]$Target) {
            $parent = Split-Path $Path; if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            New-Item -ItemType Junction -Path $Path -Target $Target | Out-Null
        }
        function Audit-Confirm([string]$Root, [string]$Operation, [string]$Deny) {
            $fixtureHost = [SwAuditPromptHost]::new($Host, $Deny)
            $space = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($fixtureHost)
            $space.Open(); $ps = [Management.Automation.PowerShell]::Create(); $ps.Runspace = $space
            try {
                $null = $ps.AddScript({
                    param($Module, $Root, $Operation)
                    Import-Module (Join-Path (Split-Path $Module) 'Sw.Project.psm1') -Force -DisableNameChecking
                    Import-Module $Module -Force -DisableNameChecking
                    switch ($Operation) {
                        sync { Sync-SwProject -Root $Root -Config (Get-SwConfig $Root) -Confirm | Out-Null }
                    }
                    $global:LASTEXITCODE
                }.ToString()).AddArgument((Join-Path $RepoRoot 'lib/Sw.Kit.psm1')).AddArgument($Root).AddArgument($Operation)
                $values = @($ps.Invoke())
                if ($ps.HadErrors) { throw ($ps.Streams.Error -join "`n") }
                [pscustomobject]@{ ExitCode = $values[-1]; Denied = $fixtureHost.Denied }
            } finally { $ps.Dispose(); $space.Dispose() }
        }
    }

    It 'rejects manifest claim <Claim> before any effect' -ForEach @(
        @{ Claim = '../outside.md' }, @{ Claim = '/outside.md' }, @{ Claim = 'C:/outside.md' },
        @{ Claim = '.sw/../outside.md' }, @{ Claim = '.sw//workspace.md' }, @{ Claim = '.sw/workspace.md:stream' },
        @{ Claim = '.sw/workspace.md.' }, @{ Claim = '.SW/workspace.md' },
        @{ Claim = 'host-owned.md' }, @{ Claim = '.sw/comms/tasks/private/event.md' }
    ) {
        $dir = New-SwProject "manifest$(New-Id)"
        $path = Join-Path $dir '.sw/manifest.json'; $record = Read-SwJson $path
        $record['files'][$Claim] = '0' * 64; Write-SwFile $path (ConvertTo-SwJson $record)
        if ($Claim -eq '../outside.md') {
            $outside = Join-Path $TestDrive 'outside.md'; Write-SwFile $outside 'outside sentinel'
            $record['files'][$Claim] = Get-SwHash 'outside sentinel'; Write-SwFile $path (ConvertTo-SwJson $record)
        }
        $before = Audit-Tree $dir
        { Sync-SwProject -Root $dir -Config (Get-SwConfig $dir) } | Should -Throw
        Audit-Tree $dir | Should -Be $before
        if ($Claim -eq '../outside.md') { Read-SwText $outside | Should -Be 'outside sentinel' }
    }
    It 'rejects malformed manifest hashes and shape before effects' {
        $dir = New-SwProject "hash$(New-Id)"; $path = Join-Path $dir '.sw/manifest.json'; $record = Read-SwJson $path
        foreach ($bad in 'not-a-hash', $null, 3) {
            $record['files']['.sw/workspace.md'] = $bad; Write-SwFile $path (ConvertTo-SwJson $record)
            $before = Audit-Tree $dir
            { Sync-SwProject -Root $dir -Config (Get-SwConfig $dir) } | Should -Throw '*ownership manifest*'
            Audit-Tree $dir | Should -Be $before
        }
    }
    It 'refuses a linked managed target before adoption and Git init' {
        $dir = Join-Path $TestDrive "linked$(New-Id)"; $outside = Join-Path $TestDrive "sentinel$(New-Id)"
        Write-SwFile (Join-Path $outside 'workspace.rules') 'outside sentinel'; Audit-Link (Join-Path $dir '.codex/rules') $outside
        { Initialize-SwProject -Path $dir -Adopt } | Should -Throw '*link or junction*'
        Read-SwText (Join-Path $outside 'workspace.rules') | Should -Be 'outside sentinel'
        Test-Path (Join-Path $dir '.git') | Should -BeFalse
        Test-Path (Join-Path $dir '.sw/manifest.json') | Should -BeFalse
    }
    It 'rejects a file used as a participating ancestor before Git or output creation' {
        $dir = Join-Path $TestDrive "fileparent$(New-Id)"; Write-SwFile (Join-Path $dir '.claude') 'host file'
        $before = Audit-Tree $dir
        { Initialize-SwProject -Path $dir } | Should -Throw '*ancestor is not a directory*'
        Test-Path (Join-Path $dir '.git') | Should -BeFalse
        Test-Path (Join-Path $dir '.agents') | Should -BeFalse
        Audit-Tree $dir | Should -Be $before
    }
    It 'refuses linked installation roots and ancestors, leaving the physical project intact' {
        $real = New-SwProject "physical$(New-Id)"; $alias = Join-Path $TestDrive "alias$(New-Id)"
        $before = Audit-Tree $real; Audit-Link $alias $real
        { Update-SwProject -Path $alias } | Should -Throw '*link or junction*'
        { Initialize-SwProject -Path (Join-Path $alias 'new-child') } | Should -Throw '*link or junction*'
        Audit-Tree $real | Should -Be $before
        Test-Path (Join-Path $real 'new-child') | Should -BeFalse
    }
    It 'refuses a linked backup parent before any adoption effect' {
        $dir = Join-Path $TestDrive "backup$(New-Id)"; $outside = Join-Path $TestDrive "recovery$(New-Id)"
        Write-SwFile (Join-Path $dir '.sw/workspace.md') 'precious'; Write-SwFile (Join-Path $outside 'sentinel.md') 'outside'
        Audit-Link (Join-Path $dir '.sw/backup') $outside
        { Initialize-SwProject -Path $dir -Adopt } | Should -Throw '*link or junction*'
        Read-SwText (Join-Path $dir '.sw/workspace.md') | Should -Be 'precious'
        @(Get-ChildItem $outside -File).Count | Should -Be 1
        Test-Path (Join-Path $dir '.git') | Should -BeFalse
    }
    It 'leaves unrelated host links alone' {
        $dir = New-SwProject "unrelated$(New-Id)"; $outside = Join-Path $TestDrive "assets$(New-Id)"
        Write-SwFile (Join-Path $outside 'sentinel.md') 'host'; Audit-Link (Join-Path $dir 'assets') $outside
        Sync-SwProject -Root $dir -Config (Get-SwConfig $dir) | Out-Null
        $global:LASTEXITCODE | Should -Be 0
        Read-SwText (Join-Path $outside 'sentinel.md') | Should -Be 'host'
    }
    It 'new recovery/record helpers refuse linked ancestors before creating directories' {
        $outside = Join-Path $TestDrive "external$(New-Id)"; Write-SwFile (Join-Path $outside 'sentinel.md') 'keep'
        $alias = Join-Path $TestDrive "helperlink$(New-Id)"; Audit-Link $alias $outside
        { Write-SwNewFile (Join-Path $alias 'new/sub/file.md') 'must not write' } | Should -Throw '*link or junction*'
        Test-Path (Join-Path $outside 'new') | Should -BeFalse
    }
    It 'rejects invalid stored tier <Tier> before any write' -ForEach @(@{ Tier = 3 }, @{ Tier = '1' }, @{ Tier = $true }, @{ Tier = 1.0 }, @{ Tier = $null }) {
        $dir = New-SwProject "tier$(New-Id)"; $config = Get-SwConfig $dir; $config['githubTier'] = $Tier
        $before = Audit-Tree $dir
        { Sync-SwProject -Root $dir -Config $config } | Should -Throw '*supported integer*'
        Audit-Tree $dir | Should -Be $before
    }
    It 'preflights missing skill sources before target creation or Git init' {
        $kit = Join-Path $TestDrive "kit$(New-Id)"; New-Item -ItemType Directory $kit | Out-Null
        foreach ($rel in 'project', 'lib', 'sw.ps1', 'VERSION', 'LICENSE', 'THIRD_PARTY_NOTICES.md') { Copy-Item (Join-Path $RepoRoot $rel) (Join-Path $kit $rel) -Recurse }
        Remove-Item (Join-Path $kit 'project/base/.agents/skills/handoff/SKILL.md')
        $target = Join-Path $TestDrive "missing$(New-Id)"
        InModuleScope Sw.Kit -Parameters @{ Kit = $kit; Target = $target } {
            param($Kit, $Target); $saved = $script:Kit
            try { $script:Kit = $Kit; { Initialize-SwProject -Path $Target } | Should -Throw '*source definitions missing*' } finally { $script:Kit = $saved }
        }
        Test-Path $target | Should -BeFalse
    }
    It 'validation rejects missing core and profile LFS blocks' {
        $dir = New-SwProject "policy$(New-Id)" unreal; $path = Join-Path $dir 'AGENTS.md'
        Write-SwFile $path ([regex]::Replace((Read-SwText $path), '(?s)<!-- sw:begin core -->.*?<!-- sw:end core -->', ''))
        (Test-SwValidate $dir).ExitCode | Should -Be 1
        $other = New-SwProject "lfs$(New-Id)" unreal; Remove-Item -Force (Join-Path $other '.gitattributes')
        (Test-SwValidate $other).ExitCode | Should -Be 1
    }
    It 'repeated init and user recording preserve nonempty host placeholders' {
        $dir = New-SwProject "keep$(New-Id)"; $path = Join-Path $dir '.sw/comms/tasks/.gitkeep'; Write-SwFile $path 'host placeholder'
        Initialize-SwProject -Path $dir | Out-Null; Read-SwText $path | Should -Be 'host placeholder'
        $inbox = Join-Path $dir '.sw/comms/inbox/alpha/.gitkeep'; Write-SwFile $inbox 'host inbox'
        Add-SwUser alpha -Path $dir | Out-Null; Read-SwText $inbox | Should -Be 'host inbox'
    }
    It 'does not guess an ambiguous contributor inbox; explicit ID works' {
        $dir = New-SwProject "identity$(New-Id)"; Add-SwUser alpha -Path $dir | Out-Null; Add-SwUser beta -Path $dir | Out-Null
        { Invoke-SwComms inbox -Path $dir } | Should -Throw '*identity is ambiguous*'
        (Invoke-SwComms inbox -Path $dir -User alpha | Out-String) | Should -Match 'Inbox empty: alpha'
    }
    It 'mixed decline of an update retains original hashes and reports PARTIAL' {
        $dir = New-SwProject "decline$(New-Id)"; $rel = '.sw/workspace.md'; Write-SwFile (Join-Path $dir $rel) 'old kit'
        $path = Join-Path $dir '.sw/manifest.json'; $record = Read-SwJson $path; $record['files'][$rel] = Get-SwHash 'old kit'; Write-SwFile $path (ConvertTo-SwJson $record)
        $result = Audit-Confirm $dir sync ([regex]::Escape($rel))
        $result.Denied | Should -Be 1; $result.ExitCode | Should -Be 1
        Read-SwText (Join-Path $dir $rel) | Should -Be 'old kit'
        (Read-SwJson $path)['files'][$rel] | Should -Be (Get-SwHash 'old kit')
    }
    It 'mixed decline of retirement retains file and original ownership' {
        $dir = New-SwProject "retire$(New-Id)"; $rel = '.opencode/agents/project-documentation.md'; Write-SwFile (Join-Path $dir $rel) 'old role'
        $path = Join-Path $dir '.sw/manifest.json'; $record = Read-SwJson $path; $record['files'][$rel] = Get-SwHash 'old role'; Write-SwFile $path (ConvertTo-SwJson $record)
        $result = Audit-Confirm $dir sync ([regex]::Escape($rel)); $result.ExitCode | Should -Be 1
        Test-Path (Join-Path $dir $rel) | Should -BeTrue
        (Read-SwJson $path)['files'][$rel] | Should -Be (Get-SwHash 'old role')
    }
    It 'mixed decline of an edited old-prefix move retains original path and ownership' {
        $dir = New-SwProject "movedecline$(New-Id)"
        $old = '.opencode/skills/minimal-change/SKILL.md'; $new = '.agents/skills/minimal-change/SKILL.md'
        $text = Read-SwText (Join-Path $dir $new); $hash = Get-SwHash $text
        Write-SwFile (Join-Path $dir $old) ($text + "local edit`n")
        Remove-Item (Join-Path $dir $new)
        $path = Join-Path $dir '.sw/manifest.json'; $record = Read-SwJson $path
        $record['files'].Remove($new); $record['files'][$old] = $hash; Write-SwFile $path (ConvertTo-SwJson $record)
        $result = Audit-Confirm $dir sync 'move from'; $result.ExitCode | Should -Be 1
        Read-SwText (Join-Path $dir $old) | Should -Be ($text + "local edit`n")
        Test-Path (Join-Path $dir $new) | Should -BeFalse
        $after = (Read-SwJson $path)['files']; $after[$old] | Should -Be $hash; $after.Contains($new) | Should -BeFalse
    }
    It 'declined ownership write prevents all sync file effects' {
        $dir = New-SwProject "marker$(New-Id)"; $before = Audit-Tree $dir
        $result = Audit-Confirm $dir sync ([regex]::Escape('.sw/manifest.json'))
        $result.ExitCode | Should -Be 1; Audit-Tree $dir | Should -Be $before
    }
    It 'CI has immediate native exit guards and a first failure cannot be masked' {
        $yaml = Read-SwText (Join-Path $RepoRoot '.github/workflows/ci.yml')
        $yaml | Should -Match 'init \$t -Profile unreal -Name CiCheck\n\s+if \(\$LASTEXITCODE -ne 0\) \{ exit \$LASTEXITCODE \}'
        & $script:Shell -NoProfile -Command 'powershell -NoProfile -Command "exit 17"; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; powershell -NoProfile -Command "exit 0"'
        $LASTEXITCODE | Should -Be 17
    }
    It '<Rel> runs once per change: push on main only, pull requests when ready, drafts skipped' -ForEach @(
        @{ Rel = '.github/workflows/ci.yml'; DocsIgnored = $true },
        @{ Rel = 'project/github/.github/workflows/sw-validate.yml'; DocsIgnored = $false }
    ) {
        $yaml = Read-SwText (Join-Path $RepoRoot $Rel)
        $on = [regex]::Match($yaml, '(?ms)^on:\n(.*?)^\S').Groups[1].Value
        $on | Should -Match '(?m)^  push:\n    branches: \[main\]\n'
        $on | Should -Match '(?m)^  pull_request:\n    types: \[opened, synchronize, reopened, ready_for_review\]\n'
        @([regex]::Matches($on, '(?m)^  \w+:')).Count | Should -Be 2
        @([regex]::Matches($yaml, '(?m)^    if: \$\{\{ !github\.event\.pull_request\.draft \}\}\n')).Count | Should -Be @([regex]::Matches($yaml, '(?m)^    runs-on:')).Count
        $yaml | Should -Not -Match '\*\*/\*\.md'
        if ($DocsIgnored) {
            @([regex]::Matches($on, "(?m)^    paths-ignore: \['docs/\*\*'\]\n")).Count | Should -Be 2
        } else { $yaml | Should -Not -Match 'paths-ignore' }
    }
}

Describe 'Windows PowerShell 5.1 and PowerShell 7 parity' {
    BeforeAll {
        function Get-GitBlob([string]$Spec) {
            # Raw UTF-8 text of a committed file; PowerShell's native-output decoding differs between the shells.
            $psi = [Diagnostics.ProcessStartInfo]::new('git', "-C `"$RepoRoot`" show $Spec")
            $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
            $p = [Diagnostics.Process]::Start($psi)
            try {
                $err = $p.StandardError.ReadToEndAsync(); $text = $p.StandardOutput.ReadToEnd(); $p.WaitForExit(); $null = $err.Result
                if ($p.ExitCode -ne 0) { throw "git show $Spec failed" }; $text
            } finally { $p.Dispose() }
        }
        # The parity values: block hashes A7 records and compares, a fixed hash vector, and the generated JSON bytes.
        $script:ParityScript = {
            param($Root)
            Import-Module (Join-Path $Root 'lib/Sw.Project.psm1') -Force -DisableNameChecking
            Import-Module (Join-Path $Root 'lib/Sw.Kit.psm1') -Force -DisableNameChecking
            $rules = Read-SwText (Join-Path $Root 'global/rules.md')
            $json = foreach ($rel in '.claude/settings.json', '.sw/manifest.json', '.sw/profile.json', '.sw/config.json') { Get-SwHash (ConvertTo-SwJson (Read-SwJson (Join-Path $Root $rel))) }
            (@(& (Get-Module Sw.Kit) { $script:GlobalShipped }) + @(& (Get-Module Sw.Kit) { param($r) Get-SwHash (Get-SwGlobalBody $r) } $rules) + @(Get-SwHash "a`r`nb") + @($json)) -join ','
        }
    }

    It 'a native command that cannot launch stops the CLI instead of running on with a stale exit code' {
        $dir = New-SwProject "nogit$(New-Id)" generic
        $cli = Join-Path $dir '.sw/sw.ps1'
        $path = $env:PATH
        try {
            $env:PATH = (@($path -split ';' | Where-Object { $_ -and -not (Test-Path -LiteralPath (Join-Path $_ 'git.exe')) }) -join ';')
            Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Should -BeNullOrEmpty -Because 'git is off PATH for the child'
            $probe = "`$ErrorActionPreference = 'Continue'; Import-Module '$(Join-Path $RepoRoot 'lib/Sw.Project.psm1')' -DisableNameChecking; Invoke-SwNative git @('--version'); 'continued'"
            (@(Invoke-SwNative $script:Shell @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $probe)) -join "`n") | Should -Not -Match 'continued'
            # stderr is kept here (Continue, so 5.1 does not throw on it): the refusal must name git.
            $out = (& { $ErrorActionPreference = 'Continue'; & $script:Shell -NoProfile -ExecutionPolicy Bypass -File $cli comms event -Task nogit -From bob -Event progress -Body x 2>&1 } | ForEach-Object { "$_" }) -join "`n"
            $LASTEXITCODE | Should -Not -Be 0
            $out | Should -Match "'git'"
        } finally { $env:PATH = $path }
        Test-Path -LiteralPath (Join-Path $dir '.sw/comms/tasks/nogit') | Should -BeFalse -Because 'no event is recorded with a blank branch and HEAD'
    }

    It 'every shipped global rules hash is the block hash of global/rules.md at its commit' {
        $lines = @((Read-SwText (Join-Path $RepoRoot 'lib/Sw.Kit.psm1')) -split "`n" | Where-Object { $_ -match "^\s+'([0-9a-f]{64})' # ([0-9a-f]{7,})\s*$" })
        $lines.Count | Should -Be 10
        # A squashed public clone lacks most cited commits: verify those present, and always tie the newest entry to the current rules.
        $null = $lines[-1] -match "^\s+'([0-9a-f]{64})'"
        InModuleScope Sw.Kit -Parameters @{ T = (Read-SwText (Join-Path $RepoRoot 'global/rules.md')) } { param($T) Get-SwHash (Get-SwGlobalBody $T) } | Should -Be $Matches[1] -Because 'the newest shipped hash is the current global/rules.md'
        foreach ($line in $lines) {
            $null = $line -match "^\s+'([0-9a-f]{64})' # ([0-9a-f]{7,})"
            $hash, $commit = $Matches[1], $Matches[2]
            if (-not (& { $ErrorActionPreference = 'Continue'; git -C $RepoRoot cat-file -e "${commit}^{commit}" 2>$null; $LASTEXITCODE -eq 0 })) { continue }
            # The kit shipped from product/ for a while (fa7115d).
            $text = try { Get-GitBlob "${commit}:global/rules.md" } catch { Get-GitBlob "${commit}:product/global/rules.md" }
            InModuleScope Sw.Kit -Parameters @{ T = $text } { param($T) Get-SwHash (Get-SwGlobalBody $T) } | Should -Be $hash -Because "global/rules.md at $commit"
        }
    }

    It 'hashes use the SHA-256 lowercase hex of LF-normalized UTF-8 text' {
        Get-SwHash "a`r`nb" | Should -BeExactly '7e18f737311b2dc3b2f269dd78396b0351f14fb66efa879f768cb23181883c78'
    }

    It 'the generated JSON files are reproduced byte for byte by the kit JSON writer' {
        foreach ($rel in '.claude/settings.json', '.sw/manifest.json', '.sw/profile.json', '.sw/config.json') {
            $text = Read-SwText (Join-Path $RepoRoot $rel)
            ConvertTo-SwJson (Read-SwJson (Join-Path $RepoRoot $rel)) | Should -BeExactly $text -Because $rel
        }
    }

    It 'the other shell computes the same hashes and JSON bytes' {
        $other = if ($PSVersionTable.PSEdition -eq 'Core') { 'powershell' } else { 'pwsh' }
        $exe = Get-Command $other -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $exe) { Set-ItResult -Skipped -Because "$other is not installed here"; return }
        # Encoded, so neither shell's native argument quoting can alter the script.
        $command = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("& { $($script:ParityScript.ToString()) } '$RepoRoot'"))
        $mine = (& $script:Shell -NoProfile -ExecutionPolicy Bypass -EncodedCommand $command) -join ''
        $theirs = (& $exe.Source -NoProfile -ExecutionPolicy Bypass -EncodedCommand $command) -join ''
        $mine | Should -Match '^([0-9a-f]{64},){15}[0-9a-f]{64}$'
        $theirs | Should -BeExactly $mine
    }
}

Describe 'Review route' {
    It 'Codex stays the default; a single-provider review is an owner choice, never a way around a failure' {
        $skill = Read-SwText (Join-Path $RepoRoot 'project/base/.agents/skills/review/SKILL.md')
        $skill | Should -Match 'The reviewer is Codex by default'
        $skill | Should -Match '(?m)^## Single-provider review$'
        $skill | Should -Match 'no conversation history'
        $skill | Should -Match '"single-provider review" in the pull request and the task record'
        $skill | Should -Match 'quota, rate-limit or permission failure on the Codex route means\s+stop and ask the owner; never switch provider'
        $rules = Read-SwText (Join-Path $RepoRoot 'global/rules.md')
        $rules | Should -Match 'single-provider review'
        $rules | Should -Match 'Never switch provider\s+to get around a Codex failure'
    }
}

Describe 'Status skill' {
    It 'checks for a remote before reading a remote main, and reports a remote-free project as local-only' {
        $skill = Read-SwText (Join-Path $RepoRoot 'project/base/.agents/skills/status/SKILL.md')
        $skill | Should -Not -Match 'git rev-parse origin/main'
        $skill | Should -Match '`git remote`\. With a remote, also run'
        $skill | Should -Match '"local-only; no remote configured"'
    }
}
