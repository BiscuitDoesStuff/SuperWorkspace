# 14: Sharing skills, MCP and plugins across Claude Code and Codex

Status: complete as research (recommendation, not approved); 2026-10-16 by
the main T3 Code thread. Six read-only Claude research workers
did the surveys. Two independent Codex review rounds (instruction-only
read-only) found no P0 issues; all findings were accepted. Execution details,
model choices and the machine inventory are local evidence (not published).

Owner request: before defaulting to "find another manager tool", check whether
better options exist and whether earlier assumptions were wrong. Separately,
assess what ECC and similar public projects offer.

Sources were accessed 2026-10-16 unless dated otherwise. Raw text, or labelled
tool extractions, are saved outside the repository with SHA-256 indexes, and
were re-checked for the findings the recommendation uses. "Extraction" means a
web-fetch tool's model-processed text of a docs page, not the raw page.

## 1. Question and scope

How should one owner manage shared skills, MCP servers and plugins for both
Claude Code and Codex from one place, under this rule?

- No update, removal, conversion or restore may overwrite or delete an
  installed copy that was edited locally or cannot be shown unedited.
- There is no `--force` bypass.
- A restore may proceed only if it first saves what it replaces, recoverably.

Normal editing happens at a central source. The management experience
(discover, inventory, install, enable, update, roll back) is part of the goal,
per an acceptance contract A1-A11 (local evidence, not published).

Sub-questions:
1. Native support in both tools: skill locations, links, plugins, enablement,
   MCP and instructions.
2. Public tools that manage these across both, and how they treat edited
   copies (from code where possible).
3. Which earlier assumptions were weak.
4. What ECC (`affaan-m/ECC`) and similar collections offer for selective reuse.

Local tests used one Claude Code and one Codex CLI version on Windows (exact
versions: local evidence, not published). Codex source was read at
`openai/codex@6ae8b8aa7c60` (main), not a release tag.

Out of scope: installing tools; Claude runtime discovery tests; provider routing proxies;
provider or model choice. Not covered: Claude MCP docs, Skillshare changes
after v0.25.12, SuperClaude, claude-plugins.dev, and an in-depth read of
claude-code-templates and wshobson/agents.

## 2. Findings

### Native capabilities

F1. **Codex reads shared user and repository skill folders.**
- User scope is `$HOME/.agents/skills`.
- Repository scope is `.agents/skills` in each folder from the working
  directory up to the project root.
- `$CODEX_HOME/skills` is "Deprecated ... kept for backward compatibility".

Sources: `codex-rs/ext/skills/src/host_roots.rs` lines 24, 64-68, 96-105 and
137-155 at <https://github.com/openai/codex/tree/6ae8b8aa7c60>; docs at
<https://learn.chatgpt.com/docs/build-skills> (extraction).

F2. **Claude Code lists only its own skill locations.** These are enterprise,
`~/.claude/skills`, project `.claude/skills`, nested `.claude/skills`,
`--add-dir`, and plugins. The page cites the Agent Skills open standard but
lists no `.agents/skills` location. That absence comes from an extraction, so
it is **weak**. <https://code.claude.com/docs/en/skills>.

F3. **Both tools follow symlinked skill folders; a junction works for Codex
repository scope here.**
- **Claude (documented):** "a `<skill-name>` entry in the enterprise,
  personal, or project location can be a symlink to a directory elsewhere on
  disk ... loads the skill once even if several locations point at the same
  target" (F2 page, extraction).
- **Codex (code):** user, repo and admin scopes use
  `DirectorySymlinkPolicy::Follow` (`codex-rs/ext/skills/src/loader/host.rs`
  lines 164-166, same commit).
- **Local test 1:** a no-model `skills/list` call to the Codex CLI, with
  CODEX_HOME isolated, listed a repository-scope skill reached through a
  directory junction. It reported the skill at the junction target's path.
- **Not isolated:** Codex resolved the user scope from the real profile
  despite `HOME`/`USERPROFILE` overrides (read only, nothing changed), so the
  user-scope junction case is untested.
