# 03: Model advisor (detect providers, recommend tiers, free by default)

Status: complete; reviewed by the owner 2026-09-27; R1, R2, R4, R6, R7 adopted; R3 and the F20 fix recorded for after the rewrite; R5 `effort` deferred.
Researched 2026-09-26 (local) by `project-research` (research-3, Claude Opus 5.5
via Claude Code). All sources accessed 2026-09-27 between 02:15Z and 02:17Z;
page dates are given where the page showed one. Raw page text was saved
with `curl` to the session scratchpad (outside the repo), and every finding
was re-checked against that text, not against a model summary. No finding
is summary-based. Findings resting on an *absence* in the fetched text are
marked **weak**.

## 1. Question and scope

How can a kit detect which models and providers a user has, cheaply and
without touching credentials, and recommend a model per tier (reasoning,
standard, fast) that defaults to free and never forces a choice?

Sub-questions:
1. Detection: per-harness model listing and local runtimes; which need no
   credentials, a key, or money.
2. Free sources: how free models are identified programmatically; limits
   and data-use terms.
3. Ranking: sources that rank models by tier fit; change rate, licence,
   offline use.
4. Mapping: tier recommendation to per-harness config, including effort
   and variant fields; how comparable tools present it.
5. Recommendation mapped onto `sw tiers`, the `free-models` skill,
   `sw doctor`, the Claude adapter map, `roles.json` tiers and the standing
   rules.

Out of scope (one line each):
- Role design (topic 5): `roles.json` tier membership is taken as given.
- Token budgets (topic 4): context window sizes are not compared.
- Install and update (topic 7): how an advisor ships is not covered.
- Permissions (topic 8): `permission` syntax is not covered.
- Specific paid-model rankings: mechanisms only, per the assignment.

Not covered:
- Codex CLI: whether a command lists models. The config reference shows
  `model`, providers and a catalog file, not a list command (**weak**).
- Gemini CLI settings keys for per-subagent `model` beyond 02-F6.
- OpenRouter's numeric free-model limits: the table's numbers are rendered
  client-side and are absent from the raw HTML (F10).
- LMArena data and terms: the leaderboard page is client-rendered; only its
  navigation text was captured (F14).
- OpenCode V2 CLI page: `opencode models` is taken from the V1 CLI page
  (F2); the V2 CLI page was not fetched.
- Comparable tools' advisor UX (sub-question 4, second half): no advisor
  tool was fetched. The harness pickers themselves (F3, F7, F9) are the
  precedent used instead.
- Artificial Analysis Terms of Use and Data Platform Terms: linked, not
  fetched.

## 2. Findings

Topic 1 and 2 findings are cited as `01-F<n>` and `02-F<n>`.

### Detection (sub-question 1)

F1. **OpenCode V2 lists models in `/models` from models.dev, provider
integrations and config; selection is per session.** "The selector only
shows enabled models whose provider is available in the current project."
Selecting in `/models` "does not change your configuration". Variants are
chosen with `#variant` (`opencode run --model openai/gpt-5.2#high`); "an
unknown variant produces a model-resolution error". "The root model
currently retains only the default provider and model, not a variant."
A config `model` that is unavailable falls back to "the newest available
supported model". <https://opencode.ai/v2/docs/models/>, accessed
2026-09-27, no page date.

F2. **`opencode models [provider]` prints the configured providers'
models as `provider/model`, no credentials shown.** `--verbose` adds
"metadata like costs"; `--refresh` refreshes the cache from models.dev.
`opencode run` takes `--model` and `--variant`. This is the V1 CLI page;
the V2 CLI page was not fetched. <https://opencode.ai/docs/cli/>, "last
updated" 2026-09-26.

F3. **Claude Code has no list command; the `/model` picker and aliases
are the interface.** Aliases: `default`, `best`, `fable`, `sonnet`,
`opus`, `haiku`, `sonnet[1m]`, `opus[1m]`, `opusplan`. What `opus` and
`sonnet` resolve to "depends on the provider" (a table maps Anthropic API,
Bedrock, Foundry and others to different versions). `/model` writes
`model` to `~/.claude/settings.json`; `availableModels` in managed
settings restricts choices, including subagent frontmatter `model`.
Fable usage "can bill to usage credits", shown in the picker.
<https://code.claude.com/docs/en/model-config>, accessed 2026-09-27, no
page date.

F4. **Claude Code subagents and skills accept an `effort` frontmatter
field.** "set effort in a skill or subagent markdown file to override the
effort level when that skill or subagent runs"; caps still apply. An
unsupported level "falls back to the highest supported level at or below
the one you set". Same page as F3.

