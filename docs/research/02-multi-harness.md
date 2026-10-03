# 02: Multi-harness compatibility from a single source

Status: complete; reviewed by the owner 2026-09-27; R1-R4 and R6 adopted, R5 revised, option b and R3 deferred to the roadmap rewrite.
Researched 2026-09-26 by `project-research` (research-2, Claude Opus 5.5 via
Claude Code). All sources accessed 2026-09-26; page dates are given where
the page showed one. Every finding is **summary-based**: it rests on the
fetch tool's model summary of the page, not on saved raw text, because the
25-call cap left no room to re-fetch. Findings that rest on the summary
reporting an *absence* are also marked **weak**.

## 1. Question and scope

Which harness features can one canonical source serve across the major AI
coding harnesses, and what is the smallest per-harness output SuperWorkspace
must generate?

Harnesses: OpenCode, Claude Code, OpenAI Codex CLI, Gemini CLI, Cursor,
GitHub Copilot (VS Code agent mode).

Sub-questions:
1. Comparison table: instructions, user-global instructions, skills,
   subagents (model field), commands, MCP location, hooks (presence).
2. Convergence on AGENTS.md, Agent Skills and MCP; shared locations.
3. Generate vs share, per feature; rulesync and ruler as precedents.
4. Overlay reach for `~/.config/superworkspace/rules.local.md` (topic 1 R1).
5. Recommendation mapped onto `Get-SwClaudeFiles` / `Invoke-SwClaude`.

Out of scope (one line each):
- Permission and tool-restriction syntax (topic 8): every harness has its
  own (`permission`, `tools`, `readonly`, `sandbox_mode`); none is shared.
- Model choice and tier mapping (topic 3): only whether a per-agent `model`
  field exists is recorded. All six have one, with different value formats.
- Install and update (topic 7): any new adapter reuses the Claude adapter's
  generated-marker, git-ignore and backup model.

Not covered:
- Codex custom prompts and slash commands. The fetched Codex pages do not
  describe them.
- Cursor commands. The fetched pages only say commands can migrate to skills.
- Hooks formats. Presence only, from links on fetched pages; hook pages
  were not fetched.
- Codex and Cursor user-global import syntax, and whether Copilot follows
  links inside instruction files. Not stated in the fetched pages.
- The agents.md and agentskills.io adopter lists. Adoption is taken from
  each harness's own docs instead, which is the stronger source.
- Other harnesses: Windsurf, Cline, Roo/Kilo/Zoo Code, Aider, Goose, Kiro,
  Continue, Amp, GitHub Copilot CLI and cloud agent, JetBrains AI.

## 2. Findings

Topic 1 findings are cited as `01-F<n>`.

### Per-harness surfaces (sub-question 1)

F1. **Codex CLI loads `AGENTS.md` natively.** Global
`~/.codex/AGENTS.override.md`, else `~/.codex/AGENTS.md`; then each level
from the Git root to the working directory (`AGENTS.override.md`, then
`AGENTS.md`, then `project_doc_fallback_filenames`). Files concatenate
root-down; closer files override. The combined limit is
`project_doc_max_bytes`, default 32 KiB. No import syntax is described.
<https://learn.chatgpt.com/docs/agent-configuration/agents-md> (redirected
from developers.openai.com), accessed 2026-09-26, no page date.

F2. **Codex custom agents are TOML files with a `model` field.** They live
in `.codex/agents/` or `~/.codex/agents/`; `name`, `description` and
`developer_instructions` are required; `model` and `model_reasoning_effort`
are optional. MCP servers are `[mcp_servers.<name>]` in `config.toml`.
<https://learn.chatgpt.com/codex/agent-configuration/subagents>, accessed
2026-09-26, no page date.

