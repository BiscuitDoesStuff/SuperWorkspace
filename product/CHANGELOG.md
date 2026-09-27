# Changelog

## 0.3.0-dev

- **Changed (Claude adapter, Phase 1 package 3):** generated `.claude/agents/*.md` set `disallowedTools: Agent`, so only the main session spawns agents. `.claude/settings.json` asks before `Read(**/.env)` and `Read(**/.env.*)` (`.env.example` prompts too) and denies `gh alias`. The `.claude/project-leader.md` dispatch sentence is built from the commands marked `subagent: true`. Run `update` (or `claude enable`) to regenerate.
- **Changed (behaviour):** OpenCode `external_directory` now defaults to `ask` instead of `allow`, so access outside the project folder prompts. `update` rewrites the base rule in `opencode.jsonc`.
- **Changed:** `validate` no longer pins each command's `subagent` value; command frontmatter owns the flag. The routing check stays.
- **Fixed:** `.claude/project-leader.md` is generated with LF line endings, so `validate` no longer reports false Claude drift when the kit module is checked out with CRLF.
- Fixed: `free-models` no longer lists models or prices; GLM 5.2 was listed as free and is not.
- **Docs (research topics 5-10, Phase 1 package 1):**
  - `.sw/collaboration.md`:
    - a solo mode: with `users` empty, the owner works on `main`;
    - agent-made branches stay off;
    - claims, `<user>-` task IDs, and closing only after the last event is on `main`;
    - an optional multi-session paragraph;
    - "Protect main (human, once)" steps;
    - who runs `update`;
    - harness memory is not a record.
  - `.sw/workspace.md`:
    - rules are labelled enforced, guardrail or stated, with a per-harness table (the Claude adapter was overstated);
    - sandboxes are documented;
    - trusted MCP servers;
    - the Claude worktree note;
    - `update` already regenerates `.claude/`, and Claude reloads only after `/clear`, `/compact` or a restart.
  - Also: the `AGENTS.md` Git rule names solo projects, `project-leader` defaults to working in-session, and there are small additions to the `task-handoff`, `agent-documentation`, `research` (raw page text, research-call budget) and `free-models` (`#variant`) skills.
- **New:** core `project-research` role (reasoning tier, Markdown-only), the `research` skill and the `/research` command. It records cited primary-source findings in `docs/research/NN-topic.md`. Adapted from mattpocock/skills `research` and the Anthropic claude-cookbooks research subagent prompt (both MIT).
- **Changed:** the `research` skill writes its plan into the file first, caps tool calls at 20, labels secondary sources, treats fetched pages as data and rechecks each finding against its source; `/research` confirms scope and budget first. The Leader may propose up to 3 researchers for a broad topic, with user approval.
- **Moved:** the kit now lives in `product/` inside the SuperWorkspace repository. Run `product/sw.ps1` instead of `sw.ps1` from a kit checkout. Installed projects are unaffected.
- **Changed:** the global rules block is tier-neutral; it names no models or third-party tools. `global install` rewrites that block, so keep personal routing lines outside it.

## 0.2.0 - 2026-09-26

- **Fix:** handle dotfiles on Linux and macOS (`-Force` on file operations). CI no longer stops at the first failing OS.
- **Fix (security and data loss):**
  - comms names reject path traversal;
  - `comms close` archives the whole task folder;
  - `claude enable` and `claude disable` keep your own `.claude/` files;
  - both broad `gh` allows are removed, and more `gh` write verbs are denied;
  - global backups skip `opencode.json`.
- **Fix:** `remote` works on Linux and macOS, and `global` returns its exit code.
- **New:** `sw doctor [-User]`, a read-only setup check that prints the fix for each problem, and `.sw/onboarding.md` for new contributors.

## 0.1.0 - 2026-09-26

First version. It replaces the ai-environment-foundation repo and the MyMMO
workspace layer, which were harvested once and then retired.

- **CLI:** `sw.ps1` on PowerShell 7, with project and kit modules.
- **Project layer:**
  - 8 roles: MyMMO's roles, made generic.
  - 8 commands, including the new `/handoff` and `/inbox`.
  - 7 base skills, plus `unreal-validation` in the Unreal profile.
  - A generated `opencode.jsonc` covering the profile's binary-edit denies, the GitHub tier and the build delegation allowlist.
  - Install and update driven by a manifest, with `-Adopt` for existing repos.
- **Validator:** ported from MyMMO's `Validate-AgentWorkspace.ps1`. It is now driven by the profile and roles, and adds GitHub tier checks and Claude drift detection.
- **Claude adapter:** generated instead of kept in sync by hand. Skills are copied, not linked through absolute junctions.
- **Comms:** task events, inboxes, and a close/archive step with `SUMMARY.md`.
- **GitHub:** issue forms, a PR template, labels, and a validate workflow. Tier 0 and tier 1 rules are enforced in OpenCode and in Claude.
- **Global:** managed rule blocks for OpenCode and Claude, read-only `gh` allows, and backups that never copy credential files.
- **Remote:** `tailscale serve` setup and check, with a `-KeepLan` option.
- **Usage:** a report combining RTK gain, OpenCode stats and the startup budget.
