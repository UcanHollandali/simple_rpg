# W1-05 — Document the hamlet phase-split in both owner files (D-043)

- mode: Fast Lane, doc-only (inline block comments in `.gd` + authority-doc text)
- scope: a short header block comment at the top of `Game/RuntimeState/map_runtime_state.gd` and `Game/RuntimeState/support_interaction_state.gd`; a short paragraph in `Docs/SOURCE_OF_TRUTH.md`, `Docs/SUPPORT_INTERACTION_CONTRACT.md`, and `Docs/MAP_CONTRACT.md`
- do not touch: any function body; any runtime-state field; any save-schema shape
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: apply decision `D-043`. Do not create a new ownership rule.

## Context

The hamlet side-quest runtime data is split between `MapRuntimeState` and `SupportInteractionState`. Without an explicit note, future agents read the split as drift and open a cleanup escalation. `D-043` says: the split stays, and both owners must name it.

## Task

1. Add a 3–6 line block comment at the top of `Game/RuntimeState/map_runtime_state.gd` and `Game/RuntimeState/support_interaction_state.gd` that says the hamlet side-quest runtime state is intentionally split between these two owners, names the other owner, and points to `D-043` and `SOURCE_OF_TRUTH.md`.
2. Add a short paragraph to `Docs/SOURCE_OF_TRUTH.md` under the appropriate ownership section saying the same thing in prose.
3. Add one sentence in `Docs/SUPPORT_INTERACTION_CONTRACT.md` and `Docs/MAP_CONTRACT.md` pointing to `SOURCE_OF_TRUTH.md` for the exact split.
4. Do not move any field between the two owners. This is a naming patch, not a refactor.

## Non-goals

- Do not touch function bodies.
- Do not adjust save shape.
- Do not add new command/event families.

## Report format

- before/after for each of the five edits
- confirmation that no field moved, no signal changed, no test needed to update
- validator result