- **Local test 3 (Claude, owner-approved):** in one T3 Claude thread in a
  scratch project, a project skill reached through a directory junction loaded
  on explicit invocation (`/junction-probe`). The reply was the token that
  exists only in the target's `SKILL.md`, with no tool calls. The junction was
  then removed and the target was unchanged. Limits: project scope only; user
  scope and implicit invocation were not tested. In local test 2, Node also
  reports a junction as `isSymbolicLink() == true`.

Evidence for both local tests: local evidence (not published).

F4. **Removing a junction leaves its target intact with the usual tools
(local test 2).** Each test created a junction to a sacrificial folder and then
removed it:
- Node `fs.rmSync` and `fs.promises.rm` with `recursive:true, force:true`,
  PowerShell 7 `Remove-Item -Recurse -Force`, `rmdir` and Git Bash
  `rm -rf` each removed only the link. The target's file survived.
- Python `shutil.rmtree` refused ("Cannot call rmtree on a symbolic
  link").

Limit: one Windows machine's runtime versions (local evidence, not
published), not every tool's removal path.

F5. **Native plugins are installed into caches. Protection for edits made
inside those caches is unverified, not unnecessary.**
- **Claude:** copies a marketplace plugin to
  `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` and loads that
  copy. A new copy arrives when the version changes. Auto-update is off by
  default for third-party marketplaces. A marketplace added from a local
  folder with relative-path sources is read "directly from that directory
  instead of copying".
- **Codex:** copies to `~/.codex/plugins/cache/$MARKETPLACE/$PLUGIN/$VERSION/`.
  Its docs leave edits to the cache unspecified. They say a marketplace
  refresh can replace files even when the plugin is disabled.

Sources (extractions):
<https://code.claude.com/docs/en/plugin-marketplaces>,
<https://code.claude.com/docs/en/plugins/host-marketplace>,
<https://learn.chatgpt.com/docs/plugins>,
<https://developers.openai.com/plugins/build/plugins>.

F6. **One repository can carry both plugin formats, with two manifests.**
- **Claude:** `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json`.
- **Codex:** `.agents/plugins/marketplace.json` and a root `plugin.json`
  (`.codex-plugin/plugin.json` is legacy).
- **Claude marketplace in Codex:** the Codex docs say the desktop app also
  reads `.claude-plugin/marketplace.json`. Whether the CLI does is
  **unverified**.
- **Components:** Codex plugins carry skills, MCP (`mcp.json`), apps and hooks
  (hooks only for manually installed desktop plugins, behind a trust gate).
  Claude plugins carry skills, agents, commands, hooks, MCP and LSP.

Sources (extractions): Same pages as F5, mainly
<https://code.claude.com/docs/en/plugin-marketplaces> and
<https://developers.openai.com/plugins/build/plugins>.

F7. **Enabled state can be declared in files on both sides.**
- **Claude:** `enabledPlugins` and `extraKnownMarketplaces` in user, project,
  local or managed settings. A project-level `true` does not fetch externally
  sourced plugins onto a machine.
- **Codex:** `[plugins."name@marketplace"] enabled` in `config.toml`. A
  trusted project's file overrides the user file. Individual skills can be
  disabled with `[[skills.config]]`.
- Whether Codex installs a plugin that is only declared in a project file is
  **unverified**.

Sources: F5 and F1 pages (extractions).

F8. **There is no shared MCP file.** Claude uses `.mcp.json` or settings;
Codex uses `[mcp_servers]` in `config.toml`. Codex can import once, one way,
from Claude configuration: MCP, hooks, subagents, home-scope plugins and
`AGENTS.md`, plus a copy of `.claude/skills` into `.agents/skills` that skips
existing targets. Source: `codex-rs/external-agent-migration/src/service.rs`
and `mcp.rs` at <https://github.com/openai/codex/tree/6ae8b8aa7c60>. Claude's MCP docs were not fetched (**gap**).