F5. **Codex CLI configures models in `config.toml`, with a local-runtime
switch.** Keys: `model`, `model_provider`, `model_providers.<id>.base_url`
and `.env_key` ("Environment variable supplying the provider API key"),
`model_reasoning_effort` ("low, medium, high, xhigh, max, or ultra.
Available levels depend on the model and client"),
`agents.default_subagent_model` and `agents.default_subagent_reasoning_effort`,
`model_catalog_json`, and `oss_provider` (`lmstudio | ollama`, used with
`--oss`). No model-listing command appears on the page (**weak**).
<https://learn.chatgpt.com/codex/config-reference>, accessed 2026-09-27,
no page date.

F6. **Gemini CLI: free users moved off it; `/model` offers Auto, Pro,
Flash.** The page banner: "Unpaid tier and Google One users: Gemini CLI
was replaced by Antigravity CLI on June 18th, 2026." `/model` opens a
dialog (Auto (Gemini 3), Auto (Gemini 2.5), Manual); `--model` sets it at
startup; "/model ... does not override the model used by sub-agents".
<https://geminicli.com/docs/cli/model/>, "last updated" 2026-03-19; the
banner is newer than that date.

F7. **Ollama lists local models at `GET /api/tags`, no key.** Example:
`curl http://localhost:11434/api/tags`; each entry has `name`, `size`,
`details.parameter_size`, `quantization_level`, `family`. No
authentication is described for the local API (**weak**, absence).
<https://github.com/ollama/ollama/blob/main/docs/api.md> (fetched raw
from `raw.githubusercontent.com`, `main` branch), accessed 2026-09-27.

F8. **LM Studio serves OpenAI-compatible `GET /v1/models` on
`localhost:1234`.** It also implements `/v1/responses`, which is why Codex
works with it. <https://lmstudio.ai/docs/developer/openai-compat>,
accessed 2026-09-27, no page date. Its Authentication page was not
fetched.

### Free sources (sub-question 2)

F9. **OpenRouter's public models API marks free models, efforts, tool
support and benchmark indices, without a key.** An unauthenticated
`GET https://openrouter.ai/api/v1/models` returned 458 models on
2026-09-27. Fields include `pricing` (`prompt`, `completion` as strings),
`supported_parameters` (for example `tools`, `reasoning_effort`),
`reasoning` (`supported_efforts`, `default_effort`), `expiration_date`,
and `benchmarks.artificial_analysis` (`intelligence_index`,
`coding_index`, `agentic_index`). Counts on that date: 17 IDs end in
`:free`; 21 have zero prompt and completion price. The four zero-priced
IDs without the suffix include the `openrouter/free` router ("selects
free models at random") and a stealth model; routers report price `-1`.
16 of 17 `:free` models list `tools`; 11 carry Artificial Analysis
indices; 5 list `supported_efforts`. So `:free` alone is not the whole
free set, and price `0` is not always a model.
<https://openrouter.ai/api/v1/models>, accessed 2026-09-27 (live data;
counts change).

F10. **OpenRouter free models are rate-limited by credits purchased; the
numbers were not captured.** For free model variants (IDs ending in
`:free`) the page has a table keyed by "Credits purchased (all time)" with
"Requests per minute" and "Requests per day" columns. The numbers are rendered client-side and
absent from the raw HTML. An authenticated `GET /api/v1/key` reports
`free_model_daily_requests` (`used`, `limit`, `remaining`); "The
per-minute limit is not reported there." A negative balance can cause
errors "including for free models".
<https://openrouter.ai/docs/api-reference/limits>, accessed 2026-09-27,
no page date.

F11. **OpenRouter training opt-out is an account setting, separate for
free and paid.** "you can set whether you would like to allow routing to
providers that may train on your data ... There are separate settings for
paid and free models." Opting out means OpenRouter "will not route to
providers that train". <https://openrouter.ai/docs/guides/privacy/provider-logging>,
accessed 2026-09-27, no page date.

