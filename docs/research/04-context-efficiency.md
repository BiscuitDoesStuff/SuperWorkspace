# 04: Context and token efficiency

Status: complete; reviewed by the owner 2026-09-27; R1-R7 adopted, R5's optional leader count adopted; no tokenizer (use `/context`).
Researched 2026-09-26 (local) by `project-research` (research-4, Claude Opus 5.5
via Claude Code). All sources accessed 2026-09-27 between 02:51Z and 02:56Z;
page dates are given where the page showed one. Raw page text was saved
with `curl` to the session scratchpad (outside the repo), and every finding
was re-checked against that text, not against a model summary. No finding
is summary-based. Findings resting on an *absence* in the fetched text are
marked **weak**. No tokenizer was run: no token count below was measured
by this task. Token figures are either quoted from a source or estimated as
bytes/4 by the kit, and are labelled as such.

## 1. Question and scope

What does each harness put into context at startup and per turn, what does
that cost, and how should SuperWorkspace measure and cap it, especially for
free models with small context windows?

Sub-questions:
1. Startup load in OpenCode and Claude Code; subagent context; measurement
   tools; Codex in one line.
2. Caching: mechanisms, minimum sizes, TTLs, invalidation; free endpoints.
3. Size guidance for instructions and skills; length versus adherence.
4. Long sessions: compaction, handoff, tool-output condensing, subagents.
5. Free-model context windows; is a fixed byte cap the right measure?
6. Recommendation for `Test-SwProject`'s startup budget, `sw doctor`, role
   body sizes and commands-as-skills (02-R3); is bytes/4 sound; should the
   cap depend on the model?

Out of scope (one line each):
- Memory and upkeep (topic 6): auto memory is mentioned only as startup load.
- Role design (topic 5): role bodies are measured, not redesigned.
- Validation methods (topic 9): how `validate` tests the budget is unchanged.
- Model choice (topic 3): context length is reported, not ranked.

Not covered:
- OpenCode startup load in detail: no OpenCode page lists what enters the
  system prompt, or whether AGENTS.md reaches a child session beyond F9's
  line (**weak**). OpenCode's token or context display was not fetched.
- OpenCode's own compaction threshold (when "context is full" triggers).
- Codex CLI: beyond 02-F1 (32 KiB `project_doc_max_bytes`), nothing fetched.
- Whether OpenCode Zen or OpenRouter free endpoints cache in practice; only
  published prices were read (F15, F16).
- The bytes/4 ratio: OpenAI's "what are tokens" help page returned no
  article text (client-rendered), and no tokenizer is installed locally
  (`tiktoken`, `tokenizers` absent). Verify against `/context` (Q4); no
  tokenizer dependency (owner, 2026-09-27).
- Claude Code's per-model auto-compact thresholds page (`model-config`)
  was not fetched; only the context-window page's pointer to it was.
- A primary study of instruction length versus adherence; only one
  secondary benchmark (F14).

## 2. Findings

Topic 1-3 findings are cited as `0N-F<n>`.

### Startup load (sub-question 1)

F1. **Claude Code loads CLAUDE.md, auto memory, MCP tool names and skill
descriptions before the first prompt.** "Before you type anything:
CLAUDE.md, auto memory, MCP tool names, and skill descriptions all load
into context. AGENTS.md files can load too". An output style or
`--append-system-prompt` may add more. The page's interactive timeline
uses illustrative figures: system prompt 4,200 tokens, auto memory 680,
environment info 280, deferred MCP tool names 120, skill descriptions
450. These are a simulation's example values, not measurements.
<https://code.claude.com/docs/en/context-window>, accessed 2026-09-27, no
page date.

