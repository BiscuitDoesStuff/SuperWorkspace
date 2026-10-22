# 13: Agentic leverage on T3 Code

Status: complete (recommendation, not approved); 2026-10-15 by the current
Leader. Owner request: look at
every agentic technique worth it for quality, cost and speed, including the
methods topic 12 did not cover (GSD, Agent OS, Kiro). Sources accessed
2026-10-15 unless a page date is given; raw text saved outside the repository
and re-read for each finding.

## 1. Question and scope

Which agentic techniques available on T3 Code with Claude and Codex
measurably raise quality, cut cost or cut time for Workspace work, and which
should Workspace adopt?

Sub-questions:
1. Methods not covered in topic 12: GSD, Agent OS, Kiro.
2. Quality: Codex review (owner: Codex is the default reviewer), verification
   signals, deterministic hooks.
3. Speed: parallel threads, dynamic workflows, best-of-N attempts, automatic
   approval review.
4. Cost: model routing, context hygiene, prompt caching.
5. Automation: pull-request watching, scheduled tasks, hosted review.
6. Evidence and recommendation.

Out of scope: implementation; live trials (owner declined trials for topic
12); pricing tables (topic 3).

Not covered: Codex `/review` in the CLI (its documentation page returned 404;
secondary sources only, not used); whether Codex's `/review` and goal
commands are reachable through T3's app-server; independent measurements of
GSD, Agent OS or Kiro; model-routing studies beyond vendor guidance.

Budget: 18 research calls (5 searches, 13 fetches including 2 failures) of
25. Corpus claims as `C<nnn>` (ResearchProj, local); topics as `1N-F<n>`.

## 2. Findings

### Methods not covered in topic 12

