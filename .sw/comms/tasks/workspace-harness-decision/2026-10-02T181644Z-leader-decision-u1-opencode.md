# workspace-harness-decision - decision - U1 harness: OpenCode (after follow-up checks) - 2026-10-02T181644Z - Leader

- **Author / audience:** Workspace Project Leader (Claude Opus 5.5, Claude Code desktop); owner, and the next Leader session.
- **Approval:** owner in session, 2026-10-02. After reading the [Kilo results](2026-10-02T172033Z-leader-handson-results-kilo.md), the owner chose "C then A":
  - **C:** run the optional OpenCode follow-ups (handoff item 5), small and free.
  - **A:** choose OpenCode and work around its routing gap.
  The owner said to wait on the generator refit submission. Also in session: the owner had Kilo's user-scope folders removed; they were moved to the Recycle Bin.
- **Status:** U1 harness decided: **OpenCode**. The follow-up checks are done. The workarounds below are proposals for the generator refit; they are not implemented.
- **Setup:** OpenCode `v2.0.20` (global npm install, unchanged). Disposable git project `scratch\ocproj`. `opencode run --standalone --format json`, with evidence from `opencode session export`. Models: Zen free `opencode/nemotron-3.5-lightning-free` and `opencode/mimo-v2.6-flash-free`. Spend: US$0. The OpenRouter calls were refused for the key limit before inference.

## Follow-up results (OpenCode)

| Check | Configured | Served (runtime record) | Runs | Result |
| --- | --- | --- | --- | --- |
| Top-level `model` set; `run --agent rt-primary`, no `-m` | agent frontmatter MiMo, top-level Nemotron | top-level Nemotron | 3 (F1-dbg, F1-agent2-3) | **does not fix it**: the top-level default replaces the unconfigured default, and the agent model is still ignored |
| Same, default agent (no `--agent`) | as above | Nemotron | 1 (F1-default1) | same |
| **Generator form:** local `.opencode/opencode.jsonc` `agents.rt-primary.model` (as `Set-SwTiers` writes it); no frontmatter or top-level model | MiMo (shown in `debug config`) | `openrouter/inclusionai/ling-3.1-flash`, refused (key limit) | 3 `--agent` + 1 default (F3) | **FAIL**: the config-level agent model is also ignored on the CLI path |
| Permission rule `subagent *nemotron*` deny; parent passes `model: nemotron` | subagent pinned MiMo | child served Nemotron; call allowed | 3 (F2-modeldeny1-3) | **cannot deny**: the rule does not see the `model` argument |
| Control: `subagent rt-free-b` deny | - | `permission.rejected` | 1 (F2-namedeny1) | the subagent rule's resource is the agent name |

Excluded: F1-agent-1 and F1-agent-1b produced no session within 300 s and 600 s. A later identical run with `--print-logs` waited about 60 s for the provider, then completed (F1-dbg).

Combined with the [OpenCode record](2026-10-02T061500Z-leader-handson-results-opencode.md):
- On the OpenCode `run` path, **only `-m` selects the primary model**.
- Subagents launched through the `subagent` tool do honour their pin, unless the parent passes `model`.
- No permission rule can stop that override.

## Decision

The U1 harness is **OpenCode** (owner, 2026-10-02). Kilo stays a documented alternative.

The reasons:
- On enforcement the two are equivalent.
- OpenCode runs Workspace's existing config and plugin natively.
- Kilo silently drops the current config.
- OpenCode's routing gap can be worked around in the launcher.

## Proposals for the generator refit (not approved; the refit waits on the owner)

1. **Launcher passes `-m`:** every scripted or documented `opencode run --agent X` also passes `-m <tier model of X>`. The local tier map alone does not route on the CLI path. Re-verify after each OpenCode upgrade.
2. **Keep the local `agents` map:** it still helps subagents (pins honoured through the tool) and the interactive TUI (not tested).
3. **Override rule in prompts:** add a role-prompt rule that parents do not pass `model` to the `subagent` tool. It cannot be enforced by permission (F2), so treat it as advisory, and spot-check session exports.
4. **Enforcement (S4):** pair each hard shell rule with `write`/`edit` rules at project level, and review `rtk.ts` as part of the enforcement boundary (C317).
5. The refit submission's open question about sequencing is settled: no Kilo emitter is needed.

## Validation of this record

Scratch evidence is in the session scratch folder: `ocruns/*` and `ocproj/`. It is not copied into Workspace. Workspace checks: see the Leader's reply.

## Next action

Owner: approve, edit or decline the [generator refit submission](2026-10-02T051533Z-leader-submission-generator-refit.md), including proposals 1-4 above and the open question about the Claude adapter.
