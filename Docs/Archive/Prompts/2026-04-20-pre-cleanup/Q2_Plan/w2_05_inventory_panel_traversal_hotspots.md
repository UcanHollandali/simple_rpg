# W2-05 — Remove shared inventory-panel post-render traversal hotspots (P-13)

- mode: Guarded Lane
- scope: `Game/UI/run_inventory_panel.gd`, `Game/UI/inventory_card_factory.gd`, `scenes/combat.gd`, `scenes/map_explore.gd`
- do not touch: `Game/RuntimeState/*`; save shape; command/event catalog entries
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 test_inventory_card_interaction_handler.gd test_button_tour.gd test_phase2_loop.gd`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- doc policy: optimization-only; no authority doc change unless caching semantics need to be named.

## Task

1. Find the per-card traversal sites that run on every render (audit `SCN-F4`, `SCN-F5`).
2. Replace the per-card traversal with:
   - a cached lookup on card construction, or
   - a single outer traversal that feeds children their data instead of each child walking up.
3. Keep behavior identical. A failing `test_phase2_loop.gd` is a regression, not a refactor.
4. `scenes/combat.gd` is 1184 lines (cap 1200). Do not grow past the cap; if you need to, extract first — and that extraction is not in scope for this patch.

## Escalation checks

Stop and report if:
- any of the four files in scope would need to grow past its cap
- the change would need a new runtime-state field
- the change would need a new event family

## Report format

- per-callsite diff summary
- measured frame-time before/after if practical; otherwise explicit note that measurement was qualitative
- targeted tests + scene isolation + full suite result
- line count before/after for all four files
