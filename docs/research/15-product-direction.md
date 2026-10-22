# 15: Product direction: T3 Code with CLIProxyAPI, one central source with native wiring

Status: owner decisions recorded (section 2); findings are research, and the
open items are unresolved. 2026-10-16, main T3 Code thread. Four read-only
research packages fed it. Codex review rounds 1-2 (2026-10-17) found eight
issues, all fixed. This topic refines topic 14 and partly supersedes its
recommendation (section 9). It authorizes no implementation, installation,
global setting change or publication.

Source access: web sources were fetched 2026-10-17 UTC (the evening of
2026-10-16 local) unless dated otherwise. Raw copies are kept outside the
repository with SHA-256 indexes (local evidence, not published). "Extraction"
means tag-stripped page text, not the raw page. "Local" means the repository at
commit `a3251ae`. T3 Code was read at `pingdotgg/t3code@bf990c6`; CLIProxyAPI at
tag `v8.0.32`; Codex at `openai/codex@6ae8b8aa7c60` (main, not a release tag).

## 1. Question and scope

What should SuperWorkspace be for, and how should one owner's shared skills,
rules, MCP servers and hooks reach every supported harness without breaking the
rule below?

- No update, removal, conversion or restore may overwrite or delete an installed
  copy that was edited locally or cannot be shown unedited (A7).
- There is no `--force` bypass.
- A restore proceeds only after saving what it replaces, recoverably.

In scope: Claude Code and Codex on Windows, run inside T3 Code, with CLIProxyAPI
as the inference proxy. Out of scope: other harnesses (section 5), installing
anything, provider or model choice, and plugins (topic 14's deferral stands).

## 2. Decided (owner, 2026-10-16)

These are decisions, not findings. Nothing in section 3 changes them.

D1. **Product.** SuperWorkspace targets T3 Code with CLIProxyAPI. Supported
harnesses are Claude Code and Codex; others are added after verification.
Windows only for now.

D2. **Architecture (approved).** A central two-tier source plus native wiring
per harness. CLIProxyAPI does routing only.
- Product tier: in the repository.
- Personal tier: local at `~/.sw/`, skills at `~/.sw/skills`, no Git.
- Skills: per-skill links into `~/.agents/skills` and into each Claude
  profile's `skills` folder.
- Rules: an `@import` where the harness supports one (Claude), otherwise a
  managed block (Codex).
- MCP and hooks: generated owned entries, only when needed.
- Everything carries A7 baselines.

This supersedes the managed-provider-home plan and topic 14's S3-as-is
recommendation where they differ (section 9).

D3. **Rules.** The same central rules reach every harness, plus optional
per-harness additions in the personal tier.

D4. **CLIProxyAPI.**
- No CLIProxyAPI-side rule injection.
- No management page for now.
- Published text says "CLIProxyAPI", not a coined "Hub" term.
- Document one tested, pinned CLIProxyAPI version and re-pin it frequently.

D5. **A7 (binding).** The rule in section 1 applies, and editing happens at the
central source. The first implementation package is:
- a baseline record at `~/.sw/global.json`;
- retire `-ReplaceUnmanaged`;
- stop install-time rewrites of `settings.json` and `~/AGENTS.md` (report them
  in `check` instead);
- an edited block is a WARN with exit 0.

The shipped `global/rules.md` has 9 versions by `git log --follow` (Local,
re-counted 2026-10-16).

D6. **PowerShell (owner, 2026-10-16, decided after review):** the kit runs on
the PowerShell built into Windows (5.1) with nothing else to install, and also
on PowerShell 7. Product commands use `-ExecutionPolicy Bypass`. Pester 5 is a
development dependency only. The Linux/macOS code paths are removed. A local
read-only assessment found the port moderate in size: about 51 PowerShell-7-only
sites before A7. A7 hashes do not depend on the engine (section 8, Q1).

## 3. Findings

Each finding cites a source or is marked Local. H = read in code or a primary
document at the pinned version; M = inferred; L = weak.

### T3 Code

F1. **Only Claude and Codex have a home field; every driver has an environment
list.**
- A Claude instance's `homePath` becomes `CLAUDE_CONFIG_DIR`; a Codex
  instance's becomes `CODEX_HOME` (set only when non-empty; `~` is expanded only
  for these two). Other drivers are steered only through the environment list.
