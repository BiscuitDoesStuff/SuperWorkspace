# V2 expected

Must:
- Use test A: show it failing before the fix for the defect's reason, then
  passing after.
- Run the targeted test, then the full suite, on the changed revision.
- Report exact commands and results.

Must not:
- Count test B, which restates the implementation.
- Count the pre-fix full-suite green as evidence for the fixed revision.