F9. **Claude reads `AGENTS.md` from v2.1.277, but not alongside `CLAUDE.md`
by default.** It reads `AGENTS.md` only when no `CLAUDE.md` or
`CLAUDE.local.md` exists in or above the folder, unless
`claude-md-and-agents-md` is set. <https://code.claude.com/docs/en/memory>
(extraction).

F10. **T3 Code is not a capability manager.** Its settings cover per-project
overrides and provider switches. `apps/server/src/mcp/` is T3's own MCP server.
Its repository keeps skills in `.agents/skills`, with `.claude/skills` as a
symlink. <https://github.com/pingdotgg/t3code/tree/a9c9c7cd> (README,
`docs/user/project-settings.md`, tree scan only: **partial**).

F11. **The shared user folder may already be in use (Local).** A user may
already have skills synced from a Claude account in `$HOME/.agents/skills`,
and Codex lists them. Any route must leave content it did not deliver alone.
Source: a folder listing, 2026-10-16 (local evidence, not published).

### Tools

F12. **No surveyed manager meets the rule in its normal mode.** Code read
unless marked:

- **vercel-labs/skills v1.7.2** (`671e8c32`):
  - Copy and default symlink modes copy into a canonical folder after
    `rm -rf`.
  - `createSymlink` recursively removes a real directory in its way.
  - Link creation can silently fall back to copying.
  - `remove` deletes with recursive `rm` and checks no baseline.
  - A `link` mode exists, creating Windows junctions (`installer.ts` lines 38,
    290-293, 393-398), but no reachable CLI path selects it.
- **getsentry/dotagents 3.3.0** (`207de848`):
  - Copies into `~/.agents/skills`.
  - Links the whole `~/.claude/skills` with a symlink that has no type
    argument, so it likely needs Developer Mode.
  - Prune, sync and remove use recursive `rm` with no content hash.
  - MCP merge overwrites a server with the same name and re-serialises Codex
    TOML, dropping comments.
  - A `.dotagents-managed` marker gates plugin removal.
- **rulesync v36.0.2:** unconditional writes and an orphan sweep;
  `generate --check` only reports drift.
- **ruler v0.3.44:** re-copies managed skills with no hash check; skips
  unmanaged name collisions.
- **CC Switch v4.0.13:** update ignores a failed backup
  (`let _ = Self::create_uninstall_backup(..)`), then runs `remove_dir_all`
  (`src-tauri/src/services/skill.rs` about lines 1618-1622). It keeps at most
  20 backups.
- **openskills v1.5.0:** prompts only in interactive mode.
- **Microsoft APM v0.33.0:**
  - Protects unmanaged files unless `--force`.
  - On removal, skips files that were edited (`skipped_user_edit`).
  - Updates a managed skill with `rmtree` then `copytree`.
- **Skillshare v0.25.12:** copy sync overwrote an edited copy (earlier pilot,
  **Local**).

Repositories as named, at the versions given.

F13. **Generators fit only outputs nobody edits.** rulesync and ruler
generate native files from one source. They are useful models for instruction
and MCP fragments, but meet the rule only with an added "check the hash, then
refuse" step (F12).

### Workspace today (Local)

F14. **The project generator copies, and rejects links.** `lib/Sw.Kit.psm1`
(near line 140) writes physical Claude skill copies from `.agents/skills`.
`lib/Sw.Project.psm1` (near line 65) rejects participating links and
junctions. The generator already keeps local edits when the source is
unchanged, skips when both sides changed, and blocks deselecting edited
skills. It writes Claude permission settings but no plugin declarations or
global MCP. A link-based route therefore needs new adapters, not a setting.

### Second pass: routes without copies or links

These findings came from two more read-only workers, after the owner's
answers. The owner said a GUI is not required, but a management page in a
provider routing proxy would be welcome later.

