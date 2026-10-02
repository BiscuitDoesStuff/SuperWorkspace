# Workspace outline v0.2

**Status: provisional draft, not an approved implementation plan.**
Authored 2026-10-01 from the latest available local evidence. This is the first
authored outline under the requested v0.2 label; no earlier outline is assumed.
The owner authorized drafting, not adoption of its recommendations.

Current implementation and authorization belong to [Workspace state](workspace-state.md).
Execution evidence, source cutoff and checks belong to the
[review task](../.sw/comms/tasks/workspace-state-review/).

## 1. Purpose and design direction

A reusable AI workspace for bounded project work: clear authority, discoverable
tools, proportionate coordination, recoverable changes and verifiable outcomes.
The generic core should support different project types without requiring every
AI-engineering technique, harness, connector or research area.

**Proposed direction:** strengthen the existing small core before expanding it.
Reuse current files, roles and checks; add a capability only for a demonstrated
failure or missing requirement. Simplicity is a starting point, not a claim that
simple systems always outperform complex ones.

Success means useful work meets project acceptance criteria and permissions,
can resume from durable evidence, preserves unrelated work, and has known cost
and verification limits. More agents, longer instructions or a higher leaderboard
score are not success measures by themselves.

Basis: cumulative corpus synthesis, "Convergent principles" [R1]; foundation
recommendations R1/R3/R4 [R2]. These are design interpretations, not replicated
proof of an optimal workspace architecture.

## 2. Evidence snapshot and authority

- **Completed evidence:** cumulative corpus through Pass 6, using the current
  claims register and dated updates rather than obsolete earlier report grades.
  Earlier foundations/frontier work supplies information, authority, evaluation
  and recovery distinctions; Passes 4-6 supply workspace-specific evidence [R1-R5].
- **Newest incoming evidence, checked 2026-10-01 at 08:50:45 UTC:** Pass 7 B1
  (benchmarks) and B2 (LLM judges) collection tables have arrived, with 34/120
  calls reported. They are preliminary: no synthesized report/register updates,
  retention verification, independent review or closure yet [R6]. Their proposed
  grades do not supersede reviewed claims. B3-B6 are pending at this cutoff.
- **Scope:** synthesis of local reports, register rows and collection tables,
  not a new audit of every original. No external research or direct ModelAnalysis
  access was performed. Incoming tables referencing that project retain its
  private/noncommercial/nonredistributable boundary; no data files are copied.
- **Authority:** research supports bounded recommendations, not project rules.
  Current policy remains in [AGENTS.md](../AGENTS.md), roles/permissions in
  [workspace guidance](../.sw/workspace.md), and records/publication in
  [collaboration guidance](../.sw/collaboration.md). This outline grants no work.

`Declared` means documented, not demonstrated enforcement. `Qualified` preserves
conditions and uncertainty. `Replicated (direction)` does not pool effect sizes.
`Contradicted` rejects an unconditional claim, not every possible use.
`Gap` means evidence was not established in the stated scope/searches.

## 3. Actual base: retain, do not rebuild

Observed 2026-10-01: SuperWorkspace 0.3.0-dev, generic profile, solo configuration,
GitHub tier 0, unborn local `main` and existing files untracked. Base setup is
complete; nine project agents, nine commands, eight base skills, RTK plugin and
the context7 MCP configuration are installed. Local tiers and the optional Claude
adapter are unconfigured. No new model/provider/harness is selected here.

Keep kit sources in `project/`, `lib/`, `global/` and `sw.ps1`; generated
installation remains under `.sw/`, `.opencode/`, `.agents/` and related manifest
paths. Project identity/state and execution records remain project-owned.
Do not create competing maintained copies or another memory/backlog hierarchy.

Static contracts and prior render/manifest checks passed. Runtime enforcement,
child routing and controlled resume are not certified; `doctor` remains blocked
by the recorded npm-launcher encoding exception. Diagnosis is not repair, and
that failure does not prove the Desktop runtime unusable [W1].

## 4. Proposed workspace outline

All directions below are proposals. Existing behavior stays unchanged unless a
separate approved task changes its owning source and validates the result.

### 4.1 Shared core and harness adapters

Retain OpenCode as the installed shared baseline, not a universal product winner.
Keep project instructions and portable skills canonical; optional harness adapters
should be thin, local/generated and tested for the exact version and directory.
Check loading/discovery through observable evidence, not a model's recollection.

**Basis/gate:** C067/C068/C080 are declared portability with differing semantics;
C069/C070 are single-machine, single-version Pass 4 observations, not Workspace
certification. C146-C151 add loading, truncation and listing qualifications [R3-R5].
An adapter needs a concrete use case and harmless loading/permission tests first.