F2. **Claude Code MCP schemas are deferred by default; `/context` shows
what is consuming space.** "MCP tool definitions are deferred by default,
so only tool names and server instructions enter context until Claude uses
a specific tool. Run `/context` to see what's consuming space." CLI tools
such as `gh` "don't add any per-tool listing". `ENABLE_TOOL_SEARCH=auto`
loads schemas up front "when they fit within 10% of the context window"
(F1's page). `/usage` shows session token and cache statistics.
<https://code.claude.com/docs/en/costs>, accessed 2026-09-27, no page date.

F3. **Claude Code's skill listing is capped at 1% of the context window;
each entry at 1,536 characters.** "The budget scales at 1% of the model's
context window. When the listing overflows, Claude Code drops descriptions
starting with the skills you invoke least". The combined `description`
and `when_to_use` "is truncated at 1,536 characters in the skill listing".
Bodies load only when invoked; "Subagents with preloaded skills ... the
full skill content is injected at startup." `/doctor` estimates the
listing's cost; the Skills row in `/context` shows it after the budget.
<https://code.claude.com/docs/en/skills>, accessed 2026-09-27, no page date.

F4. **Claude Code subagents start fresh but reload CLAUDE.md, AGENTS.md
and git status.** "Each subagent starts with a fresh, isolated context
window. It doesn't see your conversation history, the skills you've
already invoked, or the files Claude has already read." Its initial
context is its own system prompt ("not the Claude Code system prompt"),
the task message, "every level of the CLAUDE.md hierarchy ... and any
AGENTS.md files loaded as project instructions", a git status snapshot,
preloaded skills and a sibling roster. Built-in Explore and Plan skip
CLAUDE.md and git status; `omitClaudeMd: true` skips user, project and
local files. Custom subagent descriptions over 15,000 tokens combined
trigger a startup warning. A fork inherits the parent conversation.
<https://code.claude.com/docs/en/sub-agents>, accessed 2026-09-27, no page
date.

F5. **Claude Code guidance: CLAUDE.md under 200 lines; HTML comments are
free.** "target under 200 lines per CLAUDE.md file. Longer files consume
more context and reduce adherence." Imports "still load and enter the
context". A CLAUDE.md up to 4 MiB loads in full; "Shorter files produce
better adherence." MEMORY.md loads its "first 200 lines ... or the first
25KB". "Block-level HTML comments ... are stripped before the content is
injected into Claude's context." No study is cited for the adherence
claim. <https://code.claude.com/docs/en/memory>, accessed 2026-09-27, no
page date.

F6. **Claude Code: move workflow detail out of CLAUDE.md into skills.**
"Skills load on-demand only when invoked, so moving specialized
instructions into skills keeps your base context smaller. Aim to keep
CLAUDE.md under 200 lines". Same page as F2.

F7. **OpenCode lists skills (name and description) in the skill tool's
description and loads bodies on demand.** "Skills are loaded on-demand via
the native skill tool—agents see available skills and can load the full
content when needed." The listing is an `<available_skills>` block;
disabling the skill tool omits it. Descriptions are 1-1024 characters.
OpenCode also reads `.claude/skills/*/SKILL.md` and `.agents/skills/`.
<https://opencode.ai/docs/skills/>, accessed 2026-09-27 (V1 docs).

F8. **OpenCode V2 subagents run "with fresh context"; project
instructions and skills are still added.** "Subagents run with fresh
context in foreground or background child sessions." A non-empty `system`
"replaces the provider's base prompt for that agent", and "Project
instructions, skills, references, and other instruction sources are still
added." The model shown to a parent choosing a subagent is the
subagent's `description`. <https://opencode.ai/v2/docs/agents/>, accessed
2026-09-27, no page date.

F9. **OpenCode config: `instructions` adds files to every session.**
`"instructions": ["CONTRIBUTING.md", ...]` loads extra instruction files
alongside AGENTS.md. <https://opencode.ai/docs/config/>, "last updated"
2026-09-26 (V1 page). Whether each file costs context in every child
session is implied by F8, not stated (**weak**).

F10. **Local: the kit's budget counts a subset of what a session loads.**
`validate` on this repository, 2026-09-27: 6,753-8,808 bytes per role
("~1,689-2,202 tokens", bytes/4), cap 12,100. The count is AGENTS.md
(5,330 bytes, 110 lines here; 2,651 bytes in the product template), the
role body (698-3,047 bytes) and skill names plus descriptions. Not
counted: the harness system prompt and tool schemas (F1), command and
agent descriptions (739 and 856 bytes of `description:` lines here), the
user-level `~/.claude/CLAUDE.md` (2,157 bytes plus a 460-byte `RTK.md`
import on this machine), and SessionStart hook output. This session's
hooks injected the generated `project-leader.md` pointer and a ~5 KB
"Ponytail" style block, and the harness listed about 50 skills,
most from user plugins. Local evidence, measured with `wc -c`;
`product/lib/Sw.Project.psm1` lines 328-337.

### Caching (sub-question 2)

F11. **Anthropic caches the whole prefix `tools` → `system` → `messages`;
a change invalidates its level and all later levels.** Default TTL is 5
minutes, "refreshed for no additional cost each time the cached content is
used"; 1 hour is optional. Writes cost 1.25× base input (5 min) or 2×
(1 h); reads 0.1×. Minimum cacheable length: 512 tokens for Opus 5.5,
Opus 5, Fable 5/5.1; 1,024 for Sonnet 5 and Sonnet 4.x; 4,096 for Haiku
4.5. Shorter prompts "cannot be cached ... and no error is returned".
Changing tool definitions invalidates everything; thinking and effort
changes invalidate at least the messages cache.
<https://platform.claude.com/docs/en/build-with-claude/prompt-caching>,
accessed 2026-09-27, no page date.

F12. **Claude Code orders requests stable-first; editing CLAUDE.md
mid-session neither invalidates the cache nor takes effect.** Layers:
system prompt and tool definitions, then project context (CLAUDE.md, auto
memory, unscoped rules), then conversation. Root and user CLAUDE.md "are
read once at session start ... the edit also doesn't apply" until
`/clear`, `/compact` or restart. Cache-breaking actions: `/model`
switches (each model has its own cache), effort changes on most models,
adding or removing loaded tool definitions, compaction (conversation layer
only), and a new Claude Code version. Plugin skills, commands and agents
are appended, never invalidating. `/usage` reports a "Prompt cache (main)"
line with hit share and misses (v2.1.251+).
<https://code.claude.com/docs/en/prompt-caching>, accessed 2026-09-27, no
page date; `/usage` detail from F2's page.

F13. **OpenAI caches automatically from 1,024 visible tokens; retention
is minutes to hours.** "The minimum cacheable prompt length is 1,024
tokens for GPT-5.6 and later"; the cached length rounds down to multiples
of 128. For GPT-5.6+, writes cost 1.25× and reads 0.1×. Default entries
remain reusable "for 30 minutes after its most recent write or reuse";
other retention modes are described as "around 5 to 10 minutes of
inactivity, up to one hour" and extended "up to 24 hours". Compaction
"can change the prefix, so the first request after compaction may reuse
less". <https://developers.openai.com/api/docs/guides/prompt-caching>
(fetched from `platform.openai.com/docs/guides/prompt-caching`; canonical
link as shown), accessed 2026-09-27, no page date.

### Size guidance (sub-question 3)

F14. **Secondary: instruction-following degrades as instruction count
grows.** IFScale (500 keyword-inclusion instructions, 20 models) finds
"even the best frontier models only achieve 68% accuracy at the max
density of 500 instructions", with "bias towards earlier instructions".
It measures keyword inclusion in a report, not agent rules; it is a
preprint benchmark. Secondary. Jaroslawicz et al., "How Many Instructions
Can LLMs Follow at Once?", <https://arxiv.org/abs/2507.11538>, submitted
2025-07-15, accessed 2026-09-27.

F15. **Anthropic skill guidance: SKILL.md body under 500 lines; only
metadata preloads.** "At startup, only the metadata (name and
description) from all Skills is pre-loaded." "Keep SKILL.md body under
500 lines for optimal performance." Ask of each paragraph "Does this
paragraph justify its token cost?" Consistent with 01-F6 (body under
5,000 tokens). <https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices>,
accessed 2026-09-27, no page date.

