# 06: Upkeep and memory

Status: complete; reviewed by the owner 2026-09-27; R1-R6 adopted (R2 option c, R5 option A).
Researched 2026-09-26 (local) by `project-research` (research-6, Claude Opus 5.5
via Claude Code 2.1.282, desktop app, native Windows). All sources accessed
2026-09-27 between 03:25Z and 03:28Z; page dates are given where the page
showed one. Raw page text was saved with `curl` to the session scratchpad
(outside the repo). Claude pages were fetched as their `.md` sources; HTML
pages were stripped to text. Every finding was re-checked against that text.
No finding is summary-based. Findings that rest on an *absence* in the
fetched text are marked **weak**.

## 1. Question and scope

How do harnesses remember things across sessions, how do comparable
projects keep agent instructions and records accurate over time, and what
upkeep should SuperWorkspace build in?

Sub-questions:
1. Harness memory in Claude Code, OpenCode and Codex: what persists, where,
   at what scope, whether it is shared, and privacy notes.
2. Instruction upkeep: vendor guidance on keeping AGENTS.md, CLAUDE.md and
   skills current; precedents for dating and expiring facts; evidence that
   stale instructions cause errors.
3. Records and logs: keeping durable logs useful without unbounded growth;
   what a task record holds and when it is summarised.
4. Memory versus repository versus the user overlay (01 R1).
5. Local analysis: record bloat from the "Checked revision / changed" line;
   the `close` and archive flow; the `agent-documentation` and
   `task-handoff` skills; the dated style of `free-models`.
6. Recommendation mapped onto the kit.

Out of scope (one line each):
- Context budgets (topic 4, done): memory load size is cited from 04-F5 only.
- Validation lint and evaluation (topic 9): R5's rule is text; enforcing it is topic 9.
- Multi-user collaboration and branch models (topic 10).
- Install and update (topic 7).

Not covered:
- OpenCode local session storage (where transcripts live, retention). The
  rules and share pages do not say; no storage page was fetched.
- OpenCode memory. The rules page describes AGENTS.md, global rules and
  `instructions` only (**weak**: absence).
- Claude subagent `memory:` frontmatter. The memory page names it; the
  sub-agents page section was not re-fetched (05 fetched that page for
  other facts).
- `cleanupPeriodDays` detail. The settings page fetched does not contain
  it; the data-usage page gives the default (F4).
- Direct evidence that *stale* instructions cause errors. None found (F10).

## 2. Findings

Findings from topics 0-5 are cited as `0N-F<n>` or `0N R<n>`.

### Harness memory (sub-question 1)

F1. **Claude Code has two memory systems: CLAUDE.md (you write) and auto
memory (Claude writes).** Scope: CLAUDE.md is "Project, user, or org"; auto
memory is "Per repository, shared across worktrees". Both load every
session, auto memory as its "first 200 lines or 25KB" (04-F5). "Claude
treats them as context, not enforced configuration. To block an action ...
use a PreToolUse hook". Auto memory saves four types, `user`, `feedback`,
`project` and `reference`, and "skips anything it can derive from the
codebase ... It also skips anything your CLAUDE.md files already say".
Asking Claude to "remember" something writes auto memory; "To add
instructions to CLAUDE.md instead, ask Claude directly".
<https://code.claude.com/docs/en/memory>, accessed 2026-09-27, no page date.

F2. **Claude auto memory is machine-local, on by default, and exempt from
transcript cleanup.** "Each project gets its own memory directory at
`~/.claude/projects/<project>/memory/`", derived from the git repository.
"Auto memory is machine-local ... Files are not shared across machines or
cloud environments." It is on by default; `autoMemoryEnabled: false` (user
or project settings) or `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` turns it off,
and `autoMemoryDirectory` moves it. Transcripts are deleted after
`cleanupPeriodDays`, but memory files are excluded: they "stay until you or
Claude edits or deletes them". Same page as F1.

F3. **Claude auto memory prunes its own index; the main session's memory
does not reach subagents.** Near the limit, Claude Code reminds Claude to
"keep one line per entry, move detail into topic files, and merge or drop
stale entries"; over the limit "the write still succeeds" but returns an
error, "because everything past the limit is dropped on the next load".
Topic files load on demand. "The main conversation's auto memory isn't
loaded into subagents"; forks are the exception. Same page as F1.

