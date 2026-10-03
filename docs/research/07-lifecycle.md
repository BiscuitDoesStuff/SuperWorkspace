# 07: Lifecycle

Status: complete; reviewed by the owner 2026-09-27; R1-R7 adopted (R7: skills move planned for the next phase with the rename map).
Researched 2026-09-26 (local) by `project-research` (research-7, Claude Opus 5.5
via Claude Code, desktop app, native Windows). All sources accessed
2026-09-27 at 03:48Z; page dates are given where the page showed one. Raw
page text was saved with `curl` to the session scratchpad (outside the
repo). Claude pages were fetched as their `.md` sources, GitHub READMEs as
raw Markdown, and HTML pages were stripped to text. Every finding was
re-checked against that text. No finding is summary-based. Findings that
rest on an *absence* in the fetched text are marked **weak**.

## 1. Question and scope

How do comparable tools install, update and merge scaffolding into user
projects while keeping user edits, and what lifecycle model should
SuperWorkspace keep or change?

Sub-questions:
1. Distribution: how tools reach a project and pin a version; how a user
   gets a newer kit.
2. Update and merge: hash manifest, three-way merge, managed blocks,
   overlays; how each keeps edits and handles conflicts, compared with the
   kit's plan actions.
3. Lock files and pinning: is `.sw/manifest.json` enough?
4. Adoption: the `-Adopt` gap and how others adopt existing config.
5. Migrations and removal, applied to 02 option b.
6. Local analysis of the kit's lifecycle code against its docs.
7. Recommendation, plus a verdict on 02 option b.

Out of scope (one line each):
- Global overlay: topic 1, decided.
- Permissions: topic 8.
- Validation and evaluation (including new `validate` checks): topic 9.
- Multi-user and branch models: topic 10.

Not covered:
- Claude plugin "Versions and updates" and "When auto-update runs"
  sections (`plugins/loading`); the fetched pages link to them only.
- cruft conflict handling: the README does not describe it (**weak**:
  absence).
- rulesync lock or source pinning: the README does not mention one
  (**weak**: absence). Its linked docs site was not fetched.
- OpenCode npm plugin version pinning syntax: the plugins page does not
  show one (**weak**: absence).
- Package-manager lock files (npm `package-lock.json`): dropped for budget;
  PSResourceGet's `RequiredResourceFile` stands in as the pinning example.

Throwaway init for observation (not a research call), path under the
session scratchpad:
`pwsh -NoProfile -File product/sw.ps1 init <scratchpad>/adopt -Adopt -Name Adopt`
on a directory holding only a three-line `AGENTS.md`, then
`<scratchpad>/adopt/.sw/sw.ps1 validate -Path <scratchpad>/adopt`, then one
appended line in `.sw/workspace.md` and `product/sw.ps1 update .` there.

## 2. Findings

Findings from topics 0-6 are cited as `0N-F<n>` or `0N R<n>`.

### Distribution and pinning (sub-questions 1 and 3)

F1. **Copier pins by git tag and records it in an answers file.** By
default Copier copies "from the last release found in template Git tags,
sorted as PEP 440"; `--vcs-ref` picks another ref. The chosen version "is
stored automatically in the answers file, like this: `_commit: v1.0.0`".
The answers file (default `.copier-answers.yml`) holds the user's answers;
its template header reads "Changes here will be overwritten by Copier;
NEVER EDIT MANUALLY". Template authors are warned: "Avoid moving Git tags
after projects have been generated from them".
<https://copier.readthedocs.io/en/stable/generating/> and
<https://copier.readthedocs.io/en/stable/configuring/>, accessed
2026-09-27, no page date.

F2. **Copier checks for a newer version without applying it.**
`copier check-update` prints "Current version is 1.0.0, latest version is
2.0.0"; `--output-format json` and `--quiet` (exit code) serve automation.
<https://copier.readthedocs.io/en/stable/updating/>, accessed 2026-09-27,
no page date.

F3. **cruft records the template commit hash in `.cruft.json`.** The file
"contains the git hash of the template used as well as the template
variables specified", plus a `skip` list of paths never updated.
`cruft check` validates "whether or not a project is using the latest
version of a template" and "can easily be added to CI pipelines".
<https://github.com/cruft/cruft> (README), accessed 2026-09-27, no release
date on the page. Secondary (README, not reference docs).