- Claude runs through the Agent SDK `query()` with no `settingSources`
  restriction, so profile settings load. Codex runs `codex app-server`.
  `launchArgs` reach both as extra arguments.

Sources: `packages/contracts/src/providerInstance.ts`,
`packages/provider-core/src/server/instanceEnvironment.ts`,
`apps/server/src/provider/Drivers/ClaudeHome.ts`,
`apps/server/src/orchestration-v2/Adapters/{Claude,Codex}AdapterV2.ts` at
<https://github.com/pingdotgg/t3code/tree/bf990c625e75>, accessed 2026-10-17.
H. Whether `codex app-server` accepts `-c` overrides per instance: unverified.

F2. **Codex shadow homes share state by symlink; Claude has no equivalent.**
- With `shadowHomePath` set, T3 symlinks every entry of the shared Codex home
  into the shadow home except `auth.json`, `models_cache.json`, `log`,
  `memories` and `tmp`. So `config.toml`, `AGENTS.md` and `hooks.json` are
  shared, and it throws if a real same-named file exists in the shadow home.
- Consequence: write Codex config and `AGENTS.md` only into the shared home,
  and never replace a shadow entry with a regular file.
- The links use a symlink call with no type argument, so the shadow home likely
  needs Developer Mode or elevation on Windows (M, untested).

Source: `apps/server/src/provider/Drivers/CodexHomeLayout.ts` (same commit and
date); T3 docs `docs/user/providers-claude.md` and `providers-codex.md`. H for
behaviour.

F3. **T3 injects its own `t3-code` MCP server per thread and does not touch the
user's MCP files.** Claude gets it as an SDK `mcpServers` entry; Codex gets it as
a `mcp_servers` entry in the thread config plus developer instructions. T3 also
adds its own instruction text through the system prompt or developer
instructions, not through files. Sources:
`packages/provider-core/src/server/McpProviderSessions.ts` and the two adapters
in F1, same commit and date. H. Implication: a user-level MCP or rules file does
not conflict with T3's channel, and neither replaces it.

