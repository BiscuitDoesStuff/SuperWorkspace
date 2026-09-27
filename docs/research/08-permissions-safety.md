# 08: Permissions and safety across harnesses

Status: complete; reviewed by the owner 2026-09-27; R1-R4 and R6-R8 adopted; R5 not now.
Researched 2026-09-26 (local) by `project-research` (research-8, Claude Opus 5.5
via Claude Code 2.1.282, desktop app, native Windows). All sources accessed
2026-09-27 between 04:07Z and 04:10Z; no fetched page showed a page date.
Raw page text was saved with `curl` to the session scratchpad (outside the
repo). Claude pages were fetched as their `.md` sources and HTML pages were
stripped to text. Every finding was re-checked against that text. No finding
is summary-based. Findings that rest on an *absence* in the fetched text are
marked **weak**. Kit code was read at `0d593d0`.

## 1. Question and scope

What can each harness actually enforce (permission rules, tool lists,
sandboxes, hooks), where do pattern rules leak, and how should
SuperWorkspace express one safety policy across harnesses without
overclaiming?

Sub-questions:
1. Permission models: OpenCode V2, Claude Code, Codex; matching semantics
   for shell commands and documented bypass classes.
2. Sandboxing: what exists, what it isolates, Windows support; should the
   kit recommend it?
3. Hooks and trust: Claude PreToolUse hooks and workspace trust (the
   "folder not trusted" skip), OpenCode plugin hooks. Can hooks enforce a
   role limit?
4. Untrusted content and secrets.
5. GitHub tier (local analysis).
6. Role access classes per harness (local analysis); what `validate`
   proves.
7. Recommendation mapped onto the kit.

Out of scope (one line each):
- Validation methods, including new `validate` checks: topic 9.
- Multi-user and branch models: topic 10.
- Lifecycle: topic 7, done.

Not covered:
- Claude permission modes page (`permission-modes`): what auto mode and
  bypass mode do to deny rules and protected paths. Linked from the
  fetched pages, not fetched.
- Whether Claude's `Bash(...)` rules also govern its PowerShell tool. The
  permissions page gives PowerShell its own `PowerShell(...)` rule form
  (F3) and says nothing about Bash rules covering it (**weak**: absence).
- Codex execution-policy `rules` files and Codex permission profiles
  beyond the lines quoted in F16. Not fetched.
- OpenCode shell scanner behaviour for wrappers (`bash -c`, `pwsh -c`,
  `git -C`) and command substitution: the V2 page says only "Scanner-produced
  command string; compound commands may produce several" (**weak**:
  absence).
- Whether `tool.execute.before` receives the calling agent's ID in
  OpenCode (**weak**: the fetched plugin pages show only `input.tool` and
  `output.args`).
- GitHub server-side controls (branch protection, rulesets): not
  researched; mentioned in R3 as a human action only.
- Runtime tests of any rule. The assignment forbids bypass attempts; no
  rule was exercised.

## 2. Findings

Findings from topics 0-7 are cited as `0N-F<n>` or `0N R<n>`.

### Claude Code permission model (sub-question 1)

F1. **Claude evaluates deny, then ask, then allow; an allow cannot carve an
exception out of a deny.** "Rules are evaluated in order: deny, then ask,
then allow. The first match in that order determines the outcome, and rule
specificity doesn't change the order." Across scopes, "a user-level deny
blocks a project-level allow", and managed settings "user and project
settings can't override". A bare tool name in deny removes the tool from
Claude's context; a scoped rule "leaves the tool available and blocks
matching calls". "Permission rules are enforced by Claude Code, not by the
model." <https://code.claude.com/docs/en/permissions>, accessed
2026-09-27.

F2. **Claude Bash rules split compound commands and strip a fixed wrapper
list, but match the command as written.** Separators `&&`, `||`, `;`, `|`,
`|&`, `&` and newlines split a command; "Deny and ask rules apply when any
subcommand matches them, including a command nested inside a subshell, a
command substitution, or a control-flow body". Stripped wrappers:
`timeout`, `time`, `nice`, `nohup`, `stdbuf`, `command`, `builtin`,
`noglob`, bare `xargs`, and leading environment assignments (for deny and
ask, "any leading assignment"). Not stripped: `direnv exec`, `devbox run`,
`mise exec`, `npx`, `docker exec`. The page's own table: `Bash(git push *)`
"Doesn't stop" `git -C . push origin main`, `git -c push.default=current
push origin main` or `git 'push' origin main`; `Bash(rm *)` does not stop
`/bin/rm` or `bash -c 'rm ...'`. "A deny or ask rule covers the invocation
Claude usually produces and isn't a security boundary around the program."
Same page as F1.

