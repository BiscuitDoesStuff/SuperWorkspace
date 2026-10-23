# 16: Public skills, plugins and MCP defaults

Date: 2026-10-19 UTC. Status: E0 candidate-source inspection complete; E1
delivery contract prepared under the owner's approved execution slice.
The owner accepted the delivery contract and E3 read-only synthetic preview;
catalogue and skill-revision recommendations remain unselected. No shipped
or installed defaults changed.

## 1. Question and scope

Which skills should the public SuperWorkspace product distribute and select,
and which plugins and MCP integrations should it offer or enable by default?
Use this repository and the owner's local research corpus first; consult the
web only for a material unanswered question.

Owner's audience clarification: a general foundation, with research and
software development equally included by default. This is the selected target,
not approval of the individual recommendations below. Unreal remains an
optional specialist recommendation.

Sub-questions: what ships today; what local evidence changes the choices;
which capabilities add distinct value; how distribution, installation and
enablement differ; what evidence is needed before adoption?

Owner steering, 2026-10-19 UTC: first inspect individual public common skills
used or recommended by ECC, Hermes and source documentation. Compare actual
instructions, scoped licenses, overlap, general/research/software usefulness
and dependency assumptions. This extends the source review; it does not select
the earlier revision/prototype proposal or model-comparison budget. Use saved
local material first, with a new ceiling of 20 external requests for gaps.

Scope excludes installation, changing generated definitions/defaults, external
corpus edits, global settings and publication. No exhaustive marketplace
survey or live integration benchmark is implied. E0 inspected exact frontend
and data sources/licenses plus a synthesis method; service terms, account
entitlement and unrelated format skills were not audited.

Evidence basis: repository sources inspected 2026-10-19; saved primary-source
text and reports in the owner's local research corpus, including its newer
2026-10-18 documentation captures. Source capture dates appear
below; reading saved text today is not a new verification of the live page.
The newer catalog describes an Oct 16 listing snapshot with Oct 18 text; the
catalog alone is not a content review. Bulk text can lag individual pages.
Private locators, corpus revision and inspection evidence stay in the local
task record; no corpus captures are redistributed here.

External research calls: **9 of 12** for E0/E1 (four candidate-source requests,
five targeted native/method requests, including one failed official-index
lookup; eight successful responses saved outside the repository). The earlier
local-only reassessment used zero. The subsequent G1 extension used **4 of 20**
new external requests (two HEAD metadata bodies and two pinned archives), all
successful, plus saved primary documentation. Source inspection supports the revised
proposals below, not adoption; runtime and benefit checks remain unrun and
need their selected evaluation scope.

## 2. Findings

### F1. Public distribution and default availability are different

Local, observed 2026-10-19: the kit contains **11 skill sources**. Its
[selection catalogue](../../project/selection.json) selects nine core skills;
the [research preset](../../project/profiles/research/profile.json) adds the
research capability, and the
[Unreal preset](../../project/profiles/unreal/profile.json) adds
`unreal-validation`. Thus a fresh selection-enabled generic preset has nine,
research ten, and Unreal ten without additional capabilities.

The [renderer](../../lib/Sw.Kit.psm1) filters source files and emits copies for
both project harness folders. Legacy configurations without selection keep
all base skills. The [resolver](../../lib/Sw.Project.psm1) has a fixed
six-workflow-skill floor and additive capabilities: it cannot currently express
arbitrary per-skill removals. The future central linking mechanism is separate
work, not an already-installed global default.

Use these distinct columns for every future release:

| Choice | Meaning | Proposed baseline |
| --- | --- | --- |
| Public distribution | Content actually included in the public product | Retain the 11 existing sources, subject to individual revisions below; no new third-party content or server binaries |
| Default selection | Skills made available when installing the normal preset | Provisional nine common skills after revisions; agent-documentation and Unreal optional. New capability gaps must be assessed before final selection |
| Invocation / enablement | Whether the agent can invoke a skill or start/use an integration | Preserve existing explicit workflow controls; no external plugin or MCP enabled by the kit |

Selecting a skill for availability is not authority to collect research,
delegate, install, publish or change settings. Generated availability and
runtime enforcement are different evidence.

### F2. The kit configures no plugin or MCP defaults

