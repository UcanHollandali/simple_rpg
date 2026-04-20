# W1-08 — Document the `RunState` compat-surface freeze (D-042)

- mode: Fast Lane, doc-only (inline block comment + authority-doc text)
- scope: a block comment around the compat accessors (lines ~38–68) of `Game/RuntimeState/run_state.gd`; short paragraph in `Docs/SOURCE_OF_TRUTH.md` and `Docs/SAVE_SCHEMA.md`
- do not touch: the accessor implementations; any caller; `Tools/validate_architecture_guards.py` (already guards the same names); any test
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: apply decision `D-042`. Do not retire the accessors. Do not add new ones.

## Context

`Game/RuntimeState/run_state.gd` exposes `weapon_instance`, `armor_instance`, `belt_instance`, `consumable_slots`, `passive_slots` as compat accessors that delegate to `InventoryState`. The validator already guards new uses (`RUNTIME_RUNSTATE_COMPATIBILITY_PATTERNS`, `TEST_RUNSTATE_INVENTORY_COMPATIBILITY_PATTERNS`). `D-042` closes the open question: these stay frozen; the validator stays the enforcement point; no removal pass is scheduled.

## Task

1. Add a 6–10 line block comment immediately above the compat-accessor block in `Game/RuntimeState/run_state.gd` stating:
   - this is a frozen compatibility surface,
   - the five names are not an expansion surface,
   - the validator enforces that no new callers land,
   - the decision is `D-042`,
   - owner for reads/writes is `InventoryState`.
2. Add a short paragraph to `Docs/SOURCE_OF_TRUTH.md` restating the freeze.
3. Add a one-line cross-reference in `Docs/SAVE_SCHEMA.md` if the save schema anywhere mentions these names.

## Non-goals

- Do not remove or add compat accessors.
- Do not modify the validator rule. (Exists and is correct.)
- Do not touch any caller of these accessors.

## Report format

- exact before/after line span of the comment
- SOURCE_OF_TRUTH paragraph in final form
- SAVE_SCHEMA cross-reference (or explicit note that none was needed)
- validator result
