# W1-03 — Consolidate texture loading around one shared helper (P-04)

- mode: Fast Lane
- scope: `Game/UI/inventory_card_factory.gd`, `Game/UI/map_board_canvas.gd`, `Game/UI/scene_layout_helper.gd`. A new helper file under `Game/UI/` may be introduced if none of these three is a natural owner.
- do not touch: any `Game/RuntimeState/*`; any scene file; any texture asset; `ASSET_PIPELINE.md`; `ASSET_LICENSE_POLICY.md`
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- doc policy: asset-pipeline authority stays put; this is a loading-code consolidation only.

## Task

1. Identify the repeated texture-load pattern across the three files.
2. Route all three callsites through a single helper call. If `scene_layout_helper.gd` is the natural owner, put it there; otherwise create a narrow helper under `Game/UI/` and keep it stateless.
3. Keep behavior identical: same fallback handling, same error reporting, same cache behavior (do not introduce a new cache in this patch).
4. Do not change any asset path.

## Non-goals

- Do not introduce a new cache.
- Do not change any fallback semantics.
- Do not update `ASSET_PIPELINE.md` or `ASSET_BACKLOG.md` — this is an internal UI-helper change.

## Report format

- diff summary
- before/after callsite count
- validator + scene isolation + full suite result