F3. **Codex reads skills only from `.agents/skills`.** Current directory,
parents up to the repo root, `~/.agents/skills`, `/etc/codex/skills`, and
bundled skills. Same-name skills are both listed, not merged. Symlinked
skill folders are followed. Leader re-verified 2026-09-27.
<https://learn.chatgpt.com/codex/skills>, accessed 2026-09-26, no page date.

F4. **Gemini CLI reads `GEMINI.md` by default and `AGENTS.md` by setting.**
Global `~/.gemini/GEMINI.md`, then project and parent directories, then
just-in-time files. `settings.json` `context.fileName` can be
`["AGENTS.md", ...]`. `@file.md` imports accept relative and absolute
paths. <https://geminicli.com/docs/cli/gemini-md/>, updated 2026-06-18.

F5. **Gemini CLI reads skills from `.agents/skills` and `.gemini/skills`.**
User `~/.gemini/skills/` or `~/.agents/skills/`; workspace `.gemini/skills/`
or `.agents/skills/`. Within a tier "the `.agents/skills/` alias takes
precedence". <https://geminicli.com/docs/cli/skills/>, updated 2026-04-30.

F6. **Gemini CLI subagents are Markdown with a `model` field.**
`.gemini/agents/*.md` and `~/.gemini/agents/*.md`, YAML frontmatter (`name`,
`description`, `kind`, `tools`, `model`, `temperature`, `max_turns`,
optional per-agent `mcpServers`), body is the system prompt.
<https://geminicli.com/docs/core/subagents/>, updated 2026-06-08.

F7. **Gemini CLI commands are TOML.** `~/.gemini/commands/` and
`.gemini/commands/`; required `prompt`, optional `description`; `{{args}}`
placeholder; subdirectories namespace as `/dir:name`.
<https://geminicli.com/docs/cli/custom-commands/>, updated 2026-04-30.

F8. **Gemini CLI MCP servers live in `settings.json` `mcpServers`.** User
`~/.gemini/settings.json` or project `.gemini/settings.json`.
<https://geminicli.com/docs/tools/mcp-server/>, updated 2026-09-02.
The Gemini instructions page also links a Hooks page (presence only).

F9. **Cursor reads `AGENTS.md` natively; user rules are settings only.**
Project rules are `.cursor/rules/*.mdc` with frontmatter; plain `.md` there
is ignored except `AGENTS.md`; nested `AGENTS.md` is supported. User Rules
are defined in Customize → Rules, not in a file.
<https://cursor.com/docs/context/rules>, accessed 2026-09-26, no page date.

F10. **Cursor reads skills from `.agents`, `.cursor`, `.claude` and `.codex`.**
Project `.agents/skills/`, `.cursor/skills/`; user `~/.agents/skills/`,
`~/.cursor/skills/`; "legacy compatibility" `.claude/skills/`,
`.codex/skills/` and their home equivalents. The page mentions
`.cursor/mcp.json`, hooks, and commands migrating to skills.
<https://cursor.com/docs/context/skills>, accessed 2026-09-26, no page date.

F11. **Cursor reads subagents from `.cursor`, `.claude` and `.codex`.**
`.cursor/agents/`, `.claude/agents/`, `.codex/agents/` and home
equivalents; `.cursor/` wins on name conflicts. Frontmatter `name`,
`description`, `model` (default `inherit`, or a Cursor model ID),
`readonly`, `is_background`. Leader re-verified 2026-09-27.
<https://cursor.com/docs/context/subagents>, accessed 2026-09-26, no page
date. It does not say how Cursor parses Codex TOML agents.

F12. **Copilot in VS Code reads `AGENTS.md` and `CLAUDE.md` by setting.**
`.github/copilot-instructions.md`, `*.instructions.md` (`applyTo`),
`AGENTS.md` (`chat.useAgentsMdFile`, nested via
`chat.useNestedAgentsMdFiles`), `CLAUDE.md` (`chat.useClaudeMdFile`). User
instructions: `~/.copilot/instructions`, `~/.claude/rules`, or the VS Code
profile. A `chat.includeReferencedInstructions` setting exists; what it
follows is not stated in the summary.
<https://code.visualstudio.com/docs/copilot/customization/custom-instructions>,
updated 2026-09-16.