F3. **Claude has separate `PowerShell(...)` rules.** "PowerShell permission
rules use the same shape as Bash rules"; aliases are canonicalized
(`Get-ChildItem` also matches `gci`, `ls`, `dir`), matching is
case-insensitive, and Claude "parses the PowerShell AST and checks each
command in a compound command independently". The page does not say that
`Bash(...)` rules apply to PowerShell commands (**weak** on that negative).
Same page as F1. Local: `.claude/settings.json` holds only `Bash(...)`
rules; this session exposes a Bash tool and reports PowerShell as the
primary shell.

F4. **Claude `Read` and `Edit` rules cover the file tools, recognized file
commands and redirections, not arbitrary subprocesses.** "To block
Claude's file tools from reading a file or directory, add a `Read` deny
rule ... such as `Read(./.env)`." A `Read` deny also blocks Edit and Write
on the path. Deny rules "don't apply to a command that reads files without
naming them, such as `grep -r pattern .` ... or to arbitrary subprocesses
that read or write files indirectly, like a Python or Node script". Output
redirects are checked against `Edit` rules; input redirects against `Read`
rules (v2.1.257+). Only `Edit(path)` and `Read(path)` are consulted for
paths; a `Write(path)` rule is accepted "but never consulted". Same page as
F1.

F5. **Claude subagent limits: `Agent(name)` deny rules and per-agent tool
lists.** "Use `Agent(AgentName)` rules to control which subagents Claude
can use", in `deny` or `--disallowedTools`. Per-subagent `tools` and
`disallowedTools` remove tools from one subagent (05-F2). Permission rules
in settings apply to the whole session; the fetched page shows no
per-subagent rule scope (**weak**: absence). Same page as F1.

F6. **Claude project allow rules wait for workspace trust; deny and ask
rules do not.** "`permissions.allow` rules and
`permissions.additionalDirectories` entries in a project's
`.claude/settings.json` grant capability, so Claude Code applies them only
after you accept the workspace trust dialog ... `deny` and `ask` rules
aren't affected, since they only restrict." Approvals saved with "Yes, and
don't ask again" go to `.claude/settings.local.json`. Same page as F1.

### OpenCode V2 permission model (sub-question 1)

F7. **OpenCode V2: ordered rules, last match wins, whole-value wildcards.**
Each rule has `action`, `resource`, `effect`. "If no rule matches, OpenCode
uses ask." `*` is "Zero or more characters, including /"; backslashes are
normalized and matching is case-insensitive on Windows. "A shell pattern
ending in ` *` also matches the command without arguments." Order: lower
config first, global rules next, "agent rules are appended last". "Any
deny denies the operation; otherwise any ask asks". V2 renamed V1
`permission`, `bash`, `task` to `permissions`, `shell`, `subagent`.
<https://opencode.ai/v2/docs/permissions/>, accessed 2026-09-27.

F8. **OpenCode's shell resource is scanner output, and the docs call
directory inference best effort.** The `shell` resource is a
"Scanner-produced command string; compound commands may produce several".
Warning: "shell runs with the host user's filesystem, process, and network
authority. Directory inference from command text is best effort, so prefer
a narrow shell allowlist instead of patterns intended to recognize every
dangerous command." The default scanner is tree-sitter; an experimental
portable scanner "cannot analyze" some commands and returns "a scanner
error, not a permission denial". Same page as F7.

F9. **OpenCode's default base policy asks for `.env` reads and external
directories.** Every agent starts with `* * allow`, `external_directory *
ask`, `read *.env ask`, `read *.env.* ask`, `read *.env.example allow`.
Saved "Allow always" approvals "never override a configured deny". A
custom subagent "uses its own permissions, not a subset of its parent's".
Same page as F7. Local: `product/project/opencode.base.json` sets
`external_directory * allow`, loosening the default.

