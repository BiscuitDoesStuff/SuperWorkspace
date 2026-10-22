# 12: Development workflow methods for T3 Code

Status: complete (recommendation, not approved); 2026-10-15 by the current
Leader. Owner request: decide
thoroughly which workflow method the Workspace workflow skills should follow,
under the owner precedent (2026-10-15) that a better-evidenced option replaces
the current system. Sources accessed 2026-10-15 unless a page date is given;
raw text saved outside the repository and re-read for each finding.

## 1. Question and scope

Which development workflow method (how a task goes from request to merged,
verified change) should Workspace use on T3 Code with Claude and Codex:
the current Workspace process, a third-party method adopted as-is, or a
composite, and on what evidence?

Sub-questions:
1. Criteria: which of topic 11's goals (11-F1) a workflow method serves.
2. Candidates: current Workspace process; Superpowers; GitHub Spec Kit; BMAD
   Method; Every's Compound Engineering; OpenAI ExecPlans; Anthropic's
   published Claude Code practice.
3. Each candidate's mechanics, licence, harness support, maintenance status
   and measurements.
4. Independent evidence on the shared components (tests first, plan or spec
   first, independent review, per-task fresh context, captured learnings).
5. Comparison and recommendation.

Out of scope: implementation; live trials; model choice (topic 3).

Not covered here: GSD ("get-shit-done"), Agent OS and Kiro specs, assessed
later in [topic 13](13-agentic-leverage.md) F1-F3 and R6; any controlled comparison of whole methods (none found);
code-specific studies of cross-model review (the self-preference evidence in
F12 is not code-specific; transfer is my inference).

Budget: 16 research calls (6 searches, 10 fetches) of a 30-call cap the
owner's request for thoroughness allowed. Corpus claims are cited as `C<nnn>`
(ResearchProj `docs/research-claims.md`, local); topic 11 as `11-F<n>`.

## 2. Findings

### Candidates

F1. **Current Workspace process.** `/work` asks the Leader to clarify,
present a scoped plan and, once approved, execute "to completion" with "the
smallest useful team"; `project-planning` decomposes into "smallest
independently verifiable steps" with owners and validation; approvals and
evidence live in `.sw/comms/tasks/`; review (`/review`) is optional;
`minimal-change` governs edits. There is no test-first rule and no standing
independent review. Local: `project/base/.opencode/commands/work.md`,
`project/base/.agents/skills/project-planning/SKILL.md`, read 2026-10-15.