F13. **Copilot reads skills from `.github`, `.claude` and `.agents`.**
Project `.github/skills/`, `.claude/skills/`, `.agents/skills/`; personal
`~/.copilot/skills/`, `~/.claude/skills/`, `~/.agents/skills/`.
`chat.agentSkillsLocations` is deprecated.
<https://code.visualstudio.com/docs/agent-customization/agent-skills>,
updated 2026-09-16.

F14. **Copilot custom agents read `.claude/agents` too.** `.agent.md` files
in `.github/agents`, `.claude/agents` ("Claude format"), `~/.copilot/agents`
or `~/.claude/agents`. `model` takes one name or a prioritised array.
<https://code.visualstudio.com/docs/agent-customization/custom-agents>,
updated 2026-09-16.

F15. **Copilot prompt files are being replaced by skills.** `.github/prompts/
*.prompt.md` or the user profile, with `agent`, `model`, `tools`
frontmatter. "Prompt files are deprecated for Agent Host sessions";
migrate to skills.
<https://code.visualstudio.com/docs/agent-customization/prompt-files>,
updated 2026-09-16.

F16. **Copilot reads the portable `.mcp.json`.** `.vscode/mcp.json`
(`servers`), project-root `.mcp.json` (`mcpServers`), or a user-profile
`mcp.json`. The custom-instructions page links a Hooks page (presence
only). <https://code.visualstudio.com/docs/agent-customization/mcp-servers>,
updated 2026-09-16.

F17. **Claude Code reads skills from `.claude/skills` only.** Personal,
project, nested, plugin and enterprise locations are all `.claude/skills`
shaped. "Custom commands have been merged into skills": `.claude/commands/x.md`
and `.claude/skills/x/SKILL.md` both create `/x`. Leader re-verified
2026-09-27: the page lists only `.claude/skills` shapes and plugin
`skills/`, and does not mention `.agents/skills`. <https://code.claude.com/docs/en/skills>, accessed
2026-09-26, no page date.

F18. **Claude Code subagents: `.claude/agents` with a `model` field; MCP in
`.mcp.json`.** `model` accepts `sonnet`, `opus`, `haiku`, `fable`, a full ID
or `inherit`; subagents may carry `hooks` and `mcpServers`. Project MCP is
`.mcp.json`. **Weak** on the negative: `.agents/` is said not to be read.
<https://code.claude.com/docs/en/sub-agents>, accessed 2026-09-26, no page
date.

F19. **OpenCode agents are `.opencode/agents/*.md` with `model:
provider/model-id`.** Also `~/.config/opencode/agents/`; `mode` is
`primary`, `subagent` or `all`. The page lists no other agent directories.
<https://opencode.ai/docs/agents/>, "last updated" 2026-09-26 (see 01's
caveat). Commands live in `.opencode/commands/` (01-F4); skills in 01-F7;
hooks are code plugins (01-F5).

F20. **OpenCode MCP is the `mcp` key in `opencode.json`.** Types `local`
and `remote`. The page mentions no `.mcp.json`.
<https://opencode.ai/docs/mcp-servers/>, "last updated" 2026-09-26.

### Comparison table

