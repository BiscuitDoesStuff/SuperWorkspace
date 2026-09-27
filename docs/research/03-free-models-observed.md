# Free models: observed per-model facts

Source: moved from the shipped `free-models` skill
(`product/project/base/.opencode/skills/free-models/SKILL.md`) on
2026-09-27, Phase 1 package 2 (03 R3, 06 R5 option A). Dated evidence, not a
research topic; not shipped. Every line is a single-machine snapshot unless
it cites a finding. Re-verify before use; do not copy these back into a
shipped skill.

## Corrections (2026-09-27)

- **GLM 5.2 (Z.ai) is not free.** On 2026-09-27 no `z-ai/glm*` ID ended in
  `:free` on OpenRouter, and OpenCode Zen lists GLM 5.2 at $1.40/$4.40 per
  million tokens (03-F13, from F9 and F12). The skill listed it as a free
  endpoint and as a Reasoning-tier fit; both lines below are stale.
- **Muse Spark 1.3 Contributor Free is contradictory and trains on
  prompts.** Zen's pricing table marks it "Free", but its Privacy section
  calls it "Heavily discounted token pricing"; treat it as possibly
  metered. Its terms grant "permission to use your prompts and completions
  to train future Meta models" (03-F12, Zen docs "last updated"
  2026-09-26).
- **Nemotron free endpoints are trial use only.** Zen: Nemotron 3 Ultra Free
  and Nemotron 3.5 Lightning Free are "Trial use only — do not submit
  personal or confidential data", and logged (03-F12).

## Options per model (observed 2026-09)

Native level names only; no inferred numeric effort mapping.

- Muse Spark 1.3 / 1.2 (Meta): minimal, low, medium, high, xhigh.
  Observed default high; xhigh observed used for coding. "max" is rejected
  on free/contributor tiers.
- MiMo-V2.6 Flash (Xiaomi): thinking on/off only, default on. No variant
  levels exposed for the free endpoint (`opencode/mimo-v2.6-flash-free`), so
  there is nothing to configure and no effort dropdown appears. Observed
  locked sampling in thinking mode: temperature 1.0 / top_p 0.95; never set
  those.
- GLM 5.2 (Z.ai): high and xhigh observed on the (then) free endpoint.
  Vendor docs say "max" but no max level was observed. Not free as of
  2026-09-27 (see Corrections).
- Qwen 3.8 27B: none/low/medium/xhigh observed natively. Observed
  thinking-mode sampling: temperature 1.0, top_p 0.95, top_k 20.
- Ling 3.0 Flash Fin: thinking on/off only, default on. Observed sampling:
  temperature 0.6, top_p 0.95, top_k 20.
- Inkling: none/minimal/low/medium/high/max observed natively. Observed
  2026-09: high or max used for coding; never below medium for important
  work. Its free endpoint works only inside agent harnesses and logs
  prompts for training.
- Nemotron 3 Ultra: on/off/low-effort plus optional budget observed,
  default on. Trial use only (see Corrections).

## Flakiness (observed 2026-09-25, single run, may be transient)

- The OpenRouter GLM 5.2 free endpoint refused an agent request with 404
  "no endpoints that support tool use".
- Qwen 3.8 27B free died mid-run with a bare provider 400 after ~85s.

## Agentic use (observed 2026-09)

- Qwen at reduced effort does not always finish multi-turn agent tasks
  faster. xhigh was preferred for harness work despite slowness; medium for
  single-shot questions. Behavioral observation, not a measured guarantee.

## Tier fit as the skill listed it (observed 2026-09)

- Reasoning: GLM 5.2 at xhigh (now paid, see Corrections) or Inkling at
  high/max.
- Standard: `opencode/mimo-v2.6-flash-free` (thinking on, no variant) or
  Qwen 3.8 27B at xhigh.
- Fast: Ling 3.0 Flash Fin or Nemotron 3 Ultra with thinking/effort off.
- Paid upgrade path: OpenAI GPT, exact ID matched against `/models`.

## Benchmarks note (moved text)

Benchmark figures, where the skill mentioned them, were Artificial Analysis
Intelligence Index snapshots as dated; index versions are not comparable
with each other.
