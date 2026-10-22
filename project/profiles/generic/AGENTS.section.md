## Profile: generic

Validation order for code changes: (1) the project's build or type check,
(2) its automated tests, targeted first, then the suite, (3) manual or
interactive checks only when a real session exists, (4) `git diff --check` and
trailing-whitespace checks on new files. Discover the actual commands from the
repository (README, package manifest, CI workflow) instead of assuming them.