F12. **OpenCode Zen lists free models by name and states data use per
model.** The model list is at `https://opencode.ai/zen/v1/models`
(not fetched). The pricing table marks ten models "Free", all "for a
limited time". Privacy: providers are zero-retention "with the following
exceptions": Big Pickle, MiMo-V2.6-Flash Free, MiMo-V2.5 Free and Ling 3.0
Flash Fin Free ("collected data may be used to improve the model");
Nemotron 3 Ultra Free and Nemotron 3.5 Lightning Free ("Trial use only —
do not submit personal or confidential data", logged); Muse Spark 1.3
Contributor Free ("permission to use your prompts and completions to
train future Meta models"). Space Bunny Free and LongCat 2.5 Preview Free
state zero retention and no training. The page lists Muse Spark 1.3
Contributor Free as "Free" in the pricing table but calls it "Heavily
discounted token pricing" under Privacy; the two conflict, so treat it as
possibly metered. Zen model IDs are `opencode/<model-id>`.
<https://opencode.ai/docs/zen/>, "last updated" 2026-09-26.

F13. **The `free-models` skill is already partly stale.** It names GLM
5.2 on the free OpenRouter endpoint. On 2026-09-27 no `z-ai/glm*` ID
ended in `:free` (F9), and Zen lists GLM 5.2 at $1.40/$4.40 per million
tokens (F12). Inkling (`thinkingmachines/inkling:free`), Qwen 3.8 27B,
Ling 3.0 Flash Fin and Nemotron 3 Ultra are still free on OpenRouter (F9).
Sources F9, F12; the skill is
`.opencode/skills/free-models/SKILL.md` ("Observed 2026-09").

### Ranking (sub-question 3)

F14. **Artificial Analysis has a free, keyed, rate-limited API with
required attribution.** "Attribution is required for all use of our free
API." Key via account, `x-api-key` header; "rate-limited to 1,000
requests per day"; "please do not include in client side code and cache
responses". `GET /api/v2/data/llms/models` returns stable `id`,
`evaluations` (intelligence, coding, math indices and sub-benchmarks),
`pricing`, speed and latency. Use is "subject to our Terms of Use and Data
Platform Terms" (not fetched). <https://artificialanalysis.ai/documentation>,
accessed 2026-09-27, no page date. Secondary source for rankings.

F15. **OpenRouter re-publishes Artificial Analysis indices without a key**
(`benchmarks.artificial_analysis` in F9). Whether the F14 attribution
duty carries over to data read through OpenRouter is not stated in either
source (open question 4). Sources F9, F14.

F16. **LMArena's leaderboard is client-rendered; categories only.** The
raw page shows rankings "Overall, Agent, Text, WebDev" and more, plus
"Terms of Use"; no scores, dates or API. **Weak.**
<https://lmarena.ai/leaderboard>, accessed 2026-09-27. Secondary.

F17. **Harness vendors publish their own tier guidance, not rankings.**
Claude aliases are described by tier purpose: `opus` "for complex
reasoning tasks", `sonnet` "for daily coding tasks", `haiku` "for simple
tasks" (F3). Gemini: "Pro models for complex tasks and reasoning, Flash
models for high speed results", "Default to Auto" (F6). OpenCode's
recommended list says it is "not an exhaustive list nor is it necessarily
up to date" (<https://opencode.ai/docs/models/>, V1, "last updated"
2026-09-26).

### Mapping (sub-question 4)

F18. **OpenCode V2 agents take `model: provider/model#variant` or an
expanded object with `variant`, under the `agents` key.** Expanded form:
`{"providerID": ..., "model": ..., "variant": "high"}`. "A subagent uses
its configured model, or inherits the parent session's model when none is
configured." <https://opencode.ai/v2/docs/agents/>, accessed 2026-09-27,
no page date. This matches what `Set-SwTiers` writes (`agents.<role>.model`).

F19. **OpenCode V2 model aliases: `modelID` gives an API model a catalog
ID of your choice.** Example: `"model": "openai/coding-default"` with
`providers.openai.models.coding-default.modelID = "gpt-5.2"`. Variants are
an array of `{id, settings}`. Same page as F1.

F20. **The `$schema` URL the kit writes serves the V1 schema.**
`https://opencode.ai/config.json` defines `agent` and `permission`
(singular) and sets `additionalProperties: false` on `Config`; it has no
`agents` key. V2 docs still show that `$schema` URL with `agents`
(F18). So an editor that validates against it may flag the kit's
`opencode.jsonc` and the `sw tiers` output, while V2 accepts them per its
docs. Whether V2 itself validates against this file is untested.
<https://opencode.ai/config.json>, accessed 2026-09-27.

F21. **Per-harness tier fields, extending 02-F24.** Synthesis of the
cited findings; their links and dates (accessed 2026-09-26 or 2026-09-27)
apply.

| Harness | Per-agent model | Effort field | Value format |
|---|---|---|---|
| OpenCode V2 | `agents.<id>.model` (F18) | `#variant` suffix or `variant` (F1, F18) | `provider/model[#variant]` |
| Claude Code | frontmatter `model` (02-F18) | frontmatter `effort` (F4) | alias or full ID (F3) |
| Codex CLI | agent TOML `model` (02-F2); `agents.default_subagent_model` (F5) | `model_reasoning_effort`, `agents.default_subagent_reasoning_effort` (F5) | vendor ID; `model_provider` selects provider |
| Gemini CLI | frontmatter `model` (02-F6) | not found | Gemini model name or Auto (F6) |

Effort level names differ per model even inside one harness: OpenCode
says `low`, `high`, `max` "are not available for every model" (F1);
Claude falls back to the nearest lower level (F4); Codex says levels
"depend on the model and client" (F5); OpenRouter publishes
`supported_efforts` per model (F9).

### Local context

F22. **Local context: an owner-local tool already does
keyless free-model retrieval with a strict-$0 filter.** Its README says
"No keys required for a public run. No billing." Keyless sources:
OpenRouter, NVIDIA, ZenMux, OpenCode Zen and models.dev; OpenAI,
Anthropic, Groq, Cerebras and Artificial Analysis need a key and "are
skipped gracefully when keys are absent". Free rule: "A model counts as
free only if it costs $0 at retrieval time": zero prompt and completion
price (or a `:free` ID), or a Zen `*-free` route; text-only output; no
`openrouter/*` router entries. Artificial Analysis $0 rows without strict
confirmation are listed separately as provisional `[F?]`. This matches F9
(routers and `:free` are not the same set) and F12. Read-only; the tool
was not run. Local evidence, not a primary source.

## 3. Options compared

### Detection source

| Source | Credentials | Cost | Tells you |
|---|---|---|---|
| `opencode models --verbose` (F2) | uses what the user configured; prints none | none | exactly what this user can select, with costs |
| OpenCode `/models` (F1) | same | none | same, interactive only |
| OpenRouter `/api/v1/models` (F9) | none | none | public catalogue: free flag, efforts, tools, AA indices |
| Zen docs or `/zen/v1/models` (F12) | none | none | Zen free list and data use (docs page) |
| Ollama `/api/tags`, LM Studio `/v1/models` (F7, F8) | none, local | none | installed local models |
| Claude `/model` (F3) | account login | none to list | aliases only; no scriptable list |
| Artificial Analysis API (F14) | own key | free, 1,000/day | rankings; attribution required |

### Advisor shape

| Option | What it is | Cost | Risk |
|---|---|---|---|
| a. Doc only | a detection recipe in docs | none | nobody follows it at setup |
| b. Skill (extend `free-models`) | agent runs `opencode models`, reads the public OpenRouter list, proposes a `sw tiers` line | one skill edit | agent-run fetch counts as a web call; stays advisory |
| c. `sw models` command | kit runs `opencode models --verbose`, probes local runtimes, prints a suggested `sw tiers` command | new function, tests, a network call inside the kit | model lists change weekly; free flag needs OpenRouter or Zen data; widens kit scope |
| d. Auto-write tiers | command writes the tier map | as c | forces a choice; violates the standing rule |

## 4. Recommendation

R1. **Smallest useful advisor: a skill (option b), not a command.**
Rewrite the `free-models` skill into a model-advisor procedure:
(1) run `opencode models --verbose` (F2) for what the user actually has;
(2) optionally probe `localhost:11434/api/tags` and `localhost:1234/v1/models`
(F7, F8); (3) identify free models by the strict-$0 filter tested in F22
(zero prompt and completion price or `:free`, Zen `*-free` routes,
text output, routers excluded) over the public OpenRouter list (F9) and
the Zen free list (F12), never by name alone. A user's `rules.local.md`
overlay (topic 1 R1) may point the advisor at a local snapshot report
instead; the product skill names no personal tool; (4) show the data-use terms of each free candidate (F11, F12) and
ask before routing real work to a training endpoint; (5) propose, never
run, one `sw tiers -Reasoning <id> -Standard <id> -Fast <id>` line. The
dated per-model observations stay, labelled as snapshots. This matches the
standing rule "never force a model" and the free-first guardrail, and
adds no code. Option c can follow if the skill proves too slow in use.

R2. **Keep `sw tiers` as the only writer; document `#variant`.**
`Set-SwTiers` already writes the V2 `agents.<role>.model` shape (F18), and
V2 accepts `provider/model#variant` in that string (F1, F18). So effort
per tier needs no code: `-Reasoning opencode/<id>#high` works as written.
One doc line in the skill covers it.

R3. **Refresh the `free-models` skill's facts now or with R1.** GLM 5.2
is no longer free on OpenRouter or Zen (F13). Muse Spark 1.3 Contributor
Free is contradictory on Zen and trains on prompts (F12). Add the
Nemotron "trial use only" terms (F12).

R4. **`sw doctor`: no change now.** It already warns when no tier map
exists and prints a `sw tiers` fix. A future row could say "N free models
available" from `opencode models`, but that makes doctor slower and
network-dependent; defer until R1 is used.

R5. **Claude adapter map: keep aliases, consider `effort`.** The hard-coded
`reasoning=opus, standard=sonnet, fast=haiku` in `Get-SwClaudeFiles`
matches the vendor's own tier wording (F17), and aliases track the
user's provider (F3), so they are the portable choice. Two limits:
aliases resolve to different versions per provider (F3), and
`availableModels` may block one, with Claude substituting a fallback
(F3). Optional: emit `effort` in generated subagents (F4); Claude falls
back safely for models without that level. The adapter ignores the
OpenCode tier map by design; a per-user Claude override is not needed
until someone runs Claude through a non-Anthropic gateway.

R6. **`roles.json` tiers: no change.** Three tiers plus `session` map
cleanly onto every harness's per-agent `model` field (F21).

R7. **Rankings: do not ship ranking data in the kit.** Artificial Analysis
requires a key and attribution (F14); LMArena is not machine-readable
without its API (F16); both change weekly. If a skill mentions a
benchmark, cite a dated snapshot, as the skill already does. The
OpenRouter list gives AA indices keylessly (F15), but attribution for
that path is unconfirmed (open question 4).

Interactions (one line each):
- Topic 2: Gemini CLI is no longer offered to unpaid users (F6), which
  weakens 02-R4's Gemini adapter for a free-first kit.
- Topic 7: if option c is ever built, `update` must not overwrite a user's
  tier map (`Set-SwTiers` already refuses without `-Force`).
- Topic 5: tier membership in `roles.json` is unchanged here.

## 5. Open questions

Owner answers recorded 2026-09-27 (relayed by the Leader).

1. Owner: adopt R1 (skill, no command)? It rewrites the `free-models`
   skill, which installed projects receive through `update`.
   **Answer:** adopted (a skill, no command).
2. Owner: may the advisor skill fetch the public OpenRouter models list
   (one unauthenticated call) at setup, or should it rely only on
   `opencode models` output? The free-first guardrail covers spend, not
   network calls.
   **Answer:** yes, public keyless calls are fine; F22 is the precedent;
   a personal report is reached through the `rules.local.md` overlay.
3. Owner: add `effort` to the generated Claude subagents (R5)? Default
   effort today is the model's own (F4).
   **Answer:** deferred to the roadmap rewrite.
4. Is OpenRouter's re-published Artificial Analysis data covered by AA's
   attribution requirement? Neither page says (F15).
   **Answer:** open.
5. Runtime test: does OpenCode V2 reject or warn on `agents` given the V1
   `$schema` URL (F20)? The dogfood install works today, which suggests
   V2 does not validate against it, but that is not confirmed.
   **Answer:** runtime test; `opencode` is not on the owner's Bash PATH,
   so it is deferred to implementation. The F20 `$schema` mismatch is
   recorded as a known defect, fixed after the rewrite.
6. Runtime test: what does `opencode models --verbose` print for Zen free
   models (price 0 or a label)? The V1 CLI page says it includes costs
   (F2); the exact output decides whether the skill needs OpenRouter at
   all.
   **Answer:** runtime test, deferred to implementation (same reason).
   R3 (stale `free-models` entries, F13) is recorded as a known defect,
   fixed after the rewrite.
7. Budget report: 17 research calls (17 `curl` fetches of 17 URLs, one of
   them the OpenRouter JSON), no searches, cap 25. Total tool calls about
   30, including reading the raw text and kit code. Saving raw text
   worked: every finding was re-checked from saved text with no extra
   research calls. It failed for client-rendered pages (OpenRouter limit
   numbers, LMArena). Dropped: V2 CLI page, Zen `/zen/v1/models`, AA
   terms, LMArena API, Codex model listing, advisor precedents.
8. Fetched pages contained no text directed at the agent. The Claude and
   OpenRouter pages carry a generic "Fetch the complete documentation
   index" line for readers, not an instruction to this task.

## 6. Supersedes / updates

None superseded. Updates `02-multi-harness.md`: F21 adds effort fields to
02-F24's `model` row, and F6 (Gemini CLI replaced for unpaid users)
bears on 02-R4 and 02-R5 (for the Leader's roadmap fold). Updates the `free-models` skill's GLM 5.2 entry
(F13); this file proposes no edit to it. Answers roadmap topic 3.
