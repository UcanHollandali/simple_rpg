# SIMPLE RPG - Handoff

Last updated: 2026-04-25 (asset-production cleanup)

This file is a current-state snapshot only.
It is not a rule contract. If it conflicts with an authority doc, the authority doc wins.
Use `Docs/ROADMAP.md` for next-lane planning and `Docs/DOC_PRECEDENCE.md` for authority routing.

## Current State

- The repo is prototype-playable across `MapExplore`, `Combat`, and the non-combat overlay family.
- The fixed-board map replacement remains prototype structural/presentation evidence, not final art or release proof.
- Normal/default map render uses one default surface lane:
  - `render_model.path_surfaces`
  - `render_model.junctions`
  - `render_model.clearing_surfaces`
- Socket art remains explicit-review only:
  - `MapBoardCanvas.set_prototype_socket_dressing_enabled(true)` gates path, landmark, and decor socket art.
  - `MapBoardCanvas.set_board_ground_texture_enabled(true)` gates the board-ground production texture.
  - normal/default board render does not draw candidate, socket-smoke, or production socket art automatically.
- Map production targets are wired as PNG-primary constants under `Game/UI/ui_asset_paths.gd`.
- Current socket resolver order is `Production -> ArtPilot -> SocketSmoke`.
- Temporary probe and generated socket-brief artifacts were removed from the active repo surface.
- The only active AI-facing map asset handoff is `Docs/ProductionAssetBriefs/map_asset_external_request_pack.md`.
- Runtime map production targets are intentionally missing until asset intake:
  - `Assets/UI/Map/Production/ui_map_board_ground.png`
  - `Assets/UI/Map/Production/ui_map_path_brush.png`
  - `Assets/UI/Map/Production/ui_map_boss_landmark.png`
  - `Assets/UI/Map/Production/ui_map_key_landmark.png`
  - `Assets/UI/Map/Production/ui_map_rest_landmark.png`
  - `Assets/UI/Map/Production/ui_map_merchant_landmark.png`
  - `Assets/UI/Map/Production/ui_map_combat_landmark.png`
  - `Assets/UI/Map/Production/ui_map_event_landmark.png`
  - `Assets/UI/Map/Production/ui_map_reward_landmark.png`
  - `Assets/UI/Map/Production/ui_map_blacksmith_landmark.png`
  - `Assets/UI/Map/Production/ui_map_hamlet_landmark.png`
  - `Assets/UI/Map/Production/ui_map_forest_decor_family.png`

## Last Verified Local Checks

- `py -3 Tools/validate_assets.py`
- `py -3 Tools/validate_architecture_guards.py` with existing hotspot warnings only
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 -Tests test_map_board_canvas.gd,test_map_board_style.gd,test_map_board_composer_v2.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `git diff --check`

## Open Risks

- Test green does not replace visual review for map readability.
- Art-pilot and socket-smoke assets remain provisional review aids, not final art.
- Runtime assets under `Assets/UI/Map/Production/` must not be added without matching source/master files and manifest provenance.
- Default render promotion remains a separate screenshot-review and pixel-diff decision.
- Runtime ownership remains stable:
  - `MapRuntimeState` owns graph, current-node, discovery, adjacency, key/boss, and pending-node truth.
  - `RunSessionCoordinator` owns movement and pending-screen orchestration.
  - `Game/UI` owns derived presentation only.

## Next Step

1. Use only `Docs/ProductionAssetBriefs/map_asset_external_request_pack.md` as the external production handoff.
2. Ask for `2-3` variants per requested asset where practical.
3. Keep socket assets transparent.
4. Keep board ground opaque, `920x1180`, edge-to-edge, and free of paths, nodes, landmarks, island composition, or border frame.
5. When assets return, run a separate intake pass:
  - copy reviewed masters into `SourceArt/Edited/Map/Production/`
  - export runtime files under `Assets/UI/Map/Production/`
  - add or update `AssetManifest/asset_manifest.csv`
  - review through explicit socket/ground flags before any default render promotion

## Locked Decisions

- No save-shape, flow-state, or source-of-truth ownership change is part of the asset-prep cleanup.
- Candidate art remains provisional unless a later production-art lane explicitly promotes reviewed assets.
- The external request pack is the production ask; generated drafts and JSON siblings are not active handoff surfaces.
