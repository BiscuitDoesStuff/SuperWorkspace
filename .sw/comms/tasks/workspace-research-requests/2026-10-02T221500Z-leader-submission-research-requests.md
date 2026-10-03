# workspace-research-requests - submission - bounded research questions for AI-Research [2] - 2026-10-02T221500Z - Leader

- **Author / audience:** Workspace Project Leader (Claude Opus 5.5, Claude Code desktop); owner, who carries the prompt below to an AI-Research [2] session.
- **Approval:** owner in session, 2026-10-02: research requests are delivered as a Workspace record plus a prompt the owner pastes (no writes into AI-Research [2]). Approving and running a pass is decided in AI-Research [2] under its own protocol.
- **Status:** proposed.
- **Branch / base:** `main` at `0701522`. Uncommitted.

## Questions

| ID | Question | Decision it serves | Existing claims |
| --- | --- | --- | --- |
| R1 | Is scripted or headless Claude use (`claude -p`, the Claude Agent SDK, a launcher script starting Claude Code) on a Pro/Max subscription login allowed under Anthropic's current Consumer Terms and published guidance? Is interactive use started by a script treated differently? | Launcher `-Headless` for Claude roles ([submission](../workspace-harness-decision/2026-10-02T220000Z-leader-submission-launcher.md)) | C283, C324, C325, C326, C093 |
| R2 | Does Claude Code honour the model per launch path: `--model`, an agent's `model:` frontmatter with `--agent`, subagents launched through the Agent tool, and `-p`? What override or fallback reports exist, and how can the served model be confirmed from logs? | Launcher routing and the verification method for Claude roles | C222, C223 |
| R3 | On native Windows (no WSL2), which Claude Code controls actually block a denied write or command: permission deny rules, PreToolUse hooks, managed settings? Including for subagents and plugin-carried agents. | S4 Claude Code enforcement parity | C224, C230, C231, C258 |
| R4 | How does OpenCode compact long sessions, and which instruction files does it re-inject afterwards (AGENTS.md, agent prompts, config `instructions`)? | S5 continuity: where must-survive constraints live | C251, C253 |
| R5 | According to OpenCode's documentation and issues, what does `opencode run` (headless) do when a tool call hits an `ask` permission: reject, wait or approve? Does `--auto` change it? | Launcher headless OpenCode sessions; runtime-check design | none recorded |
| R6 | How can OpenAI models be used per user in OpenCode (and, if needed, Codex CLI): API key, or a ChatGPT-plan sign-in? What do OpenAI's terms allow for scripted or headless use on a ChatGPT plan, and does model routing per agent hold? | Launcher routing for OpenAI tiers; per-user configuration | C131, C309 |

Bounds: primary sources first (vendor docs, terms, repositories, issues). Record a date for every captured source; this is not legal advice. Desk research only: no installs, no runtime tests, no paid services. Results return as claims in AI-Research [2]'s register, which Workspace reads.

## Prompt for an AI-Research [2] session

```text
Workspace requests a bounded research pass (proposal; approve under the AI-Research research protocol before running).
Source: C:\DevProjects\Workspace\.sw\comms\tasks\workspace-research-requests\2026-10-02T221500Z-leader-submission-research-requests.md
Questions R1-R6 in that file: Claude subscription use from scripts (R1), Claude Code model routing per launch path (R2), Claude Code enforcement on native Windows (R3), OpenCode compaction and re-injection (R4), OpenCode headless ask handling (R5), OpenAI per-user access and terms (R6).
Read the state Startup, propose a pass scope and budget for owner approval, then run it under the protocol. Desk research only; no installs or runtime tests. Do not edit Workspace.
```