### 4.2 Context, instructions and task continuity

Use short canonical startup instructions, a small current-state section and
on-demand detail. Preserve durable constraints and approved decisions in their
owning files; use existing task events for approval, progress, checks and resume.
Before continuing, reconcile records with actual files/Git and current authority.

Measure useful content, not file length alone. Ordinary context files showed no
significant success gain on studied Python tasks (C112, replicated direction),
not powered equivalence or proof that policy files are useless. Studies disagree
on cost/step effects; a universal increase is contradicted (C113). Tuned guidance
is model/task-specific (C114, qualified).

**Basis/gate:** [R4] section 2.1; C115 and C160 are separate qualified results,
with changing constraints confounding C160. C152 is qualified policy-file
evidence, C161 adjacent persona drift [R5] section 2.3. No fixed session length,
universal prompt recipe or automatic performance gain follows. Test any tuning
on the chosen acceptance case before broadening instructions.

### 4.3 Roles and orchestration

Use Leader-inline work by default when delegation adds little. Invoke existing
planning, architecture, implementation, build, documentation, research and review
roles for bounded responsibilities; do not require every role on every task.
Parallelize independent reads or genuinely separable work with explicit ownership,
assigned checkouts, dependencies and one validation owner per checkout.

**Basis/gate:** unconditional multi-agent superiority is contradicted (C089).
Matched-compute comparisons show no general advantage, with task-dependent gains
(C121, replicated direction) [R4] section 2.3. C091/C153 are qualified, different
spec-detail/workflow results, not a universal spec-first mandate. Adopt a team,
A2A or workflow engine only after measured coordination needs justify it.

### 4.4 Skills, tools, plugins and MCP

Inventory and reuse the installed skills, commands, RTK and context7 configuration.
For an addition, identify the missing capability, source/release, data flow,
privileges, cost, maintenance and recovery/removal plan; require explicit approval
and a harmless acceptance test. Treat supplied instructions and tools as untrusted
inputs, not authorization. Do not install marketplace collections by default.

**Basis/gate:** C082 and C154 establish directional skill risk, not pooled rates;
C154 has no approval-enabled runs. C088 concerns differing scanner flags, not
confirmed-malicious prevalence. Packaging/spec declarations (C141/C142/C144/C145)
and qualified simulated-host results (C143) are not compatibility or safety
certification [R3-R5]. Apply the foundation R4 selection gate [R2], not a new
registry, plugin framework or automatic protocol migration.

### 4.5 Local models, providers and cost

Retain local credentials/model mappings and the project's free-first policy;
metered use requires owner opt-in. Configuration is separate from proof of effective
child routing. Select a model/harness/effort/tool configuration for representative
tasks and permitted data, with quality, total effort and failures measured together.

**Basis/gate:** labels and advertised context are not usable-capacity guarantees
(C001 qualified; C002 declared). Local-model adequacy remains a gap (C094).
Provider terms are dated declarations with feature/product exclusions, not audited
retention guarantees (C132-C136/C157-C159); C162 is possibly outdated consumer-only
evidence [R4-R5]. Do not select a provider or promise ZDR from these summaries.
Recheck actual terms and versions before separately approved sensitive-data use.
Preliminary Pass 7 leaderboard disagreements strengthen the need to preserve
metric, harness, provenance and capture date, not to name a model winner [R6].

### 4.6 Memory and knowledge persistence

Keep authoritative project files and task records first. Do not add a vector store,
graph, database or autonomous memory writer just to supply a memory category.
Any additional memory needs a demonstrated retrieval/update problem, write authority,
provenance, dates, correction/expiry handling and comparison with simpler baselines.
Retrieved or summarized material never acquires policy authority automatically.

**Basis/gate:** poisoned persistence and stale-memory failures are directionally
replicated (C076/C077); downstream behavior is model-dependent. General memory
superiority is contradicted (C078), coding-file-memory effects remain a gap (C079),
and read savings can be offset by write cost (C119) [R4-R5]. C117 concerns some
attacks evading tested screens; C118's A-MemGuard negatives are two different
single-family results. A defence is not a general robustness guarantee.
Clearing active context is distinct from purging stored data (C005, declared).

### 4.7 Permissions, isolation and effects

Preserve human-owned publication and action-level approval. Describe controls as
enforced, guardrail or stated; do not call shell-pattern rules a sandbox. Inspect
data destinations and resolved write targets where relevant, and reconcile an
ambiguous effect before retrying it. Untrusted repositories/connectors need a
separately approved isolation/data-access decision, not trust in prompt wording.

