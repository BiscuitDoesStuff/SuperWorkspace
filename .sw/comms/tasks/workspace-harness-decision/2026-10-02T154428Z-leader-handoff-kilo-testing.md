# workspace-harness-decision - handoff - continue hands-on check with Kilo - 2026-10-02T154428Z - Leader

- **Author / audience:** Workspace Project Leader (Claude Opus 5.5, Claude Code desktop); the next Leader session and the owner.
- **Approval:**
  - The hands-on check ([scope](2026-10-02T051533Z-leader-submission-handson-check.md)) was approved and run in session on 2026-10-02.
  - The owner then said: "we will install kilo via npm next". That approves the npm route in principle. Confirm the exact package, version, size and install location with the owner before running the install.
  - Spend cap: about US$2. Use free models.
- **Status:** OpenCode half done ([results](2026-10-02T061500Z-leader-handson-results-opencode.md)). Kilo half not started.
- **Branch / base:** `main` at `ddd155c`. Uncommitted: `docs/workspace-outline.md`, `docs/workspace-state.md`, and this task folder. No commit or push unless the owner asks.

## Goal (unchanged)

Runtime evidence for U1 (OpenCode vs Kilo) on the two properties research could not settle:

1. **Model routing:** does each launch path use the configured per-agent model? The model-only tier rubric depends on it.
2. **Windows enforcement:** do deny rules and hooks actually block? S4 depends on it.

Licences are already confirmed: both MIT. The main question for Kilo is whether it shares OpenCode's gaps, since it is built on OpenCode server (C303), or fixes any of them.

## OpenCode results to compare against

| Check | OpenCode 2.0.20 |
| --- | --- |
| CLI agent path without explicit model | FAIL: agent model ignored; unconfigured `openrouter/unbiased/pareto-26.10-preview` served, 5 of 5 |
| Explicit model flag | pass |
| Subagent via tool, pinned model | pass, 3 of 3 (non-Claude); Claude pin routed to Anthropic, 3 of 3 |
| Subagent with no model | inherits the parent, 3 of 3 |
| Parent passes `model` when launching a subagent | FAIL: overrides the pin, 3 of 3 (cf. Kilo C304) |
| Shell deny rule (project and agent level) | blocks the shell call, 9 of 9 |
| Denied effect via other tools | achieved via `write`, 6 of 6, until `write`/`edit` rules were added; `execute` has no fs or child_process but has network `fetch` |
| Shell hook that throws, crashes, or is slow (90 s) | blocks; fails closed; no timeout-open (the session stalls) |
| Plugin rewrite before the permission check (C317) | defeats the deny rule; the session record shows the original command as completed |

## Environment facts

- **Scratch evidence from the OpenCode run is gone.** It lived in that session's scratch folder. Rebuild the fixtures below in the new session's scratch folder, never inside Workspace.
- **Credentials:**
  - The OpenCode Anthropic key has no credit.
  - The OpenRouter key has hit its total limit.
  - OpenCode Zen free models worked: `opencode/nemotron-3.5-lightning-free` and `opencode/mimo-v2.6-flash-free`. `opencode/ling-3.0-flash-fin-free` endpoint was unavailable.
  - Kilo's credentials and free models are unknown. Kilo may need its own sign-in, which the **owner** performs; the agent never enters keys. A Claude credential is wanted only to show routing (request IDs are enough).
- **Kilo package:** npm `@kilocode/cli` 7.8.3 (MIT, repo `Kilo-Org/kilocode`). It is a 26 KB wrapper with a `postinstall` script (`node ./postinstall.mjs`). It pulls the optional dependency `@kilocode/cli-windows-x64` (about 242 MB unpacked). The bins are `kilo` and `kilocode`. winget has no package.
- **Install:** local to scratch only, no global install or PATH change. For example: `npm install --prefix <scratch>\kilo @kilocode/cli@7.8.3`, then run `<scratch>\kilo\node_modules\.bin\kilo`. Read `postinstall.mjs` before running the install, and report anything it does beyond fetching or placing the binary.
- **Discover, don't assume:** Kilo's config file name and directory, agent format (Markdown agents with sticky per-agent models, per C303), permission syntax, CLI run flags, session export, and plugin or hook mechanism. Use `--help`, its debug commands and the Kilo repo. If Kilo has no hook mechanism, record that as a finding.
- **Windows gotchas from the last run:**
  - On Windows, `opencode` is a script shim, so `Start-Process` failed.
  - `pwsh -File` mangled array arguments (it dropped `-m`, which invalidated 3 runs).
  - Use an in-process helper function and call the CLI directly.
  - A `Remove-Item` whose path is built from a variable can trip a path guard; use literal paths.
  - Some free-model runs take minutes. Give long probes a wall-clock limit and record a stopped run as not run.

## OpenCode fixtures (port to Kilo's equivalent format)

