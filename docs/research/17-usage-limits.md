# 17: Subscription usage limits and the levers that reduce usage

Date: 2026-10-27 UTC. Status: complete for the vendor-documented levers listed
below; the vendors do not publish the weights behind the limits (section 5).
All sources accessed 2026-10-27 between 02:00Z and 02:30Z. No shipped default
other than model-free tier guidance changed (section 4).

## 1. Question and scope

How are Claude and ChatGPT/Codex subscription limits metered, and which levers
reduce usage without naming a model in shared files (design rule O9)?

Scope: vendor-documented behavior only. Excluded: measurements from any
particular session, account or plan details, machine paths, session IDs, proxy
details and third-party benchmark tables. Independent speed and quality
comparisons exist (for example <https://artificialanalysis.ai/>); none is used
here, and this page makes no tier-fit claim.

Source method: each cited page was fetched on the access date above through a
web-fetch tool that returns the page text or a model-written extract. Status
per source is stated with the finding. Pages showed no machine-readable
publication date unless a date is given. Fetched pages are product
documentation and change without notice; a later reader should re-fetch before
relying on a figure or version number.

## 2. Findings

F1. **Claude paid plans meter usage in a five-hour session window plus weekly
limits, and the pool is shared across apps.** "A session limit that resets
every five hours, and weekly limits that reset once every week"; usage of
"claude.ai, Claude Code, Claude Desktop" counts toward "the same usage limit".
The Claude Code article repeats that "all activity in both tools counts against
the same limits" (IDE use included), and says higher plans add a separate
weekly limit for the top model. At the session limit a small, capped wrap-up
allowance exists and counts toward the weekly limit. Sources, status read in
full (extract, page "Updated over 2 weeks ago" and "Updated this week"):
<https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work>,
<https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan>.

F2. **Vendor-listed usage drivers and reductions (Claude apps).** Drivers named:
conversation length and complexity, features used, model, effort level, and
tools and connectors ("token-intensive"); conversations that trigger automatic
context management "consume more of your usage limit". Reductions named:
extended thinking off, lower effort, turn off unneeded tools, shorter project
instructions, fewer project files, a new conversation instead of a long one,
grouping related questions in one message. Caches "expire after a period of
inactivity", after which the first message counts the content in full again.
Sources, status read in full (extract; the first shows "Updated over 2 weeks
ago", the second is dated 2026-09-22):
<https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work>,
<https://support.claude.com/en/articles/9797557-usage-limit-best-practices>.

F3. **Model choice weights usage; the weights are not published.** The vendor
says each turn "sends three things" (conversation so far, project context, new
prompt), that the first grows fastest, that a higher-capability model "costs
several times more per turn" than the next tier down, and that spending the
top tier on routine work "is the fastest way to drain a daily limit"; the
middle tier is "the right choice for the large majority of coding work" and
the smallest is for mechanical tasks. These are relative statements about
cost per turn; no page found gives the subscription-limit weight of any model.
Source, read in full (extract, dated 2026-09-22):
<https://support.claude.com/en/articles/14552983-claude-code-usage-limits-and-how-to-manage-them>.
Cross-reference: open question Q1.

F4. **Effort level changes token spend; defaults are per model.** "Lower effort
is faster and cheaper for straightforward tasks"; `medium` "reduces token
usage"; `xhigh` is "deeper reasoning at higher token spend"; `max` "may show
diminishing returns and is prone to overthinking, so test before adopting it
broadly". The scale "is calibrated per model, so the same level name does not
represent the same underlying value across models", and the default differs by
model (some default to `medium`, most to `high`). Thinking tokens are billed as
output tokens. An explicit `CLAUDE_CODE_EFFORT_LEVEL`, `--effort` or `/effort`
choice takes precedence over saved settings. Effort changes keep the prompt
cache on the newest model generations with a subscription or API key and
invalidate it on others (F6). The page gives no per-level multiplier.
Sources, status read in part (first 100,000 characters; the requested sections
were complete):
<https://code.claude.com/docs/en/model-config#adjust-effort-level>,
<https://code.claude.com/docs/en/costs#adjust-extended-thinking>.

F5. **Cached input still draws usage, so context length matters every turn.**
Claude Code resends the whole conversation with each request, and "a one-line
question in a session that has been open all day still draws usage for the
whole conversation" even though history is re-read "at the cached token rate".
Caching is by exact prefix match; each model, and on most models each effort
level and each speed, has its own cache. Two TTLs exist (five minutes and one
hour). On a subscription within included usage the main conversation requests
the one-hour TTL; subagents, forks, compaction and other non-main requests get
five minutes by default; over the plan limit, on usage credits, an API key or a
cloud provider the main conversation also defaults to five minutes. The first
message after a gap longer than the TTL reprocesses the full context.
Sources, status read in full (page text):
<https://code.claude.com/docs/en/costs#why-usage-climbs-in-a-long-session>,
<https://code.claude.com/docs/en/prompt-caching#cache-lifetime>.

F6. **Some actions rebuild the cache; others keep it.** Invalidating: switching
models (including `opusplan` mode toggles and a skill whose frontmatter names
another model), changing effort on models where each level has its own cache,
turning fast mode on or off, adding or removing tool definitions when tools are
loaded upfront, compaction (the conversation layer), many accumulated images,
and upgrading the client. Keeping: editing CLAUDE.md mid-session (the edit also
does not apply until `/clear`, `/compact` or a restart), invoking skills,
changing permission mode, `/rewind`, and spawning a subagent. The vendor's tip:
choose model and effort at the top of a session and save `/compact` for natural
breaks.
Source, status read in full (page text):
<https://code.claude.com/docs/en/prompt-caching#actions-that-invalidate-the-cache>.

F7. **Compaction is itself a request, and costs most when the cache is cold.**
Summarizing sends a separate request carrying the system prompt, tools and the
history being summarized; while the cache is warm it reads the prefix from the
cache and "costs a fraction of what the context size suggests". After a break
longer than the TTL it "reprocesses that history as uncached input", which is
why `/compact` costs the most when resuming an old session. `/clear` "costs
nothing" and is the vendor's most effective lever between unrelated tasks. The
auto-compact window is configurable (100,000 to 1,000,000 tokens; per model,
flag, setting or environment variable, with documented precedence); the
vendor documents no recommended value and this page recommends none.
Sources, status read in full (costs, prompt-caching) and in part (model-config,
first 100,000 characters; the requested section was complete):
<https://code.claude.com/docs/en/prompt-caching#compacting-the-conversation>,
<https://code.claude.com/docs/en/costs#manage-context-proactively>,
<https://code.claude.com/docs/en/model-config#set-the-auto-compact-window>.

F8. **Tool search defers MCP tool definitions and is on by default.** Only tool
names and server instructions enter context until a tool is used; `/context`
shows what consumes space; unused servers can be disabled with `/mcp`, and CLI
tools add no per-tool listing. `ENABLE_TOOL_SEARCH` unset and `true` both defer
all MCP tools; `auto` or `auto:N` defers only above a context-percentage
threshold; `false` loads everything upfront. Tool search needs a model that
supports it and a deployment that accepts it. Behind an LLM gateway
(`ANTHROPIC_BASE_URL`), tool search is on by default from v2.1.304; before
that it was off unless `ENABLE_TOOL_SEARCH` was `true`, `auto` or `auto:N`.
Deferral also keeps the cache stable when servers connect mid-session (F6).
`alwaysLoad` exempts a server. The environment-variable reference page was read
only to character 100,000, which does not reach `ENABLE_TOOL_SEARCH`; the
behavior above comes from the MCP page.
Sources, status read in part (MCP page, the tool-search sections complete):
<https://code.claude.com/docs/en/mcp#configure-tool-search>,
<https://code.claude.com/docs/en/mcp#tool-search-through-a-gateway>,
<https://code.claude.com/docs/en/costs#reduce-mcp-server-overhead>.

F9. **Subagent model inheritance: the environment default does not reach the
built-in subagents without a force flag.** Subagent model resolves in order:
the per-call `model` parameter, the definition's `model` frontmatter
(`inherit` follows the main conversation), `CLAUDE_CODE_SUBAGENT_MODEL`, then
the main conversation's model. (Before v2.1.251 the environment variable came
first.) "Setting `CLAUDE_CODE_SUBAGENT_MODEL` by itself doesn't change the
model the built-in Explore and Plan subagents run on." Setting
`CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` (v2.1.257 or later) applies one model to
every subagent, teammate and workflow agent: with both variables set,
subagents run on the model in `CLAUDE_CODE_SUBAGENT_MODEL`; with only FORCE,
they run on the main conversation's model, except built-in Explore keeps its
own listed model. While FORCE is on, Claude Code ignores the `model` field in
subagent definitions and Claude cannot pass a model when it starts a subagent;
forks and `model: inherit` skills in a subagent stay on the main model. A
user or project subagent named `Explore` overrides the built-in. Subagents
inherit the main conversation's thinking setting. A subagent starts its own
cache and does not read the parent's, so its first request is uncached; its
requests still draw on plan usage; `/tasks` shows the model a subagent runs on.
Sources, status read in full (the requested sections; the page was read to
character 100,000 of 116,349):
<https://code.claude.com/docs/en/sub-agents#choose-a-model>,
<https://code.claude.com/docs/en/sub-agents#run-every-subagent-on-one-model>,
<https://code.claude.com/docs/en/costs#delegate-verbose-operations-to-subagents>.

F10. **Claude fast mode raises per-token cost and is outside subscription
limits.** Fast mode is the same model with a faster configuration at a higher
price per token; on subscription plans it is "available via usage credits only
and not included in the subscription rate limits" and "draws directly from
usage credits, even if you have remaining usage on your plan". Fast mode and
standard speed keep separate caches, so the first enablement in a conversation
reads the whole context uncached at fast rates, and every later toggle (or an
automatic fallback to standard speed) can do so again; enable it at the start
of a session if at all. The page is labelled a research preview whose pricing
may change.
Source, status read in full (page text):
<https://code.claude.com/docs/en/fast-mode>.

F11. **Codex and ChatGPT share one usage pool; the vendor gives estimates, not
fixed limits.** "ChatGPT Work and Codex share usage." Per-model figures are
local messages per five-hour period and cover individual and standard
business tiers; cloud tasks may consume more than local messages, local
messages and cloud chats share one allowance, and weekly caps may also apply.
Factors named: model, task size and complexity, local versus cloud, context,
reasoning, tool use, retrieval and caching; "prompt length alone isn't a
reliable estimate". After included limits end, credits (priced per million
input, cached input and output tokens per model, with no separate cache-write
charge in Codex) keep work going. Tips named: tight prompts, only relevant
files, a smaller AGENTS.md, fewer MCP servers (each adds context), a smaller
model or narrower scope when usage runs high, and a weekly check of the usage
dashboard or `/status`.
Source, status read in full (page text; no page date shown; the original
address redirects with HTTP 308):
<https://developers.openai.com/codex/pricing> redirecting to
<https://learn.chatgpt.com/docs/pricing>.

