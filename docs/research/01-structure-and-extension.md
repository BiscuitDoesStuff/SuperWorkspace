# 01: Structure and extension

Status: complete; reviewed by the owner 2026-09-27, R1-R4 adopted (R2 corrected).
Researched 2026-09-26 by `project-research` (research-1, Claude Opus 5.5 via
Claude Code). All sources accessed 2026-09-26. The OpenCode pages reported
"last updated September 26, 2026" through the fetch tool; that date may be
the build date, so treat it as an access date. The other pages show no date.

## 1. Question and scope

How do comparable agent-workspace tools and config kits structure a shipped
core plus optional extensions and user-local overlays, and what minimal
structure should SuperWorkspace adopt?

Sub-questions:
1. Harness extension models (OpenCode, Claude Code): packaging, manifests,
   discovery, precedence across global, project and local scopes.
2. Portable skills: Agent Skills (SKILL.md) and which harnesses read it.
3. Overlays: harness-native imports and includes, plus general precedents
   (git `include`, chezmoi). Is `~/.config/superworkspace/rules.local.md`
   sound, and can an import replace rewriting a managed block?
4. Packs and registries: Claude plugin marketplaces, OpenCode plugins,
   copier. What is the smallest SuperWorkspace pack manifest?
5. Recommendation mapped onto the current kit.

Out of scope (per the assignment): install, update and merge mechanics and
lock files (topic 7); cross-harness generation (topic 2); permissions
(topic 8). Interactions with those topics get one line each.

Not covered:
- chezmoi's partial-file tools (`modify_` scripts). The fetched page does
  not describe them, and they were not fetched separately to stay in budget.
- cookiecutter. Copier stands in for template registries because it has
  an update story and cookiecutter does not claim one.
- Harnesses other than OpenCode and Claude Code, and the Agent Skills
  adopter list. Both belong to topic 2.
- Claude plugin install scopes in detail (user, project, local, managed).
  Only the default user scope was confirmed.
- Whether OpenCode's `instructions` array accepts `~` paths, and whether
  arrays concatenate or replace when configs merge. The docs do not say,
  so a runtime test is needed (see Open questions).

## 2. Findings

### Harness extension models (sub-question 1)

F1. **Claude Code instruction scopes load in order and concatenate.** The
order is managed policy, user (`~/.claude/CLAUDE.md`), project
(`./CLAUDE.md` or `./.claude/CLAUDE.md`), then local (`./CLAUDE.local.md`,
gitignored). Files from the filesystem root down to the working directory
are "concatenated into context rather than overriding each other".
`CLAUDE.local.md` is appended after `CLAUDE.md` at each level. Claude reads
`AGENTS.md` when no `CLAUDE.md` exists, or alongside one.
<https://code.claude.com/docs/en/memory>, accessed 2026-09-26.

F2. **Contradictions are not resolved by order.** The same page warns that
"if two rules contradict each other, Claude may pick one arbitrarily". An
overlay should therefore add or replace lines. It should not rely on
coming later in context to override an earlier line.
<https://code.claude.com/docs/en/memory>, accessed 2026-09-26.

F3. **A Claude Code plugin needs no manifest.** "The manifest is
optional"; without one, Claude Code loads the components in the standard
layout (`skills/`, `commands/`, `agents/`, `hooks/` at the plugin root). If
a manifest exists, it lives at `.claude-plugin/plugin.json`, and "`name` is
the only required key". `version` is a free string that "pins the plugin to
that version until you change it". Plugins get `${CLAUDE_PLUGIN_ROOT}` and
`${CLAUDE_PLUGIN_DATA}` (`~/.claude/plugins/data/<id>/`, which survives
updates).
<https://code.claude.com/docs/en/plugins-reference>, accessed 2026-09-26.