Vendor size guidance, together: CLAUDE.md under 200 lines (F5); skill
body under 500 lines (F15) or 5,000 tokens (01-F6); Codex instruction
chain capped at 32 KiB (02-F1); skill listing entry 1,536 characters (F3)
or 1,024 (F7, 01-F6). None of the vendor pages cites evidence for the
adherence claim; F14 is the only measurement found, and it is secondary.

### Long sessions (sub-question 4)

F16. **Claude Code: auto-compaction, `/compact` with focus, and
what survives.** Auto-compaction "summarizes conversation history when
approaching context limits" (F2's page). After compaction the system
prompt applies, project-root CLAUDE.md and auto memory are "Re-injected
from disk"; nested CLAUDE.md reloads when a matching file is read.
Invoked skills are re-attached up to 5,000 tokens each, 25,000 combined,
most recent first (F3's page). `/autocompact <tokens>` sets the
threshold; per-model defaults live on the model-config page (not
fetched). A mid-session `/compact` reads the warm cache, so it "costs a
fraction of what the context size suggests" (F12's page). Sources: F1,
F2, F3, F12 pages.

F17. **OpenCode `compaction` config: `auto` (default true), `prune`
(default false) and `reserved`.** "auto - Automatically compact the
session when context is full"; "prune - Remove old tool outputs to save
tokens"; "reserved - Token buffer for compaction". V2 has "Hidden
compaction, title, and summary agents" (F8's page). Source: F9's page.

F18. **Both vendors recommend subagents to keep verbose output out of the
main context.** Claude: "Delegate verbose operations to subagents ... the
verbose output stays in the subagent's context while only a summary
returns", but "The subagent's own requests still draw on your usage"
(F2's page). Agent teams use "approximately 7x more tokens" in plan mode
(F2's page). Sources: F2, F4 pages.

F19. **Claude documents tool-output condensing through hooks.** A
PreToolUse hook can rewrite a test command to keep only failures,
"reducing context from tens of thousands of tokens to hundreds".
Same page as F2. Local precedent: the owner's `~/.claude/RTK.md` tells the
agent that command output "is condensed to save tokens" and to re-run
with `rtk proxy` only when output is unusable; `sw doctor` already prints
`rtk gain --project` when `rtk` is installed (`Sw.Project.psm1` line 761).
Local evidence, read only; RTK itself was not inspected.

### Free-model context windows (sub-question 5)

F20. **Free OpenRouter models have 64K to 1M context windows; median
256K.** Unauthenticated `GET https://openrouter.ai/api/v1/models`, 458
models on 2026-09-27. The 17 `:free` IDs report `context_length` from
65,536 (`liquid/lfm-2.5-2.6b:free`) to 1,048,576, median 262,144; the
coding-capable ones (Qwen 3.8 27B, Nemotron 3 Super, Ling, Laguna, Gemma
4) are 262,144. `top_provider.max_completion_tokens` ranges 8,192 to
460,800. No free entry has an `input_cache_read` price field.
<https://openrouter.ai/api/v1/models>, accessed 2026-09-27 (live data;
counts change; builds on 03-F9).

F21. **OpenCode Zen lists cached reads as "Free" for its free models.**
The pricing table shows Input, Output and Cached Read as "Free" for Big
Pickle and eight other "Free" models; Jev 1.13 Free shows no cached-read
price. Whether cache hits occur is not stated (**weak**).
<https://opencode.ai/docs/zen/>, "last updated" 2026-09-26.

F22. **OpenRouter caching is provider-dependent with sticky routing;
free endpoints are not mentioned.** "Most providers automatically enable
prompt caching", Anthropic and Alibaba need `cache_control`. After a
cached request OpenRouter routes the same model to the same provider;
sticky sessions "expire after 10 minutes of inactivity" and apply "only
when the provider's cache read pricing is cheaper than regular prompt
pricing". OpenAI via OpenRouter has "a minimum prompt size of 1024
tokens". The word "free" does not appear on the page (**weak**): with a
zero price, the sticky-routing condition cannot hold as written.
<https://openrouter.ai/docs/guides/best-practices/prompt-caching>, accessed
2026-09-27, no page date.

F23. **Local runtimes are the small-window case: Ollama defaults to 4K
under 24 GiB VRAM.** "< 24 GiB VRAM: 4k context; 24-48 GiB VRAM: 32k
context; >= 48 GiB VRAM: 256k context". "Tasks which require large
context like web search, agents, and coding tools should be set to at
least 64000 tokens." Set with `OLLAMA_CONTEXT_LENGTH`; `ollama ps` shows
the allocated `CONTEXT`. <https://github.com/ollama/ollama/blob/main/docs/context-length.mdx>
(fetched raw from `raw.githubusercontent.com`, `main`), accessed
2026-09-27.

## 3. Options compared

### What the budget measures

| Option | Measures | Deterministic | Cost | Weakness |
|---|---|---|---|---|
| a. Bytes (today) | kit-owned text, UTF-8 bytes | yes | none | tokens only estimated; misses harness load (F10) |
| b. Tokens via a tokenizer | same text, one tokenizer | yes per tokenizer | new dependency | tokenizers differ per model; still misses harness load |
| c. Model-relative cap (% of window) | bytes/4 against the model's `context_length` | needs tier map and a model lookup | network call or catalog | free windows are 64K+ (F20), so the kit share is ~1-3%; the cap rarely binds |
| d. Harness measurement | `/context`, `/usage` (F2, F3, F12) | no, manual and per session | none | interactive; not scriptable in `validate` |

### Where to spend effort

| Lever | Size of effect | Source |
|---|---|---|
| Kit files (AGENTS.md, role body, skill listing) | ~1.7-2.2K tokens per role (bytes/4) | F10 |
| Harness system prompt and tools | ~4.2K tokens illustrative in Claude | F1 |
| User and plugin additions (hooks, plugin skills, user CLAUDE.md) | unbounded by the kit; ~5 KB hook here | F10 |
| Conversation and tool output | dominant in long sessions | F16, F18, F19 |
| Local model window | 4K default can fail before the first prompt | F23 |

## 4. Recommendation

R1. **Keep the byte cap (option a); stop calling it a token budget.**
Bytes are deterministic and tokenizer-free, which suits a static
`validate` check. The kit's share is 1,689-2,202 estimated tokens, about
3% of the smallest free OpenRouter window (64K, F20) and under 1% of the
typical 256K. No evidence supports a model-dependent cap (option c): the
windows where it would bind are local runtimes (F23), and there the
harness's own load (F1) already fails first. Change the output label to
"~N tokens (bytes/4 estimate; tokenizer varies)". bytes/4 is a common
English rule of thumb, but this task did not verify it; verify against
`/context` (Q4); no tokenizer dependency (owner, 2026-09-27);
Markdown with paths and code usually tokenizes denser, so read it as a
lower bound on tokens.

R2. **Say what the budget excludes, in `sw doctor`, not in `validate`.**
Add one line under doctor's "Startup budget per role" section: "Kit files
only. Harness prompt, tool schemas, user files, hooks and plugins are not
counted; check `/context` (Claude) for the real total." This is the
honest measurement path (F2, F3, F10) and needs no new code path.

R3. **Doctor: warn on a small local context window (optional, later).**
If a tier uses `ollama/...`, print the Ollama guidance: at least 64,000
tokens, `OLLAMA_CONTEXT_LENGTH`, `ollama ps` (F23). Defer until a tier map
actually points at a local runtime; today none does.

R4. **Role bodies and AGENTS.md: no change.** Role bodies (0.7-3 KB) are
far under every vendor limit (F5, F15, 01-F6). The product AGENTS.md
template is 2.6 KB; the dogfood one is 110 lines, under Claude's 200
(F5). The 12,100-byte cap leaves about 3.3 KB headroom for the leader;
keep it and keep requiring evidence to raise it. Keep the generated
header as an HTML comment: Claude strips it (F5).

R5. **Commands-as-skills (02-R3): decide on portability, not tokens.**
Both harnesses list skills as name plus description and load bodies on
demand (F3, F7). The nine command descriptions total 739 bytes here
(F10), so conversion changes startup load by well under 1 KB either way.
If converted, the leader budget should count them as skills; today it
counts neither commands nor agent descriptions. Optional: add agent
`description:` bytes to the leader's count only, since it is the only role
that sees the subagent catalog (F4, F8); that adds 856 bytes here.

R6. **Caching: document two rules, add no code.** (a) Instruction edits
and `sw update` take effect in Claude only after `/clear`, `/compact` or a
restart (F12); say so in the `update` output or docs. (b) Tier or effort
switches mid-session break the cache in every harness (F11, F12, F13);
keep one model per session, which the global rules already say. The kit's
startup text (~2K tokens) exceeds Anthropic's 512-1,024-token minimum
for current models (F11) but relies on the harness prefix to reach
Haiku's 4,096. Caching on free endpoints is unconfirmed (F20-F22); do not
count on it.

R7. **Long sessions: rely on the harness plus the existing record
pattern.** Claude re-injects root CLAUDE.md and AGENTS.md-derived project
context after compaction (F16); task state already lives in
`.sw/comms` records, which survive compaction by being files. Keep
subagents for verbose work (F18). Do not ship tool-output condensing: it
is a local hook or tool (F19), and doctor already surfaces RTK when
present. Mention OpenCode's `compaction.prune` (F17) as a user option in
docs; do not set it in templates.

Interactions (one line each):
- Topic 3: small context windows argue against `liquid/lfm-2.5-2.6b:free`
  (64K) for any tier; the advisor skill (03-R1) can read `context_length`.
- Topic 6: auto memory loads up to 200 lines or 25 KB per session (F5);
  its budget belongs to topic 6.
- Topic 9: whether `validate` should test the doctor note is topic 9's.

## 5. Open questions

Owner answers recorded 2026-09-27 (relayed by the Leader).

1. Owner: adopt R1 and R2 (relabel tokens as an estimate; doctor states
   what is excluded)? Both change files installed projects receive.
   **Answer:** adopted.
2. Owner: count agent descriptions in the leader's budget (R5, +856 bytes
   here)? It keeps the leader under the cap today.
   **Answer:** yes, count agent descriptions for the leader.
3. Owner: may a later task add a tokenizer (a dependency) to check bytes/4
   once? Without it the ratio stays unverified.
   **Answer:** no tokenizer; bytes/4 is checked against a `/context` run
   (Q4).
4. Runtime test: run `/context` in a fresh Claude session of this repo and
   record the real startup total per category; compare with F10's 8,808
   bytes for the leader. Only the owner's interactive session can do this.
   **Answer:** runtime test, open.
5. Runtime test: does OpenCode add AGENTS.md to every child session, and
   what does its context display show at startup (F8, F9, Not covered)?
   **Answer:** runtime test, open.
6. Budget report: 18 research calls (15 page or API fetches in two
   batches, plus the Zen page, the Ollama raw file and the OpenAI tokens
   help page returned no text), no searches, cap 25. Total tool calls
   about 30, including kit measurement and reading saved text. Dropped:
   Claude `model-config` thresholds, OpenCode V2 context display, Codex
   beyond 02-F1, a tokenizer check.
7. Fetched pages contained no text directed at this task. The Claude
   pages carry a generic "Fetch the complete documentation index" line for
   readers.

## 6. Supersedes / updates

None superseded. Extends 01-F6 (skill size) with F3 and F15, and 02-F1
(Codex 32 KiB) with the other harnesses' guidance. Bears on 02-R3
(commands-as-skills): the token case is neutral (R5). Adds
`context_length` to 03-F9's list of usable OpenRouter fields. Answers
roadmap topic 4.
