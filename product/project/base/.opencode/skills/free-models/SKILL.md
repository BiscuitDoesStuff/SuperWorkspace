---
name: free-models
description: Shareable baseline of free-model reasoning options, defaults, and constraints; each machine verifies against its own provider list.
---

# Free models

Use when choosing effort levels for free models in OpenCode, or when
applying the baseline to a machine. This is shared knowledge, not
configuration: it contains no provider credentials and no config blocks.
Every option below must be confirmed against that machine's `/models`
output before use; endpoints, levels, and defaults change. Dated
observations are single-machine snapshots, not standing guarantees.

Benchmark figures, where mentioned, are Artificial Analysis Intelligence
Index snapshots as dated; index versions are not comparable with each
other. No qualitative ranking here (such as "strongest coder" or "fastest")
is sourced; choose levels by observed behavior on the task, not by labels.

## Options per model

Observed 2026-09; re-verify per machine. Native level names only; no
inferred numeric effort mapping is maintained here.

- Muse Spark 1.3 / 1.2 (Meta): minimal, low, medium, high, xhigh.
  Observed default high; xhigh observed used for coding. Do not configure
  "max": it is rejected on free/contributor tiers.
- MiMo-V2.6 Flash (Xiaomi): thinking on/off only, default on. No variant
  levels are exposed for the free endpoint
  (`opencode/mimo-v2.6-flash-free`), so there is nothing to configure.
  Observed locked sampling in thinking mode: temperature 1.0 / top_p 0.95;
  never set those; re-verify rather than assuming these values.
- GLM 5.2 (Z.ai): high and xhigh observed on the free endpoint. Vendor
  docs say "max" but no max level was observed here; do not configure it.
- Qwen 3.8 27B: none/low/medium/xhigh observed natively. Observed
  thinking-mode sampling: temperature 1.0, top_p 0.95, top_k 20;
  re-verify rather than assuming these values.
- Ling 3.0 Flash Fin: thinking on/off only, default on. Observed
  sampling: temperature 0.6, top_p 0.95, top_k 20; re-verify rather than
  assuming these values.
- Inkling: none/minimal/low/medium/high/max observed natively. Observed
  2026-09: high or max used for coding; never below medium for important
  work; re-verify per machine rather than assuming these levels.
- Nemotron 3 Ultra: on/off/low-effort plus optional budget observed,
  default on.

## Hard constraints

- Never configure a rejected level to chase a headline benchmark figure;
  unreachable scores are not a configuration problem.
- Never override MiMo's locked sampling values.
- Inkling's free endpoint works only inside agent harnesses and logs
  prompts for training. Get explicit user consent before routing real
  work to it.
- Free endpoints may silently ignore effort settings server-side. If a
  variant change alters neither behavior nor response length, the server
  is locking the level; do not "fix" this in config.
- Observed 2026-09-25 (single run, may be transient): the OpenRouter GLM
  5.2 free endpoint refused an agent request with 404 "no endpoints that
  support tool use," and Qwen 3.8 27B free died mid-run with a bare
  provider 400 after ~85s. Treat free-endpoint flakiness as normal;
  retry once, then route around, never reconfigure.

## Tier mapping examples

Role-to-tier membership lives only in `.sw/workspace.md` (Model tiers). A
blank tier inherits the session model unless a local override selects one.
Map tiers with `sw tiers -Reasoning <id> -Standard <id> -Fast <id>`, or by
hand in the git-ignored `.opencode/opencode.jsonc`. An ID may carry an effort
variant (`-Reasoning opencode/<id>#high`); `sw tiers` writes it as given.

Free-model tier fit, by the observed behavior above — verify the exact ID
against `/models` before use; a name alone is not a working config:

- Reasoning: a high/xhigh-effort thinking model, e.g. GLM 5.2 at xhigh or
  Inkling at high/max — slower and more thorough, suited to
  architecture/review work.
- Standard: `opencode/mimo-v2.6-flash-free` (thinking on, no variant to
  configure) or Qwen 3.8 27B at xhigh for agentic implementation work.
- Fast: Ling 3.0 Flash Fin or Nemotron 3 Ultra with thinking/effort off, for
  low-latency exploration.

OpenAI GPT is the paid upgrade path for any tier once usage is available;
match its exact model ID against `/models` the same way — this skill
guarantees no ID as currently correct.

## Agentic-use caveats

- Observed 2026-09: Qwen at reduced effort does not always finish
  multi-turn agent tasks faster. Prefer xhigh for harness work despite
  slowness; reserve medium for single-shot questions. Re-verify; this is
  behavioral observation, not a measured guarantee.
- Select effort interactively with the composer effort dropdown (desktop
  shows it only for models that have variants; MiMo exposes none, so no
  dropdown appears there). Programmatically, use the `#variant` suffix:
  `provider/model#variant` (in `run --model`, or a session/agent/command
  model field). There is no `/variants` command in V2.
- Variant keybinds depend on the installed client and version: the CLI
  keybind reference (fetched 2026-09-25) defines `variant.cycle`
  (default `ctrl+t`) and an unbound `variant.list`. Desktop bindings may
  differ; verify against the installed client's keybind reference and
  version before asserting a shortcut exists. An unknown variant errors
  loudly at selection; a wrong model ID in config still fails silently,
  so match IDs character-for-character, including `-free` suffixes.
- Badge/label behavior is version-dependent and unverified here. Confirm
  the active variant from the session/model ref, not just any badge.
- A wrong model ID fails silently: variants attach to nothing and the
  options never appear, which looks identical to "no levels available."
  Match IDs character-for-character, including `-free` suffixes.