F12. **Codex per-model message ranges are vendor estimates and span an order
of magnitude within a model.** The page's local-message estimates per five
hours, identical for the base individual paid tier and the standard business
tier (the page states "These estimates are not fixed message limits" and
points to the usage dashboard for current limits):

| Model (as named on the page) | Local messages per 5 hours |
|---|---|
| GPT-6 Astra | 5-45 |
| GPT-6.1 Sol | 15-160 |
| GPT-6.1 Terra | 35-285 |
| GPT-6 Sol | 15-150 |
| GPT-6 Luna | 350-3,000 |

The model names and ranges are a dated snapshot (the page itself mentions a
model retirement and a promotional price window); treat them as illustrating
the spread between model tiers, not as a stable quota.
Source, status read in full (page text):
<https://learn.chatgpt.com/docs/pricing>.

F13. **Codex fast modes multiply included-usage burn.** Relative to standard
speed on the same model, Fast uses 2.5x included subscription usage (2x
purchased credits), and the Ultrafast modes listed for two models use 8x
(6x credits). "Priority request processing" appears only as an enterprise
plan feature and is not tied to usage rates on the page.
Source, status read in full (page text): <https://learn.chatgpt.com/docs/pricing>.

### Local findings

F14. Local: the kit's tier guidance is deliberately model-free. Vendor limit
weights are unpublished (F3, F12), model lineups and defaults change within
months (F4, F10, F12), and shared files must not carry personal routing (O9).
The guidance therefore names levers (tier, effort, explicit launch settings,
no fast modes by default), and a personal ignored file maps tiers to models.

