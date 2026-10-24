# Skill fixtures

Synthetic scenarios for the revised `work`, `status`, `review`, `validate` and
`research` skill drafts. Each case directory holds `input.md` (what the agent
is given) and `expected.md` (required and forbidden behavior). They are
hand-checked rubrics, not wired into a test runner, and no model trial has
scored them.

| Case | Skill | Tests |
|---|---|---|
| `work/w1-small-docs-edit` | work | small approved edit: exact change, doc checks, no plan or test |
| `work/w2-resume-unknown-exit` | work | approval reuse; reconcile an unknown-exit command |
| `status/s1-named-task` | status | named-task scope among several active records |
| `validate/v1-docs-reuse-checks` | validate | reuse same-revision checks; no product suite |
| `validate/v2-code-regression` | validate | meaningful regression test on the changed revision |
| `review/r1-seeded-defect` | review | real defect over formatting; command identity; read-only |
| `research/q1-local-synthesis` | research | claim/source-family matrix from local excerpts |
| `research/q2-current-gap` | research | one dated gap resolved from a supplied snapshot |
| `research/q3-no-gap` | research | no factual gap: no research procedure |

All names, files, data and quotations are invented for these fixtures.
Licence: the repository licence (MIT). No third-party text is reproduced;
the `q1` matrix shape follows the framework method of Gale et al. 2013
(BMC Medical Research Methodology 13:117, CC BY 2.0), described in original
wording.
