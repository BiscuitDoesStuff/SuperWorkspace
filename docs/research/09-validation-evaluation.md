# 09: Validation and evaluation of agent workspaces

Status: complete; reviewed by the owner 2026-09-27; R1-R8 adopted (R3 as a warning, shipped; R7 after the rewrite; R8 practice only).
Researched 2026-09-26 (local) by `project-research` (research-9, Claude Opus 5.5
via Claude Code 2.1.282, desktop app, native Windows). All sources accessed
2026-09-27 between 04:24Z and 04:27Z; page dates are given where the page
showed one. Raw page text was saved with `curl` to the session scratchpad
(outside the repo). Claude and OpenAI pages were fetched as their `.md`
sources; HTML pages were stripped to text; the two JSON schemas were saved
as JSON. Every finding was re-checked against that text. No finding is
summary-based. Findings that rest on an *absence* in the fetched text are
marked **weak**. Kit code was read at `2676728`. Local experiments ran only
static commands (`--help`, `claude plugin validate`, `Test-Json`, a Python
scan of `docs/research/`); no agent was run against any model.

## 1. Question and scope

How do vendors and comparable projects validate agent instructions, skills
and permission setups, statically and at runtime, cheaply, and what should
SuperWorkspace's `validate`, tests and CI check?

Sub-questions:
1. Evaluating instructions and skills: vendor guidance and tools, headless
   runs, transcript or output assertions, LLM-as-judge limits.
2. Static validation of the formats the kit ships.
3. Runtime permission checks: headless, free, compared with the static
   matrix (08-F28).
4. CI: deterministic versus model-in-the-loop checks, secrets, cost.
5. Local: what `tests/Sw.Tests.ps1` and `Test-SwProject` cover and miss;
   map each carried input to a check and an owner file.
6. Recommendation: `validate`, Pester, CI, or manual/runtime-only.

Carried inputs (from `docs/roadmap.md` and topics 3-8): research lint;
`## Project identity` check (07 R4); tests for the frontmatter-owned
subagent flag (05 R7); staleness lint for shipped skills (06 R5, option C
in the 06 options table); Claude checks beyond the byte comparison
(08-F28); static matrix versus runtime OpenCode, and the V1 `$schema`
(03-F20); "create evaluations before documentation" (06-F10).

Out of scope, one line each: multi-user and branch models (topic 10);
permission design (topic 8, done); lifecycle (topic 7, done).

Not covered:
- Markdown lint tools (markdownlint and similar). Dropped for budget; the
  kit's own hygiene check covers whitespace, conflict markers, mojibake and
  optional local links (F19).
- The `skills-ref` validator's install and exact checks: the spec names it
  (F8) but its repository was not fetched.
- Codex non-interactive mode (`codex exec`) and Gemini headless mode. Not
  fetched; Codex is not an adapter yet (02 R5).
- OpenAI's `evals` API and graders pages beyond the agent-evals decision
  page (F6).
- OpenCode's JSON event format for `opencode run --format json`: the fetched
  CLI pages do not describe it (**weak**: absence). OpenCode is not
  installed on this machine, so no flag was confirmed locally.
- Any runtime test. The assignment forbids running agents against paid or
  metered models; no permission rule was exercised.

## 2. Findings

Findings from topics 0-8 are cited as `0N-F<n>` or `0N R<n>`.

### Evaluating instructions and skills (sub-question 1)

F1. **Anthropic: start small from real failures; prefer code graders; read
transcripts; calibrate model judges.** Three grader kinds: code-based
("String match checks", "Binary tests", "Static analysis", "Tool calls
verification", "Transcript analysis": "Fast", "Cheap", "Objective",
"Reproducible", but "Brittle to valid variations"); model-based
("Non-deterministic", "More expensive than code", "Requires calibration
with human graders"); human. "20-50 simple tasks drawn from real failures is
a great start." Capability evals "start at a low pass rate"; regression
evals "should have a nearly 100% pass rate". "Each trial should be
'isolated' by starting from a clean environment" (one Claude used git
history from earlier trials). "it's often better to grade what the agent
produced, not the path it took". Judges: give "a way out, like providing an
instruction to return 'Unknown'", and grade each dimension "with an
isolated LLM-as-judge". "You won't know if your graders are working well
unless you read the transcripts". pass@k versus pass^k: at a 75% per-trial
rate, all of 3 trials pass about 42% of the time.
<https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents>,
published 2026-01-09, accessed 2026-09-27. Engineering blog, first-party.

