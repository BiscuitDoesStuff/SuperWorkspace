# Changelog

## 0.3.0-dev

- **Changed (model routing, Phase 1 package 8, breaking):** tiers renamed
  `reasoning/standard/fast` -> `high/standard/light` everywhere, no aliases
  or old names. Default role tiers: `project-plan`, `project-architect`,
  `project-research`, `project-review` = standard; `project-developer`,
  `project-worker`, `project-build`, `project-documentation`, `explore` =
  light; `project-leader` stays session. `sw tiers` flags are renamed to
  `-Light -Standard -High`; re-run it with the new flags (an existing
  `.opencode/opencode.jsonc` tier map keeps working, since it maps roles to
  models directly). The Claude adapter now gives every generated agent
  `model: opus` plus `effort: low|medium|xhigh` (light/standard/high)
  instead of picking a model per tier; `validate` checks both lines.
  `.sw/workspace.md` gains a Planning/Execution routing section and rubric
  (no model IDs); `free-models`' tier-mapping names are renamed to match.
- **Changed (skills, Phase 1 package 6):** canonical skills moved from `.opencode/skills` to `.agents/skills` (base and the `unreal` profile), because OpenCode, Codex, Gemini, Cursor and Copilot all read `.agents/skills`, while `.opencode/skills` is OpenCode-only.
  - The rename map (`$script:Moved`, `Sw.Kit.psm1`) gained prefix support: one `.opencode/skills/` -> `.agents/skills/` rule, expanded per file against the project's manifest. `update` moves an edited kit skill to `.agents/skills/<name>` with its edit, the same as any other renamed file.
  - A user's own skill under `.opencode/skills/<name>` (not a kit skill name) is left alone; OpenCode still reads it there, but `claude enable` and `validate` now read only `.agents/skills`. Move your own skills to `.agents/skills/<name>` and delete their stale `.claude/skills/<name>` copies.
  - `validate` now reads skills from `.agents/skills`, and reports a new error when a kit skill name still exists under `.opencode/skills/<name>`, since it shadows the kit's `.agents/skills` copy in OpenCode.
  - The generated `.claude/skills` copy is now built from `.agents/skills`. Claude users: re-run `sw claude enable` if `update` does not regenerate your `.claude/` (no `.claude/.sw-generated` marker).
- **Changed (OpenCode permissions, Phase 1 package 5a):** OpenCode desktop 2.0.17/2.0.18 ignores the project-level `permissions` list in `opencode.jsonc` and applies only agent frontmatter.
  - `update` writes the session rules (shell allow, `external_directory` ask, skill allow, subagent deny, commit ask, push/reset/clean/stash/`gh` deny, the profile's edit denies, the GitHub tier allows, then the `.env` read asks) at the head of every `.opencode/agents/*.md` `permissions` list, and of `agents.build`. The role's own rules follow and still win. `opencode.jsonc` keeps the same list. The rules now live in `Get-SwSessionRules`; `opencode.base.json` no longer holds a `permissions` list.
  - A `githubTier` change needs `update`, which now rewrites the agents too. A locally edited agent follows the usual `skip-modified` / `incoming/` path.
  - `validate` models each role from its agent file only (`build` from `agents.build`), and reports `Session rule drift: .opencode/agents/<role>.md ...; run sw update` when an agent's leading rules differ from the session rules for the project's config.
  - Read-only roles (`project-plan`, `project-architect`, `project-review`) may run `git status *`, `git diff *`, `git log *` and `git show *`, plus `git log --oneline` and `git log --oneline -??`. `--output`, `--ext-diff` and `--textconv` stay denied; `validate` checks both.
  - `.sw/workspace.md`: the harness table states OpenCode enforcement through agent frontmatter, OpenCode `.env` prompts as unverified, and Claude `.env` prompts as a guardrail (Read tool only). Built-in OpenCode agents other than Build carry no kit rules. `.sw/workspace.md` and `.sw/collaboration.md` no longer call branch protection the real push control: the solo ruleset stops force pushes and deletion, not ordinary pushes.
- **Fixed (OpenCode permissions, Phase 1 package 5a): RTK bypass.** OpenCode 2.0.18 runs plugin shell hooks before its permission check, so the RTK plugin's rewrite (`git push ...` to `rtk git push ...`) slipped past the push, commit, stash and `gh` rules. `update` now renders an `rtk ` twin, with the same effect, directly after every shell rule except `*`: in every `.opencode/agents/*.md` list (session and role rules), `opencode.jsonc` `permissions` and `agents.build`. `validate` checks every shell case for its `rtk` form too, compares agents against the twinned session rules, and reports `RTK twin missing: ...; run sw update` for a shell rule without its twin. `.sw/workspace.md` records the rewrite order, and OpenCode `.env` prompts read "enforced (ask)".
- **Changed (update, Phase 1 package 5): lifecycle.**
  - `.sw/manifest.json` gains `kitCommit`, the kit clone's `git rev-parse HEAD` (`null` outside a git clone, or when the kit was copied into another repository).
  - `update` and `init` refuse to run when the manifest's `kitVersion` is newer than the running kit (a `-dev` build is older than its release), and write nothing. Update the kit clone, or pass `-Force` to downgrade on purpose. `update` also accepts `-Adopt`.
  - The plan starts with `kit A -> B`.
  - A locally edited file the kit did not change is reported `kept-local`, with no merge hint.
  - A locally edited file the kit did change stays `skip-modified`. The kit's new version is written to `.sw/backup/<stamp>/incoming/<path>` (git-ignored; credential-like names are never copied), and one `git diff --no-index <path> <incoming>` line is printed per file.
  - `orphan-kept` files are listed as dropped from the kit and left in place.
  - An `AGENTS.md` without a `## Project identity` heading gets the template's project sections inserted above the kit blocks, and the plan says "fill Project identity". Existing text is untouched. This fixes package 4's new `validate` error.
  - A kit-side rename map (empty today) moves files the kit renames. An edited old file moves with its edit and is reported like any edited file.
- **Changed (validate, Phase 1 package 4): three new errors.** Fix these before or right after `update`:
  - `AGENTS.md` must keep a `## Project identity` heading. A project that adopted an existing `AGENTS.md` may lack it; add the heading above the kit blocks.
  - Every skill `name` must be 1-64 lowercase letters, digits and single inner hyphens, and its `description` at most 1024 characters (Agent Skills spec). Rename or shorten your own skills that break this.
  - When `.claude/.sw-generated` exists, `.claude/` must match `.sw/roles.json`: one agent per role except `project-leader` and `explore`, with the tier's `model`, the role's `claudeTools` as `tools`, and `disallowedTools: Agent`, plus one command per `.opencode/commands/*.md`. Run `claude enable` to fix.
- **New (validate):** a research lint for `docs/research/*.md` (sections 1-6, a dated header, a citation per `F<n>.` finding). It prints `WARNING:` lines and never changes the exit code.
- **Changed (validate):** the budget line reads `~N tokens (bytes/4 estimate; tokenizer varies)`, and `project-leader`'s count adds the other agents' `description` bytes (the subagent catalogue it sees). `.sw/workspace.md` describes the same.
- **Changed (doctor):** two notes: the startup budget counts kit files only (check `/context` in Claude for the real total), and branch protection on `main` is not checked (see `.sw/collaboration.md`, Protect main).
- **Changed (comms):** an event's "changed" line drops `.sw/comms/` entries and lists at most 10 paths, then `(+N more)`.
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