F15. Local: the fetch tool used for this page returns page text or a model
extract, not raw HTML; quotations above are from that output and were not
diffed against the live pages. Findings that rest on an absence in the fetched
text are marked as such (F8, the environment-variable page).

## 3. Options compared

- **Pin models in shared files.** Rejected by O9 and by F14: the weights are
  unpublished and the lineup changes.
- **Model-free tier guidance in the shared rules (adopted).** Names the levers
  that F3-F10 and F13 support without naming a model: planning on the
  mid-to-top tier at moderate effort, implementation from a written scope on
  the mid tier, explicit model and effort on every launch, no maximum effort
  or fast modes by default.
- **Settings in the T3 Claude provider environment (adopted as setup
  documentation only).** `ENABLE_TOOL_SEARCH`, `CLAUDE_CODE_SUBAGENT_MODEL` and
  `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` (F8, F9). Owner-applied; the kit changes no
  machine setting.
- **Agent-definition `model` fields.** Out of scope here, and overridden while
  FORCE is on (F9).
- **An auto-compact window value.** Deferred: F7 documents the control but no
  recommended value, and the right value needs a fresh measurement.

## 4. Recommendation

1. Ship the model-free tier guidance (rule text, workspace rules and
   onboarding) and revise the O9 provenance to cite this page.
