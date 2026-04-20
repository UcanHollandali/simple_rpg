# W2-03 — Standardize Application invalid-state/error handling style (P-11)

- mode: Guarded Lane
- scope: `Game/Application/run_session_coordinator.gd`, `Game/Application/app_bootstrap.gd`, `Game/Application/combat_flow.gd`, `Game/Application/save_runtime_bridge.gd`, `Game/Application/game_flow_manager.gd`
- do not touch: `Game/RuntimeState/*`; save schema shape; command/event catalog entries; the `NodeResolve` narrowing from W2-01 (keep them as separate patches)
- validation budget: `py -3 Tools/validate_architecture_guards.py`; targeted flow/save/combat tests; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- doc policy: if the standardization introduces a shared helper, note the helper once in `Docs/ARCHITECTURE.md`. Otherwise no authority doc change.

## Task

1. Inventory the invalid-state/error paths in the five files in scope. Audit finding `APP-F4` identifies the inconsistency.
2. Pick one existing idiom that already appears in at least two of the five files and converge the other three onto it. Do not invent a new idiom.
3. Keep behavior identical: same control flow on the happy path, same observable error on the error path (log line, signal, or return value).
4. `combat_flow.gd` is at its validator line cap (764 / 764). If the standardization would grow any file past its cap, stop — the fix needs an extraction first and that is a separate item. Report the blocker.

## Escalation checks

Stop and report if:
- the change would need a new command/event family
- the change would move a source-of-truth ownership boundary
- any of the five files would need to grow past its `HOTSPOT_FILE_LINE_LIMITS` cap

## Report format

- which idiom was chosen and why (one sentence)
- per-file diff summary
- validator + targeted test + full suite result
- line counts for all five files before and after