F4. **Claude transcripts: plaintext, local, 30 days by default.** "Claude
Code clients store session transcripts locally in plaintext under
`~/.claude/projects/` for 30 days by default ... Adjust the period with
`cleanupPeriodDays`." Transcripts from Claude Desktop or Cowork sessions
are "exempt from that limit by default". Transcripts sent with `/feedback`,
`/bug` or `/share` "are retained for 5 years".
<https://code.claude.com/docs/en/data-usage>, accessed 2026-09-27, no page
date.

F5. **Claude private project instructions: `CLAUDE.local.md`, gitignored,
per worktree.** "For private per-project preferences that shouldn't be
checked into version control, create a `CLAUDE.local.md` ... Add
`CLAUDE.local.md` to your `.gitignore`." It "only exists in the worktree
where you created it"; to share across worktrees, import a home-directory
file. Same page as F1.

F6. **OpenCode: no memory feature found; `/init` writes AGENTS.md; global
rules are personal.** "`/init` scans the important files in your repo, may
ask a couple of targeted questions ... and then creates or updates
`AGENTS.md`." "If you already have an `AGENTS.md`, `/init` will improve it
in place instead of blindly replacing it." "You should commit your
project's `AGENTS.md` file to Git." Global rules live in
`~/.config/opencode/AGENTS.md`: "Since this isn't committed to Git or shared
with your team, we recommend using this to specify any personal rules".
<https://opencode.ai/docs/rules/>, page date 2026-09-26, accessed
2026-09-27. **Weak** on "no memory": absence from this page.

F7. **OpenCode sharing uploads a session and keeps it until unshared.**
Sharing "Creates a unique public URL for your session" and "Syncs your
conversation history to our servers". Manual is the default; auto-share
and disabled are options. "Shared conversations remain accessible until you
explicitly unshare them." Recommendations include "For sensitive projects,
disable sharing entirely." <https://opencode.ai/docs/share/>, accessed
2026-09-27, no page date read.

F8. **Codex: local memories are off by default, generated state, and a
recall layer only.** "Keep required team guidance in `AGENTS.md` or
checked-in documentation. Treat memories as a helpful recall layer, not as
the only source for rules that must always apply." Memories live under
`~/.codex/memories/`; "Treat these files as generated state ... don't rely
on editing them by hand as your primary control surface." Codex "redacts
secrets from generated memory fields" but "Don't store secrets in memories".
"Local Codex memories are off by default." `/memories` controls per chat.
<https://developers.openai.com/codex/customization/memories>, accessed
2026-09-27, no page date. Codex instructions: `~/.codex/AGENTS.md` (global),
repository AGENTS.md files concatenated root-down, `AGENTS.override.md` "for
a temporary global override", `project_doc_max_bytes` "32 KiB by default".
<https://developers.openai.com/codex/guides/agents-md>, accessed
2026-09-27, no page date.

### Instruction upkeep (sub-question 2)