Project config (OpenCode V2 syntax; last match wins):

```json
{ "default_agent": "rt-primary",
  "permissions": [
    { "action": "shell", "resource": "*", "effect": "allow" },
    { "action": "subagent", "resource": "*", "effect": "allow" },
    { "action": "shell", "resource": "*DENYPROBE*", "effect": "deny" },
    { "action": "write", "resource": "*probe*", "effect": "deny" },
    { "action": "edit", "resource": "*probe*", "effect": "deny" },
    { "action": "shell", "resource": "*REWRITEPROBE*", "effect": "deny" } ] }
```

Note: the `write`/`edit` rules were added only after the first deny runs. Run the first deny round without them, to see whether the effect is reachable through other tools, then add them.

Agents:

| Agent | Mode | Model | Extra |
| --- | --- | --- | --- |
| `rt-primary` | primary | free model A | agent rule: shell `*AGENTPROBE*` deny |
| `rt-free-b` | subagent | free model B | agent rule: shell `*SUBPROBE*` deny (**configured but never run in OpenCode**) |
| `rt-claude` | subagent | a Claude model | none |
| `rt-inherit` | subagent | none | none |

The subagent body is "Reply with exactly one short sentence."

Probe plugin (OpenCode V2 API, `.opencode/plugins/hookprobe.ts`). It writes to a log file outside the project, and its `shell.create.before` hook does the following:
- **REWRITEPROBE:** sets `e.command = "echo rewritten > rwout.txt"`.
- **HOOKPROBE:** throws.
- **HOOKCRASH:** calls a method on `null`.
- **HOOKSLOW:** waits 90 s, then throws.

The API is `export default { id, async setup(ctx) { await ctx.shell.hook("create.before", async (e) => { ... }) } }`, as in Workspace `.opencode/plugins/rtk.ts`.

Evidence per call:
- The harness's session export: the provider and model on each assistant message, and the state of each tool part.
- Provider error bodies and request IDs.
- A sentinel file created by the command, which is the side effect.
- The probe plugin's log.

## Test matrix for Kilo (3 runs per row unless noted)

1. Licence: already done (MIT, LICENSE blob `c5762eb`). Record the installed version.
2. Plugin control: list every plugin, extension, MCP and config source Kilo loads, at user and project scope. Stop if any is unreviewed. Check whether Kilo also reads OpenCode's global config or plugins.
3. Routing:
   - CLI agent path without explicit model (the OpenCode FAIL case);
   - explicit model flag;
   - subagent via tool, pinned non-Claude;
   - subagent pinned Claude;
   - subagent with no model;
   - mention path, if it differs;
   - parent passes a model at launch (C304 says yes; confirm at runtime);
   - Kilo "sticky" model behavior across a continued session (`-c`/`--session` equivalent).
4. Enforcement:
   - allowed control (1 run);
   - project-level shell deny;
   - agent-level shell deny;
   - subagent-level shell deny (`SUBPROBE`);
   - effect via other tools (first without, then with `write`/`edit` rules);
   - code-execution tool, if any: filesystem, process and network reach;
   - hook throw, crash and slow, if a hook mechanism exists;
   - plugin rewrite before the permission check (1 run).
5. Optional OpenCode follow-ups, if cheap:
   - can a permission rule deny the `subagent` tool's `model` argument?
   - does setting a top-level default `model` fix the CLI agent path?
   - interactive TUI path.

## Done when

A results record `…-leader-handson-results-kilo.md` sits in this folder, with the same tables as the OpenCode record. A short comparison (OpenCode vs Kilo, per row) goes to the owner for the U1 decision. `pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --check` pass. The state Startup is updated. Nothing is committed unless asked.

## Prompt for the next session

```text
Continue the U1 hands-on check with Kilo, per the handoff:
.sw/comms/tasks/workspace-harness-decision/2026-10-02T154428Z-leader-handoff-kilo-testing.md

1. Read the Workspace state Startup and the handoff. Confirm base ddd155c plus the uncommitted harness-decision changes.
2. Install Kilo via npm into this session's scratch folder only (@kilocode/cli 7.8.3, ~242 MB Windows binary, postinstall script). Read postinstall.mjs first, show me the exact command, and wait for my go-ahead. No global install.
3. If Kilo needs provider sign-in, tell me what to run; I enter credentials myself. Prefer free models; cap ~US$2.
4. Rebuild the fixtures from the handoff in Kilo's own format in scratch (discover the format; don't assume OpenCode's). Run the Kilo test matrix: plugin control, routing per launch path, Windows deny/hook tests. Use runtime evidence only: session records, provider responses, sentinel files.
5. Write the Kilo results record next to the OpenCode one and give me a side-by-side OpenCode vs Kilo comparison for the U1 decision. Update the state Startup.
6. Run `pwsh -NoProfile -File .sw/sw.ps1 validate` and `git diff --check`. Do not commit.
```