**Basis/gate:** action choice differs from authority, and timeout is not proof of
no effect (C006/C007, declared) [R1]. Adaptive attacks limit model-only defences
(C033 replicated; C034/C035 qualified) [R7]. C101 concerns differing symlink/consent
failures; C102 remains a repository/tool-injection efficacy gap. C155 measured
hardening cost, not attack efficacy; C156 tested a compromised router, not a
repository attacker [R5]. No safe permission mode or sandbox is certified here.

### 4.8 Lifecycle, preservation and recovery

Retain existing initialization/update mechanisms without rerunning setup. Before
lifecycle changes or distribution, propose focused fixtures for fresh installation,
clean updates, local edits, managed blocks, renames and `WhatIf` preservation.
Distinguish installed manifest integrity from recovery of the whole project.

**Basis/gate:** Workspace has no committed recovery baseline, and ordinary checks
do not prove all preservation scenarios [W1]. Full Windows environment
reproducibility/removal remains a gap (C104). A general uninstall is not an existing
CLI command. Any backup, commit, cleanup or removal needs explicit owner scope;
never discard existing work or treat a same-disk copy as independent recovery.

### 4.9 Evaluation and operational verification

Propose one owner-selected real task before capability expansion, then a small
representative task set if needed. Define outcome checks, constraints, failure and
abstention cases, resume/correction behavior and resource limits before comparison.
Record versions/configuration and human correction effort; repeat trials when
their uncertainty matters and an approved budget permits it. Prefer executable
outcome checks where possible; calibrate any model judge against task-specific
human judgments and allow an unknown result.

**Basis/gate:** C008 distinguishes tool success from actual state; C009/C010 are
qualified variance/judge findings. C106 qualifies benchmark fragility; C108 remains
a workspace-evaluation gap [R1/R3]. New Pass 7 B1 rows 2/6/7/9/10 and B2 rows
1/5-9/12-15 are preliminary: leakage, scaffold conditions, uncertainty and judge
criterion/generation matter. Bias direction is not universal; no judge reliability
transfer or exact current-model ranking is assumed [R6].

Keep static contracts, runtime discovery, permission decisions, harmless workflow
tests and independent review separate. Add neither an eval platform nor telemetry
by default; useful diagnostic evidence must respect content/privacy boundaries.

### 4.10 Optional profiles and non-code work

Keep generic as the active profile. The kit also contains an Unreal profile;
its presence is not a request to install it. Optional harnesses, remote access,
domain profiles, knowledge connectors and non-code workflows remain possible,
not mandatory components of v0.2.

**Basis/gate:** knowledge-workspace features are declared (C097), but non-code
outcomes and builder quality/popularity remain gaps (C098/C100). C099 is qualified
access-control risk, not a universal builder verdict [R3/R5]. Choose a concrete
use case, permitted data and acceptance criteria before proposing an addition.

## 5. Proposed sequence and acceptance gates

These are candidate tasks, not an authorized queue of implementation work.

| Gate | Bounded next outcome | Completion evidence / dependency |
| --- | --- | --- |
| A. Draft quality (this task) | Evidence-linked outline and accurate current docs | Static/hygiene/link checks; preserved managed definitions; read-only review; explicit caveats and owner decisions |
| B. Recovery decision | Owner selects screened baseline and independent recovery approach | Defined source/data/local exclusions and recovery evidence; commit/backup actions only if separately authorized |
| C. Operability and check coverage | Read-only launcher diagnosis; separately scoped diagnostic/validation corrections if justified | Exact harmless probe evidence; preserve remaining diagnostics; ordinary project links/untracked hygiene/drift covered with targeted failure cases |
| D. Runtime readiness | Directory-scoped discovery, permission decisions and harmless dispatch/skill/resume | Usable approved invocation; exact version/directory; separate actual results; no destructive denial probes |
| E. Real-work value | One representative task using the existing core | Owner-selected outcome oracle, constraints and budget; verification/correction/resume and effort evidence; comparison only where useful |
| F. Targeted expansion | One identified gap, not a bundled capability programme | Owner approval, relevant refreshed evidence and narrow acceptance test; preservation fixtures precede lifecycle changes |

Recovery decisions and read-only diagnosis can be scoped independently. Runtime
tests depend on usable invocation; configuring tiers is not a prerequisite for
finishing this outline. Complete removal, new memory, agent teams and adapters
remain deferred unless a real case justifies them. New research can revise these
proposals but does not authorize any gate automatically.

## 6. Limits and corrections that survive this draft

- Use corrected **C141-C162**. C115 stays qualified; C160 is separately qualified
  due to turn/constraint confounding. C161 is adjacent persona drift; C162 does
  not establish current commercial/API retention.