F4. **OpenCode merges config layers.** In ascending precedence: remote
`.well-known/opencode`, global `~/.config/opencode/opencode.json`,
`OPENCODE_CONFIG`, project `opencode.json`, `.opencode` directories,
`OPENCODE_CONFIG_CONTENT`, then managed config. Configs "are merged
together, not replaced", and only conflicting keys are overridden.
Component directories are `agents/`, `commands/`, `modes/`, `plugins/`,
`skills/`, `tools/` and `themes/`. `{env:VAR}` and `{file:path}`
substitutions are supported, and `{file:}` accepts `~`.
<https://opencode.ai/docs/config/>, accessed 2026-09-26.

F5. **OpenCode plugins are code, with no manifest.** They load from
`.opencode/plugins/`, `~/.config/opencode/plugins/`, or npm packages
listed in the config's `plugin` array. Load order is global config,
project config, global directory, project directory. Dependencies go in a
`package.json` in the config directory, and OpenCode runs `bun install` at
startup. The page mentions a community ecosystem list but no registry or
marketplace.
<https://opencode.ai/docs/plugins/>, accessed 2026-09-26.

### Portable skills (sub-question 2)

F6. **The Agent Skills format is a directory with a `SKILL.md`.** Only
`name` (1-64 chars, lowercase, hyphenated, must match the directory) and
`description` (1-1024 chars) are required. `license`, `compatibility`,
`metadata` (a string map) and `allowed-tools` (experimental) are optional.
`scripts/`, `references/` and `assets/` are optional, and the format is
loaded by progressive disclosure: metadata at startup, then the body
(under 5000 tokens recommended), then resources.
<https://agentskills.io/specification>, accessed 2026-09-26.

F7. **OpenCode reads skills from its own paths and from Claude and Agents
paths.** In order: `.opencode/skills/`, `~/.config/opencode/skills/`,
`.claude/skills/`, `~/.claude/skills/`, `.agents/skills/`, then
`~/.agents/skills/`. It recognises only the spec's `name`, `description`,
`license`, `compatibility` and `metadata` fields.
<https://opencode.ai/docs/skills/>, accessed 2026-09-26.

### Overlays (sub-question 3)

F8. **Claude Code resolves `@path` imports in CLAUDE.md.** Relative paths
resolve against the importing file, absolute paths are allowed, and
recursion is capped at "four hops". Imports inside code spans are skipped.
The docs show a home import, `@~/.claude/my-project-instructions.md`. Imports
from user-scope files like `~/.claude/CLAUDE.md` load "without the dialog".
External imports from project files need a one-time approval. The one
exception: Cowork desktop sessions skip user-scope imports that point
outside the working directory.
<https://code.claude.com/docs/en/memory>, accessed 2026-09-26.

F9. **OpenCode has no `@file` imports in AGENTS.md.** Its native include
mechanism is the `instructions` field in `opencode.json`, which takes file
paths, globs and remote URLs (5-second timeout) and combines with
`AGENTS.md`. For global rules, "the first matching file wins in each
category". `~/.config/opencode/AGENTS.md` beats the `~/.claude/CLAUDE.md`
fallback, which `OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1` turns off.
<https://opencode.ai/docs/rules/>, accessed 2026-09-26.

F10. **Git precedent: an include is spliced in place and the last value
wins.** "The contents of the included file are inserted immediately, as if
they had been found at the location of the include directive." A relative
include resolves against the including file, `~` is expanded, and
`includeIf` adds conditions such as `gitdir` and `onbranch`. The fetched
text only confirms that missing system or global files are ignored, so
treat "a missing include is ignored" as weak.
<https://git-scm.com/docs/git-config>, accessed 2026-09-26.

F11. **chezmoi handles machine differences by generation, not layering.**
Files become templates fed by per-machine data in
`~/.config/chezmoi/chezmoi.$FORMAT`. `.chezmoiignore` excludes files per
machine, and `.chezmoitemplates/` holds shared fragments. The whole target
file is regenerated, so this is the generation model, not a user-owned
overlay.
<https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/>,
accessed 2026-09-26.

### Packs and registries (sub-question 4)

