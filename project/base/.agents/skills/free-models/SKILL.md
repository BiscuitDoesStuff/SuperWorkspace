---
name: free-models
description: Procedure for finding, verifying and mapping free models to tiers; each machine verifies against its own provider list.
---

# Free models

Use when choosing free models for OpenCode tiers; tiers are model-only. This is
procedure, not configuration: it holds no provider credentials, no config
blocks, and no model IDs, prices, endpoints or effort levels. Those change
within days; read them from the machine and the provider, never from memory
or an old note.

## Find and verify

1. List what this machine can use: `opencode models --verbose` (or `/models`
   in a session). Only IDs listed there are candidates.
2. Confirm each candidate is free today from the provider's own list, not by
   name: a zero prompt and completion price or a `:free` ID on OpenRouter; a
   `*-free` route on the OpenCode Zen pricing page. Routers are not models.
3. Read each candidate's data-use terms on the provider page. Some free
   endpoints log prompts or train on them; get explicit user consent before
   routing real work to one.
4. Tiers are model-only: pick a model ID, never an effort level or variant
   (`sw validate` rejects `effort`, `variant` and `#variant` in tier config).
5. Match IDs character-for-character, including `-free` suffixes.

## Hard constraints

- Never configure a rejected level to chase a headline benchmark figure;
  unreachable scores are not a configuration problem.
- Never override sampling values a model locks in thinking mode.
- Free endpoints may silently ignore effort settings server-side. If a
  variant change alters neither behavior nor response length, the server
  is locking the level; do not "fix" this in config.
- On quota, 429, rate or session limits: stop and checkpoint the task record;
  do not retry, spawn or route around (`.sw/workspace.md`, Approved-plan
  execution).
- On other free-endpoint failures (refused tool use, bare provider errors,
  mid-run failures): reconcile the exit, artifacts and unknown effects first.
  Retry or reroute only with new evidence and applicable approval, within the
  three-failed-attempts ceiling; never reconfigure to work around them.
- No qualitative ranking (such as "strongest coder" or "fastest") is
  sourced here; choose levels by observed behavior on the task, not labels.

## Tier mapping

Role-to-tier membership lives only in `.sw/workspace.md` (Model tiers). A
blank tier inherits the session model unless a local override selects one.
Map tiers with `sw tiers -Light <id> -Standard <id> -High <id>`, or by
hand in the git-ignored `.opencode/opencode.jsonc`. IDs are plain
`provider/model`; `sw tiers` rejects a `#variant` suffix. On `opencode run`,
pass the tier model with `-m` (`.sw/workspace.md` Model tiers).

Fit by behavior verified above, never by name alone:

- Light: a fast model, used for execution and exploration.
- Standard: a model that finishes multi-turn agent tasks reliably, for
  implementation work.
- High: the most thorough model available; slower, suited to architecture
  and review work.

A paid model is the upgrade path for any tier once usage is available; match
its exact ID against `/models` the same way.

## Variants

- Variants are an interactive, per-session choice only; tier config never
  carries them. Select effort interactively with the composer effort dropdown (desktop
  shows it only for models that have variants). Programmatically, use the
  `#variant` suffix: `provider/model#variant` (in `run --model` for a
  one-off session; not in agent, command or tier config). There is no `/variants` command in V2.
- Variant keybinds depend on the installed client and version: the CLI
  keybind reference (fetched 2026-09-25) defines `variant.cycle`
  (default `ctrl+t`) and an unbound `variant.list`. Desktop bindings may
  differ; verify against the installed client's keybind reference and
  version before asserting a shortcut exists.
- An unknown variant errors loudly at selection. A wrong model ID in config
  fails silently: variants attach to nothing and the options never appear,
  which looks identical to "no levels available."
- Badge/label behavior is version-dependent and unverified here. Confirm
  the active variant from the session/model ref, not just any badge.