F10. **OpenCode policies are a hard floor a repository cannot lift.**
`experimental.policies` statements "are binary, never prompt, and only
ever tighten". A `permission` statement's resource is `<action>:<value>`
(examples: `shell:git push *`, `edit:*.env`, `read:*/.ssh/*`); a denied
check fails "instead of prompting" and "overrides an ask and an 'Allow
always' approval alike". Precedence reverses normal config: Console
workspace, then global `~/.config/opencode/opencode.json(c)`, then project
files. "A repository cannot re-enable a provider you deny globally." The
policy plugin cannot be disabled from `plugins`. Policies "do not sandbox
plugin code". <https://opencode.ai/v2/docs/policies/> and
<https://opencode.ai/v2/docs/plugins/>, accessed 2026-09-27.

### Codex and others (sub-question 1)

F11. **Codex: an OS sandbox mode plus an approval policy.** "Sandbox mode:
What Codex can do technically ... Approval policy: When Codex must ask
you". Local default "Auto" is `--sandbox workspace-write
--ask-for-approval on-request`, network off. Inside writable roots,
`.git`, `.agents` and `.codex` are "protected as read-only", recursively.
`approval_policy = "untrusted"` is retired; per-project `trust_level =
"untrusted"` replaces it and "also disables project-local configuration".
Prompt injection: "Prompt injection can cause the agent to fetch and
follow untrusted instructions"; web search defaults to a cached index,
which "reduces exposure".
<https://developers.openai.com/codex/agent-approvals-security>, accessed
2026-09-27.

F12. **Other harnesses: one syntax each, nothing shared** (02, scope
note): OpenCode `permission`, Claude `tools`, Gemini and Copilot per their
own settings, Codex `sandbox_mode`. Links and dates: 02-F4 to 02-F16. Topic 2 fetched no permission pages
for Gemini, Cursor or Copilot; this topic did not either.

### Sandboxing (sub-question 2)

F13. **Claude's sandbox covers Bash, PowerShell and Monitor commands on
macOS, Linux and WSL2; native Windows is not supported.** "The sandbox is
built into Claude Code and runs on macOS, Linux, and WSL2. Native Windows
is not supported." It enforces filesystem and network limits "for every
Bash, PowerShell, or Monitor command and its child processes". Default
writes: the working directory, added directories and `$TMPDIR`; default
reads: "the entire computer", including `~/.aws/credentials` and `~/.ssh/`
unless `sandbox.credentials` or `denyRead` block them. Protected paths
inside writable directories include `.claude` settings, skills, agents,
commands, hooks, `.mcp.json`, and `.git/hooks` and `.git/config`.
Network goes through a proxy that "pre-allows no domains by default".
<https://code.claude.com/docs/en/sandboxing>, accessed 2026-09-27.

F14. **Claude's sandbox has an escape hatch and known limits.** Claude
"may retry the command with the `dangerouslyDisableSandbox` parameter",
which goes through normal permissions; `allowUnsandboxedCommands: false`
turns it off. Limits: the proxy does not inspect TLS by default, so
"domain fronting or similar techniques" may reach other hosts; "Allowing
broad domains such as `github.com` can create paths for data
exfiltration". Read, Edit and Write "use the permission system directly
rather than running through the sandbox". Same page as F13.

F15. **Permissions and sandbox are documented as complementary layers.**
"Use both for defense-in-depth, since sandbox restrictions still apply even
if a prompt injection bypasses Claude's decision-making." With the sandbox
on, explicit deny rules and content-scoped ask rules such as `Bash(git push
*)` still apply. Same page as F1.

F16. **Codex sandboxes natively on Windows; the stronger mode needs admin
setup.** "When running natively on Windows, Codex uses a Windows sandbox
implementation" (WSL2 uses the Linux bwrap sandbox; WSL1 unsupported from
0.115). `elevated` "uses dedicated lower-privilege sandbox users,
filesystem permission boundaries, firewall rules, and local policy
changes"; `unelevated` uses "a restricted Windows token ... ACL-based
filesystem boundaries" and is "weaker". Network is off "without your
explicit approval". <https://developers.openai.com/codex/windows/windows-sandbox>
and the F11 page, accessed 2026-09-27.

F17. **OpenCode documents no OS sandbox** (**weak**: absence). The V2
documentation navigation lists no sandbox page, and the permissions page
warns that shell has host-user authority (F8). V2 navigation read from
<https://opencode.ai/v2/docs/permissions/>, accessed 2026-09-27.

### Hooks and trust (sub-question 3)

F18. **The "folder not trusted" skip is documented behaviour for subagent
frontmatter hooks.** "Frontmatter hooks in a project subagent run only
after you accept the workspace trust dialog for the folder the agent file
came from. A `-p` session doesn't count as accepting it." In the table of
what runs before trust, subagent frontmatter hooks are "Not used, and no
dialog is offered" when "You trusted only a parent folder". "Before
v2.1.218, these hooks could run from folders you hadn't trusted." The fix
is to trust the repository itself, or set
`projects["<path>"].hasTrustDialogAccepted` in `~/.claude.json`.
<https://code.claude.com/docs/en/hooks> and
<https://code.claude.com/docs/en/permissions>, accessed 2026-09-27. This
explains the `docs/decisions.md` lesson (2.1.281); whether it still
applies here was not tested.

F19. **Settings-file hooks run inside subagents and see the subagent's
name, so one hook can apply per-role limits.** "Hooks from settings files,
managed policy settings, and plugins also run inside subagents ... the
input carries the `agent_id` and `agent_type`". Settings-file hooks need
workspace trust in interactive sessions (the folder "or for a parent
directory whose trust extends to it"); `-p` and SDK sessions treat the
folder as trusted. <https://code.claude.com/docs/en/hooks>, accessed
2026-09-27. Local: this session's generated SessionStart hook ran, so
settings hooks work here.

F20. **A PreToolUse hook can block before permission rules, but cannot
loosen a deny.** "A hook that exits with code 2 stops the tool call before
permission rules are evaluated"; "Hook decisions don't bypass permission
rules ... a matching deny rule blocks the call". PreToolUse does not fire
for `@` file references in the prompt. <https://code.claude.com/docs/en/permissions>
and <https://code.claude.com/docs/en/hooks>, accessed 2026-09-27.

F21. **OpenCode plugins can block a tool call in `tool.execute.before`.**
The docs' ".env protection" example throws `new Error("Do not read .env
files")` when `input.tool === "read"` and the path includes `.env`.
Plugins load from `.opencode/plugins/` and from config `plugins` arrays.
<https://opencode.ai/docs/plugins/> and <https://opencode.ai/v2/docs/plugins/>,
accessed 2026-09-27. Agent identity in the hook input is not shown
(**weak**).

### Untrusted content and secrets (sub-question 4)

F22. **Claude's prompt-injection guidance relies on approval, isolation and
VMs.** Safeguards include "Web fetch uses a separate context window",
"Trust verification" for first-time codebases and new MCP servers
("disabled when running non-interactively with the `-p` flag"), and
"Fail-closed matching". Practice: "Avoid piping untrusted content directly
to Claude" and "Use virtual machines (VMs) to run scripts and make tool
calls, especially when interacting with external web services". MCP: use
servers "from providers that you trust"; Anthropic "does not
security-audit or manage any MCP server".
<https://code.claude.com/docs/en/security>, accessed 2026-09-27. Extends
00-F12 (OpenAI: stage web research apart from private data).

F23. **Secrets: vendors pair a file rule with an OS layer.** Claude: a
`Read(./.env)` deny for the file tools (F4), and `sandbox.credentials`
for OS-level blocking plus unsetting variables like `GITHUB_TOKEN` (F13).
OpenCode: base asks for `.env` reads (F9), and a policy can deny
`read:*/.ssh/*` (F10). Both vendors state that the file rule does not
cover arbitrary subprocesses (F4, F8). Codex: memories redact secrets but
"Don't store secrets in memories" (06-F8).

### GitHub tier, local (sub-question 5)

F24. **OpenCode's GitHub rules are an allowlist; Claude's are an enumerated
denylist.** OpenCode: `gh *` deny, then `Get-SwGhRules` appends allows for
the read verbs (and tier 1 writes); last match wins (F7), so any verb not
listed, including aliases and extensions, is denied. Claude cannot do
deny-then-allow (F1), so `Get-SwClaudeGhDeny` lists 53 write verbs plus the
6 tier-0 verbs. Anything unlisted falls to Claude's default for that mode.
Local: `product/lib/Sw.Project.psm1` lines 148-172; `.claude/settings.json`; read 2026-09-27 at `0d593d0`.

F25. **Coverage of the named write paths.**

| Path | OpenCode | Claude |
|---|---|---|
| `gh api` (any method; POST when fields are passed, and GraphQL) | denied (`gh *`) | denied (`gh api`) |
| `gh pr merge` | denied | denied |
| `gh release create/edit/delete/upload` | denied | denied |
| `gh repo edit` | denied | denied |
| `gh alias set` (an alias starting with `!` or `--shell` "will be evaluated through the sh interpreter") | denied | **not listed**: default mode decides |
| invoking an existing alias or extension (`gh <name>`) | denied | **not listed**: default mode decides |
| `gh extension install` | denied | denied |
| a verb added to `gh` later | denied | **not listed** |
| `gh pr create` at tier 1 | allowed only as `gh pr create --draft *` | ask |

`gh api` method rule: "The default HTTP request method is GET normally and
POST if any parameters were added." <https://cli.github.com/manual/gh_api>;
alias rule: <https://cli.github.com/manual/gh_alias_set>, both accessed
2026-09-27.

F26. **`git push` has other routes past both harnesses' deny.** Both deny
the command as written (`git push *` in OpenCode, `Bash(git push:*)` in
Claude). Routes not matched, by documented Claude matching (F2) and the
OpenCode whole-value model (F7): `git -C . push`, `git -c k=v push`,
`git 'push'`, an absolute path to `git`, `sh -c`/`bash -c`/`pwsh -c`
wrappers, and a git alias (`git config alias.p push`, then `git p`). In
OpenCode, full-access roles inherit `shell * allow`, so these run without a
prompt; in Claude they fall to the default mode (a prompt in Manual mode).
`gh pr create` pushes too (`docs/decisions.md`); it is denied at tier 0 in
both. Read-only OpenCode roles resist these: they deny all shell except exact
allowed strings. Local analysis, 2026-09-27; not tested against GitHub or this repository.

### Role access classes, local (sub-question 6)

F27. **Rules enforced in one harness but only stated in the other.**
Sources: `product/project/roles.json`, `.opencode/agents/*.md`,
`product/project/opencode.base.json`, `Get-SwClaudeFiles`
(`Sw.Project.psm1` lines 428-486) and the generated `.claude/`, read 2026-09-27 at `0d593d0`.

| Rule | OpenCode | Claude adapter |
|---|---|---|
| readonly: no edits | enforced (`* * deny`) | enforced (`tools` has no Edit or Write) |
| readonly: shell limited to listed git reads | enforced (exact allowlist) | **stated**: `tools` includes Bash, and only the session-wide denies apply |
| markdown: edit `*.md` only | enforced | **stated**: Edit and Write are unrestricted by path |
| worker: no `git switch/checkout/merge/rebase/cherry-pick/branch/worktree` | enforced | **stated**: no rule |
| non-leader roles: no subagent launch | enforced (`subagent` deny) | enforced for readonly and markdown (no `Agent` in `tools`); **stated** for developer, worker, build (no `tools` line; 05-F20). 05 R1 (`disallowedTools: Agent`) is adopted but not yet generated at `0d593d0` |
| `.env` read prompts | enforced (base policy, F9) | **absent**: no `Read` rule, and in-directory reads need no approval (F1 page table) |
| outside-directory access | **allowed** (kit sets `external_directory * allow`) | prompts by default (F1 page table) |
| profile `editDeny` globs | enforced | enforced (`Edit(**/<glob>)`) |
| `git push/reset --hard/clean/stash` deny, `git commit` ask | enforced as written | enforced as written (Bash only; F3) |
| GitHub tier | allowlist (F24) | denylist (F24) |

Claude settings rules are session-wide (F5), so per-role path or verb
limits have no rule form there; F19's hook is the documented route.

F28. **What the `validate` permission matrix proves.** It rebuilds each
role's OpenCode policy (the documented V2 base, then `opencode.jsonc`, then
the agent's rules) and runs about 35 probe strings per role (380 cases in total) through the
kit's own model of V2 matching (`Test-SwPattern`, `Get-SwDecision`:
whole-value wildcards, last match wins, trailing ` *` matches the bare
command). It proves that the committed rule lists, in their order, give
the intended decision for those strings under the documented semantics.
It does not prove: that the running OpenCode applies V2 semantics (03-F20:
the kit writes the V1 `$schema`); how the scanner splits compound or
wrapped commands (F8); any other spelling of a denied command (F26); or
anything about Claude, whose check is a byte comparison of generated
files. Local: `Sw.Project.psm1` lines 340-379 and 115-146, read 2026-09-27; `validate` reported "permission cases=380".

