#requires -Version 7.2
[CmdletBinding()]
param([switch]$ParseOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$module = Join-Path $root 'lib/Sw.Manager.psm1'
foreach ($file in $module, (Join-Path $root 'sw.ps1'), $PSCommandPath) {
    $tokens = $null; $errors = $null
    $null = [Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw ($errors.Message -join "`n") }
}
Import-Module (Join-Path $root 'lib/Sw.Project.psm1') -Force -DisableNameChecking
Import-Module $module -Force -DisableNameChecking
Write-Output 'PASS: manager parser and source module import.'
if ($ParseOnly) { exit 0 }
$script:checks = 0
function Assert($Condition, [string]$Message) {
    $script:checks++
    if (-not $Condition) { throw $Message }
}
function Reject([scriptblock]$Action, [string]$Pattern) {
    $message = $null
    try { $null = & $Action } catch { $message = $_.Exception.Message }
    Assert ($message -and $message -match $Pattern) "Expected rejection matching $Pattern; got $message"
}
function TreeHash([string]$Path) {
    (@(Get-ChildItem -LiteralPath $Path -File -Recurse -Force | Sort-Object FullName | ForEach-Object { "$($_.FullName):$((Get-FileHash -LiteralPath $_.FullName).Hash)" }) -join "`n")
}
$scratch = Join-Path $root '.scratch/manager'
if (-not (Test-Path -LiteralPath (Join-Path $scratch '.gitignore'))) { Write-SwFile (Join-Path $scratch '.gitignore') "*`n" }
$fixture = Join-Path $scratch (Get-SwOperationId)
$null = New-Item -ItemType Directory -Path $fixture
Write-Output "Fixture evidence: $fixture"
$before = TreeHash $fixture
Install-SwManager -Path $fixture -WhatIf | Out-Null
Assert ((TreeHash $fixture) -ceq $before) 'Install WhatIf writes nothing'
Install-SwManager -Path $fixture | Out-Null
Assert (-not (Test-Path -LiteralPath (Join-Path $fixture '.git'))) 'Manager installation never initializes Git'
Assert (-not (Test-Path -LiteralPath (Join-Path $fixture '.github'))) 'No GitHub/CI integration installed into root'
$before = TreeHash $fixture
Install-SwManager -Path $fixture | Out-Null
Assert ((TreeHash $fixture) -ceq $before) 'Repeated unchanged install preserves all content'
$oc = Read-SwJson (Join-Path $fixture 'opencode.jsonc')
Assert ($oc.Count -eq 2 -and $oc.Contains('$schema') -and $oc.Contains('agents')) 'Root config has no inherited defaults, models/providers/MCPs/compaction/permissions'
Assert ($oc['agents'].Count -eq 2 -and $oc['agents'].Contains('ws-manager') -and $oc['agents'].Contains('ws-planner')) 'Only namespaced role definitions'
foreach ($action in 'edit', 'shell', 'subagent', 'execute', 'websearch', 'webfetch', 'some_mcp_tool') {
    Assert ((Get-SwDecision $oc['agents']['ws-planner']['permissions'] $action '*') -eq 'deny') "Planner denies $action"
}
foreach ($action in 'install', 'register', 'approve', 'attach') {
    Assert ((Get-SwDecision $oc['agents']['ws-manager']['permissions'] 'shell' "pwsh -NoProfile -File .sw/sw.ps1 manager $action -Task example") -eq 'deny') "Manager cannot self-authorize $action"
}
Assert ((Get-SwDecision $oc['agents']['ws-manager']['permissions'] 'edit' '.sw/comms/tasks/any/manager-approval.json') -eq 'deny') 'Manager cannot forge approval through direct edits'
foreach ($action in 'status', 'request', 'start', 'send', 'collect', 'accept') {
    Assert ((Get-SwDecision $oc['agents']['ws-manager']['permissions'] 'shell' "pwsh -NoProfile -File .sw/sw.ps1 manager $action -Task example") -eq 'allow') "Manager can coordinate $action"
}
foreach ($id in 'research-notes', 'workspace', 'analysis') {
    $dir = switch ($id) { research-notes { 'Research Notes [2]' } workspace { 'Workspace' } default { 'Analysis' } }
    Write-SwFile (Join-Path $fixture "$dir/AGENTS.md") "# $id rules`nNo implementation approved.`n"
    Write-SwFile (Join-Path $fixture "$dir/docs/state.md") "# State`n`n## Startup`nCurrent $id scope.`n`n## History`nDo not use old approval.`n"
    Write-SwFile (Join-Path $fixture "$dir/opencode.jsonc") '{"default_agent":"project-leader","agents":{"project-developer":{"description":"existing"}},"compaction":{"auto":false}}'
    $childBefore = TreeHash (Join-Path $fixture $dir)
    Invoke-SwManager register -Path $fixture -Project $id -Directory $dir -StateFile 'docs/state.md' | Out-Null
    Assert ((TreeHash (Join-Path $fixture $dir)) -ceq $childBefore) "Register preserves $id child files"
}
$childrenBefore = @('Research Notes [2]', 'Workspace', 'Analysis') | ForEach-Object { TreeHash (Join-Path $fixture $_) }
Reject { Invoke-SwManager register -Path $fixture -Project bad -Directory '../outside' -StateFile 'state.md' } 'escapes'
Reject { Invoke-SwManager register -Path $fixture -Project bad -Directory 'Workspace' -StateFile '../AGENTS.md' } 'escapes'
Reject { Invoke-SwManager register -Path $fixture -Project workspace -Directory 'Workspace' -StateFile 'docs/state.md' } 'already registered'
Reject { Invoke-SwManager register -Path $fixture -Project missing-section -Directory 'Workspace' -StateFile 'docs/state.md' -StateSection Absent } 'Startup section missing'
Write-SwFile (Join-Path $fixture 'Workspace/secret.env') "## Startup`nMust not be read as project state.`n"
Reject { Invoke-SwManager register -Path $fixture -Project credential-state -Directory 'Workspace' -StateFile 'secret.env' } 'Markdown files'
# The owner-created fixture file is not a coordination mutation; include it in preservation baseline.
$childrenBefore = @('Research Notes [2]', 'Workspace', 'Analysis') | ForEach-Object { TreeHash (Join-Path $fixture $_) }
$status = @(Invoke-SwManager status -Path $fixture)
Assert ($status.Count -eq 3) 'Status includes all three projects'
Assert (-not @($status | Where-Object { $_.Startup -match 'old approval' }).Count) 'Only startup sections returned, not history'
Test-SwManager -Path $fixture | Out-Null
Assert ($LASTEXITCODE -eq 0) 'Manager validates with three registered projects'
$pwsh = (Get-Process -Id $PID).Path
$cliOutput = @(& $pwsh -NoProfile -File (Join-Path $fixture '.sw/sw.ps1') manager projects)
Assert ($LASTEXITCODE -eq 0 -and ($cliOutput -join "`n") -match 'research-notes') 'Installed CLI emits project metadata before exiting'
$before = TreeHash $fixture
$null = & $pwsh -NoProfile -File (Join-Path $root 'sw.ps1') manager install -Path $fixture
Assert ($LASTEXITCODE -eq 0 -and (TreeHash $fixture) -ceq $before) 'Cross-process reinstall is byte-idempotent, including policy/manifest key order'

# No native CLI, service start or model calls. The sole transport seam is replaced.
$scope = Get-Module Sw.Manager
& $scope {
    $script:fake = @{ calls = @(); sessions = @{}; inbox = @{}; messages = @{}; failCreate = $false; failSend = $false; unsafe = $false; active = @{}; paginate = $false }
    function script:Invoke-SwManagerApi($Method, $Route, $Body) {
        $script:fake.calls += @{ method = $Method; route = $Route; body = $Body }
        if ($Route.StartsWith('/api/agent/ws-planner?')) {
            $dir = [Uri]::UnescapeDataString(($Route -split '=', 2)[1])
            $policy = @(Get-SwManagerPolicy)
            if ($script:fake.unsafe) { $policy += @{ action = 'shell'; resource = '*'; effect = 'allow' } }
            return @{ location = @{ directory = $dir }; data = @{ id = 'ws-planner'; mode = 'primary'; permissions = $policy } }
        }
        if ($Route -eq '/api/session' -and $Method -eq 'post') {
            if ($Body.Contains('parentID')) { throw 'Incorrect inherited-location child session' }
            $s = @{}; foreach ($key in $Body.Keys) { $s[$key] = $Body[$key] }
            $s['time'] = @{ created = 1; updated = 1 }
            $script:fake.sessions[$s['id']] = $s
            $script:fake.inbox[$s['id']] = @()
            $script:fake.messages[$s['id']] = @()
            if ($script:fake.failCreate) { throw 'fixture unknown creation after server admission' }
            return @{ data = $s }
        }
        if ($Route -eq '/api/session/active') { return @{ data = $script:fake.active } }
        if ($Route -match '^/api/session/(ses[_a-zA-Z0-9-]+)(.*)$') {
            $id = $Matches[1]; $suffix = $Matches[2]
            if (-not $script:fake.sessions.Contains($id)) { throw 'fixture missing native session' }
            if ($suffix -eq '') { return @{ data = $script:fake.sessions[$id] } }
            if ($suffix -eq '/inbox') { return @{ data = $script:fake.inbox[$id] } }
            if ($suffix.StartsWith('/message?')) {
                $all = @($script:fake.messages[$id])
                if ($script:fake.paginate -and $all.Count -gt 1) {
                    if ($suffix -match 'cursor=') { return @{ data = @($all | Select-Object -Skip 1); cursor = @{ next = $null } } }
                    return @{ data = @($all[0]); cursor = @{ next = 'fixture-next' } }
                }
                return @{ data = $all; cursor = @{ next = $null } }
            }
            if ($suffix -eq '/prompt' -and $Method -eq 'post') {
                $entry = @{ id = $Body['id']; sessionID = $id; delivery = $Body['delivery']; type = 'user'; payload = @{ text = $Body['text'] } }
                $script:fake.inbox[$id] += $entry
                if ($script:fake.failSend) { throw 'fixture unknown send after server admission' }
                return @{ data = $entry }
            }
        }
        throw "Unexpected fixture API route $Method $Route"
    }
}
function CallCount { & $scope { $script:fake.calls.Count } }
function Draft([string]$Task, [string]$Project = 'workspace', [string[]]$Dependencies = @()) {
    Invoke-SwManager request -Path $fixture -Project $Project -Task $Task -Body "Bounded planning for $Task; no execution." -DependsOn $Dependencies
}
function Approve([string]$Task, [string]$Project = 'workspace', [int]$Budget = 2) {
    Invoke-SwManager approve -Path $fixture -Task $Task -Project $Project -Model 'fixture/model' -MaxMessages $Budget -Owner 'fixture-owner' -Approval 'offline test only, no live authority' | Out-Null
}
$draft = Draft 'first-task'
Assert ((CallCount) -eq 0) 'Draft and static inspection never call API'
Reject { Invoke-SwManager start -Path $fixture -Task 'first-task' } 'Human planning approval'
Reject { Invoke-SwManager approve -Path $fixture -Task 'first-task' -Project workspace -Model 'anthropic/claude-fixture' -MaxMessages 1 -Owner fixture -Approval test } 'non-Claude'
Reject { Invoke-SwManager approve -Path $fixture -Task 'first-task' -Project workspace -Model 'fixture/model#high' -MaxMessages 1 -Owner fixture -Approval test } 'variants'
Reject { Invoke-SwManager approve -Path $fixture -Task 'first-task' -Project workspace -Model 'fixture/model' -MaxMessages 0 -Owner fixture -Approval test } 'MaxMessages'
Reject { Draft '../unsafe' } 'Invalid manager'
Reject { Draft 'self' 'workspace' @('self') } 'cannot depend on itself'
Approve 'first-task' 'workspace' 1
$before = TreeHash $fixture
Invoke-SwManager start -Path $fixture -Task 'first-task' -WhatIf | Out-Null
Assert ((TreeHash $fixture) -ceq $before -and (CallCount) -eq 0) 'Action WhatIf writes/calls nothing'
& $scope { $script:fake.unsafe = $true }
Reject { Invoke-SwManager start -Path $fixture -Task 'first-task' } 'not restricted'
Assert (-not (Test-Path -LiteralPath (Join-Path $fixture '.sw/comms/tasks/first-task/manager-session-intent.json'))) 'Unsafe runtime blocked before creation intent'
& $scope { $script:fake.unsafe = $false }
$started = Invoke-SwManager start -Path $fixture -Task 'first-task'
Assert ($started['state'] -eq 'verified') 'Native identity verified before use'
$native = & $scope { @($script:fake.sessions.Values)[0] }
Assert ($native['location']['directory'] -eq (Join-Path $fixture 'Workspace')) 'Native session starts at exact child directory'
Assert ($native['model']['providerID'] -eq 'fixture' -and $native['model']['id'] -eq 'model') 'Explicit model is passed as V2 Model.Ref'
Reject { Invoke-SwManager start -Path $fixture -Task 'first-task' } 'intent already exists'
Reject { Invoke-SwManager accept -Path $fixture -Task 'first-task' -Request $draft['request'] -Summary reviewed } 'completed correlated'
$admitted = Invoke-SwManager send -Path $fixture -Task 'first-task' -Request $draft['request']
Assert ($admitted['state'] -eq 'admitted' -and $admitted['delivery'] -eq 'queue') 'Acknowledgment is admission/queue, not completion'
$lastCall = & $scope { $script:fake.calls[-1] }
Assert ($lastCall['body']['resume'] -eq $true -and $lastCall['body']['delivery'] -eq 'queue') 'Scoped send resumes idle session but never steers/interrupts'
Reject { Invoke-SwManager send -Path $fixture -Task 'first-task' -Request $draft['request'] } 'never resend'
$second = Draft 'first-task'
Reject { Invoke-SwManager send -Path $fixture -Task 'first-task' -Request $second['request'] } 'budget exhausted'
$collection = Invoke-SwManager collect -Path $fixture -Task 'first-task'
Assert ($collection.Requests[0].Delivery -eq 'queued' -and $collection.Requests[0].Acceptance -eq 'pending') 'Queued input is not accepted'
$sid = $started['sessionID']; $mid = $admitted['messageID']
& $scope {
    param($sid, $mid)
    $script:fake.inbox[$sid] = @()
    $script:fake.messages[$sid] = @(@{ id = $mid; type = 'user'; text = 'fixture' })
} $sid $mid
$collection = Invoke-SwManager collect -Path $fixture -Task 'first-task'
Assert ($collection.Requests[0].Delivery -eq 'delivered') 'Delivered input without completed assistant text is not answered'
& $scope {
    param($sid)
    $script:fake.messages[$sid] += @{ id = 'msg_answer'; type = 'assistant'; time = @{ completed = 2 }; finish = 'stop'; content = @(@{ type = 'text'; text = 'A bounded fixture plan.' }) }
    $script:fake.paginate = $true
} $sid
$collection = Invoke-SwManager collect -Path $fixture -Task 'first-task'
Assert ($collection.Requests[0].Delivery -eq 'answered' -and $collection.Requests[0].Response -eq 'A bounded fixture plan.') 'Paginated correlated completed answer is returned'
Invoke-SwManager accept -Path $fixture -Task 'first-task' -Request $draft['request'] -Summary 'Reviewed bounded plan; no execution approval.' | Out-Null
$collection = Invoke-SwManager collect -Path $fixture -Task 'first-task'
Assert ($collection.Requests[0].Acceptance -eq 'accepted') 'Explicit reviewed planning acceptance distinct from response'
Assert (-not ((TreeHash (Join-Path $fixture '.sw/comms')) -match 'A bounded fixture plan')) 'Native transcripts not persisted (only observations/references)'
$records = Get-ChildItem -LiteralPath (Join-Path $fixture '.sw/comms/tasks/first-task') -Filter '*-observation.json'
Assert (-not @($records | Where-Object { (Read-SwText $_.FullName) -match 'A bounded fixture plan' }).Count) 'Observation records do not copy response text'

$dependent = Draft 'dependent' 'analysis' @('missing-task')
Approve 'dependent' 'analysis'
Invoke-SwManager start -Path $fixture -Task 'dependent' | Out-Null
Reject { Invoke-SwManager send -Path $fixture -Task 'dependent' -Request $dependent['request'] } 'Dependency not accepted'
$dependent = Draft 'dependent' 'analysis' @('first-task')
Invoke-SwManager send -Path $fixture -Task 'dependent' -Request $dependent['request'] | Out-Null
Assert ($true) 'Accepted cross-project dependency permits scoped follow-up'

$unknown = Draft 'unknown-create' 'research-notes'
Approve 'unknown-create' 'research-notes'
& $scope { $script:fake.failCreate = $true }
Reject { Invoke-SwManager start -Path $fixture -Task 'unknown-create' } 'unknown creation'
& $scope { $script:fake.failCreate = $false }
Reject { Invoke-SwManager start -Path $fixture -Task 'unknown-create' } 'intent already exists'
$collection = Invoke-SwManager collect -Path $fixture -Task 'unknown-create'
Assert ($collection.Identity -eq 'verified') 'Unknown creation reconciles exact persisted native ID without another create'
& $scope { $script:fake.failSend = $true }
Reject { Invoke-SwManager send -Path $fixture -Task 'unknown-create' -Request $unknown['request'] } 'unknown send'
& $scope { $script:fake.failSend = $false }
Reject { Invoke-SwManager send -Path $fixture -Task 'unknown-create' -Request $unknown['request'] } 'never resend'
$collection = Invoke-SwManager collect -Path $fixture -Task 'unknown-create'
Assert ($collection.Requests[0].Delivery -eq 'queued') 'Unknown send reconciles native acknowledgment without another prompt'

$attach = Draft 'attached'
Approve 'attached'
Reject { Invoke-SwManager attach -Path $fixture -Task attached -SessionID $sid -Owner fixture -Approval 'owner opt-in' } 'already belongs'
& $scope {
    param($sid)
    $standalone = $script:fake.sessions[$sid] | ConvertTo-Json -Depth 30 | ConvertFrom-Json -AsHashtable
    $standalone['id'] = 'ses_standalone'
    $standalone['metadata'] = @{}
    $script:fake.sessions['ses_standalone'] = $standalone
    $script:fake.inbox['ses_standalone'] = @()
    $script:fake.messages['ses_standalone'] = @()
} $sid
$sid = 'ses_standalone'
& $scope { param($sid) $script:fake.active[$sid] = @{ type = 'running' } } $sid
Reject { Invoke-SwManager attach -Path $fixture -Task attached -SessionID $sid -Owner fixture -Approval 'owner opt-in' } 'active session'
& $scope { param($sid) $script:fake.active.Remove($sid) } $sid
$attached = Invoke-SwManager attach -Path $fixture -Task attached -SessionID $sid -Owner fixture -Approval 'owner opt-in'
Assert ($attached['mode'] -eq 'attach') 'Matching idle restricted session can opt in without modifying its native identity'
& $scope { param($sid) $script:fake.sessions[$sid]['model']['id'] = 'changed' } $sid
Reject { Invoke-SwManager send -Path $fixture -Task attached -Request $attach['request'] } 'drift'
& $scope { param($sid) $script:fake.sessions[$sid]['model']['id'] = 'model' } $sid
& $scope { param($sid) $script:fake.sessions[$sid]['outcome'] = 'failed' } $sid
Reject { Invoke-SwManager send -Path $fixture -Task attached -Request $attach['request'] } 'Native session reports failure'
& $scope { param($sid) $script:fake.sessions[$sid].Remove('outcome') } $sid
Invoke-SwManager handoff -Path $fixture -Task attached -To 'Claude-native-session' -Body 'Manual planning handoff only.' | Out-Null
Assert (@(Get-ChildItem -LiteralPath (Join-Path $fixture '.sw/comms/tasks/attached') -Filter '*-handoff.json').Count -eq 1) 'Claude handoff remains manual, with no native delivery claim'

# Failed/truncated turns and uncertain native admissions stop further dispatch.
$failure = Draft 'failed-turn'
Approve 'failed-turn'
$failedSession = Invoke-SwManager start -Path $fixture -Task 'failed-turn'
$failedSend = Invoke-SwManager send -Path $fixture -Task 'failed-turn' -Request $failure['request']
& $scope {
    param($sid, $mid)
    $script:fake.inbox[$sid] = @()
    $script:fake.messages[$sid] = @(@{ id = $mid; type = 'user' }, @{ id = 'msg_failed'; type = 'assistant'; time = @{ completed = 2 }; finish = 'length'; content = @(@{ type = 'text'; text = 'Truncated plan' }) })
} $failedSession['sessionID'] $failedSend['messageID']
$collection = Invoke-SwManager collect -Path $fixture -Task 'failed-turn'
Assert ($collection.Requests[0].Delivery -eq 'failed') 'Truncated response is a failed turn, not an answer'
$followup = Draft 'failed-turn'
Reject { Invoke-SwManager send -Path $fixture -Task 'failed-turn' -Request $followup['request'] } 'stop and reconcile'
Reject { Invoke-SwManager accept -Path $fixture -Task 'failed-turn' -Request $failure['request'] -Summary reviewed } 'completed correlated'

$uncertain = Draft 'uncertain-admission'
Approve 'uncertain-admission'
Invoke-SwManager start -Path $fixture -Task 'uncertain-admission' | Out-Null
& $scope { $script:fake.failSend = $true }
Reject { Invoke-SwManager send -Path $fixture -Task 'uncertain-admission' -Request $uncertain['request'] } 'unknown send'
& $scope { $script:fake.failSend = $false }
$followup = Draft 'uncertain-admission'
Reject { Invoke-SwManager send -Path $fixture -Task 'uncertain-admission' -Request $followup['request'] } 'Prior admission is unknown'
$requestFile = Join-Path $fixture ".sw/comms/tasks/uncertain-admission/$($followup['request']).json"
$badDraft = Read-SwJson $requestFile
$badDraft['body'] = 'x' * 16001
Write-SwFile $requestFile (ConvertTo-SwJson $badDraft)
Reject { Invoke-SwManager send -Path $fixture -Task 'uncertain-admission' -Request $followup['request'] } 'Malformed/unbounded'

$beforeCalls = CallCount
Invoke-SwManager projects -Path $fixture | Out-Null
Invoke-SwManager status -Path $fixture | Out-Null
Test-SwManager -Path $fixture | Out-Null
Assert ((CallCount) -eq $beforeCalls) 'Projects/status/validate remain entirely offline'
$childrenAfter = @('Research Notes [2]', 'Workspace', 'Analysis') | ForEach-Object { TreeHash (Join-Path $fixture $_) }
Assert (($childrenBefore -join "`n") -ceq ($childrenAfter -join "`n")) 'No child project files changed during coordination'

$validation = @(Test-SwManager -Path $fixture)
Assert ($LASTEXITCODE -eq 0 -and -not @($validation -match 'stale vs source|skipped').Count) 'Fresh install has no drift vs kit source'
$kitCopy = Join-Path $fixture 'Workspace'
foreach ($rel in 'sw.ps1', 'lib/Sw.Project.psm1', 'lib/Sw.Manager.psm1', 'project/manager/manager.md', 'project/manager/manager-role.md', 'project/manager/planner-role.md') { Write-SwFile (Join-Path $kitCopy $rel) (Read-SwText (Join-Path $root $rel)) }
Write-SwFile (Join-Path $kitCopy 'project/manager/manager.md') ((Read-SwText (Join-Path $root 'project/manager/manager.md')) + "`nSource change.`n")
$validation = @(& $pwsh -NoProfile -File (Join-Path $fixture '.sw/sw.ps1') manager validate)
Assert ($LASTEXITCODE -eq 0 -and @($validation -match 'stale vs source: \.sw/manager\.md$').Count -eq 1 -and @($validation -match 'stale vs source').Count -eq 1) 'Installed validate warns only for the stale managed file'

$managedFile = Join-Path $fixture '.sw/manager.md'
Write-SwFile $managedFile ((Read-SwText $managedFile) + "`nUser change.`n")
$before = TreeHash $fixture
Reject { Install-SwManager -Path $fixture } 'modified file preserved'
Assert ((TreeHash $fixture) -ceq $before) 'Conflicting install preflight preserves every file'
Test-SwManager -Path $fixture | Out-Null
Assert ($LASTEXITCODE -eq 1) 'Installation drift fails static validation'
Write-Output "PASS: $script:checks offline manager assertions; no native OpenCode/Claude CLI, service or model requests."
exit 0