- C117 covers some attacks/screens, with differing detectors; M255 was attacker-run
  and paraphrasing neutralised AgentPoison there. C118's different single-family
  A-MemGuard negatives are qualified. C088 has minority shares from only two
  sources; another gives a count without a denominator. No pooled malicious rate.
- C154 remains directional replication across varying configurations, with no
  approval-enabled run; discount M202's Snyk interest without declaring the family
  non-independent. C156 does not resolve repository/tool-injection efficacy.
- Independent review was bounded: some harness, safety, provider and memory sources
  were unread; C129/C131 lack independent source reads. M254's date mismatch and
  manifest locators saying `report pending` remain unresolved [R5].
- Original Pass 6 `freeze --tag` **failed on six archived scratch links**. A later
  exclusion probe found other archive/source/evidence/protected objects exact;
  live links/tooling were corrected, but the frozen archive/tag stayed unchanged.
  Archive verification reported `sources_checked: false`. Do not call the original
  freeze a pass. The report's review/commit status is stale despite verified closure.
- No Pass 6 lab observations exist; absence findings mean not found in named
  searches. Retention audits, approval-mode efficacy, non-Python context-file work
  and third-party adaptive memory-defence tests retain their bounded gaps.
- Pass 7 findings are unreviewed collection output. B1 has blocked primaries and
  incomplete contamination coverage; B2 is preprint-only, with limited calibration
  replication, missing workspace/multilingual coverage and an N155 inconsistency.
  Its child model/effort and source-retention verification remain unverified.
- Corpus evidence is local-only/no-redistribution; its same-disk bundle is not an
  independent off-machine backup. No corpus checks were rerun by this task, and no
  Workspace runtime or routing guarantee follows from static/documentation checks.

## 7. Decisions for the owner

1. Accept or revise this small-core direction; the draft is not assumed approved.
2. Choose a first real-work acceptance case, permitted data and cost/effort limits.
3. Select the next bounded readiness task and any separately authorized recovery
   action. Do not interpret the gate table as permission to execute it.
4. Reconsider evaluation/model-selection/prompting/cost/adoption/productivity
   proposals when Pass 7 is synthesized and independently reviewed. No automatic
   research cadence, model winner or capability purchase is selected.

## 8. Source map

`R` citations below are paths relative to the owner's read-only research corpus,
whose local checkout/revision is identified in the task record. They are code
citations, not Workspace-relative links or copied evidence. Claim IDs refer to
the current corpus `docs/research-claims.md`; the cited reports retain source
locators, configuration limits and contrary evidence.

| Ref | Local source / relevant sections |
| --- | --- |
| W1 | Workspace [state/structure review](../.sw/comms/tasks/workspace-state-review/2026-10-01T080559Z-leader-review.md), [base setup](../.sw/comms/tasks/workspace-base-setup/2026-10-01T074334Z-leader-submission.md); actual `sw.ps1`, `lib/Sw.Kit.psm1`, `lib/Sw.Project.psm1`, `project/roles.json` and installed manifest |
| R1 | `docs/research/initial-pass-overview.md`, findings; `docs/research/cross-dossier-synthesis.md`, "Convergent principles" and tensions; cumulative `docs/research/ai-engineering-landscape.md` updates |
| R2 | `docs/research/ai-research-foundation.md`, R1-R4 (method/tool-gate recommendations, not a proven optimal workflow) |
| R3 | `docs/research/workspaces-04.md`, summary and W01-W10 findings, updated through current register notes rather than its obsolete grades |
| R4 | `docs/research/workspaces-05.md`, sections 2.1-2.6 and recommendations, with later dated corrections applied |
| R5 | `docs/research/workspaces-06.md`, sections 2.1-2.6; `.sw/comms/tasks/workspaces-06/2026-10-01T080311Z-leader-review.md` and `.sw/comms/tasks/workspaces-06/2026-10-01T080559Z-leader-closure.md`; `docs/decisions.md`, post-Pass 6 housekeeping |
| R6 | `.sw/comms/tasks/frontier-breadth-07/2026-10-01T084942Z-leader-progress.md`; `.scratch/frontier-breadth-07/findings/B1.md` rows 2/5-11 and `.scratch/frontier-breadth-07/findings/B2.md` rows 1/5-9/12-15 plus gaps (preliminary, proposed grades only) |
| R7 | `docs/research/frontier-depth-03.md`, section 2.2 and post-closure qualifications; current register C033-C035 |

The inherited `00-10` design dossiers are historical inputs, not current research
evidence. Repeated recommendations across reports are not independent replication.
