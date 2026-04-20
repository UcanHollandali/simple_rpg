# W1-04 — Extend `Tools/validate_architecture_guards.py` with catalog-drift and stale-wrapper guards (P-06)

- mode: Fast Lane
- scope: `Tools/validate_architecture_guards.py` only; a small new fixture file under `Tests/` only if needed to exercise the new guard
- do not touch: production `.gd` code; existing validator rules; existing `RUNTIME_RUNSTATE_COMPATIBILITY_PATTERNS` / `TEST_RUNSTATE_INVENTORY_COMPATIBILITY_PATTERNS` (they already cover the `RunState` compat accessors — do not duplicate them here)
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- doc policy: validator is tooling; no authority doc update required.

## Do NOT re-add the RunState compat guard

The current validator already contains these lists:
- `RUNTIME_RUNSTATE_COMPATIBILITY_PATTERNS`
- `TEST_RUNSTATE_INVENTORY_COMPATIBILITY_PATTERNS`
covering `weapon_instance | armor_instance | belt_instance | consumable_slots | passive_slots | current_node_index` on `run_state`-shaped receivers. Do not add a second rule for the same names.

## Task — two narrow additions only

### 1. Catalog-drift guard

Add a rule that flags code references to event/command names that are not registered in `Docs/COMMAND_EVENT_CATALOG.md`.

Implementation shape:
- Parse `Docs/COMMAND_EVENT_CATALOG.md` to extract the set of registered names (the catalog uses one-line bullets like `- name_here`).
- Scan `.gd` files for string literals and signal names that match the pattern of an event/command name (simple heuristic: CamelCase signals and `lower_snake_case` literals that are used as event keys).
- Emit a guard failure only for names that look like event/command families (the heuristic must be conservative — false positives must stay near zero).
- The guard must currently pass on the repo after `w0_05_catalog_drift_register.md` lands (so run that first, or the guard will immediately fail on `turn_phase_resolved` / `BossPhaseChanged`).

### 2. Stale-wrapper guard

Add a rule that detects trivial wrappers that delegate 1:1 to another public API and have no callers.

Implementation shape:
- AST or regex detection of a function that consists of a single `return` or single call that delegates to another named method.
- Cross-check grep for callers of the wrapper name.
- If zero callers inside the repo, flag it.
- Allow an in-file allowlist comment (`# validator:stale_wrapper_allow`) so intentional compat wrappers can opt out.

## Non-goals

- Do not touch `RUNTIME_RUNSTATE_COMPATIBILITY_PATTERNS` or `TEST_RUNSTATE_INVENTORY_COMPATIBILITY_PATTERNS` — D-042 froze those rules as the enforcement point.
- Do not change any production code to satisfy the new guards in this patch. Run `w0_05` and `w1_01` first so the repo is already clean.

## Report format

- new guard names
- exact set of names the catalog-drift guard currently knows about (counted from the catalog)
- stale-wrapper allowlist comment syntax (exact string)
- validator result on the current repo
- full-suite result
