# 11: Agent architecture on T3 Code

Status: complete (recommendation, not approved); 2026-10-15 by the current
Leader, at the
owner's request to assess the agent design from first principles with T3 Code
as the foundation, without falling back on the inherited Workspace design.
Sources accessed 2026-10-15 unless a page date is given. Raw text was saved
outside the repository (session temp directory) and each finding was re-read
against it. T3 Code findings come from its repository docs and source at
`pingdotgg/t3code` commit `ec1313c8` (2026-10-14), saved locally the same day.

## 1. Question and scope

What agent architecture (roles, skills, commands, dispatch, model routing,
guardrails, records) best serves Workspace's goals when T3 Code is the
foundation and its providers are Claude (Claude Code via the Agent SDK) and
ChatGPT (Codex), with OpenCode dropped (owner, 2026-10-15)?

Sub-questions:
1. Goals: what must the agent layer achieve (design register D1-D6, O1-O17)?
2. Current setup: how do the inherited roles, skills, commands, tier rubric
   and dispatch rule score against those goals with T3 Code underneath?
3. Foundation: which primitives does T3 Code own, and which belong to Claude
   Code and Codex natively?
4. Alternatives: the "WAT Framework" the owner named and other current design
   patterns, with their evidence.
5. Evidence: when do extra agents and roles pay?
6. Recommendation and the owner decisions it needs.

Out of scope: implementation (needs separate approval); the root WS manager;
sibling projects; live runtime tests; model pricing (topic 3).

Not covered: live behaviour of any claim below (all static); Codex app-server
loading of project `.codex/` layers under T3; independent (non-vendor)
measurements of skills-first or spec-driven methods; other third-party
methodologies (BMAD, Agent OS and similar) beyond the two sampled in F17-F18.

Budget: 14 research calls under this plan (1 search, 13 fetches, one 404),
cap 20. Findings from earlier topics are cited as `0N-F<n>`; research-corpus
claims (ResearchProj, local) as `C<nnn>`.

## 2. Findings

### Goals (sub-question 1, local)

F1. **The register implies eight goals for the agent layer.** Approved,
bounded work only and recorded approvals (O5, O14); guardrails that hold
(O12, O13); verified quality with independent review (O14, O15); small
startup context (O4); cost control and quota stops (O9, O10); portability to
adopters with their own workflows (D5, O10); recoverable continuity (O4,
O14); and low upkeep from one owning source (D3, O3). Local:
`docs/workspace-outline.md`, read 2026-10-15. The weighting is my inference.

### Current setup on the new foundation (sub-question 2, local)

F2. **The role layer no longer loads as designed.** Roles are authored as
OpenCode agent files (`project/base/.opencode/agents/*.md`); `roles.json`
lists Leader (session tier, full), developer (light, full), research
(standard, Markdown), review (standard, read-only) and built-in `explore`.
T3 Code runs OpenCode threads as `build`, never the default agent (topic
`t3code-adoption` record), and Claude receives roles only through a local,
opt-in adapter that refuses to generate without a local model map
(`Get-SwClaudeFiles`). With OpenCode dropped, the canonical role source
targets a harness that is no longer used. Local, 2026-10-15.

F3. **Commands and procedure are scattered.** Nine OpenCode commands pin an
agent (`work`, `resume`, `handoff`, `inbox`, `workspace-check` to the Leader;
`review`, `status` to review; `research` to research; `validate` to
developer). Eight skills live in `.agents/skills`. Governance text the Leader
may need is large: `.sw/workspace.md` is 24.3 KB and `.sw/collaboration.md`
8.3 KB, much of it OpenCode-specific. Local, byte counts 2026-10-15.

F4. **The inherited dispatch rule already matches the evidence.** The Leader
body says to work inline by default and dispatch only for verbose,
self-contained or differently-tiered work (05-R3). That rule survives any
redesign (F12-F14).

### Foundation primitives (sub-question 3)