## 3. Options compared

How to express one safety policy across harnesses:

| Option | What it gives | Cost | Honesty |
|---|---|---|---|
| a. Keep today: per-harness rules, docs say "guardrails, not a sandbox" | OpenCode strong on read-only roles, Claude weaker (F27) | none | claims in `.sw/workspace.md` line 90-91 ("enforced ... and the Claude adapter") overstate Claude |
| b. a, plus close the cheap Claude gaps in the generator | `.env` ask, `gh alias` deny, `disallowedTools: Agent` (05 R1) | a few constant lines in `Get-SwClaudeFiles`; a `VERSION`/`CHANGELOG` entry | still text matching (F2) |
| c. b, plus a Claude PreToolUse hook keyed on `agent_type` | per-role limits in Claude (markdown-only edits, worker git verbs, readonly shell) | a script the kit ships and maintains; a shell dependency in a portable template; needs workspace trust (F19) | still text matching; blocks before rules (F20) |
| d. Recommend OS sandboxes | file and network limits independent of command text (F13, F16) | Claude: not on native Windows (the owner's machine); Codex elevated mode changes firewall and local policy (F16); OpenCode has none (F17) | the only layer vendors call a boundary, and they list its limits (F14) |
| e. Global hard floors (OpenCode `experimental.policies`, Claude user `settings.json` denies) | a repository cannot loosen them (F1, F10) | writes to the user profile; experimental in OpenCode | same matching limits as rules |

## 4. Recommendation

R1. **Say three words and use them consistently: enforced, guardrail,
stated.** *Enforced*: tool lists and file-tool rules the harness applies
(F1, F4, F5). *Guardrail*: shell pattern rules, which stop the command as
written and nothing else (F2, F8, F26). *Stated*: role text the model is
asked to follow. In `.sw/workspace.md` "Permissions and portability",
replace "enforced in `opencode.jsonc` (and the Claude adapter)" with
"guardrails in `opencode.jsonc`; the Claude adapter covers less (see
table)" and add a five-row version of the F27 table. Keep "not a sandbox".
Extend the `docs/decisions.md` "Known gap" line from `bash -c` to the F26
list.