F12. **A Claude Code marketplace is one JSON file.** It is
`.claude-plugin/marketplace.json`, with required `name`, `owner` and
`plugins`. Each entry needs a `name` and a `source`. Sources can be a
relative path, `github`, `git-subdir`, `url`, `archive`, `npm` or
`command`, and git sources can be pinned by `ref` or `sha`. Users run
`claude plugin marketplace add <owner>/<repo>` and then install
`<plugin>@<marketplace>`. That writes to user settings (`enabledPlugins`).
Plugins added from a local directory load in place, and hosted ones are
copied into a cache.
<https://code.claude.com/docs/en/plugin-marketplaces>, accessed 2026-09-26.

F13. **Copier versions templates with git tags.** `copier update` reads
the template's git tags (PEP 440), rebuilds the old version, diffs the
project against it and re-applies that diff to the new version, marking
conflicts inline or in `.rej` files. It needs a valid
`.copier-answers.yml` ("never update it manually"), a tagged template repo
and a git-versioned destination. Topic 7 owns update mechanics; this is
recorded only as a registry and versioning precedent.
<https://copier.readthedocs.io/en/stable/updating/>, accessed 2026-09-26.

### Current kit (local context, verified by reading, not outside evidence)

- `Set-SwBlock` (`product/lib/Sw.Kit.psm1`) replaces only the text between
  `<!-- sw:begin global -->` and `<!-- sw:end global -->`, and "everything
  outside it is left alone". `Install-SwGlobal` already keeps an
  `@RTK.md` import above the block in the Claude rules. So a user-owned
  import line outside the block survives `global install` today.
- The personal lines at risk are currently edited *inside* the block on
  the owner's machine (for example "Claude: a fresh Opus session" and
  "Ponytail" in `~/.claude/CLAUDE.md`), so the next install would overwrite
  them.
- `product/project/profiles/*/profile.json` is already a small manifest
  (`description`, `editDeny`, `lfs`, `watcherIgnore`, `skills`) with a
  `files/` overlay directory. That is pack-shaped.

## 3. Options compared

### Global overlay

| Option | Claude | OpenCode | Cost | Risk |
|---|---|---|---|---|
| A. Personal lines outside the block, in each harness file | works (F1, F8) | works | zero code | two copies to keep in sync; contradictions resolved arbitrarily (F2) |
| B. One `~/.config/superworkspace/rules.local.md`, imported by `@` in Claude and by `instructions` in OpenCode | `@~/.config/...` from user scope, no dialog (F8) | `instructions` entry in global `opencode.json` (F9); `~` support unverified | one line per harness, written once outside the block | Cowork skips it (F8); OpenCode path form to verify |
| C. Templated block with per-user variables (chezmoi style) | yes | yes | new template engine | against "neutral core"; F11 shows it is a whole-file generator |
| D. Kit merges the overlay into the block at install time | yes | yes | new merge code | hides provenance; needs rerun on every edit |

### Pack manifest

| Option | Manifest | Fits kit | Notes |
|---|---|---|---|
| a. No pack format yet | none | profiles already cover stacks | YAGNI until a second real pack exists |
| b. Directory mirroring `.opencode/` plus `pack.json` `{name, version, description}` | 3 keys | same shape as `profile.json` | matches Claude's "only `name` required" (F3) |
| c. Ship packs as Claude plugins plus OpenCode npm plugins | two formats | needs generation (topic 2) | native registries exist for Claude only (F5, F12) |
| d. Copier-style template repo with git tags | answers file | overlaps with `update` (topic 7) | strongest versioning precedent (F13) |

## 4. Recommendation

R1. **Adopt option B; the planned path is sound.** Keep
`~/.config/superworkspace/rules.local.md` as the single user-owned file.
It is outside every harness directory, so no harness install touches it,
and it follows XDG like OpenCode's own config. An import can replace
rewriting personal lines into the managed block:
- Claude: `global install -Claude` writes
  `@~/.config/superworkspace/rules.local.md` once, *after* the
  `sw:end global` marker. This reuses the existing `@RTK.md` include
  pattern. Placing it after the block follows git's order (F10), but
  content must not contradict the block (F2).
- OpenCode: add the path to `instructions` in the global
  `~/.config/opencode/opencode.json` (F9), not to `AGENTS.md`, which
  cannot import. If `~` is not expanded, use `{file:~/...}`, or write the
  absolute path on the user's machine (a machine path, so it stays local).