F5. **T3 Code owns sessions, isolation and orchestration.** Each thread is a
durable session; "New worktree" gives a thread its own checkout and branch;
the orchestrator MCP server (`t3-code`) gives every provider `delegate_task`
(child thread on any provider instance and model, prompt-only context plus
an optional role instruction), `create_threads`, `t3_thread_launch` (with an
explicit `worktree` workspace strategy), thread read/send/wait/interrupt and
pull-request linking. Child runtime and interaction modes "may not escalate
privileges". <https://github.com/pingdotgg/t3code/blob/ec1313c8/docs/orchestration-v2/orchestrator-mcp-server.md>
and <https://github.com/pingdotgg/t3code/blob/ec1313c8/docs/user/thread-sidebar.md>, accessed 2026-10-15.

F6. **T3 Code's permission modes map differently per provider.** Codex:
Supervised = approval `untrusted` with a `readOnly` sandbox; Auto-accept
edits = `on-request` + `workspaceWrite`; Auto = `on-request` with
`auto_review`; Full access = `never` + `dangerFullAccess`
(`CodexAdapterV2.ts` `codexRuntimeModeTurnDefaults`). Claude: `default`,
`acceptEdits`, `auto`, `bypassPermissions` (`ClaudeAdapterV2.ts`
`permissionModeForClaudeRuntimePolicy`).
<https://github.com/pingdotgg/t3code/tree/ec1313c8/apps/server/src/orchestration-v2/Adapters>,
accessed 2026-10-15.