R2. **Close the cheap Claude gaps in `Get-SwClaudeFiles` (option b).**
- Emit `disallowedTools: Agent` in every generated agent (05 R1, already
  adopted; not yet in code).
- Add `ask`: `Read(**/.env)` and `Read(**/.env.*)`. Claude cannot re-allow
  `.env.example` under an ask (F1), so it prompts too; that is harmless.
- Add `deny`: `Bash(gh alias:*)` (F25).
- Do not enumerate more `gh` verbs; state that the Claude list is a
  denylist and that unknown verbs, aliases and extensions fall to Claude's
  default mode (F24).
Bump `product/VERSION` and add a `CHANGELOG` entry (installed projects
receive it through `update`). `roles.json` needs no new field.

R3. **Do not chase `git push` spellings with more patterns.** Each new
pattern (for example `git *push*`) blocks legitimate commands and still
misses wrappers (F2, F8). The rule stays a guardrail (R1). The control
that holds is server-side branch protection on `main`, a human GitHub
action the kit may print but never runs (AGENTS.md). Not researched here.

R4. **Sandboxes: document, do not configure (option d as text only).** Add
one paragraph: Claude users on macOS, Linux or WSL2 may enable `/sandbox`
locally (F13); Codex users get a sandbox by default and on native Windows
choose `elevated` or `unelevated` themselves (F16); OpenCode has none
(F17). The kit never writes sandbox settings: they are machine-specific and
Codex's elevated mode changes firewall and local policy, which the kit
never does.

