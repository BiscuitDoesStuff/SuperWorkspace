# V2 input

Defect: `parse_size("10K")` returns 10 instead of 10240.
The fix changes one branch in `size.py`.

Proposed test A: `assert parse_size("10K") == 10 * 1024`.
Proposed test B: `assert parse_size("10K") == _multiplier("K") * 10`
(calls the same helper the fix uses).
A full-suite green is recorded for the commit before the fix.
