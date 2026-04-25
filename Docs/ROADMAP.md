# SIMPLE RPG - Active Roadmap

Last updated: 2026-04-25 (asset-production cleanup)

This is the active short-horizon roadmap for the repo.
It is a planning file, not an authority doc.
Authority lives where `Docs/DOC_PRECEDENCE.md` says it lives.

## Measured Current State

- The repo is prototype-playable per `Docs/HANDOFF.md`.
- There is no active queued work surface.
- The current map lane is fixed-board, structure-first, and presentation-only.
- The default map board read is:
  - `render_model.path_surfaces`
  - `render_model.junctions`
  - `render_model.clearing_surfaces`
- Candidate socket art is hidden behind explicit review flags.
- The old generated socket-brief docs, JSON sibling, design-tool routing, historical ballast, and temporary probe assets are removed from the active surface.
- The only active AI-facing map asset request is `Docs/ProductionAssetBriefs/map_asset_external_request_pack.md`.

## Closed Lane - Production Asset Prep

Result:
- added PNG-primary production target constants in `Game/UI/ui_asset_paths.gd`
- added an explicit board-ground review flag in `Game/UI/map_board_canvas.gd`
- kept normal/default map render unchanged
- kept runtime/save/flow ownership unchanged
- kept `ArtPilot` and `SocketSmoke` as explicit-review fallback assets
- removed temporary probe assets and manifest rows
- removed generated socket-brief docs and generator tooling from the active repo surface
- removed active design-tool routing and old historical/reference ballast
- kept `Docs/ProductionAssetBriefs/map_asset_external_request_pack.md` as the single external asset handoff

Validation:
- `py -3 Tools/validate_assets.py`
- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 -Tests test_map_board_canvas.gd,test_map_board_style.gd,test_map_board_composer_v2.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `git diff --check`

## Next Lane - External Map Asset Intake

Goal:
- use the request pack to produce external art variants and import only reviewed winners through the asset pipeline

Rules:
- use `Docs/ProductionAssetBriefs/map_asset_external_request_pack.md` as the only AI-facing production brief
- external assets must arrive with source/provenance notes before runtime import
- first import stays hidden behind explicit board-ground and socket drawing flags
- update `SourceArt/Edited/Map/Production/`, `Assets/UI/Map/Production/`, and `AssetManifest/asset_manifest.csv` together
- run screenshot review and pixel diff before any default render promotion

Expected asset targets:
- `ui_map_board_ground.png`
- `ui_map_path_brush.png`
- `ui_map_boss_landmark.png`
- `ui_map_key_landmark.png`
- `ui_map_rest_landmark.png`
- `ui_map_merchant_landmark.png`
- `ui_map_combat_landmark.png`
- `ui_map_event_landmark.png`
- `ui_map_reward_landmark.png`
- `ui_map_blacksmith_landmark.png`
- `ui_map_hamlet_landmark.png`
- `ui_map_forest_decor_family.png`

## After External Asset Intake

Choose the next lane explicitly from:
- a small manifest-backed default-render pilot for `2-3` reviewed assets
- additional map structural cleanup
- broader balance/content work