F9. **Vendors say: review and prune instruction files; they give no
cadence.** Claude: "Treat CLAUDE.md like code: review it when things go
wrong, prune it regularly, and test changes by observing whether Claude's
behavior actually shifts." "Bloated CLAUDE.md files cause Claude to ignore
your actual instructions!" "Check CLAUDE.md into git so your team can
contribute." <https://code.claude.com/docs/en/best-practices>, accessed
2026-09-27, no page date. The memory page adds: "if two rules contradict
each other, Claude may pick one arbitrarily. Review ... periodically to
remove outdated or conflicting instructions" (F1's page). agents.md: "Treat
AGENTS.md as living documentation." <https://agents.md/>, accessed
2026-09-27, no page date. OpenCode and Claude `/init` update in place (F6,
F1's page). Vendor guidance; no cadence, no study cited. **Weak** on "no
cadence": absence.

F10. **Anthropic's skill guidance: avoid time-sensitive facts; move old
ones to an "Old patterns" section.** "Don't include information that will
become outdated". The bad example is "If you're doing this before August
2025, use the old API"; the good one keeps a "Current method" section and
puts the old way under "Old patterns" in a collapsed
`<summary>Legacy v1 API (deprecated 2025-08)</summary>`. The checklist
item: "No time-sensitive information (or in "old patterns" section)". It
also says to "Create evaluations BEFORE writing extensive documentation"
and "Iterate based on observations rather than assumptions".
<https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices>,
accessed 2026-09-27, no page date. No fetched source uses "last verified"
or expiry dates in agent-facing files (**weak**: absence across F6, F8-F10).

F11. **Secondary (one paper): context files are followed but rarely help,
at over 20% cost.** "providing context files does not generally improve
task success rates, while increasing inference cost by over 20% on
average"; "instructions in the context files are well followed by coding
agents"; "repository overviews ... are not helpful"; context files "are
useful for specifying non-standard coding practices". Gloaguen, Mündler,
Müller, Raychev, Vechev,
[arXiv:2602.11988](https://arxiv.org/abs/2602.11988), 2026-02-12, accessed
2026-09-27; abstract only read. It does not test stale instructions. That
a stale instruction is therefore *also* followed is my inference, not the
paper's finding.

F12. **Local: the kit already has one proven staleness case.** 03-F13: the
`free-models` skill named a free GLM 5.2 endpoint that was paid within
days. The skill marks observations "Observed 2026-09" (month only), says
"re-verify per machine", and has no expiry or removal rule. It still ships
those lines (read 2026-09-27, `.opencode/skills/free-models/SKILL.md`).
No record shows an agent acting on the stale line, so there is no local
error evidence either.

### Records and logs (sub-question 3)

F13. **Changelogs: curated for humans, not git-log dumps.** "A changelog is
a file which contains a curated, chronologically ordered list of notable
changes for each version". "Using commit log diffs as changelogs is a bad
idea: they're full of noise." An `[Unreleased]` section gathers changes
before release. <https://keepachangelog.com/en/1.1.0/>, version 1.1.1
entry dated 2023-03-05, accessed 2026-09-27. Secondary (community
convention).

F14. **ADRs: append-only, superseded not deleted, short.** "Numbers will not
be reused. If a decision is reversed, we will keep the old one around, but
mark it as superseded." A status of "deprecated" or "superseded" carries "a
reference to its replacement". "The whole document should be one or two
pages long."
[Nygard, "Documenting Architecture Decisions"](https://www.cognitect.com/blog/2011/11/15/documenting-architecture-decisions),
2011-11-15, accessed 2026-09-27. adr.github.io calls the collection a
"decision log" (<https://adr.github.io/>, accessed 2026-09-27). Secondary.
The kit's `docs/decisions.md` already follows this shape (dated, status,
newest first).

F15. **Harness transcripts are not a durable log.** Claude deletes them
after 30 days by default (F4); OpenCode's are not covered; shared ones
persist on a vendor server (F4, F7). A record that must outlive the session
therefore has to be self-sufficient in the repository. This is my
inference from F4 and F7.

### Local analysis (sub-question 5)

F16. **Local: the "Checked revision / changed" line is 14% of archived
records, and almost all of it is the records describing themselves.**
`Invoke-SwComms event` writes `git status --porcelain` joined with `; `
(`product/lib/Sw.Project.psm1` lines 603 and 614). Measured on 2026-09-27
over `.sw/comms/archive/*/events/*.md`: 34 events, 99,926 bytes; that line
is 13,990 bytes (14%). For p0-research-01 to 05 (30 events, 84,859 bytes)
it is 8,223 bytes (9.7%), and 74 of the 77 dirty entries are `.sw/comms/`
paths: the previous task's archive move and this task's own folder. The
worst line is 5,426 bytes, 70 entries, in the p0-researcher-revision
worker submission. Submission lines written by the tool run 655-661 bytes;
Leader-written event lines run 76-273.

F17. **Local: `close` writes less than `.sw/collaboration.md` promises.**
The doc says `close` writes "SUMMARY.md (outcome, final SHA, decisions,
open follow-ups)". The code (lines 625-641) writes the `-Outcome` text,
the closer, the HEAD SHA and a list of event file names. Decisions and
follow-ups appear only if the closer puts them in `-Outcome`, as the
p0-research-05 summary does ("R1-R7 adopted, R7 minimal"). Agents "read the
summary, not the old events" (collaboration.md), so the summary bounds
context cost; each research task's events add about 17 KB to the repository
(84,859 bytes over 5 tasks). Records are committed (`git ls-files
.sw/comms` lists 44 files).

F18. **Local: the skills already forbid a second memory.** `task-handoff`:
"Keep execution details there rather than creating a parallel memory or
TODO ledger." `agent-documentation`: "Avoid hand-maintained live SHA
inventories and duplicate memory or status ledgers" and "Preserve dated
evidence; add a correction event rather than rewriting another author."
`.sw/collaboration.md` "Task events": "no second plan, memory, or TODO
hierarchy". None says what harness memory *is* for, and none has a rule for
dating volatile facts. Read 2026-09-27.

F19. **Local: the owner's Claude memory folder (structure only).** One
`MEMORY.md` index (168 bytes, one line) and one `project`-type topic file
(2,302 bytes), far under the 200-line/25 KB limit (F3). The entry's index
line says it tracks roadmap state, which `docs/roadmap.md` owns. No content
quoted. Read 2026-09-27. On 2026-09-27 the entry was trimmed to a pointer
(owner decision, done by the Leader).

## 3. Options compared

### Where a fact lives (sub-question 4)

| Kind of fact | Committed repo (AGENTS.md, skills, records) | User overlay `rules.local.md` (01 R1) | Harness memory (F1-F3, F8) |
|---|---|---|---|
| Team rules, workflow, commands | yes: shared, reviewed (F6, F8, F9) | no | no: machine-local, not shared (F2, F8) |
| Task state and evidence | yes: `.sw/comms/tasks/` (F18) | no | no: transcripts expire (F4); memory is not the record (F8) |
| Personal preferences across projects | no | yes: survives kit updates | acceptable duplicate; harness-specific |
| Corrections learned in one repo on one machine | only if the team needs them | if personal | yes: this is its designed use (F1) |
| Secrets, credentials | never | never | never (F8) |

Trade-offs: committed files are shared and reviewable but cost every
session's context (04-F5, F11). Harness memory is free to write but
invisible to teammates, other harnesses and other machines (F2, F8), and it
is plaintext in the profile (F4). The overlay is portable across harnesses
but personal.

### Record bloat (sub-question 5)

| Option | Change | Effect on measured data |
|---|---|---|
| a. Keep as is | none | 14% of records; grows with every uncommitted file |
| b. Exclude `.sw/comms/` paths | filter the porcelain list | removes 74 of 77 entries in p0-research-01 to 05 |
| c. b plus a cap of 10 entries, then `(+N more)` | filter and truncate | bounds the worst case (70 entries) to about 10 lines' worth |
| d. Count only (`plus N uncommitted paths`) | replace the list | smallest; loses which paths were dirty, which `task-handoff` asks for ("explicit uncommitted draft and its affected paths") |

### Archive growth (sub-question 3)

| Option | Effect |
|---|---|
| i. Keep events beside SUMMARY (today) | context bounded by the summary; repo grows about 17 KB per task (F17) |
| ii. Delete `events/` on close, rely on Git history | smaller tree; but uncommitted events would be lost, and the kit never discards work |
| iii. Summary carries decisions and follow-ups (F17) | makes the summary the self-sufficient record F15 calls for |

### Dated facts in shipped skills (sub-question 2)

| Option | Precedent | Cost |
|---|---|---|
| A. Ship procedure, not snapshot: volatile facts (IDs, prices, endpoints, levels) stay in dated research files | F10 "avoid time-sensitive information" | `free-models` loses its per-model list |
| B. Keep snapshots, each dated `Observed YYYY-MM-DD`, re-verified or moved to "Old observations" at each release | F10 "Old patterns", F14 superseded-not-deleted | a release step; still stale between releases (F12) |
| C. Expiry dates enforced by `validate` | none found (F10 weak) | a lint; topic 9 |

## 4. Recommendation

R1. **The kit does not use harness memory and does not advise turning it
off.** Nothing the kit relies on may live in harness memory, because it is
machine-local, unshared and harness-specific (F2, F8). Codex's own docs say
the same (F8). Turning memory off is the user's choice, not kit policy.
Product form: extend the existing sentence in `.sw/collaboration.md` "Task
events" ("no second plan, memory, or TODO hierarchy") with: "Harness memory
(Claude auto memory, Codex memories) is machine-local recall; anything the
team or a later session needs goes in a task record or a committed file."
About 150 bytes, outside startup context. The Claude generator keeps
emitting no `memory:` field (Not covered: not re-fetched).

R2. **Bound the "changed" line: option c.** In `Invoke-SwComms event`,
drop porcelain entries under `.sw/comms/` and keep at most 10, then append
`(+N more)`. On the measured records this removes 96% of entries (74 of
77) and caps the worst line. It keeps the paths `task-handoff` asks for.
One pipeline change near line 603; one Pester case (topic 9 owns any wider
lint). Needs a `VERSION` bump and a `CHANGELOG` entry.

R3. **Make the summary the self-sufficient record: fix the doc, not the
code.** `.sw/collaboration.md` "Closing" should say `-Outcome` must carry
the outcome, decisions and open follow-ups, matching what the code writes
(F17) and what the Leader already does. No new parameter. Keep events
(option i): the kit never discards work, and Git history is not a
substitute for uncommitted events. Transcripts expire (F4), so the summary
is the only durable digest (F15).

R4. **Skills: one line each.**
- `task-handoff`: under "Record the execution state", add "Write the record
  so it stands without the session transcript; harness transcripts
  expire." (F4, F15)
- `agent-documentation`: under "Write for the next task", add "Date every
  volatile fact (`Observed YYYY-MM-DD`) and keep it out of instructions
  when a procedure can replace it." (F10, F12)
- `free-models`: see R5.

R5. **Staleness rule for shipped skills: option A (adopted).** A shipped
skill states procedures and hard constraints; model IDs, prices, endpoints
and effort levels go in dated research files (03 already holds them). For
`free-models`, option A is adopted: the skill keeps the procedure and hard
constraints, and its "Options per model" list moves to dated research;
this resolves 03-F13. Option B stays only as the rule for any future skill
that must hold a snapshot: each line carries a full `Observed YYYY-MM-DD`
date and a re-verify step, and at each `VERSION` bump any snapshot not
re-verified moves to an "Old observations" section or is removed (F10's
"Old patterns", F14). Enforcement by `validate` is topic 9.

R6. **Instruction upkeep: no scheduled review; review on evidence.** No
vendor gives a cadence (F9). The kit already keeps startup small (04) and
F11 says context files mostly help with non-standard practices. The
trigger to review AGENTS.md or a role body is a recorded failure (a review
or correction event that names the instruction), matching Claude's "review
it when things go wrong". Nothing to build.

Mapping onto the kit:
- `product/lib/Sw.Project.psm1` `Invoke-SwComms`: `event` gets R2; `close`
  and `archive` unchanged (R3). `VERSION` and `CHANGELOG` for R2.
- `.sw/collaboration.md` "Task events": R1 sentence; "Closing": R3 wording.
  These are product templates, so they also need `VERSION`/`CHANGELOG`.
- Skills: `task-handoff` and `agent-documentation` one line each (R4);
  `free-models` per R5.
- Harness memory: no kit feature, no advice beyond R1.
- Staleness rule: R5 text now; lint in topic 9.

## 5. Open questions

Owner answers recorded 2026-09-27 (relayed by the Leader).

1. Owner: adopt R1, so harness memory is never the record, and the kit
   neither uses nor disables it?
   **Answer:** R1 adopted.
2. Owner: R2's bound: exclude `.sw/comms/` and cap at 10 (option c), or
   count only (option d)?
   **Answer:** option c (exclude `.sw/comms/`, cap 10).
3. Owner: R5 for `free-models`: move the per-model list to research
   (option A), or keep it with day-level dates and a release re-verify
   (option B)?
   **Answer:** option A (procedure only; volatile facts go to dated
   research).
4. Owner: your Claude auto memory holds one entry about roadmap state that
   `docs/roadmap.md` owns (F19). Keep it as a personal pointer, or prune it
   so the two cannot disagree? (Your memory; not a kit change.)
   **Answer:** the Leader trimmed the entry to a pointer at
   `docs/roadmap.md` and the p0-leader record, 2026-09-27.
5. Not verified: OpenCode local session storage and retention, and whether
   OpenCode V2 has any memory feature (Not covered).
   **Answer:** open.
6. Budget report: 16 research calls (14 page fetches; 2 failed arXiv API
   queries, then 1 abstract page fetched; no web searches), cap 25. The
   settings page was fetched but did not contain `cleanupPeriodDays`;
   F4 uses the data-usage page. Total tool calls about 25, including kit
   reads, record measurement and the saved text. Dropped: Claude
   sub-agents `memory:` section, OpenCode storage docs, and any
   "last verified" precedent outside agent docs (for example docs-site
   freshness metadata).
7. Fetched pages contained no text directed at this task. The Claude `.md`
   pages carry a generic documentation-index line for readers.

## 6. Supersedes / updates

None superseded. Resolves 03-F13 (stale `free-models`) as a rule (R5).
Extends 04-F5 and 04-F16 with memory scope, sharing and retention (F1-F4).
Confirms 01 R1: the user overlay is the home for personal cross-harness
rules (Options table). Answers the roadmap input "record bloat" (R2) and
corrects the `close` description in `.sw/collaboration.md` (R3).