F4. **Claude plugins are not copied into the project; the project commits
only an enable entry.** Project scope puts the entry in
`.claude/settings.json`, "which you commit. Committing that entry turns
the plugin on for your collaborators but doesn't download it to their
machines", so each runs `claude plugin install ... --scope project` once.
Hosted plugins go to a cache (01-F12). A marketplace source can pin a
branch or tag with `#ref` (01-F12 adds `sha`).
<https://code.claude.com/docs/en/discover-plugins>, accessed 2026-09-27,
no page date.

F5. **Claude plugin `version` pins; auto-update is per marketplace, off
for third parties.** `version` is "A version string, not checked against
semver. Setting it pins the plugin to that version until you change it";
local-directory plugins "loaded in place" are not pinned by it. Auto-update
is "On by default" for official marketplaces and "Off by default" for
"every other marketplace". Manual: `claude plugin update
<plugin>@<marketplace>`. A running session "keeps the versions it already
loaded". <https://code.claude.com/docs/en/plugins-reference> and
<https://code.claude.com/docs/en/discover-plugins>, accessed 2026-09-27,
no page date.

F6. **OpenCode npm plugins install into a user cache at startup.** "npm
plugins are installed automatically using Bun at startup. Packages and
their dependencies are cached in `~/.cache/opencode/node_modules/`."
Config lists package names (`"plugin": ["opencode-wakatime", ...]`). The
page shows no version-pin syntax (**weak**: absence). Extends 01-F5.
<https://opencode.ai/docs/plugins/>, accessed 2026-09-27, no page date.

F7. **rulesync and ruler are global CLIs run from npm.** rulesync:
`npm install -g rulesync` (also Homebrew or an install script), then
`rulesync init`, `rulesync generate`. ruler: `npm install -g
@intellectronica/ruler` or `npx @intellectronica/ruler apply`. Neither
README describes a per-project version record (**weak**: absence).
<https://github.com/dyoshikawa/rulesync> and
<https://github.com/intellectronica/ruler> (READMEs), accessed 2026-09-27,
no release date. Secondary. Extends 02-F26 and 02-F27.

F8. **PowerShell Gallery (PSResourceGet) installs side by side, never
removes old versions, and pins by version range.** `Update-PSResource`:
"The new version of the resource is installed side-by-side with previous
versions ... There is no command to uninstall older versions of a
package." `Install-PSResource -Version` takes "an exact version or a
version range using the NuGet versioning syntax", and
`-RequiredResourceFile myRequiredModules.psd1` installs a pinned set.
Default scope `CurrentUser` needs no elevation.
<https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.psresourceget/update-psresource>
and `.../install-psresource`, page date 2025-12-10, accessed 2026-09-27.

### Update and merge (sub-question 2)

F9. **Copier's update is a three-way merge against a regenerated old
version.** It "regenerates a fresh project from the current template
version", diffs that against the current project, updates to the new
version, then "re-applies the previously obtained diff". On a hunk it
cannot place: `--conflict inline` (default) writes git-style markers;
`--conflict rej` writes "a separate `.rej` file for each file with
conflicts". It needs a clean `git status` and recommends a pre-commit hook
that rejects markers or `.rej` files. Extends 01-F13. Same updating page
as F2.

F10. **Copier treats a deleted file as a user decision.** "Template-based
files/directories that were deleted in the generated project are
automatically excluded from updates", except `skip_if_exists` paths, whose
"presence is always ensured". `skip_if_exists` files are created once and
never overwritten. `copier recopy` reapplies the template, keeping answers
but "The new template will override any changes found in your local
project". Same updating page; `skip_if_exists` from the configuring page.

F11. **cruft shows the update for review and honours a skip list.** "If
there are any updates, cruft will have you review them before applying";
accepting "update[s] the `.cruft.json` file". Paths in `skip` are never
updated. Its CI example opens one PR to accept and one to reject an
update. Same README as F3. Secondary.

F12. **ruler uses a managed block for `.gitignore` and `.bak` backups for
files it writes.** The block is marked `# START Ruler Generated Files` /
`# END Ruler Generated Files` and ruler "Preserves existing content outside
this block". `--backup` (default on) creates `.bak` files; `ruler revert`
restores them "or removes generated files that didn't exist before", with
`--dry-run`. Its CI example fails when committed agent files are out of
sync with `.ruler/`. Same README as F7. Secondary.