- The kit creates `rules.local.md` only if it is missing, as an empty stub
  with a short comment header and no opinions, and never rewrites it.
  Backups already cover the user profile.

R2. **Move the owner's in-block edits to the overlay; the product rules do
not change.** `product/global/rules.md` is already tier-neutral: it has no
model names and no free-first rule. The personal lines are owner edits
made inside the managed block in `~/.claude/CLAUDE.md`: the Opus and
Sonnet model routing, Ponytail, `code-review` and free-first. They move to
`rules.local.md`, which leaves the block identical to the product file.
The core states the tiers, and the overlay says what they mean on this
machine. Remove, do not override: an overlay that contradicts the block
gets arbitrary results (F2). The only product change is R1: write the
import line and the `instructions` entry.

R3. **Do not build a pack format yet (option a).** The hypothesis
"personal opinions become opt-in packs" is mostly answered by R1:
personal opinions are one Markdown file, not a pack. Keep
`product/project/profiles/*` as the only extension unit. If a second
shareable bundle appears (roles or skills beyond a stack profile), grow
`profile.json` into option b by adding `name` and `version`. Mirror
`.opencode/` layout, so no new discovery code is needed. Do not add a
registry: Claude marketplaces (F12) and git tags (F13) already exist.

R4. **Keep skills in the Agent Skills shape.** The kit's
`.opencode/skills/<name>/SKILL.md` with `name` and `description` already
matches F6. OpenCode also reads `.claude/skills` and `.agents/skills`
(F7), which topic 2 should weigh against generating Claude copies.

Interactions (one line each):
- Topic 2: F7 may remove the need to copy skills for Claude; the import
  line is harness-specific output.
- Topic 7: `update` must never touch `rules.local.md` or text outside the
  block. Copier's answers file plus tags (F13) is the precedent to test.
- Topic 8: plugin and skill permissions, and Claude's external-import
  approval dialog (F8), are permission surfaces.

## 5. Open questions

Owner answers recorded 2026-09-27 (relayed by the Leader).

1. Owner: accept R2's split (the core names tiers only; models, tool
   names and cost rules move to `rules.local.md`)?
   **Answer:** adopted as corrected. `product/global/rules.md` is already
   neutral; only the owner's in-block edits move (see R2).
2. Owner: should the kit seed `rules.local.md` from a template on the
   first `global install`, or leave it for the user to create?
   **Answer:** seed an empty stub (see R1).
3. Runtime test needed: does OpenCode's `instructions` accept `~/` paths,
   and does a project `instructions` array replace or extend the global
   one? The docs do not say (F4, F9).
   **Answer:** still open; run the test before implementing R1.
4. Does the owner use Cowork? If so, the Claude import is skipped there (F8).
   **Answer:** Cowork is not used. A default Cowork project points at this
   folder, so the import would be skipped if Cowork is ever used there.
   This risk is accepted.
5. Research-skill runtime test (the first real one): about 30 tool calls
   against a cap of 25, counting the validation, event and message.
   Research itself took 21 calls, within the cap. The overrun came from
   submission mechanics: the `-Message` misuse, filling placeholders, a
   line-ending fix, and this correction. The hard-question guide of about
   10 was not realistic for four sub-questions across two harnesses. Writing the plan first worked.
   Re-verification ran against saved fetch output (exact passages
   re-read for F1-F3 and F8). F4-F7 and F9-F13 rely on one fetch
   summarised by the fetch tool's model; I did not re-fetch them, and I
   removed one unsupported claim about missing includes (now weak in
   F10). Suggestion: allow re-verification from saved fetch output, and
   say whether a tool-model summary counts as "fetched".
   **Answer:** noted. The Leader proposes that the cap count research
   calls only.

## 6. Supersedes / updates

None. This file refines the `docs/roadmap.md` input "Global overlay
(topics 1-2)" and the hypotheses "Personal opinions become opt-in packs"
and "Global rules become a neutral core plus a user overlay". It proposes
no edits to `docs/decisions.md`.