| Harness | Project instructions | User-global | Skills (Agent Skills) | Subagents; `model` field | Commands | MCP | Hooks |
|---|---|---|---|---|---|---|---|
| OpenCode | `AGENTS.md`; `CLAUDE.md` fallback (01-F9) | `~/.config/opencode/AGENTS.md`, `instructions` (01-F9) | `.opencode`, `.claude`, `.agents` `/skills` (01-F7) | `.opencode/agents/*.md`; yes (F19) | `.opencode/commands/` (01-F4) | `opencode.json` `mcp` (F20) | code plugins (01-F5) |
| Claude Code | `CLAUDE.md`; `AGENTS.md` too (01-F1) | `~/.claude/CLAUDE.md` + `@` import (01-F8) | `.claude/skills` only (F17) | `.claude/agents/*.md`; yes (F18) | merged into skills (F17) | `.mcp.json` (F18) | yes (F18) |
| Codex CLI | `AGENTS.md` native (F1) | `~/.codex/AGENTS.md` (F1) | `.agents/skills` only (F3) | `.codex/agents/*.toml`; yes (F2) | not documented | `config.toml` `[mcp_servers]` (F2) | yes, linked (F1) |
| Gemini CLI | `GEMINI.md`; `AGENTS.md` by setting (F4) | `~/.gemini/GEMINI.md` + `@` import (F4) | `.gemini`, `.agents` `/skills` (F5) | `.gemini/agents/*.md`; yes (F6) | `.gemini/commands/*.toml` (F7) | `settings.json` `mcpServers` (F8) | yes, linked (F8) |
| Cursor | `.cursor/rules/*.mdc`; `AGENTS.md` native (F9) | settings only (F9) | `.agents`, `.cursor`, `.claude`, `.codex` (F10) | `.cursor`, `.claude`, `.codex` `/agents`; yes (F11) | not documented; migrating to skills (F10) | `.cursor/mcp.json` (F10) | yes (F10) |
| Copilot (VS Code) | `copilot-instructions.md`; `AGENTS.md`, `CLAUDE.md` by setting (F12) | `~/.copilot/instructions`, `~/.claude/rules` (F12) | `.github`, `.claude`, `.agents` (F13) | `.github/agents/*.agent.md`, `.claude/agents`; yes (F14) | `.github/prompts/*.prompt.md`, deprecated for Agent Host (F15) | `.vscode/mcp.json` or `.mcp.json` (F16) | yes, linked (F16) |

### Convergence (sub-question 2)

F21. **AGENTS.md is read by all six**, natively by OpenCode, Codex and
Cursor, alongside `CLAUDE.md` by Claude (01-F1), and behind a setting in
Gemini (`context.fileName`, F4) and Copilot (`chat.useAgentsMdFile`, F12).
Sources F1, F4, F9, F12, 01-F1, 01-F9; dates as cited.

F22. **Agent Skills is implemented by all six, but no path is shared by
all six.** `.agents/skills` is read by OpenCode, Codex, Gemini, Cursor and
Copilot (5 of 6), not Claude (F17). `.claude/skills` is read by
OpenCode, Claude, Cursor and Copilot (4 of 6), not Codex or Gemini. The
kit's current `.opencode/skills` is read by OpenCode only. Sources F3, F5,
F10, F13, F17, 01-F7.

F23. **Commands are converging into skills.** Claude merged commands into
skills (F17), Copilot deprecates prompt files for skills (F15), Cursor
migrates commands to skills (F10). Gemini keeps TOML commands (F7).

F24. **Subagents are converging on Markdown plus frontmatter, with
`.claude/agents` as the de facto shared path.** Cursor and Copilot read
`.claude/agents` (F11, F14). Codex is TOML (F2); OpenCode and Gemini read
only their own directory (F6, F19). `model` values are not portable:
aliases (Claude), `provider/id` (OpenCode), vendor IDs elsewhere.

F25. **MCP is universal but each harness has its own file.** Only Claude
and Copilot share `.mcp.json` (F16, F18). OpenCode, Codex and Gemini embed
MCP in their main config (F20, F2, F8).

### Precedents (sub-question 3), secondary sources

F26. **rulesync generates everything from `.rulesync/`.** Sources are
`rules/`, `commands/`, `subagents/`, `skills/`, `mcp/`; 50+ targets; the
README shows per-feature coverage falling from rules (~95%) to hooks and
permissions (~50%). <https://github.com/dyoshikawa/rulesync>, accessed
2026-09-26; no release date on the page. Secondary.