F13. **`git merge-file` is the stock three-way merge for one file.**
`git merge-file <current> <base> <other>` "incorporates all changes that
lead from <base> to <other> into <current>"; conflicts get `<<<<<<<` /
`>>>>>>>` markers; `--ours`, `--theirs`, `--union` resolve instead. "The
exit value ... is negative on error, and the number of conflicts
otherwise"; `-p` writes to stdout. Git is already a kit prerequisite.
<https://git-scm.com/docs/git-merge-file>, accessed 2026-09-27, no page
date.

### Adoption, migrations and removal (sub-questions 4 and 5)

F14. **Adopting existing config: import or improve in place.** rulesync
has `rulesync import --targets claudecode` ("From CLAUDE.md") to pull
existing files into its source directory (F7 page). OpenCode `/init`
"will improve [an existing AGENTS.md] in place instead of blindly replacing
it" (06-F6). cruft has `cruft link TEMPLATE_REPOSITORY` to attach an
existing project to its template (F3 page). Copier `copy` into an existing
directory has `--overwrite` ("Overwrite files that already exist, without
asking"; default False; configuring page, F1); that it asks otherwise is
inferred from the wording.

F15. **Copier migrations run commands by version window.** Each migration
has a `command`, an optional `version` and `when`; with a version, it runs
only "when new version >= declared version > old version", in declared
order, and "only when updating (not when copying for the 1st time)". They
get `$STAGE` (`before` or `after`), `$VERSION_FROM` and `$VERSION_TO`.
Configuring page (F1).

F16. **Uninstall across tools.** Claude: `claude plugin uninstall`, and
removing a marketplace "uninstalls every plugin you installed from it"
(F4 page). ruler: `ruler revert` (F12). PSResourceGet: no command removes
old versions (F8). No uninstall command appears in the fetched copier or
cruft pages (**weak**: absence); both leave files in the user's git
history.

### Current kit (local analysis, sub-question 6; verified by reading and the throwaway init)

F17. **The kit is a hash-manifest updater with managed blocks.**
`Sync-SwProject` (`product/lib/Sw.Kit.psm1`) renders every kit file, then
per file: `add` (missing), `same` (current = new), `update` (current =
manifest hash), `skip-modified` (known, edited), `adopt` (unknown, with
`-Adopt`, backed up to `.sw/backup/<stamp>/`), `conflict` (unknown, aborts
the whole run before writing). Files dropped from the kit: `remove`
(unedited), `orphan-kept` (edited), `gone`. `AGENTS.md`, `.gitignore` and
`.gitattributes` get `Set-SwBlock` managed blocks instead. The manifest
stores `kitVersion` and one SHA-256 per file, and is committed.

F18. **`kitVersion` is written and never read.** No code compares it, so
an older kit clone can run `update` and silently downgrade a project, and
`0.3.0-dev` names no exact commit. `README.md` installs the kit by
`git clone`; a user gets a newer kit by pulling that clone.

F19. **`skip-modified` fires even when the kit did not change the file.**
Observed: after one appended line in `.sw/workspace.md` and an unchanged
kit, `update` printed `skip-modified .sw/workspace.md` and "diff them
against the kit and merge by hand". The manifest's old hash equals the new
hash in that case, so there is nothing to merge. When the kit *did* change
the file, the user gets no copy of the new version and no base to diff
against: the manifest stores hashes, not content.

F20. **The `-Adopt` gap reproduces and `validate` passes over it.** With a
pre-existing `AGENTS.md`, `Sync-SwProject` only appends the `core` and
`profile` blocks; the template's `## Project identity` and
`## Architecture invariants` sections are used only when no `AGENTS.md`
exists. The result's core block says "Read the project state file named in
Project identity", which does not exist, and `validate` printed `PASS`.
This happens with or without `-Adopt` (`-Adopt` affects kit files only).

F21. **Docs vs code.** `.sw/workspace.md` "Claude adapter" says
"Regenerate after `sw update`", but `Update-SwProject` already regenerates
when `.claude/.sw-generated` exists (manual step needed only when that
marker is missing). `claude enable` backs up non-generated files to
`.sw/backup/` and removes stale files carrying the generated marker;
`claude disable` removes only files still equal to generated content.
There is no `uninstall` for the project files, and a renamed managed block
would leave the old block behind. Other statements checked
(`decisions.md` "managed blocks, nothing in a database"; workspace.md
"`sw update` will skip your modified copy") match the code.

F22. **02 option b under today's `update`.** Moving
`product/project/base/.opencode/skills/*` to `.agents/skills/*` would make
each unedited old skill `remove` and each new one `add`. An edited old
skill becomes `orphan-kept` and an unedited copy is added under
`.agents/skills`, so the user's edit survives but OpenCode then sees both
directories (the duplicate-name issue 02 flagged) and the edit is not in
the file the kit now owns. Code that names `.opencode/skills`:
`Get-SwClaudeFiles` (`Sw.Project.psm1` line 455) and one test
(`tests/Sw.Tests.ps1` line 261).

## 3. Options compared

### Update strategy for kit-owned files

| Strategy | Keeps user edits by | On conflict | Needs | Kit today |
|---|---|---|---|---|
| a. Hash manifest (today) | not touching edited files | skip and report (`skip-modified`) | hashes only | yes (F17) |
| b. Hash manifest + incoming copy | as a, plus writing the new version aside | user diffs two files | nothing new | no |
| c. Three-way merge (`git merge-file`) | merging kit change into edited file | inline markers, count as exit code (F13) | the old rendered base per file | no |
| d. Full regenerate-and-diff (copier) | replaying the user diff on the new version | inline or `.rej` (F9) | git-tagged kit, clean tree, old kit render | no |
| e. Managed blocks | owning only a marked region | none; block replaced whole (F12) | markers in the file | yes, 3 files |
| f. Plugin/cache install | not writing into the project at all | none | harness plugin system (F4, F6) | no (01 decided) |

Option c needs a base. Two ways to get one: store the rendered content
(`.sw/base/`, roughly doubling kit files in the repo), or record the kit
commit and re-render the old version from the kit clone (copier's model,
F9; fails if the clone lacks that commit).

### Version record

| Record | Reproducible? | Detects downgrade? | Cost |
|---|---|---|---|
| `kitVersion` only (today) | no, `-dev` is ambiguous | no (F18) | none |
| `kitVersion` + kit commit SHA | yes, from the clone | yes, if compared | one field, one `git rev-parse` |
| Answers file (copier `_commit`, F1) | yes | via `check-update` (F2) | the kit already has `.sw/config.json` for answers |

### Distribution

| Route | Pin | Get newer | Fit |
|---|---|---|---|
| git clone (today) | none recorded | `git pull` | works; no pin |
| git clone + tag checkout | tag, like copier (F1) | `git fetch; git checkout vX` | no code; needs release tags |
| PowerShell Gallery | version range, `RequiredResourceFile` (F8) | `Update-PSResource`, old versions linger | needs a module manifest and publishing; a GitHub write, owner-only |
| Claude plugin / npm | `version`, `#ref` (F4-F6) | auto or manual update | cache install; covers one harness each; conflicts with committed files |

## 4. Recommendation

R1. **Keep the hash manifest plus managed blocks.** It already has the
same safety properties as copier's deleted-path rule and cruft's skip list
(F10, F11) without a git-clean precondition or a template engine. Do not
adopt copier-style regenerate-and-diff (option d) or plugin distribution
(option f).

R2. **Record the exact kit and refuse silent downgrades.** Add
`kitCommit` (`git -C <kit> rev-parse HEAD`, or `null` outside a git
clone) to the manifest. In `Sync-SwProject`, if the manifest's
`kitVersion` is newer than the running kit, stop unless `-Force`. Print
"kit A -> B" in `Format-SwPlan`. Two collaborators on different kit
versions: the committed manifest shows who is behind; the rule for who
runs `update` belongs to topic 10.

R3. **Split `skip-modified` and hand the user the incoming version.** When
the kit did not change the file (new hash = manifest hash), report
`kept-local` with no "merge by hand" line (F19). When it did, write the
new rendered file to `.sw/backup/<stamp>/incoming/<path>` and print one
`git diff --no-index <path> <incoming>` line (option b). This is the
laziest fix and needs no base. Three-way merge (option c) waits until
hand merges are shown to be a real cost; `git merge-file` (F13) is the
primitive when it does.

R4. **Fix the `-Adopt` gap in `Sync-SwProject`.** When an existing
`AGENTS.md` has no `## Project identity` heading, insert the template's
project sections (the text between the title and `sw:begin core`) before
the core block, and print "fill Project identity". Never touch existing
text, matching `/init` improving in place (F14). A `validate` check for
the heading belongs to topic 9.

R5. **Add a rename map instead of general migrations.** A kit-side
`moved` table (`old -> new`) in `Sync-SwProject`: unedited old file moves
(`remove` + `add`); an edited old file is *moved with its edit* and marked
`skip-modified` so R3 applies. That covers renames without copier-style
command migrations (F15), which would run arbitrary code in user projects.
No uninstall command yet (F16): `claude disable` plus `git` history cover
removal; add one when someone asks.

R6. **Distribution: tag releases; no gallery yet.** Tag `product/VERSION`
releases in git and document `git checkout v<version>` in the kit clone as
the pin. With R2 the manifest records what was used. The PowerShell
Gallery (F8) adds a publish step and side-by-side installs for no current
user; revisit if the kit gains users outside the owner's machines.

R7. **Verdict on 02 option b: feasible, do it only with R5.** Under
today's `update`, the move keeps user edits but strands them in
`.opencode/skills` beside a fresh `.agents/skills` copy (F22). With R5's
rename map the move is clean: edited skills move with their edits. Cost:
the map (about 10 lines and one test), two path changes (F22), a
`decisions.md` entry reversing part of "OpenCode is canonical", and a
`VERSION`/`CHANGELOG` entry. Benefit arrives only when a Codex, Gemini,
Cursor or Copilot user exists (02 R2). Owner decision 2026-09-27: planned
as next-phase work, R5's rename map first, then the move; universality is
the project goal, so it does not wait for a named user.

Mapping onto the kit:
- `product/lib/Sw.Kit.psm1`: `Sync-SwProject` (R2, R3, R4, R5),
  `Format-SwPlan` (R2, R3).
- `.sw/manifest.json` format: `kitCommit` (R2).
- `.sw/workspace.md` "Claude adapter": say `update` regenerates when the
  adapter is enabled (F21).
- `tests/Sw.Tests.ps1`: downgrade refusal, `kept-local`, adopt headings,
  rename map.
- `product/VERSION` minor bump and a `product/CHANGELOG.md` entry: all of
  the above reach installed projects through `update`.
- Release tags: human action, not kit code.

## 5. Open questions

Owner answers recorded 2026-09-27 (relayed by the Leader).

1. Owner: adopt R2's downgrade refusal (stop unless `-Force`), or only
   warn?
   **Answer:** refuse a downgrade unless `-Force`.
2. Owner: R3 option b (incoming copy under `.sw/backup/`), or go straight
   to three-way merge with a stored base (option c)?
   **Answer:** option b (an incoming copy, plus `kept-local`).
3. Owner: R4 inserts stub project sections into an existing `AGENTS.md`.
   Acceptable, or print instructions only and leave the file alone?
   **Answer:** R4 inserts stub sections.
4. Owner: R6, start tagging releases in git now?
   **Answer:** yes, start tagging releases.
5. Owner: R7, move skills to `.agents/skills` with the rename map, or
   defer until a non-Claude, non-OpenCode user exists?
   **Answer:** plan the rename map and the skills move as next-phase work;
   universality is the project goal (roadmap standing rule), so it does
   not wait for a named user.
6. Not verified: Claude's plugin loading page (update timing), cruft
   conflict output, rulesync and OpenCode version pinning (Not covered).
   **Answer:** open.
7. Budget report: 13 research calls (13 page fetches with `curl`, no web
   searches, none failed), cap 25. Total tool calls about 35, including
   prior-research reads, kit code reads, text extraction from saved pages,
   the throwaway init and validation. Dropped: Claude plugin loading page,
   rulesync docs site, npm lockfile docs.
8. Fetched pages contained no text directed at this task. The Claude `.md`
   pages carry a generic documentation-index line for readers.

## 6. Supersedes / updates

None superseded. Extends 01-F13 (copier) with conflict modes, deleted
paths and migrations (F9, F10, F15), and 01-F5, 01-F12, 02-F26, 02-F27
with install and update facts (F4-F7, F12). Gives the topic-7 verdict on
02 option b (R7). Answers the roadmap input "`-Adopt` gap" (R4).
