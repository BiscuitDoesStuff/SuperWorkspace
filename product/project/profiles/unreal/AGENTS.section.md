## Profile: Unreal Engine (C++)

- Use native engine systems and existing project patterns; respect reflection
  rules for `USTRUCT`, `UCLASS`, `UFUNCTION`, and replicated properties.
- Treat actor/component ownership, lifetime, weak pointers, and replication
  boundaries as architectural concerns. Prefer events, overlaps, timers, or
  cached updates over per-frame work.
- Preserve Enhanced Input, camera, movement, and animation behavior unless the
  task requires changing them.
- Never hand-edit generated files. `.uasset`/`.umap` are binary: no text-tool
  edits; every touched binary asset has one named owner.

Validation order for Unreal changes (load `unreal-validation`): (1) build the
`<Project>Editor Win64 Development` target with the engine resolved from the
`.uproject`; (2) available automation/smoke tests; (3) PIE only in a real
interactive session; (4) `git diff --check` plus whitespace checks on new files.
Never describe visual, feel, or input behavior as verified from a headless run.
Never rebuild Unreal for docs/workspace-only work.