F2. **Anthropic skill guidance: evaluations first, against a no-skill
baseline; "no built-in way" to run them.** "Create evaluations BEFORE
writing extensive documentation" (06-F10). Steps: identify gaps, "Build
three scenarios that test these gaps", "Measure Claude's performance
without the Skill", write minimal instructions, iterate. "There is not
currently a built-in way to run these evaluations." It also describes a
two-instance loop: "Claude A" writes the skill, "Claude B" (a fresh
instance) tests it on real tasks.
<https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices>,
accessed 2026-09-27, no page date. Conflict with F3: the Claude Code docs
now ship a runner. Neither page shows a date; I went with F3 for Claude
Code because the local 2.1.282 CLI has the command. F2's method still
holds.

F3. **`claude plugin eval` runs eval cases against a plugin or a
skills-directory plugin; four of six grader types cost nothing, the runs
do not.** "Every eval run and every judge grader is a real model call on
your account, counted against your plan's usage or your API bill." Target:
"A plugin directory with a `plugin.json` ... or a skills-directory plugin."
Graders: "`regex`, `tool_used`, `tool_order`, and `file_exists` are computed
from the transcript and files and cost nothing, while `llm` and `baseline`
call a judge model"; "There are no custom-code graders". Each case runs
three times by default, and again in a no-plugin arm ("one case is six
runs"); `--ablation none` "halves the cost". Stable-signal advice: "For long
output ... grade it with a `regex` grader"; pair one result grader with one
`tool_used` or `tool_order` grader. Tools: runs "never stop to ask for
permission"; ungranted `Bash`, `Write`, `Edit`, `WebFetch` "are removed from
the session". Granting Bash runs it under the OS sandbox; "Native Windows
has no backend, so run shell-granting suites under WSL2". CI: `--json`,
`--trust-plugin`, `--threshold` (default 1.0), `--max-cost-usd` (a
list-price ceiling, "not on plan usage"); exit 1 below threshold; "The
with-minus-without delta is reported but never changes the exit code". A
passing suite "says nothing about whether the plugin is safe".
<https://code.claude.com/docs/en/plugin-evals>, accessed 2026-09-27. Local:
`claude plugin eval --help` on 2.1.282 lists the same flags, plus
`--judge-model` (default haiku) and `--no-publish`.

F4. **`claude -p` gives machine-readable cost and load errors; `--bare`
makes runs reproducible but needs an API key.** "With `--output-format
json`, the response payload includes `total_cost_usd`"; `--json-schema`
constrains the output. `--bare` skips "hooks, skills, custom commands,
subagents, installed plugins, MCP servers, auto memory, and CLAUDE.md"; it
is "recommended mode for scripted and SDK calls, and will become the
default for `-p`". In bare mode "Claude Code never reads OAuth credentials",
so it needs `ANTHROPIC_API_KEY` (metered). Without `--bare`, "a `-p`
session runs the hooks in a project's `.claude/settings.json` and connects
the servers in its `.mcp.json`, even in a folder you've never trusted". The
`system/init` event carries `plugin_errors` and `mcp_server_errors` so "a
CI gate can fail on a non-empty array".
<https://code.claude.com/docs/en/headless>, accessed 2026-09-27.
Consequence: a bare run would *not* load the kit's generated `.claude/`
agents, skills or hooks unless passed by flag, so it cannot test the
adapter as installed.

F5. **`opencode run` is the scripted entry point; `--auto` approves only
what is not denied.** V2: "Use `opencode run` to submit a prompt without
opening the interactive interface. It is designed for scripts, CI jobs".
V1 flags: `--agent`, `--model`, `--format` ("default (formatted) or json
(raw JSON events)"), `--dir`, and `--auto` "Auto-approve permissions that
are not explicitly denied"; global `--pure` "Run without external
plugins". The V2 `debug` section documents only `opencode debug paths`,
which "does not start a server". No fetched page documents a command that
prints the resolved config or evaluates a permission rule without a model
(**weak**: absence). <https://opencode.ai/v2/docs/cli/> and
<https://opencode.ai/docs/cli/>, accessed 2026-09-27. Local: `opencode` is
not installed here, so no flag was confirmed.

F6. **OpenAI's agent evals are hosted: trace grading, then datasets.**
"Trace grading is the fastest way to identify workflow-level issues"; a
trace holds "model calls, tool calls, guardrails, and handoffs"; one listed
question is "Did the workflow violate an instruction or safety policy?".
Steps start in the dashboard ("Open **Logs** > **Traces**"); then "move
from individual traces to repeatable datasets and eval runs".
<https://developers.openai.com/api/docs/guides/agent-evals>, accessed
2026-09-27. For apps built on the OpenAI platform; nothing on this page
evaluates a coding harness's local config.

F7. **Secondary: promptfoo can drive Claude Code headlessly with skill and
permission settings, as an npm dependency.** Provider `anthropic:claude-
agent-sdk` (alias `anthropic:claude-code`) takes `working_dir`,
`permission_mode` (including `dontAsk` and `plan`), `max_budget_usd`,
`skills`, and a `skill-used` assertion; it "requires the
`@anthropic-ai/claude-agent-sdk` package to be installed separately";
`apiKeyRequired: false` lets it use "a local Claude Code binary with an
active session". <https://www.promptfoo.dev/docs/providers/claude-agent-sdk/>,
accessed 2026-09-27. Third-party vendor docs.

### Static validation (sub-question 2)

F8. **Agent Skills spec: exact `name` rules and a reference validator.**
`name`: "Max 64 characters. Lowercase letters, numbers, and hyphens only.
Must not start or end with a hyphen", no consecutive hyphens ("pdf--processing"
is invalid), "Must match the parent directory name". `description`: "Max
1024 characters. Non-empty." Validation: "`skills-ref validate ./my-skill`
... checks that your SKILL.md frontmatter is valid and follows all naming
conventions." <https://agentskills.io/specification>, accessed 2026-09-27.
Extends 01-F6. Local: `Test-SwProject` checks name equals directory,
non-empty description, no duplicates, and allowed keys; not the character
set or the lengths.

F9. **`claude plugin validate` checks directories of skills, agents and
commands, but misses what the kit already catches.** The plugin reference
calls it "the authoritative check for a manifest"; its local help says it
validates "a plugin or marketplace manifest, or the skills, agents, and
commands in a directory", and `--strict` is for CI.
<https://code.claude.com/docs/en/plugins-reference>, accessed 2026-09-27.
Local experiment (2.1.282): `claude plugin validate .claude --strict --json`
passed with `"contents": []`. On a scratch copy with a skill renamed
`Bad_Name`, an agent without `description`, and a command whose
frontmatter was `foo: [unclosed`, it reported only two missing-description
warnings (agent and command); the invalid skill name and the malformed
frontmatter passed.

F10. **Claude settings: a published schema that catches bad rule strings,
not unknown keys.** The settings page points to "the published JSON schema
(https://json.schemastore.org/claude-code-settings.json)".
<https://code.claude.com/docs/en/settings>, accessed 2026-09-27. The schema
is draft-07, root `additionalProperties: true`; permission rules are
pattern-checked; `defaultMode` is an enum whose notes say "UNDOCUMENTED"
for `manual` and `delegate`, so it is maintained outside the docs.
<https://json.schemastore.org/claude-code-settings.json>, accessed
2026-09-27. Secondary (SchemaStore). Local experiment with PowerShell
7.6.6's built-in `Test-Json -Schema`: the generated `.claude/settings.json`
passed; `Bash(git push` (no closing paren), `Bsh(x)` and `defaultMode:
yolo` failed; a misspelt top-level `permisions` passed.

F11. **The OpenCode `$schema` still serves V1, and the kit's
`opencode.jsonc` fails it.** V2 config docs: add `"$schema":
"https://opencode.ai/config.json"` "to enable validation", and "Use the
schema as the source of truth". <https://opencode.ai/v2/docs/config/>,
accessed 2026-09-27. The fetched schema (draft 2020-12) resolves to
`$defs/Config`, whose properties have `agent` and `permission` but not
`agents` or `permissions`, with `additionalProperties: false`.
<https://opencode.ai/config.json>, accessed 2026-09-27 04:26Z. Local:
`Test-Json` on this repo's `opencode.jsonc` against it: "All values fail
against the false schema at '/permissions'". This confirms 03-F20 in
practice.

### Runtime permission checks (sub-question 3)

F12. **Claude's `dontAsk` mode turns every would-be prompt into a denial,
which suits a headless probe.** `dontAsk` "auto-denies every tool call that
would otherwise prompt you", while "file reads inside your working
directories and read-only Bash commands", allow rules and hook approvals
still run. "Deny rules block in every mode, including `bypassPermissions`."
Documented CI example: `claude -p "run the test suite" --permission-mode
dontAsk --allowedTools "Bash(npm test)" "Read"`.
<https://code.claude.com/docs/en/permission-modes>, accessed 2026-09-27.
Local help (2.1.282) adds `--permission-prompts none` ("anything that would
prompt is denied automatically"). No fetched page documents a way to ask
Claude Code for a rule's decision on a command string without a model
turn (**weak**: absence across the permissions, headless and modes pages).

F13. **So a runtime permission check is a model run, and its cost depends
on the account.** Claude: every probe is a `-p` turn; the JSON result
reports `total_cost_usd` (F4); on a subscription it counts against plan
usage, and `--bare` needs a metered API key (F4). A non-bare run in a
throwaway init loads the generated `.claude/` and its hooks (F4), which is
what a probe must test. OpenCode: `opencode run --agent <role> --format
json --auto` (F5) with a free model is $0 in money but rate-limited and may
be logged by the provider (03-F10, 03-F12). Both depend on the model
actually attempting the command, so a refusal by the model passes without
exercising the rule; the probe must assert that the tool call was made and
denied, from the transcript or JSON events (F1's "Tool calls
verification"). Synthesis of F1, F4, F5 and F12.

### CI (sub-question 4)

F14. **Model-in-the-loop CI needs a stored credential and costs twice.**
Claude GitHub Actions: a repository secret `ANTHROPIC_API_KEY` or
`CLAUDE_CODE_OAUTH_TOKEN`, or OIDC federation with `id-token: write`. A
shared secret should be an API key, "since an OAuth token is tied to the
subscription of the person who ran `claude setup-token`". Costs: API usage
plus "GitHub Actions minutes"; cap with `--max-turns`.
<https://code.claude.com/docs/en/github-actions>, accessed 2026-09-27.
`claude plugin eval` in CI likewise needs "credentials in the environment
such as `ANTHROPIC_API_KEY`" and `--trust-plugin` (F3). Adding a secret is
a GitHub settings write, which the kit never runs (AGENTS.md).

F15. **Comparable config generators gate CI on drift, deterministically.**
ruler's CI example "fails when committed agent files are out of sync with
`.ruler/`" (07-F12). The kit's equivalent is the Claude drift check
(08-F28), which runs only when `.claude/.sw-generated` exists.

F16. **Local CI is deterministic, secret-free, and never generates the
Claude adapter.** `.github/workflows/ci.yml` (`contents: read`): on
`windows-latest` and `ubuntu-latest`, install Pester from the Gallery, run
`Invoke-Pester tests -CI`, then `init` an `unreal` project and `validate`
it. `.github/workflows/sw-validate.yml` (identical to
`product/project/github/.github/workflows/sw-validate.yml`, so installed
projects get it): `validate`, then `git diff --check` of tracked `.sw`,
`.opencode`, `AGENTS.md` and `opencode.jsonc` against the empty tree. `.claude/`
is git-ignored, so in CI the drift branch of `Test-SwProject` never runs;
the generator is covered only by the four Pester `Claude adapter` tests.
No model call, no secret. Local, read 2026-09-27 at `2676728`.

### Local coverage (sub-question 5)

F17. **Pester covers kit mechanics well and generated content thinly.**
`tests/Sw.Tests.ps1` has 40 `It` lines (the assignment says 39); the
data-driven ones expand to more cases. Covered: `Set-SwBlock`, `Get-SwHash`,
the pattern and decision model, init/update lifecycle (including
`skip-modified`, `-Adopt`, an existing `AGENTS.md`, `-WhatIf`), ten
negative validator fixtures, Claude drift, a tier-1 positive fixture,
Claude enable/disable/backup, `gh` allow narrowing, `Set-SwTiers`, comms
(including path traversal and collisions), doctor, the backup secret
filter, and a `product/` leak guard. Thin or missing:
- Claude generated content: one test asserts three `deny` entries
  (`git push`, `gh pr merge`, `gh pr create`) and the research agent's
  `WebSearch`; nothing checks readonly `tools` lists, `disallowedTools`, or
  the full tier deny list.
- The pre-existing `AGENTS.md` test checks kept text and added blocks; it
  does not assert a `## Project identity` section (07-F20).
- No fixture exercises the `Command <name> must set subagent` check, so
  removing it (05 R7) breaks no test; the change needs a *new* test, not an
  edited one.
- Nothing reads `docs/research/` or skill text for dated facts.
Local, read 2026-09-27 at `2676728`.

F18. **`Test-SwProject` checks structure and the OpenCode model; it is blind
to Claude semantics, research files and runtime.** Current output:
"contracts=1854; permission cases=380; hygiene files=34; local links=0.
NOT runtime enforcement." Checked: strict JSON, portability (no model,
provider or shell pins; no absolute paths), legacy paths, frontmatter
subsets, required agents, skills and commands, routes and the hard-coded
subagent list (`Sw.Project.psm1` lines 307 and 309), `build` subagent
allowlist, GitHub tier rules, the startup byte budget, the per-role V2
matrix (08-F28), Claude byte drift, and hygiene on shared files. Not
checked: the OpenCode schema (F11); Claude rule semantics per role
(08-F27); skill `name` character set and lengths (F8); `## Project
identity` (07-F20); `docs/research/`; dated facts in skills (06-F12); any
runtime behaviour. Local, `product/lib/Sw.Project.psm1` lines 195-420,
read 2026-09-27; `validate` run 2026-09-27.

F19. **A research lint is feasible if it accepts the citation forms the
files already use.** A Python scan of `docs/research/00`-`08` (local,
2026-09-27), per `F<n>.` block in "## 2. Findings":
- Rule "URL and a `YYYY-MM-DD` date in the block": 66 of 176 findings
  fail. Most fail by design: "Same page as F1", "Same README as F3",
  synthesis findings that cite only other findings, and local findings.
- Rule "URL, or `Same ... as F<n>`, or the word `Local`, or a cross-reference
  `(F<n>` / `0N-F<n>`", plus an "accessed" date in the header: 7 fail
  (07-F17 to F22, whose local status is in the subsection heading, and
  08-F4, where "Same page as" is split across a line break).
- Topic 00 has no numbered findings, so a lint keyed on `F<n>.` passes it
  vacuously.
Every file's header states an access date.

F20. **Carried inputs mapped to checks and owner files.**

| Input | Check | Owner file | Kind |
|---|---|---|---|
| Research lint (roadmap) | sections 1-6 present; header has an access date; each `F<n>.` block has a URL, `Same ... as F<n>`, `Local`, or a finding cross-reference (F19) | `Test-SwProject` in `product/lib/Sw.Project.psm1`, only when `docs/research/*.md` exists; fixture in `tests/Sw.Tests.ps1` | static |
| `## Project identity` (07 R4) | `AGENTS.md` has a `## Project identity` heading before `sw:begin core` | `Test-SwProject`; fixture beside the existing pre-existing-`AGENTS.md` test | static |
| Subagent flag (05 R7) | drop lines 307 and 309 (the route check on 308 stays); test that flipping `subagent:` in a command changes the generated leader dispatch line | `Sw.Project.psm1`; new Pester test in `Claude adapter` | static |
| Staleness (06 R5, option C) | shipped skills carry no `Observed YYYY-MM` snapshot lines outside an "Old observations" section | `tests/Sw.Tests.ps1` (kit-owned skills only) | static |
| Claude beyond bytes (08-F28) | from `roles.json`, not from the generator: readonly agents' `tools` have no `Edit`/`Write`; every generated agent has `disallowedTools: Agent`; `settings.json` `deny` contains every `Get-SwClaudeGhDeny` entry for the tier, `git push/reset --hard/clean/stash`, and the `.env` asks (08 R2) | `Test-SwProject` drift branch; Pester `Claude adapter` asserts in CI | static |
| Static matrix vs runtime OpenCode (08-F28, 03-F20) | schema check is impossible today (F11); a runtime probe needs a model (F13) | manual smoke, `docs/development.md` | runtime, manual |
| Evaluations first (06-F10) | three scenarios in the task record before a new skill's text; optional `claude plugin eval` later (F3) | `agent-documentation` or `research` skill text; task records | practice |

Local analysis, 2026-09-27.

## 3. Options compared

Where each kind of check lives:

| Option | Catches | Cost per run | Dependencies | Fits the rules? |
|---|---|---|---|---|
| a. Static checks in `validate` (installed projects) | structure, portability, V2 matrix, Claude structure (F20) | none | none | yes; `validate` is not startup context |
| b. Pester tests (kit repo, CI on two OSes) | generator and lifecycle correctness, kit-owned skill text | none | Pester (existing) | yes |
| c. Schema validation with `Test-Json` | Claude rule-string typos (F10); OpenCode keys once the schema is V2 | none | built into PowerShell 7; schemas fetched or vendored | Claude schema is third-party (approval); OpenCode schema fails today (F11) |
| d. `claude plugin validate` | missing descriptions only (F9) | none | Claude Code installed | adds nothing over a |
| e. Manual runtime smoke (a few headless probes in a throwaway init) | whether the harness applies the rules as written (F12, F13) | Claude: plan usage or API cost; OpenCode free model: $0, rate-limited | a harness and a model | yes, if a human runs it |
| f. Model evals (`claude plugin eval`, promptfoo) | whether agents follow skills and roles (F1-F3, F7) | 6 runs per case by default (F3); judge calls extra | Claude plugin layout or npm (F7); Bash needs WSL2 on Windows (F3) | only opt-in; promptfoo is a new dependency |
| g. Model-in-the-loop CI | same as e or f, on every push | API cost plus Actions minutes (F14) | a repository secret (F14) | no: needs a GitHub settings write and metered spend |

Research lint strictness (F19):

| Rule | Fails today | Trade-off |
|---|---|---|
| URL and date in every finding | 66 of 176 | rewrites eight approved files; forbids "Same page as" |
| Accepted citation forms plus header date | 7 | small edits to 07 and 08, or accept "Local" in the subsection heading |
| Warn, never fail | 0 | no enforcement |

## 4. Recommendation

R1. **Keep CI deterministic and secret-free (options a and b only).** No
model runs in CI and no repository secret (F14). This matches the
free-first rule and Anthropic's advice to prefer code graders where they
suffice (F1). `sw-validate.yml` and `ci.yml` need no new jobs: the new
checks below run inside `validate` and Pester.

R2. **Add three static checks to `validate` (`Test-SwProject`), each with a
negative fixture in `tests/Sw.Tests.ps1`:**
- `## Project identity` heading present in `AGENTS.md` (07 R4, 07-F20).
- Skill `name` matches the spec pattern and length, and `description` is at
  most 1024 characters (F8). The spec's `skills-ref` is not needed; this is
  one regex.
- Claude structure from `roles.json` when `.claude/.sw-generated` exists
  (F20 row 5). This gives Claude checks an oracle independent of the
  generator, which the byte comparison lacks (08-F28). The same asserts go in
  the Pester `Claude adapter` test so CI covers them (F16).
Bump `product/VERSION` and `CHANGELOG` with the change.

R3. **Research lint in `validate`, lenient rule, a warning, shipped to
installed projects; it runs only where `docs/research/*.md` exists.**
Sections 1-6 present; header has an access date; each finding has one of
the accepted citation forms (F19, F20 row 1). Accept a subsection heading
containing "local" as covering its findings (07-F17 to F22). Because the
lint only warns, fixing 08-F4's line break and editing 07 are optional.
Topic 00's unnumbered findings pass; say so rather than rewrite it.

R4. **Subagent flag (05 R7): add a test, do not edit one.** No test asserts
the removed check (F17). When lines 307 and 309 go (05 R7; the routing pin stays), add a Pester test that
flipping `subagent:` in `review.md` changes the generated leader dispatch
sentence.

R5. **Staleness: a Pester test on kit-owned skills, not a `validate` rule.**
After `free-models` moves its per-model list to research (06 R5), assert
that no shipped `SKILL.md` has an `Observed YYYY-MM` line outside an "Old
observations" section. Users' own skills are not linted (they own them).

R6. **Schemas: none now.** Do not validate `opencode.jsonc` against the
published schema: it fails every install (F11). Recheck when OpenCode serves
a V2 schema; `Test-Json` is built into PowerShell 7 and adds no dependency.
Do not vendor the SchemaStore Claude schema (third-party asset, F10); R2's
role-derived checks cover more of what matters. Skip `claude plugin
validate` (F9).

R7. **Runtime: a manual smoke checklist, run by a human, results recorded in
a task record.** In a throwaway `init` (with `claude enable`), per harness,
three probes: a denied command as written (`git push`), a readonly role's
edit, and a `.env` read. Claude: `claude -p "<probe>" --agent <role>
--permission-mode dontAsk --output-format json` (not `--bare`: it would skip
the generated adapter, F4). OpenCode: `opencode run --agent <role> --format
json "<probe>"` with a free model. Assert from the transcript that the tool
call was attempted and denied (F13). This also answers 08 open question 6.
It is documentation in `docs/development.md`, not a shipped command.

R8. **Evaluations: adopt the practice, not the tooling.** For a new or
rewritten skill, write three scenarios and a no-skill baseline in the task
record before the text (F2, 06-F10), and run them by hand. `claude plugin
eval` (F3) is the candidate if the owner later wants repeatable skill evals;
it costs plan usage and needs WSL2 for shell-granting cases on this
machine.

Mapping onto the kit:
- `product/lib/Sw.Project.psm1` `Test-SwProject`: R2, R3; R4 removes lines
  307 and 309.
- `tests/Sw.Tests.ps1`: fixtures for R2 and R3; R4 and R5 tests.
- `docs/research/07-lifecycle.md`, `08-permissions-safety.md`: R3 edits if
  the owner chooses them.
- `docs/development.md`: R7 checklist; R8 practice line.
- `product/VERSION`, `product/CHANGELOG.md`: R2, R3 (installed projects get
  them through `update`).
- CI workflows: no change (R1).

## 5. Open questions

Owner answers recorded 2026-09-27 (relayed by the Leader).

1. Owner: research lint (R3) as an error or a warning in `validate`? And
   edit 07 and 08 to pass, or accept "local" in a subsection heading?
   **Answer:** a warning, not an error (so the 07 and 08 edits are
   optional).
2. Owner: should the research lint ship to installed projects (the
   `research` skill writes `docs/research/` there too) or run only in this
   repository?
   **Answer:** it ships to installed projects and runs only where
   `docs/research/*.md` exists.
3. Owner: run the R7 smoke checklist now, once, on this machine? Claude
   probes use plan usage; OpenCode would need installing first, and a free
   model.
   **Answer:** the checklist runs after the rewrite, when the adapter fixes
   land; OpenCode must be installed first.
4. Owner: is repeatable skill evaluation (`claude plugin eval`, R8) wanted
   at all, given its per-run model cost?
   **Answer:** evaluations are a practice only; no `claude plugin eval`.
5. Budget report: 17 research calls (17 fetches with `curl`, no web
   searches, none failed; one OpenAI HTML page was re-fetched as `.md`
   because the HTML was navigation only; the skill best-practices page
   re-verifies 06-F10), cap 25. Total tool calls about 40, including reading
   prior research, kit code and tests, local `--help`, `claude plugin
   validate` and `Test-Json` experiments, the research-file scan and
   validation. Dropped: markdownlint, `skills-ref` repository, Codex
   `exec`, Gemini headless, OpenAI evals API pages, OpenCode event format.
6. Fetched pages contained no text directed at this task.

## 6. Supersedes / updates

None superseded. Confirms 03-F20 with a failing validation (F11). Answers
the topic-9 hand-offs from 05 R7 (F17: no test to change), 06 R5 option C
(R5), 07 R4 (R2), 08-F28 (R2, R7) and the roadmap's research lint (R3).
Updates 06-F10 / F2: Claude Code now has a built-in eval runner (F3), which
the skill best-practices page does not mention.