Local: [outline O7/O11](../workspace-outline.md#3-current-controls-and-inherited-choices),
[setup](../setup.md), and the source inventory, inspected 2026-10-19. RTK is an
optional native CLI, not a current shipped MCP/plugin default. T3's browser,
GitHub and orchestration capabilities belong to the app/runtime, not the kit.

This says what the kit configures. It does not establish that a user's effective
session has no plugins or skills: bundled, account-synced and personal content
may already load independently.

### F3. Useful skills are task-specific; a numerical library cap is unproven

Saved primary evidence re-read 2026-10-19:

- [SkillsBench](https://arxiv.org/html/2602.12670), v4 dated 2026-06-14,
  captured 2026-10-02: curated skills improved results across its aggregate,
  but task construction rejected tasks with no measurable separation. The
  headline gain is not an expected gain for arbitrary public skills.
- [SWE-skills evaluation](https://arxiv.org/html/2603.15401), v1 dated
  2026-03-16, captured 2026-10-02: 39 of 49 skills had no pass-rate gain;
  some version-mismatched skills caused harm. One tested configuration limits
  generalization.
- [Failure reanalysis](https://arxiv.org/html/2608.11888v1), published
  2026-08-12, captured 2026-10-02: excessive procedure caused 114 of 182
  efficiency regressions. It reuses earlier datasets, so it is not a third
  independent benchmark family.
- [Skills practice article](https://claude.dev/blog/lessons-from-building-claude-code-how-we-use-skills/),
  published 2026-06-03, captured 2026-10-18: describes hundreds of internal
  skills and selective installation/progressive loading. This is a vendor
  practice report, not controlled efficacy evidence.

The earlier [S6](../workspace-outline.md#s6-skills-curation) one-to-three
guidance should not be read as an empirically proven cap on a distributed or
installed library. Its benchmark basis concerns task bundles. Nor does the
practice article establish that a large library helps this product. Recommend
keeping compact procedures and measuring relevance, invocation and accepted
outcomes; the owner selects any revision to S6. No new benchmark was run here.

### F4. Newer local docs increase the overlap with generic bundles

[Claude skills documentation](https://code.claude.com/docs/en/skills), captured
2026-10-18, documents bundled review/debug/batch skills and app run/verification
skills. It also describes account-synced document skills in eligible sessions.
Some native workflows write or commit project skills, so they need policy
reconciliation before being recommended as Workspace procedures. These are
documented Claude behaviors, **not verified T3 behavior or Codex parity**.

The same saved page says overriding a bundled skill's primary name does not
override its aliases; it gives bundled `/review` as an example. This is a
specific acceptance risk for Workspace's `review` name. P1/M5 must verify the
actual command-to-skill mapping before adoption and decide whether naming or
wiring needs revision. No collision or safe override is established by this
documentation-only task.

[Marketplace documentation](https://code.claude.com/docs/en/plugins/anthropic-marketplaces),
captured 2026-10-18, says most entries in the official catalog come from
partners/other authors. A catalog listing is not evidence of a first-party
implementation or a cross-harness capability.

This strengthens the case for comparing a specific missing outcome before
adding generic review, debug, commit or feature-development plugins. Existing
Workspace methods and the older bundle comparisons are in
[topic 12](12-workflow-methods.md#3-options-compared) and
[topic 14](14-shared-capabilities.md#ecc-and-similar-collections), accessed
2026-10-15/16. Those older findings are dated, not a fresh audit of each bundle.

### F5. Installation is operational behavior, not just packaging

[Claude plugin security documentation](https://code.claude.com/docs/en/plugins/security),
captured 2026-10-18, documents plugin processes, hooks and background updates,
and says installation normally enables a plugin unless `defaultEnabled: false`
applies. A disabled-sounding catalogue entry alone is not a safe way to promise
an inert installation. D11 preservation applies to automatic update/removal
paths as well as explicit installer commands.

[Topic 14 F19](14-shared-capabilities.md#second-pass-routes-without-copies-or-links) inspected Codex
plugin cache replacement/removal and background refresh at source pin
`6ae8b8aa7c60` on 2026-10-16. No newer local Codex preservation evidence was
found. Retain the deferral until a selected version proves the required
behavior; this is not a claim about every current Codex release.

### F6. Redistribution rights need content-specific evidence

Local: [existing notices](../../THIRD_PARTY_NOTICES.md) cover the kit's adapted
MIT material, with license texts checked 2026-10-11. Keep those notices.

The [Anthropic skills README](https://raw.githubusercontent.com/anthropics/skills/main/README.md),
captured 2026-10-01, distinguishes many Apache-2.0 examples from source-available
`docx`, `pdf`, `pptx` and `xlsx` skills. Do not infer redistribution permission
for those files from the repository's general branding. E0's scoped frontend
and data license findings are in F8; those Anthropic format licenses remain
unchecked. F10 separately inspects Hermes format candidates and scoped MIT
licenses; their terms are not inferred from the Anthropic files.
System-provided skills in an agent session are also not
automatically product assets or licensed for copying into this repository.

### F7. Several useful outcomes are not covered by the current procedures

Local source review, 2026-10-19: `research` is triggered by outside facts and
centres on fetching primary pages and producing one cited Markdown report.
It does read existing research, but does not teach corpus synthesis or local
quantitative analysis. `work` plans execution; `validate` checks changed work.
Neither supplies a visual design method. Audience parity therefore requires
assessing these gaps, not merely making today's research skill default.

The local corpus contains a completed cross-dossier synthesis, dated
2026-09-29/30, with source-family distinctions, tensions, reused evidence and
coverage limits. This is a **Local output example**, not a reusable skill or
proof of benefit. The saved [skills practice article](https://claude.dev/blog/lessons-from-building-claude-code-how-we-use-skills/)
describes investigation runbooks; project-specific runbooks are not automatically
a general synthesis method.

Two other saved sources support narrower leads:

- [Frontend design article](https://claude.com/resources/articles/improving-frontend-design-through-skills),
  published 2025-11-12, captured 2026-10-18: actual prompt text addresses
  typography, colour, motion and backgrounds. Its examples are vendor
  demonstrations. At the initial reassessment the current skill/license had
  not been inspected; F8 records the later exact-source check.
- [Data plugin description](https://claude.com/marketplace/plugins/data),
  captured 2026-10-18: names local CSV/Excel analysis, data profiling, SQL,
  visualisation and checks for incorrect aggregation/survivorship bias.
  That initial description-only evidence establishes advertised scope, not
  quality or a reason to adopt the whole plugin. F8 now adds source inspection.

The [skill-creator announcement](https://claude.com/resources/articles/improving-skill-creator-test-measure-and-refine-agent-skills),
published 2026-03-03, captured 2026-10-18, documents clean-context evaluations,
with/without comparisons, blind output comparisons and trigger tuning. It
distinguishes encoded workflow preferences from capability improvements. Both
need evaluation; an incumbent preference has no automatic claim to default
status. These documented methods are not evaluations performed here.

### F8. Exact candidate sources narrow the proposals

Primary sources fetched and inspected 2026-10-19; immutable repository pins
and raw-body/file hashes are retained in the local execution record.

- **Frontend:** [SKILL.md](https://github.com/anthropics/skills/blob/dbd4588f9e1033efb41dad4bef2f7947c8993d44/skills/frontend-design/SKILL.md)
  and [scoped license](https://github.com/anthropics/skills/blob/dbd4588f9e1033efb41dad4bef2f7947c8993d44/skills/frontend-design/LICENSE.txt),
  revision committed 2026-10-09. The current method grounds design in the
  audience/job, creates compact visual principles, checks the brief, builds
  and critiques. It explicitly prioritizes the brief and includes mobile,
  keyboard focus and reduced-motion guidance. The older article's font bans
  and Google Fonts prompt are not this revision. Its assumed rejected prior
  designs, confirmation and optional memory/comparison suggestions need
  adaptation to session authority; they grant no extra trial or persistence.
- **Local analysis:** inspected individual [data skills](https://github.com/anthropics/knowledge-work-plugins/tree/33eeda1e8fd856455b05479d13a0f85b5f803744/data/skills)
  at revision committed 2026-10-16: analyze, explore-data,
  statistical-analysis and validate-data teach grain/keys, missingness,
  population/denominators, join expansion, weighted aggregation, comparable
  periods, uncertainty and reproducibility. Supporting visualization/query/
  context packaging files were also inspected, with dashboard/SQL reference
  sections read selectively. These are Markdown procedures; the only data
  script packages generated warehouse-context skills, not local analysis.
  That script's ZIP overwrite behavior, remote connectors, mutating SQL and
  new plotting dependencies do not belong in the local-table baseline. A
  dashboard template loads a CDN despite an offline claim. README invocation
  names lag actual skill names. Fixed statistical thresholds and simplified
  rules need revision; units still need explicit acceptance coverage.
- **Licensing:** the frontend scoped license and clean [data/LICENSE](https://github.com/anthropics/knowledge-work-plugins/blob/33eeda1e8fd856455b05479d13a0f85b5f803744/data/LICENSE)
  explicitly state Apache-2.0. Neither fetched archive has a NOTICE entry;
  the data repository's root license has unrelated trailing prose, so do not
  substitute it for the scoped file. Borrowing still requires the applicable
  license/notices and modified-file notices. Nothing was copied into the kit;
  future fonts, assets and libraries need their own evidence.
- **Synthesis:** [Gale et al., Framework Method](https://doi.org/10.1186/1471-2288-13-117),
  published 2013-09-18, [full text inspected](https://www.ebi.ac.uk/europepmc/webservices/rest/PMC3848812/fullTextXML)
  (article CC BY 2.0), provides familiarisation, coding, an evolving framework,
  a case/category matrix with quotation locators, interpretation and an audit
  trail. It focuses on qualitative health/interview analysis, permits document
  adaptation, and warns against highly heterogeneous comparisons and counting
  themes as population frequency. Adapt a claim/source-family matrix within
  research; add explicit reuse/conflict/coverage handling from local needs.
  This is a proposed adaptation, not a systematic review or validated method
  for automated research synthesis.

The evidence supports two focused instruction-only prototypes and a synthesis
mode in research. It does not establish added task benefit, choose analysis
packaging or justify the whole plugin. E0 defines 14 outcome/negative-control
case pairs before revisions; G1 selects the actual trial scope and budget.

### F9. Native loading adds acceptance cases, not a proof

[Official OpenAI skill documentation](https://learn.chatgpt.com/docs/build-skills)
and [instruction discovery](https://learn.chatgpt.com/docs/agent-configuration/agents-md),
fetched 2026-10-19, document shared user skills in `~/.agents/skills`, symlink
following, same-name skills appearing separately, global AGENTS.override.md
precedence, and a default 32 KiB combined instruction limit. The shared skills
scope is distinct from each CODEX_HOME's rules. Writing a block does not prove
it is loaded, and project selection does not hide globally available extras.

[Claude memory documentation](https://code.claude.com/docs/en/memory), fetched
2026-10-19, specifies `@path` imports, backslash-escaped spaces and no quoted
paths. It distinguishes external project-import approval from user-scope
imports, which normally load without that dialog outside Cowork. Proposed
delivery targets user scope. Keep the T3 route/version and path acceptance
tests explicit; do not infer an interactive approval requirement for this route
from project-scope rules. No native model session was run here.

The accepted E1 contract therefore specifies explicit shared/per-harness scope, unsupported/nested
import refusal for new personal rules, override/size diagnostics and separate
legacy/central project validation. E3 may implement schema/read-only synthetic
preview; installed operational behavior and global homes have not changed.

### F10. Public catalogues supply individual methods, not a default bundle

Accessed 2026-10-19: [ECC](https://github.com/affaan-m/ECC/tree/76aaa77df6adc5b889e689007bf99b9a4f74af34)
at `76aaa77df6adc5b889e689007bf99b9a4f74af34` (Oct15, unchanged from topic14)
and [Hermes](https://github.com/NousResearch/hermes-agent/tree/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872)
at `86fa9e6ca1de7ee71132d2be0103f3e37d1fa872` (Oct19). Four new HTTP
requests saved exact HEAD metadata and pinned archives outside the repository.
This review targets individual broadly applicable instructions and relevant
helpers; it is not an audit of either whole repository or installer.

Hermes's [bundled catalogue](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/website/docs/reference/skills-catalog.md)
and [skills documentation](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/website/docs/user-guide/features/skills.md)
distinguish shipped skills, optional additions and update/opt-out behavior.
Being bundled establishes a producer's distribution choice, not independent
public use, reliability or Windows/T3 compatibility. ECC and Hermes are two
source families; repeated or borrowed methods are not independent validation.
No representative popularity ranking or candidate benefit test was performed.

The saved first-party [Anthropic practice article](https://claude.dev/blog/lessons-from-building-claude-code-how-we-use-skills/)
(published Jun3, updated Sep24, captured Oct18) reports internal use across
nine categories. Its reference, verification, analysis, document/business and
maintenance examples show why a workflow-only set underrepresents a general
audience. Its verification-impact claim is an unquantified vendor report;
usage logging measures use, not causal benefit. Useful authoring advice is
focused jobs, observed gotchas, progressive references and flexibility within
constraints. [Official OpenAI documentation](https://learn.chatgpt.com/docs/build-skills)
(already fetched Oct19, reused here) similarly recommends one job, explicit
inputs/outputs, instructions before scripts and testing description triggers.
Neither document establishes an optimal public skill count or authorizes
hooks, new tools or plugin packaging for this project.

Hermes's [grounded-citations](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/research/grounded-citations/SKILL.md)
adds stable source IDs, raw passage checks and attribution while drafting.
Static inspection of its [helper](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/research/grounded-citations/scripts/sources.py)
shows normalized quote-presence checks and source-level evidence/ID/coverage
validation, not whether each claim follows from its cited passage. Its coverage
also counts explicit unverified markers and excludes tables/code. Adapt the
traceability method within research and existing task evidence; do not claim
that a green citation check proves truth or add a competing global ledger.

[Document-to-action-items](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/productivity/document-to-action-items/SKILL.md)
is a distinct general/research outcome: document versions, page/section
locators, OCR uncertainty, modality, consistency and proposed owners/deadlines.
Its duplicate `pdf` references are a packaging defect; the underlying method
is useful independently of connectors. Extraction and drafting can be local;
creating tracker/calendar records is a separate authorized effect. This adds
**cited document reasoning** to the next G1 proposal alongside the earlier
synthesis, analysis and frontend gaps. It does not select a new shipped skill.

[LLM wiki](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/research/llm-wiki/SKILL.md)
offers immutable raw layers, provenance, drift and contradiction flags. Its
new wiki/schema/index/log, numerical page/link thresholds and optional sync
are a separate persistence design. The rule that newer sources generally
supersede older ones is insufficient for conflicting evidence. Reuse the
provenance/contradiction techniques in research; defer a new wiki system.
Weekly review likewise fits optional personal productivity, with selected
systems/calendar access, rather than an automatic project-wide scan.

## 3. Options compared

### Individual existing skills

The owner's request reopens the previous ten-skill proposal. Each row below is
a source-based recommendation, with an observable case for a later evaluation.
All 11 sources remain candidates for public distribution; none is retained
because of age or generator ownership. **Keep common** means keep the contract
without a substantive redesign; **revise before common** is conditional on the
specified changes. **Optional** means available for the relevant job, outside
the proposed common selection. No row changes current behavior.

Source-contract observations are directly inspected Local evidence (2026-10-19).
Confidence in the selection recommendations is provisional: no incremental
benefit, trigger reliability or native replacement was measured.

| Skill / current selection | Proposed disposition | Distinct outcome; cheaper alternative and required change | Positive and negative acceptance cases |
| --- | --- | --- | --- |
| [work](../../project/base/.agents/skills/work/SKILL.md) / core, explicit | **Revise before common** | Coordinates an approved task from sizing to evidence. Overlaps ordinary planning and native methods. Reuse existing authorization; make review, tests and delegation proportional to the task rather than automatically multiplying steps. Keep project authority canonical. | A small docs edit uses a stated check without an unnecessary plan approval or test scaffold; a large authorized task follows its plan. Neither starts new scope or delegates merely because a plan is long. |
| [resume](../../project/base/.agents/skills/resume/SKILL.md) / core, explicit | **Keep common** | Reconciles authority, files and effects before continuing. A native conversation resume alone does not express this contract. Keep separate from read-only reporting and record production. | Continues an approved interrupted task without reapproval; several possible tasks or an unknown-effect operation cause clarification/reconciliation before mutation. |
| [handoff](../../project/base/.agents/skills/handoff/SKILL.md) / core, explicit | **Keep common** | Produces a self-contained transfer record, distinct from resuming work. Reuse canonical record fields rather than adding another memory ledger. | A fresh thread can identify the checked artifact, authority and next action; a missing exit or unobserved publication remains unknown. A handoff does not authorize continuation or send an external message by itself. |
| [status](../../project/base/.agents/skills/status/SKILL.md) / core, explicit | **Revise before common** | Read-only reporting/recovery. A plain Git report lacks task authority/effect distinctions. For a named task, inspect its relevant records first; reserve all-task/inbox/PR scanning for a project-wide report. Share recovery fields with the canonical record format. | Named-task status stays relevant and changes no files; a project-wide request reports competing tasks. No automatic selection from newest-event ordering, and no stale remote reference is reported as fresh publication. |
| [review](../../project/base/.agents/skills/review/SKILL.md) / core, explicit | **Revise before common** | Supplies a repository rubric, fixed target, findings and evidence limits. Compare native review, but retain the contract until equivalent coverage is demonstrated. Resolve command naming/routing in both harnesses, especially F4's documented alias risk. No rename is selected here. | A known defective diff yields an actionable location/consequence; a clean diff permits no findings. The intended Workspace procedure is invoked, and review grants neither writes nor publication authority. |
| [validate](../../project/base/.agents/skills/validate/SKILL.md) / core, explicit | **Revise before common** | Maps scope to checks and honest results. Project scripts and CI remain the execution baseline. Make targeted/full checks conditional on affected behavior and required project gates; reuse recorded checks at the same revision rather than repeat equivalents. Evaluate browser acceptance within this entry point first. | Docs work runs docs checks without a product build; a behavior change runs its meaningful checks and required suite. An unavailable interactive check stays not run; static passing never becomes runtime proof. |
| [minimal-change](../../project/base/.agents/skills/minimal-change/SKILL.md) / core, implicit allowed | **Keep common** | Reuse-first implementation and bounded root-cause fixes. Duplicates some policy, but supplies a concrete search/choice method; link policy instead of expanding it. Retention is a workflow preference, not measured capability uplift. | Reuses an existing helper for a defect; preserves validation/accessibility and refuses speculative refactoring or unnecessary dependencies. A substantive redesign still follows its own approved scope. |
| [structured-debugging](../../project/base/.agents/skills/structured-debugging/SKILL.md) / core, implicit allowed | **Keep common** | Expected/actual evidence, discriminating hypotheses and verification. Distinct from inspecting an arbitrary diff; compare native debug only on the same reproduction. Preserve coordination and bounded repair. | A reproducible failure leads to a supported cause and regression check. An unreproduced report remains uncertain; no bundled speculative fixes or unrequested broad audit. |
| [agent-documentation](../../project/base/.agents/skills/agent-documentation/SKILL.md) / core, implicit allowed | **Move to optional agent-authoring/maintenance** | Useful for agent rules, skills and state ownership, but not ordinary document production or every research/software task. Routine product docs can use project conventions plus work/validate. Keep the existing source and notices. | An instruction change edits its canonical source and preserves dated evidence; an ordinary report or README does not trigger a full agent-policy workflow. |
| [research](../../project/base/.agents/skills/research/SKILL.md) / research capability, explicit | **Revise, then add to common** | Provide local-evidence/synthesis and outside-source modes. Track source families, contradictions, gaps and transformations; web only for the question's unresolved gaps. Classify original studies versus summaries by provenance, not by calling every benchmark/vendor post secondary. Retain collection and action-authority boundaries. | Synthesises a supplied corpus with traceable support and no unnecessary fetch; resolves a genuinely missing current fact through a dated primary source. Does not count reused datasets as independent support or imply an exhaustive literature search. |
| [unreal-validation](../../project/profiles/unreal/files/.agents/skills/unreal-validation/SKILL.md) / Unreal profile, implicit allowed | **Keep optional specialist** | Engine discovery, a coordinated build and honest automation/PIE evidence. Generic validate delegates to it; embedding engine instructions in the shared default would add irrelevant context. | Uses the selected project's actual engine and one build owner; never substitutes another version, races a build or reports unavailable PIE as passed. No invocation for a non-Unreal project. |

The proposed common set is therefore **nine**: four kept contracts and five
conditional revisions. The two optional skills still ship in the candidate
public source set. This is an interim workflow baseline, **not a complete
capability catalogue or an optimal count**. The general/research/software target
does not require equal skill counts; it does require evaluating the uncovered
outcomes below before final selection.

The explicit controls are `disable-model-invocation` and shipped Codex
`agents/openai.yaml` policy. Their runtime enforcement was not tested. Keep
explicit workflow intent while revising triggers; availability grants no new
action authority. Do not merge status/resume/handoff merely to reduce counts:
their effects differ. Consolidate shared recovery fields under
[collaboration](../../project/base/.sw/collaboration.md), with entry points
linking to that owner instead of maintaining competing definitions.

### Selection and migration dependencies

Local source inspection: [Sw.Project](../../lib/Sw.Project.psm1) defines the
fixed workflow floor (`work`, `resume`, `handoff`, `status`, `review`, `validate`).
[selection.json](../../project/selection.json) combines core, profile and
additive capabilities. Moving agent-documentation out of core does not violate
that floor, but needs an explicit optional capability/selection route. A future
rename/removal of a workflow would require resolver and caller changes, not
just deleting a folder. Legacy installs currently retain all base skills.

Research's [capability guidance](../../project/capabilities/research/AGENTS.section.md)
and evidence checks belong with the common research outcome without forcing
software projects into the research profile. Preserve the
[generic software checks](../../project/profiles/generic/AGENTS.section.md).
Update affected `AGENTS.md`/global references, workflow callers, invocation
metadata, exact-selection and recovery tests, paired generated output and
edited-deselected-file preservation in a separately approved implementation.
The existing [tests](../../tests/Sw.Tests.ps1) are migration constraints, not
proof that the proposed catalogue is best. None ran as a product test here.

### Individual new-skill candidates

These are evaluations of **outcomes**, not endorsements of named repositories.
Synthesis, local analysis and frontend design have the highest next-inspection
priority because they expose distinct gaps. A concrete source review may still
favour a research mode, project guidance or ordinary prompting over a new skill.

| Candidate | Evidence actually inspected / confidence limit | Disposition and acceptance before selection |
| --- | --- | --- |
| Evidence synthesis/investigation | F7 Local output; F8 inspected Framework Method with document-fit/heterogeneity limits, not an evaluated skill | **Evaluate a mode in research first**, for default research coverage. Trace claims to passages/source families; retain conflicts, reuse and gaps. No web when sufficient; no systematic-review or independent-consensus claim. |
| Local quantitative analysis | F8 inspected individual instructions, packaging script and scoped Apache-2.0 license; no runtime or benefit test | **Prototype a compact local procedure**, not the plugin. Compare ordinary tools on grain, units, denominator, joins, aggregation, reproducibility and uncertainty. Then decide separate skill vs research mode; no warehouse/MCP/new library required. |
| Frontend design | F8 pinned current skill/scoped Apache-2.0 license; brief-first and accessibility content; benefit unmeasured | **Prototype a focused instruction-only skill** for software creation. Compare existing-design and new-interface cases; preserve required palette/font/components and verify behavior. No automatic downloads, memory or extra runs. |
| Systematic literature review | [Academy entry](https://academy.claude.com/use-cases/plan-your-literature-review), Oct 16 listing/Oct 18 local index only; page explicitly not fetched, no method inspected | **Optional specialist lead**, not a reviewed skill. Inspect an actual methodology before selection. Search strategy, inclusion/exclusion and study-quality extraction must be reproducible; ordinary research must not claim systematic coverage. |
| Browser/UI acceptance | F10 inspects ECC browser-qa/e2e-testing instructions and native overlap; no browser task trial | **Evaluate within validate first**. Compare native T3 tools on a stateful user journey with a deliberately broken outcome, not merely a screenshot. A separate skill needs substantive reusable content and demonstrated gaps in that baseline. |
| DOCX/PDF/PPTX/XLSX production | F10 inspects Hermes PDF/DOCX/XLSX instructions, selected helpers/references and scoped MIT licenses; PPTX remains uninspected | **Optional format-specific evaluations** with general-audience relevance. Check preservation, rendering, editability, forms/formulas and file integrity; no automatic dependency/service setup. Agent-documentation is not a substitute. |
| Skill authoring/evaluation | F7 announcement and F4 docs describe concrete evaluation/trigger methods; current system authoring guidance is session-provided, not a product license | **Optional agent-authoring pack**, alongside agent-documentation. First compare existing research/validate and system availability. Require held-out positive/negative triggers and independent with/without evidence; reject a skill that adds ceremony without benefit. No evaluation framework adoption implied. |
| Generic brainstorming/planning | Current work source; dated [topic 12](12-workflow-methods.md#3-options-compared) bundle comparison, not a current individual source audit | **No separate addition now**: work already covers sizing, conditional clarification, plans and checks. Improve conditional design exploration there for a demonstrated gap. Reconsider only after actual candidate instructions and incremental value are inspected. |
| Strict TDD | F10 inspects ECC and Hermes actual instructions; current work already asks for failing tests first where tests exist | **No separate default addition**. Useful intended-failure/behavior checks belong in work/project guidance; reject universal coverage, per-stage commits and delete/restart mandates. No incremental benefit was measured. |
| Web artifact builder | F7 design article describes React/Tailwind/shadcn and Parcel single-file bundling; scripts/dependencies/license not inspected | **Optional only for that host constraint**. Require a real single-file delivery need and compare plain HTML/existing tooling. Scaffolding and installs must not become automatic consequences of requesting an interface. |
| General writing and editing | F10 inspects ECC article-writing and Hermes humanizer, not an output comparison | **Evaluate a compact writing candidate** across reports, guides and ordinary prose. Preserve meaning, sources, uncertainty and requested voice; no operator persona, hidden brand-voice dependency or fabricated specificity. Distinct from agent-documentation. |
| Cited document reasoning | F10 inspects Hermes document-to-action-items; extraction helpers have their own format/tool requirements | **Evaluate for common general/research coverage**, either a focused research mode or separate entry. Compare version/modality/locator/unknown-owner handling; local facts/proposals grant no tracker/calendar write authority. |

### Individual public-source review

Observed 2026-10-19. These 31 entry files were inspected, with relevant bundled
support files and licensing where stated. G/R/S below mean general, research
and software relevance, not scores or measured gains. Each disposition is a
proposal for this product, independent of the source's own packaging choice.
**Adapt** means consider original changes to the existing owner; **candidate**
means evaluate the distinct outcome before selecting its distribution/default.
No unchanged import, installation, new common default or model trial follows.

#### ECC: 15 individual skills

| Pinned skill | Useful method and audience fit | Proposed home and material limits |
| --- | --- | --- |
| [search-first](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/search-first/SKILL.md) | S/R: local reuse first; report unavailable search channels; compare fit/license/dependencies. | **Adapt minimal-change/research.** No automatic researcher agent, registry search, package install or MCP configuration. |
| [iterative-retrieval](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/iterative-retrieval/SKILL.md) | R/S: state missing context, refine terminology and query again. | **Adapt research/work/debugging.** Drop arbitrary relevance scores/file counts/cycles and initial test exclusion; sufficiency depends on the question. |
| [deep-research](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/deep-research/SKILL.md) | G/R: cited full-text synthesis; separate fact/inference and gaps; fetched content is data. | **Adapt research.** Firecrawl/Exa requirements,15-30 sources, three agents and blanket12-month preference conflict with bounded local-first evidence work. |
| [documentation-lookup](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/documentation-lookup/SKILL.md) | R/S: identify library/version, then query narrowly. | **Adapt a light documentation mode in research.** Hard Context7 dependency and transmission of the full question are not defaults; use available primary docs and minimal disclosure. |
| [verification-loop](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/verification-loop/SKILL.md) | S: preserve pipeline failure status and concise check evidence. | **Adapt validate.** Fix actual task target and NOT RUN/UNKNOWN states; reject universal stages,80% coverage, periodic reruns and security claims from grep alone. |
| [tdd-workflow](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/tdd-workflow/SKILL.md) | S: distinguish intended regression failure from broken setup; match RED/GREEN to the same behavior. | **Adapt work/debugging; optional project testing guidance.** No all-code TDD,80% floor, mandatory ECC detector, per-stage commits or competing evidence reports. |
| [security-review](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/security-review/SKILL.md) | S: threat/stack-specific authorization, input and exposure checks. | **Optional security guidance through review.** Web/cloud assumptions need verification; dependency-fix/account/scanner-action examples are mutations. This inspected skill does not install AgentShield. |
| [e2e-testing](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/e2e-testing/SKILL.md) | S: browser regression organization, waits, failure artifacts, flaky/skipped reporting. | **Optional Playwright/project guidance.** Runner/browser/CI installs and live journey isolation are separate scope; retries do not erase flakes. |
| [browser-qa](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/browser-qa/SKILL.md) | G/R/S for web outputs: test data/redaction, visual baseline INCONCLUSIVE, keyboard and automation evidence. | **Adapt validate browser mode first.** Use native T3 tools when adequate. Fixed visual/performance thresholds and a screenshot do not prove accessibility or field performance. |
| [codebase-onboarding](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/codebase-onboarding/SKILL.md) | S: architecture/entry-point guide, traced flow and explicit unknowns for a newcomer. | **Optional codebase orientation candidate**, report-only. Source automatically writes/enhances CLAUDE.md; observed conventions do not authorize new instructions. |
| [article-writing](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/article-writing/SKILL.md) | G/R/S: audience/purpose, one job per section, supplied voice and factual support. | **Common writing candidate for evaluation.** Distinct from agent-documentation. Remove hidden brand-voice dependency and founder/operator voice default; test meaning/source fidelity across genres. |
| [strategic-compact](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/strategic-compact/SKILL.md) | G/R/S on long tasks: checkpoint durable state before context loss. | **Adapt handoff/resume when needed.** Reject default hooks, extra memory ledgers, model thresholds and unverified percentage-savings claims. |
| [continuous-learning](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/continuous-learning/SKILL.md) | G/R/S: recurring corrections could inform reviewed procedure changes. | **Reject deprecated v1 as a default.** Helper only requests evaluation after transcript counting; it does not implement claimed automatic learning. V2 remains unreviewed. |
| [coding-standards](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/coding-standards/SKILL.md) | S: readable names, reuse, error handling and behavioral tests. | **Project guidance.** Mostly overlaps minimal-change/lint/review; TS/React examples, fixed size/style rules and conflicting mutation advice are not universal conventions. |
| [skill-stocktake](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/skills/skill-stocktake/SKILL.md) | Agent authors: assess uniqueness, currency, alternatives and absent usage evidence. | **Adapt optional agent-authoring assessment.** Global scans/cache writes, tools and agent batches are unnecessary defaults; modification time and usage are not effectiveness tests. |

#### Hermes: 16 individual skills

| Pinned skill | Useful method and audience fit | Proposed home and material limits |
| --- | --- | --- |
| [grounded-citations](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/research/grounded-citations/SKILL.md) | G/R: stable source identity, cite while drafting, retained passages and explicit uncertainty. | **Adapt research.** Existing task evidence owns receipts; structural citation checks do not establish entailment. No global ledger or optional source installs by implication. |
| [llm-wiki](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/research/llm-wiki/SKILL.md) | G/R: raw/derived distinction, hashes, provenance and contradiction flags. | **Adapt research techniques; defer persistence system.** New wiki/schema/log, fixed thresholds, recency rule and optional Obsidian sync require separate design/evidence. |
| [document-to-action-items](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/productivity/document-to-action-items/SKILL.md) | G/R/S: cited facts/obligations, versions, OCR quality, modality, explicit owners/dates and contradictions. | **Cited document reasoning candidate for common evaluation.** Extract/draft locally; preserve unknowns. Tracker/calendar writes require their own scope; duplicate pdf references need correction. |
| [weekly-review-planning](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/productivity/weekly-review-planning/SKILL.md) | G: reconcile commitments against calendar capacity, waiting items and deferred work. | **Optional personal productivity.** Needs user-selected systems/access/window; no automatic scheduler, connectors, follow-up sending or project-wide status expansion. |
| [codebase-inspection](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/software-development/codebase-inspection/SKILL.md) | S: language/LOC inventory with generated/dependency exclusions. | **Project tool recipe.** Narrower than architecture orientation; pygount/Bash/install assumptions add little over existing tools for many tasks. LOC is not quality. |
| [systematic-debugging](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/software-development/systematic-debugging/SKILL.md) | S/R: exact symptom loop, minimal reproduction and falsifiable hypotheses. | **Adapt structured-debugging.** Drop mandatory hypothesis counts, universal test runner, architecture verdict from attempt count and unattributed speed/success claims. |
| [requesting-code-review](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/software-development/requesting-code-review/SKILL.md) | S: fixed concerns, baseline evidence, independent review and bounded fix loop. | **Adapt review/validate only.** Stash/pop, reviewer/fixer mandates and add-all/commit conflict with our rules. One-shot review skips independence but still permits a verified-label claim. |
| [simplify-code](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/software-development/simplify-code/SKILL.md) | S: evidence-backed reuse/state/lifetime/root-cause review with cost, confidence and risk. | **Adapt minimal-change/review.** Explicit trigger and inline fallback are useful; preferred four-agent sweep and auto-apply categories do not establish scope or an optimal agent count. |
| [test-driven-development](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/software-development/test-driven-development/SKILL.md) | S: behavior-first tracer slices; avoid implementation-detail/mock-only tests. | **Project testing guidance/work adaptation.** Reject delete/restart, permission for routine exceptions, every-function tests and full-suite-every-cycle mandates. This skill has no percentage coverage floor. |
| [spike](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/software-development/spike/SKILL.md) | R/S: bounded feasibility question, risk-first experiment and qualified verdict. | **Optional experiment candidate or work mode.** Use canonical records and approved experiment targets/budget; remove separate spikes ledger, blanket hardcoding and delegation assumptions. |
| [pdf](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/productivity/pdf/SKILL.md) | G/R: extraction, production and forms with structural/readback/visual checks. | **Optional format candidate.** Python/rendering prerequisites; optional OCR/Firecrawl/model downloads/API editing add distinct data/cost effects. Reconcile an edit before trying another page. |
| [docx](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/productivity/docx/SKILL.md) | G/R: editable Word/templates, tracked changes/comments and package health. | **Optional format candidate.** Preserve originals; Python/helpers required. Package readback does not prove layout; rendered validation needs an available renderer. |
| [xlsx](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/productivity/xlsx/SKILL.md) | G/R: formulas/cached values, restructuring diagnostics and spreadsheet delivery. | **Optional format candidate**, separate from analytical method. Recalc can exit0 without recalculating; default edits overwrite and helper has static Windows portability concerns. |
| [design-md](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/creative/design-md/SKILL.md) | S: design tokens/rationale, lint and export. | **Optional design-system/project guidance.** Does not replace frontend design; floating npx/spec assumptions and automatic export files need scope. Lint is not complete accessibility acceptance. |
| [humanizer](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/creative/humanizer/SKILL.md) | G/R: supplied-voice calibration, filler removal and visible editorial diff. | **Defer import; compare compact writing guidance first.** Subjective pattern rules/persona examples can alter evidence/meaning. Borrowed Wikipedia-derived content needs passage-specific rights review. |
| [arxiv](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/skills/research/arxiv/SKILL.md) | R: academic query syntax, metadata, withdrawals and citation versions. | **Source guidance under research; optional academic pack.** Helper emits unversioned links despite version advice. External API/auth/terms remain unchecked; citation counts are not study quality. |

#### Rights and implementation implications

ECC's inspected selected subtrees have a [root MIT license](https://github.com/affaan-m/ECC/blob/76aaa77df6adc5b889e689007bf99b9a4f74af34/LICENSE),
without additional scoped notices found in those subtrees. That establishes
declared terms, not every embedded quotation's provenance. Hermes has a
[root MIT license](https://github.com/NousResearch/hermes-agent/blob/86fa9e6ca1de7ee71132d2be0103f3e37d1fa872/LICENSE)
and separate Nous MIT licenses in its inspected PDF/DOCX/XLSX directories.
Those concrete format candidates must not inherit the different licensing
classification of Anthropic's format implementations in F6. Hermes's declared
software adaptations name Superpowers/GSD and other upstreams; applicable
upstream notices still need exact-content review before copying. Humanizer's
upstream MIT notice does not alone resolve its acknowledged Wikipedia-derived
passages. Referenced tools, model weights, assets and services have separate
rights/terms. No confirmed infringement, full originality audit or transitive
dependency clearance is claimed. Original method summaries above import no
third-party implementation.

Static helper checks support concrete acceptance requirements: citation IDs
and source quotes are insufficient for per-claim support; XLSX recalculation
must inspect its result rather than exit status alone; arXiv outputs must keep
the actual read version; document production must preserve originals and
distinguish package/readback from rendered layout. These are not executed
candidate tests. Licensing, preservation, Windows portability, native loading,
trigger relevance and benefit remain gates for any selected candidate.

### Plugin candidates

| Candidate | Recommendation | Why and revisit trigger |
| --- | --- | --- |
| Superpowers / Compound Engineering / ECC bundles | No bundle distribution or default installation | Dated topics 12/14 show workflow overlap, branch/commit conflicts or preservation gaps; individual useful content can still be inspected on its merits |
| Claude language-server plugins | Optional language-specific candidates; none preinstalled | Distinct diagnostics/symbol navigation; binaries and T3 acceptance still needed |
| Native Codex plugins | Defer | F5's preservation concern remains unresolved; plain skills do not require plugin packaging |

[Code-intelligence docs](https://code.claude.com/docs/en/plugins/code-intelligence),
captured 2026-10-18, name `clangd-lsp`, `pyright-lsp`, `typescript-lsp`,
`csharp-lsp` and others. They require separately installed language-server
binaries and describe terminal support, not product acceptance. No plugin
source/license audit or default language choice was made here.

### MCP shortlist: evaluate only for a named gap

All entries have **default installation: no; default enablement: no**.
Public documentation may identify them as evaluation candidates, but none is
yet a supported product integration or bundled implementation.

| Candidate | Intended gap / simpler baseline | Local evidence and remaining adoption question |
| --- | --- | --- |
| Context7 | Repeated, version-specific library lookup; compare direct official docs retrieval | [Marketplace description](https://claude.com/marketplace/plugins/context7), captured 2026-10-18, describes library resolution/document lookup. Freshness is a vendor claim, not a guarantee. Review exact source/license, dependencies, auth, query destination and answer accuracy |
| Claude documentation MCP | Claude-specific setup research; compare direct primary docs | [Quickstart](https://code.claude.com/docs/en/mcp-quickstart), captured 2026-10-18, documents hosted full-text docs search without auth. Narrow vendor scope; queries reach its service. Check both harnesses and request scope before use |
| Playwright MCP | Browser acceptance where T3 preview lacks a required capability | Same saved quickstart links [upstream](https://github.com/microsoft/playwright-mcp), describes local browser tools and Node dependency. Pin a reviewed version; inspect browser/profile/network scope and compare native T3 tools. No upstream source/license inspection here |
| GitHub MCP | A task the existing `gh`/T3 PR tools cannot complete adequately | [Claude MCP reference](https://code.claude.com/docs/en/mcp), captured 2026-10-18, points to [GitHub's server](https://github.com/github/github-mcp-server). Exact auth/toolsets and mutation controls need a source review; desktop options are not presumed portable to T3 |
| Filesystem / memory / sequential-thinking servers | No current unmet outcome identified | Shell/files, canonical task records and normal planning are the baseline. No specific implementation evaluated; no default justified |

The same service packaged as a plugin and a standalone MCP server is one
capability choice. Avoid selecting both wrappers and duplicating tools.

## 4. Recommendation

Recommend carrying these individual dispositions into the next selection plan:

1. **Use the provisional nine-skill common set as a baseline for evaluation**:
   keep resume, handoff, minimal-change and structured-debugging; revise work,
   status, review, validate and research before common selection. Make
   agent-documentation and Unreal optional. Retain all 11 source candidates,
   with their notices. This supersedes the unselected ten-default proposal,
   not the current implementation.
2. **Expand the proposed outcome comparison beyond the earlier three gaps**:
   general writing/editing and cited document reasoning now join synthesis
   within research, local quantitative analysis and frontend design. F8/F10
   provide concrete source methods and limits, not authority to build or run
   the earlier prototypes. Keep the nine workflow contracts as one evaluation
   baseline, not the complete general capability set. Evaluate browser
   acceptance within validate first. Format production, codebase orientation,
   security, academic source guidance, bounded spikes and skill authoring stay
   optional candidates. Propose a revised finite G1 drafting/comparison package
   after this review; the old 14-pair/28-run proposal is unselected. Further web
   is justified only by a material remaining source gap. No bundle install.
3. **No external plugin defaults.** Keep plain skill delivery independent of
   plugin caches. Offer language-server plugins as later, version-specific
   evaluations where their diagnostics solve a real project need.
4. **No preconfigured MCP defaults.** Make documentation lookup the first
   optional pilot for the shared research/software audience if direct docs
   access repeatedly fails. Choose Context7 for cross-library cases or the
   Claude docs server for Claude-only cases. Browser verification comes next
   only for a required capability missing from T3; GitHub follows a demonstrated
   gap beyond `gh`/T3.
5. **Use a bounded adoption record per selected candidate:** exact source and
   revision, redistributed files/notices (or reference-only), responsible
   maintainer/recheck trigger, runtime dependencies, auth/data destinations,
   permissions, recurring cost and update/removal/recovery behavior. Preserve
   user edits under D11. Do not ship floating `@latest` install commands as a
   tested default.
6. **Prove the selected delta:** select representative general, research and
   software cases covering each affected outcome, with negative-trigger and
   authority cases, before changing skill text;
   compare with/without the affected skill on fresh equivalent runs. Measure
   accepted output, source accuracy, rework, time and cost, not skill count.
   For integrations, compare the same task with native tools, then exercise
   discovery, failure/auth handling, edited config, update and removal on both
   supported harness routes and Windows shells. Budget and live targets must
   be selected before those trials. Static validation cannot replace them.

The [roadmap](../central-delivery-roadmap.html) shows the individual P1 review,
P2 plugins and P3 MCP selection alongside C1/C2/M1. P1 precedes final M2 selection;
the nine-skill baseline is not permission to skip the candidate comparisons. An empty
plugin/MCP default does not block plain skill/rule delivery. Selecting a concrete
integration triggers C4's owned-entry design only if it needs generated entries.
M5 adds the selected catalogue's acceptance cases; M6 retains explicit adoption
and publication scope.

## 5. Open questions

- **Individual dispositions:** select or amend the four kept contracts, five
  revisions and two optional skills above. The proposed nine is an interim
  baseline; catalogue choice follows the selected outcome comparisons, now
  including writing and cited document reasoning. The
  general/research/software audience is already selected.
- **Evaluation scope:** the owner requested this broader source review before
  choosing revisions/prototypes or comparisons. Revise the earlier 14-pair
  proposal for F10's outcome and negative cases, then select finite scope before
  trials. Exact sources/methods are inspected; benefit remains unmeasured. G4
  separately selects native harness versions/targets; no count is predetermined.
- **External default choice:** accept no external plugin/MCP default, or name
  a specific candidate and unmet outcome to evaluate before inclusion?
- **First optional pilot, if wanted:** version-specific documentation lookup,
  language diagnostics or browser acceptance? Select task/data scope and a cost
  budget before live integration trials. No pilot is required to deliver skills.

Remaining evidence gaps: licenses/terms for any additional selected assets or
integration; maintenance/recheck triggers; preservation of automatic write paths;
actual loading/invocation
in both T3 harness routes; representative task benefit. No paid trials, fresh
native sessions, tool installations or integration connectivity checks ran here.

## 6. Supersedes / updates

Reopens the same-day initial proposal at the owner's request to revisit
individual skills before selecting a catalogue. That proposal recommended ten
common skills (current nine plus research) and all 11 sources; it was never
selected. This revision makes agent-documentation optional, identifies five
necessary revisions and evaluates missing outcomes rather than assuming incumbents
or a whole bundle should remain default.

Extends topic 14's delivery research with public capability selection; does
not replace its preservation requirements or approve implementation. Updates
the planning view with P1-P3 and records a qualification to S6's empirical
scope, without silently revising that owner decision. Topics 12-15 remain dated
evidence: their old inventories are not a statement of what is unfinished now.
The outline owns selected direction, state owns implemented/authorized behavior,
and the local task record owns execution evidence.

E0/E1 update (2026-10-19): resolves the named priority source/license/method
inspection gaps, defines comparison cases and prepares a concrete G1/G2
contract. It passes no catalogue/build/native/adoption gate; the owner-approved
evidence/contract slice does not authorize downstream choices by itself.

G1/G2 update (2026-10-19): the owner requested the individual public-source
review recorded in F10, adding 31 concrete assessments and broader general
outcomes before selecting the catalogue. No revisions/prototypes/model trials
were approved. G2 separately accepted the delivery contract and E3 strict
schema/pure planning/read-only synthetic preview; this is the current code
authorization, with real effects/native adoption/publication still outside E3.