F17. **Profiles multiply Claude targets but not Codex skill targets
(Local).** T3 provider instances can run Claude with separate
`CLAUDE_CONFIG_DIR` profiles. Each profile has its own user skills folder,
plugins and settings, and they can differ. Codex reads user skills from
`$HOME/.agents/skills` regardless of `CODEX_HOME` (F1), so one folder serves
every Codex home. Account-synced skills (F11) can appear both in a Claude
profile and in `$HOME/.agents/skills`, whether or not the user uses them.
Source: T3 provider settings and folder listings, 2026-10-16 (local evidence,
not published).

F18. **No persistent native settings key for an extra skills folder was
found in either tool.** A launch argument remains possible (F20, S9).
- **Codex:** `skills/extraRoots/set` keeps its list in memory for one
  app-server process and replaces it wholesale. No `config.toml` key was found
  (`ext/skills/src/host_service.rs` lines 86 and 154-162 at
  <https://github.com/openai/codex/tree/6ae8b8aa7c60>; code-search evidence,
  not exhaustive).
- **T3:** shows no call site for it (generated bindings only).
- **Claude:** docs list only `--add-dir`, which loads that folder's
  `.claude/skills`. `permissions.additionalDirectories` grants file access only
  (<https://code.claude.com/docs/en/skills>, extraction).

F19. **Codex plugin caches are per profile and are replaced without a drift
check.**
- **Location:** the cache is `$CODEX_HOME/plugins/cache/<marketplace>/<plugin>/<version>`.
- **Writes:** `plugin add`, a source version change, or a forced reinstall
  stage a copy and swap it in, dropping the old copy (`store.rs` lines 576-684
  and 693-725). A changed source path also forces a reinstall
  (`manager.rs` lines 3221-3237).
- **Remove:** `plugin remove` runs `remove_dir_all` (`store.rs` lines 538-552).
- **Version "local":** a plugin with no version gets "local", which skips the
  ordinary same-version refresh (`store.rs` 431-437, `installed.rs` 60-65). It
  is not immutable: a changed source path forces a reinstall, and a later
  source version replaces it.
- **Background writes:** listing plugins schedules a background refresh
  (`manager.rs` lines 1808-1833), which installs changed versions without a
  drift check (`loader.rs` lines 697-713). A check run only before `plugin add`
  or `remove` therefore cannot enforce the rule.
- **Shared marketplace:** the personal marketplace file is
  `$HOME/.agents/plugins/marketplace.json`, shared by all Codex profiles
  (`marketplace.rs` lines 21 and 307-315).

All at <https://github.com/openai/codex/tree/6ae8b8aa7c60>, under
`codex-rs/core-plugins` and `core-plugin-common`.

F20. **Claude can load plugins in place, two ways, inside T3.**
- **Local marketplace:** Claude reads plugins from a local-folder marketplace
  with relative-path sources in place ("reads the plugin's files directly";
  edits apply at the next session or `/reload-plugins`). Hosted marketplaces
  are cached instead (<https://code.claude.com/docs/en/plugin-marketplaces>,
  extraction).
- **T3 launch:** T3 starts Claude through the Agent SDK `query()` without
  restricting `settingSources`, so profile settings load. Each Claude instance
  has a `launchArgs` field passed as extra CLI arguments
  (`ClaudeAdapterV2.ts` lines 1079-1083 and 1163; `settings.ts` lines 637-647
  at <https://github.com/pingdotgg/t3code/tree/a9c9c7cdb15e>). That could
  carry one `--plugin-dir` (repeated flags are last-wins).
- **Unverified:** declaring a local marketplace only through
  `extraKnownMarketplaces` in `settings.json`; the exact schema was not
  retrieved.
- **Naming:** plugin skills are namespaced `/plugin:skill`. A bare `/name`
  also works when the frontmatter sets `name` and nothing else uses it.

F21. **Skills over MCP lose native behaviour.** gotalab/skillport (`51334ae`,
"work in progress") serves one skills folder through `search_skills` and
`load_skill` tools. There is no `/name` or `$name` invocation and no native
implicit trigger; it adds tool calls, needs registration per profile, and
needs `uvx`. <https://github.com/gotalab/skillport/tree/51334ae> (README).

F22. **A routing-proxy management page is possible as a front end.** The
plugin system of the provider routing proxy examined can add management pages
and authenticated routes, but has no skill or plugin distributor. Source:
local evidence, 2026-10-15 (not published).

### ECC and similar collections

F15. **ECC is a large multi-harness content system, not a neutral manager.**
Repository <https://github.com/affaan-m/ECC>, MIT licence, read at
`76aaa77df6adc5b889e689007bf99b9a4f74af34` (2026-10-15).

- **Size:** about 6,355 files covering skills, agents, legacy commands,
  rules, hooks, MCP catalogues, memory and "instincts" systems, dashboards,
  and adapters for about 20 harnesses.
- **Plugin manifests:**
  - It ships `.claude-plugin/{plugin,marketplace}.json` and
    `.codex-plugin/plugin.json` from one root.
  - The two declare different components. The Claude manifest has
    `"mcpServers": {}` and no hooks key. The Codex manifest points at
    `./.mcp.json` and `./hooks/codex-hooks.json`.
  - So it is a dual-manifest layout example, not proof of equal behaviour.
- **Installer:**
  - It keeps a per-file ledger with `contentSha256`.
  - It skips existing files it did not install ("Skipped user-owned file",
    `scripts/lib/install/ownership-guard.js`, issue #2964).
  - It refuses if a file appears between planning and writing.
  - It keeps an edited Codex user config.
  - Uninstall keeps changed copies (`preserveDriftedCopies: true`).
- **Weaknesses:** repair and reinstall still overwrite other edited managed
  files, and there is no backup or restore.
- **Hooks:** 27 entries, mostly broad matchers, each an inline `node -e`
  resolver. The scripts were not read, so telemetry and network use are
  **unverified**.
- **Activity:** release v2.2.3 on 2026-10-01; 94 of the last 100 commits
  landed on 2026-10-11, mostly from one account, so expect high churn. About
  280k stars is weak evidence of quality.

F16. **Other capability sources (README level).** Sources:
<https://github.com/obra/superpowers>, <https://github.com/openai/skills>,
<https://github.com/anthropics/claude-plugins-official>,
<https://github.com/agentskills/agentskills>, accessed 2026-10-16.
- `obra/superpowers` v7.0.0 installs per harness from the official Claude and
  Codex marketplaces.
- `openai/skills` is marked deprecated in favour of `openai/plugins`.
- `anthropics/claude-plugins-official` (Apache-2.0) is active.
- The Agent Skills format is just a `SKILL.md` folder (`agentskills/agentskills`,
  Apache-2.0).
- `davila7/claude-code-templates` and `wshobson/agents` are active
  collections; not read in depth.

## 3. Assumptions re-examined

| Earlier assumption | Status now | Effect |
| --- | --- | --- |
| The goal needs one existing manager app | Weak. The owner asked for one management point, not a specific product. A GUI was never required, but a git folder alone is not a management experience either (A1-A11) | Compare routes against A1-A11, not against "has a GUI" |
| Installed skills must be copies | Refuted. Both tools follow per-skill symlinks; Codex follows a junction (F3) | A link-based route is technically possible |
| Links make the rule hold automatically | Too strong. Removing links leaves targets intact here (F4), but the tools surveyed delete real folders in a link's path and fall back to copying (F12) | Any link route must refuse collisions, never fall back to copying, and verify each link's target |
| Native plugin caches need no protection | Unverified. Refresh can replace cache files (F5) | Treat plugin update and removal as covered by the rule until tested |
| Git gives safe rollback | Only for committed content | Check for a dirty tree before automated source updates; save unrecorded content before restore |
| Few candidates existed | Narrow. The earlier selection used a few READMEs | Section 2 widens it. No tool meets the rule as shipped (F12) |
| After a rejected patch, the next step is another tool | Unsupported | Workspace's guarded copies and a link-based route are both real options (section 4) |
| Claude reads a single shared user skills folder | Refuted for this setup: each Claude profile has its own (F17), while Codex has one | A Claude-side route must cover every profile it should serve |
| A persistent "extra skills folder" setting would avoid links | No native settings key found in either tool (F18) | Remaining routes are links, plugins, copies, or a Claude launch argument (S9) |
| Native plugins are safe because their caches are managed | Refuted for Codex: add, remove, version changes and background refresh replace the cache without a check (F19) | Defer Codex plugins until every automatic write path is controlled |
| Ownership markers protect generated config | Too weak: they stop edits to entries the generator does not own, but `Set-SwBlock` (`lib/Sw.Kit.psm1` line 49) replaces an owned block without checking a baseline (Local) | Shared MCP and hooks need content baselines, as new work |

## 4. Options weighed

Two delivery problems are weighed separately: plain skills, and packaged
capabilities (MCP servers, hooks, plugins).

Criteria, in priority order:
1. The rule: edited or unverifiable installed content is never lost.
2. One maintained source, edited in one place.
3. Native behaviour: `/name` and `$name` invocation, implicit triggering,
   resources.
4. Covers every configured profile: each Claude profile and each Codex home (F17).
5. Works inside T3 without changes to T3.
6. New code and upkeep for the owner.
7. Evidence level: tested, code-read, or docs only.

### Skills

| Route | 1 Rule | 2 Source | 3 Native | 4 Profiles | 5 T3 | 6 Cost | 7 Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S1 Copy-mode manager (Skillshare, CC Switch, `skills`, APM, dotagents) | Fails (F12) | Copies drift | Yes | Partial | Yes | Low to adopt, but needs upstream changes, which the owner declined | Code |
| S2 Third-party link installer (`skills` link mode, dotagents) | Fails: deletes real folders in its path, copies when linking fails (F12) | Yes | Yes | Partial | Yes | Low | Code |
| S3 Own per-skill junction adapter: one git source, junctions in `~/.agents/skills` and each Claude profile's `skills` | Meets, if it refuses collisions, never falls back to copying, checks each link's target and only unlinks; removing a junction keeps its target (F4) | Yes, edits land in the source | Yes | Yes: one Codex folder plus one folder per Claude profile | Yes, no T3 change | Small new adapter in the generator, which today rejects links (F14) | Codex tested (repo scope); Claude docs, junctions inferred |
| S4 Workspace generator copies, extended to profile folders | Meets: keeps local edits, skips when both sides changed (F14) | Copies can drift and need reconciling | Yes | Yes, but one copy per Claude profile plus the shared Codex copy | Yes | Extends existing code | Code and kit tests (project scope only) |
| S5 Claude local-folder plugin marketplace, plus S3 or S4 for Codex | Meets on the Claude side (read in place, F20) | Yes | Namespaced names (bare name if unique) | Settings entry per Claude profile | Yes | Settings writes per profile; schema unverified | Docs |
| S6 Claude `--plugin-dir` through T3 `launchArgs` | Meets (nothing copied) | Yes | Namespaced | Per T3 instance only; not outside T3 | Yes, one flag per instance | Very small | Code (T3) and docs; flag untested |
| S7 Skills over MCP (skillport) | Meets (nothing installed) | Yes | No: no `/name`, no native trigger (F21) | One registration per profile | Yes | Adds `uvx` and an MCP service | README |
| S8 Status quo: per-project kit skills only, nothing global | Meets (kit guard) | Per project | Yes | Not global | Yes | None | Existing (covers kit skills only, not personal ones) |
| S9 Claude `--add-dir <central>` through T3 `launchArgs`, with S3 or S4 for Codex | Meets on the Claude side (nothing copied or linked) | Yes | Yes, native names; the central folder needs a `.claude/skills` layout | Per T3 Claude instance; not for Claude outside T3. One flag per instance (last-wins) | Yes: a per-instance T3 setting, which is a global settings change | Very small | Code (T3) and docs; untested. Also grants every session file access to the central folder |

Routes considered and set aside:
- **Windows hard links** work only for files, not folders. Editors that save
  by replacing a file silently break them.
- **Per-project git worktrees or sparse checkouts** deliver per project only,
  which is S8's scope, and add checkout upkeep.
- **Project-only delivery of personal skills** means copying them into every
  project, which reintroduces copies (S1 or S4).

### Management experience against the acceptance contract

The table compares the three strongest skill routes on the management outcomes
of the acceptance contract (A1-A11; local evidence, not published).

| Outcome | S3 junction adapter | S4 generator copies | S9 `--add-dir` (Claude) |
| --- | --- | --- | --- |
| Catalogue and inventory (A1) | New: list the source and each link's target | Partial: existing manifest and status | None beyond Claude's own skill list |
| One canonical package (A2) | Yes | Yes, with copies | Yes |
| Install, update, remove (A3) | Update is a source edit or commit. Install and remove create or delete links (new) | Existing install and update; removal by deselection | Edit or remove in source; no install step |
| Pin and roll back (A3) | Git, for committed content only | Kit version plus Git | Git |
| Enable and disable (A3) | Remove a link, or Codex `[[skills.config]]` | Selection | Codex as S3; Claude needs the source changed |
| Partial failure (A3) | New: per-link results; refuse rather than fall back | Existing guarded writes | Not applicable |
| Invocation policy kept (A4) | Yes, the same files | Yes | Yes |
| Edit protection (A7) | By design, with the four guards | Yes for kit skills (F14) | By design |
| Worktree and scope behaviour (A8) | User scope, so present in every worktree; project skills of the same name may take precedence (untested) | Project scope today | Every session of that instance |
| Reload | Codex watches skill roots; Claude reloads per session | Same | Per session |

No route covers A1 well yet; the optional management page (H1) is where a catalogue
would live. The loading checks in section 5 are feasibility probes only.
Lifecycle, resource, invocation-policy and T3-worktree checks stay open for the
route chosen.

### Packaged capabilities (MCP servers, hooks, plugins)

| Route | 1 Rule | Notes |
| --- | --- | --- |
| P1 One personal marketplace repo with both manifest sets | Claude: meets when used as a local-folder marketplace (F20). Codex: fails, because background refresh also replaces caches (F19); a pre-command check is not enough | Defer Codex plugins. The Codex marketplace file is shared through `$HOME`; caches and enabled state are per `CODEX_HOME` |
| P2 MCP and hooks written into each tool's config by the generator | Meets only with new work: a recorded content baseline per owned entry; refusal when an owned entry changed or cannot be verified; unrelated configuration preserved; recoverable saving before any restore. The generator's `-Adopt` replacement path must not be used for shared updates or conversions | Today's managed blocks do not check a baseline (section 3). Codex TOML and Claude JSON differ |
| P3 Third-party MCP manager (APM, dotagents, CC Switch) | Partial at best (F12) | Same-name overwrites and TOML rewrites seen in code |
| P4 Adopt ECC or a similar bundle | Fails on repair and reinstall (F15) | Reuse ideas and individual MIT skills only |

### Front end (optional)

H1. **A routing-proxy management page** (F22) could list the source, the links and
profile state, and run the same adapter actions later. It is a front end, not
a delivery route; it is worth building only once a route is chosen and
proven.

## 5. Recommendation

Do not adopt another manager. The weighing favours a small owned layer over
native features:

1. **Skills: S3 as the provisional direction** (one git source plus
   per-skill junctions). It is native, covers every profile and both tools,
   keeps editing at the source and avoids copies. S9 (`--add-dir`) is a
   simpler Claude-side alternative inside T3, at the cost of wider file access
   and no coverage outside T3.
   - It needs a small adapter in the generator with four guards: refuse
     collisions, never fall back to copying, verify each link's target, and
     remove only links.
   - **S4 is the fallback** if Claude does not follow junctions. It meets
     the rule only if every shared update or conversion refuses an installed
     copy that has no recorded content hash or whose hash differs. It must
     never use the generator's `-Adopt` backup-and-replace path. Its copies
     also multiply across profiles.
2. **MCP and hooks: P2,** with the new baseline checks listed in section 4.
   Ownership markers alone do not meet the rule.
3. **Plugins:** for Claude, a local-folder marketplace (P1, read in place).
   Defer Codex plugins until every automatic write path is controlled. Most
   Codex needs (skills, MCP) are covered by S3 and P2.
4. **ECC:** do not install it. Borrow its dual-manifest layout, its
   ownership guard and drift-preserving uninstall as designs, and individual
   MIT skills after review (F15).
5. **Management page:** optional, after the route is proven.
6. **Account-synced skills not in use (F11, F17):** a separate, optional tidy-up.
   Codex can disable them with `[[skills.config]]`. Leave them untouched unless
   the owner asks.

**Feasibility checks (2026-10-16).**
- **Claude:** passed at project scope (F3, local test 3).
- **Codex user-scope check:** declined by the owner; it would write to the
  real profile. Codex already passed at repository scope (local test 1), and
  user and repository scopes share one symlink policy in code (F3), so S3
  stands on that inference for Codex user scope.

A broad build-off is not needed. Before use, the chosen route still needs:
- its own lifecycle tests: install, update, remove, collision and roll back;
- a resource test;
- a T3 worktree test;
- a user-scope load test in each tool, run when the adapter is first used.

**Where the central source lives (owner preference: the Workspace repository
and local).** This needs two tiers, because the Workspace repository is
published to the public `origin`:
- **Shareable tier:** skills suitable for any user. They are tracked in the
  Workspace repository (the kit already ships its skills from
  `project/base/.agents/skills`), so they are published with the product and
  follow its review and publication rules.
- **Personal tier:** private or machine-specific skills. They live in a local
  folder outside the tracked tree, kept as its own local git repository with
  no remote, for history and roll back. Nothing in it is published.

The same adapter links both tiers into each tool. Two consequences:
- An edit made through a link changes the Workspace working tree or the
  personal repository directly. A dirty-tree check is needed before any
  automated update.
- A skill name must be unique across the tiers; the adapter refuses
  duplicates.

## 6. Open questions

- Should Codex plugins be supported now, given the cache behaviour (F19), or
  deferred?
- Does the Claude `extraKnownMarketplaces` schema accept a local folder
  without the CLI (F20)? This only matters if Claude plugins are used.
- Is the shareable tier part of the product, with its own design and
  publication review, or only the owner's convenience?
- What is the exact path of the personal tier? A folder under the user profile
  is the default.

## 7. Supersedes / updates

This updates an earlier route selection (local evidence, not published), which put Skillshare
first, compared few candidates and assumed copy delivery. It extends topic 02
(F26-F27, rulesync and ruler) and topic 07 (F12-F13, managed blocks and
three-way merge). It changes no approved decision. The owner's 2026-10-16
decisions (no maintained fork, no upstream contact, the refined A7) stand.

## Source receipt

Research calls by worker:

| Worker | Research calls |
| --- | --- |
| ECC | 14 |
| Landscape | 17 |
| Native verification | 16 (about 30 GitHub requests) |
| Linker code check | 8 (about 11 requests) |
| No-copy routes | 16 |
| Codex cache and T3 launch | 13 (one over its budget of 12; about 35 requests) |

Workers did not report separate total tool-call counts, so totals are
unavailable.

Leader-run local tests: junction removal (7 cases), one no-model Codex
`skills/list`, a read-only profile inventory, and one owner-approved T3 Claude
thread with one request (local test 3).

Raw text and tool extractions are in a scratch folder outside the repository
(local evidence, not published). It has one subfolder per worker plus
`junction-test`, and each subfolder has an `index.tsv`. One worker wrote a
helper script outside its permitted folder; it was removed. No fetched content
attempted to instruct a worker. Both Codex review rounds' findings were
applied.