F7. **Claude deny rules hold in every mode; project settings can lock out
bypass.** "Deny rules block in every mode, including `bypassPermissions`."
`permissions.disableBypassPermissionsMode` ("Prevent anyone from entering
bypassPermissions mode") has scope "Any file". A contrary report says SDK
subagent tool limits were not enforced in child processes (C354, contradicted).
<https://code.claude.com/docs/en/permission-modes>,
<https://code.claude.com/docs/en/settings-reference>, no page dates.

F8. **Claude can make any agent the main thread.** The `agent` setting
("Run the main thread as a named subagent, so Claude Code applies that
subagent's system prompt, tool restrictions, and model"; scope "Any file").
Subagents run in their own context window with their own tools and
permissions; `tools: Agent(worker, researcher)` restricts which types a
main-thread agent may spawn; `omitClaudeMd` and `initialPrompt` exist. In
`-p` runs a custom agent replaces the system prompt. Settings reference and
<https://code.claude.com/docs/en/sub-agents>. Whether T3's SDK launch keeps
its appended orchestration prompt under an `agent` setting is untested.

F9. **Codex custom agents are worker-only and inherit permissions.** TOML
files in `.codex/agents/` need `name`, `description`,
`developer_instructions`; they may set model and reasoning effort but "inherit
the parent's permissions, provider, and MCP servers; a custom agent file can't
override those settings". Built-ins are `default`, `worker`, `explorer`.
Local Codex spawns "after a direct request or applicable project or skill
instruction". <https://learn.chatgpt.com/docs/agent-configuration/subagents>.

F10. **Codex rules give hard command blocks, but project rules need trust.**
`prefix_rule` decisions `allow`, `prompt`, `forbidden`; "the most restrictive
decision" wins; project rules under `.codex/rules/` load "only when the
project `.codex/` layer is trusted"; marked experimental.
<https://learn.chatgpt.com/docs/agent-configuration/rules>. T3 Code sets no
Codex trust itself (source search, `ec1313c8`).

F11. **Skills are the one shared procedure format, with two discovery
paths.** Codex scans `.agents/skills` from the working directory to the
repository root and follows symlinked skill folders
(<https://learn.chatgpt.com/docs/build-skills>). Claude Code's skill-location table lists only
`.claude/skills/` paths (**weak**: rests on absence); custom commands are
merged into skills, and
`disable-model-invocation` keeps a skill user-only
(<https://code.claude.com/docs/en/skills>, accessed 2026-10-15). T3 Code lists
provider skills in its `/` and `$` menus (T3 `docs/user/composer.md`). Local:
in this T3 Claude thread, user and project instruction files, including
`AGENTS.md`, loaded natively.

### Evidence on agents, workflows and skills (sub-questions 4-5)

F12. **Single-agent first remains the best-supported default.** At matched
compute, multi-agent structure shows no general advantage; gains are
task-dependent (C121, replicated direction). "Multi-agent outperforms single
agent" is contradicted (C089). Single-agent frameworks repaired more issues
than multi-agent ones (C235, qualified). Vendor guidance agrees: simplest
solution first (05-F12); maximize one agent first (05-F16).

F13. **Subagents pay for isolation, not headcount.** Anthropic: sub-agents
"handle focused tasks with clean context windows" and suit "complex research
and analysis where parallel exploration pays dividends", while compaction and
note-taking serve back-and-forth and milestone work; system prompts should be
"the minimal set of information that fully outlines your expected behavior".
[Effective context engineering for AI agents, 2025-09-29](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents).
Matches Claude's own main-vs-subagent rule (05-F14, C234).

F14. **Skills are Anthropic's stated alternative to many specialised
agents.** "Instead of building fragmented, custom-designed agents for each use
case, anyone can now specialize their agents with composable capabilities";
progressive disclosure loads metadata first and bodies on demand; bundled
scripts give "deterministic reliability that only code can provide".
[Equipping agents for the real world with Agent Skills, 2025-10-16](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills).
Vendor guidance, no measurements.

F15. **Long role chains lose accuracy end to end.** In an 11-role
permission-isolated benchmark, end-to-end accuracy fell well below subtask
accuracy (C243, qualified, no single-agent arm). Local: ResearchProj
`docs/research-claims.md`, read 2026-10-15.

F16. **The WAT Framework is a layering vocabulary, not a tested method.**
Workflows (plain-language Markdown SOPs: trigger, steps, decision points,
exit conditions), Agents (the model reasoning and coordinating, optionally
spawning subagents) and Tools (narrow, deterministic, loudly failing
scripts). Its claims rest on separation of concerns and debuggability, with no
data; the explainer is on a vendor marketing page.
[MindStudio, "What Is the WAT Framework?", 2026-03-09](https://www.mindstudio.ai/blog/what-is-wat-framework-workflows-agents-tools),
secondary, **weak** as evidence.

F17. **Superpowers: a skills-only methodology across Claude Code and Codex.**
Mandatory auto-triggered skills: brainstorming, worktrees, written plans of
2-5 minute tasks, then either a fresh subagent per task with review after
each or inline execution with one final review, TDD, review between tasks,
branch finishing. Ships as a plugin for both harnesses. README of
[obra/superpowers](https://github.com/obra/superpowers), main branch;
practitioner method, no measurements.

F18. **Spec Kit: artifact-driven phases.** "Constitution once per project;
specify → plan → tasks → implement → converge per feature", stored under
`.specify/`. README of [github/spec-kit](https://github.com/github/spec-kit),
main branch; no measurements.

## 3. Options compared

| Option | What it is | Goal fit (F1) | Evidence | Cost and risk |
|---|---|---|---|---|
| A. Port the roster | Leader + developer + research + review as Claude agents and Codex custom agents | Keeps role limits; Leader must be forced on (F8) or entered via commands; Codex cannot make it the main role (F9) | Contradicts single-agent-first only mildly (F12) | Two role formats per role, Leader-on-every-thread problem (children too), 24 KB governance |
| B. Skills-first single thread ("WAT-shaped") | One main thread per task; procedures as skills (workflows); `sw` scripts as tools; built-in explore/worker subagents only | Strong on context, upkeep, portability; review independence weak if inline | F12-F14, F16 | Smallest; relies on the model following skills |
| C. T3-orchestrated | Main thread + T3 child threads: worktree threads for parallel packages, `delegate_task` for review/research on any provider | Strong isolation and visibility; cross-provider independent review | F5, F12-F13 for when to split | More threads and tokens; T3 is young (D6) |
| D. Adopt a third-party method | Superpowers or Spec Kit wholesale | Strong process; weak fit for approval/records/public-adoption rules | F17-F18, no data | Dependency approval; overrides Workspace governance |
| **B + C hybrid** | B by default, C only where isolation or independence pays | All eight goals | F4, F12-F15 | Two clear routes; needs the live checks in Q7 |

## 4. Recommendation

R1. **Drop the Leader as a role; the main T3 thread is the coordinator.**
Every thread already owns its session (F5). Put the core rules that apply to
every agent (authority, Git, safety, records) in `AGENTS.md`, which both
providers and every child load natively (F11). Move the Leader's procedures
into workflow skills (R2). This removes the Leader-on-every-child problem
(F8) and the Codex main-role gap (F9).

R2. **Workflows become skills, one source, two discovery paths.** `work`
(plan, approve, execute), `resume`, `handoff`, `review`, `research`,
`validate`, `status` and the existing method skills (planning, minimal-change,
debugging, documentation, task-handoff, focused-review) live in
`.agents/skills` and are generated into `.claude/skills` (F11). Side-effect
workflows are user-invoked (`disable-model-invocation`). Each skill states
trigger, steps, decision points and exit conditions (the useful part of F16).

R3. **Tools stay deterministic scripts.** `sw validate`, `sw comms`,
`sw context`, `sw doctor` remain the tool layer and get `t3.json` buttons.
Move any rule a script can check out of prose (F14, F16).

R4. **Dispatch: inline by default; split only for isolation or
independence.** Keep F4's rule. Read-heavy exploration uses the built-in
explorers. Research fan-out uses native subagents or `delegate_task` (F13).
Parallel or long implementation packages become T3 worktree threads (own
checkout and branch, visible, stoppable; F5) instead of in-checkout developer
subagents. Independent review is the one standing custom role: a read-only
reviewer, preferably on the other provider through `delegate_task` (Claude
work reviewed by Codex and vice versa), narrowed to a read-only mode (F5-F6).

R5. **Guardrails per provider, not per role.** Claude: tracked
`.claude/settings.json` deny rules (hold in every mode, F7) and
`disableBypassPermissionsMode` if live checks show T3 still starts threads.
Codex: tracked `.codex/rules` with `forbidden` for push and destructive Git,
which needs the owner to trust the project in Codex (F10); otherwise rely on
the sandbox (F6). Recommended T3 mode stays Supervised.

R6. **Models: chosen in T3, guided by a short tier table.** No tracked model
pins; the thread model is picked in T3, and delegation names a model from a
local tier table. Replaces the generated per-role model maps.

R7. **Borrow, do not adopt, third-party methods.** Superpowers' per-task
fresh worker with review and its plan granularity, and Spec Kit's
constitution/spec artifacts, are good patterns to fold into the `work` skill;
adopting either wholesale would override approval and record rules and adds a
dependency (F17-F18).

## 5. Open questions

Owner answers recorded 2026-10-15 (this thread): Q1 yes; Q2 yes; Q3 needs more
context (explained in-thread; cross-provider review rests on topic 12 F12);
Q4 yes; Q5 needs more thorough decision-making, answered by topic 12, under
the new precedent that better options replace the current system (outline
D8); Q6 yes.


1. Owner: accept R1 (no Leader role; main thread plus workflow skills)?
2. Owner: parallel implementation through T3 worktree threads instead of
   in-checkout subagents (R4)? Ignored local files are missing in worktrees
   (topic `t3code-adoption`), so records must stay in the main checkout.
3. Owner: make cross-provider review (Claude ↔ Codex via `delegate_task`) the
   standard review route (R4)?
4. Owner: trust the project in Codex so `.codex/rules` load (R5, F10)?
5. Owner: borrow from Superpowers/Spec Kit (R7), adopt one, or neither?
6. Owner: the 24 KB `.sw/workspace.md` would shrink to what scripts cannot
   check; is a rewrite of governance docs in scope?
7. Live checks before relying on R1-R6: skills load in T3 for both providers;
   Claude `agent` and deny settings under T3's SDK launch (F7-F8, C354); Codex
   project rules and custom agents under T3's app-server; `delegate_task`
   read-only narrowing on the other provider.

## 6. Supersedes / updates

Updates 05 for the T3 Code foundation: 05-R2 (keep the role set) and 05-R6
(keep commands) are superseded if the owner accepts R1-R2; 05-R1 (no nesting)
and 05-R3 (inline by default) carry forward. 02-R3 (commands to skills) is
reopened by F11. No earlier decision is changed by this file alone.
