# W1-01 — Prune stale wrappers and obvious dead public aliases (P-05)

- mode: Fast Lane
- scope: `Game/Application/game_flow_manager.gd:transition_to`, `Game/Infrastructure/save_service.gd:is_supported_save_state_now`, plus any other dead/stale wrapper you can confirm by grep with zero callers inside the repo
- do not touch: `Game/RuntimeState/run_state.gd` compat accessors (frozen by D-042 — see `Docs/DECISION_LOG.md`), save-schema shape, any flow-state transition, any command/event family
- validation budget: `py -3 Tools/validate_architecture_guards.py`; targeted tests for the touched slice; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- doc policy: if a wrapper is documented anywhere in `Docs/`, update the reference in the same patch or leave the wrapper alone.

## Task

1. For each candidate wrapper in scope:
   1. Confirm zero callers inside the repo via grep.
   2. Confirm zero references in any file under `Docs/`.
   3. Remove the wrapper definition.
2. Only touch the two explicitly named wrappers plus any additional wrappers you independently confirm as dead. Report each extra deletion separately.
3. If a wrapper looks unused but has an external-intent callsite comment (e.g. "kept for save compat"), leave it and report.

## Non-goals

- Do not rename public APIs.
- Do not introduce new indirection.
- Do not touch any `RunState` compat accessor.
- Do not modify `Docs/COMMAND_EVENT_CATALOG.md` — this is a pure code hygiene patch.

## Report format

- per-wrapper: path, final decision (removed / kept with reason)
- grep result showing zero remaining callers for each removed item
- validator result
- test result summary