F2. **Superpowers.** "A complete software development methodology ... built on
top of a set of composable skills". Mandatory, auto-triggered sequence:
brainstorming, `using-git-worktrees` ("Creates isolated workspace on new
branch"), `writing-plans` (2-5 minute tasks with exact paths and verification),
then `subagent-driven-development` or inline `executing-plans`, TDD
("Deletes code written before tests"), review between tasks, branch finishing.
Its execution skill dispatches "a fresh implementer subagent per task, a task
review (spec compliance + code quality) after each, and a broad whole-branch
review at the end", and notes the cost: "a fresh context per task and per
review". Plugins for Claude Code and Codex among many hosts. MIT; 299k stars;
last push 2026-10-10. No measurements. README and
`skills/subagent-driven-development/SKILL.md` of
[obra/superpowers](https://github.com/obra/superpowers), main branch.

F3. **GitHub Spec Kit.** "Constitution once per project; specify → plan →
tasks → implement → converge per feature", plus separate bug-fixing and
idea-assessment processes; artifacts under `.specify/`; installed with a
`specify` CLI (uv). MIT; 141k stars; last push 2026-10-14. README of
[github/spec-kit](https://github.com/github/spec-kit), main branch.

F4. **BMAD Method.** "Agile Ai Driven Development": specialised agent
perspectives (product, architecture, UX, development, testing), artifacts
that carry decisions forward, and a process that "sizes itself to the work"
("Small changes go straight to build"). Stable v6.12; v7 is "preview alpha"
with "breaking changes between updates". Skills or plugins for Claude Code
and Codex. LICENSE text is MIT (GitHub reports NOASSERTION); 54k stars.
README of [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD), main branch.

F5. **Compound Engineering (Every).** A 36-skill plugin with the loop
brainstorm → plan → work → simplify → review → compound, where `ce-compound`
writes learnings to `docs/solutions/` that later plans read; "80% is in
planning and review, 20% is in execution"; review is "report-only
multi-agent"; `/lfg` runs the pipeline hands-off and "then commits". Runs on
14 hosts including Claude Code and Codex. MIT; 25.5k stars; last push
2026-10-15. README of
[EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin), main branch.

F6. **OpenAI ExecPlans.** A `PLANS.md` meta-document tells Codex how to write
per-task ExecPlans: "fully self-contained", "a living document", must
"produce a demonstrably working behavior", with mandatory `Progress`,
`Surprises & Discoveries`, `Decision Log` and `Outcomes & Retrospective`
sections; "it should always be possible to restart from only the ExecPlan".
The page states: "This recipe is archived and may reference outdated models or
APIs." [OpenAI Cookbook, "Using PLANS.md for multi-hour problem solving"](https://developers.openai.com/cookbook/articles/codex_exec_plans), no page date.

F7. **Anthropic's Claude Code practice.** Headings "Give Claude a way to
verify its work" and "Explore first, then plan, then code"; for small, clear
changes "ask Claude to do it directly"; for larger features "have Claude
interview you and write a spec before you start implementing"; a second
opinion from "a verification subagent ... has a fresh model try to refute the
result". [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices), no page date.

### Evidence on components

F8. **Tests as executable specifications raise correctness.** An iterative
class-level TDD framework "consistently improves class-level correctness by 12
to 26 absolute points" across eight LLMs against the best direct-generation
baseline. [Scaling Test-Driven Code Generation from Functions to Classes, arXiv 2602.03557, 2026-02-03](https://arxiv.org/abs/2602.03557).
TENET (repository-level TDD) improves Pass@1 by 9.49 and 2.17 points over the
strongest baselines on RepoCod and RepoEval.
[arXiv 2509.24148, v4 2026-08-13](https://arxiv.org/abs/2509.24148). Both are
benchmark settings with given tests, not end-to-end agent workflows.

F9. **Spec-driven pipelines gain little on their own; grounding matters.**
Adding read-only repository-probing and validation hooks to a Spec Kit
pipeline improved judged quality by "+0.15 on a 1-5 composite LLM-as-judge
score (+3.0 percent of the full score)" over 128 runs and SWE-bench Lite Pass@1
by 1.7 points; agents are otherwise "context blind" in large repositories.
[Spec Kit Agents, arXiv 2604.05278, 2026-04-07](https://arxiv.org/abs/2604.05278).
No study isolated the value of the spec phases themselves (**weak**).

F10. **More roles and agents are not a free gain.** At matched compute,
multi-agent structure shows no general advantage (C121, replicated
direction); end-to-end accuracy fell well below subtask accuracy across 11
roles (C243, qualified). This weighs against persona-heavy methods (F4) and
against fan-out by default (F5 review), not against isolated reviewers.

F11. **Captured "learnings" have no controlled evidence and a staleness
risk.** No controlled study of file-based coding-agent memory was found
(C079, gap); agents handle superseded facts in memory poorly (C077,
replicated direction). Local: ResearchProj `docs/research-claims.md`, read
2026-10-15.

F12. **Models favour their own outputs when judging.** "An LLM evaluator
scores its own outputs higher than others' while human annotators consider
them of equal quality", and self-recognition correlates linearly with that
bias. [LLM Evaluators Recognize and Favor Their Own Generations, arXiv 2404.13076, 2024-04-15](https://arxiv.org/abs/2404.13076)
(NeurIPS 2024). Supports a reviewer from a different model family; transfer
to code review is my inference.

F13. **Success claims need execution evidence.** A fluent answer or
successful tool call does not establish the intended state (C008); one
success across attempts overstates consistent success (C063). Local: ResearchProj
`docs/research-claims.md`, read 2026-10-15. Matches F7's "give Claude a way to
verify its work".

## 3. Options compared

Criteria from 11-F1, restricted to what a workflow method controls. Scores:
strong / partial / weak / conflicts, with the deciding finding.

| Criterion | Workspace (F1) | Superpowers (F2) | Spec Kit (F3) | BMAD (F4) | Compound (F5) | ExecPlans (F6) | Anthropic (F7) |
|---|---|---|---|---|---|---|---|
| Approval and records | strong | weak (design sign-off only) | partial (artifacts) | partial (artifacts) | weak; `/lfg` commits | partial (decision log) | weak |
| Verified quality | weak (no test-first, review optional) | strong (TDD, per-task review; F8) | partial (converge) | partial | strong review, simplify | strong (observable outcomes) | strong (verify, refute; F13) |
| Review independence | weak | same-model reviewers | n/a | same-model personas | multi-agent, optional cross-model | n/a | fresh-context verifier |
| Right-sized | partial (implicit) | partial (mandatory sequence) | weak for small work | strong (claims) | partial | large tasks only | strong |
| Context cost | 24 KB governance (11-F3) | bootstrap plus many skills | moderate | heavy (21+ agents) | 36 skill descriptions | one file per task | none extra |
| T3 Code fit | needs rewrite (11-F2) | conflicts: creates its own worktrees/branches | neutral | neutral | partial: own worktree/commit skills | neutral | native to Claude |
| Dependency and stability | none | third-party, fast-moving | CLI install | v7 alpha | third-party, fast-moving | archived recipe, no install | none |
| Evidence | none | components only (F8) | weak (F9) | against personas (F10) | gap for learnings (F11) | none | vendor guidance |

No candidate dominates. Every third-party method lacks Workspace's approval
and record contract, and Superpowers and Compound Engineering include their
own worktree, commit or autonomous-ship steps that conflict with T3-owned
worktrees and commit-on-request. But several components are better-evidenced
than the current process, so under the precedent they should replace it.

## 4. Recommendation

R1. **Replace the current process with a composite method built from the
best-evidenced components, natively in Workspace skills, with provenance
recorded per step.** No third-party method is installed. The steps:

1. **Route by size** (F4, F7): clear small changes go straight to execution
   under the existing authority rules; normal work gets a plan in chat;
   large or multi-session work gets a plan file.
2. **Clarify by interview** when requirements are unclear (F2, F7), not as a
   mandatory preamble.
3. **Plan files follow the ExecPlan shape** (F6): self-contained, living,
   observable outcomes, `Progress`, `Decision Log`, `Surprises`,
   `Outcomes`. It lives in the task record and is the restart point
   (replaces ad-hoc plan events).
4. **Define the check before the change** (F7, F13); **tests first** where
   the project has tests (F8).
5. **Execute inline by default**; long plans use a fresh worker per task
   (F2's per-task pattern) through T3 worktree threads or subagents
   (topic 11 R4).
6. **Simplify pass** on the diff before review (F5).
7. **Independent review by the other provider** (F12): final review for
   normal work, per-task review inside long plans (F2).
8. **Close with execution evidence** (F13) in the task record. A learnings
   note is optional, dated and reviewed, never auto-loaded as rules (F11).

R2. **Keep third-party methods as evaluated alternatives with a revisit
trigger.** Re-evaluate when a method publishes controlled measurements, when
a live Workspace trial shows a measurable gap, or when its conflicts (F2, F5
worktree and commit steps) are removable by configuration. Under the
precedent, a demonstrated better option then replaces the composite.

R3. **Prove it with a small bake-off before declaring the method final.**
With owner approval of models and cost: run the composite against
Superpowers on 3-5 representative Workspace tasks, scoring completed
acceptance criteria, review findings, rework and tokens. This is the only
route to direct evidence (F9-F11 show none exists).

## 5. Open questions

Owner answers recorded 2026-10-15 (this thread): review routing set to Codex by
default (outline D7); Q1 yes, with the precedent that third-party installs are
not avoided when they are the best or most maintainable option (outline D8);
Q2 no trial; Q3 needs more help deciding; Q4 yes, and widen to agentic
techniques that raise quality or cut cost and time (topic 13). Q3 answered
later the same day: a dated lessons line in the task's closing summary, and
lessons that recur or cause a failure are promoted into a rule, check or skill
after review; nothing is auto-loaded (options B plus D).

1. Owner: adopt R1's composite as the Workspace method (replacing the current
   `/work` flow)?
2. Owner: approve the R3 bake-off later (models, task set, cost cap), or
   accept the composite on the component evidence alone?
3. Owner: allow an optional, reviewed learnings note (R1 step 8), or leave
   learnings out entirely given F11?
4. Not covered: GSD, Agent OS, Kiro; tell me if any of these should be added
   before the decision.

## 6. Supersedes / updates

Extends 11-R2 (workflows as skills) with the method those skills encode and
11-R4 (review by the other provider) with F12. Would supersede the current
`/work` and `project-planning` flow (F1) if R1 is approved. No decision is
changed by this file alone.
