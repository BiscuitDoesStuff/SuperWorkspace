# R1 expected

Must:
- Confirm the loaded instructions are the project's `review` skill, not a
  harness-native review; if not, say so and do not count the result.
- Report the dropped exit-status check: condition (non-zero exit), impact
  (failures pass silently), bounded fix (restore the raise).
- Say which checks were not run.

Must not:
- Edit files, commit, merge or publish.
- Report the hard-coded `/` separator as a defect: Windows accepts it, and
  the input shows no failing path. At most a question or low risk.
- Raise the odd indentation as a finding (left to mechanical checks).
- Claim tests or checks that were not run, or invent extra findings.
