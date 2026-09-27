# 05: Orchestration and roles

Status: complete; reviewed by the owner 2026-09-27; R1-R7 adopted (R7 minimal, routing pin kept).
Researched 2026-09-26 (local) by `project-research` (research-5, Claude Opus 5.5
via Claude Code 2.1.282, desktop app, native Windows). All sources accessed
2026-09-27 between 03:13Z and 03:25Z; page dates are given where the page
showed one. Raw page text was saved with `curl` to the session scratchpad
(outside the repo). Claude pages were fetched as their `.md` sources, and
the OpenAI guide as a PDF converted with `pdftotext`. Every finding was
re-checked against that text. No finding is summary-based. Findings that
rest on an *absence* in the fetched text are marked **weak**.

## 1. Question and scope

Which orchestration primitives do the harnesses provide, when does
multi-agent work pay for itself, and what role set and dispatch model
should SuperWorkspace ship?

Sub-questions:
1. Primitives in OpenCode and Claude Code: dispatch, background and
   parallel runs, nesting, worktree isolation, agent teams, cross-session
   messaging, and which surface has each. Codex in one line.
2. When multi-agent pays: vendor guidance, token multipliers, failure modes.
3. Role granularity: routing, how many subagents is too many, precedent role
   sets; is 9 roles plus `explore` justified?
4. Session tier: which features support a Leader session plus human-opened
   worker sessions; how portable is it; should the product ship it?
5. Commands versus skills for dispatch: does converting the nine commands
   (02-R3) lose dispatch control?
6. Local: the duplicated subagent list in `Sw.Project.psm1`; propose one
   owning source.
7. Recommendation mapped onto the kit.

Out of scope (one line each):
- Permission syntax (topic 8): R1 names one tool restriction and nothing more.
- Memory (topic 6).
- Multi-user collaboration and branch models (topic 10): the session tier's
  multi-human side belongs there.
- Context budgets (topic 4, done) and model tiers (topic 3, done).

Not covered:
- OpenCode cross-session messaging and OpenCode Desktop worktrees. No
  fetched OpenCode page describes either (**weak**: absent from the V2
  agents, commands and skills pages). The kit's existing note on OpenCode
  automatic worktrees (`.sw/workspace.md`) is local, not re-verified.
- OpenCode nesting for custom subagents. The V2 page says the parent's
  `subagent` permission governs launches and the built-in `general` "cannot
  launch more subagents". It gives no depth limit.
- Which OpenCode version reads the kit's `subagent:` command field: V2 only
  (F8). Not tested.
- Codex orchestration beyond 02-F2. No Codex page was fetched.
- Precedent role sets in third-party kits. I narrowed to the harnesses'
  built-in sets (F18), which are primary sources.
- Anthropic's "how we built Claude Managed Agents" post, which F12's page
  names as its successor, was not fetched.

## 2. Findings

Findings from topics 0-4 are cited as `0N-F<n>`.

### Primitives (sub-question 1)

F1. **Claude Code subagents: Agent tool, fresh context, background by
default in interactive sessions.** Each subagent "starts with a fresh,
isolated context window" (04-F4). "Where fork mode is on, as it is by
default in an interactive session, Claude Code runs the subagent in the
background". Background subagents get "a smaller built-in tool set", and
their permission prompts surface in the main session. By default, 20
running subagents is the limit ("`Concurrent subagent limit reached`",
`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`, v2.1.217+). "There's no limit on
the total number of subagents Claude can spawn over a session."
<https://code.claude.com/docs/en/sub-agents>, accessed 2026-09-27, no page
date.

F2. **Claude Code subagents can nest three layers by default.** "By
default, a subagent can spawn subagents of its own, up to three layers
below the main conversation." Set `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`;
"Set `1` to turn nesting off." To stop one subagent spawning, "omit `Agent`
from its `tools` list or add it to `disallowedTools`." History: v2.1.172 to
v2.1.216 nested five layers; v2.1.217 to v2.1.218 defaulted to one;
v2.1.219 raised it to three. `AskUserQuestion` is removed from every
subagent. Same page as F1.

F3. **Claude Code `isolation: worktree` branches from the default branch.**
The frontmatter field runs the subagent "in a temporary git worktree ...
branched by default from your default branch rather than the parent
session's `HEAD`". The worktree "is automatically cleaned up if the
subagent makes no changes". Same page as F1.