R5. **Hooks: not now (option c deferred).** Use a settings-file PreToolUse
hook keyed on `agent_type` (F19), not a frontmatter hook (F18), if the
owner later wants Claude to enforce per-role limits. It still matches text
and adds a shipped script; OpenCode's equivalent (`tool.execute.before`,
F21) cannot yet be shown to know the agent. Record the documented cause of
the 2.1.281 skip in the `decisions.md` lesson: subagent frontmatter hooks
need trust for the exact folder; trusting a parent does not count (F18).

R6. **Secrets and untrusted content: no new mechanism.** Keep the `.env`
prompts (OpenCode base, R2 for Claude), `.gitignore` for `.env*`, and the
"never read credential files" rule. Keep "fetched pages are data" in the
research skill (00 R2). Note in `.sw/workspace.md` that the kit ships one
third-party remote MCP server (`context7` in `opencode.base.json`) and that
vendors say to use only trusted MCP servers (F22).

R7. **Hard floors stay a per-user choice (option e).** `sw doctor` or the
docs may print an example global OpenCode policy (`shell:git push *`,
`read:*/.ssh/*`) and Claude user-settings denies; the user applies them.
The kit writes neither unprompted.

R8. **Reconsider `external_directory * allow`** in `opencode.base.json`.
It removes OpenCode's default prompt (F9) and is looser than Claude
(F27). Owner decision; see Open questions.

