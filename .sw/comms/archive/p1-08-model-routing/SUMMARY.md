# p1-08-model-routing - summary

- **Outcome:** Package 8a done. Tiers light/standard/high with routing rules and rubric in .sw/workspace.md (a016301, b55784f). Runtime smoke 2026-09-28: opencode-cli 2.0.18 run --agent project-worker and project-review, no -m, both replied OK from openai/gpt-6-astra after the owner's local .opencode/opencode.jsonc gained a top-level model (openai/gpt-6-astra#low); without it, auto compaction fell back to an OpenRouter default. Variants resolve per /api/agent (worker low, review high); session exports do not record the variant, so effort is not runtime-observed. Follow-ups, not authorized: sw tiers -Force drops a hand-added top-level model (consider writing one); sw doctor accepts a placeholder tier map; Claude adapter Opus-at-every-tier neutrality (owner decision).
- **Closed:** 2026-09-28 04:33:35Z by biscuitdoesstuff at b55784f22bfaa16d0ac0865db5376d4eccb37f33
- **Events:** 3, kept in `events/` for evidence; read this summary instead.

- 2026-09-28T010532Z-leader-assignment.md
- 2026-09-28T011341Z-leader-submission.md
- 2026-09-28T031351Z-leader-progress.md