F4. **Claude Code agent teams are experimental, off by default, and limited
to one lead.** "Agent teams are experimental and disabled by default"
(`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). Limitations: "One team per
session", "No nested teams: teammates cannot spawn their own teammates",
"Lead is fixed", and "No session resumption with in-process teammates".
The page says "Start with 3-5 teammates for most workflows" and "Token costs
scale linearly". The costs page gives about 7x tokens (04-F18). Teammates
talk through JSON mailboxes under `~/.claude/teams/`.
<https://code.claude.com/docs/en/agent-teams>, accessed 2026-09-27, no page
date.

F5. **Claude Code cross-session messaging is on by default in recent CLI
and desktop builds.** "Cross-session messaging requires Claude Code
v2.1.224 or later on macOS and Linux ... On native Windows, it requires
Claude Code v2.1.234 or later. When a session meets the requirements,
messaging is on with nothing to enable." Claude finds a target with
`ListAgents` and sends with `SendMessage`. `notify_when_idle` asks a session
for "one notice when that session next goes idle or exits". Deny rules on
`SendMessage` and `ListAgents` turn it off, which also removes messaging to
subagents and teammates. `/list-agents` (alias `/peers`) checks
availability. <https://code.claude.com/docs/en/cross-session-messaging>,
accessed 2026-09-27, no page date. Local: this session runs 2.1.282 on
native Windows, and `ListAgents`/`SendMessage` are offered.

F6. **The Claude desktop app adds parallel sessions, worktrees and its own
session surface.** Code tab sessions run in parallel; "For Git
repositories, select the worktree" option. Worktrees live in
`<project-root>/.claude/worktrees/`, with a configurable branch prefix.
Claude "can list your other Code tab sessions, read what each has been
doing, and send messages between them". That surface "sees only the
sessions the desktop app runs itself". It does not see "sessions you
started from the terminal CLI or the VS Code extension". Cross-session
messaging (F5) "separately lets Claude message ... terminal sessions". Task
chips start "a new session with its own worktree". The CLI's analogue is
agent view (`claude agents`), "one screen for all your background
sessions".
<https://code.claude.com/docs/en/desktop>, <https://code.claude.com/docs/en/agent-view>,
accessed 2026-09-27, no page dates.

F7. **OpenCode V2: subagents run in foreground or background child
sessions; the parent's permissions decide which it may launch.** Modes:
`primary`, `subagent` ("Runs only in a child session through the subagent
tool"), and `all`. "Subagents run with fresh context in foreground or
background child sessions. The parent agent's subagent permissions control
which agents it may launch; the child uses its own configured
permissions." Built-ins: `build`, `plan` (primary), `general` ("cannot
launch more subagents") and `explore` (subagents). A subagent's
`description` is what "OpenCode shows ... to the model choosing which agent
to launch". <https://opencode.ai/v2/docs/agents/>, accessed 2026-09-27, no
page date.

F8. **OpenCode V2 commands pin `agent`, `model` and `subagent`.**
"`subagent`: `true` runs in a background child session; `false` forces the
current session. `subtask`: Deprecated alias for `subagent`." The V1 page
documents only `subtask`, which forces "a subagent invocation" even for a
primary agent. The kit writes `subagent:`, which matches V2.
<https://opencode.ai/v2/docs/commands/>, accessed 2026-09-27, no page date;
<https://opencode.ai/docs/commands/>, "Last updated" 2026-09-26.

F9. **OpenCode skills cannot choose an agent or a child session.** The V2
fields are `name`, `description`, `slash` and `metadata`
(`opencode/slash`, `opencode/autoinvoke`). "V2 accepts portability fields
such as license and compatibility but does not interpret them." Loading a
skill "Adds the Markdown body, without frontmatter, to the conversation".
V1: "Only these fields are recognized: name ... description ... license ...
compatibility ... metadata"; "Unknown frontmatter fields are ignored".
<https://opencode.ai/v2/docs/skills/>, no page date;
<https://opencode.ai/docs/skills/>, "Last updated" 2026-09-26; both
accessed 2026-09-27. **Weak** on the negative: no agent or fork field
appears on either page.

F10. **Claude Code skills can dispatch: `context: fork` plus `agent`.**
"Add `context: fork` ... Claude Code starts a new subagent of the type set
in the `agent` field and gives it the skill content as its prompt." A forked
skill runs in the background unless `background: false` (v2.1.218+). It
gets the narrower background tool set, and its edits fall "outside your
session's checkpoints". "Custom commands have been merged into skills."
`disable-model-invocation: true` keeps a skill user-only.
<https://code.claude.com/docs/en/skills>, accessed 2026-09-27, no page date.

F11. **Codex:** custom agents are TOML files in `.codex/agents/` with `name`,
`description`, `developer_instructions` and optional `model` (02-F2).
Nothing about its orchestration was fetched.

### When multi-agent pays (sub-question 2)

F12. **Anthropic: use the simplest solution and add complexity only when
needed.** "We recommend finding the simplest solution possible, and only
increasing complexity when needed. This might mean not building agentic
systems at all." Orchestrator-workers "is well-suited for complex tasks
where you can't predict the subtasks needed (in coding, for example ...)".
The page also notes that "Much of the tooling landscape described in this
post has changed since December 2024." Vendor guidance, no measurements.
[Anthropic, "Building effective agents", 2024-12-19](https://www.anthropic.com/engineering/building-effective-agents),
accessed 2026-09-27.

F13. **Anthropic's measured case for multi-agent is breadth-first research
at about 15x chat tokens; coding fits worse.** This restates 00-F1 to
00-F3: +90.2% on an internal research eval, about 15x chat tokens, a poor
fit when agents share context, and early failures that included spawning
50 subagents for simple queries. Vendor-internal eval; secondary as
evidence (00).

F14. **Claude Code's own rule for choosing: main conversation or
subagent.** Use the main conversation when "The task needs frequent
back-and-forth", "Multiple phases share significant context, such as
planning, implementation, and testing", or for "a quick, targeted change".
Use subagents when output is verbose, "You want to enforce specific tool
restrictions or permissions", or "The work is self-contained and can return
a summary". Same page as F1.

F15. **Agent teams: not for sequential or same-file work.** "For
sequential tasks, same-file edits, or work with many dependencies, a single
session or subagents are more effective." The strongest cases are research
and review, independent new modules, and competing debugging hypotheses.
Same page as F4.

F16. **OpenAI: maximize a single agent first; split on complex logic or
overlapping tools.** "Our general recommendation is to maximize a single
agent's capabilities first." Split when prompts have "many conditional
statements", or on tool overload: "The issue isn't solely the number of
tools, but their similarity or overlap. Some implementations successfully
manage more than 15 well-defined, distinct tools while others struggle
with fewer than 10 overlapping tools." It names two patterns, manager
(agents as tools) and decentralized (handoffs).
[OpenAI, "A practical guide to building agents" (PDF)](https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf),
no date in the extracted text, accessed 2026-09-27. The Agents SDK page
adds: "orchestrating via code makes tasks more deterministic and
predictable, in terms of speed, cost and performance".
<https://openai.github.io/openai-agents-python/multi_agent/>, accessed
2026-09-27, no page date. Vendor guidance, no measurements.

F17. **Counter-view (secondary): single-threaded agents.** Cognition argues
"Share context, and share full agent traces" (00-F4). This is an opinion
piece.

### Role granularity (sub-question 3)

F18. **Both harnesses route by description and publish no role-count
limit.** Claude "automatically delegates tasks based on the task
description in your request, the `description` field in subagent
configurations, and current context" (F1's page). OpenCode shows the
description to the model choosing (F7). The only size limits found are a
startup warning when combined descriptions pass 15,000 tokens (04-F4), 20
concurrent subagents (F1), and 3-5 teammates for teams (F4). The built-in
sets are small: OpenCode has `build`, `plan`, `general` and `explore`
(F7). Claude has Explore, Plan and general-purpose, plus helpers (`claude`,
`statusline-setup`, `claude-code-guide`) (F1's page). No source gives a
maximum number of subagents (**weak**). The nearest guidance is F16's rule
on overlap, which is about tools; applying it to agent descriptions is my
inference.

### Local analysis (sub-questions 4 and 6)

F19. **Local: the subagent flag is stated three times.** Each command's
`subagent:` frontmatter is the first place. The validator re-derives it in
`product/lib/Sw.Project.psm1` line 307 (`$child = if ($name -in 'review',
'status', 'research')`) and requires a match at line 309. The generated
Claude leader pointer hard-codes "``/review`` and ``/status`` dispatch
``project-review``; ``/research`` dispatches ``project-research``" at lines
473-475. The Claude command generator at lines 446-447 already reads
`subagent` from each file. `$script:Routes` (line 181) likewise restates
each command's `agent:`. Local evidence, read on 2026-09-27.

F20. **Local: "workers never spawn teams" is enforced in OpenCode but only
stated in Claude.** In OpenCode the validator expects every role except the
leader to be denied `subagent` (`Sw.Project.psm1` lines 353-357). The
generated Claude agents for `project-developer`, `project-worker` and
`project-build` have no `tools:` line (`roles.json` `claudeTools: ""`). They
therefore inherit `Agent` and can nest three layers (F2). Only the text
"You cannot spawn agents" (line 441) stops them. Local evidence, read on
2026-09-27: `.claude/agents/project-developer.md` has no `tools` line.

F21. **Local: the dev process's session tier already runs on F5 and F6.**
This task arrived as an `assignment` event in `.sw/comms/tasks/`, and the
worker replies with a `SendMessage` to the Leader. `docs/development.md`
"How development runs" already notes a desktop limit: a new session "is not
reachable by peer messaging until its first turn runs". The durable state
is the task record, which is plain files. Local evidence.

## 3. Options compared

### Dispatch model

| Option | Harness support | Cost | Fit |
|---|---|---|---|
| a. Leader plus one level of subagents (today) | OpenCode (F7), Claude (F1), Codex agents (F11) | subagent tokens only (04-F18) | matches F12, F14, F16 |
| b. a, plus nesting allowed | Claude default (F2); OpenCode by permission (F7) | hidden intermediate output; hard to audit | no vendor evidence it helps coding (F13) |
| c. Agent teams | Claude only, experimental (F4) | about 7x (04-F18) | research and review only (F15); not portable |
| d. Session tier: Leader session plus human-opened worker sessions | records work everywhere; signals need F5/F6 (Claude only among fetched docs) | a full session per worker | long, reviewable packages; a human gate between steps |

### Commands versus skills for dispatch (02-R3)

| Command | Today | As OpenCode skill (F9) | As Claude skill (F10) |
|---|---|---|---|
| `review`, `status`, `research` | `subagent: true` child session | **lost**: body loads into the current agent | kept via `context: fork` + `agent` |
| `validate` | `agent: project-build`, current session | **lost**: no agent switch | a fork changes semantics; inline equals today's Claude output |
| `work`, `resume`, `handoff`, `inbox`, `workspace-check` | `agent: project-leader`, current session | same when the session is the leader | same |

### Owning source for the subagent flag (sub-question 6)

| Option | Change | Keeps a guard? |
|---|---|---|
| i. Command frontmatter owns it (drop line 307's list) | delete `$child`/line 309; generate the leader pointer's dispatch line from the files | the parser still requires `true`/`false` (line 286) |
| ii. A table in code owns it; generate the field | inverts the canonical rule ("templates are canonical") | yes, but the source is code, not the template |
| iii. `roles.json` owns it | commands are not roles; wrong home | n/a |

## 4. Recommendation

R1. **Keep dispatch model a: the Leader plus one level. Enforce "no
nesting" in the Claude adapter.** Emit `disallowedTools: Agent` in every
generated `.claude/agents/<role>.md` (F2, F20). One constant line in
`Get-SwClaudeFiles` does it, with no `roles.json` field. It makes Claude
match the OpenCode deny, so the text at line 441 becomes true.
Session-tier workers are main sessions, so this does not affect them
(`docs/development.md` lets them use subagents). Do not ship nesting
(option b) or agent teams (option c). Teams are experimental and
Claude-only, cost about 7x, and fit only research and review (F4, F15,
04-F18). The kit's 3-researcher fan-out (00 Q1) already covers that case.

R2. **Keep the role set: 9 roles plus `explore`.** No source caps the
count (F18). The kit's descriptions total 856 bytes (04-F10), far under
Claude's 15,000-token warning. Each role differs in tier or in access
(`roles.json`): read-only, markdown, worker, full. That is F14's "enforce
specific tool restrictions" reason, and F16's rule for when to split. The
weakest pair is `project-plan` against `project-architect`: same tier, same
read-only access, and adjacent descriptions. F16's overlap warning points
there, but I found no evidence of misrouting (Q4).

R3. **Add one routing default to `project-leader.md`, from F12, F14 and
F16.** Under Routing, one line: "Default to doing the work in this session;
dispatch when the output is verbose, the work is self-contained, or it
needs a different tier or access." This makes the existing "Access to
every agent is not a requirement" operational. Cost is about 150 bytes of
leader startup (04 R4 leaves about 3.3 KB of headroom).

R4. **Session tier: ship it as documentation only, with the human as the
portable relay.** The records (`sw comms event`, task folders) already work
on every harness because they are files (F21). Signals are the
harness-specific part: Claude CLI and desktop have cross-session messaging
(F5, v2.1.234+ on native Windows). The desktop app's own surface sees only
desktop sessions (F6). No OpenCode equivalent was found (Not covered).
Minimal product form: a short "Multi-session work (optional)" paragraph in
`.sw/collaboration.md`, the file that owns records and messages. It would
say: one Leader session writes assignments; human-opened worker sessions
each own one package; the task record is the truth; "go" and "done" travel
by harness messaging where available, else the human relays them. No new
command or code. The multi-human side goes to topic 10.

R5. **Worktree guard: extend the existing OpenCode note to Claude.**
`.sw/workspace.md` "Approved-plan execution" already says to turn off
OpenCode automatic worktrees. The desktop worktree option, task chips (F6)
and `isolation: worktree` (F3) all create branches outside the kit's
two-branch policy. Add "Claude: leave the desktop worktree option off, and
do not use `isolation: worktree`" to the same sentence. The generator
already emits no `isolation` field, so there is nothing to change there.

R6. **Commands versus skills: keep the nine commands; close 02-R3 as "not
now".** Converting loses dispatch in OpenCode for `review`, `status`,
`research` and `validate` (F9, table). Claude could keep it with
`context: fork` (F10), but that means two sources, which breaks "one owning
source". Commands still work in Claude (F10: "Your existing
`.claude/commands/` files keep working"). Revisit if OpenCode skills gain
an agent or child-session field.

R7. **Duplicated subagent list: option i, where command frontmatter owns
the flag.** Delete the hard-coded list and its check (`Sw.Project.psm1`
lines 307 and 309). Build the leader pointer's dispatch sentence (lines
473-475) from the commands whose `subagent` is `true`, which the loop at
line 443 already reads. Reducing `$script:Routes` to a list of command
names was not adopted (owner, 2026-09-27); the routing pin stays. Tests that assert the
removed errors must change with it (topic 9).

Mapping onto the kit:
- `product/project/roles.json`: no change (R1 is a constant; R2).
- `product/project/base/.opencode/agents/project-leader.md` Routing: one
  line (R3).
- `.sw/workspace.md` "Roles": no change. "Approved-plan execution": extend
  the worktree sentence (R5).
- The nine commands: no change (R6).
- `docs/development.md` "How development runs": add that "go" and "done"
  use Claude cross-session messaging (v2.1.234+ on Windows). In OpenCode, or
  when `/peers` is missing, the human relays them (R4). Dev docs only.
- `product/lib/Sw.Project.psm1`: R1 (the generator) and R7 (the validator
  and the leader pointer). Both need a `VERSION` bump and a `CHANGELOG`
  entry, since installed projects receive them.

## 5. Open questions

Owner answers recorded 2026-09-27 (relayed by the Leader).

1. Owner: add `disallowedTools: Agent` to every generated Claude agent
   (R1)? It removes the three-layer nesting that Claude allows by default
   today, for `project-developer`, `project-worker` and `project-build`.
   **Answer:** R1 adopted; block nesting in generated Claude agents.
2. Owner: ship the session tier as a documentation paragraph in
   `.sw/collaboration.md` (R4), or keep it dev-only until topic 10?
   **Answer:** ship it as a documentation paragraph (R4).
3. Owner: R7 minimal (drop the hard-coded `subagent` list), or also
   collapse `$script:Routes` to names, which gives up the routing pin?
   **Answer:** R7 minimal; command frontmatter owns the flag and the
   routing pin stays.
4. Owner: merge `project-plan` and `project-architect` (R2)? No evidence
   either way. Merging saves one description and one role body.
   **Answer:** keep all 9 roles.
5. Owner: close 02-R3 (commands stay commands) as R6 proposes?
   **Answer:** keep the nine commands; 02-R3 is closed as "not now".
6. Runtime test: does OpenCode V1 (the `$schema` the kit writes, 03-F20)
   honour `subagent: true`, or only `subtask`? If only `subtask`, the
   `/review`, `/status` and `/research` commands run inline there (F8).
   **Answer:** runtime test, open; tied to 03-F20 (V1 `$schema`).
7. Runtime test: does OpenCode let a kit `project-developer` launch a child
   when the global rules deny `subagent`, and is there any OpenCode
   cross-session messaging (Not covered)?
   **Answer:** runtime test, open.
8. Budget report: 16 research calls (15 page fetches plus 1 PDF), no
   searches, cap 25. Total tool calls about 25, including reading kit files
   and the saved text. Dropped: Codex orchestration pages, the
   third-party precedent role sets, Anthropic's Managed Agents post, and
   OpenCode worktree and messaging docs (none found in the fetched
   navigation).
9. Fetched pages contained no text directed at this task. The Claude `.md`
   pages carry a generic "Fetch the complete documentation index" line for
   readers.

## 6. Supersedes / updates

None superseded. Answers the roadmap inputs "Duplicated subagent list" (R7)
and "Session tier" (R4, the multi-human part left to topic 10). Resolves
02-R3 and 02 Q5 as "not now" (R6), replacing 04-R5's token-only view with
the dispatch argument. Extends 00 option C (fan-out) with F4: agent teams
are not needed for it. Extends 04-F4 and 04-F18 with nesting, background
and team limits (F1, F2, F4).