F27. **ruler shares one `AGENTS.md` and copies the rest.** `.ruler/`
holds `AGENTS.md`, `ruler.toml`, optional `mcp.json`, `skills/`, `agents/`.
It writes one `AGENTS.md` that several agents read, and "Skills are copied
directly to each agent's native skills directory" (for example
`.claude/skills/` and `.agents/skills/`).
<https://github.com/intellectronica/ruler>, accessed 2026-09-26; no
release date on the page. Secondary.

Both precedents land where the table does: share `AGENTS.md`, generate or
copy everything else. Neither is a candidate to install.

### Overlay reach (sub-question 4)

F28. **Only three harnesses can import a user file by reference.** Claude:
`@~/...` from `~/.claude/CLAUDE.md` (01-F8). Gemini: `@` imports with
absolute paths from `~/.gemini/GEMINI.md` (F4); `~` is not confirmed.
OpenCode: `instructions` in global `opencode.json` (01-F9), `~` still
untested (01 open question 3). Codex documents no import (F1), Cursor has
no user-rules file (F9), and Copilot's user instructions are a folder
(F12) with link-following unconfirmed.

## 3. Options compared

### Where the canonical skills live

| Option | Read without a copy by | Copy still needed for | Cost |
|---|---|---|---|
| a. Keep `.opencode/skills` (today) | OpenCode | Claude, and every future adapter | none now; one copy per harness |
| b. Move canonical to `.agents/skills` | OpenCode, Codex, Gemini, Cursor, Copilot (F22) | Claude only | one move; a decisions.md change; OpenCode then sees `.agents` and the `.claude` copy (duplicate names, see Open questions) |
| c. Move canonical to `.claude/skills` (committed) | OpenCode, Claude, Cursor, Copilot | Codex, Gemini | ties the core to one vendor's directory; `.claude/` is git-ignored today |

### Per-feature: share or generate

| Feature | Share one file? | Why |
|---|---|---|
| Project instructions | share `AGENTS.md` | all six read it (F21); Gemini and Copilot need one setting |
| Skills | share `.agents/skills` for 5 of 6 | Claude needs a copy (F22) |
| Commands | generate, or fold into skills | Gemini needs TOML (F7); others converge on skills (F23) |
| Subagents | generate | three formats and incompatible `model` values (F24) |
| MCP | generate | four locations and two keys (F25); the kit ships no MCP today |
| User-global overlay | one import line per harness where supported | three can import (F28) |

## 4. Recommendation

R1. **Keep `AGENTS.md` as the one shared instruction file.** It already
reaches all six (F21). Generate no per-harness instruction copies; for
Gemini and Copilot the adapter writes only the setting that turns
`AGENTS.md` on (`.gemini/settings.json` `context.fileName`, or document
`chat.useAgentsMdFile`).