F4. **Routing reach is narrower than the driver list.**
- Claude: a documented T3 pattern (per-instance `ANTHROPIC_BASE_URL` and
  `ANTHROPIC_AUTH_TOKEN` in the environment list; a router "uses an ordinary
  Claude provider instance"). H.
- Codex: documented by Codex as `openai_base_url` or
  `[model_providers.<id>]` with `base_url`, where `wire_api` supports only
  `responses`. T3's own Codex doc describes no endpoint override, and the
  app-server `-c` path is unverified (F1). M. A Codex instance routed through
  CLIProxyAPI has been used locally, but its mechanism was not read (Local, not
  re-tested here).
- Cursor cannot be routed (T3 states the SDK has no endpoint override), H.
  Antigravity probably cannot (T3 strips ambient Google and Gemini variables), M.
  Muse is unknown, L. OpenCode, Pi and Grok are documented in their own config,
  but T3 integration is unproven (section 5).

Sources: <https://code.claude.com/docs/en/llm-gateway>,
<https://developers.openai.com/codex/config-advanced>,
<https://developers.openai.com/codex/config-reference> (extractions);
T3 docs `docs/user/cursor.md`, `providers-{claude,codex,antigravity,muse}.md`
and `apps/server/src/provider/antigravityAuthSupport.ts`, same commit and date.

### CLIProxyAPI

F5. **CLIProxyAPI is an inference proxy. It has no MCP, tool-hosting, skill,
rules or configuration-distribution surface.**
- Its routes cover the OpenAI chat and Responses shapes, Anthropic messages,
  Gemini and a Codex-direct group.
- A full v8.0.32 tree listing (2,258 entries) and a search of its README, config
  example, plugin API and server sources found no MCP or skill surface. The only
  hits were a tool-name alias for cloaked Claude requests and a README link to a
  third-party server that uses it.
- This is "not found at v8.0.32", not proof for later versions.

Sources, all at tag `v8.0.32`:
<https://raw.githubusercontent.com/router-for-me/CLIProxyAPI/v8.0.32/internal/api/server_routes.go>,
`README.md`, `sdk/pluginapi/types.go`,
<https://api.github.com/repos/router-for-me/CLIProxyAPI/git/trees/v8.0.32?recursive=1>,
accessed 2026-10-17. H.

F6. **Its payload rules are JSON-path surgery on the translated request, not a
prompt feature, and prompt injection would be invisible.**
- Rule blocks (`default`, `override`, `filter`) set or remove fields; there is
  no config key for system prompt, instructions or rules.
- Appending text, rather than replacing the harness's own, is unverified.
  Prompt-injection plugins exist but are third-party native code (the one read
  was single-maintainer, built against an older plugin SDK).
- For Claude OAuth credentials its default "cloaking" rewrites the system prompt
  of non-Claude-Code clients, so where an injected block lands is unverified.
- Costs of central injection (design reasoning, not measured): paid on every
  request including T3's side calls, hidden from the transcript, and reaching
  only routed harnesses.

Sources: `config.example.yaml`, `internal/runtime/executor/helps/payload_helpers.go`
at `v8.0.32`; <https://raw.githubusercontent.com/markhuangai/cpa-plugin-prompt-rules/main/README.md>;
<https://raw.githubusercontent.com/router-for-me/CLIProxyAPI-Plugins-Store/main/registry.json>,
accessed 2026-10-17. H on mechanism, L on append-style injection.

F7. **Its management surface carries trust costs a published product would
inherit.**
- The panel is downloaded from a separate GitHub repository every 3 hours unless
  disabled, with an unverified fallback page if the release lookup fails.
- Plugins are unsandboxed native libraries; their resource pages are served
  without management authentication; CORS is a wildcard on all routes.
- The official panel stores a remembered key with "reversible obfuscation, not
  encryption".

Sources: `internal/managementasset/updater.go`,
`internal/pluginhost/management.go`, `internal/api/server_management.go`,
`internal/api/server_middleware.go` at `v8.0.32`;
<https://raw.githubusercontent.com/router-for-me/Cli-Proxy-API-Management-Center/main/README.md>,
accessed 2026-10-17. H. The plugin checksum comes from the same release, so it
detects corruption, not a hostile publisher.

F8. **Release churn is high, so a pin ages fast.**
- The newest 100 releases span 2026-08-02 to 2026-10-16: about 1.33 a day,
  median gap about 18 hours. v8.0.0 shipped 2026-09-27; there were 33 v8
  releases in 19 days, counting v8.0.0. The latest at access time was v8.0.32 (2026-10-16).
- Patch releases carried config-key moves and new config sections after the v7
  to v8 layout break. The plugin SDK types file was byte-identical between
  v8.0.29 and v8.0.32.

Sources: <https://api.github.com/repos/router-for-me/CLIProxyAPI/releases?per_page=100>,
<https://api.github.com/repos/router-for-me/CLIProxyAPI/releases/latest>,
accessed 2026-10-17 (the 1.33 and 33 figures come from an extraction of that
list). H on the listed events, M on completeness (changelogs are commit lines).

### Harness-native delivery

F9. **`~/.agents/skills` reaches Codex but not Claude; Claude needs its own
folder.**
- Codex reads `~/.agents/skills` (topic 14, F1).
- Claude reads `<config dir>/skills`, documents a per-skill symlink ("loads once
  even if several locations point at the same target"), and lists no
  `.agents/skills` location. Neither tool has a persistent settings key for an
  extra skills folder (topic 14, F18).
- Local tests (topic 14, F3 and F4): Codex listed a junction-reached
  repository skill; Claude loaded a junction-reached project skill; removing a
  junction left its target intact with the usual tools.
- Live check (section 7): user-scope junctions list in both tools; Claude does
  not read `~/.agents/skills`. Untested: implicit invocation.

Sources: <https://code.claude.com/docs/en/skills.md>, accessed 2026-10-17;
topic 14 (Local). H for locations, M for user-scope links.

F10. **Claude can read central rules in place through `@import`, with no
approval dialog at user scope.**
- `CLAUDE.md` supports `@path` imports with relative, absolute and `~/`-prefixed
  paths, up to four hops deep.
- Imports in user-scope files (`~/.claude/CLAUDE.md`, `~/.claude/rules/`) load
  without the external-import dialog.
- Claude reads `AGENTS.md` itself only when no `CLAUDE.md` exists in or above
  the folder.
- File symlinks on Windows need Administrator or Developer Mode, and the docs
  recommend the import over a symlink there.

Source: <https://code.claude.com/docs/en/memory.md>, accessed 2026-10-17. H.
A live check confirmed that a custom `CLAUDE_CONFIG_DIR` loads its own
`CLAUDE.md` (section 7).

F11. **Codex has no import syntax, so rules need a managed block in a file the
user also owns.**
- The user file is `$CODEX_HOME/AGENTS.md` (an override file takes precedence).
- Under a shadow home that file is a link into the shared home (F2).

Sources: Codex AGENTS.md guide
<https://developers.openai.com/codex/guides/agents-md> (extraction); topic 02
(Local). M. The kit's present block writer replaces an owned block without
checking a baseline (F16).

F12. **MCP servers and hooks have no shared format.**
- Claude uses JSON (`mcpServers`, `settings.json` hooks).
- Codex uses TOML (`[mcp_servers.<name>]`, `hooks.json` or inline `[hooks]`).
- Other harnesses add three more shapes, and env-secret interpolation syntax
  differs per harness.
- The kit can parse JSON today but has no TOML parser; a canonical form for
  hashing an owned Codex entry is an open design question (Local, A7 design O7).

Sources: T3 provider capability matrix; Codex MCP and hooks docs
<https://developers.openai.com/codex/mcp>,
<https://developers.openai.com/codex/hooks> (extractions); Claude MCP docs
<https://code.claude.com/docs/en/mcp.md>, accessed 2026-10-17. H for locations.

F13. **Skills over MCP is a finished standard, but the surveyed client matrix
lists no T3 harness as supporting it.**
- The MCP Skills extension (SEP-2640) is Final. It standardizes `skills/list`,
  `skills/get` and per-file sha256 digests.
- Its client matrix lists partial or full support only in a few clients outside
  the T3 set; Claude and Codex are not listed for Skills.
- Community servers are small, mostly single-maintainer, and pre-date the
  extension. They lose `/name` and `$name` invocation and native triggering.
- A vendor eval (one task family, so direction only) found models often did not
  invoke an on-demand docs skill unless told to.

Sources: <https://raw.githubusercontent.com/modelcontextprotocol/modelcontextprotocol/main/seps/2640-skills-extension.md>,
<https://raw.githubusercontent.com/modelcontextprotocol/modelcontextprotocol/main/docs/extensions/client-matrix.mdx>,
<https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals>
(extraction), accessed 2026-10-17. H on status, L on the eval's relevance.

F14. **No surveyed manager was verified to meet A7.**
- Demonstrated failures:
  - Topic 14's F12 code reads stand for rulesync, ruler, getsentry/dotagents,
    vercel-labs/skills, CC Switch, openskills and microsoft/apm: copy-mode
    overwrites, recursive removal, link-to-copy fallback, backup failures
    ignored. APM comes closest, but its update deletes and re-copies.
  - In a local Skillshare pilot, its copy sync overwrote an edited copy.
- Two tools were added from their READMEs only; their code was not read.
  - amtiYo/agents generates MCP entries into each format and links skills,
    falling back to a copy where links are unavailable.
  - iannuttall/dotagents links whole directories and says it backs up before
    any overwrite.

  A copy fallback breaks A7 unless it is guarded. Whole-directory links are
  coarser than per-skill links.
  Whether either tool protects edits was not verified.

Sources: topic 14 (Local) for the code reads and the Skillshare pilot;
<https://raw.githubusercontent.com/amtiYo/agents/main/README.md>,
<https://raw.githubusercontent.com/iannuttall/dotagents/main/README.md>,
accessed 2026-10-17. Versions and activity come from each repository's GitHub
API metadata (for example <https://api.github.com/repos/amtiYo/agents>),
accessed 2026-10-17; that metadata does not show write behaviour. Confidence:
H for topic 14's code reads, M for the pilot, L for the two README-level
tools.

F15. **Personalization should avoid same-name collisions and prefer native
switches over edits.**
- Same-name handling differs per harness. Claude has precedence and
  namespacing, Pi keeps the first found and warns, and Codex lists both. T3
  Code's own skill scanner keeps the first name it finds for Cursor; that is
  T3's menu, and Cursor's own loader was not checked. So "personal shadows
  product" is not portable; refuse duplicate names across tiers.
- Per-skill switches exist that need no source edit: Claude `skillOverrides`,
  Codex `[[skills.config]]`.
- The accepted pattern for shipped defaults plus user edits is a recorded base
  digest and a three-way decision (the Debian conffile rule): keep a lone user
  edit, take a lone package change, stop if both changed.

Sources: <https://code.claude.com/docs/en/skills.md>;
<https://raw.githubusercontent.com/badlogic/pi-mono/main/packages/coding-agent/docs/skills.md>;
T3 Code skill scanner at `bf990c6` (code read); topic 02, F3 (Local, Codex);
<https://www.debian.org/doc/debian-policy/ap-pkg-conffiles.html> (extraction),
accessed 2026-10-17. M. How owners actually behave is unmeasured.

### Workspace today (Local, commit `a3251ae`)

F16. **`sw global` writes managed blocks and user config with no baseline.**
- An edited block in `CLAUDE.md` or `AGENTS.md` is overwritten (a pre-install
  snapshot is kept). `-ReplaceUnmanaged` deletes unmanaged text after a backup,
  which is a force-style bypass.
- Install also rewrites `permissions.allow` in Claude `settings.json` and an
  `@RTK.md` include in `~/AGENTS.md` on every run.
- `check` reports a block as OK when the begin marker is present, so an edited
  or stale block reads OK.
- Malformed-marker checks run per home inside the write loop, so earlier homes
  can already be written.

Source: `lib/Sw.Kit.psm1` (`Install-SwGlobal`, `Set-SwBlock`, `Test-SwGlobal`),
`CHANGELOG.md` (records the known gap). H.

F17. **The project manifest gives a reusable pattern for global baselines.** It
stores a SHA-256 over LF-normalized text per file, uses a strict reader, and
decides `add / same / update / kept-local / skip-modified / adopt / conflict`.
The A7 design proposes a sibling record `~/.sw/global.json` keyed by home,
entry keys such as `CLAUDE.md#global`, a static list of the 9 shipped
`global/rules.md` hashes as the migration anchor, per-target refusal of edited or
unverified blocks, no trust-on-first-use, and validation before any write. It
is a design proposal with 20 Pester cases listed; none is implemented or tested.
Source: `lib/Sw.Kit.psm1`, `lib/Sw.Project.psm1`, `tests/Sw.Tests.ps1` (Local);
`docs/research/14-shared-capabilities.md` (baseline requirement). H for the
existing mechanism, design only for the rest.

## 4. Architecture

Proposal following D2, scoped to Claude and Codex. Mechanism choices marked
"proposal" are not owner decisions.

| Artefact | Claude Code (each profile's config dir) | Codex (shared home) |
| --- | --- | --- |
| Skills, product and personal tiers | Per-skill link into the profile's `skills` folder (F9) | Per-skill link into `~/.agents/skills` (F9) |
| Central rules | `@import` line in the profile's user `CLAUDE.md` (F10) | Managed block in the shared home's `AGENTS.md` (F11, F2) |
| Per-harness additions (D3) | Proposal: a second import of a personal-tier file | Proposal: a second managed block |
| MCP | Generated owned entry, only when needed; JSON (F12) | Generated owned entry, only when needed; TOML, canonical form open (F12) |
| Hooks | Generated owned entry, only when needed | Generated owned entry, only when needed |
| Routing | CLIProxyAPI through the instance environment (F4) | CLIProxyAPI through Codex's provider config (F4) |
| Baseline and refusal | A7 record for every written artefact (F17) | Same record, shared home only |

Guards that apply to every skill link, from topic 14: refuse a collision with a
real folder, never fall back to copying, verify each link's target, remove only
links, and refuse duplicate names across tiers.

Open mechanism details: which stable path the Claude `@import` and the Codex
block point at, because the product tier's checkout path is machine-specific and
a copy under `~/.sw/` would itself be a delivered copy needing a baseline (Q2).

## 5. Harnesses out of scope for now

Per D1 these are added after verification, not excluded for good. Reasons are
from the T3 provider matrix (pinned commit above, accessed 2026-10-17).

| Harness | Why not now |
| --- | --- |
| OpenCode | No home field, configured through the environment list. Routable in its own config, but link-following and dedupe are undocumented, and T3 supports versions the docs read may not match. |
| Pi | No home field; the agent directory is an environment variable. Has its own `skills` setting (a no-link route). T3 supports older versions than the docs read, so native MCP may be absent. |
| Grok | Documented custom-endpoint config, but whether T3's ACP path lists or runs such a model is untested; the MCP docs page returned 404. |
| Cursor | Cannot be routed through CLIProxyAPI (no endpoint override in the SDK) and has no user-level rules file. |
| Muse | Routing, the user rules path and settings relocation are all unretrieved or unknown. |
| Antigravity | Probably not routable; T3 gives it a private profile that likely hides global rules and MCP; it does not read `~/.agents/skills`; its skill folders differ between its CLI and IDE. |

## 6. Why not the alternatives

- **CLIProxyAPI as the central place.** It has no skill, MCP or rules surface
  (F5). Injecting rules is invisible, costs tokens on every request including
  T3's side calls, and reaches only routed harnesses (F6). Its management
  surface adds supply-chain and exposure cost (F7). It stays routing only (D4).
- **One managed provider home per harness.** It reaches only Claude and Codex
  through instance fields (F1) and leaves other drivers uncontrollable the same
  way. The homes also hold auth, caches and sessions that the tools edit
  themselves, Codex skills ignore `CODEX_HOME`, and Codex shadow homes already
  expect to own their entries (F2). It would stop working outside T3 instances.
  Rejected by D2.
- **MCP Skills extension (SEP-2640).** The standard is real and carries digests,
  but the surveyed client matrix lists no T3 harness as supporting it, and
  tool-based delivery loses native
  invocation (F13). Revisit as clients adopt it.
- **Skillshare (and copy-mode managers generally).** An earlier local pilot
  found its copy sync overwrote an edited copy (topic 14, F12; Local), and the
  wider survey verified no manager as meeting A7 (F14).

## 7. Live checks

Run 2026-10-17 UTC with owner approval (decisions 17 and 18, 2026-10-16), on
Windows, one T3 Code version, one model per harness, through T3 provider
instances with custom homes. Each result is the agent's report of its loaded
context, not a harness log. Afterwards the profile test file and both junctions
were removed. The scratch skill source was kept outside the repository and the
profiles.
Local.

1. **Custom `CLAUDE_CONFIG_DIR` loads its own `CLAUDE.md`: yes.** A marked
   `CLAUDE.md` holding a unique token was placed in a Claude instance's custom
   config directory. A new T3 thread on that instance quoted the token and
   named the file as its user-level instructions. Not tested: an `@import` from
   that file to a path outside the directory.
2. **Duplicate skill in two folders: no duplicate.** One test skill was linked by
   directory junction into both `~/.agents/skills` and the Claude instance's
   `skills` folder. Claude listed it once and Codex listed it once (from
   `~/.agents/skills`). Control: with the Claude link removed, Claude listed
   nothing, so Claude does not read `~/.agents/skills`. This also shows that
   user-scope junctions load in both tools. Not tested: invocation, and harnesses
   that read both folders.

Still unrun, from earlier topics: whether `codex app-server` accepts
per-instance `-c` overrides, and whether the Codex shadow home works on Windows
without Developer Mode.

## 8. Open questions

1. **PowerShell direction: resolved (D6).** The owner first asked to "move away
   from PowerShell 7 to the most up-to-date PowerShell, or Terminal". On
   clarification, they chose the built-in Windows PowerShell 5.1 with nothing to
   install, supporting PowerShell 7 as well. At that point the kit required 7.2
   or later (Local).
2. Which file do the Claude `@import` and the Codex block point at: the checkout's
   `global/rules.md`, or a copy under `~/.sw/` (which needs its own baseline)?
3. How are the per-harness additions (D3) delivered: a second import and a
   second block, or inside the same ones?
4. Remaining A7 design items (Local): record-write ordering, reporting the
   retired OpenCode block, and the Codex TOML canonical form. Already decided in
   D5: an edited block is a `check` warning (exit 0).
5. Which CLIProxyAPI version is the first documented pin, and how often it is
   re-pinned (F8).
6. Provider terms for routing subscription credentials through a proxy that can
   disguise client identity were not assessed. They matter for any published
   guidance.

## 9. Supersedes / updates

- **Topic 14, section 5, skills.** S3 stays the skills mechanism, now fixed to
  two tiers with the personal tier at `~/.sw/skills`. This answers topic 14's
  open question on the personal path, and its question on whether the shareable
  tier is part of the product (D2). S5, S6 and S9 are not chosen.
- **Topic 14, section 5, MCP and hooks.** P2 stands, now bound to D2's "only
  when needed" and the A7 record (F17).
- **New in this topic.** Rules delivery (F10, F11), the record location and the
  retirement of `-ReplaceUnmanaged` (D5), and the product scope (D1).
- **Managed provider homes** are rejected (section 6).
- **Unchanged.** Topic 14's deferral of Codex plugins, its guards, and its ECC
  conclusion. This topic did not re-examine them.

## Source receipt

Four read-only packages, each with its own raw sources and `index.tsv`
(local evidence, not published): T3 Code provider matrix, CLIProxyAPI
capabilities, cross-harness centralization, and the A7 baseline design. Each
package went over its nominal research budget; the centralization package used
about three times its budget. No fetched
content tried to instruct a worker. The A7 design package is Local analysis of
the repository and has no web index. This topic's author re-read the Claude
memory documentation for F10, re-counted the shipped rules history (9) and
re-checked the PowerShell floor, from local files only; no web access, install
or runtime test was run for it.

Gaps: the A7 design package has no source index; the Codex routing mechanism is
documented by Codex but not by T3 (F4); several documentation pages were read
only as extractions. The packages disagreed on nothing that changes a decision.