F1. **GSD moved and keeps the fresh-context phase loop.** The original
`gsd-build/get-shit-done` (MIT, 64k stars) is archived (last push
2026-05-31); development continues as GSD Core (`open-gsd/gsd-core`, MIT,
10.5k stars, last push 2026-10-15): "Discuss → Plan → Execute → Verify →
Ship", plans are verified to fit "a fresh context window", and execution runs
"plans in parallel waves; each executor starts with a clean 200k-token
context"; supports Claude Code and Codex among others. README of
[open-gsd/gsd-core](https://github.com/open-gsd/gsd-core), main branch; repo
metadata via GitHub API. No measurements.

F2. **Agent OS v3 narrowed to coding standards.** "Discover Standards",
"Deploy Standards", "Shape Spec", "Index Standards"; works alongside Claude
Code and other tools. MIT, 5.5k stars, last push 2026-10-07. README of
[buildermethods/agent-os](https://github.com/buildermethods/agent-os), main
branch. No measurements.

F3. **Kiro is its own IDE.** Spec workflow writes `requirements.md`,
`design.md` and `tasks.md`, with steering files and hooks.
[Kiro docs, Specs](https://kiro.dev/docs/specs/), no page date. Not a T3 Code
provider, so only its pattern is transferable (my inference).

### Quality

F4. **Codex review follows `AGENTS.md` review rules and can run on GitHub.**
Codex "follows the applicable code review rules" in a `## Code Review Rules`
section of the nearest `AGENTS.md`; on GitHub it "flags only P0 and P1
issues", reviews on `@codex review` or automatically once the repository is
connected and **Automatic review** is on. Advice: start with "two or three
concise rules" and "Leave mechanical checks in CI".
<https://learn.chatgpt.com/docs/third-party/github>, no page date.

F5. **A rubric written from the repository is a cheaper verifier.** An agent
explores the repository, writes a "context-grounded rubric checklist", and
candidate patches are scored against it without running tests: "+3.5
percentage-point gain over the strongest baseline" on SWE-bench Verified
(open models). [Agentic Rubrics as Contextual Verifiers for SWE Agents, arXiv 2601.04171, 2026-01-07](https://arxiv.org/abs/2601.04171).

F6. **Deterministic hooks exist on both providers, with T3-specific
caveats.** Claude: hooks "are deterministic and guarantee the action happens"
(topic 12 F7 source). Codex hooks cover `PreToolUse`, `PermissionRequest`,
`PostToolUse`, `Stop` and more; "Non-managed hooks must be reviewed and
trusted before they run", trust is recorded "against the hook's current
hash", and project hooks load "only when the project `.codex/` layer is
trusted". <https://learn.chatgpt.com/docs/hooks>, no page date. Claude
project-agent frontmatter hooks are skipped in SDK runs (C365, declared;
T3 Code launches Claude through the SDK, topic 11 F6). Local: ResearchProj
`docs/research-claims.md`, read 2026-10-15.

### Speed

F7. **Claude dynamic workflows run large fan-outs from a script.** "A
JavaScript script that orchestrates many subagents at once"; for "a
codebase-wide bug sweep, a 500-file migration, a research question";
"Up to 16 concurrent agents by default", "1,000 agents total per run";
agents sharing a prefix read one prompt cache; no mid-run user input; a
bundled `/deep-research` workflow. [Dynamic workflows](https://code.claude.com/docs/en/workflows),
no page date. Local: the Workflow tool is offered in this T3 Code Claude
thread. Codex has no equivalent page; its subagents spawn on request
(topic 11 F9).

F8. **Codex auto-review speeds approvals without widening permissions.**
"Auto-review replaces manual approval at the sandbox boundary with a separate
reviewer agent"; the main agent keeps "the same approval policy and the same
network and filesystem limits"; a denial tells it "to find a materially safer
path or stop and ask the user".
<https://developers.openai.com/codex/concepts/sandboxing/auto-review>, no page
date. T3 Code's **Auto** mode selects exactly this for Codex
(`on-request`, `workspaceWrite`, `auto_review`; topic 11 F6). For Claude,
**Auto** is Claude's classifier mode, and deny rules still hold (topic 11 F7).

F9. **Parallel attempts help when a verifier picks the winner.** In agent
test-time scaling, "Scaling test time compute could improve the performance
of agents" and "Increasing diversified rollouts exerts a positive effect"
([arXiv 2506.12928, 2025-06-15](https://arxiv.org/abs/2506.12928)); with a
trained verifier, SWE-Lego-Qwen3-8B rose "42.2% to 49.6%"
([arXiv 2601.01426, v2 2026-01-07](https://arxiv.org/abs/2601.01426)). Both
are benchmark settings; cost scales with the number of attempts. T3 Code can
send one prompt to several models at once, each in its own thread and
worktree (T3 `docs/user/thread-sidebar.md`, saved for topic 11).

F10. **Agent teams stay a poor fit.** Experimental, Claude-only, about 7x
tokens, best for research and review (05-F4, 05-F15). Claude's cost page:
"token usage is roughly proportional to team size".
[Manage costs effectively](https://code.claude.com/docs/en/costs), no page date.

### Cost

F11. **Vendor cost levers: right-size the model, load less, delegate
verbose work.** "Sonnet handles most coding tasks well and costs less than
Opus. Reserve Opus for complex architectural decisions"; hooks can filter a
log "from tens of thousands of tokens to hundreds"; "Skills load on-demand
only when invoked, so moving specialized instructions" out of always-loaded
files saves tokens; verbose operations go to subagents, ideally on "a
smaller model". Same page as F10. Codex sets subagent defaults with
`agents.default_subagent_model` (topic 11 F9).

F12. **Prompt-cache lifetime differs by route.** A workflow agent's cache
"holds for five minutes by default, including on a Claude subscription"
unless `subagentPromptCacheTtl` is set (same page as F7); T3 Code's Claude
cache "lasts about an hour on a Claude subscription and 5 minutes with an API
key" (T3 `docs/user/providers-claude.md`, saved for topic 11). Stable
prefixes and fewer resumes after expiry cut cost (my inference).

### Automation

F13. **T3 Code automates the pull-request tail and schedules work.** Agents
call `watch_pull_request`; the server checks every two minutes and wakes the
agent on failed checks, passing checks, reviews or conflicts; scheduled and
webhook tasks run agent turns on a schedule or on a GitHub event (<https://github.com/pingdotgg/t3code/blob/ec1313c8/docs/user/source-control.md>,
<https://github.com/pingdotgg/t3code/blob/ec1313c8/docs/user/project-settings.md>,
saved for topic 11).

## 3. Options compared

| Technique | Gain | Evidence | Cost and risk | Verdict |
|---|---|---|---|---|
| Codex default reviewer with `AGENTS.md` review rules (F4) | quality | vendor; self-preference (12-F12) | one Codex run per review | **adopt** (owner decision) |
| Rubric-first review (F5) | quality, cheap | one study, open models | small prompt change | **adopt** in the review skill |
| Execution evidence and tests first (12-F8, 12-F13) | quality | studies | none | **adopt** (topic 12) |
| Hooks (F6) | quality, cost | vendor | Codex hash trust; Claude frontmatter hooks skipped under SDK | **selective**: settings-level checks only, after live check |
| Parallel T3 worktree threads | speed | 12-F2, F1 pattern | merge work, more tokens | **adopt** (owner decision) |
| Claude dynamic workflows (F7) | speed at scale | vendor | no mid-run input; Claude only | **adopt for bulk** (migrations, research, sweeps) |
| T3 **Auto** mode (F8) | speed | vendor | Claude classifier and Codex reviewer are models, not rules | **adopt** once deny rules and Codex rules ship; Supervised until then |
| Best-of-N attempts (F9) | quality on hard tasks | studies, with verifier | N times cost | **on demand** for hard, high-value tasks |
| Agent teams (F10) | research/review | vendor | ~7x, experimental | **skip** |
| Model routing and cheap subagents (F11) | cost | vendor | weaker model may miss things | **adopt** with the local tier table |
| Skills instead of always-loaded text (F11) | cost | vendor | rewrite effort (already approved) | **adopt** |
| PR watching (F13) | speed | vendor | needs GitHub token in T3 | **adopt** when a PR exists |
| Scheduled Codex audits (F13) | quality | none | unattended turns | **opt-in**, read-only reports only |
| Codex cloud automatic PR review (F4) | quality | vendor | external service, repo connection | **owner choice** |
| GSD Core / Agent OS / Kiro (F1-F3) | process | none | install, churn (GSD moved) | **borrow**: fresh-context waves (GSD), standards discovery (Agent OS) |

## 4. Recommendation

R1. **Review stack (owner: Codex by default).** The `review` skill always
routes to Codex: from a Claude thread through `delegate_task` to a Codex
instance in a read-only mode; from a Codex thread to a fresh Codex subagent.
The reviewer first writes a short repository-grounded rubric, then scores the
change against it and runs the checks (F5). Cross-provider or Claude review
runs only when the prompt asks. Add a short `## Code Review Rules` section to
`AGENTS.md` (F4) so the same rules guide local and GitHub review.

R2. **Speed by default for independent work.** Parallel packages run as T3
worktree threads; bulk work that would need dozens of agents (sweeps,
migrations, research) uses a Claude dynamic workflow, while bulk audits and
bug hunts use Codex fan-out (R1's owner rule) with one agent per area (F7,
topic 11 F9). Best-of-N only on request for hard tasks, judged by tests and
the Codex reviewer (F9).

R3. **Permission mode: move to T3 Auto after guardrails ship.** Ship Claude
deny rules and Codex `forbidden` rules first (topic 11 R5), then make **Auto**
the recommended project default: it keeps sandbox and deny limits while a
reviewer model handles routine approvals (F8). Until then, Supervised.
*Revised by owner decision D9:* the Git part of the guardrails is now only
the hard limits (no force-push, no push to public `origin` outside the pull
request route, no releases or repository settings, no rewriting `main`), with
T3 Restore and worktree threads as the safety net. Auto still waits on those
limits shipping and the Q5 live checks.

R4. **Cost: route models and keep always-loaded text small.** Local tier
table: a mid model for normal work, the top model for architecture and hard
debugging, a small model for exploration and verbose subagent work (F11).
Move governance detail into skills (F11), filter noisy output with
settings-level hooks or scripts (F6, F11).

R5. **Automation, opt-in.** Agents link pull requests and watch them when one
exists (F13). Offer, but do not enable by default, a scheduled read-only Codex
audit that writes a report and changes nothing (F13). Codex cloud automatic
PR review is an external service: owner choice (F4).

R6. **Third-party methods (precedent D8).** None of GSD Core, Agent OS or
Kiro beats the topic 12 composite on Workspace's requirements, and GSD's move
(F1) is a maintenance warning. Borrow GSD's fresh-context waves (already R2
here) and Agent OS's standards discovery as a future `standards` skill; revisit
under D8 when measurements appear.

## 5. Open questions

Owner answers recorded 2026-10-15: Q1 approved; Q2 not yet, the owner asked
what rules would actually be placed and wants them planned first; Q3 unsure,
probably not automatic, so review stays local and no repository is connected;
Q4 offered as an opt-in. Q5 live checks remain unapproved. Q2 follow-up: the
owner dropped the Git deny-rule guardrails in favour of T3 Code's Git procedures
(outline D9); R3's precondition is revised below.

1. Owner: the review stack in R1 (Codex via `delegate_task`, rubric first,
   `## Code Review Rules` in `AGENTS.md`)?
2. Owner: move the recommended mode to **Auto** once guardrails ship (R3)?
3. Owner: enable Codex cloud automatic PR review on GitHub (external), or keep
   review local (R5)?
4. Owner: offer the scheduled read-only Codex audit as an opt-in (R5)?
5. Live checks before relying on R1-R3: `delegate_task` from Claude to Codex in
   a read-only mode; Workflow tool behaviour in T3 Claude threads; T3 Auto
   behaviour for both providers with the new rules.

## 6. Supersedes / updates

Extends topic 12 (methods GSD, Agent OS, Kiro: F1-F3) and topic 11 R4-R6
(review routing, permissions, models). Would change the recommended T3 mode
from Supervised (topic `t3code-adoption`) to Auto after guardrails ship, if
approved.