R2. **The Claude skills copy cannot go.** Claude reads `.claude/skills`
only (F17), so `Get-SwClaudeFiles` must keep generating it. What *can*
change is the canonical location: option b (`.agents/skills`) makes the
copy Claude-specific and gives Codex, Gemini, Cursor and Copilot skills for
free. That reverses part of `docs/decisions.md` 2026-09-26 ("OpenCode is
canonical"), so it is an owner decision, not a research one. Until then,
keep option a.

R3. **Stop generating Claude commands when they can become skills.**
Claude treats commands and skills alike (F17), and Copilot and Cursor are
moving the same way (F23). The four `/commands` could ship as user-invocable
skills and drop the `.claude/commands` generator. This is a follow-up for
the owner; it changes the OpenCode side too.

R4. **Minimum files for the next adapters** (all generated, git-ignored,
using the existing marker and backup model):
- Codex: `.codex/agents/<role>.toml` (`name`, `description`,
  `developer_instructions` pointing at `.opencode/agents/<role>.md`, and
  `model` from the tier map) plus skills in `.agents/skills` (a copy under
  option a, nothing under option b). No instruction file: `AGENTS.md` is
  native (F1).
- Gemini: `.gemini/settings.json` with `context.fileName: ["AGENTS.md"]`,
  `.gemini/agents/<role>.md`, `.gemini/commands/<name>.toml`, plus skills as
  for Codex.
- Cursor and Copilot: no adapter. They read `AGENTS.md`, `.claude/agents`
  and `.claude/skills` (F10, F11, F13, F14), so a user who runs
  `sw claude enable` already has roles and skills there. The Claude `model`
  aliases (`opus`) may not resolve in Cursor or Copilot; they should ignore
  or fall back, but that is untested.

R5. **Add Codex next.** Universality is a project goal (`docs/roadmap.md`
standing rule "the goal is every major AI app"), so new adapters are
planned scope for the roadmap rewrite, not speculative. Codex is first
because it needs the fewest files: one generated directory
(`.codex/agents/`), `AGENTS.md` is native, and it shares the
`.agents/skills` convergence path. Gemini needs three generated locations,
and Cursor and Copilot need none (R4).

R6. **Overlay: extend topic 1 R1 only where imports exist.** Gemini gets
`@<absolute path>/rules.local.md` after the block in `~/.gemini/GEMINI.md`
(F4). Codex, Cursor and Copilot cannot import (F28): skip them, or have
`global install` copy `rules.local.md` into the Codex block, which topic 1
option D rejected. Recommend skip and document.

Interactions (one line each):
- Topic 3: tier-to-model mapping becomes per-harness output once a second
  adapter exists (F24).
- Topic 7: `update` and `claude enable` would regenerate each adapter the
  same way; option b moves files every installed project receives.
- Topic 8: permissions stay per-harness generated output; nothing shared.

## 5. Open questions

Owner answers recorded 2026-09-27 (relayed by the Leader).

1. Owner: does anyone (you or a collaborator) use Codex, Gemini, Cursor or
   Copilot today? If no, R5 stays deferred and only R2's decision is live.
   **Answer:** none today; universality is the goal (R5 as revised).
2. Owner: move canonical skills from `.opencode/skills` to `.agents/skills`
   (option b)? It changes a recorded decision.
   **Answer:** deferred to the roadmap rewrite, to decide together with
   topic 7 and after the Q3 runtime test.
3. Runtime test: OpenCode reads `.opencode/skills` and the generated
   `.claude/skills` copy today (01-F7). Does it show duplicate skills, and
   which wins? The same applies to option b.
   **Answer:** runtime test, deferred to implementation.
4. Runtime test: do Cursor and Copilot accept Claude `model: opus` in
   `.claude/agents`, ignore it, or fail?
   **Answer:** runtime test, deferred to implementation.
5. Owner: fold the four commands into user-invocable skills (R3)?
   **Answer:** deferred to the roadmap rewrite (touches topic 5).
6. Budget report: 25 research calls (24 fetches plus one Codex redirect),
   exactly at the cap; no searches. Six harnesses by six features did not
   fit about 12 calls; I narrowed by skipping hooks pages, Codex prompts and
   Cursor commands. No re-fetch budget remained, so all findings are
   summary-based. Suggestion for topic 3 onward: save raw page text (for
   example `curl` into the scratchpad) so re-verification does not spend
   research calls.
   **Answer:** adopted as a research-skill input for the roadmap.
7. Fetched pages contained no text directed at the agent.

## 6. Supersedes / updates

None superseded. Extends `01-structure-and-extension.md` R4 (skills shape)
and its topic-2 interaction line; answers the adapter question in
`docs/roadmap.md` topic 2. R2 and R3, if adopted, would update
`docs/decisions.md` 2026-09-26 "OpenCode is canonical"; this file proposes
no edit to it.