2. Document the three environment settings in the setup guide with their
   tradeoffs: FORCE moves the built-in Explore and Plan subagents (F9) but also
   overrides definition `model` fields and explicit per-call choices; the
   environment applies to new sessions only; the model ID is the user's own.
   On current client versions tool search is already the default (F8), so
   `ENABLE_TOOL_SEARCH=true` makes the choice explicit and covers older client
   versions behind a gateway.
3. State no auto-compact value (F7) and no per-model weights (F3, F12).
4. The "small tier for non-agentic lookups only" and "mid tier for
   exploration" parts of the guidance are kit decisions (F14); the vendor pages
   support matching the model to the job (F3) and cheaper subagent models
   (F9), not that specific split.

## 5. Open questions

- Q1: Subscription-limit weights per model and per effort level are not
  published (F3, F4, F12); only relative cost statements and Codex estimate
  ranges are. A measurement would be local evidence, not vendor documentation.
- Q2: Whether Claude's included-usage metering follows the same cached-input
  discount as per-token pricing is not stated on the pages read; F5 says only
  that cached history still draws usage.
- Q3: How much cache TTL choices change subscription burn is undocumented
  beyond the defaults in F5.
- Q4: The environment-variable reference page was not read past character
  100,000, so rows after `CLAUDE_CODE_OTEL_*` (including
  `CLAUDE_CODE_SUBAGENT_MODEL*` and `ENABLE_TOOL_SEARCH`) were not checked there;
  the behavior was confirmed on the sub-agents and MCP pages instead.
- Q5: Whether the T3 Claude provider passes its instance environment to
  subagent and tool processes in the way F9 assumes was not verified here.
- Q6: Version numbers in F8 and F9 (v2.1.251, v2.1.257, v2.1.304) are taken
  from the pages; the installed client version was not checked.

## 6. Supersedes / updates

Supersedes nothing. Updates the provenance of O9 (tiers and budgets) in the
design register and complements topic 04 (context and token efficiency) with
subscription-metering and caching mechanics. The outline owns the selected
direction; state owns implemented behavior.