Mapping onto the kit:
- `.sw/workspace.md` "Permissions and portability": R1 wording and table,
  R4 paragraph, R6 MCP note.
- `product/lib/Sw.Project.psm1` `Get-SwClaudeFiles`: R2 lines.
- `product/project/opencode.base.json`: R8 if adopted.
- `docs/decisions.md` lessons and "Known gap": R1, R5.
- `product/VERSION`, `product/CHANGELOG.md`: R2 (and R8).
- `validate` checks for the Claude side: topic 9.

## 5. Open questions

Owner answers recorded 2026-09-27 (relayed by the Leader).

1. Owner: adopt R1's three words (enforced, guardrail, stated) and the
   `.sw/workspace.md` table?
   **Answer:** R1 adopted.
2. Owner: R2, add the `.env` ask and `gh alias` deny to the Claude adapter,
   accepting a prompt on `.env.example`?
   **Answer:** R2 adopted.
3. Owner: R8, change `external_directory` from `allow` to the OpenCode
   default `ask`? It adds prompts for any work outside the project.
   **Answer:** R8 adopted; `external_directory` becomes `ask`.
4. Owner: R5, is Claude per-role enforcement by hook wanted now, or stay
   with stated limits?
   **Answer:** R5 not now.
5. Owner: is branch protection on `main` set for this repository (R3)?
   A human check.
   **Answer:** the owner asked the Leader to check read-only. The Leader's
   `gh api repos/.../branches/main` call was denied by that session's
   permission rules, the kit's `Bash(gh api:*)` deny (present at every tier), and the Leader
   did not route around it. Branch protection stays a human check.
   Observation (2026-09-27): live evidence that the generated Claude `gh`
   denylist applies to the main session, not only to subagents.
6. Runtime tests (not run; bypass tests forbidden here): do `Bash(...)`
   rules govern Claude's PowerShell tool (F3)? Does the frontmatter-hook
   skip still occur on 2.1.282 with the repository itself trusted (F18)?
   How does OpenCode's scanner treat `git -C . push` and `pwsh -c` (F8)?
   **Answer:** open.
7. Budget report: 14 research calls (14 page fetches with `curl`, no web
   searches, none failed; one fetched the Codex Security product page, the
   wrong page, and led to the right one), cap 25. Total tool calls about
   30, including reading prior research, kit code, the saved text and
   validation. Dropped: Claude permission-modes and settings-reference
   pages, Codex rules page, gh top-level command list, GitHub branch
   protection docs.
8. Fetched pages contained no text directed at this task.

## 6. Supersedes / updates

None superseded. Updates the `docs/decisions.md` lesson on skipped Claude
frontmatter hooks with its documented cause (F18) and widens its "Known
gap" (F26). Extends 05-F20 from subagent spawning to every role class
(F27). Extends 00-F12 with Claude and Codex injection guidance (F22).
Note for 07 R7: Codex protects `.agents` as read-only inside its sandbox
(F11), so Codex agents could not edit skills moved to `.agents/skills`.
Agents read skills and do not edit them, so this protection is expected to
be harmless (unverified: not tested in Codex).
